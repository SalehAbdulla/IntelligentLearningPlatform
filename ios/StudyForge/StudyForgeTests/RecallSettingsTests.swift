//
//  RecallSettingsTests.swift
//  StudyForgeTests
//
//  Tests for F17's deck options and learning-step state machine.
//
//  These exist because the learning steps decide whether a card the learner just failed comes
//  back inside the sitting or disappears for a day. Getting that backwards would be invisible in
//  a build and obvious only to a student revising, which is exactly the class of bug a test is
//  for.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("F17 recall settings")
struct RecallSettingsTests {

    // MARK: Clamping — a stored document is untrusted input

    @Test("Defaults match Anki's own out of the box")
    func defaultsMatchAnki() {
        let settings = RecallSettings.default
        #expect(settings.learningStepMinutes == [1, 10])
        #expect(settings.newCardsPerDay == 20)
        #expect(settings.maxReviewsPerDay == 200)
        #expect(settings.matureAfterDays == 21)
        #expect(settings.stepCount == 2)
    }

    @Test("An empty step list falls back to the default rather than stranding a new card")
    func emptyStepsFallBack() {
        #expect(RecallSettings(learningStepMinutes: []).learningStepMinutes == [1, 10])
        // A list of only non-positive values is empty in effect, so it takes the same path.
        #expect(RecallSettings(learningStepMinutes: [0, -5]).learningStepMinutes == [1, 10])
    }

    @Test("Steps are sorted and negatives dropped, so the ladder always ascends")
    func stepsAreNormalised() {
        #expect(RecallSettings(learningStepMinutes: [10, 1, 5]).learningStepMinutes == [1, 5, 10])
        #expect(RecallSettings(learningStepMinutes: [10, -1, 1]).learningStepMinutes == [1, 10])
    }

    @Test("Negative daily ceilings are clamped to zero")
    func ceilingsAreClamped() {
        let settings = RecallSettings(newCardsPerDay: -3, maxReviewsPerDay: -1)
        #expect(settings.newCardsPerDay == 0)
        #expect(settings.maxReviewsPerDay == 0)
    }

    @Test("Maturity can never sit below the graduating interval")
    func maturityNeverPrecedesGraduation() {
        // Asking for maturity at 2 days while graduating to 5 would make a card mature the
        // instant it graduates, which is a contradiction rather than a preference.
        let settings = RecallSettings(graduatingIntervalDays: 5, matureAfterDays: 2)
        #expect(settings.graduatingIntervalDays == 5)
        #expect(settings.matureAfterDays == 5)
    }

    @Test("A zero graduating interval is raised to one day")
    func graduationIsAtLeastADay() {
        #expect(RecallSettings(graduatingIntervalDays: 0).graduatingIntervalDays == 1)
    }

    // MARK: Derived state — O01's four counters

    @Test("A never-reviewed card is new")
    func neverReviewedIsNew() {
        let settings = RecallSettings.default
        let sr = SpacedRepetitionState(ease: 2.5, interval: 0, dueAt: .now, reps: 0, lapses: 0)
        #expect(settings.state(for: sr, isLearning: false) == .new)
    }

    @Test("A card inside the learning steps is learning, whatever its SM-2 state says")
    func learningWins() {
        let settings = RecallSettings.default
        // Even a card that has repetitions is reported as learning while a step is outstanding.
        let sr = SpacedRepetitionState(ease: 2.5, interval: 6, dueAt: .now, reps: 2, lapses: 0)
        #expect(settings.state(for: sr, isLearning: true) == .learning)
    }

    @Test("Graduated cards are young until they reach the maturity threshold")
    func youngThenMature() {
        let settings = RecallSettings.default
        let young = SpacedRepetitionState(ease: 2.5, interval: 6, dueAt: .now, reps: 2, lapses: 0)
        let mature = SpacedRepetitionState(ease: 2.5, interval: 21, dueAt: .now, reps: 4, lapses: 0)
        #expect(settings.state(for: young, isLearning: false) == .young)
        #expect(settings.state(for: mature, isLearning: false) == .mature)
    }

    @Test("The maturity threshold is inclusive")
    func maturityIsInclusive() {
        let settings = RecallSettings(matureAfterDays: 10)
        let exactly = SpacedRepetitionState(ease: 2.5, interval: 10, dueAt: .now, reps: 3, lapses: 0)
        #expect(settings.state(for: exactly, isLearning: false) == .mature)
    }
}

@Suite("F17 learning steps")
struct RecallLearningTests {

    private let settings = RecallSettings(learningStepMinutes: [1, 10], graduatingIntervalDays: 1)

    @Test("Again restarts the ladder, so a failed card comes back inside the sitting")
    func againRestarts() {
        #expect(RecallLearning.outcome(step: 1, rating: .again, settings: settings) == .restart)
        #expect(RecallLearning.outcome(step: 0, rating: .again, settings: settings) == .restart)
    }

    @Test("Hard repeats the current step rather than advancing")
    func hardRepeatsTheStep() {
        #expect(RecallLearning.outcome(step: 0, rating: .hard, settings: settings) == .stay(step: 0))
        #expect(RecallLearning.outcome(step: 1, rating: .hard, settings: settings) == .stay(step: 1))
    }

    @Test("Good advances one step, and graduates after the last one")
    func goodAdvancesThenGraduates() {
        #expect(RecallLearning.outcome(step: 0, rating: .good, settings: settings) == .stay(step: 1))
        #expect(RecallLearning.outcome(step: 1, rating: .good, settings: settings)
                == .graduate(intervalDays: 1))
    }

    @Test("Easy graduates immediately, which is the point of having the button")
    func easyGraduatesAtOnce() {
        #expect(RecallLearning.outcome(step: 0, rating: .easy, settings: settings)
                == .graduate(intervalDays: 1))
    }

    @Test("A single-step ladder graduates on the first Good")
    func singleStepGraduatesOnGood() {
        let oneStep = RecallSettings(learningStepMinutes: [5], graduatingIntervalDays: 3)
        #expect(RecallLearning.outcome(step: 0, rating: .good, settings: oneStep)
                == .graduate(intervalDays: 3))
    }

    @Test("An out-of-range step is clamped instead of trapping")
    func outOfRangeStepsAreClamped() {
        // A stale or hand-edited learning-step index must never crash a session.
        #expect(RecallLearning.outcome(step: 99, rating: .hard, settings: settings) == .stay(step: 1))
        #expect(RecallLearning.outcome(step: -4, rating: .hard, settings: settings) == .stay(step: 0))
    }

    @Test("A new card starts at the first step")
    func newCardsStartAtZero() {
        #expect(RecallLearning.firstStep == 0)
    }
}
