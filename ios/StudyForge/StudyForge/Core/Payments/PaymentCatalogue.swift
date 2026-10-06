//
//  PaymentCatalogue.swift
//  StudyForge
//
//  F13 — what each subscription tier costs and what it unlocks.
//  (docs/02 F13; docs/03 §L L01–L02; docs/04 §6; docs/05 §2 `subscriptions`.)
//
//  WHY THE CATALOGUE IS CODE AND NOT A FIRESTORE DOCUMENT
//  -----------------------------------------------------
//  `createCharge` already resolves the amount SERVER-SIDE from this same table
//  (`backend/functions/src/index.ts`), which is what makes a client-tampered price
//  harmless. The client copy exists only to DISPLAY a price before the call; it is never
//  the authority. Keeping the two tables identical is a review checklist item, and the
//  numbers here are asserted in `PaymentCatalogueTests` so a drift is a red test rather
//  than a wrong total on a receipt.
//
//  WHY FUNDS ARE STORED IN FILS, NOT DECIMAL
//  -----------------------------------------
//  The Bahraini dinar has THREE decimal places (1000 fils = BHD 1.000), and money in a
//  `Double` is a rounding error waiting to happen. Every amount is an `Int` count of
//  fils, and formatting to a human string happens once, at the edge.
//

import Foundation

/// How often a plan is billed (L01's monthly / annual toggle).
enum BillingTerm: String, Sendable, Codable, CaseIterable, Identifiable {
    case monthly
    case annual

    var id: String { rawValue }

    /// Months covered by one term.
    ///
    /// Derived here rather than written at each call site, so the "per month" figure the
    /// annual toggle shows is computed from the term itself and cannot disagree with it.
    var months: Int {
        switch self {
        case .monthly: 1
        case .annual: 12
        }
    }
}

/// The currency the catalogue is priced in. A one-value namespace today, but naming it
/// stops `"BHD"` and `1000` from being typed at four call sites.
enum MoneyCurrency {
    /// ISO 4217 code. Not localised — it is an identifier, like a UID.
    static let bhd = "BHD"

    /// Fils per dinar. Bahrain uses three minor-unit digits, not two.
    static let minorUnitsPerMajor = 1000
}

/// The single source of plan pricing and entitlements (docs/04 §6's BHD table).
enum PaymentCatalogue {

    /// Bahrain VAT. A single constant, because a rate typed at three sites is three
    /// chances to disagree — and disagreement shows up as a receipt that does not add up.
    static let vatPercent = 10

    /// The plans shown on the paywall, in display order (L01).
    static let purchasablePlans: [SubscriptionPlan] = [.free, .plus, .pro]

    /// The plan carrying L01's "recommended" ribbon.
    static let recommendedPlan: SubscriptionPlan = .plus

    /// Price in fils for a plan and term, or `nil` when the combination is not sold.
    ///
    /// Free has no annual term and never will — a paid annual price for a free plan is a
    /// distinction without a difference, and modelling it as `0` would invent a checkout
    /// for something that costs nothing.
    static func priceInFils(_ plan: SubscriptionPlan, _ term: BillingTerm) -> Int? {
        switch (plan, term) {
        case (.free, _): nil
        case (.plus, .monthly): 1_900
        case (.plus, .annual): 19_000
        case (.pro, .monthly): 4_900
        case (.pro, .annual): 49_000
        }
    }

    /// How much cheaper the annual term is than twelve monthly payments, as a whole percent.
    ///
    /// This is L01's "save %" badge and it is COMPUTED, not a hard-coded `17`: if a price
    /// changes, the badge follows. `nil` when there is no annual price to compare.
    static func annualSavingPercent(_ plan: SubscriptionPlan) -> Int? {
        guard
            let monthly = priceInFils(plan, .monthly), monthly > 0,
            let annual = priceInFils(plan, .annual)
        else { return nil }

        let twelveMonthly = monthly * 12
        guard twelveMonthly > 0 else { return nil }
        return Int((Double(twelveMonthly - annual) / Double(twelveMonthly) * 100).rounded())
    }

    /// A fils amount as a human string with three decimals and the locale's grouping —
    /// `1 900` fils renders as `1.900`.
    ///
    /// The currency CODE is deliberately not baked in here: L10n wraps this number, so
    /// Arabic can render `د.ب 1.900` without a second formatter.
    static func amountString(_ fils: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        formatter.locale = locale

        let value = Double(fils) / Double(MoneyCurrency.minorUnitsPerMajor)
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.3f", value)
    }
}

// MARK: - Per-plan entitlements

extension SubscriptionPlan {

    /// Whether this plan is a paid tier. Read by the paywall to decide what to show and
    /// by the receipt to decide what a purchase actually unlocked.
    var isPaid: Bool { self != .free }

    /// Saved materials the plan may hold, or `nil` for unlimited (docs/04 §6).
    var includedMaterials: Int? {
        switch self {
        case .free: 20
        case .plus: 200
        case .pro: nil
        }
    }

    /// Group revision spaces the plan may own, or `nil` for unlimited.
    var includedGroupSpaces: Int? {
        switch self {
        case .free: 1
        case .plus: 5
        case .pro: nil
        }
    }

    /// The plans strictly below this one (cheapest first) — the tiers a receipt's
    /// "unlocked features" delta is measured against (L08).
    var upgradedFrom: [SubscriptionPlan] {
        SubscriptionPlan.allCases.filter { $0.dailyAIGenerationLimit < dailyAIGenerationLimit }
    }
}
