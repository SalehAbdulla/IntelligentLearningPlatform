//
//  SFChoiceChip.swift
//  StudyForge
//
//  A selectable chip — "Multi-select chips" in docs/06 §5, used first by B01's enrolled
//  courses and again by C09's active-filter row.
//
//  SELECTION IS NOT COLOUR ALONE
//  -----------------------------
//  A selected chip is announced with the `.isSelected` trait, so a screen-reader user
//  hears the state rather than having to infer it from a fill colour. The border weight
//  also changes with selection, for the same reason an error field's border does: colour
//  on its own fails WCAG 1.4.1 for anyone who cannot distinguish these two hues.
//
//  It is a `Button` rather than a `Toggle`, because a row of toggles reads as a settings
//  list with switches; a chip is an inline choice, and the trait is what carries that.
//

import SwiftUI

struct SFChoiceChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sfCaption)
                .lineLimit(1)
                .foregroundStyle(
                    isSelected ? ColorTokens.onPrimaryContainer : ColorTokens.textPrimary
                )
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(
                    isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                    in: .capsule
                )
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? ColorTokens.primary : ColorTokens.outline,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
                // The pill keeps its compact shape; the 44 pt MINIMUM tap area is added
                // around it rather than inside it. Scaling the chip itself to 44 would
                // make a two-word chip look like a button, which is not what the design
                // system's caption-sized chip is for — but an undersized target would
                // fail the same accessibility requirement the sizing note exists for.
                .frame(minHeight: Layout.minTouchTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Previews

#Preview("SFChoiceChip states") {
    VStack(alignment: .leading, spacing: Spacing.s4) {
        HStack(spacing: Spacing.s2) {
            SFChoiceChip(title: "Databases", isSelected: true) {}
            SFChoiceChip(title: "Data Structures", isSelected: false) {}
        }
        // Two lines, to show a selected chip next to a longer unselected one does not
        // stretch either of them.
        HStack(spacing: Spacing.s2) {
            SFChoiceChip(title: "Intro", isSelected: false) {}
            SFChoiceChip(title: "Introduction to Programming", isSelected: true) {}
        }
    }
    .padding(Layout.screenMargin)
}
