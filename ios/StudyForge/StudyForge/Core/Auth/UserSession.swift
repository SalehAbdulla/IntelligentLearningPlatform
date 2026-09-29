//
//  UserSession.swift
//  StudyForge
//
//  The authenticated user's identity and capabilities.
//
//  Roles come from Firebase Auth custom claims so that authorisation is enforced
//  SERVER-SIDE in Firestore/Storage rules — the client never decides access.
//  See docs/05-DATA-MODEL-SECURITY.md §5.
//

import Foundation

/// The four StudyForge roles (docs/00-MASTER-PLAN.md §7).
///
/// Note: *Study Group Member* is deliberately **not** a role. It is a capability
/// layered on top of `student`, expressed through `groupIds` and per-folder
/// permissions — one human, one account, many contexts.
enum AppRole: String, Codable, Sendable, CaseIterable {
    case student
    case tutor
    case admin

    var displayName: String {
        switch self {
        case .student: "Student"
        case .tutor: "Tutor"
        case .admin: "Admin"
        }
    }
}

/// The user's subscription tier, mirrored from the `plan` custom claim.
/// Entitlements are written server-side by the Tap Payments webhook — never by the client.
enum SubscriptionPlan: String, Codable, Sendable, CaseIterable {
    case free
    case plus
    case pro

    /// User-facing label. Part of the localisation debt recorded in
    /// `Core/Localisation/L10n.swift`: `AppRole.displayName` and this share the same
    /// problem — centralised but not yet routed through `Localizable.strings`.
    var displayName: String {
        switch self {
        case .free: "Free"
        case .plus: "Plus"
        case .pro: "Pro"
        }
    }

    /// Free cloud AI generations per day. On-device generation is unlimited and free
    /// (docs/04-TECH-ARCHITECTURE-COST.md §4).
    var dailyAIGenerationLimit: Int {
        switch self {
        case .free: 15
        case .plus: 100
        case .pro: .max
        }
    }
}

/// A resolved user session.
struct UserSession: Identifiable, Sendable, Equatable {
    let id: String              // Firebase Auth uid
    let displayName: String
    let role: AppRole
    let plan: SubscriptionPlan
    /// Group memberships, used to grant collaborative access.
    let groupIds: [String]

    /// True when this user can reach the tutor content studio.
    var isTutor: Bool { role == .tutor || role == .admin }

    /// True when this user participates in at least one study group.
    var isStudyGroupMember: Bool { !groupIds.isEmpty }

    static let preview = UserSession(
        id: "uid_preview",
        displayName: "Sara Ali",
        role: .student,
        plan: .free,
        groupIds: ["g_1042"]
    )
}
