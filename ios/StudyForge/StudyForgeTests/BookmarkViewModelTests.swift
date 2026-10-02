//
//  BookmarkViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the bookmark collection list, detail and save flows.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Collection list (F10)")
@MainActor
struct CollectionListViewModelTests {

    @Test("An empty store shows the empty state")
    func emptyStore() async {
        let viewModel = CollectionListViewModel(store: InMemoryBookmarkStore())
        await viewModel.load()
        #expect(viewModel.isEmpty)
    }

    @Test("Creating a collection trims the name and clears the field")
    func createTrims() async throws {
        let store = InMemoryBookmarkStore()
        let viewModel = CollectionListViewModel(store: store)
        viewModel.name = "  Exam revision  "

        await viewModel.create()

        #expect(try await store.all().first?.name == "Exam revision")
        #expect(viewModel.name.isEmpty, "the field is cleared after creating")
    }

    @Test("A blank name creates nothing")
    func blankNameIsRefused() async throws {
        let store = InMemoryBookmarkStore()
        let viewModel = CollectionListViewModel(store: store)
        viewModel.name = "   "

        await viewModel.create()

        #expect(try await store.all().isEmpty)
    }

    @Test("The counts and copy come from the catalogue")
    func copyIsLocalised() {
        let viewModel = CollectionListViewModel(store: InMemoryBookmarkStore())
        let collection = BookmarkCollection(
            name: "Exam revision",
            bookmarks: [Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4", savedOffline: true)]
        )

        #expect(viewModel.title == L10n.bookmarkTitle.string)
        #expect(viewModel.emptyTitle == L10n.bookmarkEmptyTitle.string)
        #expect(viewModel.offlineBadgeTitle == L10n.bookmarkOfflineBadge.string)
        #expect(viewModel.itemCount(collection) == L10n.bookmarkItemCount.string(1))
        #expect(viewModel.offlineCount(collection) == L10n.bookmarkOfflineCount.string(1))
    }
}

@Suite("Collection detail (F10)")
@MainActor
struct CollectionDetailViewModelTests {

    private func collection(
        id: String = "c1",
        name: String = "Exam revision",
        bookmarks: [Bookmark] = []
    ) -> BookmarkCollection {
        BookmarkCollection(id: id, name: name, bookmarks: bookmarks)
    }

    private func model(
        _ collections: [BookmarkCollection],
        id: String = "c1"
    ) async -> (CollectionDetailViewModel, InMemoryBookmarkStore) {
        let store = InMemoryBookmarkStore(seededWith: collections)
        let viewModel = CollectionDetailViewModel(collectionId: id, store: store)
        await viewModel.load()
        return (viewModel, store)
    }

    @Test("Removing a bookmark persists the removal")
    func removePersists() async throws {
        let bookmark = Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4")
        let (viewModel, store) = await model([collection(bookmarks: [bookmark])])

        await viewModel.remove(bookmark)

        #expect(viewModel.bookmarks.isEmpty)
        #expect(try await store.collection(id: "c1")?.bookmarks.isEmpty == true)
    }

    @Test("Moving a bookmark files it under the target and out of the source")
    func moveBetweenCollections() async throws {
        let bookmark = Bookmark(kind: .deck, referenceId: "d1", title: "Normalisation cards")
        let (viewModel, store) = await model([
            collection(id: "c1", bookmarks: [bookmark]),
            collection(id: "c2", name: "Reading list"),
        ])

        await viewModel.loadMoveTargets()
        #expect(viewModel.moveTargets.map(\.id) == ["c2"], "the source is not a move target")

        await viewModel.move(bookmark, to: "c2")

        #expect(viewModel.bookmarks.isEmpty)
        #expect(try await store.collection(id: "c2")?.bookmarks.map(\.id) == [bookmark.id])
    }

    @Test("Moving into a collection that already holds the reference does not duplicate it")
    func moveDeduplicates() async throws {
        let bookmark = Bookmark(kind: .deck, referenceId: "d1", title: "Normalisation cards")
        let (viewModel, store) = await model([
            collection(id: "c1", bookmarks: [bookmark]),
            collection(id: "c2", name: "Reading list", bookmarks: [bookmark]),
        ])

        await viewModel.move(bookmark, to: "c2")

        #expect(try await store.collection(id: "c2")?.bookmarks.count == 1)
    }

