//
//  BroadcastStore.swift
//  StudyForge
//
//  Where sent and scheduled announcements are kept, and the seam that hides WHERE (docs/03 section K,
//  K09).
//
//  WHY THIS SEAM HAS NO DELETE
//  ---------------------------
//  A sent announcement is history: it went to real people, and removing the record would be rewriting
//  what happened. Scheduled ones can be cancelled later, but that is a status change, not a delete, so
//  the seam stays read-and-append.
//

import Foundation

/// Reads and stores announcements.
protocol BroadcastStore: Sendable {

    /// Every announcement, newest first.
    func broadcasts() async throws -> [Broadcast]

    /// Stores an announcement, replacing any existing one with the same id.
    func save(_ broadcast: Broadcast) async throws
}

/// Failures from the broadcast layer, in the app's own vocabulary.
typealias BroadcastError = AdminError
