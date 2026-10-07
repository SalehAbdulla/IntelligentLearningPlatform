//
//  StoreKitGateway.swift
//  StudyForge
//
//  F13: the App Store route, required by Apple's Guideline 3.1.1 for a real release.
//
//  WHY BOTH A TAP AND A STOREKIT GATEWAY EXIST
//  -------------------------------------------
//  The client brief specifies Tap (a Bahrain gateway). Apple's Guideline 3.1.1 requires digital
//  subscriptions sold in an App Store app to go through StoreKit. Rather than pretend the
//  conflict does not exist, both sit behind `PaymentGateway`, and `AppContainer` picks one by
//  build environment. That is the "professional judgement under LO3" the design document claims,
//  and it has to be TRUE in the code or it is only a paragraph.
//
//  WHERE THE ENTITLEMENT COMES FROM
//  --------------------------------
//  StoreKit is the source of truth: the entitlement is the VERIFIED transaction, not a value
//  this type invents. It is mirrored into the app's own store so the paywall and settings read
//  it the same way they read a Tap entitlement.
//

import Foundation

actor StoreKitGateway: PaymentGateway {

    private let store: any StoreKitPurchasing
    private let entitlements: any SubscriptionStore

    init(store: any StoreKitPurchasing, entitlements: any SubscriptionStore) {
        self.store = store
        self.entitlements = entitlements
    }

    func startCheckout(order: Order, method: PaymentMethod) async throws -> PaymentOutcome {
        guard let productId = StoreKitCatalogue.productId(order.plan, order.term) else {
            return .failed(.gatewayUnavailable)
        }

        let purchase: VerifiedPurchase
        do {
            purchase = try await store.purchase(productId: productId)
        } catch StorePurchaseError.userCancelled {
            // The student backed out. Not an error; the picker simply stays open.
            return .cancelled
        } catch {
            return .failed(.gatewayUnavailable)
        }

        // A revoked transaction never grants an entitlement.
        guard !purchase.isRevoked else {
            return .failed(.cardDeclined)
        }

        let subscription = Subscription(
            id: order.uid,
            plan: order.plan,
            status: .active,
            periodStart: purchase.purchaseDate,
            periodEnd: purchase.expirationDate,
            tapChargeId: purchase.transactionId,
            autoRenews: true
        )

        let receipt = PaymentRecord(
            id: purchase.transactionId,
            uid: order.uid,
            plan: order.plan,
            term: order.term,
            amountFils: order.totalFils,
            vatFils: order.vatFils,
            currency: order.currency,
            method: method,
            last4: nil,
            tapChargeId: purchase.transactionId,
            idempotencyKey: order.idempotencyKey,
            status: .succeeded,
            paidAt: purchase.purchaseDate
        )

        // Mirror the verified transaction into the app's store, so the rest of the app reads
        // an App Store entitlement exactly as it reads a Tap one.
        try? await entitlements.upsert(subscription)
        try? await entitlements.record(receipt)

        return .succeeded(subscription: subscription, receipt: receipt)
    }

    func restoreEntitlements(uid: String) async throws -> Subscription? {
        let purchases = await store.currentEntitlements()
        let active = purchases.first { purchase in
            guard !purchase.isRevoked else { return false }
            return (purchase.expirationDate ?? .distantFuture) > .now
        }

        guard let active, let (plan, _) = StoreKitCatalogue.plan(forProductId: active.productId) else {
            return try await entitlements.subscription(for: uid)
        }

        return Subscription(
            id: uid,
            plan: plan,
            status: .active,
            periodStart: active.purchaseDate,
            periodEnd: active.expirationDate,
            tapChargeId: active.transactionId,
            autoRenews: true
        )
    }
}
