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

    /// Institutions offered as quick-picks by the university picker.
    ///
    /// Deliberately short, and now a SUGGESTION rather than a boundary: the picker is a free
    /// text field, so a student types their own institution when it is not here. Inventing a
    /// longer list would look like real data; the real institutional list arrives with
    /// enrolment (C01/F02).
    var universities: [String]

    /// Years offered by the segmented control.
    ///
    /// Part of the catalogue rather than hard-coded in the control, so a five-year
    /// programme does not need a view change. 1–4 reflects the four-year bachelor's
    /// pattern at the institutions above.
    var years: [Int]

    /// Courses offered as quick-picks, in the order they should be shown. Like `universities`,
    /// a suggestion: a student may add subjects the list does not carry.
    var courses: [CourseOption]

    // TODO(M1 · F02): Replace this scaffolding with the student's real enrolled courses.
    // Done when: the catalogue is loaded from F02's store at its single injection point,
    // `AcademicCatalogue.placeholder` is no longer referenced by a product screen, and a
    // test covers the enrolled path.
    //
    /// The placeholder catalogue. See the note above: this is F01 scaffolding, not data.
    ///
    /// `IT8108` is the one real course id here. It was confirmed rather than invented:
    /// the student is enrolled in IT8108, and "Programming" is their MAJOR — so the course
    /// is offered by its code, because nobody has supplied its title. Showing the code is
    /// honest and is what a timetable shows; inventing a title would put a made-up course
    /// name in front of a marker as though it were real. C01 replaces this list with the
    /// catalogue, titles included (docs/09 §3, Q10).
    static let placeholder = AcademicCatalogue(
        universities: [
            "Bahrain Polytechnic",
            "University of Bahrain",
        ],
        years: [1, 2, 3, 4],
        courses: [
            CourseOption(id: "IT8108", name: "IT8108"),
            CourseOption(id: "c_101", name: "Introduction to Programming"),
            CourseOption(id: "c_104", name: "Data Structures"),
            CourseOption(id: "cs201", name: "Databases"),
        ]
    )

    func course(for id: String) -> CourseOption? {
        courses.first { $0.id == id }
    }

    /// Display names for stored course ids, comma-separated, in the order given.
    ///
    /// An id the catalogue does not know is shown AS THE ID. A code is honest and a guessed
    /// name is not — the same convention docs/03 §B already uses where a course has no known
    /// title yet. Kept here rather than on each summary screen, so B04's confirmation and B06's
    /// profile view cannot resolve the same ids two different ways.
    func courseNames(for ids: [String]) -> String {
        ids.map { course(for: $0)?.name ?? $0 }.joined(separator: ", ")
    }
}
