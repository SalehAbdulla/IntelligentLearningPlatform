//
//  PaymentRecord.swift
//  StudyForge
//
//  F13 — the receipt and the vocabulary of a payment (docs/05 §2 `payments/{paymentId}`;
//  docs/03 §L L04/L08/L09).
//
//  WHAT IS DELIBERATELY NOT HERE
//  -----------------------------
//  There is no card number, no expiry and no CVV — not truncated, not encrypted, simply
//  absent. The Tap Card SDK tokenises inside its own view (docs/04 §6), so the only thing
//  this type ever holds is the LAST FOUR for the receipt ("visa •••• 4242"). That choice
//  is what keeps the project out of PCI-DSS scope, and it is enforced by the type not
//  having a field to put a full number in.
//

import Foundation

/// How the student paid (L04's method cards).
enum PaymentMethod: String, Sendable, Codable, CaseIterable, Identifiable {
    case card
    case benefitPay
    case applePay
    case knet

    var id: String { rawValue }

    /// The payment-network mark a row shows. Names are chosen to survive localisation:
    /// BenefitPay and KNET are proper nouns, so L10n only has to carry the two generic
    /// ones.
    var symbolName: String {
        switch self {
        case .card: "creditcard"
        case .benefitPay: "b.circle"            // Benefit is spelled with a "b" mark
        case .applePay: "apple.logo"
        case .knet: "k.circle"
        }
    }

    /// Whether this method hands the user off to a web page rather than collecting
    /// details in-app — L06's BenefitPay redirect, and the reason `applePay` shows no
    /// card-entry screen at all.
    var isRedirect: Bool {
        switch self {
        case .benefitPay, .knet: true
        case .card, .applePay: false
        }
    }
}

/// The lifecycle of one charge.
enum PaymentStatus: String, Sendable, Codable, CaseIterable {
    case succeeded
    case failed
    case refunded
}

/// Why a charge did not go through. L09 designs a distinct message and next step for
/// each, so they are distinct cases rather than one "declined".
enum PaymentFailureReason: String, Sendable, Codable, CaseIterable {
    /// The card had insufficient funds.
    case insufficientFunds

    /// The 3-D Secure challenge timed out — the user can simply retry.
    case threeDSecureTimeout

    /// The connection dropped mid-charge.
    case network

    /// The issuer declined the card outright; another card is needed, not a retry.
    case cardDeclined

    /// A charge for this order already succeeded. Not an error the user caused — and
    /// deliberately surfaced rather than silently ignored, because "you were not charged
    /// twice" is information the user wants.
    case duplicateCharge

    /// The gateway refused the secret-key call.
    case gatewayUnavailable

    /// Whether retrying the SAME method is worth offering. L09 shows "Retry" only when it
    /// is: a declined card will decline again, and a button that repeats a known failure
    /// is worse than no button.
    var isRetryable: Bool {
        switch self {
        case .threeDSecureTimeout, .network, .gatewayUnavailable: true
        case .insufficientFunds, .cardDeclined, .duplicateCharge: false
        }
    }

    /// Maps into the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .insufficientFunds:
            .paymentFailed(reason: "Your card was declined for insufficient funds. Try another card or method.")
        case .threeDSecureTimeout:
            .paymentFailed(reason: "The bank's verification timed out. You have not been charged — try again.")
        case .network:
            .paymentFailed(reason: "The connection dropped during payment. You have not been charged — check your connection and retry.")
        case .cardDeclined:
            .paymentFailed(reason: "Your bank declined this card. Try a different card or method.")
        case .duplicateCharge:
            .paymentFailed(reason: "This order was already paid. You have not been charged twice.")
        case .gatewayUnavailable:
            .paymentFailed(reason: "We couldn't reach the payment service. Try again in a moment.")
        }
    }
}

/// A completed charge, mirroring `payments/{paymentId}` (docs/05 §2).
///
/// Written by the webhook, read by the receipt. The app never constructs a `PaymentRecord`
/// with `status: .succeeded` on its own authority — the only writer is the gateway's
/// verification path.
struct PaymentRecord: Identifiable, Equatable, Sendable, Codable {

    let id: String

    /// The paying account. Firestore rules key the read on this field, so it must exist
    /// even though the document id is already unique.
    var uid: String

    var plan: SubscriptionPlan
    var term: BillingTerm

    /// Total charged, VAT included, in fils.
    var amountFils: Int

    /// The VAT portion of `amountFils`, kept separate so the receipt can show the
    /// breakdown the design's order summary promised.
    var vatFils: Int

    var currency: String
    var method: PaymentMethod

    /// Last four digits, for a card. `nil` for BenefitPay/KNET, which have no PAN.
    var last4: String?

    /// The gateway's charge reference — the receipt's traceable id.
    var tapChargeId: String

    /// The key that makes a retry idempotent: the same order replayed must not charge
    /// twice (docs/04 §6 point 4).
    var idempotencyKey: String

    var status: PaymentStatus
    var paidAt: Date

    /// The amount before VAT was added — derived, so it can never disagree with the total.
    var subtotalFils: Int { amountFils - vatFils }
}
