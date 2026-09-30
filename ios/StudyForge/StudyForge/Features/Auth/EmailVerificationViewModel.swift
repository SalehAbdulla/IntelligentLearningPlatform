//
//  EmailVerificationViewModel.swift
//  StudyForge
//
//  Presentation logic for A06 (`06_SignUp_OTP_Verify_{M1}` as designed).
//
//  WHY A RESEND COOLDOWN IS NOT OPTIONAL
//  ------------------------------------
//  Firebase rate-limits verification emails, and the limiter counts ATTEMPTS — not
//  successes. A user who taps "Resend" three times in a row does not get three emails;
//  they get one email and then a `tooManyRequests` failure, which reads as the app being
//  broken at the exact moment they are already frustrated. A visible countdown turns an
//  invisible server-side limit into an expectation the user can see, and it prevents the
//  failure rather than explaining it afterwards.
//
//  WHY CHECKING IS EXPLICIT
//  ------------------------
//  Verification happens in the user's mail client, which this process cannot observe.
//  There is no callback and no notification — the app has to ASK. That is the entire
//  reason the "I've verified — continue" button exists rather than the screen advancing on
//  its own.
//

import Foundation
import Synchronization

@MainActor
@Observable
final class EmailVerificationViewModel {

    /// The address the link was sent to. Shown so a typo is visible rather than mysterious.
    let email: String

    private(set) var isSending = false
    private(set) var isChecking = false
    private(set) var error: AppError?

    /// True briefly after a successful send, to confirm it happened.
    private(set) var didSend = false

    /// True when `checkVerification` came back still-unverified, so the screen can say so
    /// instead of appearing to do nothing.
    private(set) var isStillUnverified = false

    /// Seconds remaining before another send is allowed. Zero means allowed.
    private(set) var resendSecondsRemaining = 0

    private let auth: any AuthService
    private let cooldownSeconds: Int

    /// The countdown task.
    ///
    /// Held behind a `Mutex` and marked `nonisolated` so `deinit` — which is NOT
    /// main-actor isolated — can cancel it. A plain `@MainActor var` cannot be touched
    /// from `deinit` under strict concurrency, and without the cancel a ticking task keeps
    /// its view model alive for the length of the countdown. Same pattern as
    /// `AppContainer.authObservation`.
    private nonisolated let cooldownTask = Mutex<Task<Void, Never>?>(nil)

    /// - Parameter cooldownSeconds: injectable so a test does not have to wait a minute to
    ///   exercise the countdown. Production uses the default.
    init(
        auth: any AuthService,
        email: String,
        cooldownSeconds: Int = 60
    ) {
        self.auth = auth
        self.email = email
        self.cooldownSeconds = cooldownSeconds
    }

    // MARK: Derived state

    var canResend: Bool { resendSecondsRemaining == 0 && !isSending }

    /// The resend button's label: the action, or the countdown that replaces it.
    var resendTitle: String {
        resendSecondsRemaining > 0
            ? L10n.verifyResendIn.string(resendSecondsRemaining)
            : L10n.verifyResend.string
    }

    var isCheckingEnabled: Bool { !isChecking && !isSending }

    // MARK: Actions

    func sendVerification() async {
        guard canResend else { return }

        isSending = true
        error = nil
        didSend = false
        isStillUnverified = false
        defer { isSending = false }

        do {
            try await auth.sendEmailVerification()
            didSend = true
            startCooldown()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Asks the provider whether verification has happened yet.
    ///
    /// On success the refreshed session is emitted on the auth stream and `RootView` routes
    /// onward by itself — this method deliberately does not navigate.
    func checkVerification() async {
        guard isCheckingEnabled else { return }

        isChecking = true
        error = nil
        didSend = false
        isStillUnverified = false
        defer { isChecking = false }

        do {
            let session = try await auth.refreshSession()
            // `!= true` rather than `== false`: a nil session means signed out, which is a
            // different situation but not an error to report here.
            if session?.isEmailVerified != true {
                isStillUnverified = true
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Signs out so the user can sign up again with a corrected address.
    ///
    /// The alternative — leaving them stranded on a verification screen for an address
    /// they mistyped — is the worst outcome of this whole flow.
    func signOut() async {
        try? await auth.signOut()
    }

    // MARK: Cooldown

    private func startCooldown() {
        cooldownTask.withLock { $0?.cancel() }
        resendSecondsRemaining = cooldownSeconds

        let task = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }

                if self.resendSecondsRemaining <= 1 {
                    self.resendSecondsRemaining = 0
                    return
                }
                self.resendSecondsRemaining -= 1
            }
        }
        cooldownTask.withLock { $0 = task }
    }

    deinit {
        // A ticking task outliving its view model would keep a reference alive for the
        // length of the countdown.
        cooldownTask.withLock { $0?.cancel() }
    }
}
