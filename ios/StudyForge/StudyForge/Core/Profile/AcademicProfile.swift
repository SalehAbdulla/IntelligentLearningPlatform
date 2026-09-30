//
//  AcademicProfile.swift
//  StudyForge
//
//  The academic half of a student's profile — the four fields the profile wizard's
//  first step (B01, `11_ProfileSetup_Academic_{M1}`) collects, and nothing else.
//
//  WHY THE WRITABLE SET IS A NAMED TYPE
//  -----------------------------------
//  Updates to `users/{uid}` are authorised by an ALLOWLIST —
//  `onlyChanges(editableProfileFields())` in backend/firestore.rules. An allowlist
//  rejects every key it has not been told about, which is the point of it (D25,
//  docs/09): a field added by a later sprint is not client-writable until somebody
//  writes it down and justifies it.
//
//  The consequence for this screen is concrete. A stray field here does not fail
//  quietly and it does not "not save" — it fails the WHOLE write with PERMISSION_DENIED,
//  leaving the student on a screen that looks finished. Keeping the writable set in one
//  type, with the Firestore key names in one place, is what turns that into a change
//  somebody made on purpose.
//
//  Note what is deliberately absent: no `email`, `role` or `plan`. The update rule also
//  pins those with `keeps('role')` / `keeps('plan')`, so carrying them here would reject
//  the update just as surely — and a profile form has no business writing an entitlement.
//

import Foundation

/// The academic fields a student may set about themselves.
struct AcademicProfile: Sendable, Equatable {

    /// The institution, chosen from `AcademicCatalogue.universities`.
    var university: String

    /// The student's programme or major. Free text — every institution words this
    /// differently ("Major", "Programme", "Specialisation"), so a fixed list would be
    /// wrong for most of them.
    var major: String

    /// Year of study, 1-based. An `Int` rather than a string so dashboard queries and
    /// "year 3 students" cohort filters can compare it numerically.
    var year: Int

    /// Firestore ids of the enrolled courses.
    ///
    /// The same ids `courses/{courseId}` and `materials/{materialId}.courseId` use, which
    /// is what lets a student's material be filed by course without a second mapping.
    var courseIds: [String]
}

extension AcademicProfile {

    /// The Firestore field names, declared once.
    ///
    /// These are the literal strings the rules allowlist compares against, and they are
    /// shared with the service that performs the write, so the two cannot drift apart in
    /// a way that only shows up as a permission failure on a device.
    enum Field {
        static let university = "university"
        static let major = "major"
        static let year = "year"
        static let courseIds = "courseIds"
    }
}
