//
//  CohortSnapshotTests.swift
//  StudyForgeTests
//
//  F11 — the four numbers across the top of J01. `now` is injected so "active this week" means
//  the same thing on every machine and at every hour.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Cohort snapshot (F11)")
struct CohortSnapshotTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func member(
        uid: String,
        mastery: Int,
        lastActiveDaysAgo: Int?,
        status: EnrollmentStatus = .active
    ) -> Enrollment {
        Enrollment(
            courseId: "c1",
            uid: uid,
            studentName: "Student \(uid)",
            studentNumber: uid,
            masteryPercent: mastery,
            lastActiveAt: lastActiveDaysAgo.map { now.addingTimeInterval(-Double($0) * 86_400) },
            status: status
        )
    }

    @Test("An empty roster is a designed state, not an error")
    func emptyRoster() {
        let snapshot = CohortSnapshot.from([], now: now)

        #expect(snapshot.students == 0)
        #expect(snapshot.isEmpty)
        #expect(snapshot.activeFraction == nil, "no cohort means no fraction to show")
    }

    @Test("Students, average mastery and at-risk counts come from the roster")
    func counts() {
        let snapshot = CohortSnapshot.from([
            member(uid: "a", mastery: 80, lastActiveDaysAgo: 1),
            member(uid: "b", mastery: 40, lastActiveDaysAgo: 2),   // at risk: < 60
            member(uid: "c", mastery: 60, lastActiveDaysAgo: 20),  // not at risk: 60 is not < 60
        ], now: now)

        #expect(snapshot.students == 3)
        #expect(snapshot.averageMastery == 60)     // (80 + 40 + 60) / 3
        #expect(snapshot.atRisk == 1)
        #expect(snapshot.activeThisWeek == 2, "the third student was last active 20 days ago")
    }

    @Test("A student who has never been active is not counted as active")
    func neverActive() {
        let snapshot = CohortSnapshot.from([
            member(uid: "a", mastery: 70, lastActiveDaysAgo: nil),
        ], now: now)

        #expect(snapshot.students == 1)
        #expect(snapshot.activeThisWeek == 0)
    }

    @Test("A pending request is not yet a student")
    func pendingIsNotAStudent() {
        let snapshot = CohortSnapshot.from([
            member(uid: "a", mastery: 90, lastActiveDaysAgo: 1, status: .pending),
            member(uid: "b", mastery: 50, lastActiveDaysAgo: 1),
        ], now: now)

        #expect(snapshot.students == 1, "the pending request is excluded")
        #expect(snapshot.averageMastery == 50)
    }

    @Test("The active fraction is the share of the cohort")
    func activeFraction() {
        let snapshot = CohortSnapshot.from([
            member(uid: "a", mastery: 70, lastActiveDaysAgo: 1),
            member(uid: "b", mastery: 70, lastActiveDaysAgo: 40),
        ], now: now)

        #expect(snapshot.activeFraction == 0.5)
    }

    @Test("An at-risk threshold is exactly below 60")
    func atRiskThreshold() {
        #expect(member(uid: "a", mastery: 59, lastActiveDaysAgo: 1).isAtRisk)
        #expect(member(uid: "b", mastery: 60, lastActiveDaysAgo: 1).isAtRisk == false)
        #expect(
            member(uid: "c", mastery: 10, lastActiveDaysAgo: 1, status: .removed).isAtRisk == false,
            "a removed student is not at risk — they are gone"
        )
    }
}
