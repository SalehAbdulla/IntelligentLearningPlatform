//
//  PlatformUser.swift
//  StudyForge
//
//  F12 — one account in the platform directory (docs/03 §K, K02/K03; docs/05 §2.1 `users`).
//
//  WHY THE DIRECTORY IS A LOCAL STAND-IN, AND SAYS SO
//  --------------------------------------------------
//  `users/{uid}` is one document per account, and a list of them is a server query — the privacy
//  model in docs/05 §2.1 gives an admin a cohort-wide read that no device can synthesise. This type
//  is the SHAPE the roster screen needs, and the store behind it is seeded locally so the screen is
//  demonstrable without a backend. It is a stand-in, not a claim: nothing here reads another
//  student's device, and the seam is where the real query will land.
//
//  WHY MASTERY IS A PERCENT AND NOT A RAW SCORE
//  --------------------------------------------
//  K02's table column is "mastery %", and mastery is a derived value (F07 computes it from attempts
//  and card state). Storing the DERIVED number keeps this record a directory entry rather than a
//  second copy of the assessment engine.
//

import Foundation

/// Whether an account may sign in.
enum AccountStatus: String, Sendable, CaseIterable, Codable, Identifiable {
    case active
    case suspended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: L10n.adminStatusActive.string
        case .suspended: L10n.adminStatusSuspended.string
        }
    }
}

/// One account, as the admin roster sees it.
struct PlatformUser: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var displayName: String
    var email: String
    var role: AppRole
    var status: AccountStatus

    /// The student's derived mastery, 0–100. Meaningless for a tutor or admin, and shown as such.
    var masteryPercent: Int

    let joinedAt: Date
    var lastLoginAt: Date

    init(
        id: String = UUID().uuidString,
        displayName: String,
        email: String,
        role: AppRole,
        status: AccountStatus = .active,
        masteryPercent: Int = 0,
        joinedAt: Date = .now,
        lastLoginAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.role = role
        self.status = status
        self.masteryPercent = masteryPercent
        self.joinedAt = joinedAt
        self.lastLoginAt = lastLoginAt
    }

    var isSuspended: Bool { status == .suspended }

    /// Whether this account signed in within the last seven days — K01's "active this week".
    func isActive(within days: Int = 7, now: Date = .now) -> Bool {
        lastLoginAt >= now.addingTimeInterval(-Double(days) * 86_400)
    }

    /// Whether this account looks at risk — K01's at-risk count and K03's risk flag.
    ///
    /// A student who has not signed in for a fortnight OR whose mastery is under half. Both are
    /// stated in the open rather than hidden behind a score, because an admin acting on this needs
    /// to know which of the two it was.
    var isAtRisk: Bool {
        role == .student && (!isActive(within: 14) || masteryPercent < 50)
    }
}

#if DEBUG
extension PlatformUser {

    /// A small, obviously-fake roster, for previews.
    ///
    /// DEBUG only, and never seeded on device: a REAL platform's roster comes from a server query,
    /// and a shipping build showing invented accounts would be the worst kind of lie about data.
    static let samples: [PlatformUser] = [
        PlatformUser(
            id: "u_1",
            displayName: "Sara Ali",
            email: "sara.ali@example.test",
            role: .student,
            masteryPercent: 72,
            lastLoginAt: .now.addingTimeInterval(-3_600)
        ),
        PlatformUser(
            id: "u_2",
            displayName: "Omar Hassan",
            email: "omar.hassan@example.test",
            role: .student,
            masteryPercent: 38,
            lastLoginAt: .now.addingTimeInterval(-86_400 * 9)
        ),
        PlatformUser(
            id: "u_3",
            displayName: "Dr Ghassan AlShajjar",
            email: "ghassan@example.test",
            role: .tutor,
            lastLoginAt: .now.addingTimeInterval(-86_400 * 2)
        ),
        PlatformUser(
            id: "u_4",
            displayName: "Shahad Ashoor",
            email: "shahad@example.test",
            role: .admin,
            status: .active,
            lastLoginAt: .now.addingTimeInterval(-600)
        ),
    ]
}
#endif