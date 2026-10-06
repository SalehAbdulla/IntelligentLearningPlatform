//
//  PaymentCatalogueTests.swift
//  StudyForgeTests
//
//  The plan catalogue and the money maths behind L01–L03.
//
//  These are pinned deliberately: the numbers here are the SAME numbers the Cloud Function
//  resolves server-side, and a receipt that disagrees with the catalogue is a wrong charge.
//  A test that fails when someone edits a price is doing its job.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Payment catalogue (F13)")
struct PaymentCatalogueTests {

    @Test("Paid plans are priced for both terms; free has no price at all")
    func prices() {
        #expect(PaymentCatalogue.priceInFils(.plus, .monthly) == 1_900)
        #expect(PaymentCatalogue.priceInFils(.plus, .annual) == 19_000)
        #expect(PaymentCatalogue.priceInFils(.pro, .monthly) == 4_900)
        #expect(PaymentCatalogue.priceInFils(.pro, .annual) == 49_000)
        #expect(PaymentCatalogue.priceInFils(.free, .monthly) == nil)
        #expect(PaymentCatalogue.priceInFils(.free, .annual) == nil)
    }

    @Test("The annual saving is computed from the prices, not hard-coded")
    func annualSaving() {
        // Both paid tiers give two months free, i.e. 2/12 ≈ 16.7 % → 17 %.
        #expect(PaymentCatalogue.annualSavingPercent(.plus) == 17)
        #expect(PaymentCatalogue.annualSavingPercent(.pro) == 17)
        #expect(PaymentCatalogue.annualSavingPercent(.free) == nil)
    }

    @Test("Plan entitlements match the documented tiers")
    func entitlements() {
        #expect(SubscriptionPlan.free.dailyAIGenerationLimit == 15)
        #expect(SubscriptionPlan.free.includedMaterials == 20)
        #expect(SubscriptionPlan.free.includedGroupSpaces == 1)

        #expect(SubscriptionPlan.plus.dailyAIGenerationLimit == 100)
        #expect(SubscriptionPlan.plus.includedMaterials == 200)
        #expect(SubscriptionPlan.plus.includedGroupSpaces == 5)

        #expect(SubscriptionPlan.pro.includedMaterials == nil, "nil means unlimited")
        #expect(SubscriptionPlan.pro.includedGroupSpaces == nil)

        #expect(SubscriptionPlan.free.isPaid == false)
        #expect(SubscriptionPlan.plus.isPaid)
        #expect(SubscriptionPlan.pro.isPaid)
    }

    @Test("Money renders with the dinar's three decimal places")
    func formatting() {
        let locale = Locale(identifier: "en_US")
        #expect(MoneyText.price(1_900, locale: locale).contains("1.900"))
        #expect(PaymentCatalogue.amountString(0, locale: locale) == "0.000")
        #expect(PaymentCatalogue.amountString(19_000, locale: locale) == "19.000")
    }

    @Test("VAT is a single catalogue constant")
    func vatRate() {
        #expect(PaymentCatalogue.vatPercent == 10)
    }
}

@Suite("Order maths (F13)")
struct OrderTests {

    @Test("Subtotal, VAT and total add up exactly")
    func totalsAddUp() throws {
        let order = try Order.build(uid: "u1", plan: .plus, term: .annual)
        #expect(order.totalFils == 19_000)
        #expect(order.subtotalFils + order.vatFils == order.totalFils)
    }

    @Test("VAT is extracted FROM the inclusive total, not added on top")
    func vatIsInclusive() throws {
        // 4 900 * 10/110 = 445.45 → 445, so the total is still exactly 4 900.
        let order = try Order.build(uid: "u1", plan: .pro, term: .monthly)
        #expect(order.totalFils == 4_900)
        #expect(order.vatFils == 445)
        #expect(order.subtotalFils == 4_455)
    }

    @Test("A free plan has no order")
    func freeHasNoOrder() {
        #expect(throws: PaymentError.planNotPurchasable) {
            try Order.build(uid: "u1", plan: .free, term: .monthly)
        }
    }

    @Test("The idempotency key follows uid:plan:term:day")
    func idempotencyKey() throws {
        let order = try Order.build(uid: "u1", plan: .plus, term: .monthly)
        #expect(order.idempotencyKey.hasPrefix("u1:plus:monthly:"))
        #expect(order.idempotencyKey.hasSuffix(Order.dayStamp()))
    }

    @Test("A retry on the same day produces the same key")
    func sameDayIsIdempotent() throws {
        let first = try Order.build(uid: "u1", plan: .plus, term: .monthly)
        let second = try Order.build(uid: "u1", plan: .plus, term: .monthly)
        #expect(first.idempotencyKey == second.idempotencyKey)
    }
}
