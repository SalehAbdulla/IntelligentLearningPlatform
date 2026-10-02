//
//  StudyPlanViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F06's week view: loading the plan, grouping sessions by day, and the actions.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Study plan week view (F06)")
@MainActor
struct StudyPlanViewModelTests {

    private let day = Date(timeIntervalSince1970: 1_000_000)

    private func session(
        id: String,
        day: Date,
        hour: Int = 17,
        status: StudySessionStatus = .pending
    ) -> StudySession {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        return StudySession(id: id, subject: "Maths", estimatedMinutes: 45, scheduledAt: date, status: status)
    }

    private func plan(sessions: [StudySession]) -> StudyPlan {
        StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Maths"], weeklyHours: 8, intensity: .balanced),
            sessions: sessions
        )
    }

    @Test("An empty store shows the empty state")
    func emptyStore() async {
        let viewModel = StudyPlanViewModel(store: InMemoryStudyPlanStore())
        await viewModel.load()
        #expect(viewModel.isEmpty)
        #expect(viewModel.plan == nil)
    }

    @Test("Sessions are grouped by day, each group ordered by time")
    func sessionsGroupByDay() async {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        let store = InMemoryStudyPlanStore(seededWith: [
            plan(sessions: [
                session(id: "s2", day: day, hour: 19),
                session(id: "s1", day: day, hour: 17),
                session(id: "s3", day: nextDay, hour: 17),
            ])
        ])
        let viewModel = StudyPlanViewModel(store: store)

        await viewModel.load()

        let groups = viewModel.sessionsByDay
        #expect(groups.count == 2)
        #expect(groups.first?.sessions.map(\.id) == ["s1", "s2"], "same day, earliest first")
    }

    @Test("Marking a session done persists the new status")
    func markDonePersists() async throws {
        let store = InMemoryStudyPlanStore(seededWith: [plan(sessions: [session(id: "s1", day: day)])])
        let viewModel = StudyPlanViewModel(store: store)
        await viewModel.load()

        await viewModel.markDone(session(id: "s1", day: day))

        #expect(viewModel.plan?.sessions.first?.status == .completed)
        #expect(try await store.plan(id: "p1")?.sessions.first?.status == .completed)
    }

    @Test("Skipping a session persists the new status")
    func skipPersists() async throws {
        let store = InMemoryStudyPlanStore(seededWith: [plan(sessions: [session(id: "s1", day: day)])])
        let viewModel = StudyPlanViewModel(store: store)
        await viewModel.load()

        await viewModel.skip(session(id: "s1", day: day))

        #expect(viewModel.plan?.sessions.first?.status == .skipped)
    }

    @Test("Re-planning regenerates the sessions from the same input")
    func replanRegenerates() async throws {
        let store = InMemoryStudyPlanStore(seededWith: [plan(sessions: [session(id: "s1", day: day)])])
        let viewModel = StudyPlanViewModel(store: store)
        await viewModel.load()

        await viewModel.replan()

        // The input has 8 weekly hours at balanced (45 min) → 10 sessions, so the single old session
        // is replaced by a full week.
        #expect(viewModel.plan?.sessions.count == 10)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = StudyPlanViewModel(store: InMemoryStudyPlanStore())

        #expect(viewModel.title == L10n.planTitle.string)
        #expect(viewModel.emptyTitle == L10n.planEmptyTitle.string)
        #expect(viewModel.weekHeading == L10n.planWeekHeading.string)
        #expect(viewModel.markDoneTitle == L10n.planMarkDone.string)
        #expect(viewModel.skipTitle == L10n.planSkip.string)
        #expect(viewModel.replanTitle == L10n.planReplan.string)
    }
}
