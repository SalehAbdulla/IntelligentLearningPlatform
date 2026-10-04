//
//  LoginViewModel.swift
//  StudyForge
//
//  Presentation logic for A07 (`07_Login_…`).
//
//  WHAT THIS OWNER DECIDES, AND WHY
//  --------------------------------
//  1. **Errors appear next to the field that caused them.** "That doesn't look like an
//     email address" belongs under the email box, not in a banner at the top — the
//     banner is reserved for failures that are not the user's typing (offline, server).
//     `AuthError` already knows which is which, so the mapping is mechanical rather
//     than invented per screen.
//  2. **No network round trip for a typo.** `AuthInput.validate` runs first, so a
//     malformed email fails instantly and offline instead of after a request that was
//     always going to be refused.
//  3. **No routing on success.** Sign-in mutates `AuthService` state; `AppContainer`
//     observes it and `RootView` re-renders. Having the view model also navigate would
//     give two sources of truth for "am I signed in", which is how a screen ends up
//     showing the wrong branch for a frame.
//

import Foundation

@MainActor
@Observable
final class LoginViewModel {

    /// Fields that can carry their own error.
    enum Field: Hashable {
        case email
        case password
    }

    // MARK: Bound state

    var email = ""
    var password = ""

    // MARK: Derived state

    private(set) var isSubmitting = false

    /// A failure that is not about a specific field. Rendered in `SFErrorBanner`.
    private(set) var error: AppError?

    /// Per-field validation messages, rendered by the fields themselves.
    private(set) var fieldErrors: [Field: String] = [:]

    /// True once a submit has been attempted, so the form does not scold the user for
    /// an empty field they have not reached yet.
    private(set) var hasAttemptedSubmit = false

    private let auth: any AuthService

    init(auth: any AuthService) {
        self.auth = auth
    }

    // MARK: Presentation helpers

    var emailError: String? { fieldErrors[.email] }
    var passwordError: String? { fieldErrors[.password] }

    /// The button is tappable while a field is empty: pressing it is how the user finds
    /// out what is missing. Disabling it instead leaves them with a dead control and no
    /// explanation.
    var isSubmitEnabled: Bool { !isSubmitting }

    // MARK: Actions

    /// Clears a field's error the moment the user edits it.
    ///
    /// Leaving a stale error under a field the user is actively fixing reads as though
    /// their correction was rejected before they finished typing it.
    func didEdit(_ field: Field) {
        guard fieldErrors[field] != nil else { return }
        fieldErrors[field] = nil
    }

    func submit() async {
        guard !isSubmitting else { return }

        hasAttemptedSubmit = true
        error = nil
        fieldErrors = [:]

        do {
            try AuthInput.validate(email: email, password: password)
        } catch {
            applyLocallyRaised(error)
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await auth.signIn(email: email, password: password)
            // Success is signalled through auth state, not through this call.
        } catch {
            applyLocallyRaised(error)
        }
    }

    // MARK: Error routing

    /// Routes a thrown error to the field it belongs to, or to the banner if it belongs
    /// to no field in particular.
    private func applyLocallyRaised(_ thrown: any Error) {
        guard let authError = thrown as? AuthError else {
            error = AppError.from(thrown)
            return
        }

        switch authError {
        case .invalidEmail:
            fieldErrors[.email] = authError.asAppError.message
        case .weakPassword:
            fieldErrors[.password] = authError.asAppError.message
        default:
            // `.wrongCredentials` lands here on purpose. It covers BOTH "no such
            // account" and "wrong password" — see `AuthError.wrongCredentials` — so it
            // cannot be pinned to one field without leaking which one was wrong.
            error = authError.asAppError
        }
    }
}
