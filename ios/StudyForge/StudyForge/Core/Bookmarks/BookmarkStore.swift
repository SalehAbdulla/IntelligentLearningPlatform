//
//  BookmarkStore.swift
//  StudyForge
//
//  Where the student's bookmark collections are kept, and the seam that hides WHERE.
//
//  THE SEAM THE SCREENS ARE WRITTEN AGAINST
//  ----------------------------------------
//  docs/05 §2.5 defines `collections/{id}` and `bookmarks/{id}` with owner-only rules. Screens
//  depend on this protocol rather than on a concrete store, so they are previewed and tested
//  with `InMemoryBookmarkStore` and run unchanged against the store `AppContainer` selects,
//  `FirestoreBookmarkStore`. `FileBookmarkStore` conforms to the same seam as an on-device
//  alternative.
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