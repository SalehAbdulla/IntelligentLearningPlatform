/**
 * StudyForge — Cloud Functions
 *
 * STATUS: the Tap payment surface (createCharge, tapWebhook) is IMPLEMENTED, ported from a
 * working Tap integration (the `beyond` project) so the endpoints, the charge payload, the
 * status set and the X-Tap-Signature HMAC verification match a real deployment. It is NOT
 * deployed: that needs the Blaze plan plus a budget alert and spend cap (docs/04 §5) and the
 * Tap secret keys from a Tap merchant account (docs/09 Q2/Q3). `rollupDailyMetrics` is still
 * a skeleton (Sprint S4 work, see docs/10-SPRINT-PLAN.md §4).
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
import { getAuth } from 'firebase-admin/auth';
import { createHmac, timingSafeEqual } from 'node:crypto';

initializeApp();

// Keep the blast radius small: one region, few instances, bounded concurrency.
setGlobalOptions({ region: 'us-central1', maxInstances: 3 });

const db = getFirestore();

/** Secrets live only in the function environment — never in the app bundle. */
const TAP_SECRET_KEY = defineSecret('TAP_SECRET_KEY');
const TAP_WEBHOOK_SECRET = defineSecret('TAP_WEBHOOK_SECRET');
/** Optional merchant id (TAP_MERCHANT_ID); Tap uses it to attribute the charge. */
const TAP_MERCHANT_ID = defineSecret('TAP_MERCHANT_ID');

// TODO(M1 · backend): Two prerequisites this surface cannot satisfy on its own.
//   1. Add an `onUserCreate` Auth trigger that writes the `role` custom claim. The role model
//      depends on it and nothing else sets it, so roles are currently granted out of band
//      (docs/09 Q13).
//   2. Deploy only after a Google Cloud budget alert and spend cap exist, and link the
//      Functions SDK in the app so it can call `createCharge`.
// Done when: the trigger exists, the three functions deploy, and plan and role claims come
// from the server rather than an out-of-band grant.

/** Plan catalogue. Mirrors docs/04 §6. Prices are VAT-inclusive, in BHD fils. */
const PLANS: Record<string, { monthly: number; annual: number }> = {
  plus: { monthly: 1900, annual: 19000 },
  pro: { monthly: 4900, annual: 49000 },
};

/** Tap REST base. The trailing slash on create matters (ported from the `beyond` integration). */
const TAP_API = 'https://api.tap.company/v2/charges';
/** Tap hosted payment page: the student pays on Tap's page, then Tap redirects back. */
const TAP_SOURCE_ALL = 'src_all';
/** BHD has THREE decimal places; Tap expects a decimal amount, not fils. */
const TAP_CURRENCY = 'BHD';
/** Where Tap sends the student back. Set TAP_REDIRECT_URL in the function env. */
const TAP_RETURN_URL = process.env.TAP_REDIRECT_URL ?? 'https://studyforge.app/payment/return';
/** Where Tap posts async status updates (this webhook). Set TAP_WEBHOOK_URL in the env. */
const TAP_WEBHOOK_URL = process.env.TAP_WEBHOOK_URL ?? '';

/** The Tap charge statuses, so a webhook for any of them is handled knowingly. */
const TAP_STATUS = {
  initiated: 'INITIATED',
  captured: 'CAPTURED',
} as const;

/** Fils to a Tap BHD amount with three decimals: 1900 -> 1.9 (serialised as "1.900" by Tap). */
function filsToBhd(fils: number): number {
  return Number((fils / 1000).toFixed(3));
}

/** One month or one year after `start`, by calendar. In step with the app's periodEnd. */
function periodEnd(term: 'monthly' | 'annual', start: Date): Date {
  const end = new Date(start);
  if (term === 'annual') end.setUTCFullYear(end.getUTCFullYear() + 1);
  else end.setUTCMonth(end.getUTCMonth() + 1);
  return end;
}

/**
 * Verifies Tap's `X-Tap-Signature` header: HMAC-SHA256 of the RAW request body with the
 * webhook secret, hex-encoded, compared in constant time. Ported from the working `beyond`
 * verification, which is the only thing standing between a stranger and a free Pro plan.
 */
function verifyTapSignature(rawBody: string, header: string | undefined, secret: string): boolean {
  if (!header || !secret) return false;
  const expected = createHmac('sha256', secret).update(rawBody, 'utf8').digest('hex');
  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(header, 'utf8');
  return a.length === b.length && timingSafeEqual(a, b);
}

// ═════════════ 1. createCharge — keeps the secret key server-side ═════════════

/**
 * Creates a Tap charge and returns the redirect URL for the client to present.
 *
 * SECURITY: the client sends only a plan id and a term — never an amount. The
 * amount is resolved HERE from PLANS, so a tampered price in the app is ignored
 * because the server recomputes what is actually owed.
 */
