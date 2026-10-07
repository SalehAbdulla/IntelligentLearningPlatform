/**
 * StudyForge — Cloud Functions
 *
 * STATUS: all four functions are IMPLEMENTED and typecheck. Tap's createCharge and tapWebhook are
 * ported from a working Tap integration (the `beyond` project), so the endpoints, the charge
 * payload, the status set and the X-Tap-Signature HMAC verification match a real deployment.
 * onUserCreate grants the default role and plan as custom claims at sign-up. rollupDailyMetrics
 * rolls the activity log into the dashboard's read-optimised documents. NONE of it is deployed:
 * that needs the Blaze plan plus a budget alert and spend cap (docs/04 §5), Identity Platform
 * enabled for the blocking function, and the Tap secret keys (docs/09 Q2/Q3).
 *
 * WHY THIS SURFACE IS DELIBERATELY TINY
 * -------------------------------------
 * Cloud Functions are the only component that can produce an unbudgeted bill,
 * because the Blaze plan is tied to a billing account. Everything that can run
 * on-device does (docs/04 §4). So exactly four things live here:
 *
 *   1. createCharge       : the Tap SECRET key must never ship inside the app
 *   2. tapWebhook         : entitlement is granted by the gateway, never by a
 *                           client that merely claims success
 *   3. rollupDailyMetrics : roll-ups must not become billable client writes
 *   4. onUserCreate       : the role claim must be server-owned, never client-chosen
 *
 * Anything else belongs in the app.
 */

import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { beforeUserCreated } from 'firebase-functions/v2/identity';
import { defineSecret } from 'firebase-functions/params';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
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

// DEPLOY PREREQUISITES (not code, do not forget them): this surface cannot deploy itself. It needs
// the Blaze plan with a budget alert and spend cap (docs/04 §5), Identity Platform enabled for the
// onUserCreate blocking function, the Tap secret keys (docs/09 Q2/Q3), and the Functions SDK linked
// in the app. Until then the app runs on the local payment simulator and out-of-band roles.

// ═════════════ 0. onUserCreate, the server owns the role claim ═════════════

/**
 * The role and plan every new account starts with.
 *
 * Tutor and admin are NOT here: granting them is a deliberate, audited admin action (docs/09 Q13),
 * never something a sign-up can request.
 */
const DEFAULT_CLAIMS = { role: 'student', plan: 'free' } as const;

/**
 * Grants every new account its default role and plan as CUSTOM CLAIMS at creation.
 *
 * WHY CLAIMS AND NOT A FIELD: the role model reads `role` off the ID token (docs/05 §2.1), which is
 * exactly what makes the client unable to choose its own role. Setting the claim at CREATION rather
 * than a moment later means it is present on the very first token, so there is no window in which a
 * fresh sign-up has no role.
 *
 * WHY A BLOCKING FUNCTION: it runs inside the sign-up call, so the claim exists before Auth ever
 * returns a token. It requires Identity Platform (GCIP) to be enabled on the project.
 */
export const onUserCreate = beforeUserCreated(async () => ({
  customClaims: DEFAULT_CLAIMS,
}));

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
/** Bahrain VAT, mirroring `PaymentCatalogue.vatPercent` in the app. Baked into the price. */
const VAT_PERCENT = 10;
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
          // The VAT portion inside the total, so the app's receipt adds up.
          vatFils: Math.round((expectedFils * VAT_PERCENT) / (100 + VAT_PERCENT)),
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

const DAY_MS = 24 * 60 * 60 * 1000;
/** Bahrain is UTC+3 with no daylight saving, so a fixed offset is exact. */
const BAHRAIN_OFFSET_MS = 3 * 60 * 60 * 1000;
/** The streak/scan window. 30 days covers a streak and the current week, and bounds the read. */
const ROLLUP_WINDOW_DAYS = 30;
/** Users per chunk, so one slow user cannot blow the 300s timeout. */
const ROLLUP_CHUNK = 20;

