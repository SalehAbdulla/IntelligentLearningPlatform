//
//  StoreKitGatewayTests.swift
//  StudyForgeTests
//
//  Tests for F13's App Store gateway: a verified purchase writes an entitlement, a cancel
//  writes nothing, an unavailable product fails cleanly, and restore reads the entitlement.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("StoreKit payments gateway (F13)")
struct StoreKitGatewayTests {

    /// A StoreKit seam returning canned results, so the gateway is tested without StoreKit.
    private struct FakeStoreKit: StoreKitPurchasing {
        var purchaseResult: VerifiedPurchase? = nil
        var purchaseError: StorePurchaseError? = nil
        var entitlements: [VerifiedPurchase] = []

        func products(for ids: [String]) async throws -> [StoreProduct] {
            ids.map { StoreProduct(id: $0, displayPrice: "BHD 1.900") }
        }

        func purchase(productId: String) async throws -> VerifiedPurchase {
            if let purchaseError { throw purchaseError }
            guard let purchaseResult else { throw StorePurchaseError.unavailable }
            return purchaseResult
        }

        func currentEntitlements() async -> [VerifiedPurchase] { entitlements }
    }

    private func order(plan: SubscriptionPlan = .plus, term: BillingTerm = .monthly) -> Order {
        Order(
            uid: "u1",
            plan: plan,
            term: term,
            subtotalFils: 1_727,
            discountFils: 0,
            vatFils: 173,
            totalFils: 1_900,
            currency: MoneyCurrency.bhd,
            promoCode: nil
        )
    }

    private func verifiedPurchase(
        expires: Date? = Date.now.addingTimeInterval(30 * 24 * 3600),
        revoked: Bool = false
    ) -> VerifiedPurchase {
        VerifiedPurchase(
            productId: "com.studyforge.app.plus.monthly",
            transactionId: "2000000123",
            purchaseDate: .now,
            expirationDate: expires,
            isRevoked: revoked
        )
    }

    @Test("A verified purchase writes the entitlement and returns the receipt")
    func purchaseSucceeds() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = StoreKitGateway(
            store: FakeStoreKit(purchaseResult: verifiedPurchase()),
            entitlements: store
        )

        let outcome = try await gateway.startCheckout(order: order(), method: .card)

        guard case .succeeded(let subscription, let receipt) = outcome else {
            Issue.record("expected success, got \(outcome)")
            return
        }
        #expect(subscription.plan == .plus)
        #expect(receipt.tapChargeId == "2000000123")
        let persisted = try await store.subscription(for: "u1")
        #expect(persisted?.plan == .plus)
    }

    @Test("A cancelled purchase returns .cancelled and writes nothing")
    func cancelWritesNothing() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = StoreKitGateway(
            store: FakeStoreKit(purchaseError: .userCancelled),
            entitlements: store
        )

        let outcome = try await gateway.startCheckout(order: order(), method: .card)

        #expect(outcome == .cancelled)
        let persisted = try await store.subscription(for: "u1")
        #expect(persisted == nil)
    }

    @Test("An unavailable product fails cleanly")
    func unavailableFails() async throws {
        let gateway = StoreKitGateway(
            store: FakeStoreKit(purchaseError: .unavailable),
            entitlements: InMemorySubscriptionStore()
        )

        let outcome = try await gateway.startCheckout(order: order(), method: .card)
        #expect(outcome == .failed(.gatewayUnavailable))
    }

    @Test("Restore reads the active entitlement from StoreKit")
    func restoreReadsEntitlement() async throws {
        let gateway = StoreKitGateway(
            store: FakeStoreKit(entitlements: [verifiedPurchase()]),
            entitlements: InMemorySubscriptionStore()
        )

        let restored = try await gateway.restoreEntitlements(uid: "u1")
        #expect(restored?.plan == .plus)
        #expect(restored?.isPremium == true)
    }
}
