//
//  PaywallViewModel.swift
//  StudyForge
//
//  F13 — presentation logic for L01 (`118_Paywall_Plans_{M3}`), the plan chooser.
//
//  WHY IT READS THE ENTITLEMENT ON APPEAR
//  --------------------------------------
//  "Restore purchases" is not a rare recovery action here; it is the normal path, because
//  the entitlement lives server-side and the device remembers nothing about it. So the
//  screen starts by asking the source of truth what the account owns, and marks the
//  current plan from that answer rather than from anything it was told.
//

import Foundation

@MainActor
@Observable
final class PaywallViewModel {

    // MARK: Bound state

    /// The monthly / annual toggle (L01).
    var term: BillingTerm = .annual

    /// The plan the carets flow into checkout from.
    var selectedPlan: SubscriptionPlan = PaymentCatalogue.recommendedPlan

    /// The entitlement as last read. `loaded(nil)` means "no subscription yet".
    private(set) var state: LoadState<Subscription?> = .idle

    private(set) var isRestoring = false

    private let uid: String
    private let gateway: any PaymentGateway

    init(uid: String, store: any SubscriptionStore, gateway: any PaymentGateway) {
        self.uid = uid
        self.gateway = gateway
        // `store` is accepted for symmetry with the other screens and so a caller can pass
        // the same pair everywhere; the paywall itself only reads through the gateway, so
        // that there is exactly one way to learn what an account owns.
    }

    // MARK: Derived

    var plans: [SubscriptionPlan] { PaymentCatalogue.purchasablePlans }
    var subscription: Subscription? { state.value ?? nil }
    var currentPlan: SubscriptionPlan { subscription?.plan ?? .free }
    var isPremium: Bool { subscription?.isPremium ?? false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { state.error }

    // MARK: Copy

    var title: String { L10n.subscriptionPaywallTitle.string }
    var subtitle: String { L10n.subscriptionPaywallSubtitle.string }
    var monthlyTitle: String { L10n.subscriptionTermMonthly.string }
    var annualTitle: String { L10n.subscriptionTermAnnual.string }
    var recommendedTitle: String { L10n.subscriptionRecommended.string }
    var continueTitle: String { L10n.commonContinue.string }
    var restoreTitle: String { L10n.subscriptionRestore.string }
    var compareTitle: String { L10n.subscriptionCompareTitle.string }
    var currentTitle: String { L10n.subscriptionCurrent.string }
    var perMonthTitle: String { L10n.subscriptionPerMonth.string }
    var upgradeTitle: String { L10n.subscriptionUpgrade.string }

    /// The plan's display name. Reuses `SubscriptionPlan.displayName`, the same value the
    /// home screen and the admin directory already show.
    func planName(_ plan: SubscriptionPlan) -> String { plan.displayName }

    func isRecommended(_ plan: SubscriptionPlan) -> Bool {
        plan == PaymentCatalogue.recommendedPlan
    }

    func isCurrent(_ plan: SubscriptionPlan) -> Bool { plan == currentPlan }

    /// The price for the selected term, or `nil` when the plan is not sold for it.
    ///
    /// Free resolves to `BHD 0.000` rather than `nil`, because L01 shows a price even on
    /// the free card — "no price" reads as a bug, not as "free".
    func priceLabel(_ plan: SubscriptionPlan) -> String? {
        if plan == .free { return MoneyText.price(0) }
        guard let fils = PaymentCatalogue.priceInFils(plan, term) else { return nil }
        return MoneyText.price(fils)
    }

    /// The per-month figure shown under an annual price, so the two terms are comparable.
    /// Only shown for the annual term — on monthly it is the price again.
    func perMonthLabel(_ plan: SubscriptionPlan) -> String? {
        guard term == .annual, plan.isPaid,
              let annual = PaymentCatalogue.priceInFils(plan, .annual) else { return nil }
        return MoneyText.price(annual / BillingTerm.annual.months)
    }

    /// L01's "save %" badge, annual term only.
    func savingLabel(_ plan: SubscriptionPlan) -> String? {
        guard term == .annual, let percent = PaymentCatalogue.annualSavingPercent(plan) else {
            return nil
        }
        return L10n.subscriptionSavePercent.string(percent)
    }

    // MARK: Actions

    /// Reads the entitlement the account actually holds.
    func load() async {
        state = .loading
        do {
            let subscription = try await gateway.restoreEntitlements(uid: uid)
            state = .loaded(subscription)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// L01's "restore purchases" — a re-read with a visible in-progress state, because a
    /// user who taps it expects something to happen even when the answer is unchanged.
    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        await load()
    }
}
