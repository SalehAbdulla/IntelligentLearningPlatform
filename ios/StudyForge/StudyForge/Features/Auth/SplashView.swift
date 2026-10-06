//
//  SplashView.swift
//  StudyForge
//
//  A01 — `01_Splash_Logo_{M1}` (docs/03 §A, P0).
//
//  THE POINT OF THIS SCREEN IS THE UNCERTAINTY IT COVERS
//  ----------------------------------------------------
//  Firebase resolves a persisted session asynchronously, so for the first fraction of a
//  second the app genuinely does not know whether the user is signed in. Without a
//  splash, that uncertainty gets rendered as "signed out" and a returning student sees
//  the log-in screen flash before being thrown to their home screen — the most common
//  and most credibility-damaging launch bug in Firebase apps.
//
//  So this view is not decoration. It is what `AuthState.unknown` looks like, and it is
//  why `AppContainer.hasResolvedAuth` exists rather than checking `session == nil`.
//

import SwiftUI

struct SplashView: View {

    /// Announced to VoiceOver. The visual spinner is decorative once this is read.
    private var accessibilityLabelText: String {
        "\(L10n.appName.string). \(L10n.splashTagline.string). \(L10n.splashChecking.string)"
    }

    var body: some View {
        VStack(spacing: Spacing.s6) {

            Spacer()

            VStack(spacing: Spacing.s4) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(ColorTokens.primary)

                Text(L10n.appName.string)
                    .font(.sfDisplayL)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(L10n.splashTagline.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: Spacing.s3) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ColorTokens.primary)

                Text(L10n.splashChecking.string)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .padding(.bottom, Spacing.s12)
        }
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Layout.screenMargin)
        .background(ColorTokens.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
    }
}

// MARK: - Previews

#Preview("A01 Splash") {
    SplashView()
}
