import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import { proModel } from "../shared/vertexClient";
import { checkPlanLimit } from "../shared/planGuard";
import { RECALIBRATE_PROMPT } from "../shared/prompts";
import { FieldValue } from "firebase-admin/firestore";

interface RecalibResult {
  changes: Array<{
    taskId: string;
    field: string;
    newValue: string;
    reason: string;
  }>;
  newTasks: Array<{
    parentId: string | null;
    level: number;
    title: string;
    description: string;
    priority: string;
    reason: string;
  }>;
}

/**
 * recalibrateProject — HTTPS Callable
 * Reads incomplete, non-locked tasks + KB text → Gemini Pro → writes recalib_diff
 * Does NOT modify tasks until user accepts
 * Input: { projectId, kbItemId }
 * Output: { diffId, changeCount, newTaskCount }
 */
export const recalibrateProject = onCall(
  { maxInstances: 5, timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    await checkPlanLimit(uid, "kb_upload");

    const { projectId, kbItemId } = request.data;
    if (!projectId || !kbItemId) {
      throw new HttpsError("invalid-argument", "projectId and kbItemId required.");
    }

    // Get KB item text
    const kbDoc = await db.collection("projects").doc(projectId)
      .collection("kb_items").doc(kbItemId).get();
    if (!kbDoc.exists) throw new HttpsError("not-found", "KB item not found.");
    const kbText = kbDoc.data()!.extractedText || "";
    if (!kbText.trim()) throw new HttpsError("failed-precondition", "KB item has no extracted text.");

    // Get all incomplete, non-locked tasks
    const tasksSnap = await db.collection("projects").doc(projectId)
      .collection("tasks").get();
    const incompleteTasks = tasksSnap.docs
      .filter((d) => {
        const data = d.data();
        return data.status !== "done" && !data.lockedFromRecalib;
      })
      .map((d) => ({
        taskId: d.id,
        title: d.data().title,
        description: d.data().description,
        priority: d.data().priority,
        status: d.data().status,
        parentId: d.data().parentId,
        level: d.data().level,
      }));

    if (incompleteTasks.length === 0) {
      throw new HttpsError("failed-precondition", "No incomplete tasks to recalibrate.");
    }

    // Call Gemini Pro with recalibration prompt
    let result: RecalibResult;
    let retries = 0;

    while (retries < 2) {
      try {
        const genResult = await proModel.generateContent({
          contents: [
            { role: "user", parts: [{ text: RECALIBRATE_PROMPT(incompleteTasks, kbText) }] },
          ],
        });
        const jsonText = genResult.response.candidates?.[0]?.content?.parts?.[0]?.text || "";
        result = JSON.parse(jsonText) as RecalibResult;
        if (!Array.isArray(result.changes) || !Array.isArray(result.newTasks)) {
          throw new Error("Invalid schema");
        }
        break;
      } catch (e) {
        retries++;
        if (retries >= 2) throw new HttpsError("internal", "Failed to parse recalibration response.");
      }
    }

    // Build diff document with old values
    const changesWithOld = [];
    for (const change of result!.changes) {
      const taskDoc = tasksSnap.docs.find((d) => d.id === change.taskId);
      if (!taskDoc) continue;
      changesWithOld.push({
        taskId: change.taskId,
        field: change.field,
        oldValue: taskDoc.data()[change.field] || "",
        newValue: change.newValue,
        reason: change.reason,
      });
    }

    // Write recalib_diff — tasks are NOT modified yet
    const diffRef = db.collection("projects").doc(projectId)
      .collection("recalib_diffs").doc();
    await diffRef.set({
      projectId,
      kbItemId,
      status: "pending_review",
      changes: changesWithOld,
      newTasks: result!.newTasks,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      diffId: diffRef.id,
      changeCount: changesWithOld.length,
      newTaskCount: result!.newTasks.length,
    };
  }
);
