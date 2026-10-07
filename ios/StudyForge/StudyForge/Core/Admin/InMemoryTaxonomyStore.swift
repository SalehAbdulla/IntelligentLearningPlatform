//
//  InMemoryTaxonomyStore.swift
//  StudyForge
//
//  A `TaxonomyStore` that keeps everything in memory, for previews and tests.
//
//  A REAL conformance rather than a stub, mirroring the other in-memory stores, so a screen driven by
//  it behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryTaxonomyStore: TaxonomyStore {

    private var stored: [TaxonomyTerm]

    /// When set, every call fails with it until cleared.
    private var failure: AdminError?

    init(seededWith terms: [TaxonomyTerm] = []) {
        self.stored = terms
    }

    // MARK: TaxonomyStore

    func terms() async throws -> [TaxonomyTerm] {
        try failIfForced()
        return sorted(stored)
    }

    func save(_ term: TaxonomyTerm) async throws {
        try failIfForced()
        if let index = stored.firstIndex(where: { $0.id == term.id }) {
            stored[index] = term
        } else {
            stored.append(term)
        }
    }

    func remove(id: String) async throws {
        try failIfForced()
        stored.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: AdminError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }

    /// Kind first, then `sortIndex`, then name as a stable tie-breaker.
    private func sorted(_ terms: [TaxonomyTerm]) -> [TaxonomyTerm] {
        terms.sorted {
            if $0.kind != $1.kind { return $0.kind.rawValue < $1.kind.rawValue }
            if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
            return $0.name < $1.name
        }
    }
}
