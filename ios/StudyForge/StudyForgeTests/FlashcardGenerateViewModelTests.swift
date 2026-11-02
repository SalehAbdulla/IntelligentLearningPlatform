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

    @Test("The chosen card type shapes the generated cards")
    func cardTypeIsApplied() async {
        let viewModel = model(material: material())
        viewModel.cardType = .cloze

        await viewModel.generate()

        #expect(viewModel.cards.allSatisfy { $0.cardType == .cloze })
        // The mock blanks a word for a cloze card, so the front is a sentence with a gap rather than
        // a question — proof the selector actually reached the generator.
        #expect(viewModel.cards.contains { $0.front.contains("_____") })
    }

    @Test("Cards default to question-and-answer when no type is chosen")
    func defaultsToQa() async {
        let viewModel = model(material: material())

        await viewModel.generate()

        #expect(viewModel.cards.allSatisfy { $0.cardType == .qa })
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model(material: material())

        #expect(viewModel.title == L10n.flashcardGenerateTitle.string)
        #expect(viewModel.countLabel == L10n.flashcardCountLabel.string)
        #expect(viewModel.difficultyLabel == L10n.flashcardDifficultyLabel.string)
        #expect(viewModel.cardTypeLabel == L10n.flashcardTypeLabel.string)
        #expect(viewModel.generateTitle == L10n.flashcardGenerate.string)
        #expect(viewModel.saveDeckTitle == L10n.flashcardSaveDeck.string)
        #expect(viewModel.savedTitle == L10n.flashcardSavedTitle.string)
        #expect(CardType.cloze.title == L10n.flashcardTypeCloze.string)
    }

    @Test("Repeated questions are flagged and can be removed in one go")
    func duplicatesAreFlagged() async {
        let viewModel = model(material: material())

        await viewModel.generate()

        #expect(!viewModel.duplicateIDs.isEmpty)
        viewModel.removeDuplicates()
        #expect(viewModel.duplicateIDs.isEmpty)
        let fronts = viewModel.cards.map { FlashcardText.normalized($0.front) }
        #expect(Set(fronts).count == fronts.count)
    }

    @Test("Cards that repeat a question already in the chosen deck are flagged")
    func duplicatesAgainstExistingDeck() async throws {
        let store = InMemoryDeckStore()
        let viewModel = model(material: material(), deckStore: store)
        await viewModel.generate()
        viewModel.removeDuplicates()

        try await store.add(Deck(id: "existing", title: "Existing", cards: [viewModel.cards[0]]))
        await viewModel.loadDecks()
        viewModel.targetDeckID = "existing"

        #expect(viewModel.duplicateIDs.contains(viewModel.cards[0].id))
    }

    @Test("Saving into an existing deck appends the new cards")
    func saveIntoExistingDeck() async throws {
        let existingCard = Flashcard(
            front: "Existing question",
            back: "Existing answer",
            provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high)
        )
        let store = InMemoryDeckStore(seededWith: [Deck(id: "existing", title: "Existing", cards: [existingCard])])
        let viewModel = model(material: material(), deckStore: store)
        await viewModel.loadDecks()
        viewModel.targetDeckID = "existing"

        await viewModel.generate()
        let generated = viewModel.cards.count
        await viewModel.saveDeck()

        let saved = try await store.deck(id: "existing")
        #expect(saved?.cards.count == generated + 1)
        #expect(viewModel.savedDeck?.id == "existing")
        #expect(try await store.all().count == 1)
    }

    @Test("A page range limits the text sent to the generator")
    func pageRangeLimitsSource() {
        let text = PageMarker.forPage(1) + "Alpha page one text."
            + PageMarker.forPage(2) + "Beta page two text."
            + PageMarker.forPage(3) + "Gamma page three text."
        let viewModel = model(material: Material(title: "Paged", source: .pdf, text: text, pageCount: 3))

        #expect(viewModel.hasPageRange)
        viewModel.setFirstPage(2)
        viewModel.setLastPage(2)

        #expect(viewModel.sourceText.contains("Beta"))
        #expect(!viewModel.sourceText.contains("Alpha"))
        #expect(!viewModel.sourceText.contains("Gamma"))
        #expect(viewModel.rangeTitle == FlashcardCopy.pageRange(2, 2))
    }

    @Test("The page range can never run backwards or past the last page")
    func pageRangeIsClamped() {
        let text = PageMarker.forPage(1) + "One." + PageMarker.forPage(2) + "Two." + PageMarker.forPage(3) + "Three."
        let viewModel = model(material: Material(title: "Paged", source: .pdf, text: text, pageCount: 3))

        viewModel.setLastPage(10)
        #expect(viewModel.lastPage == 3)
        viewModel.setFirstPage(5)
        #expect(viewModel.firstPage == 3)
        viewModel.setLastPage(1)
        #expect(viewModel.lastPage == 3)
        viewModel.setFirstPage(0)
        #expect(viewModel.firstPage == 1)
    }

    @Test("A material with no text cannot be generated from")
    func emptyMaterialIsBlocked() async {
        let viewModel = model(material: material(text: "   "))

        #expect(viewModel.materialError == FlashcardCopy.materialEmpty)
        #expect(viewModel.canGenerate == false)

        await viewModel.generate()
        #expect(viewModel.cards.isEmpty)
    }

    @Test("Editing a draft card trims it and refuses a blank side")
    func editDraftCard() async {
        let viewModel = model(material: material())
        await viewModel.generate()
        let id = viewModel.cards[0].id

        viewModel.updateCard(id: id, front: "  New front  ", back: "New back")
        #expect(viewModel.cards[0].front == "New front")

        viewModel.updateCard(id: id, front: "", back: "Other")
        #expect(viewModel.cards[0].front == "New front")
    }

    @Test("Removing and adding draft cards changes what will be saved")
    func removeAndAddDraftCards() async {
        let viewModel = model(material: material())
        await viewModel.generate()
        let before = viewModel.cards.count

        viewModel.removeCard(id: viewModel.cards[0].id)
        viewModel.addCard(front: "My question", back: "My answer")

        #expect(viewModel.cards.count == before)
        #expect(viewModel.cards.last?.aiDrafted == false)
    }

    @Test("Discarding the drafts returns to configuration")
    func discardReturnsToConfigure() async {
        let viewModel = model(material: material())
        await viewModel.generate()

        viewModel.discardCards()

        #expect(viewModel.cards.isEmpty)
        #expect(viewModel.phase == .configuring)
    }

    @Test("The deck name is cut to the limit and loses line breaks")
    func deckTitleLimit() {
        let viewModel = model(material: material())
        viewModel.deckTitle = "Line\nbreak" + String(repeating: "x", count: 100)

        viewModel.limitDeckTitle()

        #expect(viewModel.deckTitle.count == FlashcardLimits.deckTitleMaxCharacters)
        #expect(!viewModel.deckTitle.contains("\n"))
    }

    @Test("The generate button names the chosen card count")
    func generateTitleNamesCount() {
        let viewModel = model(material: material())
        viewModel.count = 30

        #expect(viewModel.generateButtonTitle == FlashcardCopy.generateCount(30))
    }
}
