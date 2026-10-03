//
//  GlobalSearchTests.swift
//  StudyForgeTests
//
//  Tests for M05's global search and its recent-searches store.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Recent searches

@Suite("Recent searches (M05)")
struct RecentSearchStoreTests {

    @Test("A query is remembered, most recent first")
    func recordsNewestFirst() {
        let store = InMemoryRecentSearchStore()
        store.record("normalisation")
        store.record("hashing")
        #expect(store.recent == ["hashing", "normalisation"])
    }

    @Test("A repeat moves to the front rather than appearing twice")
    func repeatsMoveToFront() {
        let store = InMemoryRecentSearchStore()
        store.record("normalisation")
        store.record("hashing")
        store.record("normalisation")
        #expect(store.recent == ["normalisation", "hashing"])
    }

    @Test("A repeat is matched ignoring case and surrounding space")
    func repeatsIgnoreCaseAndSpace() {
        let store = InMemoryRecentSearchStore()
        store.record("Hashing")
        store.record("  hashing  ")
        #expect(store.recent == ["hashing"], "the newer spelling wins and the old one is dropped")
    }

    @Test("A blank query is not remembered")
    func blankIsIgnored() {
        let store = InMemoryRecentSearchStore()
        store.record("   ")
        store.record("")
        #expect(store.recent.isEmpty)
    }

    @Test("The list is capped, dropping the oldest")
    func capped() {
        let store = InMemoryRecentSearchStore()
        for index in 0..<(RecentSearchLimit.cap + 4) {
            store.record("query \(index)")
        }
        #expect(store.recent.count == RecentSearchLimit.cap)
        #expect(store.recent.first == "query \(RecentSearchLimit.cap + 3)")
    }

    @Test("Clearing empties the list")
    func clearing() {
        let store = InMemoryRecentSearchStore(recent: ["a", "b"])
        store.clear()
        #expect(store.recent.isEmpty)
    }

    @Test("The UserDefaults store keeps the same rule")
    func userDefaultsStore() throws {
        let defaults = try #require(UserDefaults(suiteName: "search-tests-\(UUID().uuidString)"))
        let store = UserDefaultsRecentSearchStore(defaults: defaults)

        store.record("normalisation")
        store.record("Hashing")
        store.record("normalisation")

        #expect(store.recent == ["normalisation", "Hashing"])
        store.clear()
        #expect(store.recent.isEmpty)
    }
}

// MARK: - Search

@Suite("Global search (M05)")
@MainActor
struct GlobalSearchViewModelTests {

    private let provenance = AIProvenance(materialId: "m1", pageNumbers: [1], confidence: .high)

    private func material() -> Material {
        Material(
            id: "m1",
            title: "Lecture 4",
            source: .text,
            text: "Normalisation removes redundancy by decomposing relations.",
            tags: ["databases"]
        )
    }

    private func summary() -> Summary {
        Summary(
            id: "s1",
            title: "Normalisation summary",
            length: .standard,
            style: .bullets,
            language: .english,
            tldr: "Normalisation reduces redundancy.",
            keyPoints: ["First normal form needs atomic values"],
            glossary: [],
            provenance: provenance,
            tier: .firebaseAI
        )
    }

    private func deck() -> Deck {
        Deck(
            id: "d1",
            title: "Hash tables",
            cards: [Flashcard(front: "What is a load factor?", back: "Entries over buckets.", provenance: provenance)]
        )
    }

    private func quiz() -> Quiz {
        Quiz(
            id: "q1",
            title: "Databases quiz",
            questionType: .multipleChoice,
            questions: [
                QuizQuestion(
                    stem: "What is 3NF?",
                    options: ["No transitive dependencies", "b", "c", "d"],
                    correctOptionIndex: 0,
                    explanation: "Because.",
                    topic: "normalisation",
                    provenance: provenance
                ),
            ]
        )
    }

    private func model() -> (GlobalSearchViewModel, InMemoryRecentSearchStore) {
        let recents = InMemoryRecentSearchStore()
        let viewModel = GlobalSearchViewModel(
            materials: InMemoryMaterialStore(seededWith: [material()]),
            summaries: InMemorySummaryStore(seededWith: [summary()]),
            decks: InMemoryDeckStore(seededWith: [deck()]),
            quizzes: InMemoryQuizStore(seededWith: [quiz()]),
            folders: InMemoryFolderStore(seededWith: [
                SharedFolder(id: "f1", name: "Revision folder", items: [
                    FolderItem(kind: .material, referenceId: "m1", title: "Lecture 4"),
                ]),
            ]),
            bookmarks: InMemoryBookmarkStore(seededWith: [
                BookmarkCollection(id: "c1", name: "Exam list", bookmarks: [
                    Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4"),
                ]),
            ]),
            recents: recents
        )
        return (viewModel, recents)
    }

