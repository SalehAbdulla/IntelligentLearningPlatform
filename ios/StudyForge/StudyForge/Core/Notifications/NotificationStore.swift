//
//  NotificationStore.swift
//  StudyForge
//
//  Where the student's inbox and their notification choices are kept, and the seam that hides WHERE.
//
//  WHY THE CHOICES LIVE IN THE SAME STORE AS THE INBOX
//  --------------------------------------------------
//  docs/05 §2.1 keeps `notificationPrefs` in `users/{uid}/private/prefs` while `notifications` is its
//  own collection — different places for different reasons (one is private, one is a list). Locally
//  the two are read together on every screen that needs either, so one store with two concerns is
//  the honest shape here, and the seam can be split the day the server needs it to be.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  The inbox is the app's own record (see `StudyNotification`), so it works with no project
//  configured. `add` replaces by id, which is what makes the reminder planner's stable ids idempotent.
//

import Foundation

/// Reads and writes the student's inbox and their notification choices.
protocol NotificationStore: Sendable {

    /// Every notification, newest first.
    func all() async throws -> [StudyNotification]

    /// Stores a notification, replacing any existing one with the same id.
    func add(_ notification: StudyNotification) async throws

    /// Marks one notification read. Marking an already-read or unknown notification is not an error.
    func markRead(id: String) async throws

    /// Marks every notification read — M01's "mark all as read".
    func markAllRead() async throws

    /// Removes a notification. Removing one that is already gone is not an error.
    func delete(id: String) async throws

    /// The student's choices, or the defaults when they have never saved any.
    func preferences() async throws -> NotificationPreferences

    /// Stores the student's choices.
    func savePreferences(_ preferences: NotificationPreferences) async throws
}

/// Failures from the notification layer, in the app's own vocabulary.
enum NotificationError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "notification-store-failed")
        }
    }
}