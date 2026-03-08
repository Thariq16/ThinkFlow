/**
 * ThinkFlow Cloud Functions — Index
 * Exports all Cloud Functions for Firebase deployment
 */

// Voice processing
export { processVoice } from "./voice/processVoice";

// Task generation
export { generateSubtasks } from "./tasks/generateSubtasks";

// Knowledge Base
export { ingestKbItem } from "./kb/ingestKbItem";
export { recalibrateProject } from "./kb/recalibrateProject";
export { acceptRecalibDiff } from "./kb/acceptRecalibDiff";

// Stripe billing
export { createCheckoutSession } from "./stripe/createCheckoutSession";
export { stripeWebhook } from "./stripe/stripeWebhook";
