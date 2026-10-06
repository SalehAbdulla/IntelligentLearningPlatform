//
//  AIConfiguration.swift
//  StudyForge
//
//  F12 — the platform's AI settings, as an admin sets them (docs/03 §K, K07; docs/05 §2.1 `aiConfig`).
//
//  WHY THIS EXISTS AT ALL
//  ----------------------
//  The AI router's behaviour was a compile-time decision: the order lived in `AITask.tierPreference`
//  and the quota in `SubscriptionPlan`. K07's whole point is that both should be settable without a
//  build — which matters beyond convenience, because it is the screen that makes the cost governor
//  OPERATIONAL rather than a paragraph in a design document. An admin can see what is being spent and
//  change the policy that spends it.
//
//  WHAT IS CONFIGURABLE, AND WHAT DELIBERATELY IS NOT
//  -------------------------------------------------
//  The routing policy and the daily ceiling are here. The PROMPT TEMPLATES are not: they live in
//  `PromptTemplates` as compiled code, and an editor over them is only honest against a real
//  `aiConfig` document served by a backend (docs/05 §2.1 says as much — the app reads that document
//  through Remote Config). Shipping a local editor would let an admin change prompts that only their
//  own device would ever use, which is worse than not offering it.
//

import Foundation

/// The platform's AI settings.
struct AIConfiguration: Equatable, Sendable, Codable {

    /// Which engine the router prefers. See `AIRoutingPolicy`.
    var policy: AIRoutingPolicy

    /// The admin's daily ceiling for cloud generations, or `nil` to use the plan's own limit.
    var dailyQuotaOverride: Int?

    init(policy: AIRoutingPolicy = .onDeviceFirst, dailyQuotaOverride: Int? = nil) {
        self.policy = policy
        self.dailyQuotaOverride = dailyQuotaOverride
    }

    /// The shipped behaviour: on-device first, plan default quota.
    ///
    /// The default is the important part — an install with no admin configuration behaves exactly as
    /// it did before this type existed, so the feature can be added without changing anyone's app.
    static let `default` = AIConfiguration()

    /// Whether the config still matches the shipped defaults.
    var isDefault: Bool { self == .default }

    /// The ceiling the app will actually apply, given a plan's own limit.
    func effectiveQuota(planLimit: Int) -> Int { dailyQuotaOverride ?? planLimit }
}