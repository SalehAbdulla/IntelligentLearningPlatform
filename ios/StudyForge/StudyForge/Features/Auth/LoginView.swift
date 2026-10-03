//
//  LoginView.swift
//  StudyForge
//
//  A07 — `07_Login_{M1}` (docs/03 §A, P0).
//
//  Deferred from the design, deliberately:
//   · **"Continue with Apple"** — shipping a third-party sign-in obliges us to offer
//     Sign in with Apple under App Store Guideline 4.8, which needs a paid Apple
//     Developer account. Omitted rather than shown disabled: a dead social button is a
//     visible defect in a demo, and this app currently has no social sign-in at all.
//   · **Face ID** — needs `LocalAuthentication` plus Keychain credential storage, and a
//     considered decision about what is stored. Deferred to P1; the design's intent is
//     recorded here so it is not silently dropped.
//

import SwiftUI

struct LoginView: View {

    @State private var viewModel: LoginViewModel

    /// Raised when the user wants the reset flow instead.
    let onForgotPassword: () -> Void

    /// Raised when the user needs an account.
    let onCreateAccount: () -> Void

    init(
        auth: any AuthService,
        onForgotPassword: @escaping () -> Void,
        onCreateAccount: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: LoginViewModel(auth: auth))
        self.onForgotPassword = onForgotPassword
        self.onCreateAccount = onCreateAccount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                header

                if let error = viewModel.error {
                    SFErrorBanner(
                        error: error,
                        // Only offer a retry where retrying could plausibly work. The
                        // banner itself decides, via AppError.recoveryAction.
                        onRecover: { Task { await viewModel.submit() } }
                    )
                }

                form

                SFPrimaryButton(
                    title: L10n.loginSubmit.string,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } },
                    loadingTitle: L10n.loginSubmitting.string
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
            Text(L10n.loginTitle.string)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(L10n.loginSubtitle.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.s8)
        // One heading announcement instead of two loose lines.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {

            SFTextField(
                label: L10n.loginEmail.string,
                text: $viewModel.email,
                placeholder: "you@example.com",
                error: viewModel.emailError,
                keyboard: .emailAddress,
                contentType: .username,
                submitLabel: .next
            )
            .onChange(of: viewModel.email) { _, _ in viewModel.didEdit(.email) }

            SFPasswordField(
                label: L10n.loginPassword.string,
                text: $viewModel.password,
                placeholder: "••••••••",
                error: viewModel.passwordError,
                contentType: .password,
                submitLabel: .go,
                onSubmit: { Task { await viewModel.submit() } }
            )
            .onChange(of: viewModel.password) { _, _ in viewModel.didEdit(.password) }

            Button(L10n.loginForgot.string, action: onForgotPassword)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
                .accessibilityAddTraits(.isButton)
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.s1) {
            Text(L10n.loginNoAccount.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            Button(L10n.loginCreateAccount.string, action: onCreateAccount)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
                .accessibilityAddTraits(.isButton)
        }
        .padding(.bottom, Spacing.s6)
    }
}

// MARK: - Previews

#Preview("A07 Log in") {
    LoginView(
        auth: MockAuthService(latency: .zero),
        onForgotPassword: {},
        onCreateAccount: {}
    )
}

#Preview("A07 Log in — wrong credentials") {
    let auth = MockAuthService(latency: .zero)
    auth.forceFailure(.wrongCredentials)

    return LoginView(auth: auth, onForgotPassword: {}, onCreateAccount: {})
}

#Preview("A07 Log in — offline") {
    let auth = MockAuthService(latency: .zero)
    auth.forceFailure(.networkUnavailable)

    return LoginView(auth: auth, onForgotPassword: {}, onCreateAccount: {})
}
