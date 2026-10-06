//
//  CourseStore.swift
//  StudyForge
//
//  F11 — where a tutor's courses, roster, review queue and announcements are kept, and the
//  seam that hides WHERE (docs/05 §2 `courses` · `enrollments` · `reviewQueue` ·
//  `announcements`).
//
//  LOCAL-FIRST, LIKE EVERY OTHER STORE
//  -----------------------------------
//  `firestore.rules` already makes all four collections tutor-owned and denies students the
//  write. What it does not provide is a tutor studio that is demonstrable before a Firebase
//  project, an admin claim and a cohort of real accounts exist — which is every day of this
//  project so far (docs/09 D22). So this protocol is the seam the real queries land behind,
//  and the local implementations are what the app runs on until then.
//
//  WHY ONE SEAM FOR FOUR COLLECTIONS
//  ---------------------------------
//  They are read and written together by one role, on one set of screens: a course detail
//  screen shows its roster, its review queue and its announcements at once. Splitting them
//  would mean four stores injected everywhere for no benefit, and it would let the four drift
//  apart in ways a tutor would notice but the code would not.
//

import Foundation

/// Reads and writes the tutor studio's records.
protocol CourseStore: Sendable {

    // MARK: Courses

    /// Courses owned by a tutor, most recently updated first.
    ///
    /// Filtered by `tutorUid` because that is exactly what `firestore.rules` scopes a tutor's
    /// access to — the parameter is the security boundary, not a convenience filter.
    func courses(tutorUid: String) async throws -> [Course]

    /// One course, or `nil` when nothing is stored under that id.
    func course(id: String) async throws -> Course?

    /// Stores a course, replacing any existing one with the same id.
    func upsert(_ course: Course) async throws

    /// Removes a course and everything that belonged to it (roster, queue, announcements).
    func deleteCourse(id: String) async throws

    // MARK: Roster

    /// A course's roster, most recently active first.
    func enrollments(courseId: String) async throws -> [Enrollment]

    /// Stores an enrolment. Adding a student is the same call as editing one.
    func upsert(_ enrollment: Enrollment) async throws

    // MARK: Review queue

    /// A course's review items, newest first.
    func reviewItems(courseId: String) async throws -> [ReviewItem]

    /// Stores a review item — the write that records a tutor's decision.
    func upsert(_ item: ReviewItem) async throws

    // MARK: Announcements

    /// A course's announcements, newest first.
    func announcements(courseId: String) async throws -> [Announcement]

    /// Stores an announcement.
    func upsert(_ announcement: Announcement) async throws
}

/// Failures from the tutor layer, in the app's own vocabulary.
enum TutorError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// The signed-in account is not a tutor, so the studio has nothing to show it.
    case notATutor

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "tutor-store-failed")
        case .notATutor:
            // Fails closed with a permissions error rather than an apology, because it IS a
            // permissions fact — the same reason `firestore.rules` denies rather than hides.
            .notPermitted
        }
    }
}
