//
//  CoachStore.swift
//  StudyForge
//
//  F15 — where coach conversations and answer ratings are kept (docs/05 §2 `coachThreads`,
//  `aiFeedback`).
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  docs/05 §2 gives both collections an owner-only rule, which is correct and stays. What it does
//  not provide is a coach that remembers a conversation before a Firebase project exists, so the
//  protocol is the seam a real sync lands behind and the local implementations are what the app
//  runs on until then.
//
//  WHY ONE SEAM FOR TWO COLLECTIONS
//  --------------------------------
//  A rating always refers to a message in a thread. Kept apart, a thread could be deleted while its
//  ratings survived pointing at nothing — which is the same cascade bug the tutor store's delete
//  guards against.
//

import Foundation

/// Reads and writes coach conversations and their ratings.
protocol CoachStore: Sendable {

    /// Every conversation, most recently updated first.
    func threads() async throws -> [CoachThread]

    /// One conversation, or `nil` when nothing is stored under that id.
    func thread(id: String) async throws -> CoachThread?

    /// Stores a conversation, replacing any existing one with the same id.
    func upsert(_ thread: CoachThread) async throws

    /// Removes a conversation and every rating attached to it.
    func deleteThread(id: String) async throws

    /// Ratings, newest first.
    func feedback() async throws -> [AnswerFeedback]

    /// Records one rating. Re-rating the same message replaces the earlier rating rather than
    /// stacking, so an aggregate never counts one answer twice.
    func record(_ feedback: AnswerFeedback) async throws
}

/// Failures from the coach layer, in the app's own vocabulary.
enum CoachStoreError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "coach-store-failed")
        }
    }
}
