//
//  PaymentGateway.swift
//  StudyForge
//
//  F13 — the seam between the app and whoever actually takes the money (docs/04 §6).
//
//  WHY A PROTOCOL AND NOT A DIRECT TAP CALL
//  ----------------------------------------
//  Two reasons, and only one of them is testability.
//
//  1. **Testability.** `SimulatedTapGateway` gives the whole flow — paywall to receipt —
//     a deterministic engine with no network, which is what lets the golden path run in
//     the Simulator and in CI.
//  2. **Compliance.** Apple's Guideline 3.1.1 requires in-app digital subscriptions to be
//     sold through StoreKit. `TapPaymentsGateway` is the brief's requirement, and
//     `StoreKitGateway` is the App-Store-compliant route a real release needs. Both
//     satisfy this protocol, so the choice is one line in `AppContainer` rather than a
//     rewrite (docs/04 §6). This is the "professional judgement under LO3" the document
//     claims, and it has to be TRUE in the code or it is just a paragraph.
//
//  The protocol is small on purpose: start a checkout, restore what is already owned.
//  Anything more is the gateway's business, not the app's.
//

import Foundation

/// A priced order, assembled from the catalogue BEFORE anything is charged.
///
/// The client builds this to display a total; the server recomputes the amount it charges
/// from its own copy of the catalogue (`createCharge` in `backend/functions/src`). The two
/// are compared on the webhook, so a tampered price here buys nothing.
///
/// Money is in fils throughout. The amounts are VAT-INCLUSIVE, matching docs/04 §6
/// ("BHD amount incl. 10% VAT"), and `vatFils` is the VAT PORTION *inside* `totalFils` —
/// not an amount added on top. Getting that direction wrong is a receipt that overcharges.
struct Order: Equatable, Sendable {

    let uid: String
    let plan: SubscriptionPlan
    let term: BillingTerm

    /// Amount before VAT, after any discount.
    let subtotalFils: Int

    /// Promotional discount already applied to the list price, for display.
    let discountFils: Int

    /// VAT portion contained within `totalFils`.
    let vatFils: Int

    /// What the gateway will charge, VAT included.
    let totalFils: Int

    let currency: String

    /// The applied promo code, echoed on the receipt.
    let promoCode: String?

    /// The key that makes replaying this order harmless (docs/04 §6 point 4).
    ///
    /// Built the same way as the Cloud Function's key — `uid:plan:term:YYYY-MM-DD` — so a
    /// retry on the same day resolves to the same charge rather than a second one.
    var idempotencyKey: String {
        "\(uid):\(plan.rawValue):\(term.rawValue):\(Self.dayStamp())"
    }

    /// `YYYY-MM-DD` in UTC. UTC rather than local time so two devices in different time
    /// zones cannot mint different keys for the same calendar day.
    static func dayStamp(_ date: Date = .now) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

extension Order {

    /// Builds an order from the catalogue, applying an optional promo code.
    ///
    /// - Throws: `PaymentError.planNotPurchasable` when the plan/term pair has no price
    ///   (a free plan, or a term that is not sold).
    static func build(
        uid: String,
        plan: SubscriptionPlan,
        term: BillingTerm,
        promo: PromoCode? = nil,
        now: Date = .now
    ) throws -> Order {
        guard let list = PaymentCatalogue.priceInFils(plan, term) else {
            throw PaymentError.planNotPurchasable
        }

        let discount = promo.map { $0.discountFils(on: list) } ?? 0
        let total = max(0, list - discount)

        // VAT is extracted FROM the inclusive total, so subtotal + VAT == total exactly
        // (the VAT is the remainder, not a separately-rounded number).
        let vat = Int((Double(total) * Double(PaymentCatalogue.vatPercent)
            / Double(100 + PaymentCatalogue.vatPercent)).rounded())

        return Order(
            uid: uid,
            plan: plan,
            term: term,
            subtotalFils: total - vat,
            discountFils: discount,
            vatFils: vat,
            totalFils: total,
            currency: MoneyCurrency.bhd,
            promoCode: promo?.code
        )
    }
}

// MARK: - Outcome and protocol

/// The result of asking the gateway to take money.
///
/// `succeeded` carries the entitlement and receipt the gateway's verification path wrote —
/// NOT something the app decided. That distinction is the feature: an in-app "success"
/// callback changes nothing, and the only way to observe an entitlement is to read the
/// subscription the gateway persisted.
enum PaymentOutcome: Equatable, Sendable {
    case succeeded(subscription: Subscription, receipt: PaymentRecord)
    case failed(PaymentFailureReason)
    case cancelled
}

/// Takes payments and reports what the account owns.
///
/// `Sendable` because gateways are handed across actor boundaries: a `@MainActor` view
/// model awaits one, and the conformance must be safe to do so.
protocol PaymentGateway: Sendable {

    /// Requests a charge and returns the outcome the server-side verification produced.
    ///
    /// Implementations MUST write the entitlement and receipt themselves before returning
    /// `.succeeded` — this stands in for the Tap webhook, which is the single source of
    /// truth (docs/04 §6 point 3). Returning a success without persisting it would let the
    /// UI show a plan the account does not have.
    func startCheckout(order: Order, method: PaymentMethod) async throws -> PaymentOutcome

    /// What the account currently owns, or `nil` if nothing has ever been bought.
    ///
    /// Used on launch and by L01's "restore purchases" — the client asks the source of
    /// truth rather than trusting anything it remembers locally.
    func restoreEntitlements(uid: String) async throws -> Subscription?
}

/// Failures specific to starting a checkout.
enum PaymentError: Error, Equatable {

    /// The plan/term pair has no price in the catalogue.
    case planNotPurchasable

    /// A charge was requested with no signed-in account to attach it to.
    case notSignedIn

    /// The account already holds an active entitlement for this plan — a second charge
    /// would be a mistake, so the gateway refuses rather than taking money.
    case alreadySubscribed

    /// Maps into the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .planNotPurchasable:
            .server(reference: "payment-plan-invalid")
        case .notSignedIn:
            .notPermitted
        case .alreadySubscribed:
            // Not a scary failure: the account is ALREADY on the plan they asked for.
            .paymentFailed(reason: "You're already on this plan. Nothing was charged.")
        }
    }
}
