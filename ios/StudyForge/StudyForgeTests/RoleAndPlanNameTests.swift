//
//  RoleAndPlanNameTests.swift
//  StudyForgeTests
//
//  The role and plan names are the app's copy, not wire values: `AppRole.student.rawValue` is what the
//  token carries, while `displayName` is what a student reads. These pin the second half, so a name
//  cannot quietly go back to being a hard-coded English literal.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Role and plan names")
struct RoleAndPlanNameTests {

    @Test("Every role's name comes from the catalogue")
    func roleNamesComeFromTheCatalogue() {
        #expect(AppRole.student.displayName == L10n.sessionRoleStudent.string)
        #expect(AppRole.tutor.displayName == L10n.sessionRoleTutor.string)
        #expect(AppRole.admin.displayName == L10n.sessionRoleAdmin.string)
    }

    @Test("Every plan's name comes from the catalogue")
    func planNamesComeFromTheCatalogue() {
        #expect(SubscriptionPlan.free.displayName == L10n.sessionPlanFree.string)
        #expect(SubscriptionPlan.plus.displayName == L10n.sessionPlanPlus.string)
        #expect(SubscriptionPlan.pro.displayName == L10n.sessionPlanPro.string)
    }

    @Test("Every case is covered, so a new role or plan cannot ship unnamed")
    func everyCaseIsNamed() {
        #expect(AppRole.allCases.map(\.displayName).allSatisfy { !$0.isEmpty })
        #expect(SubscriptionPlan.allCases.map(\.displayName).allSatisfy { !$0.isEmpty })
    }
}
