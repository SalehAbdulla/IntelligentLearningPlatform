//
//  Broadcast.swift
//  StudyForge
//
//  F12: a platform announcement and the audience it targets (docs/03 section K, K09).
//
//  WHY THE AUDIENCE IS A SEGMENT AND NOT A LIST
//  --------------------------------------------
//  K09 asks for a segment builder, not a recipient picker. A segment is a reusable rule ("students at
//  risk"), so the composer states the RULE and the size is derived from the roster at send time, which
//  is what keeps the number honest rather than frozen at the moment the screen opened.
//
//  WHY A BROADCAST REMEMBERS WHERE IT WENT
//  ---------------------------------------
//  A sent announcement is a record: who it targeted and when. Storing the segment and the count means
//  K08's trail and the recent list agree about it, instead of the count existing only on screen.
//

import Foundation

/// Who a broadcast targets.
enum AudienceSegment: String, Sendable, CaseIterable, Codable, Identifiable {
    case everyone
    case students
    case atRiskStudents
    case tutors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyone: L10n.adminBroadcastAudienceEveryone.string
        case .students: L10n.adminBroadcastAudienceStudents.string
        case .atRiskStudents: L10n.adminBroadcastAudienceAtRisk.string
        case .tutors: L10n.adminBroadcastAudienceTutors.string
        }
    }

    /// One line explaining who the rule selects, shown under the picker.
    var detail: String {
        switch self {
        case .everyone: L10n.adminBroadcastAudienceEveryoneDetail.string
        case .students: L10n.adminBroadcastAudienceStudentsDetail.string
        case .atRiskStudents: L10n.adminBroadcastAudienceAtRiskDetail.string
        case .tutors: L10n.adminBroadcastAudienceTutorsDetail.string
        }
    }

    /// Whether an account is in this segment. The single place the rule lives.
    func matches(_ user: PlatformUser) -> Bool {
        switch self {
        case .everyone: true
        case .students: user.role == .student
        case .atRiskStudents: user.isAtRisk
        case .tutors: user.role == .tutor
        }
    }
}

/// One announcement.
struct Broadcast: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var segment: AudienceSegment
    var title: String
    var message: String

    /// When it should go out, or `nil` for "as soon as it is confirmed".
    var scheduledAt: Date?

    /// How many accounts the segment selected at the moment of sending.
    var recipientCount: Int

    let createdAt: Date

    /// Whether it has left the composer. A scheduled broadcast is not sent until its time arrives.
    var isSent: Bool

    init(
        id: String = UUID().uuidString,
        segment: AudienceSegment,
        title: String,
        message: String,
        scheduledAt: Date? = nil,
        recipientCount: Int = 0,
        createdAt: Date = .now,
        isSent: Bool = false
    ) {
        self.id = id
        self.segment = segment
        self.title = title
        self.message = message
        self.scheduledAt = scheduledAt
        self.recipientCount = recipientCount
        self.createdAt = createdAt
        self.isSent = isSent
    }

    var isScheduled: Bool { !isSent && scheduledAt != nil }
}

#if DEBUG
extension Broadcast {

    /// A couple of obviously-fake announcements, for previews.
    static let samples: [Broadcast] = [
        Broadcast(
            id: "b_1",
            segment: .atRiskStudents,
            title: "Revision clinic on Thursday",
            message: "Drop in at 4pm if you want help planning your week.",
            recipientCount: 12,
            createdAt: .now.addingTimeInterval(-3_600 * 6),
            isSent: true
        ),
        Broadcast(
            id: "b_2",
            segment: .students,
            title: "New Biology material",
            message: "Chapter 5 has been added to the library.",
            scheduledAt: .now.addingTimeInterval(86_400),
            recipientCount: 140,
            createdAt: .now.addingTimeInterval(-600)
        ),
    ]
}
#endif
