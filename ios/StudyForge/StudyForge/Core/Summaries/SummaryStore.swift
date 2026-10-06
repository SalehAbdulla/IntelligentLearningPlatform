//
//  SummaryStore.swift
//  StudyForge
//
//  Where a student's saved summaries are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, FOR THE SAME REASON MATERIALS ARE (D24, docs/09)
//  --------------------------------------------------------------
//  A summary is derived from material that already lives on the device, and the model that
//  produces it runs there too. The durable home is therefore a local file, exactly like
//  `FileMaterialStore`, and this protocol is the only place that knows that. A screen asks for
//  summaries and never learns whether they came from a file, a database or a server — which is
//  what keeps the decision reversible and every screen testable with `InMemorySummaryStore`.
//
//  WHY `async`
//  -----------
//  File IO must not run on the main actor, and the moment summaries gain a remote half — the
//  "only summaries sync" promise on the sign-up screen — the call becomes a network round trip.
//  An interface that is already `async` absorbs that change without touching a caller.
//

import Foundation

/// Reads and writes the student's saved summaries.
protocol SummaryStore: Sendable {

    /// Every saved summary, newest first.
    func all() async throws -> [Summary]

    /// Stores a summary, replacing any existing one with the same id.
    func add(_ summary: Summary) async throws

    /// Removes a summary. Removing one that is already gone is not an error.
    func delete(id: String) async throws

    /// One summary, or `nil` when nothing is stored under that id.
    func summary(id: String) async throws -> Summary?
}

/// Failures from the summary layer, in the app's own vocabulary.
enum SummaryError: Error, Equatable {

    /// The local store could not be read or written.
    ///
    /// One case rather than a code per `FileManager` error, for the same reason `MaterialError`
    /// keeps a single `storageFailed`: nothing a student can do differs between them, and the
    /// screen shows a retry either way.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            // A reference and a retry, because failing to read the student's OWN summaries is
            // a defect on our side, not the student's mistake.
            .server(reference: "summary-store-failed")
        }
    }
}