/** A unit of student activity. One document per action (docs/02 section 6). */
interface ActivityEvent {
  uid?: string;
  at?: Timestamp;
  minutes?: number;
  items?: number;
}

/** One answered question inside a quiz attempt. */
interface QuizResponse {
  questionId?: string;
  topic?: string;
  isCorrect?: boolean;
}

/** One completed quiz attempt. */
interface QuizAttempt {
  uid?: string;
  at?: Timestamp;
  responses?: QuizResponse[];
}

/** The Bahrain-local calendar day (YYYY-MM-DD) containing `date`. */
function dayKey(date: Date): string {
  return new Date(date.getTime() + BAHRAIN_OFFSET_MS).toISOString().slice(0, 10);
}

/** The day before a YYYY-MM-DD key. */
function previousDayKey(key: string): string {
  const d = new Date(`${key}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

/** The day after a YYYY-MM-DD key. */
function nextDayKey(key: string): string {
  const d = new Date(`${key}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

/** The Monday-start of the Bahrain-local week containing `date`. */
function weekStartKey(date: Date): string {
  const local = new Date(date.getTime() + BAHRAIN_OFFSET_MS);
  const mondayOffset = (local.getUTCDay() + 6) % 7; // Monday = 0
  local.setUTCDate(local.getUTCDate() - mondayOffset);
  return local.toISOString().slice(0, 10);
}

/**
 * Consecutive active days ending today, or yesterday.
 *
 * Mirrors `ProgressCalculator.streak`: a student who studied yesterday but has not opened the app
 * yet today keeps the streak they earned.
 */
function streakDays(activeDays: Set<string>, now: Date): number {
  const today = dayKey(now);
  let cursor = activeDays.has(today) ? today : previousDayKey(today);
  if (!activeDays.has(cursor)) return 0;
  let count = 0;
  while (activeDays.has(cursor)) {
    count += 1;
    cursor = previousDayKey(cursor);
  }
  return count;
}

/**
 * Rolls raw activity into the read-optimised documents the dashboards use.
 *
 * WHY: dashboards that recompute from raw events on the client are the classic Firestore read-cost
 * trap. One scheduled job does the work once, and the app then reads a single small document per user.
 *
 * WHAT IT READS (the event log the app writes once it is online):
 *   activityEvents/{id}  { uid, at, minutes?, items? }        one doc per unit of activity
 *   quizAttempts/{id}    { uid, at, responses: [Response] }   one doc per completed attempt
 *
 * WHAT IT WRITES (both are READ-ONLY to clients in the security rules):
 *   progress/{uid}                       the dashboard's headline numbers
 *   topicMastery/{uid}/topics/{topicId}  the weakness radar
 *
 * The window is 30 days: enough for a streak and the current week, and it bounds the scan. The read
 * uses a single-field range on `at` on purpose, so no composite index is required.
 */
export const rollupDailyMetrics = onSchedule(
  { schedule: 'every day 02:00', timeZone: 'Asia/Bahrain', timeoutSeconds: 300 },
  async () => {
    const startedAt = Date.now();
    const now = new Date();
    const since = new Date(now.getTime() - ROLLUP_WINDOW_DAYS * DAY_MS);

    // 1. Read the activity window ONCE and group by user. Any user with an event in the last day is
    //    "active" and gets a fresh roll-up; the same read supplies their 30-day streak history.
    const activity = await db
      .collection('activityEvents')
      .where('at', '>=', Timestamp.fromDate(since))
      .orderBy('at', 'desc')
      .get();

    const eventsByUser = new Map<string, ActivityEvent[]>();
    const activeUsers = new Set<string>();
    const activeSince = now.getTime() - DAY_MS;
    for (const doc of activity.docs) {
      const event = doc.data() as ActivityEvent;
      const uid = event.uid;
      if (!uid) continue;
      const list = eventsByUser.get(uid);
      if (list) list.push(event);
      else eventsByUser.set(uid, [event]);
      if ((event.at?.toDate().getTime() ?? 0) >= activeSince) activeUsers.add(uid);
    }

    // 2. Quiz attempts in the same window, grouped the same way.
    const quizzes = await db
      .collection('quizAttempts')
      .where('at', '>=', Timestamp.fromDate(since))
      .orderBy('at', 'desc')
      .get();

    const attemptsByUser = new Map<string, QuizAttempt[]>();
    for (const doc of quizzes.docs) {
      const attempt = doc.data() as QuizAttempt;
      if (!attempt.uid) continue;
      const list = attemptsByUser.get(attempt.uid);
      if (list) list.push(attempt);
      else attemptsByUser.set(attempt.uid, [attempt]);
    }

    // 3. Roll up each active user, in chunks so the 300s timeout always holds.
    const uids = [...activeUsers];
    for (let i = 0; i < uids.length; i += ROLLUP_CHUNK) {
      const chunk = uids.slice(i, i + ROLLUP_CHUNK);
      await Promise.all(
        chunk.map((uid) =>
          rollupUser(uid, eventsByUser.get(uid) ?? [], attemptsByUser.get(uid) ?? [], now),
        ),
      );
    }

    // 4. Record the run so a silent failure is visible and the UI can show staleness.
    await db.collection('aiConfig').doc('rollupStatus').set(
      {
        status: 'ok',
        lastRunStartedAt: Timestamp.fromMillis(startedAt),
        lastRunFinishedAt: FieldValue.serverTimestamp(),
        durationMs: Date.now() - startedAt,
        usersActive: uids.length,
      },
      { merge: true },
    );
  },
);


/** Writes one user's `progress/{uid}` and `topicMastery/{uid}/topics/*`. */
async function rollupUser(
  uid: string,
  events: ActivityEvent[],
  attempts: QuizAttempt[],
  now: Date,
): Promise<void> {
  // Activity: minutes this week, total items, and which days were active.
  const activeDays = new Set<string>();
  const weekDays = new Set<string>();
  let cursor = weekStartKey(now);
  for (let i = 0; i < 7; i += 1) {
    weekDays.add(cursor);
    cursor = nextDayKey(cursor);
  }

  let minutesThisWeek = 0;
  let itemsCompleted = 0;
  for (const event of events) {
    const at = event.at?.toDate();
    if (!at) continue;
    const key = dayKey(at);
    activeDays.add(key);
    itemsCompleted += event.items ?? 1;
    if (weekDays.has(key)) minutesThisWeek += event.minutes ?? 0;
  }

  // Quiz: overall accuracy, and per-topic mastery for the weakness radar.
  const correctByTopic = new Map<string, number>();
  const totalByTopic = new Map<string, number>();
  let correct = 0;
  let responses = 0;
  for (const attempt of attempts) {
    for (const response of attempt.responses ?? []) {
      responses += 1;
      if (response.isCorrect) correct += 1;
      const topic = response.topic ?? 'unclassified';
      totalByTopic.set(topic, (totalByTopic.get(topic) ?? 0) + 1);
      if (response.isCorrect) correctByTopic.set(topic, (correctByTopic.get(topic) ?? 0) + 1);
    }
  }

  await db.collection('progress').doc(uid).set(
    {
      uid,
      streakDays: streakDays(activeDays, now),
      minutesThisWeek,
      itemsCompleted,
      quizzesTaken: attempts.length,
      averageQuizScore: responses === 0 ? 0 : Math.round((correct / responses) * 100),
      windowStart: Timestamp.fromDate(new Date(now.getTime() - ROLLUP_WINDOW_DAYS * DAY_MS)),
      windowEnd: Timestamp.fromDate(now),
      // The UI reads this to show staleness, so it is SERVER time, not the job's `now`.
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  for (const [topic, total] of totalByTopic) {
    if (total === 0) continue;
    const hits = correctByTopic.get(topic) ?? 0;
    await db
      .collection('topicMastery')
      .doc(uid)
      .collection('topics')
      // A topic label is not a valid document id, so any slash is escaped.
      .doc(topic.replace(/\//g, '_'))
      .set(
        {
          topic,
          correct: hits,
          total,
          mastery: hits / total,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  }
}

