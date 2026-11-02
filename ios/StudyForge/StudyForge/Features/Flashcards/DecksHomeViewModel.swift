import Foundation

@MainActor
@Observable
final class DecksHomeViewModel {

    private(set) var decks: [Deck] = []
    private(set) var hasLoaded = false
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let store: any DeckStore

    init(store: any DeckStore) {
        self.store = store
    }

    var isEmpty: Bool { hasLoaded && decks.isEmpty && error == nil }

    func totalDue(now: Date = .now) -> Int {
        decks.reduce(0) { $0 + $1.dueCount(now: now) }
    }

    func mostDueDeck(now: Date = .now) -> Deck? {
        decks
            .filter { $0.dueCount(now: now) > 0 }
            .max { $0.dueCount(now: now) < $1.dueCount(now: now) }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            decks = try await store.all()
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func delete(_ deck: Deck) async {
        do {
            try await store.delete(id: deck.id)
            decks.removeAll { $0.id == deck.id }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }
}
