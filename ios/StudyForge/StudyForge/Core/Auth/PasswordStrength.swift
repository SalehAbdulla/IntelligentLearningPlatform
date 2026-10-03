//
//  PasswordStrength.swift
//  StudyForge
//
//  Evaluates a password against the rules the UI shows the user.
//
//  WHY THIS IS DOMAIN CODE AND NOT VIEW CODE
//  -----------------------------------------
//  The sign-up screen renders a strength meter AND a live rule checklist. If those were
//  computed inside the view, the checklist and the meter could disagree — "8 characters"
//  ticked while the meter still reads Weak — and neither would be testable without a
//  running UI. Keeping the evaluation here makes it a pure function with a test, and the
//  view becomes a renderer.
//
//  RELATIONSHIP TO `AuthInput`
//  --------------------------
//  `AuthInput.minimumPasswordLength` is the AUTHORITATIVE rule: if the two disagree, the
//  server-facing validation wins and this meter is merely cosmetic. The length rule is
//  therefore read from `AuthInput` rather than restated, so they cannot drift.
//

import Foundation

/// The strength band shown by the meter.
enum PasswordStrength: Int, Comparable, Sendable, CaseIterable {
    case weak = 0
    case fair = 1
    case strong = 2

    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Proportional fill for the meter bar, 0…1.
    var fraction: Double {
        switch self {
        case .weak: 0.34
        case .fair: 0.67
        case .strong: 1.0
        }
    }

    /// Localised label.
    var displayName: String {
        switch self {
        case .weak: L10n.strengthWeak.string
        case .fair: L10n.strengthFair.string
        case .strong: L10n.strengthStrong.string
        }
    }
}

/// One rule shown in the live checklist.
struct PasswordRule: Identifiable, Sendable {

    enum Kind: String, Sendable, CaseIterable {
        case length
        case number
        case symbol
    }

    let kind: Kind
    let isSatisfied: Bool

    var id: String { kind.rawValue }

    /// Localised description. Length interpolates the authoritative minimum.
    var text: String {
        switch kind {
        case .length: L10n.strengthRuleLength.string(AuthInput.minimumPasswordLength)
        case .number: L10n.strengthRuleNumber.string
        case .symbol: L10n.strengthRuleSymbol.string
        }
    }
}

enum PasswordEvaluator {

    /// The three rules, evaluated in a stable order so the checklist never reorders
    /// as the user types.
    static func rules(for password: String) -> [PasswordRule] {
        PasswordRule.Kind.allCases.map { kind in
            PasswordRule(kind: kind, isSatisfied: isSatisfied(kind, by: password))
        }
    }

    /// The strength band.
    ///
    /// Length dominates, which is the NIST position: a long passphrase is strong even with
    /// few character classes. An earlier version of this function required a symbol for
    /// `strong`, which rated `correct horse battery 1` (24 characters) as *fair* while
    /// rating `StudyForge1!` (12 characters) as *strong* — correct by composition rules and
    /// backwards in practice. There are two routes to strong for that reason.
    static func strength(of password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .weak }

        let minimum = AuthInput.minimumPasswordLength

        // Below the minimum is weak regardless of variety: a 7-character password with a
        // symbol is still trivially brute-forced, and variety must not mask that.
        guard password.count >= minimum else { return .weak }

        let hasNumber = isSatisfied(.number, by: password)
        let hasSymbol = isSatisfied(.symbol, by: password)

        // Route 1 — long, with any one variety signal. Favours passphrases.
        if password.count >= longPasswordLength, hasNumber || hasSymbol { return .strong }

        // Route 2 — the classic composition rule at minimum length.
        if hasNumber && hasSymbol { return .strong }

        return .fair
    }

    /// Length at which the variety requirement relaxes to a single signal.
    ///
    /// 16 is the point where the search space is large enough that a passphrase's length
    /// outweighs its lack of symbols.
    static let longPasswordLength = 16

    private static func isSatisfied(_ kind: PasswordRule.Kind, by password: String) -> Bool {
        switch kind {
        case .length:
            password.count >= AuthInput.minimumPasswordLength
        case .number:
            password.contains(where: \.isNumber)
        case .symbol:
            // Anything that is not a letter, a number, or whitespace. Spaces are
            // deliberately excluded: a passphrase should not have to contain a symbol
            // to be treated as considered.
            password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
        }
    }
}
