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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aiConfigChanged: L10n.adminAuditConfigChanged.string
        case .roleChanged: L10n.adminAuditRoleChanged.string
        case .accountSuspended: L10n.adminAuditAccountChanged.string
        }
    }

    var symbolName: String {
        switch self {
        case .aiConfigChanged: "bolt.badge.clock"
        case .roleChanged: "person.badge.key"
        case .accountSuspended: "person.crop.circle.badge.xmark"
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