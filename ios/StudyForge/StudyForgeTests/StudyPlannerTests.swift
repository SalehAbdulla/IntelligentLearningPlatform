//
//  StudyPlannerTests.swift
//  StudyForgeTests
//
//  Tests for the study-plan scheduler — the maths the week view trusts.
//
//  The load-bearing one is `isDeterministic`: the whole "re-plan" promise rests on the same input
//  producing the same schedule, and a scheduler that drifted would make the calendar jump every
//  time a student opened it.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Study planner")
struct StudyPlannerTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func input(
        subjects: [String] = ["Maths", "Physics"],
        weeklyHours: Int = 8,
        deadline: Date? = nil,
        examDates: [CourseExam] = [],
        intensity: StudyIntensity = .light
    ) -> StudyPlanInput {
        StudyPlanInput(
            subjects: subjects,
            weeklyHours: weeklyHours,
            deadline: deadline,
            examDates: examDates,
            intensity: intensity
        )
    }

    @Test("The same input produces the same schedule")
    func isDeterministic() {
        let first = StudyPlanner.schedule(input(), now: now)
        let second = StudyPlanner.schedule(input(), now: now)
        #expect(first.map(\.scheduledAt) == second.map(\.scheduledAt))
        #expect(first.map(\.subject) == second.map(\.subject))
    }

    @Test("The weekly hours split into sessions of the intensity's length")
    func sessionCountFollowsIntensity() {
        let sessions = StudyPlanner.schedule(input(weeklyHours: 8, intensity: .light), now: now)
        #expect(sessions.count == 16, "8 h × 60 min ÷ 30 min")
        #expect(sessions.allSatisfy { $0.estimatedMinutes == 30 })
    }

    @Test("Subjects are cycled evenly across the sessions")
    func subjectsCycleEvenly() {
        let sessions = StudyPlanner.schedule(input(weeklyHours: 8, intensity: .light), now: now)
        #expect(sessions.filter { $0.subject == "Maths" }.count == 8)
        #expect(sessions.filter { $0.subject == "Physics" }.count == 8)
    }

    @Test("No subjects, or no hours, produces no sessions")
    func noInputProducesNothing() {
        #expect(StudyPlanner.schedule(input(subjects: []), now: now).isEmpty)
        #expect(StudyPlanner.schedule(input(weeklyHours: 0), now: now).isEmpty)
    }

    @Test("A deadline shortens the horizon the sessions are spread over")
    func deadlineShortensHorizon() {
        let deadline = now.addingTimeInterval(3 * 86_400)
        let sessions = StudyPlanner.schedule(input(weeklyHours: 8, deadline: deadline, intensity: .light), now: now)

        let days = Set(sessions.map { Calendar.current.startOfDay(for: $0.scheduledAt) })
        #expect(days.count == 3)
    }

    @Test("Session length follows the intensity")
    func sessionLengthFollowsIntensity() {
        #expect(StudyPlanner.schedule(input(intensity: .balanced), now: now).first?.estimatedMinutes == 45)
        #expect(StudyPlanner.schedule(input(intensity: .intensive), now: now).first?.estimatedMinutes == 60)
    }

    // MARK: Exam dates (F06)

    /// A date whole days from `now`, so the horizon is `days` whichever timezone runs the suite.
    private func exam(in days: Int) -> Date {
        now.addingTimeInterval(Double(days) * 86_400)
    }

    private func dayCount(of subject: String, in sessions: [StudySession]) -> Int {
        Set(sessions.filter { $0.subject == subject }.map { Calendar.current.startOfDay(for: $0.scheduledAt) }).count
    }

    @Test("No session for a subject lands on or after that subject's exam")
    func examDateIsNeverBreached() {
        let examDate = exam(in: 4)
        let sessions = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: examDate)]),
            now: now
        )

        let maths = sessions.filter { $0.subject == "Maths" }
        let examDay = Calendar.current.startOfDay(for: examDate)

        #expect(!maths.isEmpty, "the subject with an exam must still be given sessions")
        for session in maths {
            #expect(
                Calendar.current.startOfDay(for: session.scheduledAt) < examDay,
                "\(session.scheduledAt) is on or after the Maths exam"
            )
        }
    }

    @Test("A nearer exam changes the plan")
    func nearerExamChangesThePlan() {
        let near = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 3))]),
            now: now
        )
        let far = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 6))]),
            now: now
        )

        #expect(near.map(\.scheduledAt) != far.map(\.scheduledAt))
    }

    /// The student MOVES a date on an existing plan — the re-plan case, not just two plans that
    /// happen to differ. Moving it earlier must pull every session behind the new date, and the
    /// subject with no exam is placed by the ordinary week horizon, which the change does not
    /// touch — so its sessions must be identical in both runs.
    @Test("Moving a subject's exam earlier pulls every session behind the new date")
    func movingAnExamEarlierRepullsItsSessions() {
        let original = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 6))]),
            now: now
        )
        let changed = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 3))]),
            now: now
        )

        #expect(original.map(\.scheduledAt) != changed.map(\.scheduledAt), "changing the date must change the plan")

        let newExamDay = Calendar.current.startOfDay(for: exam(in: 3))
        let maths = changed.filter { $0.subject == "Maths" }
        #expect(!maths.isEmpty, "the subject whose exam moved still gets sessions")
        for session in maths {
            #expect(
                Calendar.current.startOfDay(for: session.scheduledAt) < newExamDay,
                "\(session.scheduledAt) is on or after the moved Maths exam"
            )
        }

        #expect(
            original.filter { $0.subject == "Physics" }.map(\.scheduledAt)
                == changed.filter { $0.subject == "Physics" }.map(\.scheduledAt),
            "moving one course's exam must not disturb a course without one"
        )
    }

    @Test("Moving a subject's exam later frees the days it used to shadow")
    func movingAnExamLaterFreesTheOldDays() {
        let original = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 2))]),
            now: now
        )
        let changed = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 5))]),
            now: now
        )

        // Two days before the old date, five before the new one — the plan visibly re-spreads.
        #expect(dayCount(of: "Maths", in: original) == 2, "confined to the two days before the old exam")
        #expect(dayCount(of: "Maths", in: changed) == 5, "five days open up under the later exam")

        let newExamDay = Calendar.current.startOfDay(for: exam(in: 5))
        for session in changed.filter({ $0.subject == "Maths" }) {
            #expect(
                Calendar.current.startOfDay(for: session.scheduledAt) < newExamDay,
                "\(session.scheduledAt) is on or after the moved Maths exam"
            )
        }
    }

    @Test("A near exam packs that subject into fewer days than a subject without one")
    func nearExamConcentratesSessions() {
        let sessions = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 3))]),
            now: now
        )

        #expect(dayCount(of: "Maths", in: sessions) == 3, "the three days before the exam")
        #expect(
            dayCount(of: "Physics", in: sessions) > dayCount(of: "Maths", in: sessions),
            "the subject with no exam keeps the whole week"
        )
    }

    @Test("An exam date that has already passed does not constrain the plan")
    func staleExamDateIsIgnored() {
        let stale = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: now.addingTimeInterval(-3 * 86_400))]),
            now: now
        )
        let plain = StudyPlanner.schedule(input(), now: now)

        #expect(stale.map(\.scheduledAt) == plain.map(\.scheduledAt))
        #expect(stale.map(\.subject) == plain.map(\.subject))
    }

    @Test("An exam beyond the plan's own window leaves the week laid out as usual")
    func distantExamDoesNotStretchThePlan() {
        let distant = StudyPlanner.schedule(
            input(examDates: [CourseExam(subject: "Maths", date: exam(in: 30))]),
            now: now
        )
        let plain = StudyPlanner.schedule(input(), now: now)

        // Compared by WHAT the schedule says, not by identity: `StudySession.id` is a fresh
        // UUID on every call, so `distant == plain` could never be true no matter how correct
        // the planner is — the same reason `isDeterministic` and `staleExamDateIsIgnored`
        // compare these two maps rather than whole sessions.
        #expect(
            distant.map(\.scheduledAt) == plain.map(\.scheduledAt),
            "a month-away exam must not reshape a one-week plan"
        )
        #expect(distant.map(\.subject) == plain.map(\.subject))
    }

    @Test("Exam dates do not make the schedule nondeterministic")
    func isDeterministicWithExamDates() {
        let examDates = [
            CourseExam(subject: "Maths", date: exam(in: 2)),
            CourseExam(subject: "Physics", date: exam(in: 5))
        ]

        // `StudySession.id` is a fresh UUID per call, so identity comparison would fail
        // even when the schedule says exactly the same thing. Compare the schedule's
        // content, exactly as `isDeterministic` does.
        let first = StudyPlanner.schedule(input(examDates: examDates), now: now)
        let second = StudyPlanner.schedule(input(examDates: examDates), now: now)
        #expect(first.map(\.scheduledAt) == second.map(\.scheduledAt))
        #expect(first.map(\.subject) == second.map(\.subject))
    }
}
