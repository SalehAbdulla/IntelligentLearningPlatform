//
//  GroupStore.swift
//  StudyForge
//
//  Where the student's group revision spaces are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  docs/05 §2.4 defines `groups/{id}` with member-based rules, and the backend enforces them. This
//  protocol is the seam a realtime sync swaps in behind. Until then the feature works with no
//  Firebase project configured — which is what makes the group board, chat and live quiz
//  demonstrable today rather than empty.
//

import Foundation

/// Reads and writes the student's groups.
protocol GroupStore: Sendable {

    /// Every group, most recently updated first.
    func all() async throws -> [StudyGroup]

    /// One group, or `nil` when nothing is stored under that id.
    func group(id: String) async throws -> StudyGroup?

    /// Stores a group, replacing any existing one with the same id. Posting a message, pinning a
    /// resource or joining is the same call: the group is rewritten.
    func add(_ group: StudyGroup) async throws

    /// Removes a group. Removing one that is already gone is not an error.
    func delete(id: String) async throws

    /// The group whose invite code matches, or `nil` when no group carries it.
    ///
    /// A lookup rather than a list scan at the call site, because joining by code is the one
    /// operation that has to work against a server-side index and so belongs behind the seam.
    func group(withInviteCode code: String) async throws -> StudyGroup?
}

/// Failures from the group layer, in the app's own vocabulary.
enum GroupError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// No group carries the code that was typed (I09's error state).
    case codeNotFound

    /// The code matches a group the student is already in.
    case alreadyAMember

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "group-store-failed")
        // A bad or already-used invite code is a rejected INPUT, not a server fault, and the student
        // can act on it where they typed it. `.authInvalidInput` is the app's only "input rejected,
        // here is the specific reason" case, and it presents `reason` verbatim — which is exactly
        // what I09's error state needs.
        case .codeNotFound:
            .authInvalidInput(reason: L10n.groupJoinCodeInvalid.string)
        case .alreadyAMember:
            .authInvalidInput(reason: L10n.groupJoinAlreadyMember.string)
        }
    }
}