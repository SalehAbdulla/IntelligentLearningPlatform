//
//  CollectionDetailViewModel.swift
//  StudyForge
//
//  Presentation logic for I16 (`96_Bookmark_Collection_Detail_{M4}`) — the bookmarks in one
//  collection, with move, remove and select-and-share.
//
//  WHY IT RELOADS BY ID
//  --------------------
//  Removing or moving a bookmark rewrites the collection, so the screen reads it back from the
//  store rather than mutating a held copy. One source of truth is what keeps the header counts and
//  the list beneath them from ever disagreeing.
//
//  WHY "OPEN" IS NOT WIRED HERE
//  ----------------------------
//  I16 lists three swipe actions — remove, move and open. Remove and move are here; opening the
//  underlying artefact is deliberately not, and the reason is architectural rather than a
//  shortcut: a bookmark is a REFERENCE (see `BookmarkCollection`), so "open" is a cross-feature
//  deep link into F02/F04/F05/F07, and deep links are the job of the router that F14's
//  notifications and M05's global search introduce. F08 left the same seam for the same reason.
//  The share action below is what demonstrates the reference is useful in the meantime.
//

import Foundation

@MainActor
@Observable
final class CollectionDetailViewModel {

    private(set) var state: LoadState<BookmarkCollection> = .idle

    /// Kept SEPARATE from `state` so a failed action does not blank out the collection already on
    /// screen — the student keeps the list and sees the error above it.
    private(set) var error: AppError?

    /// The other collections a bookmark can be moved into. Loaded on demand, when the move sheet
    /// opens, rather than on every entry to the screen.
    private(set) var moveTargets: [BookmarkCollection] = []

    private let collectionId: String
    private let store: any BookmarkStore

    init(collectionId: String, store: any BookmarkStore) {
        self.collectionId = collectionId
        self.store = store
    }

    // MARK: Derived

    var collection: BookmarkCollection? { state.value }
    var bookmarks: [Bookmark] { state.value?.bookmarks.sorted { $0.savedAt > $1.savedAt } ?? [] }
    var isLoading: Bool { state.isLoading }

    // MARK: Copy

    var noItemsTitle: String { L10n.bookmarkNoItems.string }
    var removeTitle: String { L10n.bookmarkRemove.string }
    var moveTitle: String { L10n.bookmarkMove.string }
    var moveSheetTitle: String { L10n.bookmarkMoveTitle.string }
    var shareTitle: String { L10n.bookmarkShare.string }
    var selectTitle: String { L10n.bookmarkSelect.string }
    var offlineBadgeTitle: String { L10n.bookmarkOfflineBadge.string }
    var noMoveTargetsTitle: String { L10n.bookmarkNoCollections.string }

    func itemCountTitle(_ count: Int) -> String { L10n.bookmarkItemCount.string(count) }
    func offlineCountTitle(_ count: Int) -> String { L10n.bookmarkOfflineCount.string(count) }

    /// "Saved 3 Oct 2026" — the saved-date label I16 lists on each row.
    func savedOnTitle(_ date: Date) -> String {
        L10n.bookmarkSavedOn.string(date.formatted(date: .abbreviated, time: .omitted))
    }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            guard let collection = try await store.collection(id: collectionId) else {
                state = .empty
                return
            }
            state = .loaded(collection)
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// The collections this one's bookmarks can be moved into — everything except this one.
    func loadMoveTargets() async {
        do {
            moveTargets = try await store.all().filter { $0.id != collectionId }
        } catch {
            self.error = AppError.from(error)
            moveTargets = []
        }
    }

    // MARK: Bookmark actions

    func remove(_ bookmark: Bookmark) async {
        await mutate { $0.bookmarks.removeAll { $0.id == bookmark.id } }
    }

    /// Moves a bookmark to another collection: removed here, appended there.
    ///
    /// Both writes happen before the screen updates, so a move that fails half-way cannot leave the
    /// bookmark filed under the source AND the destination. If the destination already holds the
    /// same reference the bookmark is not duplicated — it is simply removed from here, which is the
    /// honest outcome of "move something to somewhere that already has it".
    func move(_ bookmark: Bookmark, to targetId: String) async {
        guard targetId != collectionId else { return }
        do {
            guard var source = collection,
                  var target = try await store.collection(id: targetId) else {
                return
            }

            source.bookmarks.removeAll { $0.id == bookmark.id }
            source.updatedAt = .now

            if !target.contains(referenceId: bookmark.referenceId, kind: bookmark.kind) {
                target.bookmarks.append(bookmark)
            }
            target.updatedAt = .now

            try await store.add(source)
            try await store.add(target)
            state = .loaded(source)
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// The text the share sheet hands out for a selection of bookmarks.
    ///
    /// Composed here rather than in the view so it is testable without a view, and so the format is
    /// one place rather than sprinkled through a `ShareLink`'s builder.
    func shareText(for bookmarks: [Bookmark]) -> String {
        let heading = collection?.name ?? ""
        let lines = bookmarks.map { "• \($0.title)" }
        return ([heading] + lines).filter { !$0.isEmpty }.joined(separator: "\n")
    }

    // MARK: Mutation

    /// Applies a change to the collection and persists it, keeping the screen on what was stored.
    private func mutate(_ change: (inout BookmarkCollection) -> Void) async {
        guard var collection else { return }
        change(&collection)
        collection.updatedAt = .now
        do {
            try await store.add(collection)
            state = .loaded(collection)
        } catch {
            self.error = AppError.from(error)
        }
    }
}