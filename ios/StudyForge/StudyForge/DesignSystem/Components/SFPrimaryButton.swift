//
//  SFPrimaryButton.swift
//  StudyForge
//
//  The single call-to-action button.
//
//  THREE THINGS THIS PREVENTS
//  --------------------------
//  1. **Double submission.** A sign-up that takes two seconds invites a second tap, and
//     the second `createUser` fails with `emailAlreadyInUse` — so the user is told their
//     brand-new account already exists. `isLoading` disables the control while the
//     request is in flight, which is a correctness fix, not a nicety.
//  2. **Truncated labels at large type.** The label wraps rather than shrinking, because
//     a CTA whose text is clipped at AX5 is unusable for the people who need AX5.
//  3. **An unlabelled spinner.** While loading, the accessibility label becomes the
//     in-progress message and the button reports `.isButton` plus a busy value, so
//     VoiceOver says what is happening instead of going silent.
//

import SwiftUI

struct SFPrimaryButton: View {

    let title: String

    /// Shows a spinner in place of the label and blocks interaction.
    var isLoading: Bool = false

    /// Caller-driven enablement (e.g. "the form is incomplete").
    var isEnabled: Bool = true

    let action: () -> Void

    /// Loading text, announced while the spinner is showing.
    var loadingTitle: String?

    private var isInteractive: Bool { isEnabled && !isLoading }

    var body: some View {
        // The appearance lives in `SFPrimaryButtonStyle` so this View and a `Button` that
        // applies the style directly (a NavigationLink label, a dialog action) cannot drift
        // apart — same fill, same 50 pt height, same pressed feedback. What this wrapper adds
        // is the asynchronous behaviour: a busy state that blocks the second tap, and one
        // accessibility label that reports it.
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(SFPrimaryButtonStyle(isLoading: isLoading))
        .disabled(!isInteractive)
        // One element, one label — the spinner is decorative once the label carries the
        // meaning.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isLoading ? (loadingTitle ?? title) : title)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isLoading ? L10n.commonLoading.string : "")
    }
}

// MARK: - Previews

#Preview("SFPrimaryButton states") {
    VStack(spacing: Spacing.s4) {
        SFPrimaryButton(title: "Create account") {}
        SFPrimaryButton(title: "Create account", isLoading: true) {}
        SFPrimaryButton(title: "Create account", isEnabled: false) {}
        SFPrimaryButton(
            title: "A deliberately very long button label to prove it wraps instead of clipping"
        ) {}
    }
    .padding(Layout.screenMargin)
}
