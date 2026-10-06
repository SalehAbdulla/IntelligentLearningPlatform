//
//  ProgressCalculator.swift
//  StudyForge
//
//  The pure derivation behind the dashboard. See `ProgressSnapshot` for why these numbers are
//  computed rather than read from a stored aggregate.
//
//  PURITY IS THE POINT
//  -------------------
//  The same inputs always produce the same snapshot, so a long list of edge cases — a streak that
//  spans a month boundary, a week with no activity, a topic answered twice — can be asserted in a
//  test instead of eyeballed on a screen.
//

import Foundation

/// Everything the calculator reads. Plain values, so a test can build one by hand.
struct ProgressInput: Sendable {
    var materials: [Material]
    var decks: [Deck]
    var quizzes: [Quiz]
    var plan: StudyPlan?

    /// The student's weekly goal in hours, from B03. `nil` when unanswered.
    var weeklyGoalHours: Int?

    var now: Date

    init(
        materials: [Material] = [],
        decks: [Deck] = [],
        quizzes: [Quiz] = [],
        plan: StudyPlan? = nil,
        weeklyGoalHours: Int? = nil,
        now: Date
    ) {
        self.materials = materials
        self.decks = decks
        self.quizzes = quizzes
        self.plan = plan
        self.weeklyGoalHours = weeklyGoalHours
        self.now = now
    }
}

enum ProgressCalculator {

    /// The interval at which a card counts as "mastered". Matches the deck counters in `Deck`.
    static let masteredIntervalDays = 30

    /// The weak-topic threshold, kept here so the explanation and the number cannot drift.
    static let weakTopicThreshold = 0.6

    /// One day's totals, keyed by the start of that day.
    struct DayTotals: Equatable {
        var minutes = 0
        var items = 0
    }

    static func snapshot(_ input: ProgressInput) -> ProgressSnapshot {
        let calendar = Calendar.current
        let days = activityDays(input, calendar: calendar)
        let quizStats = quizStatistics(input.quizzes)
        let cardStats = cardStatistics(input.decks)

        return ProgressSnapshot(
            masteryPercent: masteryPercent(
                cardMasteryFraction: cardStats.fraction,
                quizAccuracyFraction: quizStats.accuracy,
                hasCards: cardStats.total > 0,
                hasQuizzes: quizStats.responses > 0
            ),
            streakDays: streak(days: days, calendar: calendar, now: input.now),
            minutesThisWeek: minutesInCurrentWeek(days: days, calendar: calendar, now: input.now),
            weeklyGoalHours: input.weeklyGoalHours,
            weeklyActivity: currentWeek(days: days, calendar: calendar, now: input.now),
            subjects: subjectProgress(input.plan),
            topics: topicMastery(input.quizzes),
            itemsCompleted: days.values.reduce(0) { $0 + $1.items },
            quizzesTaken: input.quizzes.reduce(0) { $0 + $1.attempts.count },
            averageQuizScore: Int((quizStats.accuracy * 100).rounded()),
            cardsMastered: cardStats.mastered,
            cardsTotal: cardStats.total
        )
    }

    // MARK: - Activity

    /// What the student did, by day.
    ///
    /// Four honest sources, because there is no event log yet: a completed study session (the
    /// minutes), a quiz attempt, an import, and a deck that has been reviewed (its `updatedAt`
    /// only counts once at least one card has SM-2 history — otherwise merely saving a deck would
    /// look like studying).
    static func activityDays(_ input: ProgressInput, calendar: Calendar) -> [Date: DayTotals] {
        var totals: [Date: DayTotals] = [:]

        func record(_ date: Date, minutes: Int, items: Int) {
            let key = calendar.startOfDay(for: date)
            totals[key, default: DayTotals()].minutes += minutes
            totals[key, default: DayTotals()].items += items
        }

        for material in input.materials {
            record(material.createdAt, minutes: 0, items: 1)
        }

        for deck in input.decks where deck.cards.contains(where: { $0.sr.reps > 0 }) {
            record(deck.updatedAt, minutes: 0, items: 1)
        }

        for quiz in input.quizzes {
            for attempt in quiz.attempts {
                record(attempt.createdAt, minutes: 0, items: 1)
            }
        }

        for session in input.plan?.sessions ?? [] where session.status == .completed {
            // A completed session is where the minutes come from: it is the only artefact that
            // records an intended DURATION, and the student marked it done.
            record(session.scheduledAt, minutes: session.estimatedMinutes, items: 1)
        }

        return totals
    }

