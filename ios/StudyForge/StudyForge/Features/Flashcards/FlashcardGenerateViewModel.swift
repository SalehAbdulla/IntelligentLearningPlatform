//
//  FlashcardGenerateViewModel.swift
//  StudyForge
//
//  Presentation logic for F04's generation path — E02's config, E03's generating and the
//  "review your cards before saving" step in one stateful sheet, mirroring the summary flow.
//
//  WHY THE SOURCE IS OPTIONAL
//  --------------------------
//  The same sheet serves two entries: the library's "make cards" button (a material is already
//  chosen) and the decks list's "new deck" button (nothing chosen yet). When `initialMaterial` is
//  nil the sheet opens on a material picker first; otherwise it skips straight to configuration.
//

import Foundation

@MainActor
@Observable
final class FlashcardGenerateViewModel {

    /// Which state the sheet is drawing.
    enum Phase: Equatable {
        case choosingSource
        case configuring
        case generating
        case review
        case saved
    }

    // MARK: Source selection

    private(set) var materials: [Material] = []
    private(set) var selectedMaterial: Material?

    // MARK: Configuration

    /// Optional because `SFSegmentedField` models "nothing chosen yet" as `nil`. Defaulted so the
    /// Generate button works immediately.
    var count: Int? = 20
    var difficulty: FlashcardDifficulty? = .mixed

    /// The deck name the student can edit before saving. Empty means "use the material's title".
    var deckTitle = ""

    // MARK: Derived state

    private(set) var isGenerating = false
    private(set) var isSaving = false
    private(set) var error: AppError?
    private(set) var cards: [Flashcard] = []
    private(set) var savedDeck: Deck?

    private let materialStore: any MaterialStore
    private let deckStore: any DeckStore
    private let router: AIRouter
    private let learningStyle: LearningStyle

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        deckStore: any DeckStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        self.materialStore = materialStore
        self.deckStore = deckStore
        self.router = router
        self.learningStyle = learningStyle
        self.selectedMaterial = initialMaterial
    }

    // MARK: Phase

    var phase: Phase {
        if savedDeck != nil { return .saved }
        if !cards.isEmpty { return .review }
        if isGenerating { return .generating }
        if selectedMaterial != nil { return .configuring }
        return .choosingSource
    }

    // MARK: Copy

    var title: String { L10n.flashcardGenerateTitle.string }
    var sourceLabel: String { L10n.flashcardSourceLabel.string }
    var sourcePrompt: String { L10n.flashcardSourcePrompt.string }
    var countLabel: String { L10n.flashcardCountLabel.string }
    var difficultyLabel: String { L10n.flashcardDifficultyLabel.string }
    var generateTitle: String { L10n.flashcardGenerate.string }
    var generatingTitle: String { L10n.flashcardGeneratingTitle.string }
    var generatingBody: String { L10n.flashcardGeneratingBody.string }
    var reviewHeading: String { L10n.flashcardReviewHeading.string }
    var deckNameLabel: String { L10n.flashcardDeckNameLabel.string }
    var deckNamePlaceholder: String { selectedMaterial?.title ?? "" }
    var saveDeckTitle: String { L10n.flashcardSaveDeck.string }
    var savingDeckTitle: String { L10n.flashcardSavingDeck.string }
    var savedTitle: String { L10n.flashcardSavedTitle.string }
    var savedBody: String { L10n.flashcardSavedBody.string }

    func difficultyTitle(_ difficulty: FlashcardDifficulty) -> String {
        switch difficulty {
        case .recall: L10n.flashcardDifficultyRecall.string
        case .understanding: L10n.flashcardDifficultyUnderstanding.string
        case .mixed: L10n.flashcardDifficultyMixed.string
        }
    }

    // MARK: Actions

    func loadMaterials() async {
        guard materials.isEmpty else { return }
        do {
            materials = try await materialStore.all()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func choose(_ material: Material) {
        selectedMaterial = material
        deckTitle = ""
    }

    func generate() async {
        guard !isGenerating, let material = selectedMaterial, let count, let difficulty else { return }
        error = nil
        cards = []
        isGenerating = true
        defer { isGenerating = false }

        let context = AIGenerationContext(
            materialId: material.id,
            text: material.text,
            language: .english,
            learningStyle: learningStyle
        )

        do {
            let generated = try await router.makeFlashcards(
                FlashcardRequest(context: context, count: count, difficulty: difficulty)
            )
            cards = generated.value.map {
                Flashcard(
                    front: $0.front,
                    back: $0.back,
                    cardType: .qa,
                    provenance: generated.provenance,
                    aiDrafted: true
                )
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func saveDeck() async {
        guard !cards.isEmpty, savedDeck == nil, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let name = deckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let deck = Deck(
            title: name.isEmpty ? (selectedMaterial?.title ?? title) : name,
            materialId: selectedMaterial?.id,
            cards: cards
        )

        do {
            try await deckStore.add(deck)
            savedDeck = deck
        } catch {
            self.error = AppError.from(error)
        }
    }
}
