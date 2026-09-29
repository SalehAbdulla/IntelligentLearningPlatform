//
//  MockAuthService.swift
//  StudyForge
//
//  A deterministic `AuthService` for previews, unit tests and offline development.
//
//  This is not a test-only stub. With no Firebase project yet — and with the on-device
//  AI tier unavailable in the Simulator — a mock auth service is what keeps the whole
//  app runnable: you can sign in, land on the student spine, and build every screen
//  that depends on a session.
//
//  It shares `AuthInput.validate` with the real implementation on purpose. If the
//  mock had its own rules, a test could pass against validation that production does
//  not have.
//

import Foundation
import Synchronization

final class MockAuthService: AuthService {

    /// Whether the next call succeeds, or fails in a specific way.
    enum Outcome: Sendable {
        case succeed
        case fail(AuthError)
    }

    /// email → password for accounts the mock considers to exist.
    ///
    /// Empty by default, meaning "accept anything well-formed" — the right behaviour
    /// for previews. Tests that need a rejection seed specific accounts.
    private let knownAccounts: [String: String]

    private let broadcaster: AuthStateBroadcaster
    private let latency: Duration
    private let outcome: Mutex<Outcome>

    init(initialState: AuthState = .signedOut,
         latency: Duration = .milliseconds(250),
         outcome: Outcome = .succeed,
         knownAccounts: [String: String] = [:]) {
        self.broadcaster = AuthStateBroadcaster(initial: initialState)
        self.latency = latency
        self.outcome = Mutex(outcome)
        self.knownAccounts = knownAccounts
    }

    // MARK: - AuthService

    func stateChanges() -> AsyncStream<AuthState> {
        broadcaster.stream()
    }

    func currentSession() -> UserSession? {
        broadcaster.current.session
    }

    @discardableResult
    func signUp(email: String, password: String, displayName: String) async throws -> UserSession {
        try AuthInput.validate(email: email, password: password)

        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AuthError.missingDisplayName }

        try await simulateWork()
        try throwIfForced()

        // A mock account is created the way the real one would be: least privilege,
        // with no claims yet — the `onUserCreate` Cloud Function grants anything more.
        let session = CustomClaims.leastPrivilege.session(
            uid: Self.uid(for: email),
            displayName: name
        )
        broadcaster.send(.signedIn(session))
        return session
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> UserSession {
        try AuthInput.validate(email: email, password: password)

        try await simulateWork()
        try throwIfForced()

        let normalised = Self.normalise(email)

        // Only enforce the account list when one was supplied; otherwise accept any
        // well-formed credentials, which is what previews want.
        if !knownAccounts.isEmpty {
            guard let expected = knownAccounts[normalised], expected == password else {
                throw AuthError.wrongCredentials
            }
        }

        let session = CustomClaims.leastPrivilege.session(
            uid: Self.uid(for: normalised),
            displayName: Self.displayName(from: normalised)
        )
        broadcaster.send(.signedIn(session))
        return session
    }

    func signOut() async throws {
        try await simulateWork()
        broadcaster.send(.signedOut)
    }

    func sendPasswordReset(to email: String) async throws {
        // Validates the address but never reveals whether an account exists — the same
        // property the real implementation preserves.
        guard AuthInput.isPlausibleEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AuthError.invalidEmail
        }
        try await simulateWork()
        try throwIfForced()
    }

    // MARK: - Test and preview controls

    /// Forces the next call to fail with `error`. Lets a test exercise the error path
    /// of a screen without inventing a broken account.
    func forceFailure(_ error: AuthError?) {
        outcome.withLock { $0 = error.map(Outcome.fail) ?? .succeed }
    }

    /// Moves straight to a signed-in state, for previews of authenticated screens.
    func seedSignedIn(_ session: UserSession = .preview) {
        broadcaster.send(.signedIn(session))
    }

    // MARK: - Helpers

    private func simulateWork() async throws {
        // Skipped when zero so unit tests run instantly while previews still show
        // realistic loading states.
        guard latency > .zero else { return }
        do {
            try await Task.sleep(for: latency)
        } catch {
            throw AuthError.networkUnavailable
        }
    }

    private func throwIfForced() throws {
        if case .fail(let error) = outcome.withLock({ $0 }) {
            throw error
        }
    }

    private static func normalise(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// A stable, obviously-fake uid. Deterministic so tests can assert on it, and
    /// prefixed so a mock session is never mistaken for a real one in a screenshot.
    private static func uid(for email: String) -> String {
        "mock-uid-\(abs(normalise(email).hashValue % 1_000_000))"
    }

    private static func displayName(from email: String) -> String {
        let local = email.split(separator: "@").first.map(String.init) ?? "Student"
        return local
            .split(whereSeparator: { $0 == "." || $0 == "_" || $0 == "-" })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