    @Test("Loading reads every store into one corpus")
    func loadBuildsCorpus() async {
        let (viewModel, _) = model()
        await viewModel.load()
        #expect(viewModel.corpus.count == 6, "one hit per store")
        #expect(viewModel.corpus.allSatisfy { $0.haystack == $0.haystack.lowercased() })
    }

    @Test("An empty query returns nothing rather than everything")
    func emptyQueryIsSilent() async {
        let (viewModel, _) = model()
        await viewModel.load()

        viewModel.query = "   "
        #expect(viewModel.isSearching == false)
        #expect(viewModel.results.isEmpty)
        #expect(viewModel.isEmptyResult == false, "an untouched field is not a failed search")
    }

    @Test("A match is found in a title, a tag, a card and a question")
    func matchesAcrossKinds() async {
        let (viewModel, _) = model()
        await viewModel.load()

        viewModel.query = "normalisation"
        let kinds = Set(viewModel.results.map(\.kind))
        #expect(kinds.contains(.material), "the word is in the extracted text")
        #expect(kinds.contains(.summary), "the word is in the title")
        #expect(kinds.contains(.quiz), "the word is in a question stem and a topic")

        viewModel.query = "databases"
        #expect(viewModel.results.contains { $0.kind == .material }, "a tag matches")
        #expect(viewModel.results.contains { $0.kind == .quiz }, "the quiz title matches")

        viewModel.query = "load factor"
        #expect(viewModel.results.map(\.kind) == [.deck], "a card's text matches its deck")

        viewModel.query = "revision"
        #expect(viewModel.results.map(\.kind) == [.folder])

        viewModel.query = "exam"
        #expect(viewModel.results.map(\.kind) == [.bookmark])
    }

    @Test("Matching ignores case and surrounding space")
    func matchingIsForgiving() async {
        let (viewModel, _) = model()
        await viewModel.load()

        viewModel.query = "  NORMALISATION  "
        #expect(viewModel.results.isEmpty == false)
    }

    @Test("The scope narrows the results without changing the query")
    func scopeNarrows() async {
        let (viewModel, _) = model()
        await viewModel.load()
        viewModel.query = "normalisation"

        let all = viewModel.results.count
        viewModel.scope = .quiz

        #expect(viewModel.results.allSatisfy { $0.kind == .quiz })
        #expect(viewModel.results.count < all)
        #expect(viewModel.query == "normalisation", "the scope does not rewrite the field")
    }

    @Test("A query that matches nothing is an empty result, not an untouched field")
    func emptyResult() async {
        let (viewModel, _) = model()
        await viewModel.load()

        viewModel.query = "zzzzz"

        #expect(viewModel.hasResults == false)
        #expect(viewModel.isEmptyResult)
    }

    @Test("The per-kind counts follow the query")
    func matchCounts() async {
        let (viewModel, _) = model()
        await viewModel.load()

        viewModel.query = "normalisation"
        #expect(viewModel.matchCount(for: .material) == 1)
        #expect(viewModel.matchCount(for: .folder) == 0)

        viewModel.query = ""
        #expect(viewModel.matchCount(for: .material) == 0, "no query, no counts")
    }

    @Test("Committing a search remembers it; using one reruns it; clearing empties the list")
    func recentSearches() async {
        let (viewModel, recents) = model()
        await viewModel.load()

        viewModel.query = "normalisation"
        viewModel.commitSearch()
        #expect(recents.recent == ["normalisation"])
        #expect(viewModel.hasRecent)

        viewModel.query = ""
        viewModel.use("normalisation")
        #expect(viewModel.query == "normalisation")
        #expect(viewModel.scope == nil, "running a remembered query clears the scope")

        viewModel.clearRecent()
        #expect(viewModel.hasRecent == false)
        #expect(recents.recent.isEmpty)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _) = model()
        await viewModel.load()

        #expect(viewModel.title == L10n.searchTitle.string)
        #expect(viewModel.emptyTitle == L10n.searchEmptyTitle.string)
        #expect(viewModel.allScopeTitle == L10n.searchScopeAll.string)
        #expect(viewModel.resultCountTitle(3) == L10n.searchResultCount.string(3))
        #expect(SearchResultKind.deck.title == L10n.searchKindDeck.string)
    }
}