//
//  FirebaseAuthService.swift
//  StudyForge
//
//  The only file in the app that talks to Firebase Authentication.
//
//  It works against a real project AND against the local emulator without changing a
//  line, because it never decides which one it is talking to — `FirebaseBootstrap`
//  already pointed the SDK at one or the other at launch.
//
//  TWO SECURITY PROPERTIES WORTH KEEPING
//  -------------------------------------
//  1. **Claims, not documents.** The role arrives in the ID token, so `firestore.rules`
//     can enforce it directly. The client reads claims to decide what to SHOW; it never
//     decides what is ALLOWED.
//  2. **Missing claims mean least privilege.** A brand-new account has no claims until
//     the `onUserCreate` function writes them. Until then the user is a free student,
//     never something more.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Synchronization

/// A reference box around the claims cache.
///
/// `Mutex` is `~Copyable`, so it cannot be passed as a parameter or captured by an
/// escaping closure without ownership annotations. Wrapping it in a small `Sendable`
/// reference type keeps the auth listener free to capture it — which is what lets the
/// listener avoid capturing `self` during initialisation.
private final class ClaimsBox: @unchecked Sendable {
    private let mutex = Mutex(CustomClaims.leastPrivilege)

    var claims: CustomClaims {
        get { mutex.withLock { $0 } }
        set { mutex.withLock { $0 = newValue } }
    }
}

/// - Note: `@unchecked Sendable` is required here, not cosmetic. The Firebase SDK does
///   not annotate `Firestore` or the auth-listener handle as `Sendable`, although both
///   are documented as safe for concurrent use. The unchecked conformance is confined
///   to those two SDK-owned references: every piece of state this class actually owns
///   is guarded by a `Mutex`.
final class FirebaseAuthService: AuthService, @unchecked Sendable {

    private let broadcaster: AuthStateBroadcaster
    private let firestore: Firestore

    /// The last resolved claims.
    ///
    /// Claims live in the ID token, which can only be read asynchronously, but
    /// `currentSession()` must be synchronous. Caching is the bridge — and because the
    /// cache starts at `leastPrivilege`, an early read under-reports permissions rather
    /// than over-reporting them.
    private let claimsBox: ClaimsBox

    private let listenerHandle: AuthStateDidChangeListenerHandle

    /// The collection holding one document per user. Named here once so the Cloud
    /// Functions and rules can be grepped against it.
    static let usersCollection = "users"

