//
//  ManageSubscriptionViewModelTests.swift
//  StudyForgeTests
//
//  L10 / B13 — the plan panel, the methods on file and, most importantly, that cancelling
//  stops the renewal WITHOUT cutting off access the student has already paid for.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Manage subscription (F13)")
@MainActor
struct ManageSubscriptionViewModelTests {

    private func subscription(
        plan: SubscriptionPlan = .plus,
        status: SubscriptionStatus = .active,
        autoRenews: Bool = true,
        periodEnd: Date = Date().addingTimeInterval(60 * 60 * 24 * 20)
    ) -> Subscription {
        Subscription(
            id: "u1",
            plan: plan,
            status: status,
            periodStart: Date().addingTimeInterval(-60 * 60 * 24 * 10),
            periodEnd: periodEnd,
            tapChargeId: "ch_1",
            autoRenews: autoRenews
        )
    }

    private func receipt(id: String, method: PaymentMethod, daysAgo: Int) -> PaymentRecord {
        PaymentRecord(
            id: id,
            uid: "u1",
            plan: .plus,
            term: .monthly,
            amountFils: 1_900,
            vatFils: 173,
            currency: MoneyCurrency.bhd,
            method: method,
            last4: nil,
            tapChargeId: "ch_\(id)",
            idempotencyKey: "k_\(id)",
            status: .succeeded,
            paidAt: Date().addingTimeInterval(-Double(daysAgo) * 86_400)
        )
    }

    @Test("Cancelling stops the renewal but keeps access until the period ends")
    func cancelKeepsAccess() async throws {
        let store = InMemorySubscriptionStore(seededWith: [subscription()])
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: store)
        await viewModel.load()
        #expect(viewModel.canCancel)

        await viewModel.cancel()

        let stored = try #require(try await store.subscription(for: "u1"))
        #expect(stored.status == .cancelled)
        #expect(stored.autoRenews == false)
        #expect(stored.isEntitled, "access continues until the period ends")
        #expect(stored.isPremium)

        #expect(viewModel.canCancel == false, "there is nothing left to cancel")
        #expect(viewModel.subscription?.isEndingAtPeriodEnd == true)
    }

    @Test("An active paid plan reads as renewing")
    func renewalCopy() async {
        let end = Date().addingTimeInterval(60 * 60 * 24 * 10)
        let store = InMemorySubscriptionStore(seededWith: [subscription(periodEnd: end)])
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: store)

        await viewModel.load()

        let date = end.formatted(date: .abbreviated, time: .omitted)
        #expect(viewModel.renewalText == L10n.subscriptionRenewsOn.string(date))
        #expect(viewModel.autoRenewText == L10n.subscriptionAutoRenewOn.string)
    }

    @Test("A free account has nothing to cancel and no renewal line")
    func freeCannotCancel() async {
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: InMemorySubscriptionStore())
        await viewModel.load()

        #expect(viewModel.isPremium == false)
        #expect(viewModel.canCancel == false)
        #expect(viewModel.renewalText == nil)
        #expect(viewModel.planValue == SubscriptionPlan.free.displayName)
    }

    @Test("Methods come from the receipts, newest first and de-duplicated")
    func methodsFromReceipts() async {
        let store = InMemorySubscriptionStore(receipts: [
            receipt(id: "a", method: .card, daysAgo: 40),
            receipt(id: "b", method: .benefitPay, daysAgo: 10),
            receipt(id: "c", method: .card, daysAgo: 1),
        ])
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: store)

        await viewModel.load()

        #expect(viewModel.methods == [.card, .benefitPay], "newest first, card de-duplicated")
        #expect(viewModel.hasHistory)
        #expect(viewModel.defaultMethod == .card, "seeded from the most recent successful charge")
    }

    @Test("Making a method default updates the session choice")
    func makeDefault() async {
        let store = InMemorySubscriptionStore(receipts: [
            receipt(id: "a", method: .card, daysAgo: 1),
            receipt(id: "b", method: .knet, daysAgo: 2),
        ])
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: store)
        await viewModel.load()

        viewModel.makeDefault(.knet)
        #expect(viewModel.defaultMethod == .knet)
    }

    @Test("A storage failure surfaces as an AppError")
    func failureMaps() async {
        let store = InMemorySubscriptionStore()
        await store.forceFailure(.storageFailed)
        let viewModel = ManageSubscriptionViewModel(uid: "u1", store: store)

        await viewModel.load()

        #expect(viewModel.error != nil)
    }
}
