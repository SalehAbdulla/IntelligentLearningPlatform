//
//  FlashcardGenerateViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F04's card-generation and save flow.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard generation (F04)")
@MainActor
struct FlashcardGenerateViewModelTests {

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
        deckStore: any DeckStore = InMemoryDeckStore()
    ) -> FlashcardGenerateViewModel {
        FlashcardGenerateViewModel(
            initialMaterial: material,
            materialStore: InMemoryMaterialStore(seededWith: [material].compactMap { $0 }),
            deckStore: deckStore,
            router: AIRouter(
                providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
                governor: AICostGovernor()
            )
        )
    }

    @Test("Generating produces the requested number of cards")
    func generateSucceeds() async {
        let viewModel = model(material: material())

        await viewModel.generate()

        #expect(viewModel.cards.count == 20)
        #expect(viewModel.phase == .review)
    }

    @Test("A material with too little text is refused")
    func shortSourceIsRefused() async {
        let viewModel = model(material: material(text: "Too short."))

        await viewModel.generate()

        #expect(viewModel.cards.isEmpty)
        #expect(
            viewModel.error == AppError.materialUnreadable(
                reason: "There wasn't enough text in that material to work with."
            )
        )
    }

    @Test("Saving creates a deck holding the generated cards")
    func saveDeckPersists() async throws {
        let store = InMemoryDeckStore()
        let viewModel = model(material: material(), deckStore: store)

        await viewModel.generate()
        viewModel.deckTitle = "My deck"
        await viewModel.saveDeck()

        #expect(viewModel.savedDeck != nil)
        #expect(viewModel.phase == .saved)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "My deck")
        #expect(all.first?.cards.count == viewModel.cards.count)
    }

    @Test("A blank deck title falls back to the material title")
    func blankTitleFallsBack() async throws {
        let source = material()
        let store = InMemoryDeckStore()
        let viewModel = model(material: source, deckStore: store)

        await viewModel.generate()
        await viewModel.saveDeck()

        #expect(try await store.all().first?.title == source.title)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model(material: material())

        #expect(viewModel.title == L10n.flashcardGenerateTitle.string)
        #expect(viewModel.countLabel == L10n.flashcardCountLabel.string)
        #expect(viewModel.difficultyLabel == L10n.flashcardDifficultyLabel.string)
        #expect(viewModel.generateTitle == L10n.flashcardGenerate.string)
        #expect(viewModel.saveDeckTitle == L10n.flashcardSaveDeck.string)
        #expect(viewModel.savedTitle == L10n.flashcardSavedTitle.string)
    }
}
