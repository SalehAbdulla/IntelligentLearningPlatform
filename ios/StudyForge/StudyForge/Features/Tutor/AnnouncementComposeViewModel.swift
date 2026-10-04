//
//  AnnouncementComposeViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for J09 (`107_Tutor_Announcement_Compose_{M2}`).
//
//  WHY THE AUDIENCE CHANGES WHAT STUDENTS CAN READ
//  -----------------------------------------------
//  `Announcement.visibility` is derived from the audience, and `firestore.rules` lets a student
//  read an announcement only when it is `'course'`. So choosing "one student" is not a display
//  preference — it is the difference between a message delivered and a message a cohort can
//  open. The screen says which is which rather than leaving the tutor to discover it.
//

import Foundation

@MainActor
@Observable
final class AnnouncementComposeViewModel {

    // MARK: Bound state

    var title = ""
    var body = ""

    /// J09's audience selector.
    var audience: AnnouncementAudience = .course

    /// J09's schedule-send. Ignored unless `wantsSchedule` is on.
    var wantsSchedule = false
    var scheduledFor: Date = Date().addingTimeInterval(60 * 60)

    private(set) var isSending = false
    private(set) var error: AppError?

    /// The announcement as written, once it has been sent or queued.
    private(set) var sent: Announcement?

    private let uid: String
    private let courseId: String
    private let store: any CourseStore

    init(uid: String, courseId: String, store: any CourseStore) {
        self.uid = uid
        self.courseId = courseId
        self.store = store
    }

    // MARK: Derived

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedBody: String { body.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Why the composer cannot send, or `nil` when it can.
    var validationMessage: String? {
        if trimmedTitle.isEmpty { return L10n.tutorTitleRequired.string }
        if trimmedBody.isEmpty { return L10n.tutorBodyRequired.string }
        return nil
    }

    var canSend: Bool { validationMessage == nil && !isSending }
    var audiences: [AnnouncementAudience] { AnnouncementAudience.allCases }
    var templates: [AnnouncementTemplate] { AnnouncementTemplate.allCases }

    /// Whether a student would be able to open this. See the note at the top of the file.
    var reachesStudents: Bool { audience == .course }

    /// The outcome banner, once there is one.
    var confirmationText: String? {
        guard let sent else { return nil }
        return sent.isSent ? L10n.tutorSentBanner.string : L10n.tutorScheduledBanner.string
    }

    // MARK: Copy

    var screenTitle: String { L10n.tutorAnnounceTitle.string }
    var audienceLabel: String { L10n.tutorAudienceLabel.string }
    var titleLabel: String { L10n.tutorAnnounceTitleLabel.string }
    var titlePlaceholder: String { L10n.tutorAnnounceTitlePlaceholder.string }
    var bodyLabel: String { L10n.tutorAnnounceBodyLabel.string }
    var bodyPlaceholder: String { L10n.tutorAnnounceBodyPlaceholder.string }
    var templatesHeading: String { L10n.tutorTemplatesHeading.string }
    var sendNowTitle: String { L10n.tutorSendNow.string }
    var scheduleTitle: String { L10n.tutorSchedule.string }

    func audienceName(_ audience: AnnouncementAudience) -> String {
        switch audience {
        case .course: L10n.tutorAudienceCourse.string
        case .group: L10n.tutorAudienceGroup.string
        case .individual: L10n.tutorAudienceIndividual.string
        }
    }

    // MARK: Actions

    /// Fills the title from a template, leaving the body to the tutor.
    ///
    /// A template that wrote the body would be the app putting words in a teacher's mouth to
    /// their students — the one thing this screen should never do.
    func applyTemplate(_ template: AnnouncementTemplate) {
        title = template.title
    }

    /// Sends immediately (J09's "send now").
    @discardableResult
    func sendNow() async -> Bool {
        await commit(scheduled: false)
    }

    /// Queues for the chosen date (J09's "schedule send").
    @discardableResult
    func schedule() async -> Bool {
        await commit(scheduled: true)
    }

    private func commit(scheduled: Bool) async -> Bool {
        guard canSend else { return false }

        isSending = true
        defer { isSending = false }
        error = nil

        let announcement = scheduled
            ? Announcement(
                courseId: courseId,
                authorUid: uid,
                audience: audience,
                title: trimmedTitle,
                body: trimmedBody,
                scheduledFor: scheduledFor
            )
            : Announcement(
                courseId: courseId,
                authorUid: uid,
                audience: audience,
                title: trimmedTitle,
                body: trimmedBody,
                sentAt: .now
            )

        do {
            try await store.upsert(announcement)
            sent = announcement
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }
}
