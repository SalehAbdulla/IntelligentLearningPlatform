//
//  ModerationStore.swift
//  StudyForge
//
//  Where user-submitted content reports are kept, and the seam that hides WHERE (docs/03 section K,
//  K04/K05; docs/05 section 2.1 `reports`).
//
//  WHY THIS IS ITS OWN SEAM
//  ------------------------
//  `AIConfigurationStore` holds the app's own settings and trail; `AdminDirectoryStore` holds a roster
//  read constantly. Reports are a THIRD shape: a work queue whose whole purpose is to shrink as items
//  are decided. Giving it its own protocol keeps the queue's read-and-decide rhythm from leaking into
//  the settings store, and keeps the seam the real `reports` query will land behind a single file.
//
//  WHY THE STORE CANNOT DELETE
//  ---------------------------
//  A decided report is not removed, it is marked. The record of WHAT WAS REPORTED and WHY IT WAS
//  DECIDED is exactly the history K05 shows and K08 audits, so the store only ever reads and saves.
//

import Foundation

/// Reads and writes the moderation queue.
protocol ModerationStore: Sendable {

    /// Every report, newest first.
    func reports() async throws -> [ContentReport]

    /// One report, or `nil` when nothing is stored under that id.
    func report(id: String) async throws -> ContentReport?

    /// Stores a report, replacing any existing one with the same id.
    func save(_ report: ContentReport) async throws
}

/// Failures from the moderation layer, in the app's own vocabulary.
///
/// Shares `AdminError` with the other admin stores: all three are "the admin layer could not read or
/// write its own records", and a second spelling of that would not tell anyone anything new.
typealias ModerationError = AdminError
