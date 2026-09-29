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

    // MARK: - Session construction

    @Test("A session carries the claims through to the user's capabilities")
    func sessionReflectsClaims() {
        let session = CustomClaims(role: .tutor, plan: .plus, groupIds: ["g_1"])
            .session(uid: "uid_123", displayName: "Dr Ali")

        #expect(session.id == "uid_123")
        #expect(session.displayName == "Dr Ali")
        #expect(session.role == .tutor)
        #expect(session.plan == .plus)
        #expect(session.isTutor)
        #expect(session.isStudyGroupMember)
    }

    @Test("Least privilege means a student, on free, in no groups")
    func leastPrivilegeIsEmptyOnEveryAxis() {
        let session = CustomClaims.leastPrivilege.session(uid: "u", displayName: "New Student")

        #expect(session.role == .student)
        #expect(session.plan == .free)
        #expect(session.groupIds.isEmpty)
        #expect(session.isTutor == false, "a new account must never reach the tutor studio")
        #expect(session.isStudyGroupMember == false)
    }
}
