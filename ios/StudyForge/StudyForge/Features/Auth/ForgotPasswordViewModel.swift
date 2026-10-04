//
//  ForgotPasswordViewModel.swift
//  StudyForge
//
//  Presentation logic for A08 (`08_ForgotPassword_Request_{M1}`).
//
//  THE SUCCESS STATE IS THE WHOLE POINT
//  ------------------------------------
//  This screen must confirm that a link was *sent* without confirming that an account
//  *exists*. Reporting "no account found" would turn the form into an account-enumeration
//  oracle: anyone could test whether a given student's email is registered. `AuthService`
//  already refuses to distinguish the two, and this view model's job is to not undo that
//  by guessing — so success is shown identically for a real and an unknown address, and
//  the copy is worded conditionally ("If an account exists for …").
//

import Foundation

@MainActor
@Observable
final class ForgotPasswordViewModel {

    enum Field: Hashable {
        case email
    }

    var email = ""

    private(set) var isSubmitting = false
    private(set) var error: AppError?
    private(set) var fieldErrors: [Field: String] = [:]

    /// True once a reset request has been accepted. Drives the confirmation panel.
    private(set) var didSend = false

    private let auth: any AuthService

    init(auth: any AuthService) {
        self.auth = auth
    }

    var emailError: String? { fieldErrors[.email] }
    var isSubmitEnabled: Bool { !isSubmitting }

    /// The address to show in the confirmation copy — echoed back so the user can spot a
    /// typo, without implying the address is registered.
    var confirmationEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func didEdit(_ field: Field) {
        guard fieldErrors[field] != nil else { return }
        fieldErrors[field] = nil
    }

    func submit() async {
        guard !isSubmitting else { return }

        error = nil
        fieldErrors = [:]

        // Address shape is the only thing checked locally: the password is irrelevant
        // here, so `AuthInput.validate` (which also checks length) is the wrong tool.
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthInput.isPlausibleEmail(trimmed) else {
            fieldErrors[.email] = AuthError.invalidEmail.asAppError.message
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await auth.sendPasswordReset(to: trimmed)
            // Shown for every address, registered or not. See the note above.
            didSend = true
        } catch let authError as AuthError {
            if case .invalidEmail = authError {
                fieldErrors[.email] = authError.asAppError.message
            } else {
                // `self.` is required: `catch` implicitly binds its own immutable `error`,
                // which shadows the property of the same name.
                self.error = authError.asAppError
            }
        } catch {
            self.error = AppError.from(error)
        }
    }
}
