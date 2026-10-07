//
//  TaxonomyStore.swift
//  StudyForge
//
//  Where the platform's subjects and tags are kept, and the seam that hides WHERE (docs/03 section K,
//  K06).
//
//  WHY THIS ONE CAN DELETE
//  -----------------------
//  The audit trail and the moderation queue are append-only, but a taxonomy is a LIST an admin curates:
//  deleting an unused tag is a normal, expected operation. So this seam carries `remove`, and K06's
//  merge is expressed as "add the usage to the survivor, then remove the duplicate".
//

import Foundation

/// Reads and writes the platform taxonomy.
protocol TaxonomyStore: Sendable {

    /// Every term, ordered by kind then `sortIndex`.
    func terms() async throws -> [TaxonomyTerm]

    /// Stores a term, replacing any existing one with the same id.
    func save(_ term: TaxonomyTerm) async throws

    /// Removes a term. Safe to call for an id that is not stored.
    func remove(id: String) async throws
}

/// Failures from the taxonomy layer, in the app's own vocabulary.
typealias TaxonomyError = AdminError
