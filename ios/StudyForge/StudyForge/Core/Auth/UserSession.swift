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

    /// The user-facing role name, from the catalogue so it follows the app's language.
    var displayName: String {
        switch self {
        case .student: L10n.sessionRoleStudent.string
        case .tutor: L10n.sessionRoleTutor.string
        case .admin: L10n.sessionRoleAdmin.string
        }
    }
}

/// The user's subscription tier, mirrored from the `plan` custom claim.
/// Entitlements are written server-side by the Tap Payments webhook — never by the client.
enum SubscriptionPlan: String, Codable, Sendable, CaseIterable {
    case free
    case plus
    case pro

    /// The user-facing plan name, from the catalogue so it follows the app's language.
    var displayName: String {
        switch self {
        case .free: L10n.sessionPlanFree.string
        case .plus: L10n.sessionPlanPlus.string
        case .pro: L10n.sessionPlanPro.string
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

    /// The address the account was registered with.
    ///
    /// Carried on the session because A06 must SHOW it: a mistyped address is the most
    /// common reason a verification email never arrives, and it is invisible unless the
    /// screen echoes what it actually sent to. Defaults to `""` so a session built for a
    /// preview does not have to invent one.
    let email: String

    /// Whether the provider has verified the user controls their email address.
    ///
    /// Read from the ID token's standard `email_verified` claim. The **default is
    /// `false`**, matching the fail-closed rule the rest of this file follows: if the
    /// claim is missing or unparseable, the app treats the user as unverified and shows
    /// A06. That direction is safe because it is recoverable — a genuinely verified user
    /// taps "I've verified" and is let through — whereas defaulting to `true` would let an
    /// unverified account straight past the one check F01 exists to enforce.
    let isEmailVerified: Bool

    init(
        id: String,
        displayName: String,
        role: AppRole,
        plan: SubscriptionPlan,
        groupIds: [String],
        email: String = "",
        isEmailVerified: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.role = role
        self.plan = plan
        self.groupIds = groupIds
        self.email = email
        self.isEmailVerified = isEmailVerified
    }

    /// True when this user can reach the tutor content studio.
    var isTutor: Bool { role == .tutor || role == .admin }

    /// True when this user participates in at least one study group.
    var isStudyGroupMember: Bool { !groupIds.isEmpty }

    static let preview = UserSession(
        id: "uid_preview",
        displayName: "Sara Ali",
        role: .student,
        plan: .free,
        groupIds: ["g_1042"],
        // Verified, so previews of the signed-in screens do not all show A06.
        isEmailVerified: true
    )
}
