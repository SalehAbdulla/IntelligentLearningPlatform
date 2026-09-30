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
    /// - Parameter profile: only the fields named in `ProfileField` are written. That is a
    ///   correctness boundary, not a style preference — the server's allowlist rejects the
    ///   entire update if anything else is included (see `AcademicProfile`).
    /// - Throws: `ProfileError` for every failure; the caller maps it with `AppError.from`.
    func saveAcademicProfile(_ profile: AcademicProfile) async throws

    /// Saves the student's learning style (B02).
    ///
    /// A separate method rather than an optional field on `AcademicProfile`, because the
    /// two are separate WIZARD STEPS. A patch type carrying "whichever fields this step
    /// collected" would make `nil` mean both "the student chose nothing" and "this step did
    /// not ask", and the difference decides whether a field is written or left alone —
    /// which is exactly the sort of ambiguity that clears a preference nobody asked about.
    ///
    /// - Parameter style: its `storageValue` is written, not its Swift case name. The two
    ///   differ for `readWrite`, and the wire format is the documented one.
    /// - Throws: `ProfileError` for every failure.
    func saveLearningStyle(_ style: LearningStyle) async throws
}
