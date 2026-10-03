//
//  EmailVerificationTests.swift
//  StudyForgeTests
//
//  Tests for A06, the email-verification screen.
//
//  Two things here are load-bearing and easy to get wrong:
//   · the **resend cooldown**, because Firebase's rate limiter counts attempts, so a
//     repeated tap produces a `tooManyRequests` failure rather than more email
//   · **routing on the refreshed claim**, because `email_verified` lives in the ID token
//     and a cached token still reads `false` after the user has clicked the link
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Email verification view model")
@MainActor
struct EmailVerificationViewModelTests {

    /// Builds a view model over a mock that is **already signed in**.
    ///
    /// A06 is only reachable from a signed-in state, and there is no address to send a
    /// verification email to otherwise. A first draft of these tests used the mock's
    /// default signed-out state and got `wrongCredentials` — which is the service behaving
    /// correctly, not a bug.
    private func model(
        auth: MockAuthService,
        cooldown: Int = 60
    ) -> EmailVerificationViewModel {
        auth.seedSignedIn(
            UserSession(
                id: "uid_new",
                displayName: "New Student",
                role: .student,
                plan: .free,
                groupIds: [],
                email: "sara@studyforge.test",
                isEmailVerified: false
            )
        )
        return EmailVerificationViewModel(
            auth: auth,
            email: "sara@studyforge.test",
            cooldownSeconds: cooldown
        )
    }

    @Test("A fresh screen offers the resend immediately, with no countdown")
    func initialState() {
        let viewModel = model(auth: MockAuthService(latency: .zero))

        #expect(viewModel.canResend)
        #expect(viewModel.resendSecondsRemaining == 0)
        #expect(viewModel.resendTitle == L10n.verifyResend.string)
        #expect(viewModel.didSend == false)
        #expect(viewModel.error == nil)
    }

    @Test("Sending starts the cooldown and confirms it happened")
    func sendingStartsTheCooldown() async {
        let viewModel = model(auth: MockAuthService(latency: .zero), cooldown: 60)

        await viewModel.sendVerification()

        #expect(viewModel.didSend)
        #expect(viewModel.error == nil)
        #expect(viewModel.resendSecondsRemaining == 60)
        #expect(viewModel.canResend == false, "a second tap must be blocked")
    }

    @Test("While cooling down, the button label carries the remaining time")
    func labelShowsTheCountdown() async {
        // The label IS the explanation. A separate warning line saying "please wait" beside
        // a disabled button is worse than the button simply stating how long.
        let viewModel = model(auth: MockAuthService(latency: .zero), cooldown: 30)

        await viewModel.sendVerification()

        #expect(viewModel.resendTitle == L10n.verifyResendIn.string(30))
    }

    @Test("A second send during the cooldown is refused, not attempted")
    func rapidTapsAreRefused() async {
        // The property that matters: no second request reaches the provider, so the rate
        // limiter is never tripped in the first place.
        let auth = MockAuthService(latency: .zero)
        let viewModel = model(auth: auth, cooldown: 60)

        await viewModel.sendVerification()
        #expect(viewModel.resendSecondsRemaining == 60)

        // A failure would be forced onto the next call; if the guard works, nothing is
        // called and the error stays nil.
        auth.forceFailure(.tooManyRequests)
        await viewModel.sendVerification()

        #expect(viewModel.error == nil, "the second send should not have been attempted")
        #expect(viewModel.resendSecondsRemaining == 60, "the countdown should be untouched")
    }

    @Test("The countdown actually ticks down and then re-enables resending")
    func countdownExpires() async throws {
        let viewModel = model(auth: MockAuthService(latency: .zero), cooldown: 2)

        await viewModel.sendVerification()
        #expect(viewModel.canResend == false)

        // Real time, because the timer is the thing under test. Kept to ~2s.
        try await Task.sleep(for: .milliseconds(2500))

        #expect(viewModel.resendSecondsRemaining == 0)
        #expect(viewModel.canResend)
        #expect(viewModel.resendTitle == L10n.verifyResend.string)
    }

