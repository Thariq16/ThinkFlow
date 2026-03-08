import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import { flashModel } from "../shared/vertexClient";
import { checkPlanLimit } from "../shared/planGuard";
import { GENERATE_SUBTASKS_PROMPT } from "../shared/prompts";
import { FieldValue } from "firebase-admin/firestore";

interface SubtaskResult {
  subtasks: Array<{
    title: string;
    description: string;
    priority: string;
  }>;
}

/**
 * generateSubtasks — HTTPS Callable
 * Uses Gemini 1.5 Flash for quick subtask generation
 * Input: { projectId, epicId, epicTitle, epicDescription }
 * Output: { subtasks: SubTask[] }
 */
export const generateSubtasks = onCall(
  { maxInstances: 10, timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    await checkPlanLimit(uid, "voice_input");

    const { projectId, epicId, epicTitle, epicDescription } = request.data;
    if (!projectId || !epicId || !epicTitle) {
      throw new HttpsError("invalid-argument", "projectId, epicId, and epicTitle are required.");
    }

    // Generate subtasks using Flash model
    let result: SubtaskResult;
    let retries = 0;

    while (retries < 2) {
      try {
        const genResult = await flashModel.generateContent({
          contents: [
            { role: "user", parts: [{ text: GENERATE_SUBTASKS_PROMPT(epicTitle, epicDescription || "") }] },
          ],
        });
        const jsonText = genResult.response.candidates?.[0]?.content?.parts?.[0]?.text || "";
        result = JSON.parse(jsonText) as SubtaskResult;
        if (!Array.isArray(result.subtasks)) throw new Error("Invalid schema");
        break;
      } catch (e) {
        retries++;
        if (retries >= 2) throw new HttpsError("internal", "Failed to generate subtasks.");
      }
    }

    // Write subtasks to Firestore
    const batch = db.batch();
    let order = 0;
    for (const sub of result!.subtasks) {
      const ref = db.collection("projects").doc(projectId).collection("tasks").doc();
      batch.set(ref, {
        projectId,
        parentId: epicId,
        level: 2,
        title: sub.title,
        description: sub.description || "",
        priority: sub.priority || "medium",
        status: "todo",
        aiGenerated: true,
        lockedFromRecalib: false,
        order: order++,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Update project task count
    batch.update(db.collection("projects").doc(projectId), {
      taskCount: FieldValue.increment(result!.subtasks.length),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return { subtasks: result!.subtasks };
  }
);
