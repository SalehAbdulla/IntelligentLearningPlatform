//
//  AIRoutingPolicy.swift
//  StudyForge
//
//  F12 — the engine-routing policy an admin can set (docs/03 §K, K07; docs/05 §2.1 `aiConfig`).
//
//  WHY THIS IS A POLICY AND NOT A SETTING BURIED IN THE ROUTER
//  -----------------------------------------------------------
//  The router's default order is a product decision ("free tier first, cloud as the fallback"), and
//  K07 exists so that decision can be changed WITHOUT a build. Modelling it as a value the router
//  consults keeps the decision in one readable place, and — importantly — keeps the router's
//  behaviour testable against every policy rather than only the one it happens to ship with.
//
//  WHY THE ORDERING IS A PARTITION AND NOT A SORT
//  ----------------------------------------------
//  Swift's `sorted` is not guaranteed stable, so sorting by "is this on-device?" could reorder two
//  cloud tiers relative to each other and change which engine runs. Two filters — the preferred
//  group first, the rest after — express the same intent and are obviously correct, which matters
//  more here than brevity: a router whose order is subtly un-pinned is a router nobody can reason
//  about.
//

import Foundation

/// Which engine the app should prefer. The admin-configurable half of the cost strategy.
enum AIRoutingPolicy: String, Sendable, CaseIterable, Codable, Identifiable {
    /// On-device first (the shipped default): free and private, cloud only as a fallback.
    case onDeviceFirst

    /// Cloud first: better quality, spends the metered budget.
    case cloudFirst

    /// Never call the cloud. A task that cannot run on-device reports why rather than spending.
    case offlineOnly

    var id: String { rawValue }

    /// The localised name, for K07's selector.
    var title: String {
        switch self {
        case .onDeviceFirst: L10n.adminPolicyOnDeviceFirst.string
        case .cloudFirst: L10n.adminPolicyCloudFirst.string
        case .offlineOnly: L10n.adminPolicyOfflineOnly.string
        }
    }

    /// Reorders a task's preferred tiers under this policy.
    ///
    /// The task's own preference still decides WHICH tiers are candidates and their order within
    /// each group; the policy only decides whether the device leads and whether the cloud may be
    /// reached at all. That split is what keeps a multimodal task — which cannot run on-device at
    /// all — from being sent to a text-only engine.
    func ordered(_ preference: [AITier]) -> [AITier] {
        switch self {
        case .onDeviceFirst:
            return preference.filter { $0 == .onDevice } + preference.filter { $0 != .onDevice }
        case .cloudFirst:
            return preference.filter { $0 != .onDevice } + preference.filter { $0 == .onDevice }
        case .offlineOnly:
            return preference.filter { $0 == .onDevice }
        }
    }
}