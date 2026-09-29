//
//  AuthInputTests.swift
//  StudyForgeTests
//
//  Tests for the credential rules every AuthService shares.
//
//  These matter more than they look: this validation runs BEFORE any network call, so
//  it is the only thing standing between a typo and a confusing server error — and it
//  is shared, so the mock cannot silently accept input production would reject.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Auth input validation")
struct AuthInputTests {

    // MARK: - Accepted

    @Test("Well-formed credentials pass", arguments: [
        ("sara@studyforge.test", "Password1"),
        ("a.b-c_d@sub.domain.ac.uk", "longenoughpw"),
        ("student+tag@university.edu", "correct horse battery"),
        ("  padded@example.com  ", "Password1"),
    ])
    func acceptsValidCredentials(email: String, password: String) throws {
        try AuthInput.validate(email: email, password: password)
    }

    @Test("Trimmed whitespace around an email is tolerated, since users paste addresses")
    func trimsEmailWhitespace() throws {
        try AuthInput.validate(email: "\tsara@studyforge.test \n", password: "Password1")
    }

    @Test("A password exactly at the minimum length is accepted")
    func acceptsMinimumLengthPassword() throws {
        let password = String(repeating: "a", count: AuthInput.minimumPasswordLength)
        try AuthInput.validate(email: "sara@studyforge.test", password: password)
    }

    @Test("Spaces inside a password are allowed — they are legitimate and strong")
    func allowsSpacesInPassword() throws {
        try AuthInput.validate(email: "sara@studyforge.test", password: "correct horse")
    }

    // MARK: - Rejected

    @Test("Malformed addresses are rejected", arguments: [
        "no-at-sign",
        "@nolocal.com",
        "no-domain@",
        "no-dot@domain",
        "trailing-dot@domain.",
        "leading-dot@.domain.com",
        "two@at@signs.com",
        "has space@domain.com",
        "",
        "a@b",
    ])
    func rejectsMalformedEmails(email: String) {
        #expect(AuthInput.isPlausibleEmail(email) == false, "\(email) should be rejected")
        #expect(throws: AuthError.invalidEmail) {
            try AuthInput.validate(email: email, password: "Password1")
        }
    }

    @Test("A password one character below the minimum is rejected")
    func rejectsPasswordBelowMinimum() {
        let password = String(repeating: "a", count: AuthInput.minimumPasswordLength - 1)

        do {
            try AuthInput.validate(email: "sara@studyforge.test", password: password)
            Issue.record("expected a weakPassword error")
        } catch let error as AuthError {
            guard case .weakPassword = error else {
                Issue.record("expected weakPassword, got \(error)")
                return
            }
        } catch {
            Issue.record("expected an AuthError, got \(error)")
        }
    }

    @Test("We require more than Firebase's own 6-character minimum")
    func stricterThanFirebase() {
        // Firebase accepts 6. Accepting the server's floor would mean shipping the
        // weakest thing that happens to work rather than a considered rule.
        #expect(AuthInput.minimumPasswordLength > 6)

        let firebaseWouldAccept = String(repeating: "a", count: 6)
        #expect(throws: (any Error).self) {
            try AuthInput.validate(email: "sara@studyforge.test", password: firebaseWouldAccept)
        }
    }

    @Test("An empty password is rejected")
    func rejectsEmptyPassword() {
        #expect(throws: (any Error).self) {
            try AuthInput.validate(email: "sara@studyforge.test", password: "")
        }
    }

    @Test("Email is checked before password, so the first error is the one to fix first")
    func emailIsValidatedFirst() {
        // Both are wrong; the user should be told about the email, because fixing the
        // password first would still leave a failing form.
        do {
            try AuthInput.validate(email: "nonsense", password: "x")
            Issue.record("expected a failure")
        } catch let error as AuthError {
            #expect(error == .invalidEmail)
        } catch {
            Issue.record("expected an AuthError, got \(error)")
        }
    }
}
