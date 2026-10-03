//
//  AICostGovernor.swift
//  StudyForge
//
//  The **AI cost governor** — the mechanism that keeps StudyForge on a free tier.
//
//  TWO INDEPENDENT SAVINGS, AND WHY BOTH ARE NEEDED
//  -----------------------------------------------
//  1. **Only cloud calls spend budget.** Tier 0 runs on the device: it costs nothing
//     and is therefore unlimited. Counting it would make the free plan look scarce
//     while changing nothing about the actual bill — and would push users onto the
//     metered tier for no reason.
//
//  2. **Identical input is never generated twice.** The cache key is the SHA-256 of
//     the extracted text, so re-summarising the same PDF is answered with the stored
//     result. Without this, a student tapping "Generate" three times costs three
//     calls for one artefact.
//
//  Budget is tracked in memory now; S3 moves the count to `aiUsage/{uid}/days/{date}`
//  in Firestore so it survives reinstalls and cannot be reset by clearing the app.
//

import Foundation

@MainActor
@Observable
final class AICostGovernor {

    /// The tier's daily ceiling. On-device generation is exempt (see the file header).
    let plan: SubscriptionPlan

    /// An admin override for the daily ceiling (F12, K07).
    ///
    /// `nil` means "use the plan's own limit", which is the shipped behaviour — so an install with
    /// no admin configuration counts exactly as it did before this existed.
    var limitOverride: Int?

    private(set) var usedToday: Int = 0

    /// Local day the counter belongs to, so a stale count is discarded after midnight
    /// rather than silently carrying over.
    private var countedDay: Date

    /// Supplies "now". Injected rather than called directly so the daily reset can be
    /// tested without waiting until midnight.
    @ObservationIgnored
    private let clock: @Sendable () -> Date

    init(plan: SubscriptionPlan = .free,
         clock: @escaping @Sendable () -> Date = { Date() }) {
        self.plan = plan
        self.clock = clock
        self.countedDay = Calendar.current.startOfDay(for: clock())
    }

    // MARK: - Budget

    /// Daily cloud-generation ceiling for this plan, or the admin's override when one is set.
    var limit: Int { limitOverride ?? plan.dailyAIGenerationLimit }

    var hasBudget: Bool {
        resetIfNeeded()
        return usedToday < limit
    }

    var remaining: Int {
        resetIfNeeded()
        return max(0, limit - usedToday)
    }

    /// When the allowance refreshes. Shown in the quota-exceeded screen so the user
    /// is told when to come back rather than just being refused.
    var resetsAt: Date {
        Calendar.current.startOfDay(for: clock()).addingTimeInterval(86_400)
    }

    /// Records one cloud generation. On-device calls are deliberately ignored.
    func record(tier: AITier, task: AITask) {
        guard tier != .onDevice else { return }
        resetIfNeeded()
        usedToday += 1
    }

    /// Exposed so tests and previews can set up a specific state without generating.
    func seed(usedToday value: Int) {
        countedDay = Calendar.current.startOfDay(for: clock())
        usedToday = value
    }

    private func resetIfNeeded() {
        let today = Calendar.current.startOfDay(for: clock())
        guard today != countedDay else { return }
        countedDay = today
        usedToday = 0
    }

    // MARK: - Response cache

    /// Stable cache key for a piece of source text.
    ///
    /// SHA-256 rather than `hashValue`, because Swift's `Hashable` is randomly seeded
    /// per process: the same document would produce a different key on every launch,
    /// and the cache would never hit.
    ///
    /// The dimensions that change output are folded in, so a short exam-ready Arabic
    /// summary never serves a long English bulleted one.
    static func cacheKey(
        text: String,
        language: OutputLanguage,
        learningStyle: LearningStyle,
        variant: String
    ) -> String {
        let material = [text, language.rawValue, learningStyle.rawValue, variant]
            .joined(separator: "\u{1F}")
        return ContentHash.sha256Hex(of: material)
    }

    /// Number of cloud generations a document would cost if not cached.
    /// Used by the UI to warn before an expensive action.
    static func estimatedCostMicros(textLength: Int) -> Int {
        // Rough: the tier-1 free quota is limited by requests, not tokens, so the
        // meaningful estimate is "one request" — kept as a hook for tier-2 pricing,
        // where tokens do cost money.
        textLength > 60_000 ? 2 : 1
    }
}
