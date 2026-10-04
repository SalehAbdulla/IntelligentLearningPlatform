//
//  Course.swift
//  StudyForge
//
//  F11 — a tutor's course: the cohort, its term and what has been published to it
//  (docs/03 §J J02/J03/J05; docs/05 §2 `courses/{courseId}`).
//
//  WHY THE ROSTER IS A LIST OF UIDS HERE
//  -------------------------------------
//  `backend/firestore.rules` grants a course read to a student only
//  `if ... uid() in resource.data.enrolledUids` — membership is decided by a field ON THE
//  COURSE, not by a query. Keeping `enrolledUids` on the document is therefore not a
//  shortcut: it is what makes the security rule expressible. The richer per-student detail
//  (name, mastery, last active) lives in `Enrollment`, joined on by the store.
//
//  WHY PUBLISHED MATERIALS ARE ON THE COURSE
//  -----------------------------------------
//  Storage paths them under `courses/{courseId}/published/**` (docs/05 §3), and the tutor
//  publishes from their own library (F02) rather than uploading a second copy. A link record
//  is the honest shape: the material keeps one home, and a course says which of them it has
//  shown to whom.
//

import Foundation

/// How a student joins a course (J03's "enrolment mode").
enum EnrolmentMode: String, Sendable, Codable, CaseIterable, Identifiable {
    /// Anyone with the code or link can join.
    case open

    /// A join code is required.
    case code

    /// The tutor approves each request.
    case approval

    var id: String { rawValue }

    /// Deliberately NOT `displayName`: the label is copy, so it lives in `L10n` and the
    /// view model resolves it (docs/04 §8 — no user-facing string outside the catalogue).
    var symbolName: String {
        switch self {
        case .open: "lock.open"
        case .code: "number"
        case .approval: "person.badge.clock"
        }
    }
}

/// A material this course has published to its cohort (J05).
///
/// `materialId` points at the tutor's library item; `title` is a snapshot so the course can
/// render its published list without loading every material.
struct PublishedMaterial: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var materialId: String
    var title: String

    /// When it goes live (J05's publish date/time picker). A future date is a scheduled
    /// publication, which is why this is not simply "now".
    var publishedAt: Date

    /// Whether publishing notified the cohort (J05's "notify students" toggle).
    var notifiesStudents: Bool

    init(
        id: String = UUID().uuidString,
        materialId: String,
        title: String,
        publishedAt: Date = .now,
        notifiesStudents: Bool = true
    ) {
        self.id = id
        self.materialId = materialId
        self.title = title
        self.publishedAt = publishedAt
        self.notifiesStudents = notifiesStudents
    }

    /// Whether it is visible to students yet.
    func isLive(at now: Date = .now) -> Bool { publishedAt <= now }

    /// Whether it is queued for a future date — shown as "Scheduled", not "Live".
    func isScheduled(at now: Date = .now) -> Bool { publishedAt > now }
}

/// A tutor-owned course and its cohort (docs/05 §2 `courses/{courseId}`).
struct Course: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var name: String

    /// The institution's course code — what a student recognises it by (J02's "code").
    var code: String

    /// The owning tutor. `firestore.rules` checks `resource.data.tutorUid == uid()` on
    /// create, so this is the field that decides who may edit the course.
    var tutorUid: String

    var termStart: Date
    var termEnd: Date

    var enrolmentMode: EnrolmentMode

    /// Index into the design palette for the course cover (J03's colour picker). Stored as
    /// an INDEX rather than a hex string, so a token change repaints every course instead of
    /// leaving stale colours baked into documents.
    var colourIndex: Int

    /// Uids of enrolled students. See the note at the top of this file.
    var enrolledUids: [String]

    var publishedMaterials: [PublishedMaterial]

    var isArchived: Bool

    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        code: String,
        tutorUid: String,
        termStart: Date = .now,
        termEnd: Date = .now.addingTimeInterval(60 * 60 * 24 * 120),
        enrolmentMode: EnrolmentMode = .code,
        colourIndex: Int = 0,
        enrolledUids: [String] = [],
        publishedMaterials: [PublishedMaterial] = [],
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.tutorUid = tutorUid
        self.termStart = termStart
        self.termEnd = termEnd
        self.enrolmentMode = enrolmentMode
        self.colourIndex = colourIndex
        self.enrolledUids = enrolledUids
        self.publishedMaterials = publishedMaterials
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// How many students are enrolled (J02's "enrolment count").
    var enrolmentCount: Int { enrolledUids.count }

    /// How many published materials are LIVE.
    ///
    /// A scheduled publication is not visible to the cohort yet, so counting it would
    /// overstate what students can actually see — which is the one thing this figure is for.
    func liveMaterialCount(at now: Date = .now) -> Int {
        publishedMaterials.filter { $0.isLive(at: now) }.count
    }

    /// Whether the term is still running.
    func isRunning(at now: Date = .now) -> Bool { now <= termEnd }

    /// Whether a student is already on the roster.
    func enrols(uid: String) -> Bool { enrolledUids.contains(uid) }

    /// Adds a student, ignoring a duplicate so a double-tap cannot double-count (J04).
    mutating func enrol(uid: String, at now: Date = .now) {
        guard !enrolledUids.contains(uid) else { return }
        enrolledUids.append(uid)
        updatedAt = now
    }

    /// Adds a publication, replacing any earlier one for the SAME material — re-publishing an
    /// edited material is an update, not a second entry (docs/02 §6's "re-publishing an edited
    /// material" edge case).
    mutating func publish(_ material: PublishedMaterial, at now: Date = .now) {
        if let index = publishedMaterials.firstIndex(where: { $0.materialId == material.materialId }) {
            publishedMaterials[index] = material
        } else {
            publishedMaterials.append(material)
        }
        updatedAt = now
    }
}

// MARK: - Preview and demo data

extension Course {

    /// A running, populated course for previews and the seeded demo dataset (docs/11 §6
    /// wants a demo course with real materials and members).
    static let sample = Course(
        id: "course_it8108",
        name: "IT8108 — Project Design & Prototype",
        code: "IT8108",
        tutorUid: "uid_tutor",
        termStart: Date().addingTimeInterval(-60 * 60 * 24 * 40),
        termEnd: Date().addingTimeInterval(60 * 60 * 24 * 60),
        enrolmentMode: .code,
        colourIndex: 1,
        enrolledUids: ["uid_a", "uid_b", "uid_c", "uid_d"]
    )
}