    init(firestore: Firestore = Firestore.firestore()) {
        let broadcaster = AuthStateBroadcaster()
        let claimsBox = ClaimsBox()

        self.broadcaster = broadcaster
        self.firestore = firestore
        self.claimsBox = claimsBox

        // Deliberately captures only LOCALS, never `self`: this listener fires
        // synchronously during initialisation, before the instance is fully formed.
        // Capturing `self` here compiles in some Swift versions and then crashes.
        //
        // `FirebaseAuth.User` is NOT `Sendable`, so the raw object cannot cross into the
        // task below — under Swift 6 that is a data-race error, not a warning. The
        // Sendable facts are copied out here and the token is re-read inside the task.
        self.listenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            let uid = user?.uid
            let name = user?.displayName
            let email = user?.email

            Task {
                await Self.publish(
                    uid: uid,
                    displayName: name,
                    email: email,
                    to: broadcaster,
                    claims: claimsBox
                )
            }
        }
    }

    deinit {
        Auth.auth().removeStateDidChangeListener(listenerHandle)
    }

    // MARK: - AuthService

    func stateChanges() -> AsyncStream<AuthState> {
        broadcaster.stream()
    }

    func currentSession() -> UserSession? {
        guard let user = Auth.auth().currentUser else { return nil }
        return claimsBox.claims.session(
            uid: user.uid,
            displayName: Self.displayName(for: user),
            email: user.email ?? ""
        )
    }

    @discardableResult
    func signUp(email: String, password: String, displayName: String) async throws -> UserSession {
        try AuthInput.validate(email: email, password: password)

        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AuthError.missingDisplayName }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user

            // The display name lives on the Auth record so other surfaces (and the
            // tutor roster) can show it without reading Firestore.
            let change = user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()

            try await writeUserProfile(uid: user.uid, email: email, displayName: name)

            // Claims do not exist yet — the `onUserCreate` function writes them — so this
            // returns least privilege, which is the correct and safe answer.
            return await activate(user)
        } catch {
            throw Self.map(error)
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> UserSession {
        try AuthInput.validate(email: email, password: password)

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return await activate(result.user)
        } catch {
            throw Self.map(error)
        }
    }

    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw Self.map(error)
        }
    }

    func updateDisplayName(_ displayName: String) async throws {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AuthError.missingDisplayName }
        guard let user = Auth.auth().currentUser else { throw AuthError.wrongCredentials }

        do {
            // The Auth record first: it is what `UserSession.displayName` is read from, so
            // this is the half that makes the app show the new name.
            let change = user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()

            // Then the document, so a tutor roster (and anything else reading `users/{uid}`)
            // does not keep the old name. Only these two fields, deliberately: re-sending
            // `role` or `plan` would be rejected by `keeps()` for anyone who is not a free
            // student, and this is not the sign-up path.
            try await firestore
                .collection(Self.usersCollection)
                .document(user.uid)
                .setData(
                    ["displayName": name, "updatedAt": FieldValue.serverTimestamp()],
                    merge: true
                )
        } catch {
            throw Self.map(error)
        }

        // Re-emit, so the caller and every observer see the new name immediately rather than
        // at the next token refresh. `activate` re-reads the claims — unchanged by a rename,
        // but re-reading them is what publishes the state.
        _ = await activate(user)
    }

    func sendPasswordReset(to email: String) async throws {
        guard AuthInput.isPlausibleEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AuthError.invalidEmail
        }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw Self.map(error)
        }
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            // No signed-in user means no address to verify. Surfaced rather than ignored,
            // so a screen can never report "sent" when nothing was.
            throw AuthError.wrongCredentials
        }
        do {
            try await user.sendEmailVerification()
        } catch {
            throw Self.map(error)
        }
    }

    @discardableResult
    func refreshSession() async throws -> UserSession? {
        guard let user = Auth.auth().currentUser else {
            // Nobody signed in. Not an error: the app is already on the signed-out branch
            // and the observer will have said so.
            return nil
        }

        do {
            // BOTH steps are required, and omitting the second is the bug that makes this
            // screen feel broken:
            //
            //  · `reload()` refreshes the user PROFILE, which is where `isEmailVerified`
            //    lives.
            //  · forcing the ID token re-issues the TOKEN, which is where the
            //    `email_verified` CLAIM is read from. A cached token still says
            //    `false` — so without this, a user who has just clicked the link in their
            //    inbox would be shown A06 again, and would conclude the app is broken.
            try await user.reload()
            try await Self.forceTokenRefresh(for: user)
        } catch {
            throw Self.map(error)
        }

        // `activate` re-reads claims (now fresh), caches them, and re-emits onto
        // `stateChanges()` — which is how `RootView` routes onward without this method
        // having to navigate.
        return await activate(user)
    }
}

// MARK: - State resolution

extension FirebaseAuthService {

    /// Resolves claims, caches them, publishes the state, and returns the session.
    ///
    /// Called after an explicit sign-in so the CALLER receives the real role straight
    /// away. Returning the cached least-privilege session here would briefly show a
    /// returning tutor the student interface.
    private func activate(
        _ user: FirebaseAuth.User,
        forcingRefresh: Bool = false
    ) async -> UserSession {
        let claims = await Self.resolveClaims(forcingRefresh: forcingRefresh)
        claimsBox.claims = claims

        let session = claims.session(
            uid: user.uid,
            displayName: Self.displayName(for: user),
            email: user.email ?? ""
        )
        broadcaster.send(.signedIn(session))
        return session
    }

    /// Publishes state for the account Firebase reported.
    ///
    /// Static and `self`-free so the auth state listener can call it during
    /// initialisation, before the instance is fully formed. `fileprivate` because
    /// `ClaimsBox` is an implementation detail of this file.
    ///
    /// Takes primitives rather than a `FirebaseAuth.User` for the concurrency reason
    /// described at the call site.
    fileprivate static func publish(
        uid: String?,
        displayName: String?,
        email: String?,
        to broadcaster: AuthStateBroadcaster,
        claims box: ClaimsBox
    ) async {
        guard let uid else {
            box.claims = .leastPrivilege
            broadcaster.send(.signedOut)
            return
        }

        let resolved = await resolveClaims()
        box.claims = resolved
        broadcaster.send(
            .signedIn(
                resolved.session(
                    uid: uid,
                    displayName: name(from: displayName, email: email),
                    email: email ?? ""
                )
            )
        )
    }

