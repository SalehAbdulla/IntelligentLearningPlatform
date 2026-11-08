//
//  SFEmptyStateView.swift
//  StudyForge
//
//  Rule G — ONE empty state. Wraps `ContentUnavailableView` (iOS 17+, and this project targets
//  iOS 26.0, so no fallback is needed) rather than re-drawing an icon and two labels per screen.
//
//  Rule E — hero art uses `.hierarchical` symbol rendering, which is the one context allowed to
//  differ from the `.monochrome` used by controls. Calls that need the system's own search or
//  filter illustration can pass a `ContentUnavailableView` directly; this type exists so the
//  common "nothing here yet" case is one line at the call site.
//

import SwiftUI

struct SFEmptyStateView: View {

    let title: String

    /// One sentence on what would put something here. Sentence case, no marketing voice.
    var message: String?

    var systemImage: String = "tray"

    /// Optional call to action. Omitted when there is genuinely nothing the student can do —
    /// a button that leads nowhere is worse than no button (Rule C).
    var actionTitle: String?

    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .symbolRenderingMode(.hierarchical)
        } description: {
            if let message {
                Text(message)
            }
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SFSecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Previews

#Preview("Empty state — light") {
    SFEmptyStateView(
        title: "No decks yet",
        message: "Generate cards from a material and they will appear here.",
        systemImage: "rectangle.stack",
        actionTitle: "Upload a material",
        action: {}
    )
}

#Preview("Empty state — dark (default)") {
    SFEmptyStateView(
        title: "No decks yet",
        message: "Generate cards from a material and they will appear here.",
        systemImage: "rectangle.stack",
        actionTitle: "Upload a material",
        action: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty state — AX5") {
    SFEmptyStateView(
        title: "No decks yet",
        message: "Generate cards from a material and they will appear here.",
        systemImage: "rectangle.stack"
    )
    .environment(\.dynamicTypeSize, .accessibility5)
}
