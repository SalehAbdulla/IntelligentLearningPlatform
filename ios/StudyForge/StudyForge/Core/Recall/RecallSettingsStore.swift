//
//  RecallSettingsStore.swift
//  StudyForge
//
//  F17 — where one learner's Recall Space options live, and the seam that hides WHERE.
//
//  WHY THIS IS A SEPARATE SEAM AND NOT MORE OF `DeckStore`
//  ------------------------------------------------------
//  The daily ceilings and the learning steps describe the LEARNER, not any deck: they apply to
//  the cross-deck queue as a whole. Hanging them off `DeckStore` would mean either duplicating
//  them onto every deck or growing a protocol that every flashcard screen already holds. One
//  document per learner also matches `recallSettings/{uid}`, which `firestore.rules` makes
//  owner-only, so the security rule stays a single line to reason about.
//
//  WHY `async`
//  -----------
//  Same reason as `DeckStore`: file IO must not run on the main actor, and a future Firestore
//  half absorbs the change without touching a caller.
//

import Foundation

/// Reads and writes the learner's Recall Space options.
protocol RecallSettingsStore: Sendable {

    /// The learner's options.
    ///
    /// A learner who has never changed anything gets `.default` rather than an error: having no
    /// stored document is the normal first-run state, not a failure worth reporting.
    func settings() async throws -> RecallSettings

    /// Replaces the options. There is exactly one document per learner, so there is no id.
    func save(_ settings: RecallSettings) async throws
}

/// Failures from the Recall Settings layer, in the app's own vocabulary.
enum RecallSettingsError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    ///
    /// Applied by `RecallSpaceViewModel` rather than by `AppError.from`, because `AppError` is
    /// shared state-layer code outside F17's lane. If the case is promoted into `AppError.from`
    /// later, that function starts handling it and this property becomes the path for callers
    /// that hold the concrete error — the view model's behaviour does not change either way.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "recall-settings-store-failed")
        }
    }
}
