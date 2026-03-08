import { HttpsError } from "firebase-functions/v2/https";
import { db } from "./firestoreAdmin";

/**
 * Plan guard — enforces Free tier limits before any AI call.
 * Must be called at the start of every AI-using Cloud Function.
 *
 * Free: 3 projects max, 5 voice inputs/month, no KB uploads
 * Pro ($12/month): Unlimited projects, unlimited voice, KB up to 50MB
 * Team ($29/month): Everything in Pro, 5 seats
 */
export async function checkPlanLimit(
  uid: string,
  action: "voice_input" | "kb_upload" | "create_project"
): Promise<void> {
  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User document not found.");
  }

  const data = userDoc.data()!;
  const plan: string = data.plan || "free";
  const voiceInputsThisMonth: number = data.voiceInputsThisMonth || 0;
  const projectCount: number = data.projectCount || 0;

  if (plan !== "free") {
    // Pro and Team have no limits for these actions
    return;
  }

  // Free plan limits
  switch (action) {
    case "voice_input":
      if (voiceInputsThisMonth >= 5) {
        throw new HttpsError(
          "resource-exhausted",
          "Free plan limit reached. Upgrade to Pro for unlimited voice inputs."
        );
      }
      break;

    case "kb_upload":
      throw new HttpsError(
        "permission-denied",
        "KB uploads require a Pro plan."
      );

    case "create_project":
      if (projectCount >= 3) {
        throw new HttpsError(
          "resource-exhausted",
          "Free plan limit reached. Upgrade to Pro for unlimited projects."
        );
      }
      break;
  }
}
