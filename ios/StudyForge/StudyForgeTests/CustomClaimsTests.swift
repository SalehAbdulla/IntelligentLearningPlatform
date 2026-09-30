//
//  CustomClaimsTests.swift
//  StudyForgeTests
//
//  Tests for the authorisation facts carried in the ID token.
//
//  These are SECURITY tests. Every one asks the same question: when this data is
//  missing or malformed, does the app grant the LEAST privilege? A parser that defaults
//  to `tutor` on bad input is a privilege-escalation bug, and these prevent one being
//  introduced later.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Custom claims — fail closed")
struct CustomClaimsTests {

    @Test("No claims at all yields the least privileged user")
    func emptyClaimsAreLeastPrivilege() {
        #expect(CustomClaims.parse(from: [:]) == .leastPrivilege)
    }

    @Test("Well-formed claims are read")
    func readsWellFormedClaims() {
        let claims = CustomClaims.parse(from: [
            "role": "tutor",
            "plan": "pro",
            "groupIds": ["g_1", "g_2"],
        ])

        #expect(claims.role == .tutor)
        #expect(claims.plan == .pro)
        #expect(claims.groupIds == ["g_1", "g_2"])
    }

    @Test("An unrecognised role falls back to student, never to something higher",
          arguments: ["superuser", "TUTOR", "", "admin;", " root", "Teacher"])
    func unknownRoleIsStudent(role: String) {
        // "TUTOR" and " root" are deliberately included: casing and stray whitespace
        // must NOT be silently normalised into a privilege grant.
        #expect(CustomClaims.parse(from: ["role": role]).role == .student,
                "'\(role)' must not grant anything but student")
    }

    @Test("An unrecognised plan falls back to free, never to something better",
          arguments: ["enterprise", "PRO", "", "unlimited"])
    func unknownPlanIsFree(plan: String) {
        #expect(CustomClaims.parse(from: ["plan": plan]).plan == .free)
    }

    @Test("A claim of the wrong type falls back instead of crashing")
    func wrongTypesAreTolerated() {
        // Claims arrive as `Any`; a number or nested object where a string is expected
        // must not take the app down at launch.
        let claims = CustomClaims.parse(from: [
            "role": 7,
            "plan": ["nested": true],
            "groupIds": "g_1",
        ])

        #expect(claims.role == .student)
        #expect(claims.plan == .free)
        #expect(claims.groupIds.isEmpty)
    }

    @Test("A malformed groupIds array keeps only the strings in it")
    func filtersNonStringGroupIds() {
        let claims = CustomClaims.parse(from: ["groupIds": ["g_1", 42, ["nested"], "g_2"]])
        #expect(claims.groupIds == ["g_1", "g_2"])
    }

    @Test("Each claim is judged independently")
    func partialClaimsAreHonouredIndependently() {
        // Failing the entire claim set because one field is odd would demote a real
        // tutor to a student. The role survives; only the odd field is downgraded.
        let claims = CustomClaims.parse(from: ["role": "tutor", "plan": "nonsense"])
        #expect(claims.role == .tutor)
        #expect(claims.plan == .free)
    }

    // MARK: - Email verification (a standard token claim, not a custom one)

    @Test("A verified account is read from the standard email_verified claim")
    func verifiedClaimIsRead() {
        let claims = CustomClaims.parse(from: ["email_verified": true])
        #expect(claims.isEmailVerified)
    }

    @Test("An absent email_verified claim means UNVERIFIED, not verified")
    func absentClaimFailsClosed() {
        // The direction that matters. Defaulting to verified would let an account that
        // never confirmed its address straight past the one check F01 exists to enforce.
        let claims = CustomClaims.parse(from: ["role": "student"])
        #expect(claims.isEmailVerified == false)
    }

    @Test("A non-boolean email_verified is treated as absent rather than coerced")
    func nonBooleanClaimFailsClosed() {
        // `"true"` is truthy in many languages. Here it is not a boolean, so it is treated
        // as absent — a token shape we do not recognise must not become a permission.
        for value in ["true", "TRUE", [true], [:]] as [Any] {
            let claims = CustomClaims.parse(from: ["email_verified": value])
            #expect(
                claims.isEmailVerified == false,
                "email_verified of \(type(of: value)) must not be coerced to true"
            )
        }
    }

    @Test("A numeric boolean is accepted, because JSON tokens can encode it that way")
    func numericBooleanIsAccepted() {
        // Some token encodings deliver a boolean as a number, and treating that as absent
        // would strand verified users on A06.
        #expect(CustomClaims.parse(from: ["email_verified": NSNumber(value: true)]).isEmailVerified)
        #expect(CustomClaims.parse(from: ["email_verified": NSNumber(value: false)]).isEmailVerified == false)
    }

    @Test("An integer 1 does NOT read as verified — only real booleans do")
    func integerOneFailsClosed() {
        // Worth pinning down, because the bridging rules here are genuinely subtle:
        //
        //   · `NSNumber(value: true)`  → `as? Bool` succeeds  (see the test above)
        //   · `Int(1)` boxed in `Any`  → `as? Bool` FAILS, because Swift does not
        //                                 auto-bridge a boxed `Int` to `Bool`
        //
        // So the loose token shape that would be most tempting to accept is exactly the
        // one that is rejected. That is the fail-closed direction, so it is asserted rather
        // than left to chance — an earlier draft of this file claimed `1` WAS accepted and
        // a test proved the opposite.
        #expect(CustomClaims.parse(from: ["email_verified": 1]).isEmailVerified == false)
        #expect(CustomClaims.parse(from: ["email_verified": 0]).isEmailVerified == false)
    }

    @Test("Verification travels into the session, alongside the email")
    func verificationReachesTheSession() {
        let session = CustomClaims(
            role: .student,
            plan: .free,
            groupIds: [],
            isEmailVerified: true
        )
        .session(uid: "uid_1", displayName: "Sara", email: "sara@studyforge.test")

        #expect(session.isEmailVerified)
        #expect(session.email == "sara@studyforge.test")
    }

    // MARK: - Session construction

    @Test("A session carries the claims through to the user's capabilities")
    func sessionReflectsClaims() {
        let session = CustomClaims(role: .tutor, plan: .plus, groupIds: ["g_1"])
            .session(uid: "uid_123", displayName: "Dr Ali", email: "ali@studyforge.test")

        #expect(session.id == "uid_123")
        #expect(session.displayName == "Dr Ali")
        #expect(session.role == .tutor)
        #expect(session.plan == .plus)
        #expect(session.isTutor)
        #expect(session.isStudyGroupMember)
    }

    @Test("Least privilege means a student, on free, in no groups, unverified")
    func leastPrivilegeIsEmptyOnEveryAxis() {
        let session = CustomClaims.leastPrivilege.session(
            uid: "u",
            displayName: "New Student",
            email: "new@studyforge.test"
        )

        #expect(session.role == .student)
        #expect(session.plan == .free)
        #expect(session.groupIds.isEmpty)
        #expect(session.isTutor == false, "a new account must never reach the tutor studio")
        #expect(session.isStudyGroupMember == false)
        #expect(session.isEmailVerified == false, "a new account starts unverified")
    }
}
