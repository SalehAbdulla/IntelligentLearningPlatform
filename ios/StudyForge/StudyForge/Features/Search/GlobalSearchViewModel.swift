//
//  GlobalSearchViewModel.swift
//  StudyForge
//
//  Presentation logic for M05 (`132_Global_Search_{M1}`, docs/03 §M, P0) — one search across
//  materials, summaries, decks, quizzes, folders and bookmarks.
//
//  WHY THE CORPUS IS LOADED ONCE AND FILTERED IN MEMORY
//  ----------------------------------------------------
//  Everything search reaches is already on the device (D24 and the local-first stores), and it is the
//  student's own work rather than a catalogue — so it is small, it is in hand, and a predicate over an
//  in-memory array is honest at this size. It also makes typing instant: filtering does not await six
//  stores on every keystroke, which is the difference between a search field that feels alive and one
//  that feels broken. When the corpus can be paged the filtering moves behind a store seam, which is
//  exactly what the seams are for.
//
//  WHY THE QUERY IS MATCHED, NOT RANKED
//  ------------------------------------
//  There is no relevance score here on purpose. Ranking across six different kinds of thing would
//  need weights nobody can justify ("is a deck title more relevant than a summary's key point?"), and
//  a wrong order is worse than an obvious one. The results are grouped by kind instead, which is a
//  statement the student can actually see.
//

import Foundation

@MainActor
@Observable
final class GlobalSearchViewModel {

    // MARK: Bound state

    /// What the student is looking for.
    var query = ""

    /// Which kind to show, or `nil` for all of them — M05's scope chips.
    var scope: SearchResultKind?

    // MARK: Derived state

    private(set) var corpus: [SearchResult] = []
    private(set) var isLoading = false
    private(set) var error: AppError?
    private(set) var recent: [String] = []

    private let materials: any MaterialStore
    private let summaries: any SummaryStore
    private let decks: any DeckStore
    private let quizzes: any QuizStore
    private let folders: any FolderStore
    private let bookmarks: any BookmarkStore
    private let recents: any RecentSearchStore

    init(
        materials: any MaterialStore,
        summaries: any SummaryStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        folders: any FolderStore,
        bookmarks: any BookmarkStore,
        recents: any RecentSearchStore
    ) {
        self.materials = materials
        self.summaries = summaries
        self.decks = decks
        self.quizzes = quizzes
        self.folders = folders
        self.bookmarks = bookmarks
        self.recents = recents
    }

    // MARK: Derived

    var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Whether there is anything to search for yet.
    var isSearching: Bool { !trimmedQuery.isEmpty }

    /// The hits for the current query and scope.
    var results: [SearchResult] {
        guard isSearching else { return [] }
        return corpus.filter { (scope == nil || $0.kind == scope) && $0.matches(trimmedQuery) }
    }

    var hasResults: Bool { !results.isEmpty }

    /// The query ran and found nothing — M05's designed empty state.
    var isEmptyResult: Bool { isSearching && !hasResults }

    var hasRecent: Bool { !recent.isEmpty }

    /// How many hits a kind would contribute, for the scope chips' counts.
    func matchCount(for kind: SearchResultKind) -> Int {
        guard isSearching else { return 0 }
        return corpus.filter { $0.kind == kind && $0.matches(trimmedQuery) }.count
    }

    // MARK: Copy

    var title: String { L10n.searchTitle.string }
    var prompt: String { L10n.searchPrompt.string }
    var emptyTitle: String { L10n.searchEmptyTitle.string }
    var emptyBody: String { L10n.searchEmptyBody.string }
    var recentHeading: String { L10n.searchRecentHeading.string }
    var clearRecentTitle: String { L10n.searchClearRecent.string }
    var allScopeTitle: String { L10n.searchScopeAll.string }

    func resultCountTitle(_ count: Int) -> String { L10n.searchResultCount.string(count) }

    // MARK: Actions

    /// Loads the corpus and the recent queries. The corpus is read once per entry to the screen.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        recent = recents.recent

        do {
            corpus = try await buildCorpus()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Remembers the current query. Called when a search is committed, so typing does not fill the
    /// recent list one prefix at a time.
    func commitSearch() {
        guard isSearching else { return }
        recents.record(trimmedQuery)
        recent = recents.recent
    }

    /// Runs a remembered query again.
    func use(_ remembered: String) {
        query = remembered
        scope = nil
    }

    func clearRecent() {
        recents.clear()
        recent = []
    }

    // MARK: Corpus

    /// Projects every store's contents into one flat list of hits.
    private func buildCorpus() async throws -> [SearchResult] {
        var results: [SearchResult] = []

        for material in try await materials.all() {
            results.append(SearchResult(
                kind: .material,
                referenceId: material.id,
                title: material.title,
                subtitle: material.source.title,
                // A material matches its tags and its extracted text, which is what "searchable"
                // means for a document — the same rule the library's own field uses.
                haystack: ([material.title, material.source.title] + material.tags + [material.text])
                    .joined(separator: " ")
            ))
        }

        for summary in try await summaries.all() {
            results.append(SearchResult(
                kind: .summary,
                referenceId: summary.id,
                title: summary.title,
                subtitle: summary.tldr,
                haystack: ([summary.title, summary.tldr] + summary.keyPoints).joined(separator: " ")
            ))
        }

        for deck in try await decks.all() {
            let cardText = deck.cards.flatMap { [$0.front, $0.back] }
            results.append(SearchResult(
                kind: .deck,
                referenceId: deck.id,
                title: deck.title,
                subtitle: L10n.searchDeckCount.string(deck.cards.count),
                haystack: ([deck.title] + cardText).joined(separator: " ")
            ))
        }

        for quiz in try await quizzes.all() {
            results.append(SearchResult(
                kind: .quiz,
                referenceId: quiz.id,
                title: quiz.title,
                subtitle: L10n.searchQuizCount.string(quiz.questions.count),
                // A quiz matches its questions AND the topics they cover, so searching a topic finds
                // the quiz that tested it.
                haystack: ([quiz.title]
                           + quiz.questions.map(\.stem)
                           + quiz.questions.map(\.topic)).joined(separator: " ")
            ))
        }

        for folder in try await folders.all() {
            results.append(SearchResult(
                kind: .folder,
                referenceId: folder.id,
                title: folder.name,
                subtitle: L10n.folderItemCount.string(folder.items.count),
                haystack: ([folder.name] + folder.items.map(\.title)).joined(separator: " ")
            ))
        }

        for collection in try await bookmarks.all() {
            results.append(SearchResult(
                kind: .bookmark,
                referenceId: collection.id,
                title: collection.name,
                subtitle: L10n.bookmarkItemCount.string(collection.bookmarks.count),
                haystack: ([collection.name] + collection.bookmarks.map(\.title)).joined(separator: " ")
            ))
        }

        return results
    }
}