    @Test("The share text heads with the collection name and lists the bookmarks")
    func shareText() async {
        let bookmark = Bookmark(kind: .quiz, referenceId: "q1", title: "Databases quiz")
        let (viewModel, _) = await model([collection(bookmarks: [bookmark])])

        let text = viewModel.shareText(for: [bookmark])

        #expect(text.contains("Exam revision"))
        #expect(text.contains("Databases quiz"))
    }

    @Test("A missing collection shows the empty state rather than an error")
    func missingIsEmpty() async {
        let viewModel = CollectionDetailViewModel(collectionId: "nope", store: InMemoryBookmarkStore())

        await viewModel.load()

        #expect(viewModel.collection == nil)
        #expect(viewModel.error == nil)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _) = await model([collection()])

        #expect(viewModel.noItemsTitle == L10n.bookmarkNoItems.string)
        #expect(viewModel.moveSheetTitle == L10n.bookmarkMoveTitle.string)
        #expect(viewModel.removeTitle == L10n.bookmarkRemove.string)
        #expect(viewModel.itemCountTitle(0) == L10n.bookmarkItemCount.string(0))
    }
}

@Suite("Bookmark save sheet (F10)")
@MainActor
struct BookmarkSaveViewModelTests {

    @Test("Loading pre-selects the most recent collection so one tap saves")
    func preselectsCollection() async {
        let store = InMemoryBookmarkStore(seededWith: [BookmarkCollection(id: "c1", name: "Exam revision")])
        let viewModel = BookmarkSaveViewModel(store: store, kind: .material, referenceId: "m1", itemTitle: "Lecture 4")

        await viewModel.load()

        #expect(viewModel.selectedCollectionId == "c1")
        #expect(viewModel.canSave)
    }

    @Test("Saving files the reference with the offline flag")
    func saveStoresBookmark() async throws {
        let store = InMemoryBookmarkStore(seededWith: [BookmarkCollection(id: "c1", name: "Exam revision")])
        let viewModel = BookmarkSaveViewModel(
            store: store, kind: .material, referenceId: "m1", itemTitle: "Lecture 4", saveOffline: true
        )

        await viewModel.load()
        await viewModel.save()

        let saved = try await store.collection(id: "c1")?.bookmarks.first
        #expect(viewModel.didSave)
        #expect(saved?.referenceId == "m1")
        #expect(saved?.savedOffline == true)
    }

    @Test("An inline new name creates the collection and files into it")
    func createNewInline() async throws {
        let store = InMemoryBookmarkStore()
        let viewModel = BookmarkSaveViewModel(store: store, kind: .deck, referenceId: "d1", itemTitle: "Cards")

        await viewModel.load()
        viewModel.createName = "  Backlog  "
        #expect(viewModel.isCreatingNew, "typing a name bypasses the picker")
        #expect(viewModel.canSave)

        await viewModel.save()

        let created = try await store.all().first
        #expect(created?.name == "Backlog", "the name is trimmed")
        #expect(created?.bookmarks.first?.referenceId == "d1")
    }

    @Test("Re-saving toggles the offline flag instead of duplicating")
    func resaveDoesNotDuplicate() async throws {
        let store = InMemoryBookmarkStore(seededWith: [BookmarkCollection(id: "c1", name: "Exam revision")])
        let viewModel = BookmarkSaveViewModel(store: store, kind: .material, referenceId: "m1", itemTitle: "Lecture 4")

        await viewModel.load()
        await viewModel.save()
        viewModel.saveOffline = true
        await viewModel.save()

        let bookmarks = try await store.collection(id: "c1")?.bookmarks ?? []
        #expect(bookmarks.count == 1, "the second save updates rather than duplicating")
        #expect(bookmarks.first?.savedOffline == true)
    }

    @Test("Nothing is saved until a destination exists")
    func cannotSaveWithoutDestination() async {
        let viewModel = BookmarkSaveViewModel(
            store: InMemoryBookmarkStore(), kind: .material, referenceId: "m1", itemTitle: "Lecture 4"
        )

        await viewModel.load()
        #expect(viewModel.canSave == false)

        await viewModel.save()
        #expect(viewModel.didSave == false)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let viewModel = BookmarkSaveViewModel(
            store: InMemoryBookmarkStore(), kind: .material, referenceId: "m1", itemTitle: "Lecture 4"
        )

        #expect(viewModel.sheetTitle == L10n.bookmarkSaveSheetTitle.string)
        #expect(viewModel.saveTitle == L10n.bookmarkSave.string)
        #expect(viewModel.offlineHint == L10n.bookmarkSaveOfflineHint.string)
        #expect(viewModel.noCollectionsTitle == L10n.bookmarkNoCollections.string)
    }
}