//
//  ProfileService.swift
//  StudyForge
//
//  The profile-write contract. Firebase is an implementation detail behind it, exactly as
//  it is for `AuthService`, so the wizard can be built, previewed and tested with no
//  Firebase project — and so the rules behaviour can be exercised in the emulator without
//  the app being involved at all.
//
//  DEPENDENCY DIRECTION
//  --------------------
//  Nothing above this file imports Firebase. `FirebaseProfileService` is the only place
//  that does.
//

import Foundation

/// Writes the parts of a profile the student is allowed to set about themselves.
///
/// Separate from `AuthService` rather than a method on it: authentication answers "who is
/// this", this answers "what are they studying". Folding the second into the first would
/// put profile-shaped concerns behind the one type the app already cannot do without.
protocol ProfileService: Sendable {

    /// Saves the academic fields on the signed-in student's own document.
    ///
    /// - Parameter profile: only the fields named in `AcademicProfile.Field` are written.
    ///   That is a correctness boundary, not a style preference — the server's allowlist
    ///   rejects the entire update if anything else is included (see `AcademicProfile`).
    /// - Throws: `ProfileError` for every failure; the caller maps it with `AppError.from`.
    func saveAcademicProfile(_ profile: AcademicProfile) async throws
}
