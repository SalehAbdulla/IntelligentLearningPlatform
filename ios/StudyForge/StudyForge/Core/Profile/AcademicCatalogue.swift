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
//  referenced statically so that replacement is a change at one call site: the source is
//  `CourseCatalogueStore`, resolved once in `AppContainer.loadCatalogue()`.
//
//  The ids below are the ones the security-rules fixtures and the data-model examples
//  already use (`c_101`, `c_104`, `cs201`), deliberately — so the app, the rules tests
//  and docs/05 agree about what a course id looks like instead of each inventing one.
//
//  `IT8108` IS seeded now, and the note above predates that being settled. It began as an open
//  question: whether "Programming" is the major and IT8108 a course code, or the two are one
//  course's title and code. It was answered rather than guessed (programming is the MAJOR, so the
//  course is offered by its code, because nobody has supplied its title), and docs/09 §3 records
//  it. Where a title is still missing the rule is unchanged: a course is shown by its code rather
//  than by an invented name.
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

    /// The catalogue before, or instead of, an answer from `CourseCatalogueStore`.
    ///
    /// `years` is populated even here, and that is the load-bearing part. The year picker's
    /// options come from the catalogue, so an empty range would leave the student unable to
    /// answer the step at all, which is a worse outcome than a stale one. The other two lists
    /// are empty on purpose, because both of those pickers accept typed input: a catalogue that
    /// has not arrived costs the student quick-picks, never an answer.
    ///
    /// This is the state a failed or still-running store leaves behind. The wizard must not be
    /// able to dead-end on a source it cannot read, which is the same principle the profile gate
    /// records for its own read (`AppContainer.resolveProfile`).
    static let empty = AcademicCatalogue(universities: [], years: [1, 2, 3, 4], courses: [])

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
