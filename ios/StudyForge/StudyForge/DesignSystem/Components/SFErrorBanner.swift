//
//  SFErrorBanner.swift
//  StudyForge
//
//  Inline error presentation for a form.
//
//  WHY A BANNER AND NOT AN ALERT
//  -----------------------------
//  An alert steals focus, demands a dismissal, and hides the form the user needs to
//  correct. "Wrong password" is not an interruption — it is feedback on the thing right
//  in front of them. The banner sits above the form and leaves the fields reachable.
//
//  It renders an `AppError` rather than a string, so every failure in the app already
//  has a title, an explanation and a suggested next action — the screen adds no copy
//  of its own (docs/04 §8: never surface a raw server string).
//

import SwiftUI

struct SFErrorBanner: View {

    let error: AppError

    /// Called when the user taps the recovery affordance, when `AppError` suggests one.
    var onRecover: (() -> Void)?

    /// Optional override for the action label; defaults to the error's own suggestion.
    var recoverTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {

            Label {
                Text(error.title)
                    .font(.sfBodyEmph)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(ColorTokens.error)

            Text(error.message)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Only offer a retry when the app knows one is worth attempting. A "Try
            // again" on a validation error just repeats the same failure.
            if let onRecover, let label = recoverTitle ?? error.recoveryAction {
                Button(label, action: onRecover)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.error.opacity(0.10), in: .rect(cornerRadius: Radius.m))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m)
                .strokeBorder(ColorTokens.error.opacity(0.35), lineWidth: 1)
        }
        // Announced as one statement. Without this, VoiceOver reads a shake of icon,
        // title, body and button as four unrelated fragments.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(error.title). \(error.message)")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Previews

#Preview("SFErrorBanner") {
    ScrollView {
        VStack(spacing: Spacing.s4) {
            SFErrorBanner(error: .authFailed(reason: "We couldn't find an account with those details."))
            SFErrorBanner(
                error: .offline,
                onRecover: {}
            )
            SFErrorBanner(
                error: .authInvalidInput(reason: "An account already exists for that email. Try signing in instead."),
                onRecover: {},
                recoverTitle: "Log in instead"
            )
        }
        .padding(Layout.screenMargin)
    }
}
