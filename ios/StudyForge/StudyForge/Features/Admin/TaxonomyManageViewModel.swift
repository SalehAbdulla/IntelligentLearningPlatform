//
//  TaxonomyManageViewModel.swift
//  StudyForge
//
//  Presentation logic for K06 (`114_Admin_Taxonomy_Manage_{M4}`, docs/03 section K): the platform's
//  subjects and tags, curated.
//
//  WHY MERGE ADDS THE COUNTS
//  -------------------------
//  Merging "Bio" into "Biology" is not deleting "Bio": the content filed under "Bio" now belongs to
//  "Biology". Adding the usage counts is what keeps the survivor's count honest after the merge, which
//  is the only reason the count is worth showing.
//
//  WHY REORDER IS SEPARATE FROM EDIT
//  ---------------------------------
//  Reordering changes many rows at once, so it writes each row's new `sortIndex` and reloads, rather
//  than pretending a single term changed. The view computes the new order with SwiftUI's list move and
//  hands it here, which keeps this file free of UI imports.
//

import Foundation

@MainActor
@Observable
final class TaxonomyManageViewModel {

    // MARK: Bound state

    /// Which vocabulary is on screen. Subjects and tags are curated one at a time in K06.
    var kind: TaxonomyKind = .subject

    /// The add field.
    var newName = ""

    /// Validation message for the add field, or for a rename in flight.
    private(set) var formError: String?

    // MARK: Derived state

    private(set) var state: LoadState<[TaxonomyTerm]> = .idle
    private(set) var error: AppError?

    private let store: any TaxonomyStore
    private let audit: any AIConfigurationStore

    /// The signed-in admin's name, so the trail is attributable.
    let actorName: String

    init(store: any TaxonomyStore, audit: any AIConfigurationStore, actorName: String) {
        self.store = store
        self.audit = audit
        self.actorName = actorName
    }

    // MARK: Derived

    var terms: [TaxonomyTerm] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }

    /// The terms of the selected kind, in display order.
    var visibleTerms: [TaxonomyTerm] { terms.filter { $0.kind == kind } }

    /// Whether the selected vocabulary has no terms at all.
    var isKindEmpty: Bool { visibleTerms.isEmpty }

    /// The other terms of the same kind, so the merge sheet can offer targets.
    func mergeTargets(for term: TaxonomyTerm) -> [TaxonomyTerm] {
        visibleTerms.filter { $0.id != term.id }
    }

    // MARK: Copy

    var title: String { L10n.adminTaxonomyTitle.string }
    var addPlaceholder: String { L10n.adminTaxonomyAddPlaceholder.string }
    var addButton: String { L10n.adminTaxonomyAdd.string }
    var editButton: String { L10n.adminTaxonomyEdit.string }
    var renameTitle: String { L10n.adminTaxonomyRename.string }
    var deleteTitle: String { L10n.adminTaxonomyDelete.string }
    var mergeTitle: String { L10n.adminTaxonomyMerge.string }
    var mergeSheetTitle: String { L10n.adminTaxonomyMergeTitle.string }
    var emptyTitle: String { L10n.adminTaxonomyEmptyTitle.string }
    var emptyBody: String { L10n.adminTaxonomyEmptyBody.string }

    func kindTitle(_ kind: TaxonomyKind) -> String { kind.title }

    /// "42 uses", or "Unused" when the term is not attached to any content.
    func usageTitle(_ term: TaxonomyTerm) -> String {
        term.isUnused
            ? L10n.adminTaxonomyUnused.string
            : L10n.adminTaxonomyUsage.string(term.usageCount)
    }

    func mergeBody(source: TaxonomyTerm) -> String {
        L10n.adminTaxonomyMergeBody.string(source.name)
    }

    /// The rename title, naming the term.
    func renameTitle(for term: TaxonomyTerm) -> String {
        L10n.adminTaxonomyRenameTitle.string(term.name)
    }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            let terms = try await store.terms()
            state = terms.isEmpty ? .empty : .loaded(terms)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: Editing

    /// Adds the term named in `newName` to the selected kind. Refuses an empty or duplicate name.
    @discardableResult
    func add() async -> Bool {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            formError = L10n.adminTaxonomyNameRequired.string
            return false
        }
        guard !isDuplicate(name, in: kind, excluding: nil) else {
            formError = L10n.adminTaxonomyDuplicate.string
            return false
        }

        let nextIndex = (visibleTerms.map(\.sortIndex).max() ?? -1) + 1
        let term = TaxonomyTerm(name: name, kind: kind, usageCount: 0, sortIndex: nextIndex)

        guard await save(term) else { return false }
        await record(detail: "Added \(kind.title) '\(name)'")
        newName = ""
        formError = nil
        return true
    }

    /// Renames a term in place.
    @discardableResult
    func rename(_ term: TaxonomyTerm, to name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            formError = L10n.adminTaxonomyNameRequired.string
            return false
        }
        guard !isDuplicate(trimmed, in: term.kind, excluding: term.id) else {
            formError = L10n.adminTaxonomyDuplicate.string
            return false
        }
        guard trimmed != term.name else { return true }

        var updated = term
        updated.name = trimmed
        guard await save(updated) else { return false }
        await record(detail: "Renamed \(term.kind.title) '\(term.name)' to '\(trimmed)'")
        formError = nil
        return true
    }

    /// Removes a term.
    func delete(_ term: TaxonomyTerm) async {
        do {
            try await store.remove(id: term.id)
            await record(detail: "Deleted \(term.kind.title) '\(term.name)'")
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Folds `source` into `target`: the counts add, the source disappears, the trail records it.
    func merge(_ source: TaxonomyTerm, into target: TaxonomyTerm) async {
        var survivor = target
        survivor.usageCount = target.usageCount + source.usageCount
        do {
            try await store.save(survivor)
            try await store.remove(id: source.id)
            await record(detail: "Merged \(source.kind.title) '\(source.name)' into '\(target.name)'")
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Persists a new display order produced by the list. Only rows whose index changed are written.
    func persistOrder(_ ordered: [TaxonomyTerm]) async {
        for (index, term) in ordered.enumerated() where term.sortIndex != index {
            var updated = term
            updated.sortIndex = index
            try? await store.save(updated)
        }
        await load()
    }

    /// Clears the add field's validation error, so a fresh attempt starts clean.
    func clearFormError() {
        formError = nil
    }

    // MARK: Helpers

    private func isDuplicate(_ name: String, in kind: TaxonomyKind, excluding id: String?) -> Bool {
        terms.contains {
            $0.kind == kind
                && $0.id != id
                && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func save(_ term: TaxonomyTerm) async -> Bool {
        do {
            try await store.save(term)
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    private func record(detail: String) async {
        try? await audit.record(AuditEntry(action: .taxonomyChanged, actorName: actorName, detail: detail))
    }
}

