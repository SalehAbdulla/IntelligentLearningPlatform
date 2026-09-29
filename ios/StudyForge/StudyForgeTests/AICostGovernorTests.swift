//
//  AICostGovernorTests.swift
//  StudyForgeTests
//
//  Tests for the mechanism that keeps StudyForge on a free tier.
//
//  These exist because the spike left a declared gap: the budget logic was verified
//  by observation, not assertion. A cost guard that is not tested is a cost guard that
//  silently stops working, and the failure mode is a bill.
//

import Foundation
import Testing
@testable import StudyForge

@MainActor
@Suite("AI cost governor")
struct AICostGovernorTests {

    /// A controllable clock, so crossing midnight does not require waiting for it.
    private final class TestClock: @unchecked Sendable {
        var now: Date
        init(_ now: Date) { self.now = now }
        func advance(days: Int) {
            now = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        }
    }

    private func makeGovernor(
        plan: SubscriptionPlan = .free,
        at date: Date = Date()
    ) -> (governor: AICostGovernor, clock: TestClock) {
        let clock = TestClock(date)
        return (AICostGovernor(plan: plan, clock: { clock.now }), clock)
    }

    // MARK: - The exemption that makes the product affordable

    @Test("On-device generation never consumes the cloud budget")
    func onDeviceIsExempt() {
        let (governor, _) = makeGovernor()

        for _ in 0..<50 {
            governor.record(tier: .onDevice, task: .summarize)
        }

        #expect(governor.usedToday == 0)
        #expect(governor.remaining == governor.limit)
        #expect(governor.hasBudget)
    }

    @Test("Cloud generation consumes exactly one unit per call")
    func cloudConsumesOneUnit() {
        let (governor, _) = makeGovernor()

        governor.record(tier: .firebaseAI, task: .makeFlashcards)
        #expect(governor.usedToday == 1)

        governor.record(tier: .cloudFunction, task: .makeQuiz)
        #expect(governor.usedToday == 2)
        #expect(governor.remaining == governor.limit - 2)
    }

    // MARK: - Exhaustion

    @Test("The budget is exhausted exactly at the limit, not before")
    func exhaustionBoundary() {
        let (governor, _) = makeGovernor(plan: .free)
        let limit = governor.limit

        governor.seed(usedToday: limit - 1)
        #expect(governor.hasBudget, "still one generation left")
        #expect(governor.remaining == 1)

        governor.record(tier: .firebaseAI, task: .summarize)
        #expect(governor.hasBudget == false)
        #expect(governor.remaining == 0)
    }

    @Test("The pro plan has no practical ceiling")
    func proPlanIsUnlimited() {
        let (governor, _) = makeGovernor(plan: .pro)
        governor.seed(usedToday: 100_000)
        #expect(governor.hasBudget, "pro must not run out during a demo")
    }

    // MARK: - Daily reset

    @Test("Crossing midnight refills the allowance")
    func dailyReset() {
        let (governor, clock) = makeGovernor()
        governor.seed(usedToday: governor.limit)
        #expect(governor.hasBudget == false)

        clock.advance(days: 1)

        #expect(governor.hasBudget, "a new day must restore the allowance")
        #expect(governor.usedToday == 0)
        #expect(governor.remaining == governor.limit)
    }

    @Test("Staying within the same day does not refill the allowance")
    func noResetWithinTheSameDay() {
        let noon = Calendar.current.startOfDay(for: Date()).addingTimeInterval(43_200)
        let (governor, clock) = makeGovernor(at: noon)
        governor.seed(usedToday: governor.limit)

        clock.now = noon.addingTimeInterval(3_600)   // one hour later, same day

        #expect(governor.hasBudget == false, "the counter must not reset hourly")
    }

    // MARK: - Response cache key

    @Test("The same input produces the same key across separate calls")
    func cacheKeyIsStable() {
        let first = AICostGovernor.cacheKey(
            text: "Third normal form removes transitive dependencies.",
            language: .english,
            learningStyle: .visual,
            variant: "summary-short-bullets"
        )
        let second = AICostGovernor.cacheKey(
            text: "Third normal form removes transitive dependencies.",
            language: .english,
            learningStyle: .visual,
            variant: "summary-short-bullets"
        )

        #expect(first == second, "a non-deterministic key would make the cache useless")
        #expect(first.count == 64, "SHA-256 hex digest")
    }

    @Test("Anything that changes the output changes the key", arguments: [
        (OutputLanguage.arabic, LearningStyle.visual, "summary-short-bullets"),
        (OutputLanguage.english, LearningStyle.kinesthetic, "summary-short-bullets"),
        (OutputLanguage.english, LearningStyle.visual, "summary-examReady-cornell"),
    ])
    func cacheKeyVariesWithOutputShape(
        language: OutputLanguage,
        style: LearningStyle,
        variant: String
    ) {
        let baseline = AICostGovernor.cacheKey(
            text: "Same source text for every case.",
            language: .english,
            learningStyle: .visual,
            variant: "summary-short-bullets"
        )
        let other = AICostGovernor.cacheKey(
            text: "Same source text for every case.",
            language: language,
            learningStyle: style,
            variant: variant
        )

        #expect(baseline != other,
                "\(language)/\(style)/\(variant) must not reuse the English visual summary")
    }

    @Test("Different source text produces a different key")
    func cacheKeyVariesWithText() {
        let a = AICostGovernor.cacheKey(text: "Document A", language: .english,
                                        learningStyle: .visual, variant: "v")
        let b = AICostGovernor.cacheKey(text: "Document B", language: .english,
                                        learningStyle: .visual, variant: "v")
        #expect(a != b)
    }
}
