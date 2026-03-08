import { onRequest } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import { FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", {
  apiVersion: "2024-04-10",
});
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

/**
 * stripeWebhook — HTTPS Request handler (NOT Callable)
 * Called directly by Stripe — verifies webhook signature
 * Events:
 *   checkout.session.completed → set plan to pro/team
 *   customer.subscription.deleted → set plan back to free
 *   invoice.payment_failed → flag account
 */
export const stripeWebhook = onRequest(
  { maxInstances: 10 },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // Verify Stripe webhook signature
    const sig = req.headers["stripe-signature"];
    if (!sig) {
      res.status(400).send("Missing stripe-signature header");
      return;
    }

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        webhookSecret
      );
    } catch (err: any) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    try {
      switch (event.type) {
        case "checkout.session.completed": {
          const session = event.data.object as Stripe.Checkout.Session;
          const uid = session.metadata?.firebaseUid;
          const plan = session.metadata?.plan || "pro";

          if (uid) {
            await db.collection("users").doc(uid).update({
              plan,
              stripeSubId: session.subscription as string,
              planExpiresAt: null,
              updatedAt: FieldValue.serverTimestamp(),
            });
            console.log(`User ${uid} upgraded to ${plan}`);
          }
          break;
        }

        case "customer.subscription.deleted": {
          const subscription = event.data
            .object as Stripe.Subscription;
          // Find user by stripeSubId
          const usersSnap = await db
            .collection("users")
            .where("stripeSubId", "==", subscription.id)
            .limit(1)
            .get();

          if (!usersSnap.empty) {
            const userDoc = usersSnap.docs[0];
            await userDoc.ref.update({
              plan: "free",
              stripeSubId: null,
              planExpiresAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });
            console.log(`User ${userDoc.id} downgraded to free`);
          }
          break;
        }

        case "invoice.payment_failed": {
          const invoice = event.data.object as Stripe.Invoice;
          const customerId = invoice.customer as string;

          // Find user by stripeCustomerId
          const usersSnap = await db
            .collection("users")
            .where("stripeCustomerId", "==", customerId)
            .limit(1)
            .get();

          if (!usersSnap.empty) {
            console.warn(
              `Payment failed for user ${usersSnap.docs[0].id}`
            );
            // Could add a `paymentFailed` flag here for UI warning
          }
          break;
        }

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      res.status(200).json({ received: true });
    } catch (err: any) {
      console.error("Error processing webhook:", err);
      res.status(500).send("Internal Server Error");
    }
  }
);
