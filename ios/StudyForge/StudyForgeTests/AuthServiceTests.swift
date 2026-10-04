//
//  AuthServiceTests.swift
//  StudyForgeTests
//
//  Tests for the mock auth service and the state broadcaster.
//
//  Both exist so that the app is runnable WITHOUT a Firebase project. That makes them
//  load-bearing infrastructure rather than test scaffolding, and worth asserting on:
//  if the broadcaster drops a value, every screen keyed on the session misbehaves, and
//  the cause looks like a SwiftUI bug rather than what it is.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Auth state broadcaster")
struct AuthStateBroadcasterTests {

    @Test("A subscriber receives the current state immediately")
    func lateSubscriberGetsCurrentValue() async {
        let broadcaster = AuthStateBroadcaster(initial: .signedOut)

        var iterator = broadcaster.stream().makeAsyncIterator()
        let first = await iterator.next()

        #expect(first == .signedOut,
                "a late subscriber must not wait for the next change to learn the state")
    }

    @Test("Every subscriber receives a change, not just the first")
    func fansOutToAllSubscribers() async {
        let broadcaster = AuthStateBroadcaster(initial: .signedOut)

        var first = broadcaster.stream().makeAsyncIterator()
        var second = broadcaster.stream().makeAsyncIterator()

        // Both subscribe before the change, so both must receive it.
        #expect(await first.next() == .signedOut)
        #expect(await second.next() == .signedOut)

        broadcaster.send(.signedIn(.preview))

        #expect(await first.next() == .signedIn(.preview))
        #expect(await second.next() == .signedIn(.preview))
    }

    @Test("Re-sending the current state emits nothing")
    func ignoresNoOpChange() async {
        let broadcaster = AuthStateBroadcaster(initial: .signedOut)
        var iterator = broadcaster.stream().makeAsyncIterator()

        #expect(await iterator.next() == .signedOut)

        // If this emitted, the next value would be `.signedOut` rather than the change
        // that follows — so this assertion is what proves the suppression works.
        broadcaster.send(.signedOut)
        broadcaster.send(.signedIn(.preview))

        #expect(await iterator.next() == .signedIn(.preview),
                "a no-op send must not reach subscribers")
    }

    @Test("Finishing ends every stream rather than leaving subscribers waiting")
    func finishEndsStreams() async {
        let broadcaster = AuthStateBroadcaster(initial: .signedOut)
        var iterator = broadcaster.stream().makeAsyncIterator()
        #expect(await iterator.next() == .signedOut)

        broadcaster.finish()

        #expect(await iterator.next() == nil,
                "a finished stream must terminate, not hang a discarded view")
    }

    @Test("current reflects the latest state without subscribing")
    func currentReadsWithoutSubscribing() {
        let broadcaster = AuthStateBroadcaster(initial: .unknown)
        #expect(broadcaster.current == .unknown)

        broadcaster.send(.signedOut)
        #expect(broadcaster.current == .signedOut)
    }
}

// MARK: - Mock service

@Suite("Mock auth service")
struct MockAuthServiceTests {

    @Test("A new account is least privilege, not merely signed in")
    func signUpGrantsLeastPrivilege() async throws {
        let auth = MockAuthService(latency: .zero)

        let session = try await auth.signUp(
            email: "New.Student@StudyForge.test",
            password: "Password1",
            displayName: "New Student"
        )

        #expect(session.role == .student, "sign-up must never grant a higher role")
        #expect(session.plan == .free)
        #expect(session.groupIds.isEmpty)
        #expect(auth.currentSession() == session)
    }

