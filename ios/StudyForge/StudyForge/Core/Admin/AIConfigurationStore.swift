//
//  AIConfigurationStore.swift
//  StudyForge
//
//  Where the platform's AI settings and the admin audit trail are kept, and the seam that hides WHERE.
//
//  WHY THE TRAIL LIVES WITH THE SETTINGS
//  -------------------------------------
//  Every write to the configuration produces an audit line, so the two are read and written together
//  on the one screen that touches them. Keeping them behind one seam means a change can never be
//  saved without being recorded — the store is where "log it" stops being something a screen has to
//  remember. docs/05 §2.1 keeps them in separate collections server-side, and that split is exactly
//  what this protocol hides.
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  The settings are the app's own and the trail is the app's own record, so both work with no project
//  configured — which is what makes the admin screen demonstrable rather than empty.
//

import Foundation

/// Reads and writes the AI settings and the append-only audit trail.
protocol AIConfigurationStore: Sendable {

    /// The current settings, or the shipped defaults when none have been saved.
    func configuration() async throws -> AIConfiguration

    /// Stores the settings.
    func save(_ configuration: AIConfiguration) async throws

    /// The audit trail, newest first.
    func auditLog() async throws -> [AuditEntry]

    /// Appends an audit line.
    ///
    /// There is deliberately no update or delete: `auditLog` is append-only in the security model
    /// (docs/05 §2.1), and a trail an admin can edit is not a trail.
    func record(_ entry: AuditEntry) async throws
}

/// Failures from the admin layer, in the app's own vocabulary.
enum AdminError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "admin-store-failed")
        }
    }
}