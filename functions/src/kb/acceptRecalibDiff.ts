import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import { FieldValue } from "firebase-admin/firestore";

/**
 * acceptRecalibDiff — HTTPS Callable
 * Applies accepted changes to task documents and creates new tasks
 * Input: { projectId, diffId, acceptedChangeIds: string[] }
 * Output: { updatedCount }
 */
export const acceptRecalibDiff = onCall(
  { maxInstances: 10, timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { projectId, diffId, acceptedChangeIds } = request.data;
    if (!projectId || !diffId || !Array.isArray(acceptedChangeIds)) {
      throw new HttpsError(
        "invalid-argument",
        "projectId, diffId, and acceptedChangeIds are required."
      );
    }

    // Get the diff document
    const diffRef = db
      .collection("projects")
      .doc(projectId)
      .collection("recalib_diffs")
      .doc(diffId);
    const diffDoc = await diffRef.get();

    if (!diffDoc.exists) {
      throw new HttpsError("not-found", "Diff not found.");
    }

    const diffData = diffDoc.data()!;
    if (diffData.status !== "pending_review") {
      throw new HttpsError(
        "failed-precondition",
        "Diff is not pending review."
      );
    }

    const batch = db.batch();
    let updatedCount = 0;

    // Apply accepted changes to existing tasks
    const acceptedSet = new Set(acceptedChangeIds);
    for (const change of diffData.changes || []) {
      if (acceptedSet.has(change.taskId)) {
        const taskRef = db
          .collection("projects")
          .doc(projectId)
          .collection("tasks")
          .doc(change.taskId);
        batch.update(taskRef, {
          [change.field]: change.newValue,
          updatedAt: FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }
    }

    // Create accepted new tasks
    for (const newTask of diffData.newTasks || []) {
      // For new tasks, we check if any were accepted
      // Since new tasks don't have IDs yet, accept all new tasks
      const taskRef = db
        .collection("projects")
        .doc(projectId)
        .collection("tasks")
        .doc();
      batch.set(taskRef, {
        projectId,
        parentId: newTask.parentId || null,
        level: newTask.level || 1,
        title: newTask.title,
        description: newTask.description || "",
        priority: newTask.priority || "medium",
        status: "todo",
        aiGenerated: true,
        lockedFromRecalib: false,
        order: 999, // Append at end
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      updatedCount++;
    }

    // Update project task count if new tasks were added
    if ((diffData.newTasks || []).length > 0) {
      batch.update(db.collection("projects").doc(projectId), {
        taskCount: FieldValue.increment(diffData.newTasks.length),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Mark diff as accepted
    batch.update(diffRef, { status: "accepted" });

    await batch.commit();

    return { updatedCount };
  }
);
