//
//  SFRadioCard.swift
//  StudyForge
//
//  A single-select card — "Radio card" in docs/06 §5's input inventory. Used first by B02's
//  four learning-style options.
//
//  WHY A CARD AND NOT A ROW OF CHIPS
//  --------------------------------
//  A chip carries a label; these options need a label AND an explanation, because "verbal"
//  or "kinesthetic" mean nothing to a student without one. The card gives each option the
//  room to say what it actually changes, which is what makes the choice answerable rather
//  than a guess — the requirement docs/03 §B puts on B02 specifically.
//
//  Selection is announced with `.isSelected` and shown with a border weight as well as a
//  fill, so it does not depend on colour alone (WCAG 1.4.1) and a screen reader states it
//  rather than leaving it to be inferred.
//

import SwiftUI

struct SFRadioCard: View {

    let title: String

    /// The supporting line. Required rather than optional: a radio card with nothing but a
    /// title is a chip with extra padding, and would let a caller remove the explanation
    /// that justifies this component's existence.
    let detail: String

    let isSelected: Bool

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.s3) {

                // The radio glyph. Decorative: the trait below is what actually announces
                // the state.
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.sfTitleS)
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(title)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Text(detail)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .frame(minHeight: Layout.minTouchTarget)
            .background(
                isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                in: .rect(cornerRadius: Radius.l)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l)
                    .strokeBorder(
                        isSelected ? ColorTokens.primary : ColorTokens.outline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        // One element, one statement: without combining, VoiceOver reads the title, the
        // detail and the glyph as three unrelated fragments.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Previews

#Preview("SFRadioCard states") {
    ScrollView {
        VStack(spacing: Spacing.s3) {
            SFRadioCard(
                title: "Visual",
                detail: "Grouped lists, comparisons, and structure you can picture.",
                isSelected: true
            ) {}

            SFRadioCard(
                title: "Verbal",
                detail: "Explanations that read as if a classmate were talking you through it.",
                isSelected: false
            ) {}

            // Long copy, to prove the card grows instead of truncating at AX sizes.
            SFRadioCard(
                title: "A deliberately long option title to check the card wraps rather than clips",
                detail: "And a supporting line of a similar length, because a card that clips its explanation has removed the reason it is a card and not a chip.",
                isSelected: false
            ) {}
        }
        .padding(Layout.screenMargin)
    }
}
