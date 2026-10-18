//
//  DemoAccounts.swift
//  StudyForge
//
//  The four demo accounts, as data. DEBUG only.
//
//  WHY THIS FILE EXISTS, AND WHY IT IS NOT THE SOURCE OF TRUTH
//  ----------------------------------------------------------
//  `backend/scripts/seed-demo-accounts.mjs` CREATES these accounts and grants their roles
//  as custom claims. This file only DESCRIBES them, so the developer switcher can offer
//  them by name instead of making someone remember four addresses.
//
//  The two lists must agree. If they drift, the switcher offers an account that does not
//  exist and the sign-in fails as "wrong credentials" — which is why the failure path in
//  `DeveloperAccountSwitcher` names the seeder rather than guessing at the cause.
//
//  The roles below are what the seeder GRANTS. The role the app actually uses always comes
//  from the ID token (`CustomClaims`), never from here — so if the two ever disagree, the
//  app shows the truth and the disagreement is visible rather than hidden.
//

#if DEBUG
import Foundation

/// One seeded account, described for the developer switcher.
struct DemoAccount: Identifiable, Sendable {
    let email: String
    let displayName: String
    let role: AppRole
    let plan: SubscriptionPlan
    /// One line on what this account can reach — the reason to pick it.
    let reaches: String

    var id: String { email }
}

enum DemoAccounts {

    /// The password `backend/scripts/seed-demo-accounts.mjs` sets by default.
    ///
    /// Published on purpose: these are throwaway accounts on a student project, and the
    /// whole point of the switcher is that a demo needs no lookup. This is inside
    /// `#if DEBUG`, so it is not in a shipping build either.
    static let password = "changeme"

    static let all: [DemoAccount] = [
        DemoAccount(
            email: "student@studyforge.test",
            displayName: "Sara Ali",
            role: .student,
            plan: .free,
            reaches: "the golden path — upload, summarise, cards, review"
        ),
        DemoAccount(
            email: "tutor@studyforge.test",
            displayName: "Dr Ali Hassan",
            role: .tutor,
            plan: .pro,
            reaches: "the tutor studio (F11)"
        ),
        DemoAccount(
            email: "group@studyforge.test",
            displayName: "Omar Noor",
            role: .student,
            plan: .pro,
            reaches: "a study group member — the collaboration surfaces"
        ),
        DemoAccount(
            email: "admin@studyforge.test",
            displayName: "StudyForge Admin",
            role: .admin,
            plan: .pro,
            reaches: "the admin area (F12)"
        ),
    ]

    /// The account matching a signed-in address, or `nil` for anything else.
    ///
    /// Used to mark the current session in the switcher. `nil` is a normal answer — a real
    /// account is not one of the four.
    static func account(forEmail email: String?) -> DemoAccount? {
        guard let email else { return nil }
        return all.first { $0.email.caseInsensitiveCompare(email) == .orderedSame }
    }
}
#endif
