//
//  ManageSubscriptionViewModel.swift
//  StudyForge
//
//  F13 — presentation logic for L10 (`127_Subscription_Manage_Cancel_{M3}`) and the
//  settings row B13 (`23_Settings_Subscription_{M1}`).
//
//  WHY CANCELLING DOES NOT REVOKE ACCESS IMMEDIATELY
//  -------------------------------------------------
//  L10's retention dialog promises the student keeps what they paid for until the period
//  ends. That is not a nicety — taking money for a month and ending access on the cancel
//  tap would be the wrong thing to do, and it is also what `Subscription.isEntitled`
//  encodes. So cancel flips the status to `.cancelled` and turns off auto-renew; the
//  entitlement itself is untouched.
//

import Foundation

@MainActor
@Observable
final class ManageSubscriptionViewModel {

    // MARK: Bound state

    private(set) var state: LoadState<Subscription?> = .idle

    /// The account's receipts, most recent first (L10's billing history).
    private(set) var receipts: [PaymentRecord] = []

    /// The method marked default in this session. Seeded from the most recently used one.
    ///
    /// Not persisted yet: it belongs on `subscriptionPrefs/{uid}` alongside the account's
    /// other preferences, which is a later feature — recorded rather than faked with a
    /// `UserDefaults` write that would silently disagree with the server.
    private(set) var defaultMethod: PaymentMethod?

    private(set) var isCancelling = false
    private(set) var actionError: AppError?

    private let uid: String
    private let store: any SubscriptionStore

    init(uid: String, store: any SubscriptionStore) {
        self.uid = uid
        self.store = store
    }

    // MARK: Derived

    var subscription: Subscription? { state.value ?? nil }
    var plan: SubscriptionPlan { subscription?.plan ?? .free }
    var isPremium: Bool { subscription?.isPremium ?? false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { state.error ?? actionError }

    /// The distinct methods that actually appear in the history, most recent first.
    var methods: [PaymentMethod] {
        var seen: [PaymentMethod] = []
        for receipt in receipts where !seen.contains(receipt.method) {
            seen.append(receipt.method)
        }
        return seen
    }

    var hasHistory: Bool { !receipts.isEmpty }

    // MARK: Copy

    var title: String { L10n.subscriptionTitle.string }
    var currentPlanLabel: String { L10n.subscriptionCurrentPlanLabel.string }
    var paymentMethodsTitle: String { L10n.subscriptionPaymentMethods.string }
    var defaultBadge: String { L10n.subscriptionDefaultBadge.string }
    var makeDefaultTitle: String { L10n.subscriptionMakeDefault.string }
    var cancelTitle: String { L10n.subscriptionCancel.string }
    var cancelConfirmTitle: String { L10n.subscriptionCancelConfirmTitle.string }
    var keepPlanTitle: String { L10n.subscriptionKeepPlan.string }
    var confirmCancelTitle: String { L10n.subscriptionConfirmCancel.string }
    var cancelledNote: String { L10n.subscriptionCancelledNote.string }
    var freeBody: String { L10n.subscriptionFreeBody.string }
    var upgradeTitle: String { L10n.subscriptionUpgrade.string }
    var historyTitle: String { L10n.subscriptionHistory.string }
    var noHistoryTitle: String { L10n.subscriptionNoHistory.string }

    var planValue: String { plan.displayName }

    /// The renewal line: when it renews, or when access ends if it has been cancelled.
    /// `nil` on a free account, where neither sentence is true.
    var renewalText: String? {
        guard let subscription, let end = subscription.periodEnd else { return nil }
        let date = end.formatted(date: .abbreviated, time: .omitted)

        if subscription.isEndingAtPeriodEnd {
            return L10n.subscriptionEndsOn.string(date)
        }
        guard subscription.isEntitled else { return nil }
        return subscription.autoRenews
            ? L10n.subscriptionRenewsOn.string(date)
            : L10n.subscriptionEndsOn.string(date)
    }

    var autoRenewText: String? {
        guard let subscription, subscription.isEntitled, subscription.plan.isPaid else { return nil }
        return subscription.autoRenews
            ? L10n.subscriptionAutoRenewOn.string
            : L10n.subscriptionAutoRenewOff.string
    }

    /// The retention dialog's body, naming the plan and the date access ends.
    var cancelConfirmBody: String {
        let date = subscription?.periodEnd?.formatted(date: .abbreviated, time: .omitted) ?? "—"
        return L10n.subscriptionCancelConfirmBody.string(plan.displayName, date)
    }

    /// Can the account be cancelled at all? Only a paid, still-renewing subscription can.
    var canCancel: Bool {
        guard let subscription, subscription.plan.isPaid else { return false }
        return subscription.isEntitled && subscription.status != .cancelled
    }

    func methodName(_ method: PaymentMethod) -> String {
        switch method {
        case .card: L10n.subscriptionMethodCard.string
        case .benefitPay: L10n.subscriptionMethodBenefitPay.string
        case .applePay: L10n.subscriptionMethodApplePay.string
        case .knet: L10n.subscriptionMethodKnet.string
        }
    }

    // MARK: Actions

    func load() async {
        state = .loading
        actionError = nil
        do {
            let subscription = try await store.subscription(for: uid)
            let payments = try await store.payments(for: uid)
            receipts = payments
            if defaultMethod == nil {
                defaultMethod = payments.first(where: { $0.status == .succeeded })?.method
            }
            state = .loaded(subscription)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Cancels at period end: turns off auto-renew but leaves the entitlement in force.
    func cancel() async {
        guard var subscription = subscription, !isCancelling else { return }

        isCancelling = true
        defer { isCancelling = false }

        subscription.status = .cancelled
        subscription.autoRenews = false

        do {
            try await store.upsert(subscription)
            await load()
        } catch {
            actionError = AppError.from(error)
        }
    }

    /// Marks a method as the session default. See the note on `defaultMethod` for why this
    /// is not yet persisted.
    func makeDefault(_ method: PaymentMethod) {
        defaultMethod = method
    }
}
