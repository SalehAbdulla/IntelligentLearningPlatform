//
//  ProgressDashboardViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the dashboard's assembly: every store read into one snapshot.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Progress dashboard (F07)")
@MainActor
struct ProgressDashboardViewModelTests {

    private func model(
        materials: any MaterialStore = InMemoryMaterialStore(),
        decks: any DeckStore = InMemoryDeckStore(),
        quizzes: any QuizStore = InMemoryQuizStore(),
        studyPlans: any StudyPlanStore = InMemoryStudyPlanStore(),
        profile: any ProfileService = MockProfileService(latency: .zero)
    ) -> ProgressDashboardViewModel {
        ProgressDashboardViewModel(
            materials: materials, decks: decks, quizzes: quizzes,
            studyPlans: studyPlans, profile: profile
        )
    }

    @Test("Nothing anywhere shows the empty state, not a failure")
    func emptyStores() async {
        let viewModel = model()
        await viewModel.load()
        #expect(viewModel.showsEmpty)
        #expect(viewModel.error == nil)
    }

    @Test("A material alone is enough to leave the empty state")
    func oneMaterialIsData() async {
        let viewModel = model(
            materials: InMemoryMaterialStore(seededWith: [
                Material(title: "Lecture", source: .text, text: "body")
            ])
        )
        await viewModel.load()
        #expect(viewModel.showsEmpty == false)
        #expect(viewModel.snapshot?.itemsCompleted == 1)
    }

    @Test("The weekly goal is read from the profile")
    func goalFromProfile() async {
        let profile = MockProfileService(latency: .zero)
        profile.seed(.preview)
        let viewModel = model(
            materials: InMemoryMaterialStore(seededWith: [
                Material(title: "Lecture", source: .text, text: "body")
            ]),
            profile: profile
        )
        await viewModel.load()
        #expect(viewModel.snapshot?.weeklyGoalHours == StoredProfile.preview.weeklyStudyGoalHours)
    }

    @Test("A store failure is reported rather than swallowed")
    func failureIsReported() async {
        let decks = InMemoryDeckStore()
        await decks.forceFailure(.storageFailed)
        let viewModel = model(decks: decks)

        await viewModel.load()

        #expect(viewModel.error == AppError.server(reference: "deck-store-failed"))
    }

    @Test("Whole hours, rounded — a dashboard says 5 h, not 4 h 37 m")
    func hoursAreRounded() {
        let viewModel = model()
        #expect(viewModel.hours(fromMinutes: 0) == 0)
        #expect(viewModel.hours(fromMinutes: 59) == 1)
        #expect(viewModel.hours(fromMinutes: 90) == 2)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model()

        #expect(viewModel.title == L10n.progressTitle.string)
        #expect(viewModel.emptyTitle == L10n.progressEmptyTitle.string)
        #expect(viewModel.masteryLabel == L10n.progressMastery.string)
        #expect(viewModel.streakLabel == L10n.progressStreak.string)
        #expect(viewModel.weeklyHeading == L10n.progressWeeklyHeading.string)
        #expect(viewModel.radarTitle == L10n.progressRadarTitle.string)
        #expect(viewModel.weakTopicsHeading == L10n.progressWeakTopicsHeading.string)
        #expect(viewModel.masteryValue(80) == L10n.progressMasteryValue.string(80))
    }
}