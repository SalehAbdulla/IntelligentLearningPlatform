//
//  AuditEntry.swift
//  StudyForge
//
//  F12 — the admin action trail (docs/03 §K, K08; docs/05 §2.1 `auditLog`).
//
//  WHY THE TRAIL IS APPEND-ONLY
//  ----------------------------
//  docs/05 §2.1 gives `auditLog` no client write access at all and describes it as append-only, and
//  §9 lists auditability as a security property. The reason is simple: a record of what administrators
//  did is worth nothing if an administrator can edit it. Locally that means the store only ever ADDS —
//  there is no update or delete — so the seam already has the shape the server will enforce.
//
//  WHY `detail` IS STORED TEXT
//  ---------------------------
//  An audit line has to say what changed ("Daily limit 20 → 50"), and that is a sentence with numbers
//  in it. Storing it is the honest choice for a record whose whole job is to be a faithful account of
//  a moment; localising it later would rewrite history rather than describe it.
//

import Foundation

/// What an admin did. A small vocabulary, because each case is a thing the app can actually do.
enum AuditAction: String, Sendable, CaseIterable, Codable, Identifiable {
    /// The routing policy or the quota changed (K07).
    case aiConfigChanged

    /// An account's role changed (K03).
    case roleChanged

    /// An account was suspended or reactivated (K03).
    case accountSuspended

    /// A report was decided in the content's favour, so the content stays (K04).
    case moderationApproved

    /// A report was upheld and the content was removed (K04).
    case moderationRemoved

    /// A report was escalated for a second review (K04).
    case moderationEscalated

    /// The subject and tag vocabulary changed (K06).
    case taxonomyChanged

    /// An announcement was sent or scheduled (K09).
    case broadcastSent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aiConfigChanged: L10n.adminAuditConfigChanged.string
        case .roleChanged: L10n.adminAuditRoleChanged.string
        case .accountSuspended: L10n.adminAuditAccountChanged.string
        case .moderationApproved: L10n.adminAuditModerationApproved.string
        case .moderationRemoved: L10n.adminAuditModerationRemoved.string
        case .moderationEscalated: L10n.adminAuditModerationEscalated.string
        case .taxonomyChanged: L10n.adminAuditTaxonomyChanged.string
        case .broadcastSent: L10n.adminAuditBroadcastSent.string
        }
    }

    var symbolName: String {
        switch self {
        case .aiConfigChanged: "bolt.badge.clock"
        case .roleChanged: "person.badge.key"
        case .accountSuspended: "person.crop.circle.badge.xmark"
        case .moderationApproved: "checkmark.seal"
        case .moderationRemoved: "trash"
        case .moderationEscalated: "arrow.up.circle"
        case .taxonomyChanged: "tag"
        case .broadcastSent: "megaphone"
        }
    }
}

/// One line of the trail.
struct AuditEntry: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var action: AuditAction

    /// Who did it. An admin's own name, so the trail is attributable.
    var actorName: String

    /// What exactly changed, as a sentence for a human auditor.
    var detail: String

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        action: AuditAction,
        actorName: String,
        detail: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.action = action
        self.actorName = actorName
        self.detail = detail
        self.createdAt = createdAt
    }
}

#if DEBUG
extension AuditEntry {

    /// A short, obviously-fake trail, for previews.
    ///
    /// DEBUG only, and never seeded on device: a real trail is written by real admin actions, and a
    /// shipping build showing invented audit lines would undermine the whole point of a trail.
    static let samples: [AuditEntry] = [
        AuditEntry(
            id: "a_3",
            action: .roleChanged,
            actorName: "Shahad Ashoor",
            detail: "Omar Hassan: Student -> Tutor",
            createdAt: .now.addingTimeInterval(-600)
        ),
        AuditEntry(
            id: "a_2",
            action: .aiConfigChanged,
            actorName: "Shahad Ashoor",
            detail: "Daily limit 20 -> 50",
            createdAt: .now.addingTimeInterval(-3_600 * 4)
        ),
        AuditEntry(
            id: "a_1",
            action: .accountSuspended,
            actorName: "Saleh Abdulla",
            detail: "Sara Ali: Suspended",
            createdAt: .now.addingTimeInterval(-86_400)
        ),
    ]
}
#endif