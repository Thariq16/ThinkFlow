import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import { proModel } from "../shared/vertexClient";
import { checkPlanLimit } from "../shared/planGuard";
import { DECOMPOSE_PROMPT } from "../shared/prompts";
import { FieldValue } from "firebase-admin/firestore";

interface DecompositionResult {
  projectTitle: string;
  projectDescription: string;
  epics: Array<{
    title: string;
    description: string;
    priority: string;
    subtasks: Array<{
      title: string;
      description: string;
      priority: string;
    }>;
  }>;
}

/**
 * processVoice — HTTPS Callable
 * Auth required. Plan guard: Free max 5 calls/month.
 * Input: { audioBase64: string, mimeType: string, projectId?: string }
 * Output: { projectId: string, transcript: string, tasks: object }
 *
 * 1. Transcribe audio via Gemini 1.5 Pro multimodal
 * 2. Decompose transcript into project + task tree
 * 3. Write project + tasks to Firestore
 * 4. Increment usage counter
 */
export const processVoice = onCall(
  { maxInstances: 10, timeoutSeconds: 120 },
  async (request) => {
    // Auth verification
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    // Plan guard — Free: max 5 voice inputs/month
    await checkPlanLimit(uid, "voice_input");

    const { audioBase64, mimeType } = request.data;
    if (!audioBase64 || !mimeType) {
      throw new HttpsError(
        "invalid-argument",
        "audioBase64 and mimeType are required."
      );
    }

    // Step 1: Transcribe audio using Gemini Pro multimodal
    const transcriptionResult = await proModel.generateContent({
      contents: [
        {
          role: "user",
          parts: [
            {
              inlineData: {
                mimeType: mimeType,
                data: audioBase64,
              },
            },
            {
              text: "Transcribe this audio recording accurately. Return ONLY the transcription text, nothing else.",
            },
          ],
        },
      ],
    });

    const transcript =
      transcriptionResult.response.candidates?.[0]?.content?.parts?.[0]
        ?.text || "";

    if (!transcript.trim()) {
      throw new HttpsError(
        "internal",
        "Failed to transcribe audio. The recording may be empty or unclear."
      );
    }

    // Step 2: Decompose transcript into project + task tree
    let decomposition: DecompositionResult;
    let retries = 0;

    while (retries < 2) {
      try {
        const decompResult = await proModel.generateContent({
          contents: [
            { role: "user", parts: [{ text: DECOMPOSE_PROMPT(transcript) }] },
          ],
        });

        const jsonText =
          decompResult.response.candidates?.[0]?.content?.parts?.[0]?.text ||
          "";
        decomposition = JSON.parse(jsonText) as DecompositionResult;

        // Validate schema
        if (
          !decomposition.projectTitle ||
          !Array.isArray(decomposition.epics)
        ) {
          throw new Error("Invalid schema: missing projectTitle or epics");
        }
        break;
      } catch (e) {
        retries++;
        if (retries >= 2) {
          throw new HttpsError(
            "internal",
            "Failed to parse AI response after 2 attempts."
          );
        }
      }
    }

    // Step 3: Write to Firestore
    const projectRef = db.collection("projects").doc();
    const projectId = request.data.projectId || projectRef.id;

    const projectData = {
      uid,
      title: decomposition!.projectTitle,
      description: decomposition!.projectDescription || "",
      voiceTranscript: transcript,
      status: "active",
      taskCount: 0,
      completedCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    let totalTasks = 0;
    const batch = db.batch();

    // Create project
    const actualProjectRef = request.data.projectId
      ? db.collection("projects").doc(request.data.projectId)
      : projectRef;

    if (!request.data.projectId) {
      batch.set(actualProjectRef, projectData);
    } else {
      batch.update(actualProjectRef, {
        voiceTranscript: transcript,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Create tasks (epics + subtasks)
    let epicOrder = 0;
    for (const epic of decomposition!.epics) {
      const epicRef = actualProjectRef.collection("tasks").doc();
      batch.set(epicRef, {
        projectId: actualProjectRef.id,
        parentId: null,
        level: 1,
        title: epic.title,
        description: epic.description || "",
        priority: epic.priority || "medium",
        status: "todo",
        aiGenerated: true,
        lockedFromRecalib: false,
        order: epicOrder++,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      totalTasks++;

      let subtaskOrder = 0;
      for (const subtask of epic.subtasks || []) {
        const subtaskRef = actualProjectRef.collection("tasks").doc();
        batch.set(subtaskRef, {
          projectId: actualProjectRef.id,
          parentId: epicRef.id,
          level: 2,
          title: subtask.title,
          description: subtask.description || "",
          priority: subtask.priority || "medium",
          status: "todo",
          aiGenerated: true,
          lockedFromRecalib: false,
          order: subtaskOrder++,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        totalTasks++;
      }
    }

    // Update task count on project
    batch.update(actualProjectRef, { taskCount: totalTasks });

    // Step 4: Increment usage counter
    batch.update(db.collection("users").doc(uid), {
      voiceInputsThisMonth: FieldValue.increment(1),
      ...(request.data.projectId
        ? {}
        : { projectCount: FieldValue.increment(1) }),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      projectId: actualProjectRef.id,
      transcript,
      taskCount: totalTasks,
    };
  }
);
