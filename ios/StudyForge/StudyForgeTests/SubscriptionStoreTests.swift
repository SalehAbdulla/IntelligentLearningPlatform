//
//  SubscriptionStoreTests.swift
//  StudyForgeTests
//
//  The entitlement / receipt store, in both its in-memory and on-device forms.
//
//  The file round-trip is the test that matters: `FileSubscriptionStore` is what a real
//  build runs on, and a store that reads back something different from what it wrote would
//  show a plan the student does not have.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Subscription store (F13)")
struct SubscriptionStoreTests {

    private func sampleSubscription(uid: String = "u1") -> Subscription {
        Subscription(
            id: uid,
            plan: .plus,
            status: .active,
            periodStart: .now,
            periodEnd: Date().addingTimeInterval(60 * 60 * 24 * 30),
            tapChargeId: "ch_1",
            autoRenews: true
        )
    }

    private func sampleReceipt(uid: String = "u1", key: String = "k1") -> PaymentRecord {
        PaymentRecord(
            id: "p_\(key)",
            uid: uid,
            plan: .plus,
            term: .monthly,
            amountFils: 1_900,
            vatFils: 173,
            currency: MoneyCurrency.bhd,
            method: .card,
            last4: "4242",
            tapChargeId: "ch_1",
            idempotencyKey: key,
            status: .succeeded,
            paidAt: .now
        )
    }

    @Test("A subscription round-trips through the in-memory store")
    func inMemoryRoundTrip() async throws {
        let store = InMemorySubscriptionStore()
        #expect(try await store.subscription(for: "u1") == nil)

        try await store.upsert(sampleSubscription())

        #expect(try await store.subscription(for: "u1")?.plan == .plus)
    }

    @Test("Receipts are filtered by owner")
    func receiptsArePerOwner() async throws {
        let store = InMemorySubscriptionStore()
        try await store.record(sampleReceipt(uid: "u1", key: "a"))
        try await store.record(sampleReceipt(uid: "u2", key: "b"))

        let mine = try await store.payments(for: "u1")
        #expect(mine.count == 1)
        #expect(mine.first?.uid == "u1")
    }

    @Test("succeededPayment resolves a retry by idempotency key")
    func idempotencyLookup() async throws {
        let store = InMemorySubscriptionStore()
        try await store.record(sampleReceipt(key: "k1"))

        #expect(try await store.succeededPayment(idempotencyKey: "k1") != nil)
        #expect(try await store.succeededPayment(idempotencyKey: "nope") == nil)
    }

    @Test("A failed receipt is not returned by the idempotency lookup")
    func failedReceiptIsNotAReplay() async throws {
        let store = InMemorySubscriptionStore()
        var failed = sampleReceipt(key: "k1")
        failed.status = .failed
        try await store.record(failed)

        #expect(try await store.succeededPayment(idempotencyKey: "k1") == nil)
    }

    @Test("A storage failure maps to an AppError carrying a reference")
    func failureMapping() async throws {
        let store = InMemorySubscriptionStore()
        await store.forceFailure(.storageFailed)

        do {
            _ = try await store.subscription(for: "u1")
            Issue.record("expected the forced failure to throw")
        } catch {
            #expect(AppError.from(error) == .server(reference: "subscription-store-failed"))
        }
    }

    @Test("A subscription and its receipts survive a file round-trip")
    func fileRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("studyforge-tests-\(UUID().uuidString)", isDirectory: true)

        let store = FileSubscriptionStore(directory: directory)
        try await store.upsert(sampleSubscription())
        try await store.record(sampleReceipt())

        // A SECOND instance, to prove the data came off disk and not out of the first
        // instance's cache.
        let reopened = FileSubscriptionStore(directory: directory)
        #expect(try await reopened.subscription(for: "u1")?.tapChargeId == "ch_1")
        #expect(try await reopened.payments(for: "u1").count == 1)

        try? FileManager.default.removeItem(at: directory)
    }
}
