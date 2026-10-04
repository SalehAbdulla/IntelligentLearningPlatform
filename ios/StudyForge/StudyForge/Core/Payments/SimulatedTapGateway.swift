//
//  SimulatedTapGateway.swift
//  StudyForge
//
//  F13 — a deterministic stand-in for the Tap sandbox and its webhook (docs/04 §6).
//
//  WHAT THIS IS, AND WHAT IT IS NOT
//  --------------------------------
//  It is NOT a mock. A mock returns canned values; this models the REAL sequence the
//  production gateway performs, and it writes the entitlement itself exactly as the
//  webhook does — because the property the feature is really about is that the ENTITLEMENT
//  IS WRITTEN SERVER-SIDE and the app merely observes it (docs/04 §6 point 3). A gateway
//  that returned a success without persisting would let the UI show a plan the account
//  does not have, and the whole "the client is never trusted" claim would be a comment
//  rather than behaviour.
//
//  WHY IT EXISTS AT ALL
//  --------------------
//  The Tap iOS SDK is not integrated, and no Blaze plan means `createCharge`/`tapWebhook`
//  cannot deploy (docs/09 D22). Without this, F13 has no demonstrable happy path — the
//  same reason `MockProvider` serves tier-1 AI in the Simulator. Swapping in the real
//  `TapPaymentsGateway` is a one-line change in `AppContainer`, which is the point of the
//  protocol.
//
//  THE THREE PROPERTIES IT PROVES
//  ------------------------------
//  1. **Idempotency.** Replaying the same order (same key) returns the ORIGINAL charge
//     instead of taking the money again.
//  2. **Server authority.** A success returns the entitlement the gateway persisted, not
//     one the caller handed in.
//  3. **Graceful failure.** An injected decline returns a typed reason and writes NO
//     entitlement — so a failed payment cannot leave a half-upgraded account.
//

import Foundation

actor SimulatedTapGateway: PaymentGateway {

    private let store: any SubscriptionStore

    /// How long the "processing" state lingers, so the flow is observable. Tests pass
    /// `.zero` and never wait.
    private let latency: Duration

    /// The next charge fails with this, until cleared. This is L09's failure path and the
    /// only way to reach it on demand.
    private var forcedFailure: PaymentFailureReason?

    /// Last-four shown on a simulated card receipt. Tap's documented sandbox card ends in
    /// 4242, so a screenshot of a test receipt is recognisably a test receipt.
    private let sandboxCardLast4 = "4242"

    init(store: any SubscriptionStore, latency: Duration = .milliseconds(700)) {
        self.store = store
        self.latency = latency
    }

    // MARK: PaymentGateway

    func startCheckout(order: Order, method: PaymentMethod) async throws -> PaymentOutcome {
        if latency > .zero {
            try? await Task.sleep(for: latency)
        }

        // 1. Idempotency. A retried tap on the same day reuses the charge that already
        //    happened rather than creating a second one (docs/04 §6 point 4).
        if let existing = try await store.succeededPayment(idempotencyKey: order.idempotencyKey),
           let subscription = try await store.subscription(for: order.uid) {
            return .succeeded(subscription: subscription, receipt: existing)
        }

        // 2. The injected decline. A failed attempt is recorded for an honest history, but
        //    NO entitlement is written — a decline must not leave a half-upgraded account.
        if let reason = forcedFailure {
            try await store.record(declineRecord(for: order, reason: reason, method: method))
            return .failed(reason)
        }

        // 3. Success: write the entitlement AND the receipt, in that order, exactly as the
        //    webhook does before it answers Tap 200.
        let now = Date.now
        let chargeId = "tap_test_\(UUID().uuidString.prefix(12))"

        let subscription = Subscription(
            id: order.uid,
            plan: order.plan,
            status: .active,
            periodStart: now,
            periodEnd: Self.periodEnd(for: order.term, from: now),
            tapChargeId: chargeId,
            autoRenews: true
        )

        let receipt = PaymentRecord(
            id: UUID().uuidString,
            uid: order.uid,
            plan: order.plan,
            term: order.term,
            amountFils: order.totalFils,
            vatFils: order.vatFils,
            currency: order.currency,
            method: method,
            last4: method == .card ? sandboxCardLast4 : nil,
            tapChargeId: chargeId,
            idempotencyKey: order.idempotencyKey,
            status: .succeeded,
            paidAt: now
        )

        try await store.upsert(subscription)
        try await store.record(receipt)

        return .succeeded(subscription: subscription, receipt: receipt)
    }

    func restoreEntitlements(uid: String) async throws -> Subscription? {
        try await store.subscription(for: uid)
    }

    // MARK: Controls

    /// Makes the next checkout fail with `reason`. Pass `nil` to restore success.
    func forceFailure(_ reason: PaymentFailureReason?) {
        forcedFailure = reason
    }

    // MARK: Helpers

    /// One month for a monthly term, one year for an annual one, by CALENDAR arithmetic —
    /// not "add 30/365 days", which drifts across months and leap years.
    static func periodEnd(for term: BillingTerm, from start: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar.date(
            byAdding: term == .annual ? .year : .month,
            value: 1,
            to: start
        ) ?? start
    }

    /// The record left behind by a decline. `status: .failed`, and a charge id that is
    /// clearly not a real reference, so a failed attempt can never be mistaken for a
    /// receipt.
    private func declineRecord(
        for order: Order,
        reason: PaymentFailureReason,
        method: PaymentMethod
    ) -> PaymentRecord {
        PaymentRecord(
            id: UUID().uuidString,
            uid: order.uid,
            plan: order.plan,
            term: order.term,
            amountFils: order.totalFils,
            vatFils: order.vatFils,
            currency: order.currency,
            method: method,
            last4: nil,
            tapChargeId: "declined_\(reason.rawValue)",
            idempotencyKey: order.idempotencyKey,
            status: .failed,
            paidAt: .now
        )
    }
}


