//
//  TapPaymentsGatewayTests.swift
//  StudyForgeTests
//
//  Tests for F13's real Tap gateway: it starts a charge, opens the redirect, and returns the
//  entitlement the webhook wrote, never one it decided itself.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Tap payments gateway (F13)")
struct TapPaymentsGatewayTests {

    /// A charge caller that returns a canned ticket, or fails on demand.
    private struct FakeCaller: ChargeCaller {
        let ticket: ChargeTicket
        var shouldFail = false

        func createCharge(planId: String, term: String) async throws -> ChargeTicket {
            if shouldFail { throw ChargeCallerError.unavailable }
            return ticket
        }
    }

    /// Records the URLs the gateway opens, instead of presenting Safari.
    private actor RecordingLauncher: URLLauncher {
        private(set) var opened: [URL] = []
        func open(_ url: URL) async { opened.append(url) }
    }

    private func order() -> Order {
        Order(
            uid: "u1",
            plan: .plus,
            term: .monthly,
            subtotalFils: 1_727,
            discountFils: 0,
            vatFils: 173,
            totalFils: 1_900,
            currency: MoneyCurrency.bhd,
            promoCode: nil
        )
    }

    @Test("Opens the Tap redirect and returns the entitlement the webhook wrote")
    func succeedsFromWebhookEntitlement() async throws {
        let launcher = RecordingLauncher()
        let store = InMemorySubscriptionStore()
        let order = order()

        // Seed exactly what the webhook would have written.
        try await store.upsert(Subscription(
            id: "u1",
            plan: .plus,
            status: .active,
            periodStart: .now,
            periodEnd: .now.addingTimeInterval(30 * 24 * 3600),
            tapChargeId: "tap_test_1",
            autoRenews: true
        ))
        try await store.record(PaymentRecord(
            id: "p1",
            uid: "u1",
            plan: .plus,
            term: .monthly,
            amountFils: 1_900,
            vatFils: 173,
            currency: MoneyCurrency.bhd,
            method: .card,
            last4: "4242",
            tapChargeId: "tap_test_1",
            idempotencyKey: order.idempotencyKey,
            status: .succeeded,
            paidAt: .now
        ))

        let gateway = TapPaymentsGateway(
            caller: FakeCaller(ticket: ChargeTicket(
                tapChargeId: "tap_test_1",
                redirectURL: URL(string: "https://tap.company/pay/1")
            )),
            store: store,
            launcher: launcher,
            pollInterval: .milliseconds(5),
            timeout: .seconds(2)
        )

        let outcome = try await gateway.startCheckout(order: order, method: .card)

        let opened = await launcher.opened
        #expect(opened.count == 1)
        guard case .succeeded(let subscription, let receipt) = outcome else {
            Issue.record("expected success, got \(outcome)")
            return
        }
        #expect(subscription.plan == .plus)
        #expect(receipt.tapChargeId == "tap_test_1")
    }

    @Test("A charge that cannot start is a gateway failure, and no URL is opened")
    func unavailableCallerFails() async throws {
        let launcher = RecordingLauncher()
        let gateway = TapPaymentsGateway(
            caller: FakeCaller(
                ticket: ChargeTicket(tapChargeId: "", redirectURL: nil),
                shouldFail: true
            ),
            store: InMemorySubscriptionStore(),
            launcher: launcher,
            pollInterval: .milliseconds(5),
            timeout: .milliseconds(40)
        )

        let outcome = try await gateway.startCheckout(order: order(), method: .card)

        #expect(outcome == .failed(.gatewayUnavailable))
        let opened = await launcher.opened
        #expect(opened.isEmpty)
    }

    @Test("No entitlement inside the window is a 3-D Secure timeout")
    func noEntitlementTimesOut() async throws {
        let gateway = TapPaymentsGateway(
            caller: FakeCaller(ticket: ChargeTicket(
                tapChargeId: "tap_test_2",
                redirectURL: nil
            )),
            store: InMemorySubscriptionStore(),
            launcher: RecordingLauncher(),
            pollInterval: .milliseconds(5),
            timeout: .milliseconds(40)
        )

        let outcome = try await gateway.startCheckout(order: order(), method: .card)

        #expect(outcome == .failed(.threeDSecureTimeout))
    }
}
