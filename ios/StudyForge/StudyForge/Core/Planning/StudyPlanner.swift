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
        var sessions: [StudySession] = []
        sessions.reserveCapacity(sessionCount)

        for index in 0..<sessionCount {
            let day = index % days
            let slot = index / days
            let subject = input.subjects[index % input.subjects.count]

            let date = Calendar.current
                .date(byAdding: .day, value: day, to: baseDay)
                .flatMap { Calendar.current.date(bySettingHour: 17, minute: slot * sessionMinutes, second: 0, of: $0) }
                ?? now

            sessions.append(
                StudySession(subject: subject, estimatedMinutes: sessionMinutes, scheduledAt: date)
            )
        }

        return sessions
    }
}
