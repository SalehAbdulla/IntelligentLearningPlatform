//
//  Subscription.swift
//  StudyForge
//
//  F13 — the entitlement record: what plan a student holds, until when, and whether it
//  renews (docs/05 §2 `subscriptions/{uid}`; docs/03 §L B13/L10).
//
//  WHY THIS RECORD IS READ-ONLY TO THE CLIENT
//  ------------------------------------------
//  `backend/firestore.rules` grants `subscriptions/{uid}` a client READ and NO WRITE —
//  "Entitlements come from the Tap Payments webhook and nowhere else." This type is
//  therefore a value the app OBSERVES, never one it edits. There is deliberately no
//  `plan` setter a screen could reach for: a self-upgrade is the exact exploit the rules
//  exist to deny, and it should not be one line of Swift away.
//

import Foundation

/// Where a subscription stands right now.
enum SubscriptionStatus: String, Sendable, Codable, CaseIterable {
    /// Paid and in force.
    case active

    /// Cancelled, but still paid up until `periodEnd` — the state L10's retention dialog
    /// produces, and the reason access does not end the moment the user taps Cancel.
    case cancelled

    /// The paid period has run out.
    case expired

    /// No subscription has ever existed for this account.
    case none
}

/// A student's entitlement, mirroring `subscriptions/{uid}`.
struct Subscription: Identifiable, Equatable, Sendable, Codable {

    /// The owning uid — Firestore keys this document by user id, so the id and the owner
    /// are the same string. Naming it `id` lets the type drop into a `ForEach`.
    let id: String

    var plan: SubscriptionPlan
    var status: SubscriptionStatus

    /// When the currently-paid period began and ends. `nil` for a free account that has
    /// never been billed.
    var periodStart: Date?
    var periodEnd: Date?

    /// The Tap charge that created this entitlement. Kept so a support question ("which
    /// payment is this?") has an answer, and so the webhook can be idempotent against it.
    var tapChargeId: String?

    /// Whether the plan renews automatically. Turned off by L10's Cancel.
    var autoRenews: Bool

    init(
        id: String,
        plan: SubscriptionPlan,
        status: SubscriptionStatus,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        tapChargeId: String? = nil,
        autoRenews: Bool = false
    ) {
        self.id = id
        self.plan = plan
        self.status = status
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.tapChargeId = tapChargeId
        self.autoRenews = autoRenews
    }

    /// The entitlement every account starts with. Free, no dates, no charge — the honest
    /// representation of "nothing has been bought".
    static func free(uid: String) -> Subscription {
        Subscription(id: uid, plan: .free, status: .active, autoRenews: false)
    }

    /// Whether the plan is currently entitling the student to its features.
    ///
    /// The subtle case is `.cancelled`: L10 lets a student cancel without losing what they
    /// paid for, so a cancelled subscription is still entitled until `periodEnd`. A
    /// `periodEnd` in the past collapses to `.expired` in the UI even before a nightly job
    /// would rewrite the status, because a date the app can compare is more reliable than
    /// a flag that depends on a job having run.
    var isEntitled: Bool {
        switch status {
        case .active:
            // Active with no end date is the free entitlement: entitled, but to `free`.
            return periodEnd.map { $0 > .now } ?? true
        case .cancelled:
            return periodEnd.map { $0 > .now } ?? false
        case .expired, .none:
            return false
        }
    }

    /// Whether the student currently holds a PAID entitlement. The paywall and the
    /// settings row both key off this rather than off `status`, because "paid" is what the
    /// user actually cares about.
    var isPremium: Bool { plan.isPaid && isEntitled }

    /// When the plan next renews, or when access ends if it has been cancelled.
    var renewsOn: Date? { isEntitled ? periodEnd : nil }

    /// Whether this subscription has been cancelled but is still within its paid period —
    /// the state that needs the "access until …" copy rather than a plain renewal date.
    var isEndingAtPeriodEnd: Bool { status == .cancelled && isEntitled }
}
