/**
 * StudyForge — Cloud Functions
 *
 * ⚠️ STATUS: SKELETON. These are typed signatures with the security-critical
 * decisions documented, but the Tap Payments and aggregation bodies are NOT
 * implemented. That is Sprint S3 work — see docs/10-SPRINT-PLAN.md §4.
 *
 * WHY THIS SURFACE IS DELIBERATELY TINY
 * -------------------------------------
 * Cloud Functions are the only component that can produce an unbudgeted bill,
 * because the Blaze plan is tied to a billing account. Everything that can run
 * on-device does (docs/04 §4). So exactly three things live here:
 *
 *   1. createCharge       — the Tap SECRET key must never ship inside the app
 *   2. tapWebhook         — entitlement is granted by the gateway, never by a
 *                           client that merely claims success
 *   3. rollupDailyMetrics — roll-ups must not become billable client writes
 *
 * Anything else belongs in the app.
 */

import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

initializeApp();

// Keep the blast radius small: one region, few instances, bounded concurrency.
setGlobalOptions({ region: 'us-central1', maxInstances: 3 });

const db = getFirestore();

/** Secrets live only in the function environment — never in the app bundle. */
const TAP_SECRET_KEY = defineSecret('TAP_SECRET_KEY');
const TAP_WEBHOOK_SECRET = defineSecret('TAP_WEBHOOK_SECRET');

/** Plan catalogue. Mirrors docs/04 §6. Prices are VAT-inclusive, in BHD fils. */
const PLANS: Record<string, { monthly: number; annual: number }> = {
  plus: { monthly: 1900, annual: 19000 },
  pro: { monthly: 4900, annual: 49000 },
};

// ═════════════ 1. createCharge — keeps the secret key server-side ═════════════

/**
 * Creates a Tap charge and returns the redirect URL for the client to present.
 *
 * SECURITY: the client sends only a plan id and a term — never an amount. The
 * amount is resolved HERE from PLANS, so a tampered price in the app is ignored
 * because the server recomputes what is actually owed.
 */
export const createCharge = onCall(
  { secrets: [TAP_SECRET_KEY] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Sign in before upgrading.');
    }

    const { planId, term } = (request.data ?? {}) as {
      planId?: string;
      term?: 'monthly' | 'annual';
    };

    if (!planId || !PLANS[planId]) {
      throw new HttpsError('invalid-argument', 'Unknown plan.');
    }
    if (term !== 'monthly' && term !== 'annual') {
      throw new HttpsError('invalid-argument', 'Unknown billing term.');
    }

    const amount = PLANS[planId]![term];

    // Idempotency: a retried tap must not produce a second charge.
    const idempotencyKey =
      `${uid}:${planId}:${term}:${new Date().toISOString().slice(0, 10)}`;

    // TODO(S3): POST to Tap /v2/charges with TAP_SECRET_KEY.value(), the
    //           server-resolved `amount`, currency "BHD", and `idempotencyKey`.
    //           Return { tapChargeId, redirectURL }.
    throw new HttpsError(
      'unimplemented',
      `createCharge not implemented yet (order ${idempotencyKey}, amount ${amount} fils)`,
    );
  },
);

// ═════════════ 2. tapWebhook — the single source of truth ═════════════

/**
 * Receives Tap's payment notification and grants the entitlement.
 *
 * SECURITY: the client is never trusted. An in-app "success" callback changes
 * nothing — this webhook is the only writer of `subscriptions/{uid}` and the only
 * place the `plan` custom claim is set. The signature is verified first, then the
 * amount and currency are re-checked against PLANS so a tampered notification
 * cannot buy a Pro plan for one fils.
 */
export const tapWebhook = onRequest(
  { secrets: [TAP_SECRET_KEY, TAP_WEBHOOK_SECRET], cors: false },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    // TODO(S3):
    //  1. verifySignature(req, TAP_WEBHOOK_SECRET.value())        -> 401 if invalid
    //  2. read charge id, amount, currency, status and our orderId
    //  3. RE-RESOLVE the expected amount from PLANS and reject the payload if it
    //     disagrees with what we charged
    //  4. idempotently write (keyed on tapChargeId so a retry is harmless):
    //       payments/{paymentId}  { uid, amount, currency, status, tapChargeId }
    //       subscriptions/{uid}   { plan, status, periodStart, periodEnd, ... }
    //       auditLog/{id}         append-only record of the entitlement change
    //       auth.setCustomUserClaims(uid, { plan })   <- mirrored into the token
    //  5. respond 200 only after the writes commit, so Tap retries on failure

    res.status(501).send('tapWebhook not implemented');
  },
);

// ═════════════ 3. rollupDailyMetrics — nightly aggregation ═════════════

/**
 * Rolls raw activity into the read-optimised documents the dashboards use.
 *
 * WHY: dashboards that recompute from raw events on the client are the classic
 * Firestore read-cost trap. One scheduled job does the work once, and the app then
 * reads a single small document per user.
 *
 * Writes `progress/{uid}` and `topicMastery/{uid}/topics/{topicId}`, both of which
 * the security rules deliberately expose to clients as READ-ONLY.
 */
export const rollupDailyMetrics = onSchedule(
  { schedule: 'every day 02:00', timeZone: 'Asia/Bahrain', timeoutSeconds: 300 },
  async () => {
    // TODO(S4): for each user active in the last 24h:
    //   1. aggregate activityEvents -> streak, minutes studied, cards reviewed
    //   2. recompute topicMastery from quizAttempts and card ratings
    //   3. evaluate achievements
    //   4. write progress/{uid} with an updatedAt so staleness is visible to the UI
    //   5. checkpoint in small batches so the 300s timeout always holds

    await db.collection('aiConfig').doc('rollupStatus').set(
      {
        lastRunStartedAt: FieldValue.serverTimestamp(),
        status: 'not-implemented',
      },
      { merge: true },
    );
  },
);

