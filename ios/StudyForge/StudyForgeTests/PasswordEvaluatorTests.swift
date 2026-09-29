//
//  PasswordEvaluatorTests.swift
//  StudyForgeTests
//
//  Tests for password strength and rule evaluation.
//
//  Worth testing because the sign-up screen renders TWO things from this logic — a
//  strength band and a rule checklist — and they must never contradict each other. A
//  checklist showing every rule ticked beside a meter reading "Weak" is the kind of
//  inconsistency that makes a user distrust the whole form.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Password evaluation")
struct PasswordEvaluatorTests {

    @Test("An empty password is weak with no rules met")
    func emptyIsWeak() {
        #expect(PasswordEvaluator.strength(of: "") == .weak)
        #expect(PasswordEvaluator.rules(for: "").allSatisfy { !$0.isSatisfied })
    }

    @Test("Below the minimum length is always weak, however varied",
          arguments: ["Ab1!", "aA1!bB2", "Xy9#"])
    func shortIsAlwaysWeak(password: String) {
        // Variety must not mask a length failure: a 7-character password with a symbol,
        // a capital and a digit is still trivially brute-forced.
        #expect(password.count < AuthInput.minimumPasswordLength)
        #expect(PasswordEvaluator.strength(of: password) == .weak)
    }

    @Test("A long passphrase with one variety signal is strong, not fair")
    func longPassphraseIsStrong() {
        // The regression this guards: requiring a symbol for `strong` rated this
        // 24-character passphrase *fair* while rating a 12-character one *strong* —
        // composition-rule correct, advice-ally wrong. Length dominates.
        #expect("correct horse battery 1".count >= PasswordEvaluator.longPasswordLength)
        #expect(PasswordEvaluator.strength(of: "correct horse battery 1") == .strong)
    }

    @Test("A short-but-composed password still reaches strong by the composition route")
    func composedShortPasswordIsStrong() {
        // Route 2: at minimum length, both a digit and a symbol.
        #expect(PasswordEvaluator.strength(of: "StudyForge1!") == .strong)
    }

    @Test("Length without any variety signal is only fair")
    func unvariedPasswordIsFair() {
        #expect(PasswordEvaluator.strength(of: "abcdefghijkl") == .fair)
    }

    @Test("Rules report each condition independently")
    func rulesAreIndependent() {
        let rules = PasswordEvaluator.rules(for: "abcdefgh") // long, but no number or symbol

        let length = rules.first { $0.kind == .length }
        let number = rules.first { $0.kind == .number }
        let symbol = rules.first { $0.kind == .symbol }

        #expect(length?.isSatisfied == true)
        #expect(number?.isSatisfied == false)
        #expect(symbol?.isSatisfied == false)
    }

    @Test("All three rule kinds are always returned, in a stable order")
    func ruleListIsCompleteAndStable() {
        // A checklist that grows as the user types is harder to read than one that ticks
        // off, so the count must be constant.
        for password in ["", "a", "abcdefgh", "StudyForge1!"] {
            let kinds = PasswordEvaluator.rules(for: password).map(\.kind)
            #expect(kinds == PasswordRule.Kind.allCases)
        }
    }

    @Test("A passphrase with spaces counts as varied once it has a digit")
    func spacesDoNotCountAsSymbols() {
        // Spaces are deliberately excluded from the symbol rule: a passphrase should not
        // need punctuation to be treated as considered. Length plus a digit is enough.
        #expect(PasswordEvaluator.strength(of: "correct horse battery 1") == .strong)
    }

    @Test("The length rule uses the authoritative minimum, not a copy")
    func lengthRuleTracksAuthInput() {
        // If these two ever diverge, the meter would promise a rule `AuthInput` does not
        // accept — so the rule text must interpolate the real constant.
        let text = PasswordEvaluator.rules(for: "x").first { $0.kind == .length }?.text ?? ""
        #expect(text.contains("\(AuthInput.minimumPasswordLength)"))
    }

    @Test("Strength bands are ordered so the meter can compare them")
    func strengthIsOrdered() {
        #expect(PasswordStrength.weak < PasswordStrength.fair)
        #expect(PasswordStrength.fair < PasswordStrength.strong)
    }

    @Test("Meter fill fractions increase with strength")
    func fractionsIncrease() {
        #expect(PasswordStrength.weak.fraction < PasswordStrength.fair.fraction)
        #expect(PasswordStrength.fair.fraction < PasswordStrength.strong.fraction)
        #expect(PasswordStrength.strong.fraction == 1.0)
    }
}
