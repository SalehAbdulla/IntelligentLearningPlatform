//
//  PaymentFlowViewModelTests.swift
//  StudyForgeTests
//
//  L04 / L07 / L08 / L09 — and, more importantly, the three security properties the feature
//  claims: the entitlement is written by the gateway (never by the UI), a decline writes no
//  entitlement, and a replayed order does not charge twice.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Payment flow (F13)")
@MainActor
struct PaymentFlowViewModelTests {

    private func makeOrder(plan: SubscriptionPlan = .plus, term: BillingTerm = .monthly) throws -> Order {
        try Order.build(uid: "u1", plan: plan, term: term)
    }

    @Test("A successful charge leaves an entitlement AND a receipt in the store")
    func successWritesBoth() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        let viewModel = PaymentViewModel(order: try makeOrder(), gateway: gateway)

        await viewModel.pay()

        #expect(viewModel.receipt != nil)
        #expect(try await store.subscription(for: "u1")?.plan == .plus)
        #expect(try await store.subscription(for: "u1")?.isPremium == true)
        #expect(try await store.payments(for: "u1").count == 1)
    }

    @Test("A decline writes NO entitlement and surfaces the typed reason")
    func declineWritesNothing() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        await gateway.forceFailure(.cardDeclined)

        let viewModel = PaymentViewModel(order: try makeOrder(), gateway: gateway)
        await viewModel.pay()

        #expect(viewModel.failureReason == .cardDeclined)
        #expect(try await store.subscription(for: "u1") == nil, "a decline must not half-upgrade the account")
        #expect(viewModel.receipt == nil)
    }

    @Test("A declined card is not retryable; a network drop is")
    func retryabilityFollowsTheReason() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)

        await gateway.forceFailure(.cardDeclined)
        let declined = PaymentViewModel(order: try makeOrder(), gateway: gateway)
        await declined.pay()
        #expect(declined.canRetrySameMethod == false)

        await gateway.forceFailure(.network)
        let flaky = PaymentViewModel(order: try makeOrder(), gateway: gateway)
        await flaky.pay()
        #expect(flaky.canRetrySameMethod)
    }

    @Test("Replaying the same order reuses the original charge — no double charge")
    func replayIsIdempotent() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        let order = try makeOrder()

        await PaymentViewModel(order: order, gateway: gateway).pay()
        await PaymentViewModel(order: order, gateway: gateway).pay()

        #expect(try await store.payments(for: "u1").count == 1)
    }

    @Test("Trying another method returns to the picker with the failure cleared")
    func chooseAnotherMethod() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        await gateway.forceFailure(.insufficientFunds)

        let viewModel = PaymentViewModel(order: try makeOrder(), gateway: gateway)
        await viewModel.pay()
        #expect(viewModel.failureReason != nil)

        viewModel.chooseAnotherMethod()
        #expect(viewModel.failureReason == nil)
        #expect(viewModel.phase == .choosing)
    }

    @Test("The receipt names the card's last four and the charge reference")
    func receiptRows() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        let viewModel = PaymentViewModel(order: try makeOrder(), gateway: gateway)

        await viewModel.pay()

        let receipt = try #require(viewModel.receipt)
        let rows = viewModel.receiptRows(receipt)
        let values = rows.map(\.value).joined(separator: " | ")

        #expect(values.contains("4242"), "the sandbox card's last four")
        #expect(values.contains(receipt.tapChargeId))
    }

    @Test("The unlocked list is the plan's entitlement, with unlimited spelled out")
    func unlockedRows() async throws {
        let store = InMemorySubscriptionStore()
        let gateway = SimulatedTapGateway(store: store, latency: .zero)
        let viewModel = PaymentViewModel(order: try makeOrder(plan: .pro), gateway: gateway)

        await viewModel.pay()

        let rows = viewModel.unlockedRows(.pro)
        #expect(rows.count == 3)
        // Pro is unlimited on materials and groups.
        #expect(rows.contains { $0.value == L10n.subscriptionUnlimited.string })
    }
}
