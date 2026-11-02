import Foundation

@MainActor
@Observable
final class DeckOverviewViewModel {

    private(set) var deck: Deck?
    private(set) var hasLoaded = false
    private(set) var isMissing = false
    private(set) var isDeleted = false
    private(set) var isWorking = false
    private(set) var error: AppError?

    let deckId: String

    private let store: any DeckStore

    init(deckId: String, store: any DeckStore) {
        self.deckId = deckId
        self.store = store
    }

    var cards: [Flashcard] { deck?.cards ?? [] }
    var dueCount: Int { deck?.dueCount() ?? 0 }
    var newCount: Int { deck?.newCount ?? 0 }
    var learningCount: Int { deck?.learningCount ?? 0 }
    var masteredCount: Int { deck?.masteredCount ?? 0 }
    var canStudy: Bool { dueCount > 0 }

    var caughtUpText: String? {
        guard let deck, !deck.cards.isEmpty, dueCount == 0, let next = deck.nextDueDate() else { return nil }
        return FlashcardCopy.caughtUp(FlashcardText.dueLabel(next))
    }

    func load() async {
        do {
            if let found = try await store.deck(id: deckId) {
                deck = found
                isMissing = false
            } else {
                deck = nil
                isMissing = true
            }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func rename(to title: String) async {
        let cleaned = FlashcardText.cleaned(
            title.replacingOccurrences(of: "\n", with: " "),
            limit: FlashcardLimits.deckTitleMaxCharacters
        )
        guard var current = deck, !cleaned.isEmpty, cleaned != current.title else { return }
        current.title = cleaned
        await persist(current)
    }

    func updateCard(id: String, front: String, back: String) async {
        guard var current = deck,
              let index = current.cards.firstIndex(where: { $0.id == id }),
              !FlashcardText.isBlank(front), !FlashcardText.isBlank(back) else { return }
        current.cards[index].front = FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters)
        current.cards[index].back = FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters)
        await persist(current)
    }

    func addCard(front: String, back: String) async {
        guard var current = deck, !FlashcardText.isBlank(front), !FlashcardText.isBlank(back) else { return }
        current.cards.append(
            Flashcard(
                front: FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters),
                back: FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters),
                provenance: AIProvenance(materialId: current.materialId ?? current.id, pageNumbers: [], confidence: .high),
                aiDrafted: false
            )
        )
        await persist(current)
    }

    func deleteCard(id: String) async {
        guard var current = deck, current.cards.contains(where: { $0.id == id }) else { return }
        current.cards.removeAll { $0.id == id }
        await persist(current)
    }

    func deleteDeck() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await store.delete(id: deckId)
            isDeleted = true
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func persist(_ updated: Deck) async {
        isWorking = true
        defer { isWorking = false }
        var updated = updated
        updated.updatedAt = .now
        do {
            try await store.add(updated)
            deck = updated
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }
}
