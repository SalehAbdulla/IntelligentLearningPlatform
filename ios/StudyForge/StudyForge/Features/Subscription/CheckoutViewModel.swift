//
//  CheckoutViewModel.swift
//  StudyForge
//
//  F13 — presentation logic for L03 (`120_Checkout_OrderSummary_BHD_{M3}`).
//
//  WHY THE TOTAL IS COMPUTED HERE AND NOT TYPED INTO THE VIEW
//  ----------------------------------------------------------
//  The summary is the one screen where the numbers must add up in front of the user:
//  subtotal, discount, VAT and total. `Order.build` derives all four from the catalogue and
//  the promo, so a change to a price or a promo rate moves every figure together and the
//  screen cannot show an arithmetic error. The view only formats.
//

import Foundation

@MainActor
@Observable
final class CheckoutViewModel {

    // MARK: Bound state

    /// The promo-code field (L03).
    var promoInput = ""

    /// The terms checkbox. Proceeding is gated on it.
    var termsAccepted = false

    private(set) var appliedPromo: PromoCode?

    /// Inline feedback under the promo field — a valid code or a rejection.
    private(set) var promoMessage: String?

    /// Whether `promoMessage` is a rejection, so the field can colour it as an error.
    private(set) var promoIsError = false

    /// The priced order. Rebuilt whenever the promo changes.
    private(set) var order: Order?

    let plan: SubscriptionPlan
    let term: BillingTerm

    private let uid: String

    init(uid: String, plan: SubscriptionPlan, term: BillingTerm) {
        self.uid = uid
        self.plan = plan
        self.term = term
        rebuild()
    }

    // MARK: Derived

    var hasDiscount: Bool { (order?.discountFils ?? 0) > 0 }
    var canProceed: Bool { order != nil && termsAccepted }

    // MARK: Copy

    var title: String { L10n.subscriptionCheckoutTitle.string }
    var planLabel: String { L10n.subscriptionPlanLabel.string }
    var termLabel: String { L10n.subscriptionTermLabel.string }
    var subtotalLabel: String { L10n.subscriptionSubtotal.string }
    var discountLabel: String { L10n.subscriptionDiscount.string }
    var totalLabel: String { L10n.subscriptionTotal.string }
    var promoLabel: String { L10n.subscriptionPromoLabel.string }
    var promoPlaceholder: String { L10n.subscriptionPromoPlaceholder.string }
    var promoApplyTitle: String { L10n.subscriptionPromoApply.string }
    var termsTitle: String { L10n.subscriptionTerms.string }
    var proceedTitle: String { L10n.subscriptionProceed.string }

    /// "VAT (10 %)" — the rate comes from the catalogue, never a literal.
    var vatLabel: String { L10n.subscriptionVat.string(PaymentCatalogue.vatPercent) }

    var planValue: String { plan.displayName }

    var termValue: String {
        term == .annual ? L10n.subscriptionTermAnnual.string : L10n.subscriptionTermMonthly.string
    }

    var subtotalValue: String { order.map { MoneyText.price($0.subtotalFils) } ?? "" }
    var vatValue: String { order.map { MoneyText.price($0.vatFils) } ?? "" }
    var totalValue: String { order.map { MoneyText.price($0.totalFils) } ?? "" }

    /// The discount as a negative amount, which is how a receipt reads it.
    var discountValue: String {
        guard let order, order.discountFils > 0 else { return "" }
        return "−\(MoneyText.price(order.discountFils))"
    }

    // MARK: Actions

    /// Validates the typed code and re-prices the order.
    ///
    /// A rejection is inline feedback, not a thrown error: the checkout stays usable, and
    /// the student can simply correct the code.
    func applyPromo() {
        let normalised = PromoCode.normalise(promoInput)
        guard !normalised.isEmpty else { return }

        if let code = PromoSandbox.validate(normalised) {
            appliedPromo = code
            promoMessage = L10n.subscriptionPromoApplied.string(code.code)
            promoIsError = false
        } else {
            appliedPromo = nil
            promoMessage = L10n.subscriptionPromoInvalid.string
            promoIsError = true
        }

        rebuild()
    }

    /// Removes an applied code and restores the list price.
    func clearPromo() {
        appliedPromo = nil
        promoMessage = nil
        promoIsError = false
        promoInput = ""
        rebuild()
    }

    // MARK: Internals

    private func rebuild() {
        order = try? Order.build(uid: uid, plan: plan, term: term, promo: appliedPromo)
    }
}
