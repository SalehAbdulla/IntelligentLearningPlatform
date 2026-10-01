//
//  StoredProfile.swift
//  StudyForge
//
//  What `users/{uid}` holds, read back — the counterpart to the three write types.
//
//  WHY THIS IS A SEPARATE TYPE FROM `AcademicProfile` AND FRIENDS
//  -------------------------------------------------------------
//  The write types are strict on purpose: `AcademicProfile` carries four non-optional values
//  because a screen that has validated a form knows all four. A READ is the opposite problem
//  — the document is filled in three separate updates, so any field may be absent, and the
//  only honest model of it is a type where everything is optional. Forcing a read into the
//  write types would mean inventing the missing values, which is precisely the bug the gate
//  this exists for would hide.
//
//  EVERY FIELD OPTIONAL, AND NO THROWING
//  ------------------------------------
//  A value the app cannot parse (an unknown `learningStyle`, a `year` stored as a string)
//  becomes `nil` rather than failing the whole read. One unrecognised field must not blank
//  out the fields beside it, and a student whose profile is partly unreadable should still
//  reach their home screen.
//
//  Field names come from `ProfileField` — the same list the write uses and the rules
//  allowlist mirrors — so a rename cannot make the read silently miss a field.
//

import Foundation

/// A `users/{uid}` document, decoded.
struct StoredProfile: Sendable, Equatable {

    // MARK: The wizard's fields

    /// B01 — academic.
    var university: String?
    var major: String?
    var year: Int?
    var courseIds: [String]?

    /// B02 — learning style.
    var learningStyle: LearningStyle?

    /// B03 — study goals.
    var weeklyStudyGoalHours: Int?
    var targetGrade: TargetGrade?

    init(
        university: String? = nil,
        major: String? = nil,
        year: Int? = nil,
        courseIds: [String]? = nil,
        learningStyle: LearningStyle? = nil,
        weeklyStudyGoalHours: Int? = nil,
        targetGrade: TargetGrade? = nil
    ) {
        self.university = university
        self.major = major
        self.year = year
        self.courseIds = courseIds
        self.learningStyle = learningStyle
        self.weeklyStudyGoalHours = weeklyStudyGoalHours
        self.targetGrade = targetGrade
    }

    /// Decodes a Firestore document.
    ///
    /// Takes `[String: Any]` rather than a `DocumentSnapshot` so the decoding — including how
    /// it handles a value it does not recognise — is testable with no Firebase project. The
    /// Firestore wrapper in `FirebaseProfileService` is a one-line call to this.
    init(document: [String: Any]) {
        self.init(
            university: document[ProfileField.university] as? String,
            major: document[ProfileField.major] as? String,
            year: document[ProfileField.year] as? Int,
            courseIds: document[ProfileField.courseIds] as? [String],
            learningStyle: (document[ProfileField.learningStyle] as? String)
                .flatMap(LearningStyle.init(storageValue:)),
            weeklyStudyGoalHours: document[ProfileField.weeklyStudyGoalHours] as? Int,
            // The stored letter, read back through the wire vocabulary rather than `rawValue`
            // — same reasoning as `learningStyle`.
            targetGrade: (document[ProfileField.targetGrade] as? String)
                .flatMap(TargetGrade.init(storageValue:))
        )
    }

    // MARK: Completeness

    /// Whether the student has finished the profile wizard.
    ///
    /// DERIVED RATHER THAN A FLAG THE WIZARD SETS
    /// -----------------------------------------
    /// The alternative is a `profileCompletedAt` marker the confirmation screen writes, and
    /// it is worse here: it would be a second write that can fail AFTER the answers are saved
    /// (leaving a complete profile the app still calls incomplete), and one more field for
    /// the rules allowlist to name and defend. Deriving from the fields the wizard exists to
    /// collect keeps the answer in one place and impossible to disagree with the data.
    ///
    /// All THREE steps must have produced their fields. A part-way profile is deliberately
    /// incomplete, so the wizard re-opens — the honest outcome for a student who started and
    /// stopped, since resuming mid-wizard would need each step to be able to load its own
    /// prior answer, which none of them can yet.
    var isComplete: Bool {
        !(university ?? "").isEmpty
            && !(major ?? "").isEmpty
            && year != nil
            && !(courseIds ?? []).isEmpty
            && learningStyle != nil
            && weeklyStudyGoalHours != nil
            && targetGrade != nil
    }

    /// A complete example — a profile all three wizard steps have filled in.
    ///
    /// Used by previews, and by the preview container that claims `.complete`: the gate reads
    /// the profile service, so a preview of the home screen has to be backed by a document or
    /// it would be demonstrating a state the code can never reach.
    static let preview = StoredProfile(
        university: "Bahrain Polytechnic",
        major: "Programming",
        year: 2,
        courseIds: ["IT8108", "c_104"],
        learningStyle: .visual,
        weeklyStudyGoalHours: 12,
        targetGrade: .a
    )
}
