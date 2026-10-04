//
//  CheckoutViewModelTests.swift
//  StudyForgeTests
//
//  L03's arithmetic and the promo field. The whole point of this screen is that the numbers
//  add up in front of the student, so the first test is that they do.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Checkout (F13)")
@MainActor
struct CheckoutViewModelTests {

    @Test("Subtotal, VAT and total add up exactly, with no discount")
    func totalsAddUp() throws {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .annual)
        let order = try #require(viewModel.order)

        #expect(order.totalFils == 19_000)
        #expect(order.subtotalFils + order.vatFils == order.totalFils)
        #expect(order.discountFils == 0)
    }

    @Test("VAT is the portion inside the total, not an addition to it")
    func vatIsInclusive() throws {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .pro, term: .monthly)
        let order = try #require(viewModel.order)

        #expect(order.totalFils == 4_900)
        #expect(order.vatFils == 445)          // 4 900 * 10/110, rounded
        #expect(order.subtotalFils == 4_455)
    }

    @Test("A valid promo discounts the price and is echoed on the order")
    func validPromo() throws {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .monthly)

        viewModel.promoInput = "  study20  "     // case- and whitespace-insensitive
        viewModel.applyPromo()

        let order = try #require(viewModel.order)
        #expect(order.discountFils == 380)       // 20 % of 1 900
        #expect(order.totalFils == 1_520)
        #expect(order.promoCode == "STUDY20")
        #expect(viewModel.promoIsError == false)
        #expect(viewModel.hasDiscount)
    }

    @Test("An unknown promo is inline feedback, not a failure — the order stays priced")
    func invalidPromo() throws {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .monthly)

        viewModel.promoInput = "NOT-A-CODE"
        viewModel.applyPromo()

        let order = try #require(viewModel.order)
        #expect(viewModel.promoIsError)
        #expect(order.discountFils == 0)
        #expect(order.totalFils == 1_900)
        #expect(order.promoCode == nil)
    }

    @Test("Clearing a promo restores the list price")
    func clearPromo() throws {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .monthly)
        viewModel.promoInput = "STUDY20"
        viewModel.applyPromo()

        viewModel.clearPromo()

        let order = try #require(viewModel.order)
        #expect(order.discountFils == 0)
        #expect(order.totalFils == 1_900)
        #expect(viewModel.promoInput.isEmpty)
        #expect(viewModel.promoMessage == nil)
    }

    @Test("Proceeding is gated on accepting the terms")
    func termsGate() {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .monthly)

        #expect(viewModel.canProceed == false, "the terms must be accepted first")

        viewModel.termsAccepted = true
        #expect(viewModel.canProceed)
    }

    @Test("The copy comes from the catalogue, including the VAT rate")
    func copyIsLocalised() {
        let viewModel = CheckoutViewModel(uid: "u1", plan: .plus, term: .annual)

        #expect(viewModel.title == L10n.subscriptionCheckoutTitle.string)
        #expect(viewModel.vatLabel == L10n.subscriptionVat.string(PaymentCatalogue.vatPercent))
        #expect(viewModel.termValue == L10n.subscriptionTermAnnual.string)
        #expect(viewModel.planValue == SubscriptionPlan.plus.displayName)
    }
}
