//
//  ExamDateTests.swift
//  StudyForgeTests
//
//  Tests for F06's per-course exam dates: that they survive a write and a read, that a plan
//  written BEFORE this feature still loads, and that the wizard collects them.
//
//  The load-bearing one is `legacyPlanWithoutExamDatesStillDecodes`. Adding a field is exactly
//  the kind of change that silently breaks every plan a student already has — and the failure
//  would not show up as a red test, it would show up as "my study plan vanished". Swift's
//  synthesised decoder requires a non-optional Array's key, so without `StudyPlanInput`'s
//  hand-written `init(from:)` that is what would have happened.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Exam dates on the plan")
struct ExamDateStorageTests {

    @Test("A plan with an exam date survives a write and a read")
    func examDatesRoundTrip() throws {
        let exam = CourseExam(subject: "Physics", date: Date(timeIntervalSince1970: 2_000_000))
        let plan = StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Physics"], weeklyHours: 8, examDates: [exam], intensity: .balanced),
            sessions: []
        )

        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(StudyPlan.self, from: data)

        #expect(decoded.input.examDates == [exam])
    }

    @Test("A plan written before exam dates existed still decodes")
    func legacyPlanWithoutExamDatesStillDecodes() throws {
        // Exactly the shape this app wrote before F06: no `examDates` key anywhere.
        let legacy = """
        {
          "id" : "p1",
          "input" : {
            "subjects" : ["Maths"],
            "weeklyHours" : 8,
            "deadline" : 4000000000,
            "intensity" : "balanced"
          },
          "sessions" : [],
          "createdAt" : 1000000,
          "updatedAt" : 1000000
        }
        """

        let decoded = try JSONDecoder().decode(StudyPlan.self, from: Data(legacy.utf8))

        #expect(decoded.input.subjects == ["Maths"])
        #expect(decoded.input.examDates.isEmpty, "an old plan means 'none entered', not a failure")
    }

    @Test("An empty exam-date list is written to disk, not dropped")
    func emptyExamDatesStillEncodes() throws {
        let plan = StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Maths"], weeklyHours: 8, intensity: .balanced),
            sessions: []
        )

        let data = try JSONEncoder().encode(plan)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("examDates"))
    }
}

@Suite("Wizard capture of exam dates (F06)")
@MainActor
struct StudyPlanWizardExamDateTests {

    @Test("Switching an exam date on seeds one, and off clears it")
    func togglingAnExamDate() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())

        #expect(viewModel.examDates["Maths"] == nil)

        viewModel.setExamDate(enabled: true, for: "Maths")
        #expect(viewModel.examDates["Maths"] != nil)

        viewModel.setExamDate(enabled: false, for: "Maths")
        #expect(viewModel.examDates["Maths"] == nil)
    }

    @Test("Enabling a second time keeps the date the student chose")
    func reEnablingKeepsTheChosenDate() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())
        let chosen = Date(timeIntervalSince1970: 5_000_000)

        viewModel.setExamDate(enabled: true, for: "Maths")
        viewModel.setExamDate(chosen, for: "Maths")
        viewModel.setExamDate(enabled: true, for: "Maths")

        #expect(viewModel.examDates["Maths"] == chosen)
    }

    @Test("Removing a subject takes its exam date with it")
    func removingASubjectDropsItsExamDate() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())

        viewModel.subjectText = "Physics"
        viewModel.addSubject()
        viewModel.setExamDate(enabled: true, for: "Physics")

        viewModel.removeSubject("Physics")

        #expect(viewModel.examDates["Physics"] == nil, "a removed course must not leave a date behind")
    }

    @Test("Generating stores the exam dates on the plan, and they read back")
    func generateStoresExamDates() async throws {
        let store = InMemoryStudyPlanStore()
        let viewModel = StudyPlanWizardViewModel(store: store)
        let exam = Date(timeIntervalSince1970: 6_000_000)

        viewModel.subjectText = "Physics"
        viewModel.addSubject()
        viewModel.setExamDate(exam, for: "Physics")

        await viewModel.generate()

        let saved = try #require(viewModel.savedPlan)
        let expected = [CourseExam(subject: "Physics", date: exam)]
        #expect(saved.input.examDates == expected)

        let reloaded = try await store.plan(id: saved.id)
        #expect(reloaded?.input.examDates == expected, "the stored plan is what the planner reads")
    }

    @Test("A subject whose row was never switched on is left off the plan")
    func unsetExamDatesAreNotStored() async throws {
        let store = InMemoryStudyPlanStore()
        let viewModel = StudyPlanWizardViewModel(store: store)

        viewModel.subjectText = "Maths"
        viewModel.addSubject()

        await viewModel.generate()

        #expect(viewModel.savedPlan?.input.examDates.isEmpty == true)
    }
}