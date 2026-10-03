//
//  BookmarkSaveViewModel.swift
//  StudyForge
//
//  Presentation logic for I17 (`97_Bookmark_Save_Sheet_{M4}`) — the sheet any screen can raise to
//  file a reference into a collection, with an inline "create new" and an "also save offline"
//  toggle.
//
//  WHY THE TARGET IS PASSED IN, NOT LOOKED UP
//  ------------------------------------------
//  The sheet is raised FROM an artefact the student is already looking at, so it is handed the
//  kind, id and title rather than re-resolving them. That keeps it usable from the library today
//  and from any other screen later without the sheet needing to know what any of them are — the
//  same decoupling that lets F08 share a reference it did not load.
//
//  WHY RE-SAVING IS NOT AN ERROR
//  -----------------------------
//  Saving something already in the chosen collection is the expected second tap, not a mistake, so
//  it is not refused with a banner. The bookmark is left in place and the offline flag is honoured,
//  which makes the toggle idempotent — tapping Save twice with "offline" on and then off does what
//  it says.
//

import Foundation

@MainActor
@Observable
final class BookmarkSaveViewModel {

    // MARK: Bound state

    private(set) var state: LoadState<[BookmarkCollection]> = .idle

    /// The collection the student picked, or `nil` before they pick one.
    var selectedCollectionId: String?

    /// The inline "create new" name. Non-empty means the picker is bypassed entirely.
    var createName = ""

    /// I17's "also save offline" toggle.
    var saveOffline: Bool

    private(set) var isSaving = false
    private(set) var error: AppError?

    /// Set once the save succeeds, so the view can dismiss itself.
    private(set) var didSave = false

    private let store: any BookmarkStore

    /// What is being saved. `let` rather than `var`: the sheet describes one artefact for its life.
    let kind: BookmarkKind
    let referenceId: String
    let itemTitle: String

    init(
        store: any BookmarkStore,
        kind: BookmarkKind,
        referenceId: String,
        itemTitle: String,
        saveOffline: Bool = false
    ) {
        self.store = store
        self.kind = kind
        self.referenceId = referenceId
        self.itemTitle = itemTitle
        self.saveOffline = saveOffline
    }

    // MARK: Derived

    var collections: [BookmarkCollection] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }

    /// Whether the student is typing a new collection name instead of picking one.
    var isCreatingNew: Bool { !createName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Save is offered once a destination exists and nothing is already in flight.
    var canSave: Bool { (selectedCollectionId != nil || isCreatingNew) && !isSaving }

    // MARK: Copy

    var sheetTitle: String { L10n.bookmarkSaveSheetTitle.string }
    var saveToTitle: String { L10n.bookmarkSaveTo.string }
    var createNewTitle: String { L10n.bookmarkCreateNew.string }
    var nameLabel: String { L10n.bookmarkNameLabel.string }
    var namePlaceholder: String { L10n.bookmarkNamePlaceholder.string }
    var offlineTitle: String { L10n.bookmarkSaveOffline.string }
    var offlineHint: String { L10n.bookmarkSaveOfflineHint.string }
    var saveTitle: String { L10n.bookmarkSave.string }
    var savingTitle: String { L10n.bookmarkSaving.string }
    var noCollectionsTitle: String { L10n.bookmarkNoCollections.string }
    var existsTitle: String { L10n.bookmarkExists.string }

    func itemCount(_ collection: BookmarkCollection) -> String {
        L10n.bookmarkItemCount.string(collection.bookmarks.count)
    }

    /// Whether this collection already holds the reference being saved — the checkmark I17 shows.
    func alreadySaved(in collection: BookmarkCollection) -> Bool {
        collection.contains(referenceId: referenceId, kind: kind)
    }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            let collections = try await store.all()
            state = collections.isEmpty ? .empty : .loaded(collections)
            // Pre-select the most recent collection so a one-tap Save works when one already exists.
            if selectedCollectionId == nil { selectedCollectionId = collections.first?.id }
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: Saving

    func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            var target: BookmarkCollection
            let name = createName.trimmingCharacters(in: .whitespacesAndNewlines)

            if !name.isEmpty {
                target = BookmarkCollection(name: name)
            } else if let id = selectedCollectionId,
                      let existing = try await store.collection(id: id) {
                target = existing
            } else {
                return
            }

            if let index = target.bookmarks.firstIndex(where: {
                $0.referenceId == referenceId && $0.kind == kind
            }) {
                // Already filed here: honour the toggle rather than adding a second copy.
                target.bookmarks[index].savedOffline = saveOffline
            } else {
                target.bookmarks.append(
                    Bookmark(
                        kind: kind,
                        referenceId: referenceId,
                        title: itemTitle,
                        savedOffline: saveOffline
                    )
                )
            }
            target.updatedAt = .now

            try await store.add(target)
            didSave = true
        } catch {
            self.error = AppError.from(error)
        }
    }
}