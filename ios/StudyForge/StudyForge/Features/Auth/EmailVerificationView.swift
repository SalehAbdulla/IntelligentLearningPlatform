//
//  EmailVerificationView.swift
//  StudyForge
//
//  A06 — the verification step, designed as `06_SignUp_OTP_Verify_{M1}` (docs/03 §A, P0).
//
//  DEVIATION FROM THE DESIGN, RECORDED HERE
//  ----------------------------------------
//  The frame specifies a **6-box OTP input**. Firebase email/password authentication has no
//  OTP step — it sends a link, not a code — and a real code would mean either phone auth
//  (SMS, per-message cost, a Billable dependency) or a custom service on Cloud Functions
//  (Blaze, which D24 exists to avoid).
//
//  So this screen keeps the *purpose* of A06 — prove the user controls the address before
//  letting them through — and changes the mechanism to the one Firebase actually provides.
//  docs/02 and docs/03 should be updated to match rather than left contradicting the app.
//
//  It is deliberately a STATUS screen with a refresh action rather than an input screen:
//  the verification click happens in a mail client this process cannot observe, so the user
//  must be able to say "I've done it, check now".
//

import SwiftUI

struct EmailVerificationView: View {

    @State private var viewModel: EmailVerificationViewModel

    init(auth: any AuthService, email: String) {
        _viewModel = State(initialValue: EmailVerificationViewModel(auth: auth, email: email))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(ColorTokens.primary)
                    .padding(.top, Spacing.s10)
                    .accessibilityHidden(true)

                heading

                if let error = viewModel.error {
                    SFErrorBanner(
                        error: error,
                        onRecover: { Task { await viewModel.checkVerification() } }
                    )
                }

                // Shown when a check came back negative, so the button does not appear to
                // have done nothing at all.
                if viewModel.isStillUnverified {
                    stillUnverifiedNotice
                }

                if viewModel.didSend {
                    Label(L10n.verifyResendSent.string, systemImage: "checkmark.circle.fill")
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.successText)
                        .accessibilityElement(children: .combine)
                }

                actions

                Text(L10n.verifySpamHint.string)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                signOutButton
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
    }

    // MARK: Sections

    private var heading: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(L10n.verifyTitle.string)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // The address is interpolated so a typo is immediately VISIBLE — a mistyped
            // address is the most common reason a verification email never arrives, and it
            // is invisible if the screen just says "check your inbox".
            Text(L10n.verifyBody.string(viewModel.email))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var stillUnverifiedNotice: some View {
        SFErrorBanner(
            error: .authFailed(reason: L10n.verifyNotYetBody.string),
            onRecover: { Task { await viewModel.checkVerification() } },
            recoverTitle: L10n.verifyCheckNow.string
        )
    }

    private var actions: some View {
        VStack(spacing: Spacing.s4) {
            // The primary action is CHECKING, not resending. A user who has already clicked
            // the link wants to get in; making them resend first would send a second email
            // they do not need.
            SFPrimaryButton(
                title: L10n.verifyCheckNow.string,
                isLoading: viewModel.isChecking,
                isEnabled: viewModel.isCheckingEnabled,
                action: { Task { await viewModel.checkVerification() } },
                loadingTitle: L10n.verifyChecking.string
            )

            // Secondary. During the cooldown the LABEL carries the remaining time rather
            // than a separate warning line — one element, one message, and the disabled
            // state explains itself without extra copy.
            Button {
                Task { await viewModel.sendVerification() }
            } label: {
                Text(viewModel.resendTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(
                        viewModel.canResend ? ColorTokens.primary : ColorTokens.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canResend)
            .accessibilityAddTraits(.isButton)
        }
    }

    private var signOutButton: some View {
        Button {
            Task { await viewModel.signOut() }
        } label: {
            Text(L10n.verifyWrongAddress.string)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .padding(.bottom, Spacing.s6)
    }
}

// MARK: - Previews

#Preview("A06 Verify email") {
    EmailVerificationView(
        auth: MockAuthService(latency: .zero),
        email: "sara@studyforge.test"
    )
}

#Preview("A06 Verify email — rate limited") {
    let auth = MockAuthService(latency: .zero)
    auth.forceFailure(.tooManyRequests)

    return EmailVerificationView(auth: auth, email: "sara@studyforge.test")
}

