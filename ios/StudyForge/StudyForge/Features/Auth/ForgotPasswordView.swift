//
//  ForgotPasswordView.swift
//  StudyForge
//
//  A08 — `08_ForgotPassword_Request_{M1}` (docs/03 §A, P0).
//
//  Two states in one screen: the request form, and the confirmation panel. Kept in one
//  view rather than pushed as a second screen so the back gesture does not return to a
//  form the user has already submitted — which invites a duplicate send.
//

import SwiftUI

struct ForgotPasswordView: View {

    @State private var viewModel: ForgotPasswordViewModel

    let onBackToLogin: () -> Void

    init(auth: any AuthService, onBackToLogin: @escaping () -> Void) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(auth: auth))
        self.onBackToLogin = onBackToLogin
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if viewModel.didSend {
                    confirmation
                } else {
                    requestForm
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Request state

    private var requestForm: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(L10n.forgotTitle.string)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(L10n.forgotSubtitle.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.s8)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if let error = viewModel.error {
                SFErrorBanner(
                    error: error,
                    onRecover: { Task { await viewModel.submit() } }
                )
            }

            SFTextField(
                label: L10n.forgotEmail.string,
                text: $viewModel.email,
                placeholder: "you@example.com",
                error: viewModel.emailError,
                keyboard: .emailAddress,
                contentType: .username,
                submitLabel: .go,
                onSubmit: { Task { await viewModel.submit() } }
            )
            .onChange(of: viewModel.email) { _, _ in viewModel.didEdit(.email) }

            SFPrimaryButton(
                title: L10n.forgotSubmit.string,
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.isSubmitEnabled,
                action: { Task { await viewModel.submit() } },
                loadingTitle: L10n.forgotSubmitting.string
            )
        }
    }

    // MARK: Confirmation state

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(ColorTokens.primary)
                .padding(.top, Spacing.s10)

            Text(L10n.forgotSuccessTitle.string)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)

            // Worded conditionally on purpose — see ForgotPasswordViewModel.
            Text(L10n.forgotSuccessBody.string(viewModel.confirmationEmail))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(
                title: L10n.forgotBackToLogin.string,
                action: onBackToLogin
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Previews

#Preview("A08 Forgot password") {
    NavigationStack {
        ForgotPasswordView(auth: MockAuthService(latency: .zero), onBackToLogin: {})
    }
}
