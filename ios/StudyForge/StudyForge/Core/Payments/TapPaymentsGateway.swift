//
//  TapPaymentsGateway.swift
//  StudyForge
//
//  F13: the real gateway, Tap Company via the `createCharge` function.
//
//  THE FLOW
//  --------
//  1. Ask the server to start a charge (`createCharge`). The amount is resolved server-side.
//  2. Open the Tap hosted page it returns.
//  3. Poll the entitlement the Tap webhook writes to `subscriptions/{uid}` until it appears.
//  4. Return the entitlement AND its receipt, both read from Firestore, never decided here.
//
//  WHY IT POLLS RATHER THAN RETURNING STRAIGHT AWAY
//  ------------------------------------------------
//  Tap confirms a payment asynchronously, by webhook. The client cannot mark an account paid;
//  it can only observe what the webhook wrote, which is the whole point of the access model.
//  Polling is the honest shape of that.
//

import Foundation

actor TapPaymentsGateway: PaymentGateway {

    private let caller: any ChargeCaller
    private let store: any SubscriptionStore
    private let launcher: any URLLauncher

    /// How long to wait between entitlement checks, and in total before giving up.
    private let pollInterval: Duration
    private let timeout: Duration

    init(
        caller: any ChargeCaller,
        store: any SubscriptionStore,
        launcher: any URLLauncher,
        pollInterval: Duration = .seconds(2),
        timeout: Duration = .seconds(180)
    ) {
        self.caller = caller
        self.store = store
        self.launcher = launcher
        self.pollInterval = pollInterval
        self.timeout = timeout
    }

    func startCheckout(order: Order, method: PaymentMethod) async throws -> PaymentOutcome {
        // 1. Start the charge on the server. A failure here never charged anyone.
        let ticket: ChargeTicket
        do {
            ticket = try await caller.createCharge(
                planId: order.plan.rawValue,
                term: order.term.rawValue
            )
        } catch {
            return .failed(.gatewayUnavailable)
        }

        // 2. Send the student to Tap's hosted page.
        if let url = ticket.redirectURL {
            await launcher.open(url)
        }

        // 3. Poll for the entitlement and its receipt, both written by the webhook.
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if let subscription = try? await store.subscription(for: order.uid),
               subscription.isEntitled,
               subscription.plan == order.plan,
               let receipt = try? await store.succeededPayment(idempotencyKey: order.idempotencyKey) {
                return .succeeded(subscription: subscription, receipt: receipt)
            }
            try? await Task.sleep(for: pollInterval)
        }

        // 4. Nothing arrived inside the window: the 3-D Secure step was abandoned or timed out.
        return .failed(.threeDSecureTimeout)
    }

    func restoreEntitlements(uid: String) async throws -> Subscription? {
        try await store.subscription(for: uid)
    }
}