    @Test("A rate-limit failure is surfaced and does NOT start a cooldown")
    func rateLimitFailure() async {
        // If a failed send started the countdown, the user would be locked out of retrying
        // for a minute after something that never happened.
        let auth = MockAuthService(latency: .zero, outcome: .fail(.tooManyRequests))
        let viewModel = model(auth: auth)

        await viewModel.sendVerification()

        #expect(viewModel.error != nil)
        #expect(viewModel.didSend == false)
        #expect(viewModel.resendSecondsRemaining == 0)
        #expect(viewModel.canResend, "a failure must leave the button usable")
    }

    @Test("Sending with nobody signed in fails rather than claiming success")
    func sendingWhenSignedOutFails() async {
        // Deliberately does NOT use the `model` helper — that signs the mock in, which is
        // exactly the condition this test needs to be false.
        let viewModel = EmailVerificationViewModel(
            auth: MockAuthService(initialState: .signedOut, latency: .zero),
            email: "sara@studyforge.test",
            cooldownSeconds: 60
        )

        await viewModel.sendVerification()

        #expect(viewModel.didSend == false)
        #expect(viewModel.error != nil)
    }
}

@Suite("Email verification routing")
@MainActor
struct EmailVerificationRoutingTests {

    /// Signs up, which is how a real user arrives at A06.
    private func signedUp() async -> MockAuthService {
        let auth = MockAuthService(latency: .zero)
        _ = try? await auth.signUp(
            email: "new@studyforge.test",
            password: "Password1",
            displayName: "New Student"
        )
        return auth
    }

    @Test("A brand-new account is unverified, and carries its email")
    func newAccountIsUnverified() async {
        // This is what makes A06 reachable at all: without it, sign-up would drop the user
        // straight onto a home screen and F01's "verified user" goal would be unenforced.
        let auth = await signedUp()
        let session = auth.currentSession()

        #expect(session?.isEmailVerified == false)
        // The email is on the session so A06 can show which address the link went to.
        #expect(session?.email == "new@studyforge.test")
    }

    @Test("Checking before the link is clicked reports still-unverified, not success")
    func checkingTooEarly() async {
        let auth = await signedUp()
        let viewModel = EmailVerificationViewModel(
            auth: auth,
            email: "new@studyforge.test",
            cooldownSeconds: 60
        )

        await viewModel.checkVerification()

        #expect(viewModel.isStillUnverified)
        #expect(viewModel.error == nil)
        #expect(auth.currentSession()?.isEmailVerified == false)
    }

    @Test("After the link is clicked, checking refreshes the session to verified")
    func checkingAfterClickingSucceeds() async {
        // `simulateVerification` stands in for the click in the mail client — the one event
        // this process cannot observe, which is exactly why the screen polls.
        let auth = await signedUp()
        let viewModel = EmailVerificationViewModel(
            auth: auth,
            email: "new@studyforge.test",
            cooldownSeconds: 60
        )
        auth.simulateVerification()

        await viewModel.checkVerification()

        #expect(viewModel.isStillUnverified == false)
        #expect(auth.currentSession()?.isEmailVerified == true)
    }

    @Test("Checking while signed out is not an error")
    func checkingWhenSignedOut() async {
        // The app is on the signed-out branch already; reporting a failure here would show
        // an error for something the user did not do.
        let viewModel = EmailVerificationViewModel(
            auth: MockAuthService(initialState: .signedOut, latency: .zero),
            email: "nobody@studyforge.test",
            cooldownSeconds: 60
        )

        await viewModel.checkVerification()

        #expect(viewModel.error == nil)
        #expect(viewModel.isStillUnverified)
    }

    @Test("A refresh leaves the rest of the session intact")
    func refreshPreservesTheSession() async {
        // The refresh path rebuilds the session object; losing role or plan here would
        // silently demote a signed-in user.
        let auth = MockAuthService(latency: .zero)
        auth.seedSignedIn(
            UserSession(
                id: "uid_tutor",
                displayName: "Dr Ali",
                role: .tutor,
                plan: .pro,
                groupIds: ["g_1"],
                email: "ali@studyforge.test",
                isEmailVerified: false
            )
        )
        auth.simulateVerification()

        let refreshed = try? await auth.refreshSession()

        #expect(refreshed?.role == .tutor)
        #expect(refreshed?.plan == .pro)
        #expect(refreshed?.groupIds == ["g_1"])
        #expect(refreshed?.email == "ali@studyforge.test")
        #expect(refreshed?.isEmailVerified == true)
    }
}

