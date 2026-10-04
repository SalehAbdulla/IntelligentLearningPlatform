//
//  StudyPlanWizardViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F06's wizard: collecting the input, and generating a plan from it.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Study plan wizard (F06)")
@MainActor
struct StudyPlanWizardViewModelTests {

    @Test("Adding a subject trims it and de-duplicates")
    func addSubjectTidies() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())

        viewModel.subjectText = "  Maths  "
        viewModel.addSubject()
        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        viewModel.subjectText = "   "
        viewModel.addSubject()

        #expect(viewModel.subjects == ["Maths"])
        #expect(viewModel.subjectText.isEmpty)
    }

    @Test("The wizard cannot continue past the subjects step with none entered")
    func subjectsStepRequiresASubject() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())
        #expect(viewModel.step == .subjects)
        #expect(viewModel.canContinue == false)

        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        #expect(viewModel.canContinue)
    }

    @Test("The steps advance and go back")
    func stepNavigation() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())
        viewModel.next()
        #expect(viewModel.step == .availability)
        viewModel.next()
        #expect(viewModel.step == .deadline)
        viewModel.back()
        #expect(viewModel.step == .availability)
    }

    @Test("Generating saves a plan with sessions")
    func generateSavesAPlan() async throws {
        let store = InMemoryStudyPlanStore()
        let viewModel = StudyPlanWizardViewModel(store: store)
        viewModel.subjectText = "Maths"
        viewModel.addSubject()

        await viewModel.generate()

        #expect(viewModel.savedPlan != nil)
        #expect(viewModel.savedPlan?.sessions.isEmpty == false)
        #expect(try await store.all().count == 1)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = StudyPlanWizardViewModel(store: InMemoryStudyPlanStore())

        #expect(viewModel.title == L10n.planTitle.string)
        #expect(viewModel.subjectsHeading == L10n.planSubjectsHeading.string)
        #expect(viewModel.availabilityHeading == L10n.planAvailabilityHeading.string)
        #expect(viewModel.deadlineHeading == L10n.planDeadlineHeading.string)
        #expect(viewModel.intensityHeading == L10n.planIntensityHeading.string)
        #expect(viewModel.generateTitle == L10n.planGenerate.string)
        #expect(viewModel.stepIndicator == L10n.planStepIndicator.string(1, 4))
    }
}
