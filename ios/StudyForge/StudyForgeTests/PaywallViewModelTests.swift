//
//  PaywallViewModelTests.swift
//  StudyForgeTests
//
//  L01's presentation logic: what a free vs. paid account sees, and how the term toggle
//  drives the price, the per-month figure and the saving badge together.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Paywall (F13)")
@MainActor
struct PaywallViewModelTests {

    private func makeViewModel(subscription: Subscription? = nil) -> PaywallViewModel {
        let store = InMemorySubscriptionStore(seededWith: subscription.map { [$0] } ?? [])
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        return PaywallViewModel(uid: "u1", store: store, gateway: gateway)
    }

    @Test("A fresh account reads as free, with no premium entitlement")
    func freeByDefault() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        #expect(viewModel.currentPlan == .free)
        #expect(viewModel.isPremium == false)
        #expect(viewModel.isCurrent(.free))
    }

    @Test("An active paid entitlement marks the current plan")
    func paidEntitlement() async {
        let viewModel = makeViewModel(subscription: Subscription(
            id: "u1",
            plan: .pro,
            status: .active,
            periodEnd: Date().addingTimeInterval(60 * 60),
            autoRenews: true
        ))
        await viewModel.load()

        #expect(viewModel.currentPlan == .pro)
        #expect(viewModel.isPremium)
        #expect(viewModel.isCurrent(.pro))
    }

    @Test("The annual term shows the annual price and a computed saving; monthly shows neither")
    func termDrivesPricing() {
        let viewModel = makeViewModel()

        viewModel.term = .monthly
        #expect(viewModel.priceLabel(.plus)?.contains("1.900") == true)
        #expect(viewModel.savingLabel(.plus) == nil, "there is no saving to claim on monthly")
        #expect(viewModel.perMonthLabel(.plus) == nil)

        viewModel.term = .annual
        #expect(viewModel.priceLabel(.plus)?.contains("19.000") == true)
        #expect(viewModel.perMonthLabel(.plus)?.contains("1.583") == true, "19.000 / 12")
        #expect(viewModel.savingLabel(.plus) == L10n.subscriptionSavePercent.string(17))
    }

    @Test("Free still shows a price rather than a blank card")
    func freeShowsZero() {
        let viewModel = makeViewModel()
        #expect(viewModel.priceLabel(.free)?.contains("0.000") == true)
        #expect(viewModel.savingLabel(.free) == nil)
    }

    @Test("Plus carries the recommended ribbon")
    func recommendedPlan() {
        let viewModel = makeViewModel()
        #expect(viewModel.isRecommended(.plus))
        #expect(viewModel.isRecommended(.pro) == false)
    }

    @Test("A subscription-store failure surfaces as an AppError")
    func failureMaps() async {
        let store = InMemorySubscriptionStore()
        await store.forceFailure(.storageFailed)
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        let viewModel = PaywallViewModel(uid: "u1", store: store, gateway: gateway)

        await viewModel.load()

        #expect(viewModel.error != nil)
    }
}
