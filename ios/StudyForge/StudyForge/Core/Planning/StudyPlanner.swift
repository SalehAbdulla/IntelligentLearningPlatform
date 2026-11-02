//
//  StudyPlanner.swift
//  StudyForge
//
//  The deterministic scheduler that turns the wizard's input into a week of sessions.
//
//  WHY THIS IS HAND-WRITTEN AND PURE
//  ---------------------------------
//  Like the SM-2 engine, the scheduler is the one piece of maths the plan depends on, and it must
//  be testable without a device or a clock. A pure function over `StudyPlanInput` + `now` is
//  exactly that: same input in, same schedule out, every time (docs/10 §4's "hand-written code on
//  the parts that matter").
//
//  THE RULE IN ONE PARAGRAPH
//  -------------------------
//  Split the weekly hours into sessions of the intensity's length, spread them round-robin across
//  the days from today until the deadline (or a week when there is none), and cycle the subjects
//  evenly. It is deliberately simple rather than clever — a student should be able to look at the
//  calendar and see WHY a session is where it is.
//
//  WHEN A SUBJECT HAS AN EXAM (F06)
//  --------------------------------
//  That subject gets a horizon of its own: the days from today up to its exam, never the whole
//  week. Its sessions spread over THOSE days instead, so the nearer the exam the more of them
//  share a day — that is what weighting a near exam harder means in practice — and nothing can
//  land on or after the exam day. A subject with no exam keeps the ordinary horizon, so a plan
//  with no exam dates lays out exactly as it did before this existed.
//

import Foundation

enum StudyPlanner {

    /// Builds a week of sessions for `input`, anchored at `now`.
    ///
    /// Deterministic: the same `input` and `now` always yield the same sessions.
    static func schedule(_ input: StudyPlanInput, now: Date) -> [StudySession] {
        guard !input.subjects.isEmpty, input.weeklyHours > 0 else { return [] }

        let sessionMinutes = input.intensity.sessionMinutes
        let sessionCount = max(1, input.weeklyHours * 60 / sessionMinutes)

        // The plan runs until the deadline, or a week when there is none.
        let end = input.deadline ?? now.addingTimeInterval(7 * 86_400)
        let daySpan = Calendar.current.dateComponents([.day], from: now, to: end).day ?? 7
        let days = max(1, daySpan)

        let baseDay = Calendar.current.startOfDay(for: now)
        let subjectCount = input.subjects.count
        let subjectHorizons = horizons(for: input, days: days, baseDay: baseDay)

        var sessions: [StudySession] = []
        sessions.reserveCapacity(sessionCount)

        for index in 0..<sessionCount {
            let subject = input.subjects[index % subjectCount]

            // `occurrence` is which session this is FOR THIS SUBJECT, counted from zero, rather
            // than where it sits in the whole week. Spreading by the subject's own count is what
            // lets each subject cover its horizon evenly: with the global index and two subjects,
            // a four-day horizon puts every even index on days {0, 2} only, so two usable days
            // before the exam would go unused. With no exam the horizon is the same `days` as
            // before, so an ordinary plan is spread exactly as it always was.
            let occurrence = index / subjectCount
            let horizon = subjectHorizons[subject] ?? Horizon(span: days, lastDay: nil)

            let day = occurrence % horizon.span
            let slot = occurrence / horizon.span

            var date = Calendar.current
                .date(byAdding: .day, value: day, to: baseDay)
                .flatMap { Calendar.current.date(bySettingHour: 17, minute: slot * sessionMinutes, second: 0, of: $0) }
                ?? now

            // Enough sessions at a short horizon runs the time-of-day past midnight, which would
            // drop the session onto the day AFTER its exam. Pull it back onto the last day the
            // subject still has, keeping the time it was given. `lastDay` is nil for a subject
            // with no exam, so an ordinary plan never enters this branch at all.
            if let lastDay = horizon.lastDay {
                let sessionDay = Calendar.current.startOfDay(for: date)
                if sessionDay > lastDay {
                    date = lastDay.addingTimeInterval(date.timeIntervalSince(sessionDay))
                }
            }

            sessions.append(
                StudySession(subject: subject, estimatedMinutes: sessionMinutes, scheduledAt: date)
            )
        }

        return sessions
    }

    // MARK: Exam horizons

    /// How far one subject's sessions may be spread.
    private struct Horizon {
        /// Whole days available to the subject, always at least 1. The schedule spreads over this.
        var span: Int
        /// Start of the last day a session for this subject may occupy, or `nil` when the subject
        /// has no exam ahead of it and so carries no constraint of its own.
        var lastDay: Date?
    }

    /// Each subject's horizon, derived from its own exam date. Subjects without an exam are
    /// absent from the result, which is precisely what keeps the ordinary path untouched.
    ///
    /// AN EXAM THAT HAS ALREADY ARRIVED IS IGNORED
    /// -------------------------------------------
    /// A date in the past must not shrink the plan. The whole reason exam dates moved off the
    /// profile (docs/09 Q11) is that a date nothing ever clears keeps constraining behaviour
    /// after it has passed — so a reached exam constrains nothing, and that subject is scheduled
    /// as if it had none.
    private static func horizons(
        for input: StudyPlanInput,
        days: Int,
        baseDay: Date
    ) -> [String: Horizon] {
        let calendar = Calendar.current
        var result: [String: Horizon] = [:]

        for exam in input.examDates {
            let examDay = calendar.startOfDay(for: exam.date)
            guard examDay > baseDay else { continue }

            // Never longer than the plan's own window: an exam three weeks out does not stretch a
            // one-week plan, and `days` is already the horizon every other subject is given.
            let untilExam = calendar.dateComponents([.day], from: baseDay, to: examDay).day ?? days
            let span = min(max(1, untilExam), days)

            result[exam.subject] = Horizon(
                span: span,
                lastDay: calendar.date(byAdding: .day, value: span - 1, to: baseDay)
            )
        }

        return result
    }
}
