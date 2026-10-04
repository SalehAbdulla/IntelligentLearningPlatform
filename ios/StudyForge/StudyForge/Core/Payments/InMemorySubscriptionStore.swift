//
//  InMemorySubscriptionStore.swift
//  StudyForge
//
//  A `SubscriptionStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryBookmarkStore`, so a screen
//  driven by it behaves exactly as it does against the file store. The forced-failure
//  switch is what lets a screen's error state be photographed without corrupting a file.
//

import Foundation

actor InMemorySubscriptionStore: SubscriptionStore {

    private var subscriptions: [String: Subscription]
    private var receipts: [PaymentRecord]

    /// When set, every call fails with it until cleared.
    private var failure: SubscriptionError?

    init(
        seededWith subscriptions: [Subscription] = [],
        receipts: [PaymentRecord] = []
    ) {
        self.subscriptions = Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.id, $0) })
        self.receipts = receipts
    }

    // MARK: SubscriptionStore

    func subscription(for uid: String) async throws -> Subscription? {
        try failIfForced()
        return subscriptions[uid]
    }

    func upsert(_ subscription: Subscription) async throws {
        try failIfForced()
        subscriptions[subscription.id] = subscription
    }

    func payments(for uid: String) async throws -> [PaymentRecord] {
        try failIfForced()
        return receipts
            .filter { $0.uid == uid }
            .sorted { $0.paidAt > $1.paidAt }
    }

    func record(_ payment: PaymentRecord) async throws {
        try failIfForced()
        receipts.append(payment)
    }

    func succeededPayment(idempotencyKey: String) async throws -> PaymentRecord? {
        try failIfForced()
        return receipts.first { $0.idempotencyKey == idempotencyKey && $0.status == .succeeded }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: SubscriptionError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
