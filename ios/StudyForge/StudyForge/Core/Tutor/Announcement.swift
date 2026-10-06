//
//  Announcement.swift
//  StudyForge
//
//  F11 — a message a tutor sends to a cohort (docs/03 §J J09; docs/05 §2
//  `announcements/{id}`).
//
//  WHY `visibility` IS DERIVED FROM THE AUDIENCE
//  ---------------------------------------------
//  `firestore.rules` lets a signed-in student read an announcement only when
//  `resource.data.visibility == 'course'`. That single string is the whole difference between
//  a cohort-wide notice and a tutor's private note, so it is COMPUTED from the audience rather
//  than stored as a second, independently-editable field — two sources of truth for "who can
//  read this" is how a private note ends up on a student's phone.
//
//  WHY SCHEDULING IS MODELLED, NOT FAKED
//  -------------------------------------
//  J09 offers "schedule send" alongside "send now". The two are one field apart: a sent
//  announcement has a `sentAt`, a scheduled one has a `scheduledFor` and no `sentAt`. Modelling
//  both means the queue can be listed honestly rather than pretending a scheduled message was
//  delivered.
//

import Foundation

/// Who an announcement is addressed to (J09's audience selector).
enum AnnouncementAudience: String, Sendable, Codable, CaseIterable, Identifiable {
    case course
    case group
    case individual

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .course: "person.3"
        case .group: "person.2"
        case .individual: "person"
        }
    }
}

/// A tutor's message to a cohort (docs/05 §2 `announcements/{id}`).
struct Announcement: Identifiable, Equatable, Sendable, Codable {

    let id: String

    var courseId: String

    /// The author. `firestore.rules` requires `resource.data.authorUid == uid()` on create.
    var authorUid: String

    var audience: AnnouncementAudience

    var title: String
    var body: String

    /// When it should go out, if the tutor scheduled it rather than sending immediately.
    var scheduledFor: Date?

    /// When it actually went out. `nil` while it is a draft or still queued.
    var sentAt: Date?

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        courseId: String,
        authorUid: String,
        audience: AnnouncementAudience = .course,
        title: String,
        body: String,
        scheduledFor: Date? = nil,
        sentAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.courseId = courseId
        self.authorUid = authorUid
        self.audience = audience
        self.title = title
        self.body = body
        self.scheduledFor = scheduledFor
        self.sentAt = sentAt
        self.createdAt = createdAt
    }

    /// The `visibility` value students' read access is decided on. See the note at the top of
    /// this file: only a COURSE-wide announcement is readable by a student.
    var visibility: String { audience == .course ? "course" : "tutor" }

    /// Whether a student would be able to read it.
    var reachesStudents: Bool { visibility == "course" }

    /// Whether it is queued for a later date.
    var isScheduled: Bool { sentAt == nil && scheduledFor != nil }

    /// Whether it has gone out.
    var isSent: Bool { sentAt != nil }

    /// Marks it delivered. Idempotent, so a double-invocation cannot rewrite the send time.
    mutating func markSent(at now: Date = .now) {
        guard sentAt == nil else { return }
        sentAt = now
        scheduledFor = nil
    }
}

/// The canned openers J09 offers so a tutor is not staring at a blank field.
///
/// Titles only — the body is the tutor's to write. A template that filled the body too would
/// be the app putting words in a teacher's mouth to their students.
enum AnnouncementTemplate: String, Sendable, CaseIterable, Identifiable {
    case newMaterial
    case deadlineReminder
    case encouragement

    var id: String { rawValue }

    /// The L10n key for the template's title.
    var title: String {
        switch self {
        case .newMaterial: L10n.tutorTemplateNewMaterial.string
        case .deadlineReminder: L10n.tutorTemplateDeadline.string
        case .encouragement: L10n.tutorTemplateEncouragement.string
        }
    }
}
