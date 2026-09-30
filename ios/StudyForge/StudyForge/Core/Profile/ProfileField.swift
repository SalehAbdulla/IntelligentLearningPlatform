//
//  ProfileField.swift
//  StudyForge
//
//  The `users/{uid}` field names a client may write — the Swift mirror of the server's
//  allowlist.
//
//  WHY A SECOND COPY OF THE SAME LIST IS THE RIGHT CALL
//  ---------------------------------------------------
//  `backend/firestore.rules` decides this set, and nothing on the client can grant itself
//  more. The names are repeated here for one reason: the write has to send those exact
//  strings, and a typo (`courseIDs`) comes back as PERMISSION_DENIED, which on a device
//  looks like a network problem rather than a bug in one identifier. Keeping the names in
//  one Swift type, in the same order as the rule, makes a mismatch something to find by
//  reading rather than something to diagnose from a screenshot.
//
//  The server-owned families are deliberately absent: `role` and `plan` are set by a Cloud
//  Function, and `streak`, `badges` and mastery are gamification values the UI shows as
//  evidence of work done. A write naming those would be refused twice over — by `keeps()`
//  and by the allowlist (D25, docs/09).
//

import Foundation

/// The writable field names, mirroring `editableProfileFields()` in `backend/firestore.rules`.
enum ProfileField {

    // ── Written by the profile wizard ────────────────────────────────────────

    /// B01 — academic.
    static let university = "university"
    static let major = "major"
    static let year = "year"
    static let courseIds = "courseIds"

    /// B02 — learning style.
    static let learningStyle = "learningStyle"

    /// B03 — study goals. Both are written in one update, because they are answers to the
    /// same question and neither is meaningful without the other.
    static let weeklyStudyGoalHours = "weeklyStudyGoalHours"
    static let targetGrade = "targetGrade"

    // ── Set elsewhere, same allowlist ───────────────────────────────────────

    /// `displayName` is set at sign-up; B07 (profile edit) can change it.
    static let displayName = "displayName"

    /// B07 — profile edit.
    static let avatarUrl = "avatarUrl"

    /// Server-stamped on every write, so the client cannot backdate it.
    static let updatedAt = "updatedAt"
}
