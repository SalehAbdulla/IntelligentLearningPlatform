/**
 * payments.test.ts — the payment DECISIONS, tested.
 *
 * `npm test` compiles with tsc and runs these on Node's own test runner. No Jest, no Vitest, no
 * new dependency: `node:test` is in the runtime, and the point of this file is that the payment
 * rules are provable WITHOUT a Firebase project, credentials, an emulator or a network.
 *
 * WHAT THIS DOES NOT COVER, stated plainly so nobody reads more into a green run than is there:
 * the Firestore TRANSACTIONS (claiming a charge, writing the entitlement, revoking on refund) and
 * the HTTP calls to Tap. Those need the emulator and are exercised by hand against the simulator.
 * Everything here is a decision about data — which is the part that was previously reachable only
 * by reading.
 *
 * TWO OF THESE TESTS READ THE APP'S SWIFT. That is deliberate. The price table and the status
 * vocabulary are a CONTRACT between two languages that neither compiler can check, and
 * `PaymentCatalogue.swift` says so itself: "Keeping the two tables identical is a review checklist
 * item". A checklist item that only a human can catch is a checklist item that drifts. Now it
 * fails a test instead.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  PLANS,
  TAP_CURRENCY,
  TAP_STATUS,
  VAT_PERCENT,
  canRefund,
  filsToBhd,
  isLiveChargeStatus,
  periodEnd,
  resolveAmount,
  revokedSubscription,
  vatPortionOf,
  verifyTapSignature,
} from './payments.js';

const SECRET = 'whsec_test_only_not_a_real_secret';
const sign = (body: string, secret = SECRET): string =>
  createHmac('sha256', secret).update(body, 'utf8').digest('hex');

const BODY = JSON.stringify({ id: 'chg_1', status: 'CAPTURED', amount: 1.9 });

// ─────────────────────────── the signature gate ───────────────────────────

describe('verifyTapSignature', () => {
  it('accepts a correctly signed body', () => {
    assert.equal(verifyTapSignature(BODY, sign(BODY), SECRET), true);
  });

  it('rejects a body edited after signing — the attack that matters', () => {
    const signed = sign(BODY);
    const tampered = BODY.replace('"amount":1.9', '"amount":0.001');
    assert.notEqual(tampered, BODY, 'the fixture must actually differ, or this proves nothing');
    assert.equal(verifyTapSignature(tampered, signed, SECRET), false);
  });

  it('rejects a signature made with a different secret', () => {
    assert.equal(verifyTapSignature(BODY, sign(BODY, 'someone_elses_secret'), SECRET), false);
  });

  it('rejects a missing or empty signature header', () => {
    assert.equal(verifyTapSignature(BODY, undefined, SECRET), false);
    assert.equal(verifyTapSignature(BODY, '', SECRET), false);
  });

  it('fails closed when the secret is unset, rather than accepting a signature of an empty key', () => {
    assert.equal(verifyTapSignature(BODY, sign(BODY, ''), ''), false);
    assert.equal(verifyTapSignature(BODY, sign(BODY, SECRET), ''), false);
  });

  it('returns false for a wrong-LENGTH signature instead of throwing', () => {
    // `timingSafeEqual` THROWS when the buffers differ in length, so the length guard in front of
    // it is load-bearing: without it a malformed header would 500 the webhook and Tap would retry
    // the delivery, which is the opposite of what a rejection should do.
    assert.equal(verifyTapSignature(BODY, 'abc', SECRET), false);
    assert.equal(verifyTapSignature(BODY, sign(BODY).slice(0, -1), SECRET), false);
    assert.equal(verifyTapSignature(BODY, `${sign(BODY)}00`, SECRET), false);
  });
});

// ──────────────────── the price, resolved server-side ────────────────────

describe('resolveAmount — the server owns the price', () => {
  it('resolves the four purchasable combinations', () => {
    assert.equal(resolveAmount('plus', 'monthly'), 1900);
    assert.equal(resolveAmount('plus', 'annual'), 19000);
    assert.equal(resolveAmount('pro', 'monthly'), 4900);
    assert.equal(resolveAmount('pro', 'annual'), 49000);
  });

  it('refuses an unknown plan rather than falling back to a default', () => {
    // The whole point of resolving server-side: a client that asks for a plan that is not sold
    // gets no price, not the cheapest one.
    assert.equal(resolveAmount('free', 'monthly'), undefined);
    assert.equal(resolveAmount('ultra', 'monthly'), undefined);
    assert.equal(resolveAmount('', 'monthly'), undefined);
  });

  it('refuses an unknown or differently-cased term', () => {
    assert.equal(resolveAmount('plus', 'weekly'), undefined);
    assert.equal(resolveAmount('plus', 'MONTHLY'), undefined);
    assert.equal(resolveAmount('plus', ''), undefined);
  });

  it('prices the annual term at exactly ten months — the 17% the badge advertises', () => {
    for (const [planId, price] of Object.entries(PLANS)) {
      assert.equal(price.annual, price.monthly * 10, `${planId}: annual is not ten months`);
      const saving = Math.round(((price.monthly * 12 - price.annual) / (price.monthly * 12)) * 100);
      assert.equal(saving, 17, `${planId}: the advertised saving is not the one charged`);
    }
  });
});

// ─────────────────────────── the money arithmetic ───────────────────────────

describe('filsToBhd', () => {
  it('converts the catalogue prices to three-decimal dinars', () => {
    assert.equal(filsToBhd(1900), 1.9);
    assert.equal(filsToBhd(19000), 19);
    assert.equal(filsToBhd(4900), 4.9);
    assert.equal(filsToBhd(49000), 49);
  });

  it('keeps the third decimal that two-decimal money would lose', () => {
    assert.equal(filsToBhd(1), 0.001);
    assert.equal(filsToBhd(999), 0.999);
    assert.equal(filsToBhd(1001), 1.001);
  });

  it('never emits more than three decimals, whatever the float does', () => {
    // 1900/1000 happens to be exact, but the division is not exact for every fils count, and a
    // value like 1.9000000000000001 serialises into a Tap request that is rejected.
    for (const fils of [1, 7, 13, 999, 1001, 1900, 4900, 19000, 49000, 123457]) {
      const decimals = String(filsToBhd(fils)).split('.')[1]?.length ?? 0;
      assert.ok(decimals <= 3, `${fils} fils became ${filsToBhd(fils)} (${decimals} decimals)`);
    }
  });
});

describe('vatPortionOf', () => {
  it('returns the VAT INSIDE the total, not on top of it', () => {
    // This is the assertion that catches the classic mistake. Bahrain's 10% is inclusive, so the
    // tax inside a 1.900 total is 173 fils, NOT 190 — dividing by 110 rather than by 100.
    assert.equal(vatPortionOf(1900), 173);
    assert.equal(vatPortionOf(4900), 445);
    assert.equal(vatPortionOf(19000), 1727);
    assert.equal(vatPortionOf(49000), 4455);
    assert.ok(vatPortionOf(1900) < 190, 'VAT must be inside the total, so below 10% of it');
  });

  it('is zero for a zero total and never negative', () => {
    assert.equal(vatPortionOf(0), 0);
    for (const fils of [1, 9, 10, 99, 1900]) assert.ok(vatPortionOf(fils) >= 0);
  });

  it('leaves a net + VAT pair that adds back to the gross, to the fils', () => {
    for (const gross of [1900, 4900, 19000, 49000]) {
      const vat = vatPortionOf(gross);
      assert.equal(vat + (gross - vat), gross);
      assert.ok(vat > 0 && vat < gross);
    }
  });
});

// ───────────────────────────── the billing period ─────────────────────────────

describe('periodEnd — calendar arithmetic that matches Foundation', () => {
  it('adds one month, keeping the time of day', () => {
    assert.equal(
      periodEnd('monthly', new Date('2026-01-15T10:30:00.000Z')).toISOString(),
      '2026-02-15T10:30:00.000Z',
    );
  });

  it('adds one year', () => {
    assert.equal(
      periodEnd('annual', new Date('2026-01-15T10:30:00.000Z')).toISOString(),
      '2027-01-15T10:30:00.000Z',
    );
  });

  it('CLAMPS to the last day of the target month, as Foundation does', () => {
    // The bug this function exists to not have. `setUTCMonth(+1)` overflows 31 January into
    // 3 March, handing out three extra days of Pro past the date on the student's own receipt.
    assert.equal(
      periodEnd('monthly', new Date('2026-01-31T00:00:00.000Z')).toISOString(),
      '2026-02-28T00:00:00.000Z',
    );
    assert.equal(
      periodEnd('monthly', new Date('2026-03-31T00:00:00.000Z')).toISOString(),
      '2026-04-30T00:00:00.000Z',
    );
    assert.equal(
      periodEnd('monthly', new Date('2026-05-31T00:00:00.000Z')).toISOString(),
      '2026-06-30T00:00:00.000Z',
    );
  });

  it('clamps into a leap February, and out of one', () => {
    assert.equal(
      periodEnd('monthly', new Date('2024-01-31T00:00:00.000Z')).toISOString(),
      '2024-02-29T00:00:00.000Z',
    );
    assert.equal(
      periodEnd('annual', new Date('2024-02-29T00:00:00.000Z')).toISOString(),
      '2025-02-28T00:00:00.000Z',
    );
  });

  it('rolls December into the next January, at both ends of the month', () => {
    assert.equal(
      periodEnd('monthly', new Date('2026-12-15T00:00:00.000Z')).toISOString(),
      '2027-01-15T00:00:00.000Z',
    );
    assert.equal(
      periodEnd('monthly', new Date('2026-12-31T00:00:00.000Z')).toISOString(),
      '2027-01-31T00:00:00.000Z',
    );
  });

  it('always advances, for every day of a year', () => {
    for (let month = 0; month < 12; month += 1) {
      for (const day of [1, 15, 27, 28, 29, 30, 31]) {
        const start = new Date(Date.UTC(2026, month, day, 12));
        // Skip days that do not exist, so the fixture cannot silently roll into another month.
        if (start.getUTCMonth() !== month) continue;
        assert.ok(periodEnd('monthly', start) > start, `${start.toISOString()} monthly stalled`);
        assert.ok(periodEnd('annual', start) > start, `${start.toISOString()} annual stalled`);
      }
    }
  });
});

// ───────────────────── the two decisions that gate money ─────────────────────

describe('isLiveChargeStatus — the idempotency rule', () => {
  it('blocks a retry while the charge is still live', () => {
    assert.equal(isLiveChargeStatus(TAP_STATUS.initiated), true);
    assert.equal(isLiveChargeStatus(TAP_STATUS.captured), true);
  });

  it('leaves a refused attempt retryable, so a declined card can pay', () => {
    // The nuance that makes this a rule rather than a blanket "a row exists, refuse". A student
    // whose card was declined once has to be able to try again.
    assert.equal(isLiveChargeStatus('DECLINED'), false);
    assert.equal(isLiveChargeStatus('FAILED'), false);
    assert.equal(isLiveChargeStatus('CANCELLED'), false);
  });

  it('does not treat a refunded charge as live', () => {
    assert.equal(isLiveChargeStatus(TAP_STATUS.refunded), false);
  });

  it('lets an unrecognised status through, which is the trade-off it chose', () => {
    // Named rather than hidden: an unknown status does NOT block. The alternative — refusing on
    // anything not on a list — locks a student out of paying forever the day Tap adds a status.
    // A retry that reaches Tap is recoverable; a permanently unpayable account is not.
    assert.equal(isLiveChargeStatus(''), false);
    assert.equal(isLiveChargeStatus('SOMETHING_TAP_ADDED_LATER'), false);
  });
});

describe('canRefund', () => {
  it('allows a captured charge, which is the only one holding money', () => {
    assert.equal(canRefund(TAP_STATUS.captured), true);
  });

  it('refuses an initiated charge, which would race the webhook', () => {
    // Refunding before capture can leave a student entitled AND refunded.
    assert.equal(canRefund(TAP_STATUS.initiated), false);
  });

  it('refuses a declined charge and a second refund of the same charge', () => {
    assert.equal(canRefund('DECLINED'), false);
    assert.equal(canRefund(TAP_STATUS.refunded), false);
    assert.equal(canRefund(''), false);
  });
});

describe('revokedSubscription', () => {
  const at = new Date('2026-06-01T09:00:00.000Z');

  it('drops the plan to free and EXPIRES it, not cancels it', () => {
    // `cancelled` reads as entitled-until-periodEnd in `Subscription.isEntitled`; a refund has to
    // end the access at once, so this value is load-bearing rather than cosmetic.
    const revoked = revokedSubscription(at);
    assert.equal(revoked.plan, 'free');
    assert.equal(revoked.status, 'expired');
    assert.notEqual(revoked.status, 'cancelled');
    assert.equal(revoked.autoRenews, false);
  });

  it('ends the period AT the refund, leaving no live window behind', () => {
    // The subtle half: leaving the old periodEnd in place would read as entitled on paper.
    assert.equal(revokedSubscription(at).periodEnd.getTime(), at.getTime());
  });
});

// ──────────────── the contract between the app and the server ────────────────

/**
 * These tests read the app's SWIFT SOURCE, which is unusual and deliberate.
 *
 * The price table, the VAT rate, the currency code and the `refunded` status are a contract
 * between Swift and TypeScript that neither compiler can see. `PaymentCatalogue.swift` says as
 * much in its own header: *"Keeping the two tables identical is a review checklist item."* A
 * checklist item that only a human can catch is one that drifts — and what it produces is a
 * receipt that disagrees with the charge, which is the worst bug this flow could ship.
 *
 * So they are tests now. If a rename breaks one of these regexes, the failure says which file and
 * what to do; a silent pass is not possible.
 */

