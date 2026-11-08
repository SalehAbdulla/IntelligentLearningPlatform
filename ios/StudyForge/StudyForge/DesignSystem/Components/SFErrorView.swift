//
//  SFErrorView.swift
//  StudyForge
//
//  Rule G — ONE failure state, for a whole screen that could not load.
//
//  This is deliberately distinct from the existing `SFErrorBanner`, which is the *inline* form
//  used above content that did load (e.g. the home screen's plan card). A banner keeps the rest
//  of the screen usable; this replaces a screen that has nothing to show. Two shapes, one
//  vocabulary, because both say "something failed" and only one of them blocks the screen.
//
//  Rule B — the icon is tinted `danger` and the retry button is secondary, so a failure never
//  becomes the loudest control on the screen.
//

import SwiftUI

struct SFErrorView: View {

    let title: String

    /// One sentence on what happened, in the student's terms rather than the error's.
    var message: String?

    var retryTitle: String

    /// Omitted when retrying cannot help (e.g. a permission the student has not granted), in
    /// which case the screen explains rather than offering a button that will fail again.
    var onRetry: (() -> Void)?

    init(
        title: String,
        message: String? = nil,
        retryTitle: String = L10n.commonRetry.string,
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: Spacing.s3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.sfDisplayL)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(ColorTokens.error)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
            }
        } description: {
            if let message {
                Text(message)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        } actions: {
            if let onRetry {
                Button(retryTitle, action: onRetry)
                    .buttonStyle(SFSecondaryButtonStyle())
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Error — light") {
    SFErrorView(
        title: "Couldn't load your decks",
        message: "Check your connection and try again.",
        onRetry: {}
    )
}

#Preview("Error — dark (default)") {
    SFErrorView(
        title: "Couldn't load your decks",
        message: "Check your connection and try again.",
        onRetry: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Error — AX5") {
    SFErrorView(
        title: "Couldn't load your decks",
        message: "Check your connection and try again.",
        onRetry: {}
    )
    .environment(\.dynamicTypeSize, .accessibility5)
}
