//
//  StoreKitPurchasing.swift
//  StudyForge
//
//  F13: the StoreKit 2 calls the gateway needs, behind a seam.
//
//  WHY THE CALLS ARE ABSTRACTED
//  ----------------------------
//  `StoreKitGateway` must be unit-testable. Reaching for `Product.purchase()` directly would
//  make every test need a live StoreKit session and a StoreKit configuration file. This seam
//  lets a test hand back a verified purchase, a cancellation, or an entitlement list, and lets
//  the real conformer talk to StoreKit.
//

import Foundation
import StoreKit

/// A StoreKit product, reduced to what the gateway needs.
struct StoreProduct: Sendable, Equatable {
    let id: String
    /// The localised price string StoreKit returns, for display only.
    let displayPrice: String
}

/// A verified StoreKit transaction, reduced to what the gateway needs.
struct VerifiedPurchase: Sendable, Equatable {
    let productId: String
    /// The App Store transaction id, used as the receipt's gateway reference.
    let transactionId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let isRevoked: Bool
}

/// Why a StoreKit purchase did not complete.
enum StorePurchaseError: Error, Equatable {
    /// The student dismissed the payment sheet. Not a failure.
    case userCancelled
    /// The purchase is awaiting approval (Ask to Buy). Not a failure yet.
    case pending
    /// The product is unavailable, or the transaction could not be verified.
    case unavailable
}

/// The StoreKit operations the gateway performs.
protocol StoreKitPurchasing: Sendable {
    func products(for ids: [String]) async throws -> [StoreProduct]
    func purchase(productId: String) async throws -> VerifiedPurchase
    func currentEntitlements() async -> [VerifiedPurchase]
}

/// The real conformer: StoreKit 2.
struct LiveStoreKitStore: StoreKitPurchasing {

    func products(for ids: [String]) async throws -> [StoreProduct] {
        try await Product.products(for: ids).map {
            StoreProduct(id: $0.id, displayPrice: $0.displayPrice)
        }
    }

    func purchase(productId: String) async throws -> VerifiedPurchase {
        guard let product = try await Product.products(for: [productId]).first else {
            throw StorePurchaseError.unavailable
        }

        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw StorePurchaseError.unavailable
            }
            // Finishing the transaction is the app's job, and only for a verified one.
            await transaction.finish()
            return Self.reduce(transaction)
        case .userCancelled:
            throw StorePurchaseError.userCancelled
        case .pending:
            throw StorePurchaseError.pending
        @unknown default:
            throw StorePurchaseError.unavailable
        }
    }

    func currentEntitlements() async -> [VerifiedPurchase] {
        var purchases: [VerifiedPurchase] = []
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification {
                purchases.append(Self.reduce(transaction))
            }
        }
        return purchases
    }

    private static func reduce(_ transaction: Transaction) -> VerifiedPurchase {
        VerifiedPurchase(
            productId: transaction.productID,
            transactionId: String(transaction.id),
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            isRevoked: transaction.revocationDate != nil
        )
    }
}
