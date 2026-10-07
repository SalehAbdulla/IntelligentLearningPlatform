//
//  BookmarkStore.swift
//  StudyForge
//
//  Where the student's bookmark collections are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  A bookmark collection is, for now, a local record the student manages. docs/05 §2.5 already
//  defines `collections/{id}` and `bookmarks/{id}` with owner-only rules, so this protocol is the
//  seam a real sync swaps in behind — and until then the feature works with no Firebase project
//  configured, which is the difference between a demonstrable bookmarks screen and an empty one.
//
// TODO(M4 · F10): Add a Firestore-backed `BookmarkStore` behind this protocol, matching
// docs/05 §2.5 (`collections/{id}`, `bookmarks/{id}`, owner-only rules).
// Done when: the implementation exists, `AppContainer` can select it, and a test proves a
// collection round-trips through it.
//

import Foundation

/// Reads and writes the student's bookmark collections.
protocol BookmarkStore: Sendable {

    /// Every collection, most recently updated first.
    func all() async throws -> [BookmarkCollection]

    /// One collection, or `nil` when nothing is stored under that id.
    func collection(id: String) async throws -> BookmarkCollection?

    /// Stores a collection, replacing any existing one with the same id. Saving a bookmark,
    /// moving one or deleting one is the same call: the collection is rewritten.
    func add(_ collection: BookmarkCollection) async throws

    /// Removes a collection. Removing one that is already gone is not an error.
    func delete(id: String) async throws
}

/// Failures from the bookmark layer, in the app's own vocabulary.
enum BookmarkError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "bookmark-store-failed")
        }
    }
}