//
//  SFSectionHeader.swift
//  StudyForge
//
//  Rule C/E — a grouped-section header that carries hierarchy with type and spacing instead of
//  another card. Replaces the hand-rolled `Text(title).font(.sfSubhead)` pairs scattered across
//  screens, and the trailing action gives a section its "See all" affordance in one place.
//
//  The optional icon is `.monochrome` (Rule E: controls and labels), never `.hierarchical`,
//  which is reserved for hero and empty-state art.
//

import SwiftUI

struct SFSectionHeader: View {

    let title: String

    /// Optional leading SF Symbol. Monochrome, sized by the text style.
    var systemImage: String?

    /// Optional trailing text action, e.g. "See all".
    var actionTitle: String?

    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.sfSubhead)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SFTertiaryButtonStyle())
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Previews

#Preview("Section header — light") {
    VStack(alignment: .leading, spacing: Spacing.s4) {
        SFSectionHeader(title: "Today", systemImage: "calendar")
        SFSectionHeader(title: "Due cards", systemImage: "rectangle.stack", actionTitle: "See all", action: {})
    }
    .padding(Layout.screenMargin)
    .background(ColorTokens.surface)
}

#Preview("Section header — dark (default)") {
    VStack(alignment: .leading, spacing: Spacing.s4) {
        SFSectionHeader(title: "Today", systemImage: "calendar")
        SFSectionHeader(title: "Due cards", systemImage: "rectangle.stack", actionTitle: "See all", action: {})
    }
    .padding(Layout.screenMargin)
    .background(ColorTokens.surface)
    .preferredColorScheme(.dark)
}

#Preview("Section header — AX5") {
    SFSectionHeader(title: "Due cards", systemImage: "rectangle.stack", actionTitle: "See all", action: {})
        .padding(Layout.screenMargin)
        .environment(\.dynamicTypeSize, .accessibility5)
}