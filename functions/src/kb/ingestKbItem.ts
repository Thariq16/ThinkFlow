import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db, storage } from "../shared/firestoreAdmin";
import { checkPlanLimit } from "../shared/planGuard";
import { FieldValue } from "firebase-admin/firestore";
import * as https from "https";
import * as http from "http";

/**
 * ingestKbItem — HTTPS Callable
 * Handles PDF (pdf-parse), URL (fetch + extract), or text input
 * Input: { projectId, type, storageRef?, url?, text?, label }
 * Output: { kbItemId, status }
 */
export const ingestKbItem = onCall(
  { maxInstances: 10, timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    await checkPlanLimit(uid, "kb_upload");

    const { projectId, type, label, storageRef, url, text } = request.data;
    if (!projectId || !type || !label) {
      throw new HttpsError("invalid-argument", "projectId, type, and label are required.");
    }

    // Create KB item with 'processing' status
    const kbRef = db.collection("projects").doc(projectId).collection("kb_items").doc();
    await kbRef.set({
      projectId,
      type,
      label,
      storageRef: storageRef || null,
      sourceUrl: url || null,
      extractedText: "",
      status: "processing",
      processedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    try {
      let extractedText = "";

      switch (type) {
        case "pdf": {
          if (!storageRef) throw new Error("storageRef required for PDF type");
          const bucket = storage.bucket();
          const file = bucket.file(storageRef);
          const [buffer] = await file.download();
          // Dynamic import for pdf-parse
          const pdfParse = require("pdf-parse");
          const pdfData = await pdfParse(buffer);
          extractedText = pdfData.text || "";
          break;
        }

        case "url": {
          if (!url) throw new Error("url required for URL type");
          extractedText = await fetchUrlText(url);
          break;
        }

        case "text": {
          if (!text) throw new Error("text required for text type");
          extractedText = text;
          break;
        }

        default:
          throw new Error(`Unknown KB type: ${type}`);
      }

      // Update KB item with extracted text
      await kbRef.update({
        extractedText,
        status: "ready",
        processedAt: FieldValue.serverTimestamp(),
      });

      return { kbItemId: kbRef.id, status: "ready" };
    } catch (e: any) {
      await kbRef.update({
        status: "error",
        processedAt: FieldValue.serverTimestamp(),
      });
      throw new HttpsError("internal", `KB ingestion failed: ${e.message}`);
    }
  }
);

/**
 * Fetch text content from a URL
 */
function fetchUrlText(url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("https") ? https : http;
    client.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        // Simple HTML tag stripping
        const text = data
          .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
          .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
          .replace(/<[^>]+>/g, " ")
          .replace(/\s+/g, " ")
          .trim();
        resolve(text.substring(0, 100000)); // Cap at 100K chars
      });
      res.on("error", reject);
    }).on("error", reject);
  });
}
