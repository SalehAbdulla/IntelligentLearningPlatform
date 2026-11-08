//
//  SFLoadingView.swift
//  StudyForge
//
//  Rule G — ONE loading state. Centred spinner plus an optional sentence.
//
//  The label is not decoration: a bare spinner is silent to VoiceOver unless something says
//  what is happening, so the accessibility label falls back to "Loading…" when the caller does
//  not name the work. `.updatesFrequently` is deliberately NOT used — a determinate progress
//  bar should carry that trait, a spinner should just announce once.
//

import SwiftUI

struct SFLoadingView: View {

    /// What is being loaded, e.g. "Loading your decks…". Optional; falls back to "Loading…".
    var title: String?

    var body: some View {
        VStack(spacing: Spacing.s3) {
            ProgressView()
                .controlSize(.regular)

            if let title {
                Text(title)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title ?? L10n.commonLoading.string)
    }
}

// MARK: - Previews

#Preview("Loading — light") {
    SFLoadingView(title: "Loading your decks…")
        .background(ColorTokens.surface)
}

#Preview("Loading — dark (default)") {
    SFLoadingView(title: "Loading your decks…")
        .background(ColorTokens.surface)
        .preferredColorScheme(.dark)
}

#Preview("Loading — AX5") {
    SFLoadingView(title: "Loading your decks…")
        .environment(\.dynamicTypeSize, .accessibility5)
}
