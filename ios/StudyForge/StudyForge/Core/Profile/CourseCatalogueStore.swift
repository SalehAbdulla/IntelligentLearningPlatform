//
//  CourseCatalogueStore.swift
//  StudyForge
//
//  Where the academic step's pickers get their options, and the seam that hides WHERE.
//
//  WHY THIS EXISTS
//  ---------------
//  The catalogue used to be reached through a static, `AcademicCatalogue.placeholder`, named as a
//  default argument by seven declarations and relied on by `RootView`. A static default is not a
//  seam. It is a copy of the data that every call site depends on silently, and the one thing F02
//  cannot replace without editing all of them. The catalogue is now ASKED for through this
//  protocol and injected at the container, so replacing the source is a change at one call site.
//
//  WHY THE PROTOCOL IS ASYNC EVEN THOUGH TODAY'S ANSWER IS LOCAL
//  -----------------------------------------------------------
//  The reason the wizard cannot read `courses/{courseId}` is recorded in `AcademicCatalogue`, and
//  it is a rule working correctly rather than a gap: a student filling the wizard is enrolled in
//  nothing, so an enrolled-only read fails at exactly the moment the picker needs it. Whenever the
//  real source arrives it will therefore be a store or a function, never a plain value the client
//  holds. A synchronous protocol would have to change shape to accommodate that, and the change
//  would land on every call site this seam exists to protect.
//
//  WHAT THE STORE IS NOT
//  ---------------------
//  It is not authoritative. It offers quick-picks, and the student may type an institution or a
//  subject it does not carry, in which case the typed name is what gets stored. So a store that
//  fails costs the student suggestions, never the ability to answer.
//

import Foundation

/// Supplies the options the academic step's pickers offer.
protocol CourseCatalogueStore: Sendable {

    /// The catalogue to offer.
    ///
    /// - Throws: whatever the source raises. The caller reports it and keeps the form usable
    ///   rather than blocking on it, because the pickers accept typed input.
    func catalogue() async throws -> AcademicCatalogue
}

/// The starter set the app ships with, standing in for C01/F02's real source.
///
/// It carries the data that `AcademicCatalogue.placeholder` used to hold. The name changed
/// because the value is now SERVED rather than referenced, and "seeded" is what this codebase
/// calls a store that hands out fixed data (`InMemoryMaterialStore(seededWith:)`).
///
/// The list is short on purpose, and every entry is a quick-pick rather than a boundary: a global
/// product cannot enumerate every institution or course, so a student types their own. The ids are
/// the ones the security-rules fixtures and the data-model examples already use (`c_101`, `c_104`,
/// `cs201`), deliberately, so the app, the rules tests and docs/05 agree about what a course id
/// looks like instead of each inventing one.
///
/// `IT8108` is the one REAL course id here, and it was confirmed rather than invented. See the
/// note in `AcademicCatalogue` for why it is offered by its code and not by a title.
struct SeededCourseCatalogueStore: CourseCatalogueStore {

    /// The shipped starter set, as a value as well as a store.
    ///
    /// Exposed synchronously because previews and tests need a catalogue to render or assert
    /// against, and a preview that has to await a store before it can draw is a preview nobody
    /// uses. `AppContainer` is the only place the asynchronous accessor is needed.
    static let starter = AcademicCatalogue(
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

    func catalogue() async throws -> AcademicCatalogue { Self.starter }
}
