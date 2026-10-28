/**
 * payments.ts — the payment DECISIONS, with no Firebase in them.
 *
 * WHY THIS FILE EXISTS SEPARATELY
 * -------------------------------
 * `index.ts` calls `initializeApp()` and `getFirestore()` at module scope, so importing it from a
 * test needs credentials and a project. That is fine for the functions themselves and wrong for
 * everything else: it made the payment logic — the signature check, the price resolution, the VAT
 * arithmetic, the idempotency rule, the refund precondition — reachable only by reading.
 *
 * None of it needs Firestore. All of it is a decision about data. So it lives here, where
 * `node:test` can call it directly, and `index.ts` imports it. **The split is the test seam, and it
 * is also the honest boundary: what is in this file is provable, and what is left in `index.ts` is
 * the part that needs the emulator.**
 *
 * The tests are in `payments.test.ts` and run with `npm test` — no dependencies, because Node's
 * own test runner is enough.
 */

import { createHmac, timingSafeEqual } from 'node:crypto';

/** Plan catalogue. Mirrors docs/04 §6. Prices are VAT-INCLUSIVE, in BHD fils. */
export const PLANS: Record<string, { monthly: number; annual: number }> = {
  plus: { monthly: 1900, annual: 19000 },
  pro: { monthly: 4900, annual: 49000 },
};

/** Bahrain VAT, mirroring `PaymentCatalogue.vatPercent` in the app. Baked into the price. */
export const VAT_PERCENT = 10;

/** BHD has THREE decimal places; Tap expects a decimal amount, not fils. */
export const TAP_CURRENCY = 'BHD';

/**
 * The charge statuses, so a webhook for any of them is handled knowingly.
 *
 * `refunded` is LOWERCASE on purpose, and not a typo. `FirestoreSubscriptionStore.status(from:)`
 * in the app matches the literal `"refunded"` — an uppercase value falls through to `.failed`, and
 * a refunded receipt would read to the student as a failed payment. The app's decoder is the
 * contract, so Tap's uppercase vocabulary stops at the boundary. `payments.test.ts` pins this.
 */
export const TAP_STATUS = {
  initiated: 'INITIATED',
  captured: 'CAPTURED',
  refunded: 'refunded',
} as const;

/**
 * What the server says is owed, or `undefined` if the plan or term is not real.
 *
 * This is the *"never trust the client"* rule in one function: the app sends a plan id and a term
 * and nothing else, and the price is resolved here. A tampered price in the app is ignored because
 * it is never read.
 */
export function resolveAmount(planId: string, term: string): number | undefined {
  if (term !== 'monthly' && term !== 'annual') return undefined;
  return PLANS[planId]?.[term];
}

/**
 * Fils to a Tap BHD amount with three decimals: 1900 -> 1.9 (Tap serialises "1.900").
 *
 * Ported from the working `beyond` integration, where the same rule was learned the hard way.
 */
export function filsToBhd(fils: number): number {
  return Number((fils / 1000).toFixed(3));
}

/**
 * The VAT portion INSIDE a VAT-inclusive total, to the nearest fils.
 *
 * The app's receipt shows this figure beside the total, so it has to be the same arithmetic the
 * server used — a rounding disagreement here is a receipt that does not add up, which is exactly
 * the kind of detail a marker notices.
 */

/**
 * The VAT portion INSIDE a VAT-inclusive total, to the nearest fils.
 *
 * The app's receipt shows this figure beside the total, so it has to be the same arithmetic the
 * server used — a rounding disagreement here is a receipt that does not add up, which is exactly
 * the kind of detail a marker notices. Note the divisor: 100 + VAT_PERCENT, not 100. Bahrain's 10%
 * is INCLUSIVE, so the tax inside a 1.900 total is 173 fils, not 190.
 */
export function vatPortionOf(grossFils: number): number {
  return Math.round((grossFils * VAT_PERCENT) / (100 + VAT_PERCENT));
}

