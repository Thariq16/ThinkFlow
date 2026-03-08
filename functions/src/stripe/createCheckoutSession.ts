import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../shared/firestoreAdmin";
import Stripe from "stripe";

// Stripe client — reads secret key from Firebase Secrets
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "", {
  apiVersion: "2024-04-10",
});

// Stripe price IDs — set these after creating products in Stripe Dashboard
const PRICE_IDS: Record<string, string> = {
  pro: process.env.STRIPE_PRO_PRICE_ID || "price_pro_placeholder",
  team: process.env.STRIPE_TEAM_PRICE_ID || "price_team_placeholder",
};

/**
 * createCheckoutSession — HTTPS Callable
 * Creates or retrieves Stripe Customer, creates Checkout Session
 * Input: { plan: 'pro' | 'team', successUrl, cancelUrl }
 * Output: { checkoutUrl }
 */
export const createCheckoutSession = onCall(
  { maxInstances: 10, timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    const { plan, successUrl, cancelUrl } = request.data;
    if (!plan || !successUrl || !cancelUrl) {
      throw new HttpsError(
        "invalid-argument",
        "plan, successUrl, and cancelUrl are required."
      );
    }
    if (!PRICE_IDS[plan]) {
      throw new HttpsError("invalid-argument", `Invalid plan: ${plan}`);
    }

    // Get or create Stripe Customer
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    let customerId = userDoc.data()!.stripeCustomerId;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userDoc.data()!.email,
        metadata: { firebaseUid: uid },
      });
      customerId = customer.id;
      await userRef.update({ stripeCustomerId: customerId });
    }

    // Create Checkout Session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      line_items: [
        {
          price: PRICE_IDS[plan],
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { firebaseUid: uid, plan },
    });

    return { checkoutUrl: session.url };
  }
);
