//
//  ProgressSnapshot.swift
//  StudyForge
//
//  The DERIVED progress metrics F07's dashboard and weakness radar read.
//
//  WHY THESE ARE DERIVED, NOT STORED
//  ---------------------------------
//  docs/02 §6 plans an "activity events → nightly aggregation" pipeline writing `activityEvents`,
//  `progress` and `achievements`. That pipeline needs a server to run the nightly roll-up, and this
//  build has none — so it would mean an empty dashboard until Cloud Functions exist.
//
//  Instead the numbers are DERIVED from the artefacts the student already has on the device: their
//  decks (and each card's SM-2 state), their quiz attempts, their completed study sessions and their
//  imports. That is honest (`docs/05` §4 keeps everything local anyway), it works offline, and it
//  makes the dashboard correct from the first session rather than the first server deploy. The
//  stored collections remain the target for the day a roll-up runs; until then this is the source.
//
//  Every metric here is produced by `ProgressCalculator` — a pure function — so the maths is
//  testable without a device, exactly like the SM-2 and planner engines.
//

import Foundation

/// One day's activity, for the weekly bar chart.
struct DailyActivity: Equatable, Sendable, Identifiable {
    let day: Date
    let minutes: Int
    let items: Int

    var id: Date { day }
}

/// One subject's progress through the study plan.
struct SubjectProgress: Equatable, Sendable, Identifiable {
    let subject: String
    let completedSessions: Int
    let totalSessions: Int
    let minutesStudied: Int

    var id: String { subject }

    var fraction: Double {
        totalSessions == 0 ? 0 : Double(completedSessions) / Double(totalSessions)
    }

    var percent: Int { Int((fraction * 100).rounded()) }
}

/// How well one quiz topic is known, 0…1. The weakness radar and the "focus on" cards read this —
/// it is the in-app stand-in for `topicMastery` (docs/05 §2.3).
struct TopicMastery: Equatable, Sendable, Identifiable {
    let topic: String
    /// 0…1, where 1 is fully answered correctly.
    let mastery: Double
    let correct: Int
    let total: Int

    var id: String { topic }

    var percent: Int { Int((mastery * 100).rounded()) }

    /// Below this, the topic is surfaced as something to work on.
    ///
    /// Deliberately a documented threshold rather than a tuned number: the student should be able to
    /// see WHY a topic is flagged, and "under 60% of questions right" is a sentence they can read.
    var isWeak: Bool { total > 0 && mastery < 0.6 }
}

/// Everything the dashboard shows, computed in one pass.
struct ProgressSnapshot: Equatable, Sendable {

    /// Cards mastered and quiz accuracy blended — see `ProgressCalculator.masteryPercent`.
    let masteryPercent: Int

    /// Consecutive days ending today (or yesterday) with at least one activity.
    let streakDays: Int

    /// Minutes studied in the current calendar week.
    let minutesThisWeek: Int

    /// The student's own weekly goal, from B03. `nil` when the profile has not answered it.
    let weeklyGoalHours: Int?

    /// The days of the current calendar week, oldest first.
    let weeklyActivity: [DailyActivity]

    let subjects: [SubjectProgress]

    /// Topic mastery, weakest first.
    let topics: [TopicMastery]

    // Supporting facts, so the dashboard can explain the numbers rather than assert them.
    let itemsCompleted: Int
    let quizzesTaken: Int
    let averageQuizScore: Int
    let cardsMastered: Int
    let cardsTotal: Int

    /// Whether there is anything to show at all — an empty dashboard is a designed state.
    ///
    /// Gated on ACTIVITY rather than on substantive artefacts, because docs/02 §6 documents the
    /// empty case as *"No activity yet"*: a student who has imported a material has done something,
    /// and the dashboard should say so rather than claim nothing happened. The gaps that remain —
    /// no cards, no quizzes, no plan — are each handled by that section's own empty copy.
    var hasData: Bool {
        itemsCompleted > 0
    }

    /// Progress toward the weekly goal, 0…1. `nil` when no goal is set.
    var goalFraction: Double? {
        guard let weeklyGoalHours, weeklyGoalHours > 0 else { return nil }
        let goalMinutes = Double(weeklyGoalHours * 60)
        return min(1, Double(minutesThisWeek) / goalMinutes)
    }

    /// Topics the student should work on next, weakest first.
    var weakTopics: [TopicMastery] { topics.filter(\.isWeak) }

    /// The busiest day's minutes, used to scale the bar chart. Never zero, so bars do not divide by it.
    var peakDayMinutes: Int { max(1, weeklyActivity.map(\.minutes).max() ?? 0) }

    /// A snapshot with nothing in it, for the empty state and previews.
    static let empty = ProgressSnapshot(
        masteryPercent: 0,
        streakDays: 0,
        minutesThisWeek: 0,
        weeklyGoalHours: nil,
        weeklyActivity: [],
        subjects: [],
        topics: [],
        itemsCompleted: 0,
        quizzesTaken: 0,
        averageQuizScore: 0,
        cardsMastered: 0,
        cardsTotal: 0
    )
}