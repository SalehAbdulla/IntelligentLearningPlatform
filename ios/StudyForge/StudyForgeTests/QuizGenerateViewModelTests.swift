//
//  QuizGenerateViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F05's quiz-generation and save flow.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz generation (F05)")
@MainActor
struct QuizGenerateViewModelTests {

    private let sampleText = """
    Third normal form (3NF) is a database normalisation level used in relational design. \
    A relation is in 3NF when it is already in second normal form and has no transitive dependencies. \
    Reaching 3NF reduces data redundancy and prevents update anomalies at the cost of additional joins. \
    First normal form requires atomic values so each column holds a single value. \
    Second normal form removes partial dependencies on part of a composite key.
    """

    private func material(text: String? = nil) -> Material {
        Material(title: "Lecture 4", source: .text, text: text ?? sampleText)
    }

    private func model(
        material: Material?,
        quizStore: any QuizStore = InMemoryQuizStore()
    ) -> QuizGenerateViewModel {
        QuizGenerateViewModel(
            initialMaterial: material,
            materialStore: InMemoryMaterialStore(seededWith: [material].compactMap { $0 }),
            quizStore: quizStore,
            router: AIRouter(
                providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
                governor: AICostGovernor()
            )
        )
    }

    @Test("Generating produces the requested number of questions")
    func generateSucceeds() async {
        let viewModel = model(material: material())

        await viewModel.generate()

        #expect(viewModel.questions.count == 10)
        #expect(viewModel.phase == .review)
        #expect(viewModel.questions.allSatisfy { $0.options.count == 4 })
    }

    @Test("A material with too little text is refused")
    func shortSourceIsRefused() async {
        let viewModel = model(material: material(text: "Too short."))

        await viewModel.generate()

        #expect(viewModel.questions.isEmpty)
        #expect(
            viewModel.error == AppError.materialUnreadable(
                reason: "There wasn't enough text in that material to work with."
            )
        )
    }

    @Test("Saving creates a quiz holding the generated questions")
    func saveQuizPersists() async throws {
        let store = InMemoryQuizStore()
        let viewModel = model(material: material(), quizStore: store)

        await viewModel.generate()
        viewModel.quizTitle = "My quiz"
        await viewModel.saveQuiz()

        #expect(viewModel.savedQuiz != nil)
        #expect(viewModel.phase == .saved)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "My quiz")
        #expect(all.first?.questions.count == viewModel.questions.count)
    }

    @Test("A blank quiz title falls back to the material title")
    func blankTitleFallsBack() async throws {
        let source = material()
        let store = InMemoryQuizStore()
        let viewModel = model(material: source, quizStore: store)

        await viewModel.generate()
        await viewModel.saveQuiz()

        #expect(try await store.all().first?.title == source.title)
    }

    @Test("The timer toggle is recorded on the saved quiz")
    func timerConfigIsRecorded() async throws {
        let store = InMemoryQuizStore()
        let viewModel = model(material: material(), quizStore: store)

        await viewModel.generate()
        viewModel.timerEnabled = true
        viewModel.timerMinutes = 15
        await viewModel.saveQuiz()

        #expect(try await store.all().first?.timerMinutes == 15)
        #expect(try await store.all().first?.isTimed == true)
    }

    @Test("A quiz is untimed unless the student asks for a clock")
    func untimedByDefault() async throws {
        let store = InMemoryQuizStore()
        let viewModel = model(material: material(), quizStore: store)

        await viewModel.generate()
        await viewModel.saveQuiz()

        #expect(try await store.all().first?.timerMinutes == nil)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model(material: material())

        #expect(viewModel.title == L10n.quizGenerateTitle.string)
        #expect(viewModel.typeLabel == L10n.quizTypeLabel.string)
        #expect(viewModel.countLabel == L10n.quizCountLabel.string)
        #expect(viewModel.generateTitle == L10n.quizGenerate.string)
        #expect(viewModel.saveTitle == L10n.quizSave.string)
        #expect(viewModel.savedTitle == L10n.quizSavedTitle.string)
        #expect(viewModel.timerToggleTitle == L10n.quizTimerToggle.string)
        #expect(viewModel.minutesTitle(15) == L10n.quizMinutes.string(15))
    }
}
