import { VertexAI } from "@google-cloud/vertexai";

// Singleton Vertex AI client — uses ADC (Application Default Credentials)
// No API key needed — Cloud Functions service account handles auth automatically
const vertex = new VertexAI({
  project: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "",
  location: "us-central1",
});

// Gemini 1.5 Pro — decomposition, recalibration, transcription
export const proModel = vertex.getGenerativeModel({
  model: "gemini-1.5-pro",
  generationConfig: {
    responseMimeType: "application/json",
    temperature: 0.2,
    maxOutputTokens: 8192,
  },
});

// Gemini 1.5 Flash — subtask generation, change summaries
export const flashModel = vertex.getGenerativeModel({
  model: "gemini-1.5-flash",
  generationConfig: {
    responseMimeType: "application/json",
    temperature: 0.3,
    maxOutputTokens: 4096,
  },
});