export const createCharge = onCall(
  { secrets: [TAP_SECRET_KEY, TAP_MERCHANT_ID] },
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

    // POST to Tap. The amount is resolved HERE from PLANS, so a tampered price in the app is
    // ignored. Ported from the working `beyond` Tap integration (goSell hosted page): Tap wants
    // BHD as a decimal with three places, not fils.
    const tapBody = {
      amount: filsToBhd(amount),
      currency: TAP_CURRENCY,
      customer_initiated: true,
      threeDSecure: true,
      save_card: false,
      description: `StudyForge ${planId} (${term})`,
      metadata: { uid, planId, term, idempotencyKey },
      reference: { order: idempotencyKey, transaction: uid },
      merchant: TAP_MERCHANT_ID.value() ? { id: TAP_MERCHANT_ID.value() } : undefined,
      customer: request.auth?.token?.email
        ? { email: String(request.auth.token.email) }
        : undefined,
      source: { id: TAP_SOURCE_ALL },
      post: TAP_WEBHOOK_URL ? { url: TAP_WEBHOOK_URL } : undefined,
      redirect: { url: TAP_RETURN_URL },
    };

    const tapResponse = await fetch(`${TAP_API}/`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${TAP_SECRET_KEY.value()}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(tapBody),
    });
    const charge = (await tapResponse.json()) as {
      id?: string;
      status?: string;
      redirect?: { url?: string };
      transaction?: { url?: string };
      errors?: unknown;
    };
    if (!tapResponse.ok || charge.errors) {
      throw new HttpsError('internal', `Tap charge failed (HTTP ${tapResponse.status}).`);
    }

    // Record the attempt, keyed by the Tap charge id, so the webhook can match it and a later
    // restore can read the outcome.
    await db.collection('payments').doc(String(charge.id)).set(
      {
        uid,
        plan: planId,
        term,
        amountFils: amount,
        currency: TAP_CURRENCY,
        status: charge.status ?? TAP_STATUS.initiated,
        tapChargeId: charge.id,
        idempotencyKey,
        redirectURL: charge.redirect?.url ?? charge.transaction?.url ?? null,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      tapChargeId: charge.id,
      redirectURL: charge.redirect?.url ?? charge.transaction?.url ?? null,
      status: charge.status ?? null,
    };
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

    // 1. Verify the X-Tap-Signature HMAC-SHA256 over the RAW body. Fail closed: no valid
    //    signature, no entitlement, ever.
    const raw = req.rawBody?.toString('utf8') ?? '';
    const signature = req.get('X-Tap-Signature') ?? undefined;
    if (!verifyTapSignature(raw, signature, TAP_WEBHOOK_SECRET.value())) {
      res.status(401).send('Invalid signature');
      return;
    }

    // 2. Parse and read the charge.
    let payload: {
      id?: string;
      status?: string;
      amount?: number;
      currency?: string;
      metadata?: { uid?: string; planId?: string; term?: string };
    };
    try {
      payload = JSON.parse(raw);
    } catch {
      res.status(400).send('Malformed JSON');
      return;
    }

    const chargeId = String(payload.id ?? '');
    if (!chargeId) {
      res.status(400).send('Missing charge id');
      return;
    }

    // 3. Only a CAPTURED charge grants an entitlement. Anything else is acknowledged and ignored
    //    (Tap retries are cheap; we answer inside the 2-second window).
    if (payload.status !== TAP_STATUS.captured) {
      res.status(200).send('ignored');
      return;
    }

    const meta = payload.metadata ?? {};
    const uid = meta.uid;
    const planId = meta.planId;
    const term = meta.term === 'annual' ? 'annual' : 'monthly';
    if (!uid || !planId || !PLANS[planId]) {
      res.status(400).send('Missing order metadata');
      return;
    }

    // 4. RE-RESOLVE the amount from PLANS and reject a payload that disagrees, so a tampered
    //    notification cannot buy Pro for one fils.
    const expectedFils = PLANS[planId]![term];
    if (Number(payload.amount) !== filsToBhd(expectedFils) || payload.currency !== TAP_CURRENCY) {
      res.status(409).send('Amount mismatch');
      return;
    }

    // 5. Idempotent write, keyed on the charge id, then mirror the plan into a custom claim.
    const now = new Date();
    const end = periodEnd(term, now);

    await db.runTransaction(async (tx) => {
      const payRef = db.collection('payments').doc(chargeId);
      const snap = await tx.get(payRef);
      if (snap.exists && snap.get('status') === TAP_STATUS.captured) return; // already granted

      tx.set(
        payRef,
        {
          uid,
          plan: planId,
          term,
          amountFils: expectedFils,
          currency: TAP_CURRENCY,
          status: TAP_STATUS.captured,
          tapChargeId: chargeId,
          paidAt: now,
        },
        { merge: true },
      );
      tx.set(
        db.collection('subscriptions').doc(uid),
        {
          plan: planId,
          status: 'active',
          periodStart: now,
          periodEnd: end,
          tapChargeId: chargeId,
          autoRenews: true,
          updatedAt: now,
        },
        { merge: true },
      );
      tx.set(db.collection('auditLog').doc(), {
        actor: 'tap-webhook',
        action: 'entitlement.granted',
        uid,
        plan: planId,
        tapChargeId: chargeId,
        at: now,
      });
    });

    await getAuth().setCustomUserClaims(uid, { plan: planId });

    // 6. 200 only after the writes commit, so Tap retries on a failure.
    res.status(200).send('ok');
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
    // TODO(M3 · F07): for each user active in the last 24h:
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

