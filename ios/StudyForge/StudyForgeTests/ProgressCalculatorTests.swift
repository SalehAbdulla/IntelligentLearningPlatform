//
//  ProgressCalculatorTests.swift
//  StudyForgeTests
//
//  Tests for the derived progress metrics.
//
//  The load-bearing ones are `streakSurvivesAnEmptyToday` — a student who studied yesterday must not
//  lose the streak they earned just because they have not opened the app yet — and
//  `masteryIgnoresAnUnusedFeature`, because averaging a zero in for a feature nobody has used is how
//  a dashboard demotivates the person it is for.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Progress calculator")
struct ProgressCalculatorTests {

    private let calendar = Calendar.current
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func days(_ offsets: [Int: Int]) -> [Date: ProgressCalculator.DayTotals] {
        var result: [Date: ProgressCalculator.DayTotals] = [:]
        for (offset, minutes) in offsets {
            let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
            result[day] = ProgressCalculator.DayTotals(minutes: minutes, items: 1)
        }
        return result
    }

    // MARK: Streak

    @Test("No activity means no streak")
    func noActivityNoStreak() {
        #expect(ProgressCalculator.streak(days: [:], calendar: calendar, now: now) == 0)
    }

    @Test("An unbroken run of days counts from today backwards")
    func streakCountsRun() {
        let totals = days([0: 30, -1: 45, -2: 20])
        #expect(ProgressCalculator.streak(days: totals, calendar: calendar, now: now) == 3)
    }

    @Test("A day missed yesterday but studied today still counts")
    func streakResetsAfterAGap() {
        let totals = days([0: 30, -2: 45, -3: 20])
        #expect(ProgressCalculator.streak(days: totals, calendar: calendar, now: now) == 1)
    }

    @Test("Studying yesterday but not today keeps the streak the student earned")
    func streakSurvivesAnEmptyToday() {
        let totals = days([-1: 45, -2: 20])
        #expect(ProgressCalculator.streak(days: totals, calendar: calendar, now: now) == 2)
    }

    @Test("A streak older than yesterday is broken")
    func staleStreakIsZero() {
        let totals = days([-2: 45, -3: 20])
        #expect(ProgressCalculator.streak(days: totals, calendar: calendar, now: now) == 0)
    }

    // MARK: Mastery

    @Test("With only one feature used, that feature's mastery IS the headline")
    func masteryIgnoresAnUnusedFeature() {
        #expect(
            ProgressCalculator.masteryPercent(
                cardMasteryFraction: 0.8, quizAccuracyFraction: 0,
                hasCards: true, hasQuizzes: false
            ) == 80
        )
        #expect(
            ProgressCalculator.masteryPercent(
                cardMasteryFraction: 0, quizAccuracyFraction: 0.5,
                hasCards: false, hasQuizzes: true
            ) == 50
        )
    }

    @Test("With both features used, the headline blends them")
    func masteryBlendsWhenBothExist() {
        #expect(
            ProgressCalculator.masteryPercent(
                cardMasteryFraction: 1.0, quizAccuracyFraction: 0.5,
                hasCards: true, hasQuizzes: true
            ) == 75
        )
    }

    // MARK: Weekly activity

    @Test("The week always has seven days, even with no activity")
    func weekIsAlwaysSevenDays() {
        #expect(ProgressCalculator.currentWeek(days: [:], calendar: calendar, now: now).count == 7)
    }

    @Test("Only the current week's minutes are totalled")
    func minutesCountTheCurrentWeekOnly() {
        // Today is in this week; 30 days ago is not.
        let totals = days([0: 45, -30: 90])
        #expect(ProgressCalculator.minutesInCurrentWeek(days: totals, calendar: calendar, now: now) == 45)
    }
}