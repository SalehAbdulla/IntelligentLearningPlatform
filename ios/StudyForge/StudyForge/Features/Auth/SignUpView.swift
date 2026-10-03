//
//  SignUpView.swift
//  StudyForge
//
//  A05 — `05_SignUp_Email_{M1}` (docs/03 §A, P0).
//
//  Deliberately omitted from the design's version of this screen:
//  · **"Continue with Apple"** — see the note in `LoginView`. Its absence is a recorded
//    decision, not an oversight.
//  · A confirm-password field. The reveal toggle already covers "did I typo it?" without
//    doubling the interaction cost, and the design does not call for one.
//

import SwiftUI

struct SignUpView: View {

    @State private var viewModel: SignUpViewModel

    let onLogInInstead: () -> Void

    init(auth: any AuthService, onLogInInstead: @escaping () -> Void) {
        _viewModel = State(initialValue: SignUpViewModel(auth: auth))
        self.onLogInInstead = onLogInInstead
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                header

                if let error = viewModel.error {
                    SFErrorBanner(
                        error: error,
                        onRecover: { Task { await viewModel.submit() } }
                    )
                }

                form

                legal

                SFPrimaryButton(
                    title: L10n.signUpSubmit.string,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } },
                    loadingTitle: L10n.signUpSubmitting.string
                )

                footer
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(L10n.signUpTitle.string)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)

            // This is a privacy claim, not filler: it states where materials go, which is
            // the architecture decision D24 made real.
            Text(L10n.signUpSubtitle.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.s8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {

            SFTextField(
                label: L10n.signUpName.string,
                text: $viewModel.displayName,
                hint: L10n.signUpNameHint.string,
                error: viewModel.displayNameError,
                contentType: .name,
                // Names are capitalised; this is the one field where that is true.
                autocapitalization: .words,
                autocorrectionDisabled: false
            )
            .onChange(of: viewModel.displayName) { _, _ in viewModel.didEdit(.displayName) }

            SFTextField(
                label: L10n.signUpEmail.string,
                text: $viewModel.email,
                placeholder: "you@example.com",
                error: viewModel.emailError,
                keyboard: .emailAddress,
                contentType: .username
            )
            .onChange(of: viewModel.email) { _, _ in viewModel.didEdit(.email) }

            VStack(alignment: .leading, spacing: Spacing.s3) {
                SFPasswordField(
                    label: L10n.signUpPassword.string,
                    text: $viewModel.password,
                    placeholder: "••••••••",
                    hint: L10n.signUpPasswordHint.string(AuthInput.minimumPasswordLength),
                    error: viewModel.passwordError,
                    // `.newPassword` so iOS offers a strong password here, and the saved
                    // one on the log-in screen.
                    contentType: .newPassword,
                    submitLabel: .go,
                    onSubmit: { Task { await viewModel.submit() } }
                )
                .onChange(of: viewModel.password) { _, _ in viewModel.didEdit(.password) }

                // Only once there is something to measure — a meter at zero on an
                // untouched field is noise.
                if !viewModel.password.isEmpty && viewModel.passwordError == nil {
                    SFPasswordStrengthMeter(
                        strength: viewModel.passwordStrength,
                        rules: viewModel.passwordRules
                    )
                }
            }
        }
    }

    private var legal: some View {
        // Rendered as one wrapping sentence — "By continuing you agree to our Terms of
        // Service and Privacy Policy." Splitting it into separate HStacks breaks the word
        // order in Arabic (RTL), so the whole sentence is one attributed string.
        //
        // ⚠️ These are styled as links but are NOT tappable: the documents do not exist
        // yet. Marked here rather than faked with a dead `Link`.
        Text(legalSentence)
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(
                "\(L10n.signUpTermsPrefix.string) \(L10n.signUpTerms.string) "
                + "\(L10n.signUpTermsJoiner.string) \(L10n.signUpPrivacy.string). "
                + L10n.signUpTermsUnavailable.string
            )
    }

    private var legalSentence: AttributedString {
        var sentence = AttributedString(
            "\(L10n.signUpTermsPrefix.string) \(L10n.signUpTerms.string) "
            + "\(L10n.signUpTermsJoiner.string) \(L10n.signUpPrivacy.string)."
        )

        // Styled to read as links; see the note above on why they do not navigate yet.
        for phrase in [L10n.signUpTerms.string, L10n.signUpPrivacy.string] {
            if let range = sentence.range(of: phrase) {
                sentence[range].foregroundColor = ColorTokens.primary
                sentence[range].underlineStyle = .single
            }
        }
        return sentence
    }

    private var footer: some View {
        HStack(spacing: Spacing.s1) {
            Text(L10n.signUpHaveAccount.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            Button(L10n.signUpLogIn.string, action: onLogInInstead)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
                .accessibilityAddTraits(.isButton)
        }
        .padding(.bottom, Spacing.s6)
    }
}

// MARK: - Previews

#Preview("A05 Sign up") {
    SignUpView(auth: MockAuthService(latency: .zero), onLogInInstead: {})
}

#Preview("A05 Sign up — email already registered") {
    let auth = MockAuthService(latency: .zero)
    auth.forceFailure(.emailAlreadyInUse)

    return SignUpView(auth: auth, onLogInInstead: {})
}

