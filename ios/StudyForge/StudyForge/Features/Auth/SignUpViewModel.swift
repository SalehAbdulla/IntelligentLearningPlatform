//
//  SignUpViewModel.swift
//  StudyForge
//
//  Presentation logic for A05 (`05_SignUp_Email_{M1}`).
//
//  DEVIATION FROM THE DESIGN — READ THIS
//  -------------------------------------
//  docs/02/03 describe the sign-up sequence as:
//      … → Sign up email → **OTP verify** → Role select → Profile wizard → Role home
//
//  Firebase email/password authentication has no OTP step. It sends a **link**, not a
//  6-digit code. A real OTP would mean phone auth (SMS, per-message cost, and a Billable
//  dependency) or a custom code service on Cloud Functions (Blaze — we are deliberately
//  on Spark, see D24).
//
//  So F01 aims at the same GOAL — "get a *verified* user onto the correct role home" —
//  through email verification instead. That is a real mechanism, it is free, and it
//  genuinely verifies possession of the address. Screen A06 is therefore re-specified as
//  a verification *status* screen rather than a code-entry screen, and the design docs
//  should be updated to match rather than left contradicting the app.
//

import Foundation

@MainActor
@Observable
final class SignUpViewModel {

    enum Field: Hashable {
        case displayName
        case email
        case password
    }

    // MARK: Bound state

    var displayName = ""
    var email = ""
    var password = ""

    // MARK: Derived state

    private(set) var isSubmitting = false
    private(set) var error: AppError?
    private(set) var fieldErrors: [Field: String] = [:]

    private let auth: any AuthService

    init(auth: any AuthService) {
        self.auth = auth
    }

    // MARK: Live feedback

    var displayNameError: String? { fieldErrors[.displayName] }
    var emailError: String? { fieldErrors[.email] }
    var passwordError: String? { fieldErrors[.password] }

    /// Live strength band. Deliberately recomputed from the current password rather than
    /// stored, so it cannot fall out of step with the text in the field.
    var passwordStrength: PasswordStrength { PasswordEvaluator.strength(of: password) }

    /// The live rule checklist. Always all three, with satisfied flags — a list that
    /// grows as you type is harder to read than one that ticks off.
    var passwordRules: [PasswordRule] { PasswordEvaluator.rules(for: password) }

    var isSubmitEnabled: Bool { !isSubmitting }

    // MARK: Actions

    func didEdit(_ field: Field) {
        guard fieldErrors[field] != nil else { return }
        fieldErrors[field] = nil
    }

    func submit() async {
        guard !isSubmitting else { return }

        error = nil
        fieldErrors = [:]

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            fieldErrors[.displayName] = AuthError.missingDisplayName.asAppError.message
            return
        }

        do {
            try AuthInput.validate(email: email, password: password)
        } catch let authError as AuthError {
            route(authError)
            return
        } catch {
            self.error = AppError.from(error)
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await auth.signUp(
                email: email,
                password: password,
                displayName: trimmedName
            )
            // Success flips auth state; the router takes over from here.
        } catch let authError as AuthError {
            route(authError)
        } catch {
            self.error = AppError.from(error)
        }
    }

    // MARK: Error routing

    private func route(_ authError: AuthError) {
        switch authError {
        case .missingDisplayName:
            fieldErrors[.displayName] = authError.asAppError.message
        case .invalidEmail, .emailAlreadyInUse:
            // `emailAlreadyInUse` belongs on the email field: the fix is to change the
            // address or go and log in, both of which are decisions about that field.
            fieldErrors[.email] = authError.asAppError.message
        case .weakPassword:
            fieldErrors[.password] = authError.asAppError.message
        default:
            error = authError.asAppError
        }
    }
}
