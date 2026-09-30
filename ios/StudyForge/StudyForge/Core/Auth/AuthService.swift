//
//  AuthService.swift
//  StudyForge
//
//  The authentication contract. Firebase is an implementation detail behind it, which
//  is what lets every screen be built, previewed and tested without a Firebase project.
//
//  DEPENDENCY DIRECTION
//  --------------------
//  Nothing above this file imports Firebase. `FirebaseAuthService` is the only place
//  that does, so replacing or mocking auth touches exactly one type.
//

import Foundation

// MARK: - State

/// The authentication state machine. `unknown` is a real state, not a placeholder:
/// Firebase resolves the persisted session asynchronously, and treating "not yet
/// answered" as "signed out" is what causes the classic sign-in flash on launch.
enum AuthState: Sendable, Equatable {
    case unknown
    case signedOut
    case signedIn(UserSession)

    var session: UserSession? {
        if case .signedIn(let session) = self { return session }
        return nil
    }

    /// True once the first answer has arrived, whatever it was.
    var isResolved: Bool { self != .unknown }
}

// MARK: - Errors

/// Authentication failures, in the app's own vocabulary.
enum AuthError: Error, Equatable {

    case invalidEmail
    case weakPassword(reason: String)
    case emailAlreadyInUse

    /// Deliberately covers BOTH "no such account" and "wrong password".
    ///
    /// Firebase merges these, and we keep them merged on purpose: distinguishing them
    /// would let anyone test whether a given student's email is registered, which for a
    /// university app leaks who is enrolled. The cost is a slightly less specific
    /// message, which is the right trade.
    case wrongCredentials

    case userDisabled
    case tooManyRequests
    case networkUnavailable
    /// The sign-in method is not enabled in the project (e.g. Email/Password, Apple).
    case methodNotEnabled
    case missingDisplayName
    case unknown(underlying: String)

    /// Maps to the app's single user-facing error type so no screen sees a raw
    /// `AuthError` or a Firebase code (docs/04 §8).
    var asAppError: AppError {
        switch self {
        case .invalidEmail:
            .authInvalidInput(reason: "That doesn't look like an email address.")
        case .weakPassword(let reason):
            .authInvalidInput(reason: reason)
        case .missingDisplayName:
            .authInvalidInput(reason: "Please enter your name so your tutor can identify you.")
        case .emailAlreadyInUse:
            .authInvalidInput(reason: "An account already exists for that email. Try signing in instead.")
        case .wrongCredentials:
            .authFailed(reason: "We couldn't find an account with those details.")
        case .userDisabled:
            .notPermitted
        case .tooManyRequests:
            .authFailed(reason: "Too many attempts. Please wait a few minutes and try again.")
        case .networkUnavailable:
            .offline
        case .methodNotEnabled:
            .server(reference: "auth-method-disabled")
        case .unknown:
            .unknown
        }
    }
}

// MARK: - The contract

/// An authentication provider.
///
/// Conformers are `Sendable` because sign-in work runs off the main actor; only the
/// resulting state hops back.
protocol AuthService: Sendable {

    /// Emits the current state immediately, then every subsequent change.
    ///
    /// A stream rather than a callback so that a view model cannot leak a closure into
    /// a longer-lived object — the subscription's lifetime stays explicit.
    func stateChanges() -> AsyncStream<AuthState>

    /// The current session, or `nil`. Synchronous because callers already hold the
    /// stream's latest value; this is for one-off reads.
    func currentSession() -> UserSession?

    @discardableResult
    func signUp(email: String, password: String, displayName: String) async throws -> UserSession

    @discardableResult
    func signIn(email: String, password: String) async throws -> UserSession

    func signOut() async throws

    /// Sends a reset email. Deliberately does NOT report whether the address exists —
    /// see `AuthError.wrongCredentials`.
    func sendPasswordReset(to email: String) async throws

    /// Sends the email-verification message to the currently signed-in user.
    ///
    /// - Throws: `AuthError.tooManyRequests` if Firebase's rate limiter rejects it. A
    ///   caller MUST surface that distinctly rather than retrying, because the limiter
    ///   makes repeated attempts worse, not better.
    /// - Throws: `AuthError.wrongCredentials` if nobody is signed in — there is no
    ///   address to send to.
    func sendEmailVerification() async throws

    /// Reloads the user from the provider and re-emits auth state.
    ///
    /// WHY THIS EXISTS
    /// `emailVerified` flips **server-side**, when the user clicks a link in their inbox —
    /// something this process cannot observe. Without an explicit reload the app would
    /// keep showing A06 to a user who has already verified, until the token happened to
    /// refresh on its own.
    ///
    /// - Returns: the refreshed session, or `nil` if reloading found nobody signed in.
    /// - Note: the resulting state is also emitted on `stateChanges()`, so `RootView`
    ///   routes onward without the caller having to pass the result anywhere.
    @discardableResult
    func refreshSession() async throws -> UserSession?
}

// MARK: - Shared input validation

/// Credential rules, shared by every `AuthService`.
///
/// A separate type rather than a protocol extension, for two reasons:
///  · static members declared in a protocol extension cannot be called on the
///    existential metatype, so `AuthService.validate(...)` does not compile;
///  · validation is not part of the SERVICE contract — it is an input rule that the
///    real service and the mock both happen to share, which is exactly what keeps them
///    from drifting apart.
enum AuthInput {

    /// Minimum password length.
    ///
    /// Firebase accepts 6; we require 8. A client rule stricter than the server's is
    /// safe — the server would accept it anyway — and is the difference between an
    /// assessed security posture and a passed-through default.
    static let minimumPasswordLength = 8

    /// Validates input before any network call.
    ///
    /// Checking locally gives the user an instant answer instead of a round trip that
    /// was always going to fail.
    static func validate(email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isPlausibleEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }
        guard password.count >= minimumPasswordLength else {
            throw AuthError.weakPassword(
                reason: "Use at least \(minimumPasswordLength) characters so your account stays secure."
            )
        }
    }

    /// Structural check only.
    ///
    /// Deliberately NOT a full RFC 5322 regex: those reject valid addresses, and the
    /// only authority on whether an address works is whether mail arrives. This catches
    /// typos, which is all it should try to do.
    static func isPlausibleEmail(_ email: String) -> Bool {
        guard !email.contains(" "), email.count >= 5 else { return false }
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }

        let local = parts[0]
        let domain = parts[1]
        guard !local.isEmpty, !domain.isEmpty else { return false }

        return domain.contains(".")
            && !domain.hasPrefix(".")
            && !domain.hasSuffix(".")
    }
}


