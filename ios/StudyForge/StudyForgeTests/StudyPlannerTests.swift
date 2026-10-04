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
        intensity: StudyIntensity = .light
    ) -> StudyPlanInput {
        StudyPlanInput(subjects: subjects, weeklyHours: weeklyHours, deadline: deadline, intensity: intensity)
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
}