const APP_ROOT = 'ios/StudyForge/StudyForge/Core/Payments';
const readApp = (file: string): string =>
  readFileSync(join(fileURLToPath(new URL('../../../', import.meta.url)), APP_ROOT, file), 'utf8');

/** Parses `case (.plus, .monthly): 1_900` out of the app's price switch. */
function appPriceTable(): Record<string, number> {
  const table: Record<string, number> = {};
  const cases = readApp('PaymentCatalogue.swift')
    .matchAll(/case\s*\(\s*\.(\w+)\s*,\s*\.(\w+)\s*\)\s*:\s*([\d_]+)/g);
  for (const match of cases) {
    const [, plan, term, raw] = match;
    if (!plan || !term || !raw) continue;
    table[`${plan}.${term}`] = Number(raw.replace(/_/g, ''));
  }
  return table;
}

describe('the app and the server agree (the contract neither compiler can check)', () => {
  it('prices every plan identically', () => {
    const app: Record<string, number> = appPriceTable();
    assert.deepEqual(
      app,
      { 'plus.monthly': 1900, 'plus.annual': 19000, 'pro.monthly': 4900, 'pro.annual': 49000 },
      'the app price table moved and the server table did not follow',
    );
    // A fresh binding, because `assert.deepEqual` narrows `app` to the literal type above and a
    // template-string index no longer fits it.
    const prices: Record<string, number> = app;
    for (const [planId, price] of Object.entries(PLANS)) {
      assert.ok(price.annual > price.monthly, `${planId}: a year must cost more than a month`);
      assert.equal(resolveAmount(planId, 'monthly'), prices[`${planId}.monthly`]);
      assert.equal(resolveAmount(planId, 'annual'), prices[`${planId}.annual`]);
    }
  });

  it('sells no annual term for the free plan, on either side', () => {
    assert.equal(resolveAmount('free', 'annual'), undefined);
    assert.equal(appPriceTable()['free.annual'], undefined);
  });

  it('uses the same VAT rate', () => {
    const match = /static let vatPercent = (\d+)/.exec(readApp('PaymentCatalogue.swift'));
    assert.ok(match, 'PaymentCatalogue.vatPercent was renamed or removed — update this test');
    assert.equal(VAT_PERCENT, Number(match[1]));
  });

  it('uses the same currency code', () => {
    const match = /static let bhd = "([A-Z]+)"/.exec(readApp('PaymentCatalogue.swift'));
    assert.ok(match, 'MoneyCurrency.bhd was renamed or removed — update this test');
    assert.equal(TAP_CURRENCY, match[1]);
  });

  it('writes the refunded status in the exact case the app decodes', () => {
    // `FirestoreSubscriptionStore` maps the literal "refunded" to `.refunded`; anything else falls
    // through to `.failed`, and a refunded student would be shown a FAILED payment.
    const store = readApp('FirestoreSubscriptionStore.swift');
    assert.ok(
      store.includes(`case "${TAP_STATUS.refunded}": .refunded`),
      'the app no longer decodes the status the server writes — a refund would read as a failure',
    );
  });
});
