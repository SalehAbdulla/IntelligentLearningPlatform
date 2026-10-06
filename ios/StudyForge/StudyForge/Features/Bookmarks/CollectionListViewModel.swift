//
//  CollectionListViewModel.swift
//  StudyForge
//
//  Presentation logic for I15 (`95_Bookmarks_Collections_{M4}`) and I18
//  (`98_Bookmarks_EmptyState_{M4}`) — the student's bookmark collections.
//
//  WHY IT LOADS THE WHOLE COLLECTION LIST AT ONCE
//  ----------------------------------------------
//  The list is the student's own and small, and the card on I15 shows an item count and an
//  offline badge that are aggregates of the contents. Loading the collections whole is therefore
//  the cheap path AND the honest one: the badge can never disagree with what the detail screen
//  will show, because it is computed from the same array.
//

import Foundation

@MainActor
@Observable
final class CollectionListViewModel {

    // MARK: Bound state

    /// The new collection's name, bound to the create sheet's field.
    var name = ""

    private(set) var isCreating = false

    private(set) var state: LoadState<[BookmarkCollection]> = .idle

    private let store: any BookmarkStore

    init(store: any BookmarkStore) {
        self.store = store
    }

    // MARK: Derived

    var collections: [BookmarkCollection] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    // MARK: Copy

    var title: String { L10n.bookmarkTitle.string }
    var newCollectionTitle: String { L10n.bookmarkNewCollection.string }
    var emptyTitle: String { L10n.bookmarkEmptyTitle.string }
    var emptyBody: String { L10n.bookmarkEmptyBody.string }
    var offlineNote: String { L10n.bookmarkOfflineNote.string }
    var browseLibraryTitle: String { L10n.bookmarkBrowseLibrary.string }
    var nameLabel: String { L10n.bookmarkNameLabel.string }
    var namePlaceholder: String { L10n.bookmarkNamePlaceholder.string }
    var createTitle: String { L10n.bookmarkCreate.string }
    var creatingTitle: String { L10n.bookmarkCreating.string }
    var offlineBadgeTitle: String { L10n.bookmarkOfflineBadge.string }

    func itemCount(_ collection: BookmarkCollection) -> String {
        L10n.bookmarkItemCount.string(collection.bookmarks.count)
    }

    func offlineCount(_ collection: BookmarkCollection) -> String {
        L10n.bookmarkOfflineCount.string(collection.offlineCount)
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let collections = try await store.all()
            state = collections.isEmpty ? .empty : .loaded(collections)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Creates a collection from the bound name.
    ///
    /// Unlike a shared folder (F08), a collection has no members and no owner: it is the student's
    /// own private filing cabinet, so there is no one to attribute it to.
    func create() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isCreating else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            try await store.add(BookmarkCollection(name: trimmed))
            name = ""
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func delete(_ collection: BookmarkCollection) async {
        do {
            try await store.delete(id: collection.id)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}