//
//  SFCard.swift
//  StudyForge
//
//  Rule C/G — one card container, so a card is a *surface* decision rather than a per-screen
//  chain of `.padding` + `.background(RoundedRectangle…)` + `.overlay(stroke)`.
//
//  Elevation is carried by surface colour, never by a shadow: `surfaceVariant` sits on
//  `surface`, and `surfaceElevated` sits on `surfaceVariant`. That is what makes the dark
//  appearance read as layered without glow (Rule C).
//

import SwiftUI

struct SFCard<Content: View>: View {

    /// A card layered on another card, or an input well — uses `surfaceElevated`.
    var elevated: Bool

    /// From the spacing ladder. `Spacing.s4` (16) is the default screen margin, so a card's
    /// inner padding and the screen's outer margin agree by default.
    var padding: CGFloat

    private let content: Content

    init(
        elevated: Bool = false,
        padding: CGFloat = Spacing.s4,
        @ViewBuilder content: () -> Content
    ) {
        self.elevated = elevated
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .fill(elevated ? ColorTokens.surfaceElevated : ColorTokens.surfaceVariant)
            )
    }
}

// MARK: - Previews

#Preview("Card — light") {
    VStack(spacing: Spacing.s4) {
        SFCard {
            Text("Today's plan").font(.sfTitleS)
            Text("3 sessions · 45 min").font(.sfFootnote).foregroundStyle(ColorTokens.textSecondary)
        }
        SFCard(elevated: true) {
            Text("Layered card").font(.sfBody)
        }
    }
    .padding(Layout.screenMargin)
    .background(ColorTokens.surface)
}

#Preview("Card — dark (default)") {
    VStack(spacing: Spacing.s4) {
        SFCard {
            Text("Today's plan").font(.sfTitleS)
            Text("3 sessions · 45 min").font(.sfFootnote).foregroundStyle(ColorTokens.textSecondary)
        }
        SFCard(elevated: true) {
            Text("Layered card").font(.sfBody)
        }
    }
    .padding(Layout.screenMargin)
    .background(ColorTokens.surface)
    .preferredColorScheme(.dark)
}

#Preview("Card — AX5") {
    SFCard {
        Text("Today's plan").font(.sfTitleS)
        Text("3 sessions · 45 min").font(.sfFootnote)
    }
    .padding(Layout.screenMargin)
    .environment(\.dynamicTypeSize, .accessibility5)
}
