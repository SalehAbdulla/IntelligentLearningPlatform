//
//  AuthErrorMappingTests.swift
//  StudyForgeTests
//
//  Tests that every way sign-in can fail arrives at the user as something specific and
//  actionable, rather than a generic "Something went wrong".
//
//  This is the test file that would have caught the `AppError.from` bug the AI work
//  uncovered, applied to auth. The same mistake is easy to make twice.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Auth error surface")
struct AuthErrorMappingTests {

    @Test("Invalid input maps to the actionable input error")
    func invalidInputMaps() {
        for error in [AuthError.invalidEmail, .emailAlreadyInUse, .missingDisplayName] {
            guard case .authInvalidInput = error.asAppError else {
                Issue.record("\(error) should map to .authInvalidInput")
                return
            }
        }
    }

    @Test("Every input error gives a specific reason, not a generic one")
    func inputErrorsAlwaysCarryAReason() {
        // The weakPassword reason is taken from the REAL validator rather than a
        // hand-written fixture. Writing "too short" here would assert on the test's own
        // string and pass even if production emitted something useless.
        var errors: [AuthError] = [.invalidEmail, .emailAlreadyInUse, .missingDisplayName]
        do {
            try AuthInput.validate(email: "sara@studyforge.test", password: "short")
            Issue.record("expected a weakPassword error from the validator")
        } catch let error as AuthError {
            errors.append(error)
        } catch {
            Issue.record("expected an AuthError, got \(error)")
        }

        for error in errors {
            guard case .authInvalidInput(let reason) = error.asAppError else {
                Issue.record("\(error) should be an input error")
                return
            }
            #expect(reason.count >= 15, "\(error) needs a message that explains the problem")
        }
    }

    @Test("Bad credentials map to a retryable failure, not an input error")
    func wrongCredentialsMapToFailure() {
        // The user's next action is to retry or reset, not to re-read the form — so
        // these must not be grouped with validation problems.
        guard case .authFailed = AuthError.wrongCredentials.asAppError else {
            Issue.record("wrongCredentials should map to .authFailed")
            return
        }
        guard case .authFailed = AuthError.tooManyRequests.asAppError else {
            Issue.record("tooManyRequests should map to .authFailed")
            return
        }
    }

    @Test("Connectivity and permission failures keep their own identity")
    func specialisedErrorsArePreserved() {
        #expect(AuthError.networkUnavailable.asAppError == .offline)
        #expect(AuthError.userDisabled.asAppError == .notPermitted)
    }

    @Test("An unmapped Firebase failure degrades to unknown, never to success")
    func unknownFailuresStayFailures() {
        #expect(AuthError.unknown(underlying: "weird").asAppError == .unknown)
    }

    @Test("Every auth error produces copy a student can read")
    func everyErrorHasUsableCopy() {
        let errors: [AuthError] = [
            .invalidEmail,
            .weakPassword(reason: "Use at least 8 characters."),
            .emailAlreadyInUse,
            .wrongCredentials,
            .userDisabled,
            .tooManyRequests,
            .networkUnavailable,
            .methodNotEnabled,
            .missingDisplayName,
            .unknown(underlying: "x"),
        ]
        for error in errors {
            let appError = error.asAppError
            #expect(appError.title.count >= 10, "\(error) needs a real title")
            #expect(appError.message.count >= 20, "\(error) needs to explain what happened")
            #expect(!appError.message.contains("Error"), "\(error) must not leak the word 'Error'")
        }
    }

    @Test("A raw AuthError reaching AppError.from is translated, not degraded to unknown")
    func authErrorSurvivesTheGenericMapping() {
        // The same regression class as the AI error bug: without this branch the
        // sign-in screen would say "Something went wrong" and lose the reason.
        #expect(AppError.from(AuthError.networkUnavailable) == .offline)
        #expect(AppError.from(AuthError.userDisabled) == .notPermitted)
        #expect(AppError.from(AuthError.invalidEmail) != .unknown)
    }
}
