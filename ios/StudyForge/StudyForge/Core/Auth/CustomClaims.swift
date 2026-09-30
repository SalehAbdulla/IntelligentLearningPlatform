//
//  CustomClaims.swift
//  StudyForge
//
//  Reads the role, plan and group membership that Firebase Auth puts into the ID token.
//
//  WHY CLAIMS AND NOT A FIRESTORE FIELD
//  ------------------------------------
//  Claims are signed by Firebase and travel with the token, so `firestore.rules` can
//  read them DIRECTLY:
//
//      request.auth.token.role == 'tutor'
//
//  A role stored in a Firestore document could not be checked that way without a
//  second read inside the rule — and, worse, would be a document the client might be
//  able to write. Claims make authorisation enforceable server-side, which is the
//  whole reason the client is never trusted with the decision (docs/05 §5).
//
//  FAIL CLOSED
//  -----------
//  Every default in this file is the LEAST privileged option. A missing, misspelled or
//  malformed claim yields `student` + `free`, never `tutor`. Getting this backwards is
//  a privilege-escalation bug, so it is stated once here and asserted in tests.
//

import Foundation

/// The authorisation facts carried by the ID token.
struct CustomClaims: Sendable, Equatable {

    let role: AppRole
    let plan: SubscriptionPlan
    /// Study-group memberships, used to grant collaborative access.
    let groupIds: [String]

    /// Whether the provider has verified the user's email address.
    ///
    /// This is a **standard** ID-token claim (`email_verified`), not one of our custom
    /// ones, so it is `true` for any account that has completed verification — including
    /// Google sign-in, where the provider vouches for the address. Defaults to `false`
    /// when absent, which is the fail-closed direction: an unverified account is shown
    /// A06 rather than waved through.
    let isEmailVerified: Bool

    /// Explicit init rather than the synthesised memberwise one, so `isEmailVerified` can
    /// default to `false` — the fail-closed direction — without forcing every caller to
    /// restate it.
    init(role: AppRole, plan: SubscriptionPlan, groupIds: [String], isEmailVerified: Bool = false) {
        self.role = role
        self.plan = plan
        self.groupIds = groupIds
        self.isEmailVerified = isEmailVerified
    }

    /// The safe baseline: an authenticated user with no special powers.
    ///
    /// Used when there are no claims at all — for example a brand-new sign-up, whose
    /// claims are only written by the `onUserCreate` Cloud Function afterwards.
    static let leastPrivilege = CustomClaims(
        role: .student,
        plan: .free,
        groupIds: [],
        isEmailVerified: false
    )

    /// Parses the ID token's claim dictionary.
    ///
    /// Unknown or malformed values fall back to `leastPrivilege` rather than throwing:
    /// a user with unusual claims should still be able to sign in and use the app as a
    /// student. Failing the whole sign-in because a claim was unexpected would turn a
    /// permissions problem into an outage.
    static func parse(from claims: [String: Any]) -> CustomClaims {
        CustomClaims(
            role: AppRole(rawValue: string(claims["role"])) ?? .student,
            plan: SubscriptionPlan(rawValue: string(claims["plan"])) ?? .free,
            groupIds: stringArray(claims["groupIds"]),
            isEmailVerified: boolean(claims["email_verified"])
        )
    }

    /// Builds the session these claims describe.
    ///
    /// - Parameter email: supplied by the caller rather than read from the claims, because
    ///   `email` is a claim the token carries only sometimes. The signed-in `User` always
    ///   has it, so that is the reliable source.
    func session(uid: String, displayName: String, email: String) -> UserSession {
        UserSession(
            id: uid,
            displayName: displayName,
            role: role,
            plan: plan,
            groupIds: groupIds,
            email: email,
            isEmailVerified: isEmailVerified
        )
    }

    // MARK: - Defensive readers

    /// Claims arrive as `Any` from the SDK, so each read is typed defensively.
    /// A JSON number, for example, would crash a bare `as? String` cast chain.
    private static func string(_ value: Any?) -> String {
        switch value {
        case let value as String: value
        case let value as NSString: value as String
        default: ""
        }
    }

    /// JSON booleans can arrive as `Bool`, or as `NSNumber` — Swift bridges the latter, so
    /// a token encoding a boolean as a number is still honoured. Anything else is treated
    /// as absent, so the caller's fail-closed default applies rather than a truthy coercion.
    ///
    /// - Note: the bridging is narrower than it looks, and narrower is better here.
    ///   `NSNumber(value: true)` satisfies `as? Bool`, but `Int(1)` boxed in `Any` does
    ///   **not** — so `email_verified: 1` is rejected rather than accepted. Both directions
    ///   are asserted in `CustomClaimsTests`; this was checked rather than assumed.
    private static func boolean(_ value: Any?) -> Bool {
        value as? Bool ?? false
    }

    private static func stringArray(_ value: Any?) -> [String] {
        switch value {
        case let value as [String]: value
        case let value as [Any]: value.compactMap { $0 as? String }
        default: []
        }
    }
}
