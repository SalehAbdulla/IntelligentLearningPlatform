//
//  AdminDirectoryStore.swift
//  StudyForge
//
//  Where the platform directory is kept (docs/03 §K, K01–K03; docs/05 §2.1 `users`).
//
//  WHY THIS IS A SEPARATE SEAM FROM THE AI CONFIGURATION
//  ----------------------------------------------------
//  `AIConfigurationStore` holds one small settings record and an append-only trail; this holds a
//  roster that is read, searched and filtered constantly. Two seams with two shapes is honest about
//  that difference, and it keeps the AI settings' file from being rewritten every time an admin
//  suspends an account.
//
//  WHY THE ROSTER IS A LOCAL STAND-IN, AND SAYS SO
//  -----------------------------------------------
//  A list of every account is a server query — docs/05 §2.1 gives an admin a cohort-wide read that no
//  device can synthesise, and it must not: nothing here reads another student's device. The store is
//  seeded locally so K02 is demonstrable before a backend exists, and the seam is where the real
//  query will land.
//

import Foundation

/// Reads and writes the platform directory.
protocol AdminDirectoryStore: Sendable {

    /// Every account, most recently active first.
    func users() async throws -> [PlatformUser]

    /// One account, or `nil` when nothing is stored under that id.
    func user(id: String) async throws -> PlatformUser?

    /// Stores an account, replacing any existing one with the same id.
    func save(_ user: PlatformUser) async throws
}

/// Failures from the directory layer, in the app's own vocabulary.
///
/// Shares `AdminError` with the AI configuration store: both are "the admin layer could not read or
/// write its own records", and a second spelling of that would not tell anyone anything new.
typealias AdminDirectoryError = AdminError