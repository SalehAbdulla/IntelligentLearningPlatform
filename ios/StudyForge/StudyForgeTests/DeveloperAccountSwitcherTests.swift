//
//  DeveloperAccountSwitcherTests.swift
//  StudyForgeTests
//
//  F01 — the DEBUG-only developer account switcher.
//
//  WHAT THESE CAN AND CANNOT COVER
//  -------------------------------
//  The toolbar button itself is not reachable from here: there is no UI test target, and the
//  project deliberately has none. So these cover the part that decides whether a demo works —
//  the account list, the password contract, and what `signIn(as:)` does on success and on
//  failure.
//
//  They also CANNOT prove that signing in as `tutor@studyforge.test` yields the tutor role:
//  `MockAuthService.signIn` returns `CustomClaims.leastPrivilege` by design, so the mock is
//  always a student. The role comes from the real ID token through `CustomClaims`, and the
//  only place that is verified is the device — which is what `docs/08` demo3 asks for.
//

import Foundation
import Testing
@testable import StudyForge

#if DEBUG
@Suite("Developer account switcher (F01)")
@MainActor
struct DeveloperAccountSwitcherTests {

    private func makeModel(
        outcome: MockAuthService.Outcome = .succeed
    ) -> DeveloperAccountSwitcherModel {
        DeveloperAccountSwitcherModel(auth: MockAuthService(latency: .zero, outcome: outcome))
    }

    @Test("The four accounts are exactly the four the seeder creates")
    func accountsMatchTheSeeder() {
        // `backend/scripts/seed-demo-accounts.mjs` is the source of truth. If this list drifts
        // from it, the switcher offers an account that does not exist and the sign-in fails as
        // "wrong credentials" — with no hint that the cause is a missing account.
        #expect(DemoAccounts.all.count == 4)
        #expect(DemoAccounts.all.map(\.email) == [
            "student@studyforge.test",
            "tutor@studyforge.test",
            "group@studyforge.test",
            "admin@studyforge.test",
        ])
    }

    @Test("The roles are the ones the app gates its screens on")
    func rolesAreTheOnesTheAppUses() {
        let roles = Dictionary(uniqueKeysWithValues: DemoAccounts.all.map { ($0.email, $0.role) })

        #expect(roles["student@studyforge.test"] == .student)
        #expect(roles["tutor@studyforge.test"] == .tutor)
        #expect(roles["admin@studyforge.test"] == .admin)

        // The group member is a STUDENT, not a fourth role. `UserSession.swift` is explicit
        // that "Study Group Member" is a capability expressed through `groupIds` — so if this
        // ever became a role, the switcher and the app would disagree about what it reaches.
        #expect(roles["group@studyforge.test"] == .student)
    }

    @Test("The four accounts cover all three subscription tiers")
    func accountsCoverEveryTier() {
        // THE TEST THAT WOULD HAVE CAUGHT THIS. The first version of `DemoAccounts` was
        // free / pro / pro / pro, so the PLUS branch was unreachable in a demo — even though
        // the paywall sells three plans and `PlanCompareView` compares all three.
        //
        // It asserts the COVERAGE rather than the individual values, which is what makes it
        // impossible to reintroduce: adding a fourth tier to `SubscriptionPlan` now fails
        // here until an account carries it, instead of silently going undemonstrated.
        let covered = Set(DemoAccounts.all.map(\.plan))
        let missing = Set(SubscriptionPlan.allCases).subtracting(covered)

        #expect(
            missing.isEmpty,
            "every tier must be demonstrable; missing \(missing.map(\.rawValue).sorted())"
        )
    }

    @Test("The golden-path account is on the FREE tier")
    func theStudentIsFree() {
        // The paywall upsells FROM free, so the account that demonstrates the golden path has
        // to be on it. If this ever became a paid tier the upsell could not be shown at all.
        #expect(DemoAccounts.account(forEmail: "student@studyforge.test")?.plan == .free)
    }

    @Test("The password is the seeder's default")
    func passwordMatchesTheSeeder() {
        // The seeder sets `changeme` unless SF_DEMO_PASSWORD overrides it. Pinned here so the
        // two cannot drift silently: the failure mode is a demo that cannot sign in, found in
        // front of an audience rather than in a test run.
        #expect(DemoAccounts.password == "changeme")
    }

    @Test("An account is found by its address, case-insensitively")
    func lookupIsCaseInsensitive() {
        #expect(DemoAccounts.account(forEmail: "TUTOR@studyforge.test")?.role == .tutor)
    }

    @Test("A real account is not a demo account, and nil is a normal answer")
    func lookupReturnsNilForRealAccounts() {
        // The sheet uses this to decide whether to show the tick. `nil` is not a failure —
        // it is the correct answer for every account that is not one of the four.
        #expect(DemoAccounts.account(forEmail: "someone@student.polytechnic.bh") == nil)
        #expect(DemoAccounts.account(forEmail: nil) == nil)
    }

    @Test("Signing in as a demo account succeeds and clears the busy state")
    func signInSucceeds() async {
        let model = makeModel()

        let ok = await model.signIn(as: DemoAccounts.all[1])

        #expect(ok)
        #expect(model.error == nil)
        #expect(model.busyEmail == nil, "the spinner state is cleared on the way out")
    }

    @Test("A failed sign-in reports why, rather than failing silently")
    func signInFailureIsReported() async {
        let model = makeModel(outcome: .fail(.wrongCredentials))

        let ok = await model.signIn(as: DemoAccounts.all[0])

        #expect(ok == false)
        #expect(model.error != nil, "a silent failure would look like a frozen sheet")
        #expect(model.busyEmail == nil)
    }

    @Test("Being offline and being wrong are reported differently")
    func failuresAreDistinguishable() async {
        let offline = makeModel(outcome: .fail(.networkUnavailable))
        _ = await offline.signIn(as: DemoAccounts.all[0])

        let wrong = makeModel(outcome: .fail(.wrongCredentials))
        _ = await wrong.signIn(as: DemoAccounts.all[0])

        #expect(offline.error != nil)
        #expect(wrong.error != nil)
        // "Check your connection" and "wrong password" call for different actions, so they
        // must not collapse into one message.
        #expect(offline.error != wrong.error)
    }
}
#endif
