//
//  FirestoreSubscriptionStore.swift
//  StudyForge
//
//  F13: reads the entitlement and receipts the Tap webhook writes to Firestore.
//
//  WHY THIS STORE IS READ-ONLY
//  ---------------------------
//  `backend/firestore.rules` makes `subscriptions/{uid}` and `payments/{paymentId}`
//  Cloud-Function-write-only: entitlements come from the Tap webhook and nowhere else. The two
//  write methods below therefore throw rather than pretend. The real gateway never calls them;
//  it only reads what the webhook has already written, which is the property the access model
//  depends on.
//

import Foundation
import FirebaseFirestore

actor FirestoreSubscriptionStore: SubscriptionStore {

    private let db = Firestore.firestore()

    func subscription(for uid: String) async throws -> Subscription? {
        let snapshot = try await db.collection("subscriptions").document(uid).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return Subscription(
            id: uid,
            plan: SubscriptionPlan(rawValue: data["plan"] as? String ?? "") ?? .free,
            status: SubscriptionStatus(rawValue: data["status"] as? String ?? "") ?? .none,
            periodStart: (data["periodStart"] as? Timestamp)?.dateValue(),
            periodEnd: (data["periodEnd"] as? Timestamp)?.dateValue(),
            tapChargeId: data["tapChargeId"] as? String,
            autoRenews: data["autoRenews"] as? Bool ?? false
        )
    }

    func payments(for uid: String) async throws -> [PaymentRecord] {
        let snapshot = try await db.collection("payments")
            .whereField("uid", isEqualTo: uid)
            .order(by: "paidAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap(Self.decode)
    }

    func succeededPayment(idempotencyKey: String) async throws -> PaymentRecord? {
        let snapshot = try await db.collection("payments")
            .whereField("idempotencyKey", isEqualTo: idempotencyKey)
            .whereField("status", isEqualTo: "CAPTURED")
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap(Self.decode)
    }

    // MARK: Writes, refused by rule

    func upsert(_ subscription: Subscription) async throws {
        // The webhook is the only writer of `subscriptions/{uid}`; a client write is denied.
        throw SubscriptionError.storageFailed
    }

    func record(_ payment: PaymentRecord) async throws {
        throw SubscriptionError.storageFailed
    }

    // MARK: Decoding

    private static func decode(_ document: QueryDocumentSnapshot) -> PaymentRecord? {
        let data = document.data()
        guard
            let uid = data["uid"] as? String,
            let plan = SubscriptionPlan(rawValue: data["plan"] as? String ?? ""),
            let term = BillingTerm(rawValue: data["term"] as? String ?? "")
        else { return nil }

        return PaymentRecord(
            id: document.documentID,
            uid: uid,
            plan: plan,
            term: term,
            amountFils: data["amountFils"] as? Int ?? 0,
            vatFils: data["vatFils"] as? Int ?? 0,
            currency: data["currency"] as? String ?? MoneyCurrency.bhd,
            method: PaymentMethod(rawValue: data["method"] as? String ?? "") ?? .card,
            last4: data["last4"] as? String,
            tapChargeId: data["tapChargeId"] as? String ?? document.documentID,
            idempotencyKey: data["idempotencyKey"] as? String ?? "",
            status: Self.status(from: data["status"] as? String),
            paidAt: (data["paidAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }

    /// The webhook writes Tap's status vocabulary ("CAPTURED"); the app's is succeeded/failed.
    private static func status(from raw: String?) -> PaymentStatus {
        switch raw {
        case "CAPTURED", "succeeded": .succeeded
        case "refunded": .refunded
        default: .failed
        }
    }
}
