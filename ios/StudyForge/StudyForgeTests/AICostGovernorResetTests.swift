//
//  AICostGovernorResetTests.swift
//  StudyForgeTests
//
//  R25 (docs/09): the daily AI budget reset is pinned to the CALENDAR DAY the
//  injected clock reports — never to when the last generation happened.
//
//  WHY THIS LIVES IN ITS OWN FILE
//  -----------------------------
//  `AICostGovernorTests.swift` appears in NO member's TOUCH list in
//  tools/check-lane.sh, so modifying it is OUT OF LANE for everyone — the
//  guard's NEW rule only accepts files that do not yet exist. Every member may
//  ADD files under `StudyForgeTests/`, so this pin lands here rather than
//  asking the owner to widen a lane for one test. If the owner later adds the
//  original suite to M3's TOUCH, moving this test into it is a one-file change.
//
//  WHAT IT PROTECTS
//  ----------------
//  The free-tier claim rests on the counter refilling exactly once per local
//  day (AICostGovernor.resetIfNeeded reads `countedDay` against the injected
//  clock). A reset tied to "time since the last request" would either refill
//  mid-day — spending the day's budget twice — or fail to refill after a quiet
//  night. The behaviour is correct today; this test makes sure it stays that
//  way and fails the moment the reset is re-tied to a request timestamp.
//
//  NOTE ON TEST DIRECTION
//  ----------------------
//  This is a regression PIN, not a bug fix: it passes against the current
//  implementation by design, and its failure mode is any future change that
//  makes the reset depend on when the last generation was recorded.
//

import Foundation
import Testing
@testable import StudyForge

@MainActor
@Suite("AI cost governor — daily reset semantics")
struct AICostGovernorResetTests {

    /// A controllable clock, so crossing midnight does not require waiting for it.
    private final class TestClock: @unchecked Sendable {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    @Test("The daily reset reads the clock, not the date of the last request")
    func budgetResetIgnoresLastRequestDate() {
        // 23:00 the same evening: the last generation of the day has just
        // happened, so "time since the last request" is as small as it can be
        // while the calendar day is about to change. An elapsed-time-based
        // reset would refuse to refill here.
        let dayStart = Calendar.current.startOfDay(for: Date())
        let lateEvening = dayStart.addingTimeInterval(82_800)          // 23:00 today
        let clock = TestClock(lateEvening)
        let governor = AICostGovernor(plan: .free, clock: { clock.now })

        governor.seed(usedToday: governor.limit)
        #expect(governor.hasBudget == false, "the evening starts with the budget spent")

        // One second past the NEXT day's start. Elapsed since the last
        // request: one second — a threshold-based reset would not have fired,
        // but the calendar day has changed, so the allowance must return.
        let nextDayStart = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)
            ?? dayStart.addingTimeInterval(86_400)                     // DST-proof fallback
        clock.now = nextDayStart.addingTimeInterval(1)                 // 00:00:01 tomorrow

        #expect(governor.hasBudget,
                "a new calendar day restores the allowance, however recent the last request")
        #expect(governor.usedToday == 0)
        #expect(governor.remaining == governor.limit)

        // The same proof from the other side, inside one test so the pair
        // cannot drift apart: half an hour later on the SAME evening, with a
        // request just recorded, elapsed time alone must not refill anything.
        clock.now = lateEvening
        governor.seed(usedToday: governor.limit)
        clock.now = lateEvening.addingTimeInterval(1_800)              // 23:30, same day

        #expect(governor.hasBudget == false,
                "elapsed time within one local day must never restore the allowance")
    }
}