//
//  StudentHomeViewModelTests.swift
//  StudyForgeTests
//
//  Tests for B05's data (F07): today's sessions filtered out of the week, the streak gate that
//  keeps an unearned pill hidden, and the due count that spans decks.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Student home (F07 · B05)")
@MainActor
struct StudentHomeViewModelTests {

    private func model(
        materials: any MaterialStore = InMemoryMaterialStore(),
        decks: any DeckStore = InMemoryDeckStore(),
        quizzes: any QuizStore = InMemoryQuizStore(),
        studyPlans: any StudyPlanStore = InMemoryStudyPlanStore(),
        profile: any ProfileService = MockProfileService(latency: .zero)
    ) -> StudentHomeViewModel {
        StudentHomeViewModel(
            store: studyPlans, materials: materials, decks: decks,
            quizzes: quizzes, profile: profile
        )
    }

    private var provenance: AIProvenance {
        AIProvenance(materialId: "m", pageNumbers: [], confidence: .high)
    }

    /// A plan placed around today: two sessions today (entered out of order), one yesterday,
    /// one tomorrow.
    private func planAroundToday() -> StudyPlan {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func at(_ dayOffset: Int, _ hour: Int) -> Date {
            (calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today)
                .addingTimeInterval(TimeInterval(hour * 3_600))
        }
        return StudyPlan(
            input: StudyPlanInput(subjects: ["Maths", "Physics"], weeklyHours: 4, intensity: .balanced),
            sessions: [
                StudySession(subject: "Maths", estimatedMinutes: 45, scheduledAt: at(0, 15)),
                StudySession(subject: "Physics", estimatedMinutes: 30, scheduledAt: at(0, 9)),
                StudySession(subject: "Maths", estimatedMinutes: 45, scheduledAt: at(-1, 9)),
                StudySession(subject: "Physics", estimatedMinutes: 30, scheduledAt: at(1, 9)),
            ]
        )
    }

    @Test("Only today's sessions are listed, earliest first")
    func todaySessionsAreFilteredAndSorted() async {
        let viewModel = model(
            studyPlans: InMemoryStudyPlanStore(seededWith: [planAroundToday()])
        )

        await viewModel.load()

        #expect(viewModel.todaySessions.map(\.subject) == ["Physics", "Maths"])
    }

    @Test("No plan anywhere is an empty list and a readable count — not a failure")
    func noPlanIsEmptyNotFailure() async {
        let viewModel = model()

        await viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.plan == nil)
        #expect(viewModel.planError == nil)
        #expect(viewModel.todaySessions.isEmpty)
        #expect(viewModel.dueCards == 0)
    }

    @Test("The streak pill stays hidden while there is no data to count")
    func streakHiddenWithoutData() async {
        let viewModel = model()

        await viewModel.load()

        #expect(viewModel.streakDays == nil)
    }

    @Test("One real material is enough for the streak to be shown, formatted from the catalogue")
    func streakShownWithData() async throws {
        let viewModel = model(
            materials: InMemoryMaterialStore(seededWith: [
                Material(title: "Lecture", source: .text, text: "body")
            ])
        )

        await viewModel.load()

        let days = try #require(viewModel.streakDays)
        #expect(viewModel.streakValue(days) == L10n.progressStreakValue.string(days))
        #expect(viewModel.streakLabel == L10n.progressStreak.string)
    }

    @Test("The due count adds due cards across every deck and skips the scheduled ones")
    func dueCountSpansDecks() async {
        let notDue = Flashcard(
            front: "q", back: "a",
            provenance: provenance,
            sr: SpacedRepetitionState(dueAt: .now.addingTimeInterval(86_400), reps: 1)
        )
        let dueA = Flashcard(front: "q", back: "a", provenance: provenance)
        let dueB = Flashcard(front: "q", back: "a", provenance: provenance)
        let viewModel = model(
            decks: InMemoryDeckStore(seededWith: [
                Deck(title: "A", cards: [dueA]),
                Deck(title: "B", cards: [dueB, notDue]),
            ])
        )

        await viewModel.load()

        #expect(viewModel.dueCards == 2)
    }

    @Test("A failed deck read hides the badge rather than inventing a zero")
    func deckFailureMeansNoCount() async {
        let decks = InMemoryDeckStore()
        await decks.forceFailure(.storageFailed)
        let viewModel = model(decks: decks)

        await viewModel.load()

        #expect(viewModel.dueCards == nil)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model()

        #expect(viewModel.planHeading == L10n.planTitle.string)
        #expect(viewModel.planEmptyTitle == L10n.planEmptyTitle.string)
        #expect(viewModel.planEmptyBody == L10n.planEmptyBody.string)
        #expect(viewModel.planNoSessionsTitle == L10n.planNoSessions.string)
        #expect(viewModel.planDuration(45) == L10n.planMinutes.string(45))
        #expect(viewModel.streakLabel == L10n.progressStreak.string)
    }
}