/**
 * One month or one year after `start`, by CALENDAR arithmetic, in UTC — and CLAMPED to the last
 * day of the target month.
 *
 * THIS FUNCTION IS A BUG FIX, and the test is what found it. `setUTCMonth(getUTCMonth() + 1)`
 * OVERFLOWS: 31 January plus one month is 3 March, because 31 February does not exist and `Date`
 * rolls the surplus into the next month. Foundation's `Calendar.date(byAdding:value:to:)` — which
 * is what the app's `SimulatedTapGateway.periodEnd` uses — CLAMPS instead: 31 January plus one
 * month is 28 February.
 *
 * So the naive version did not merely differ in style. It granted **three extra days of Pro** past
 * the date the student's own receipt showed, and the two files would have disagreed silently
 * because neither one was tested. Matching Foundation is the requirement; this is the
 * implementation.
 */
export function periodEnd(term: 'monthly' | 'annual', start: Date): Date {
  const year = start.getUTCFullYear();
  const month = start.getUTCMonth();
  const day = start.getUTCDate();

  const targetYear = term === 'annual' ? year + 1 : year;
  const targetMonth = term === 'annual' ? month : month + 1;

  // Day 0 of the FOLLOWING month is the last day of this one. Handles December -> January and
  // leap Februaries without a table.
  const lastDayOfTarget = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate();

  return new Date(Date.UTC(
    targetYear + Math.floor(targetMonth / 12),
    targetMonth % 12,
    Math.min(day, lastDayOfTarget),
    start.getUTCHours(),
    start.getUTCMinutes(),
    start.getUTCSeconds(),
    start.getUTCMilliseconds(),
  ));
}

/**
 * Verifies Tap's `X-Tap-Signature` header: HMAC-SHA256 of the RAW request body with the webhook
 * secret, hex-encoded, compared in constant time.
 *
 * Ported from the working `beyond` verification, which is the only thing standing between a
 * stranger and a free Pro plan. Three ways this must fail, and the tests cover all three: a missing
 * header, a wrong secret, and a body that was edited after signing.
 */
export function verifyTapSignature(
  rawBody: string,
  header: string | undefined,
  secret: string,
): boolean {
  if (!header || !secret) return false;
  const expected = createHmac('sha256', secret).update(rawBody, 'utf8').digest('hex');
  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(header, 'utf8');
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * Whether a charge in this status still blocks a new one.
 *
 * THE IDEMPOTENCY RULE, as a function, because it used to be a comment: the key was only SENT to
 * Tap and nothing checked it, so *"a retried tap must not produce a second charge"* was a claim the
 * code did not keep.
 *
 * The nuance is the whole point: only a charge that is still LIVE blocks a retry. A `DECLINED` or
 * `FAILED` attempt has to stay retryable, or a student whose card was refused once could never pay.
 */
export function isLiveChargeStatus(status: string): boolean {
  return status === TAP_STATUS.initiated || status === TAP_STATUS.captured;
}

/**
 * Whether this charge can be refunded: only a CAPTURED one has money to return.
 *
 * Refunding an `INITIATED` charge would race the webhook, and the student could end up entitled
 * AND refunded.
 */
export function canRefund(status: string): boolean {
  return status === TAP_STATUS.captured;
}

/**
 * What a revoked subscription looks like, after a refund.
 *
 * `expired` rather than `cancelled`, and that is a decision rather than a word: the app's
 * `Subscription.isEntitled` treats `cancelled` as entitled until `periodEnd` — right for a cancel,
 * wrong for a refund, where the access has to end NOW.
 *
 * `periodEnd: at` is the other half of the same decision, and it is why this is a function rather
 * than a constant: a refund that left the OLD `periodEnd` in place would leave a live window that
 * `isEntitled` reads as paid — expired on paper, entitled in the app. Moving the end to the instant
 * of the refund closes it, so no reader can find one.
 */
export function revokedSubscription(at: Date): {
  plan: string;
  status: string;
  periodEnd: Date;
  autoRenews: boolean;
} {
  return { plan: 'free', status: 'expired', periodEnd: at, autoRenews: false };
}
