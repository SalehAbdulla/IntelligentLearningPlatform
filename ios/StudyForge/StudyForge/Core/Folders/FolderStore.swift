//
//  FolderStore.swift
//  StudyForge
//
//  Where the student's shared folders are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  A shared folder is, for now, a local record the student manages. The security rules already define
//  who may read and write `folders/{id}` server-side (docs/05 §2.4), so this protocol is the seam a
//  real sync swaps in behind — and until then the feature works with no project configured, which is
//  the difference between a demonstrable folder screen and an empty one.
//

import Foundation

/// Reads and writes the student's shared folders.
protocol FolderStore: Sendable {

    /// Every folder, most recently updated first.
    func all() async throws -> [SharedFolder]

    /// One folder, or `nil` when nothing is stored under that id.
    func folder(id: String) async throws -> SharedFolder?

    /// Stores a folder, replacing any existing one with the same id. Adding an item or changing a
    /// permission is the same call: the folder is rewritten.
    func add(_ folder: SharedFolder) async throws

    /// Removes a folder. Removing one that is already gone is not an error.
    func delete(id: String) async throws
}

/// Failures from the folder layer, in the app's own vocabulary.
enum FolderError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "folder-store-failed")
        }
    }
}