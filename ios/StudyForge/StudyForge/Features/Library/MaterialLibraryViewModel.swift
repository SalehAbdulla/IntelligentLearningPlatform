//
//  MaterialLibraryViewModel.swift
//  StudyForge
//
//  Presentation logic for C08 (`31_Library_Materials_List_{M1}`, docs/03 §C, P0) — the student's
//  own materials, read from the local store.
//
//  WHY THE LIST IS A `LoadState` AND NOT AN ARRAY
//  ---------------------------------------------
//  Loading, empty and failed are states a screen has to design (docs/04 §8), and an array can
//  only express one of them. Reaching for `LoadState` also keeps this screen shaped like every
//  other data-driven screen in the app, so the loading and failure affordances come for free
//  rather than being improvised here.
//
//  WHY SEARCH FILTERS IN MEMORY
//  ---------------------------
//  The library is local and small — it is the student's own imports — so it is already in hand
//  when the search field is typed into. A predicate over an in-memory array is honest at this
//  size; when the library can be paged (a remote or indexed store), the filtering moves behind
//  `MaterialStore`, which is what the protocol boundary is for.
//

import Foundation

@MainActor
@Observable
final class MaterialLibraryViewModel {

    /// The library, as a lifecycle.
    private(set) var state: LoadState<[Material]> = .idle

    /// What the student typed into the search field.
    var query = ""

    private let store: any MaterialStore

    init(store: any MaterialStore) {
        self.store = store
    }

    // MARK: Derived

    /// What to draw: everything, or whatever matched the query.
    var visibleMaterials: [Material] {
        guard let all = state.value else { return [] }

        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return all }

        // Title, tags AND the extracted text — the three things a student would look for by.
        // Matching the text is what makes the library "searchable" in the sense the brief means:
        // the words INSIDE the document, not merely its name.
        return all.filter { material in
            material.title.lowercased().contains(needle)
                || material.tags.contains { $0.lowercased().contains(needle) }
                || material.text.lowercased().contains(needle)
        }
    }

    /// True when there ARE materials but none matched.
    ///
    /// Distinct from an empty library on purpose: telling a student who mistyped that they have
    /// no materials would read as though their library had been wiped.
    var hasNoMatches: Bool {
        guard let all = state.value else { return false }
        return !all.isEmpty && visibleMaterials.isEmpty
    }

    var isEmpty: Bool {
        if case .empty = state { return true }
        return false
    }

    var isLoading: Bool { state.isLoading }

    var error: AppError? {
        if case .failed(let error) = state { return error }
        return nil
    }

    // MARK: Copy

    var title: String { L10n.libraryTitle.string }
    var searchPrompt: String { L10n.librarySearchPlaceholder.string }
    var emptyTitle: String { L10n.libraryEmptyTitle.string }
    var emptyBody: String { L10n.libraryEmptyBody.string }
    var noMatchesTitle: String { L10n.libraryNoMatchesTitle.string }
    var noMatchesBody: String { L10n.libraryNoMatchesBody.string }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let materials = try await store.all()
            state = materials.isEmpty ? .empty : .loaded(materials)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func delete(_ material: Material) async {
        do {
            try await store.delete(id: material.id)
            // Reloaded rather than removed locally, so the empty state appears when the last
            // material goes — the one transition a local mutation would get wrong.
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
