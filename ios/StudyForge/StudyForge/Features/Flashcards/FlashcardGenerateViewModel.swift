import Foundation

@MainActor
@Observable
final class FlashcardGenerateViewModel {

    enum Phase: Equatable {
        case choosingSource
        case configuring
        case generating
        case review
        case saved
    }

    private(set) var materials: [Material] = []
    private(set) var hasLoadedMaterials = false
    private(set) var selectedMaterial: Material?
    private(set) var decks: [Deck] = []

    var count: Int? = FlashcardLimits.defaultCount
    var difficulty: FlashcardDifficulty? = .mixed
    var cardType: CardType? = .qa
    var deckTitle = ""
    var targetDeckID: String?

    private(set) var firstPage = 1
    private(set) var lastPage = 1

    private(set) var isGenerating = false
    private(set) var isSaving = false
    private(set) var error: AppError?
    private(set) var cards: [Flashcard] = []
    private(set) var savedDeck: Deck?
    private(set) var engine: SummaryEngine = .onDevice

    let startedWithMaterial: Bool

    private let materialStore: any MaterialStore
    private let deckStore: any DeckStore
    private let router: AIRouter
    private let learningStyle: LearningStyle

    @ObservationIgnored private var generationID = UUID()

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
        self.startedWithMaterial = initialMaterial != nil
        self.lastPage = Self.pageCount(of: initialMaterial)
        self.engine = predictedEngine
    }

    var phase: Phase {
        if savedDeck != nil { return .saved }
        if !cards.isEmpty { return .review }
        if isGenerating { return .generating }
        if selectedMaterial != nil { return .configuring }
        return .choosingSource
    }

    var title: String { L10n.flashcardGenerateTitle.string }
    var sourceLabel: String { L10n.flashcardSourceLabel.string }
    var sourcePrompt: String { L10n.flashcardSourcePrompt.string }
    var countLabel: String { L10n.flashcardCountLabel.string }
    var difficultyLabel: String { L10n.flashcardDifficultyLabel.string }
    var cardTypeLabel: String { L10n.flashcardTypeLabel.string }
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

    var requestedCount: Int { count ?? FlashcardLimits.defaultCount }

    var generateButtonTitle: String { FlashcardCopy.generateCount(requestedCount) }

    var saveTitle: String { FlashcardCopy.saveCards(cards.count) }

    var pageCount: Int { Self.pageCount(of: selectedMaterial) }

    var hasPageRange: Bool {
        pageCount > 1 && pageSections.contains { $0.page != nil }
    }

    var rangeTitle: String {
        hasPageRange ? FlashcardCopy.pageRange(firstPage, lastPage) : FlashcardCopy.wholeMaterial
    }

    var sourceText: String {
        guard let selectedMaterial else { return "" }
        guard hasPageRange else { return selectedMaterial.text }
        return pageSections
            .filter { section in
                guard let page = section.page else { return firstPage == 1 }
                return page >= firstPage && page <= lastPage
            }
            .map { $0.body }
            .joined(separator: "\n")
    }

    var materialError: String? {
        guard let selectedMaterial else { return nil }
        if selectedMaterial.hasNoText { return FlashcardCopy.materialEmpty }
        if FlashcardText.isBlank(sourceText) { return FlashcardCopy.rangeEmpty }
        return nil
    }

    var canGenerate: Bool {
        phase == .configuring && materialError == nil
    }

    var predictedEngine: SummaryEngine {
        switch router.decide(for: .makeFlashcards) {
        case .preferred(let tier), .fellBack(_, let tier, _):
            return SummaryEngine(tier: tier)
        case .noneAvailable:
            return .onDevice
        }
    }

    var targetDeck: Deck? {
        guard let targetDeckID else { return nil }
        return decks.first { $0.id == targetDeckID }
    }

    var duplicateIDs: Set<String> {
        var seen = Set((targetDeck?.cards ?? []).map { FlashcardText.normalized($0.front) })
        var duplicates = Set<String>()
        for card in cards {
            let key = FlashcardText.normalized(card.front)
            guard !key.isEmpty else { continue }
            if seen.contains(key) {
                duplicates.insert(card.id)
            } else {
                seen.insert(key)
            }
        }
        return duplicates
    }

    func loadMaterials() async {
        guard !hasLoadedMaterials else { return }
        do {
            materials = try await materialStore.all()
            hasLoadedMaterials = true
        } catch {
            self.error = AppError.from(error)
        }
    }

    func loadDecks() async {
        do {
            decks = try await deckStore.all()
        } catch {
            decks = []
        }
        if let targetDeckID, !decks.contains(where: { $0.id == targetDeckID }) {
            self.targetDeckID = nil
        }
    }

    func choose(_ material: Material) {
        selectedMaterial = material
        deckTitle = ""
        firstPage = 1
        lastPage = Self.pageCount(of: material)
        error = nil
    }

    func changeMaterial() {
        guard !isGenerating, cards.isEmpty, savedDeck == nil else { return }
        selectedMaterial = nil
        error = nil
    }

    func setFirstPage(_ page: Int) {
        firstPage = min(max(page, 1), lastPage)
    }

    func setLastPage(_ page: Int) {
        lastPage = max(min(page, pageCount), firstPage)
    }

    func limitDeckTitle() {
        let cleaned = FlashcardText.clamp(
            deckTitle.replacingOccurrences(of: "\n", with: " "),
            to: FlashcardLimits.deckTitleMaxCharacters
        )
        if cleaned != deckTitle {
            deckTitle = cleaned
        }
    }

    func generate() async {
        guard !isGenerating, savedDeck == nil, let material = selectedMaterial, let count, let difficulty,
              let cardType, materialError == nil else { return }
        error = nil
        cards = []
        isGenerating = true
        let runID = UUID()
        generationID = runID
        defer {
            if generationID == runID { isGenerating = false }
        }

        let context = AIGenerationContext(
            materialId: material.id,
            text: sourceText,
            language: .english,
            learningStyle: learningStyle
        )

        do {
            let generated = try await router.makeFlashcards(
                FlashcardRequest(context: context, count: count, difficulty: difficulty, cardType: cardType)
            )
            guard generationID == runID else { return }
            engine = SummaryEngine(tier: generated.tier)
            let made = generated.value
                .filter { !FlashcardText.isBlank($0.front) && !FlashcardText.isBlank($0.back) }
                .map {
                    Flashcard(
                        front: FlashcardText.cleaned($0.front, limit: FlashcardLimits.frontMaxCharacters),
                        back: FlashcardText.cleaned($0.back, limit: FlashcardLimits.backMaxCharacters),
                        cardType: cardType,
                        provenance: generated.provenance,
                        aiDrafted: true
                    )
                }
            if made.isEmpty {
                error = .materialUnreadable(reason: FlashcardCopy.noCards)
            } else {
                cards = made
            }
        } catch {
            guard generationID == runID else { return }
            self.error = AppError.from(error)
        }
    }

    func cancelGeneration() {
        generationID = UUID()
        isGenerating = false
    }

    func discardCards() {
        generationID = UUID()
        isGenerating = false
        cards = []
        error = nil
    }

    func updateCard(id: String, front: String, back: String) {
        guard let index = cards.firstIndex(where: { $0.id == id }),
              !FlashcardText.isBlank(front), !FlashcardText.isBlank(back) else { return }
        cards[index].front = FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters)
        cards[index].back = FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters)
    }

    func removeCard(id: String) {
        cards.removeAll { $0.id == id }
    }

    func removeDuplicates() {
        let duplicates = duplicateIDs
        cards.removeAll { duplicates.contains($0.id) }
    }

    func addCard(front: String, back: String) {
        guard let material = selectedMaterial,
              !FlashcardText.isBlank(front), !FlashcardText.isBlank(back) else { return }
        cards.append(
            Flashcard(
                front: FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters),
                back: FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters),
                cardType: cardType ?? .qa,
                provenance: AIProvenance(materialId: material.id, pageNumbers: [], confidence: .high),
                aiDrafted: false
            )
        )
    }

    func saveDeck() async {
        guard !cards.isEmpty, savedDeck == nil, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let deck: Deck
            if let targetDeckID, var existing = try await deckStore.deck(id: targetDeckID) {
                existing.cards.append(contentsOf: cards)
                existing.updatedAt = .now
                deck = existing
            } else {
                let name = FlashcardText.cleaned(deckTitle, limit: FlashcardLimits.deckTitleMaxCharacters)
                deck = Deck(
                    title: name.isEmpty ? (selectedMaterial?.title ?? title) : name,
                    materialId: selectedMaterial?.id,
                    cards: cards
                )
            }
            try await deckStore.add(deck)
            savedDeck = deck
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    private var pageSections: [(page: Int?, body: String)] {
        guard let selectedMaterial else { return [] }
        return PageMarker.parse(selectedMaterial.text)
    }

    private static func pageCount(of material: Material?) -> Int {
        max(material?.pageCount ?? 1, 1)
    }
}
