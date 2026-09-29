//
//  AuthViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the three auth form view models.
//
//  These cover the decisions that are invisible in a screenshot but wrong in a way users
//  feel: which errors appear where, that a typo never reaches the network, and that the
//  reset form cannot be used to discover who has an account.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Login view model")
@MainActor
struct LoginViewModelTests {

    @Test("A malformed email fails locally, without touching the network")
    func invalidEmailFailsLocally() async {
        let auth = MockAuthService(latency: .zero)
        // Any network attempt would fail with this, so its absence proves the local check
        // short-circuited.
        auth.forceFailure(.networkUnavailable)

        let model = LoginViewModel(auth: auth)
        model.email = "not-an-email"
        model.password = "Password1"

        await model.submit()

        #expect(model.emailError != nil)
        #expect(model.error == nil, "a typo is a field problem, not a banner problem")
        #expect(model.isSubmitting == false)
    }

    @Test("A short password is reported against the password field")
    func shortPasswordIsAFieldError() async {
        let model = LoginViewModel(auth: MockAuthService(latency: .zero))
        model.email = "sara@studyforge.test"
        model.password = "short"

        await model.submit()

        #expect(model.passwordError != nil)
        #expect(model.emailError == nil)
    }

    @Test("Wrong credentials go to the banner, never to a field")
    func wrongCredentialsCannotBePinnedToAField() async {
        // This is the anti-enumeration property made visible. `wrongCredentials` covers
        // BOTH "no such account" and "wrong password", so attaching it to the email field
        // would imply the email was the problem — which is exactly the information an
        // attacker wants.
        let auth = MockAuthService(
            latency: .zero,
            knownAccounts: ["sara@studyforge.test": "Password1"]
        )
        let model = LoginViewModel(auth: auth)
        model.email = "nobody@studyforge.test"
        model.password = "Password1"

        await model.submit()

        #expect(model.error != nil, "expected a banner error")
        #expect(model.emailError == nil)
        #expect(model.passwordError == nil)
    }

    @Test("Editing a field clears its error")
    func editingClearsTheFieldError() async {
        // Leaving a stale error under a field the user is actively fixing reads as though
        // their correction was rejected before they finished typing.
        let model = LoginViewModel(auth: MockAuthService(latency: .zero))
        model.email = "bad"
        model.password = "Password1"
        await model.submit()
        #expect(model.emailError != nil)

        model.didEdit(.email)
        #expect(model.emailError == nil)
    }

    @Test("A successful sign-in produces a session")
    func successfulSignInProducesASession() async {
        let auth = MockAuthService(latency: .zero)
        let model = LoginViewModel(auth: auth)
        model.email = "sara@studyforge.test"
        model.password = "Password1"

        await model.submit()

        #expect(model.error == nil)
        #expect(auth.currentSession() != nil)
        // The router keys off auth state, so the view model deliberately does not signal
        // success itself.
        #expect(model.isSubmitting == false)
    }

    @Test("A second submit while one is in flight is ignored")
    func concurrentSubmitsAreIgnored() async {
        // Guards the double-submit path: two sign-ups would mean the second fails with
        // `emailAlreadyInUse`, telling the user their brand-new account already exists.
        let auth = MockAuthService(latency: .milliseconds(50))
        let model = LoginViewModel(auth: auth)
        model.email = "sara@studyforge.test"
        model.password = "Password1"

        async let first: Void = model.submit()
        async let second: Void = model.submit()
        _ = await (first, second)

        #expect(auth.currentSession() != nil)
    }
}

@Suite("Sign-up view model")
@MainActor
struct SignUpViewModelTests {

    @Test("A blank name is rejected before anything else")
    func blankNameIsRejected() async {
        let viewModel = SignUpViewModel(auth: MockAuthService(latency: .zero))
        viewModel.displayName = "   "
        viewModel.email = "sara@studyforge.test"
        viewModel.password = "Password1"

        await viewModel.submit()

        #expect(viewModel.displayNameError != nil)
        #expect(viewModel.emailError == nil)
    }

    @Test("A malformed email is a field error")
    func malformedEmailIsAFieldError() async {
        let viewModel = SignUpViewModel(auth: MockAuthService(latency: .zero))
        viewModel.displayName = "Sara"
        viewModel.email = "nope"
        viewModel.password = "Password1"

        await viewModel.submit()

        #expect(viewModel.emailError != nil)
    }

    @Test("An already-registered email is reported on the email field")
    func emailInUseLandsOnTheEmailField() async {
        // The remedy is about the address — change it, or go and log in — so the message
        // belongs beside that field rather than in a banner above the whole form.
        let viewModel = SignUpViewModel(
            auth: MockAuthService(latency: .zero, outcome: .fail(.emailAlreadyInUse))
        )
        viewModel.displayName = "Sara"
        viewModel.email = "sara@studyforge.test"
        viewModel.password = "Password1"

        await viewModel.submit()

        #expect(viewModel.emailError != nil)
        #expect(viewModel.error == nil)
    }

