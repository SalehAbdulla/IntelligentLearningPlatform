//
//  SFPasswordStrengthMeter.swift
//  StudyForge
//
//  The live password strength meter and rule checklist for A05.
//
//  COLOUR USAGE — THE RULE THIS COMPONENT HAD TO RESPECT
//  -----------------------------------------------------
//  docs/06 §1.1: `success` and `accent` are **fill** colours, and their lighter values
//  fail WCAG AA as text. The bar is therefore a fill (safe), while the band LABEL uses
//  `textPrimary` rather than the band colour — colouring the word "Strong" green would
//  put it at ~2.8:1 on a light surface and fail the contrast requirement this design
//  system exists to enforce.
//
//  The band is never communicated by colour alone: the label states it in words and the
//  bar's width encodes it, which is what makes the meter usable with a colour-vision
//  deficiency (WCAG 1.4.1).
//

import SwiftUI

struct SFPasswordStrengthMeter: View {

    let strength: PasswordStrength
    let rules: [PasswordRule]

    private var barColor: Color {
        switch strength {
        case .weak: ColorTokens.error
        case .fair: ColorTokens.warning
        case .strong: ColorTokens.success
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            // Bar and band label
            VStack(alignment: .leading, spacing: Spacing.s2) {
                HStack {
                    Text(L10n.strengthLabel.string)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)

                    Spacer(minLength: Spacing.s2)

                    // Deliberately NOT tinted with the band colour — see the note above.
                    Text(strength.displayName)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ColorTokens.outline)

                        Capsule()
                            .fill(barColor)
                            .frame(width: proxy.size.width * strength.fraction)
                    }
                }
                .frame(height: 6)
                // Decorative: the band is already spoken via the label.
                .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(L10n.strengthLabel.string): \(strength.displayName)")

            // Rule checklist
            VStack(alignment: .leading, spacing: Spacing.s1) {
                ForEach(rules) { rule in
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: rule.isSatisfied ? "checkmark.circle.fill" : "circle")
                            .font(.sfFootnote)
                            .foregroundStyle(
                                rule.isSatisfied ? ColorTokens.successText : ColorTokens.textTertiary
                            )

                        Text(rule.text)
                            .font(.sfFootnote)
                            // Satisfied rules step up to `textPrimary` for emphasis;
                            // unsatisfied stay at `textSecondary`. Both are AA-safe —
                            // `textTertiary` is disabled-only and must never carry text.
                            .foregroundStyle(
                                rule.isSatisfied ? ColorTokens.textPrimary : ColorTokens.textSecondary
                            )
                    }
                    // "8 characters, met" rather than an ambiguous tick glyph.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(rule.text)
                    .accessibilityValue(rule.isSatisfied ? "met" : "not met")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Password strength bands") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            SFPasswordStrengthMeter(
                strength: PasswordEvaluator.strength(of: "abc"),
                rules: PasswordEvaluator.rules(for: "abc")
            )
            SFPasswordStrengthMeter(
                strength: PasswordEvaluator.strength(of: "abcdefgh1"),
                rules: PasswordEvaluator.rules(for: "abcdefgh1")
            )
            SFPasswordStrengthMeter(
                strength: PasswordEvaluator.strength(of: "Password1!"),
                rules: PasswordEvaluator.rules(for: "Password1!")
            )
        }
        .padding(Layout.screenMargin)
    }
}
