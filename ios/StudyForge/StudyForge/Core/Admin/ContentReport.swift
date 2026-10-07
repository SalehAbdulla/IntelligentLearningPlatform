//
//  ContentReport.swift
//  StudyForge
//
//  F12: one user-submitted content report (docs/03 section K, K04/K05; docs/05 section 2.1 `reports`).
//
//  WHY A REPORT IS A RECORD AND NOT A BOOLEAN
//  ------------------------------------------
//  A flag is a fact ("somebody objected"); a report is a queue item. It carries WHAT was reported, WHO
//  reported it, WHY, and WHEN, and it moves through a workflow the admin drives. Modelling the workflow
//  explicitly is what lets K04 show a queue and K05 show a decision with a recorded reason, instead of
//  a count nobody can act on.
//
//  WHY THE DECISION REASON IS STORED ON THE REPORT
//  -----------------------------------------------
//  K05 requires a "decision panel with mandatory reason" and K08 requires the trail to be auditable.
//  The reason is the difference between "removed by an admin" and "removed because it doxxed a
//  classmate". It is stored on the report AND copied into the audit line, so the queue and the trail
//  tell the same story rather than one of them carrying the justification alone.
//

import Foundation

/// What a report is about. A small vocabulary, because each case is a thing the platform can show.
enum ReportedContentKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case summary
    case deck
    case quiz
    case comment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: L10n.adminReportKindSummary.string
        case .deck: L10n.adminReportKindDeck.string
        case .quiz: L10n.adminReportKindQuiz.string
        case .comment: L10n.adminReportKindComment.string
        }
    }
}

/// Why something was reported. The reasons are the ones a student can pick from, so the set is closed
/// rather than free text: a closed set is what makes the queue filterable and the numbers meaningful.
enum ReportReason: String, Sendable, CaseIterable, Codable, Identifiable {
    case spam
    case harassment
    case misinformation
    case copyright
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spam: L10n.adminReportReasonSpam.string
        case .harassment: L10n.adminReportReasonHarassment.string
        case .misinformation: L10n.adminReportReasonMisinformation.string
        case .copyright: L10n.adminReportReasonCopyright.string
        case .other: L10n.adminReportReasonOther.string
        }
    }
}

/// Where a report sits in the moderation workflow.
///
/// The verbs match K04's action row (Approve / Remove / Escalate) so the status an admin sets is the
/// status the queue then shows, with no second translation between them.
enum ReportStatus: String, Sendable, CaseIterable, Codable, Identifiable {
    case pending
    case approved
    case removed
    case escalated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: L10n.adminReportStatusPending.string
        case .approved: L10n.adminReportStatusApproved.string
        case .removed: L10n.adminReportStatusRemoved.string
        case .escalated: L10n.adminReportStatusEscalated.string
        }
    }
}

/// One report in the queue.
struct ContentReport: Identifiable, Equatable, Sendable, Codable {

    let id: String

    /// What kind of content was reported.
    var kind: ReportedContentKind

    /// The content's own title, so the queue is readable without opening each report.
    var contentTitle: String

    /// A short excerpt. Never the whole artefact: a queue preview is a glance, not a reading.
    var contentPreview: String

    /// Who reported it. An admin acting on a report needs to know the source.
    var reporterName: String

    var reason: ReportReason

    /// The reporter's own words, optional.
    var note: String

    let reportedAt: Date

    var status: ReportStatus

    /// The admin's reason for the decision. Required before any decision is recorded (K05).
    var decisionReason: String?

    init(
        id: String = UUID().uuidString,
        kind: ReportedContentKind,
        contentTitle: String,
        contentPreview: String,
        reporterName: String,
        reason: ReportReason,
        note: String = "",
        reportedAt: Date = .now,
        status: ReportStatus = .pending,
        decisionReason: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.contentTitle = contentTitle
        self.contentPreview = contentPreview
        self.reporterName = reporterName
        self.reason = reason
        self.note = note
        self.reportedAt = reportedAt
        self.status = status
        self.decisionReason = decisionReason
    }

    var isPending: Bool { status == .pending }

    /// Whole days since the report was filed, floored at zero.
    ///
    /// Floored because a report filed seconds ago from a device whose clock is slightly ahead must
    /// not read as a negative age; an age of zero is "today", which is the honest answer.
    func ageDays(now: Date = .now) -> Int {
        let days = Calendar.current.dateComponents([.day], from: reportedAt, to: now).day ?? 0
        return max(0, days)
    }
}

#if DEBUG
extension ContentReport {

    /// A small, obviously-fake queue, for previews.
    ///
    /// DEBUG only, and never seeded on device: a real moderation queue is a server query over
    /// `reports/{id}` (docs/05 section 2.1), and a shipping build showing invented reports would
    /// misrepresent real people's content.
    static let samples: [ContentReport] = [
        ContentReport(
            id: "r_1",
            kind: .summary,
            contentTitle: "Photosynthesis, chapter 4",
            contentPreview: "Plants use sunlight to make glucose. This summary repeats the same line...",
            reporterName: "Sara Ali",
            reason: .spam,
            note: "This looks like it was copied from a marketing page.",
            reportedAt: .now.addingTimeInterval(-86_400 * 2)
        ),
        ContentReport(
            id: "r_2",
            kind: .comment,
            contentTitle: "Reply in Systems Design group",
            contentPreview: "Are you actually this slow, or is it just for the group project?",
            reporterName: "Omar Hassan",
            reason: .harassment,
            note: "",
            reportedAt: .now.addingTimeInterval(-3_600 * 5)
        ),
        ContentReport(
            id: "r_3",
            kind: .quiz,
            contentTitle: "Databases revision quiz",
            contentPreview: "Question 7 states that SQL is a NoSQL database...",
            reporterName: "Dr Ghassan AlShajjar",
            reason: .misinformation,
            note: "Grounded against the wrong source.",
            reportedAt: .now.addingTimeInterval(-86_400 * 9),
            status: .escalated,
            decisionReason: "Needs a second reviewer before the content is touched."
        ),
    ]
}
#endif