    /// Reads the signed claims from the current user's ID token.
    ///
    /// Re-reads `Auth.auth().currentUser` rather than taking a user argument, because
    /// `FirebaseAuth.User` is not `Sendable` and cannot be captured into the listener's
    /// task. The uid captured at notification time identifies the account; this only
    /// fetches its token.
    ///
    /// A failure yields `leastPrivilege` rather than throwing: a token we cannot read is
    /// a reason to grant LESS, never to lock the user out of the app entirely.
    ///
    /// - Parameter forcingRefresh: re-issues the ID token instead of serving the cached
    ///   one. Required after email verification — see `refreshSession()`.
    fileprivate static func resolveClaims(forcingRefresh: Bool = false) async -> CustomClaims {
        guard let user = Auth.auth().currentUser else { return .leastPrivilege }
        do {
            let result = try await user.getIDTokenResult(forcingRefresh: forcingRefresh)
            return CustomClaims.parse(from: result.claims)
        } catch {
            return .leastPrivilege
        }
    }

    /// Forces an ID-token refresh, bridging the SDK's completion-handler API.
    ///
    /// Written by hand rather than using an SDK async overload, because there is not one
    /// for this method: calling `try await user.getIDTokenForcingRefresh(true)` fails to
    /// compile with *"missing argument for parameter 'completion'"*. The continuation form
    /// is explicit about that and does not depend on which overloads a given SDK build
    /// happens to generate.
    ///
    /// - Note: the return value is discarded deliberately. What matters is the side effect
    ///   — the token, and therefore the `email_verified` claim, is re-issued.
    private static func forceTokenRefresh(for user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            user.getIDTokenForcingRefresh(true) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// A display name, falling back to the local part of the email.
    static func name(from displayName: String?, email: String?) -> String {
        if let displayName, !displayName.isEmpty { return displayName }
        return email?.split(separator: "@").first.map(String.init) ?? "Student"
    }

    static func displayName(for user: FirebaseAuth.User) -> String {
        name(from: user.displayName, email: user.email)
    }
}
// MARK: - Profile document

extension FirebaseAuthService {

    /// Creates the user's Firestore profile.
    ///
    /// `merge: true` so a retry after a partial failure cannot wipe a field a Cloud
    /// Function added in between — the failure mode of a blind overwrite here is a user
    /// silently losing their plan.
    ///
    /// Note the asymmetry that makes this safe: the DOCUMENT is a convenience for
    /// display and joins, while the CLAIMS are what authorisation reads. Nothing this
    /// function writes grants a capability, so a client that lies here gains nothing.
    private func writeUserProfile(uid: String, email: String, displayName: String) async throws {
        let profile: [String: Any] = [
            "displayName": displayName,
            "email": email.lowercased(),
            "role": AppRole.student.rawValue,
            "plan": SubscriptionPlan.free.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        try await firestore
            .collection(Self.usersCollection)
            .document(uid)
            .setData(profile, merge: true)
    }
}

// MARK: - Error mapping

extension FirebaseAuthService {

    /// Translates a Firebase Auth failure into the app's vocabulary, so no screen has
    /// to know about `AuthErrorCode`.
    static func map(_ error: any Error) -> AuthError {
        let nsError = error as NSError

        // A connectivity failure surfaces as URLError, not an Auth error, so it is
        // checked first. Missing this is why "no internet" so often shows up in apps as
        // "wrong password".
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return .networkUnavailable
        }

        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(underlying: nsError.localizedDescription)
        }

        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword(reason: "Please choose a stronger password.")
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword, .userNotFound, .invalidCredential:
            // Merged deliberately — see `AuthError.wrongCredentials` for why not
            // distinguishing them is a privacy decision, not laziness.
            return .wrongCredentials
        case .userDisabled:
            return .userDisabled
        case .tooManyRequests:
            return .tooManyRequests
        case .networkError:
            return .networkUnavailable
        case .operationNotAllowed:
            return .methodNotEnabled
        default:
            return .unknown(underlying: nsError.localizedDescription)
        }
    }
}


