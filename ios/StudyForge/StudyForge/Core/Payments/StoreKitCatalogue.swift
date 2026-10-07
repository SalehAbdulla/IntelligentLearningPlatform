//
//  StoreKitCatalogue.swift
//  StudyForge
//
//  F13: the bridge between a plan/term and an App Store product identifier.
//
//  WHY A SEPARATE TABLE FROM PaymentCatalogue
//  ------------------------------------------
//  `PaymentCatalogue` holds the BHD PRICES the brief's Tap flow uses. This holds the App Store
//  PRODUCT IDS, which are a different vocabulary: they must match App Store Connect exactly, so
//  they are not derived from a price and they must never be a display string.
//

import Foundation

/// App Store product identifiers, and the mapping back to a plan and term.
enum StoreKitCatalogue {

    /// The reverse-DNS product id for a plan and term, or `nil` when that pair is not sold.
    static func productId(_ plan: SubscriptionPlan, _ term: BillingTerm) -> String? {
        switch (plan, term) {
        case (.plus, .monthly): "com.studyforge.app.plus.monthly"
        case (.plus, .annual): "com.studyforge.app.plus.annual"
        case (.pro, .monthly): "com.studyforge.app.pro.monthly"
        case (.pro, .annual): "com.studyforge.app.pro.annual"
        case (.free, _): nil
        }
    }

    /// The plan and term a product id represents, or `nil` for an id we do not sell.
    static func plan(forProductId id: String) -> (plan: SubscriptionPlan, term: BillingTerm)? {
        switch id {
        case "com.studyforge.app.plus.monthly": (.plus, .monthly)
        case "com.studyforge.app.plus.annual": (.plus, .annual)
        case "com.studyforge.app.pro.monthly": (.pro, .monthly)
        case "com.studyforge.app.pro.annual": (.pro, .annual)
        default: nil
        }
    }
}