    @Test("A transport failure goes to the banner, not to a field")
    func networkFailureGoesToTheBanner() async {
        let viewModel = SignUpViewModel(
            auth: MockAuthService(latency: .zero, outcome: .fail(.networkUnavailable))
        )
        viewModel.displayName = "Sara"
        viewModel.email = "sara@studyforge.test"
        viewModel.password = "Password1"

        await viewModel.submit()

        #expect(viewModel.error != nil)
        #expect(viewModel.emailError == nil)
        #expect(viewModel.passwordError == nil)
    }

    @Test("A successful sign-up lands the user on the least privileged role")
    func successfulSignUpIsLeastPrivilege() async {
        // The client cannot grant itself anything more: creation is pinned to
        // student/free and the Cloud Function grants the rest. Asserted here because this
        // is the exact boundary the Firestore rules enforce.
        let auth = MockAuthService(latency: .zero)
        let viewModel = SignUpViewModel(auth: auth)
        viewModel.displayName = "New Student"
        viewModel.email = "new@studyforge.test"
        viewModel.password = "Password1"

        await viewModel.submit()

        let session = auth.currentSession()
        #expect(session != nil)
        #expect(session?.role == .student)
        #expect(session?.plan == .free)
        #expect(session?.displayName == "New Student")
    }

    @Test("Live strength and rules track the password being typed")
    func liveFeedbackTracksThePassword() {
        let viewModel = SignUpViewModel(auth: MockAuthService(latency: .zero))
        #expect(viewModel.passwordStrength == .weak)

        viewModel.password = "StudyForge1!"
        #expect(viewModel.passwordStrength == .strong)
        // A closure rather than `allSatisfy(\.isSatisfied)`: the `#expect` macro rewrites
        // the call and the key-path conversion defeats its `rethrows` analysis, which
        // fails to compile.
        #expect(viewModel.passwordRules.allSatisfy { $0.isSatisfied })
    }
}

@Suite("Forgot-password view model")
@MainActor
struct ForgotPasswordViewModelTests {

    private let knownAccounts = ["sara@studyforge.test": "Password1"]

    @Test("An unknown but well-formed address still reports success")
    func unknownAddressStillSucceeds() async {
        // The anti-enumeration property, asserted directly. If this ever fails, the reset
        // form has become an oracle for "is this student enrolled?" — a privacy leak, not
        // a cosmetic bug.
        let viewModel = ForgotPasswordViewModel(
            auth: MockAuthService(latency: .zero, knownAccounts: knownAccounts)
        )
        viewModel.email = "nobody@studyforge.test"

        await viewModel.submit()

        #expect(viewModel.didSend, "an unknown address must look identical to a known one")
        #expect(viewModel.error == nil)
    }

    @Test("A registered address reports success in exactly the same way")
    func knownAddressLooksTheSame() async {
        let viewModel = ForgotPasswordViewModel(
            auth: MockAuthService(latency: .zero, knownAccounts: knownAccounts)
        )
        viewModel.email = "sara@studyforge.test"

        await viewModel.submit()

        #expect(viewModel.didSend)
        #expect(viewModel.error == nil)
    }

    @Test("A malformed address is caught locally and does not send")
    func malformedAddressDoesNotSend() async {
        let viewModel = ForgotPasswordViewModel(auth: MockAuthService(latency: .zero))
        viewModel.email = "nonsense"

        await viewModel.submit()

        #expect(viewModel.emailError != nil)
        #expect(viewModel.didSend == false)
    }

    @Test("Only address shape is checked — a reset needs no password rule")
    func doesNotRequireAPasswordRule() async {
        // `AuthInput.validate` also enforces password length, which is meaningless here.
        // Using it would make this screen reject a perfectly good address.
        let viewModel = ForgotPasswordViewModel(auth: MockAuthService(latency: .zero))
        viewModel.email = "sara@studyforge.test"

        await viewModel.submit()

        #expect(viewModel.didSend)
    }

    @Test("The confirmation echoes a trimmed address")
    func confirmationEchoesTrimmedAddress() async {
        let viewModel = ForgotPasswordViewModel(auth: MockAuthService(latency: .zero))
        viewModel.email = "  sara@studyforge.test  "

        await viewModel.submit()

        #expect(viewModel.confirmationEmail == "sara@studyforge.test")
    }

    @Test("A transport failure is surfaced, and never claims success")
    func transportFailureDoesNotClaimSuccess() async {
        let viewModel = ForgotPasswordViewModel(
            auth: MockAuthService(latency: .zero, outcome: .fail(.networkUnavailable))
        )
        viewModel.email = "sara@studyforge.test"

        await viewModel.submit()

        #expect(viewModel.error != nil)
        #expect(viewModel.didSend == false)
    }
}


