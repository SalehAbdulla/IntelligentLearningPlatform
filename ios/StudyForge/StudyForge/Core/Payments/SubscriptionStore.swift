//
//  SubscriptionStore.swift
//  StudyForge
//
//  F13 — where entitlements and receipts are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  docs/05 §2 defines `subscriptions/{uid}` and `payments/{paymentId}` and
//  `backend/firestore.rules` already makes them Cloud-Function-write-only. What that does
//  not give us is a paywall that is demonstrable before a project, a Blaze plan and a Tap
//  account exist — which is every day of this project so far (docs/09 D22). So this
//  protocol is the seam the webhook writes through, and the local implementations are what
//  the app runs on until that webhook is reachable.
//
//  WHY THE ENTITLEMENT AND THE RECEIPT ARE ONE STORE
//  -------------------------------------------------
//  They are written together by one webhook and read together by one screen: a receipt
//  without its entitlement, or a plan change with no record of the charge, is a state the
//  app should never be able to observe. One store makes that atomicity the default rather
//  than something each caller has to remember.
//

import Foundation

/// Reads and writes entitlements and receipts.
protocol SubscriptionStore: Sendable {

    /// The account's current subscription, or `nil` if it has never had one.
    func subscription(for uid: String) async throws -> Subscription?

    /// Stores a subscription, replacing any existing record for the same uid.
    func upsert(_ subscription: Subscription) async throws

    /// The account's payment history, most recent first.
    func payments(for uid: String) async throws -> [PaymentRecord]

    /// Appends a receipt. Appending the same `idempotencyKey` twice is not expected —
    /// the gateway checks first — but the store does not deduplicate, because a genuine
    /// second purchase on a later day legitimately shares nothing with the first.
    func record(_ payment: PaymentRecord) async throws

    /// A previously-succeeded payment for the same idempotency key, if any.
    ///
    /// This is how a retried checkout resolves to the charge that already happened instead
    /// of taking the money again (docs/04 §6 point 4).
    func succeededPayment(idempotencyKey: String) async throws -> PaymentRecord?
}

/// Failures from the subscription layer, in the app's own vocabulary.
enum SubscriptionError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "subscription-store-failed")
        }
    }
}
