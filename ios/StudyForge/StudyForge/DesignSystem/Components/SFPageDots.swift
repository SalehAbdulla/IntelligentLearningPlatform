//
//  SFPageDots.swift
//  StudyForge
//
//  Page indicator for the onboarding pager (A02–A04).
//
//  ACCESSIBILITY NOTES
//  -------------------
//  · Each dot is a 44 pt target even though the dot itself is 8 pt. Apple's minimum, and a
//    WCAG 2.5.8 requirement — a 8 pt tap target is a real failure for anyone with a tremor.
//  · The active dot is not distinguished by colour alone: it is also wider and taller, so
//    the position reads without colour perception (WCAG 1.4.1).
//  · The group announces "Page 2 of 3", which is more useful than "dot 2 of 3" and is the
//    same phrasing the localisable string uses.
//

import SwiftUI

struct SFPageDots: View {

    let count: Int
    let currentIndex: Int

    /// When provided, the dots become buttons. Nil for a display-only indicator.
    var onSelect: ((Int) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Spacing.s1) {
            ForEach(0..<count, id: \.self) { index in
                dot(at: index)
            }
        }
        .accessibilityElement(children: onSelect == nil ? .ignore : .contain)
        .accessibilityLabel(L10n.onboardingPageIndicator.string(currentIndex + 1, count))
    }

    @ViewBuilder
    private func dot(at index: Int) -> some View {
        let isCurrent = index == currentIndex

        let shape = Capsule()
            .fill(isCurrent ? ColorTokens.primary : ColorTokens.outline)
            // Width, not just colour, marks the current page.
            .frame(width: isCurrent ? 22 : 8, height: 8)
            .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)

        if let onSelect {
            Button { onSelect(index) } label: {
                shape.contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.onboardingPageIndicator.string(index + 1, count))
            .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        } else {
            shape
                .accessibilityHidden(true)
                .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: isCurrent)
        }
    }
}

// MARK: - Previews

#Preview("Page dots") {
    @Previewable @State var index = 0

    return VStack(spacing: Spacing.s6) {
        SFPageDots(count: 3, currentIndex: index)
        SFPageDots(count: 3, currentIndex: index, onSelect: { index = $0 })
    }
    .padding(Layout.screenMargin)
}