    @Test("Sign-up requires a name, because a tutor has to be able to identify the student")
    func signUpRequiresDisplayName() async {
        let auth = MockAuthService(latency: .zero)

        await #expect(throws: AuthError.missingDisplayName) {
            _ = try await auth.signUp(email: "a@b.co", password: "Password1", displayName: "   ")
        }
    }

    @Test("Invalid input is rejected before any work is done")
    func signUpValidatesInput() async {
        let auth = MockAuthService(latency: .zero)

        await #expect(throws: AuthError.invalidEmail) {
            _ = try await auth.signUp(email: "nonsense", password: "Password1", displayName: "A")
        }
        await #expect(throws: (any Error).self) {
            _ = try await auth.signUp(email: "a@b.co", password: "short", displayName: "A")
        }
    }

    @Test("Sign-in accepts a known account and normalises the email")
    func signInAcceptsKnownAccount() async throws {
        let auth = MockAuthService(
            latency: .zero,
            knownAccounts: ["sara@studyforge.test": "Password1"]
        )

        // Mixed case and padding must still match, because users paste addresses.
        let session = try await auth.signIn(email: "  Sara@StudyForge.Test ", password: "Password1")

        #expect(session.role == .student)
        #expect(auth.currentSession() == session)
    }

    @Test("An unknown account and a wrong password are indistinguishable")
    func signInDoesNotRevealWhetherAnAccountExists() async {
        let auth = MockAuthService(
            latency: .zero,
            knownAccounts: ["sara@studyforge.test": "Password1"]
        )

        // Both must produce the SAME error. Distinguishing them would let anyone
        // confirm whether a student is enrolled — see AuthError.wrongCredentials.
        let unknownAccount = await capturedError {
            _ = try await auth.signIn(email: "nobody@studyforge.test", password: "Password1")
        }
        let wrongPassword = await capturedError {
            _ = try await auth.signIn(email: "sara@studyforge.test", password: "WrongPassword1")
        }

        #expect(unknownAccount == .wrongCredentials)
        #expect(wrongPassword == .wrongCredentials)
    }

    @Test("Signing out clears the session")
    func signOutClearsSession() async throws {
        let auth = MockAuthService(latency: .zero)
        _ = try await auth.signIn(email: "sara@studyforge.test", password: "Password1")
        #expect(auth.currentSession() != nil)

        try await auth.signOut()

        #expect(auth.currentSession() == nil)
    }

    @Test("A forced failure surfaces the configured error and leaves the user signed out")
    func forcedFailureIsHonoured() async {
        let auth = MockAuthService(latency: .zero)
        auth.forceFailure(.networkUnavailable)

        await #expect(throws: AuthError.networkUnavailable) {
            _ = try await auth.signIn(email: "sara@studyforge.test", password: "Password1")
        }
        #expect(auth.currentSession() == nil)
    }

    @Test("A password reset validates the address but never confirms it exists")
    func passwordResetDoesNotConfirmExistence() async throws {
        let auth = MockAuthService(latency: .zero)

        // An unknown address must succeed silently — that is what prevents the screen
        // being used to enumerate accounts.
        try await auth.sendPasswordReset(to: "nobody@studyforge.test")

        await #expect(throws: AuthError.invalidEmail) {
            try await auth.sendPasswordReset(to: "nonsense")
        }
    }

    @Test("A seeded signed-in state is visible without waiting for a change")
    func seededStateIsImmediatelyVisible() {
        let auth = MockAuthService(initialState: .signedIn(.preview), latency: .zero)
        #expect(auth.currentSession() == .preview)
    }

    // MARK: - Helper

    /// Runs an operation and returns the `AuthError` it threw.
    private func capturedError(
        _ operation: () async throws -> Void
    ) async -> AuthError? {
        do {
            try await operation()
            return nil
        } catch let error as AuthError {
            return error
        } catch {
            return nil
        }
    }
}

// MARK: - Display name

@Suite("Display name update")
struct DisplayNameUpdateTests {

    private func signedIn(name: String = "Sara Ali") -> MockAuthService {
        MockAuthService(
            initialState: .signedIn(UserSession(
                id: "uid_test",
                displayName: name,
                role: .student,
                plan: .free,
                groupIds: [],
                email: "sara@studyforge.test",
                isEmailVerified: true
            )),
            latency: .zero
        )
    }

    @Test("Renaming re-emits a session carrying the new name")
    func renamingReEmitsTheSession() async throws {
        let auth = signedIn()

        try await auth.updateDisplayName("  Sara A. Ali  ")

        // Trimmed, and visible through the same accessor every screen reads.
        #expect(auth.currentSession()?.displayName == "Sara A. Ali")
        // The rest of the session is carried over rather than reset.
        #expect(auth.currentSession()?.id == "uid_test")
        #expect(auth.currentSession()?.isEmailVerified == true)
    }

    @Test("The rename reaches a subscriber through the auth stream")
    func renamingIsPublished() async throws {
        let auth = signedIn()
        var iterator = auth.stateChanges().makeAsyncIterator()

        // The current state, emitted on subscription.
        #expect(await iterator.next() != nil)

        try await auth.updateDisplayName("Sara A. Ali")

        #expect(await iterator.next()?.session?.displayName == "Sara A. Ali")
    }

    @Test("A blank name is refused")
    func blankNameIsRefused() async {
        let auth = signedIn()

        await #expect(throws: AuthError.missingDisplayName) {
            try await auth.updateDisplayName("   ")
        }
    }

    @Test("Renaming with nobody signed in is refused")
    func renamingSignedOutIsRefused() async {
        let auth = MockAuthService(initialState: .signedOut, latency: .zero)

        await #expect(throws: AuthError.wrongCredentials) {
            try await auth.updateDisplayName("Sara Ali")
        }
    }
}

