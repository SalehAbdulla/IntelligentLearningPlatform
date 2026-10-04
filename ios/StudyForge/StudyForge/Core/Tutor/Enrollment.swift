//
//  Enrollment.swift
//  StudyForge
//
//  F11 — one student's membership of one course, with the facts J04's roster table shows
//  (docs/03 §J J04; docs/05 §2 `enrollments/{uid_courseId}`).
//
//  WHY THE ID IS COMPOSITE
//  -----------------------
//  docs/05 §2 names the document `enrollments/{uid_courseId}` — the pair IS the identity, and
//  a random id would allow two enrolment documents for the same student and course. Building
//  the id from the pair makes that duplicate unrepresentable rather than merely discouraged.
//
//  WHY MASTERY LIVES ON THE ENROLMENT
//  ----------------------------------
//  J04 shows "mastery %" and "last active" per student, so the roster can be read in one
//  query. The alternative — joining each student's `progress` document — is the Firestore
//  read-cost trap docs/04 warns about. The nightly roll-up (docs/02 §6) is what would keep
//  these numbers fresh; until it can deploy (docs/09 D22), they are seeded.
//

import Foundation

/// A student's standing in a course.
enum EnrollmentStatus: String, Sendable, Codable, CaseIterable {
    /// On the roster and learning.
    case active

    /// Requested to join and awaiting the tutor's approval — only possible for a course whose
    /// `enrolmentMode` is `.approval` (J03).
    case pending

    /// Taken off the roster. Kept rather than deleted so the tutor's export is auditable.
    case removed
}

/// A student's membership of a course (docs/05 §2 `enrollments/{uid_courseId}`).
struct Enrollment: Identifiable, Equatable, Sendable, Codable {

    /// `"{uid}_{courseId}"` — see the note at the top of this file.
    let id: String

    var courseId: String
    var uid: String

    /// Snapshot of the student's name, so the roster renders without loading their profile.
    var studentName: String

    /// The student number the institution uses (J04's "ID" column).
    var studentNumber: String

    /// 0…100. See the note at the top of this file.
    var masteryPercent: Int

    /// `nil` when the student has never opened the course.
    var lastActiveAt: Date?

    var status: EnrollmentStatus

    init(
        courseId: String,
        uid: String,
        studentName: String,
        studentNumber: String,
        masteryPercent: Int = 0,
        lastActiveAt: Date? = nil,
        status: EnrollmentStatus = .active
    ) {
        self.id = Enrollment.identifier(uid: uid, courseId: courseId)
        self.courseId = courseId
        self.uid = uid
        self.studentName = studentName
        self.studentNumber = studentNumber
        self.masteryPercent = masteryPercent
        self.lastActiveAt = lastActiveAt
        self.status = status
    }

    /// The document id for a (student, course) pair.
    static func identifier(uid: String, courseId: String) -> String { "\(uid)_\(courseId)" }

    /// The blend below which the tutor should look at this student.
    ///
    /// A documented threshold rather than a tuned one, matching `TopicMastery.isWeak`: the
    /// tutor can see WHY a row is flagged ("under 60 % mastery"), which a magic number could
    /// not explain.
    var isAtRisk: Bool { status == .active && masteryPercent < 60 }

    /// Whether the student has been active within the given window.
    func isActive(since cutoff: Date) -> Bool {
        guard let lastActiveAt else { return false }
        return lastActiveAt >= cutoff
    }
}