    /// Consecutive days with activity, ending today — or yesterday, so a student who studied
    /// yesterday but has not opened the app yet today keeps the streak they earned.
    static func streak(days: [Date: DayTotals], calendar: Calendar, now: Date = .now) -> Int {
        let active = Set(days.filter { $0.value.items > 0 }.keys)
        guard !active.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        var cursor = active.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        guard active.contains(cursor) else { return 0 }

        var count = 0
        while active.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// The seven days of the current calendar week, oldest first.
    ///
    /// A calendar week rather than a rolling seven days, so the bars and the "hours this week"
    /// figure always describe the same span — a dashboard whose two numbers disagree is worse than
    /// one number.
    static func currentWeek(days: [Date: DayTotals], calendar: Calendar, now: Date = .now)
        -> [DailyActivity] {

        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let start = calendar.startOfDay(for: week.start)

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let totals = days[day] ?? DayTotals()
            return DailyActivity(day: day, minutes: totals.minutes, items: totals.items)
        }
    }

    static func minutesInCurrentWeek(days: [Date: DayTotals], calendar: Calendar, now: Date = .now)
        -> Int {
        currentWeek(days: days, calendar: calendar, now: now)
            .reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Quiz statistics

    struct QuizStats: Equatable {
        var correct = 0
        var responses = 0

        var accuracy: Double { responses == 0 ? 0 : Double(correct) / Double(responses) }
    }

    /// Totals every response across every attempt of every quiz.
    static func quizStatistics(_ quizzes: [Quiz]) -> QuizStats {
        var stats = QuizStats()
        for quiz in quizzes {
            for attempt in quiz.attempts {
                for response in attempt.responses {
                    stats.responses += 1
                    if response.isCorrect { stats.correct += 1 }
                }
            }
        }
        return stats
    }

    /// Per-topic mastery across every quiz, weakest first.
    ///
    /// Topics are matched by their label (the model's `topic`), which is how `QuizTopicScore`
    /// already groups them — the same label the weakness radar and the quiz scorecard show.
    static func topicMastery(_ quizzes: [Quiz]) -> [TopicMastery] {
        var correct: [String: Int] = [:]
        var total: [String: Int] = [:]

        for quiz in quizzes {
            // A question only counts once it has actually been answered.
            let answered = Dictionary(
                uniqueKeysWithValues: quiz.attempts
                    .flatMap(\.responses)
                    .map { ($0.questionId, $0.isCorrect) }
            )
            for question in quiz.questions {
                guard let isCorrect = answered[question.id] else { continue }
                total[question.topic, default: 0] += 1
                if isCorrect { correct[question.topic, default: 0] += 1 }
            }
        }

        return total.map { topic, count in
            let hits = correct[topic] ?? 0
            return TopicMastery(
                topic: topic,
                mastery: count == 0 ? 0 : Double(hits) / Double(count),
                correct: hits,
                total: count
            )
        }
        .sorted { $0.mastery < $1.mastery }
    }

    // MARK: - Card statistics

    struct CardStats: Equatable {
        var mastered = 0
        var total = 0

        var fraction: Double { total == 0 ? 0 : Double(mastered) / Double(total) }
    }

    /// Counts cards, and how many are mastered (interval at or beyond the mastered threshold).
    static func cardStatistics(_ decks: [Deck]) -> CardStats {
        let cards = decks.flatMap(\.cards)
        return CardStats(
            mastered: cards.filter { $0.sr.interval >= masteredIntervalDays }.count,
            total: cards.count
        )
    }

    // MARK: - Headline mastery

    /// A single 0–100 "how am I doing" figure.
    ///
    /// Cards and quizzes are blended only when BOTH exist — otherwise the one that does exist is
    /// used alone. Averaging in a zero for a feature the student has not used yet would report 30%
    /// mastery to someone who has answered every card correctly, which is exactly the sort of
    /// demotivating artefact a dashboard should not invent.
    static func masteryPercent(
        cardMasteryFraction: Double,
        quizAccuracyFraction: Double,
        hasCards: Bool,
        hasQuizzes: Bool
    ) -> Int {
        let blended: Double
        switch (hasCards, hasQuizzes) {
        case (true, true): blended = (cardMasteryFraction + quizAccuracyFraction) / 2
        case (true, false): blended = cardMasteryFraction
        case (false, true): blended = quizAccuracyFraction
        case (false, false): blended = 0
        }
        return Int((blended * 100).rounded())
    }

    // MARK: - Subjects

    /// How far through the current plan each subject is.
    ///
    /// Subjects come from the PLAN rather than the library, because the plan is the only artefact
    /// that names a subject and records how many sessions it was given — which is what makes a
    /// percentage meaningful rather than decorative.
    static func subjectProgress(_ plan: StudyPlan?) -> [SubjectProgress] {
        guard let plan else { return [] }

        let grouped = Dictionary(grouping: plan.sessions, by: \.subject)
        return grouped.map { subject, sessions in
            let completed = sessions.filter { $0.status == .completed }
            return SubjectProgress(
                subject: subject,
                completedSessions: completed.count,
                totalSessions: sessions.count,
                minutesStudied: completed.reduce(0) { $0 + $1.estimatedMinutes }
            )
        }
        .sorted { $0.subject < $1.subject }
    }
}