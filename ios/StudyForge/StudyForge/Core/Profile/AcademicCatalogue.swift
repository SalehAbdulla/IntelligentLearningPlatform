//
//  AcademicCatalogue.swift
//  StudyForge
//
//  What the B01 pickers choose from: the universities, the year range, and the courses.
//
//  WHY THIS IS LOCAL DATA IN F01, AND WHY THAT IS NOT LAZINESS
//  ----------------------------------------------------------
//  The obvious design is to read the courses from Firestore. That is not possible here,
//  and the reason is a rule working correctly rather than a gap:
//
//      match /courses/{courseId} {
//        allow read: if isAdmin() || isTutor()
//                     || (signedIn() && uid() in resource.data.enrolledUids);
//
//  A student filling in the profile wizard is enrolled in NOTHING — that is precisely
//  what the screen is collecting. So the catalogue is unreadable at exactly the moment
//  the picker needs it. Widening that rule to any signed-in user would trade a real
//  authorisation boundary (course membership) for a UI convenience, which is the wrong
//  trade in an app whose selling point is that authorisation is enforced server-side.
//
//  So F01 carries the list, and C01 (`24_Courses_List`, feature F02) replaces it with the
//  real source once a course exists to read. The catalogue is INJECTED rather than
//  referenced statically so that replacement is a change at one call site.
//
//  The ids below are the ones the security-rules fixtures and the data-model examples
//  already use (`c_101`, `c_104`, `cs201`), deliberately — so the app, the rules tests
//  and docs/05 agree about what a course id looks like instead of each inventing one.
//
//  NOT INCLUDED ON PURPOSE: `IT8108` / "Programming". Those were supplied as one
//  student's real values, and it is unresolved whether "Programming" is the major and
//  IT8108 a course code or the two are a course's title and code. Seeding a guess here
//  would propagate into the app, the fixtures and the docs at once, so it stays out
//  until somebody confirms it. See docs/09 §2, the open question recorded for the wizard.
//

import Foundation

/// One selectable course.
struct CourseOption: Identifiable, Hashable, Sendable {

    /// What is stored in `AcademicProfile.courseIds`.
    ///
    /// Stable and opaque: a rename must not orphan a student's material, so the id is
    /// never the display name.
    let id: String

    /// What the student sees. Institution-supplied, therefore NOT localised here — a
    /// translated course name would be a different course name.
    let name: String
}

/// Everything the academic step chooses from.
struct AcademicCatalogue: Sendable, Equatable {

    /// Institutions offered by the university picker.
    ///
    /// Deliberately short. It contains the two institutions the repository already
    /// references, and no more, because inventing a longer list would look like real
    /// data — the real list is institutional data that arrives with enrolment (C01/F02).
    var universities: [String]

    /// Years offered by the segmented control.
    ///
    /// Part of the catalogue rather than hard-coded in the control, so a five-year
    /// programme does not need a view change. 1–4 reflects the four-year bachelor's
    /// pattern at the institutions above.
    var years: [Int]

    /// Selectable courses, in the order they should be shown.
    var courses: [CourseOption]

    /// The placeholder catalogue. See the note above: this is F01 scaffolding, not data.
    static let placeholder = AcademicCatalogue(
        universities: [
            "Bahrain Polytechnic",
            "University of Bahrain",
        ],
        years: [1, 2, 3, 4],
        courses: [
            CourseOption(id: "c_101", name: "Introduction to Programming"),
            CourseOption(id: "c_104", name: "Data Structures"),
            CourseOption(id: "cs201", name: "Databases"),
        ]
    )

    func course(for id: String) -> CourseOption? {
        courses.first { $0.id == id }
    }
}
