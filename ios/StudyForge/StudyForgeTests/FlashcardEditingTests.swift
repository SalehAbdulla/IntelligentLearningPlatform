import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard editing (F04)")
@MainActor
struct FlashcardEditingTests {

    private func card(id: String, tags: [String] = []) -> Flashcard {
        Flashcard(
            id: id,
            front: "Question \(id)",
            back: "Answer \(id)",
            tags: tags,
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
        )
    }

    @Test("Tags are trimmed, lowercased, de-hashed and joined with dashes")
    func tagNormalisation() {
        #expect(FlashcardTags.normalized("  #AVL Rotations ") == "avl-rotations")
        #expect(FlashcardTags.normalized("   ") == nil)
        #expect(FlashcardTags.normalized(FlashcardLimits.flagTag) == nil)
        #expect(FlashcardTags.normalized(String(repeating: "a", count: 40))?.count == FlashcardTags.maxLength)
    }

    @Test("Adding a tag skips duplicates and stops at the limit")
    func addingTags() {
        #expect(FlashcardTags.adding("Trees", to: ["trees"]) == ["trees"])
        let full = (0..<FlashcardTags.maxCount).map { "t\($0)" }
        #expect(FlashcardTags.adding("extra", to: full) == full)
        #expect(FlashcardTags.adding("graphs", to: ["trees"]) == ["trees", "graphs"])
    }

    @Test("Merging edited tags keeps an existing flag")
    func mergeKeepsFlag() {
        let merged = FlashcardTags.merged(["heaps", "heaps"], keepingFlagFrom: ["old", FlashcardLimits.flagTag])
        #expect(merged == ["heaps", FlashcardLimits.flagTag])
        #expect(FlashcardTags.visible(merged) == ["heaps"])
    }

    @Test("Editing a card saves its text and tags and keeps its flag")
    func applySavesTextAndTags() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d1", title: "Trees", cards: [card(id: "c1", tags: [FlashcardLimits.flagTag])])])
        let viewModel = DeckOverviewViewModel(deckId: "d1", store: store, images: InMemoryFlashcardImageStore())
        await viewModel.load()

        await viewModel.apply(FlashcardEdit(front: " New front ", back: "New back", tags: ["avl"], deckId: "d1"), toCard: "c1")

        let saved = try await store.deck(id: "d1")?.cards.first
        #expect(saved?.front == "New front")
        #expect(saved?.back == "New back")
        #expect(saved?.tags == ["avl", FlashcardLimits.flagTag])
    }

    @Test("Choosing another deck moves the card there with its schedule")
    func applyMovesCard() async throws {
        var moving = card(id: "c1")
        moving.sr = SpacedRepetitionState(interval: 6, dueAt: .now.addingTimeInterval(86_400), reps: 2)
        let store = InMemoryDeckStore(seededWith: [
            Deck(id: "d1", title: "Trees", cards: [moving, card(id: "c2")]),
            Deck(id: "d2", title: "Graphs")
        ])
        let viewModel = DeckOverviewViewModel(deckId: "d1", store: store, images: InMemoryFlashcardImageStore())
        await viewModel.load()
        #expect(viewModel.allDecks.count == 2)

        await viewModel.apply(FlashcardEdit(front: "Question c1", back: "Answer c1", deckId: "d2"), toCard: "c1")

        #expect(try await store.deck(id: "d1")?.cards.map(\.id) == ["c2"])
        let moved = try await store.deck(id: "d2")?.cards.first
        #expect(moved?.id == "c1")
        #expect(moved?.sr.reps == 2)
        #expect(viewModel.cards.map(\.id) == ["c2"])
    }

    @Test("An attached image is saved and a removed one is deleted")
    func applyHandlesImages() async {
        let images = InMemoryFlashcardImageStore(seededWith: ["c2": Data([9])])
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d1", title: "Trees", cards: [card(id: "c1"), card(id: "c2")])])
        let viewModel = DeckOverviewViewModel(deckId: "d1", store: store, images: images)
        await viewModel.load()

        await viewModel.apply(FlashcardEdit(front: "Question c1", back: "Answer c1", imageData: Data([1, 2, 3])), toCard: "c1")
        await viewModel.apply(FlashcardEdit(front: "Question c2", back: "Answer c2", removesImage: true), toCard: "c2")

        #expect(await viewModel.image(for: "c1") == Data([1, 2, 3]))
        #expect(await viewModel.image(for: "c2") == nil)
    }

    @Test("A new card from the editor keeps its tags and image")
    func addCardFromEdit() async throws {
        let images = InMemoryFlashcardImageStore()
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d1", title: "Trees")])
        let viewModel = DeckOverviewViewModel(deckId: "d1", store: store, images: images)
        await viewModel.load()

        await viewModel.addCard(FlashcardEdit(front: "Front", back: "Back", tags: ["trees"], imageData: Data([7])))

        let added = try #require(try await store.deck(id: "d1")?.cards.first)
        #expect(added.tags == ["trees"])
        #expect(added.aiDrafted == false)
        #expect(await images.image(for: added.id) == Data([7]))
    }

    @Test("A blank edit changes nothing")
    func blankEditIgnored() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d1", title: "Trees", cards: [card(id: "c1")])])
        let viewModel = DeckOverviewViewModel(deckId: "d1", store: store, images: InMemoryFlashcardImageStore())
        await viewModel.load()

        await viewModel.apply(FlashcardEdit(front: "  ", back: "Back"), toCard: "c1")

        #expect(try await store.deck(id: "d1")?.cards.first?.front == "Question c1")
    }

    @Test("The review session loads the current card's image")
    func reviewLoadsImage() async {
        let images = InMemoryFlashcardImageStore(seededWith: ["c1": Data([5])])
        let viewModel = FlashcardReviewViewModel(
            deck: Deck(id: "d1", title: "Trees", cards: [card(id: "c1"), card(id: "c2")]),
            store: InMemoryDeckStore(),
            images: images
        )

        await viewModel.loadImage()
        #expect(viewModel.currentImage == Data([5]))

        viewModel.reveal()
        await viewModel.rate(.good)
        await viewModel.loadImage()
        #expect(viewModel.currentImage == nil)
    }

    @Test("Large images are scaled down to the maximum edge")
    func imageTargetSize() {
        let size = FlashcardImagePreparer.targetSize(for: CGSize(width: 4_000, height: 2_000))
        #expect(size.width == FlashcardImagePreparer.maxDimension)
        #expect(size.height == FlashcardImagePreparer.maxDimension / 2)
        #expect(FlashcardImagePreparer.targetSize(for: CGSize(width: 300, height: 200)) == CGSize(width: 300, height: 200))
        #expect(FlashcardImagePreparer.prepared(Data([0, 1, 2])) == nil)
    }
}
