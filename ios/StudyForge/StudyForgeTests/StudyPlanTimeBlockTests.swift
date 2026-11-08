//
//  StudyPlanTimeBlockTests.swift
//  StudyForgeTests
//
//  F06 Task 03 (G02, part two) — the weekly availability time-block DATA MODEL: one-hour
//  slots on a 06:00–24:00 grid, canonicalised on the way into `StudyPlanInput` exactly the
//  way `blockedDays` is. No capacity maths, no warnings and no UI live here — later steps.
//
//  House rules (CONTRIBUTING): deterministic inputs only, no clock reads (the model is plain
//  integer calendar arithmetic), stable expectations, every assertion explainable aloud.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Weekly time blocks (F06 Task 03, part two)")
struct StudyPlanTimeBlockTests {

    /// Only the planner-equality test needs a clock; it is pinned, never `Date.now`.
    private let pinnedNow = Date(timeIntervalSince1970: 1_773_000_000)

    private func input(
        timeBlocks: [TimeSlot] = [],
        blockedDays: [Int] = [],
        weeklyHours: Int = 12
    ) -> StudyPlanInput {
        StudyPlanInput(
            subjects: ["Maths"],
            weeklyHours: weeklyHours,
            intensity: .balanced,
            blockedDays: blockedDays,
            timeBlocks: timeBlocks
        )
    }

    private func block(_ weekday: Int, _ startMinute: Int) -> TimeSlot {
        TimeSlot(weekday: weekday, startMinute: startMinute)
    }

    /// One session reduced to the fields the scheduler actually decides — everything except
    /// the generated `id`. `StudySession` mints a fresh UUID on every schedule, so two
    /// independently built schedules can never be `==` as whole sessions even when they say
    /// exactly the same thing (the same reason `StudyPlannerTests` compares maps of these
    /// fields rather than whole sessions).
    private struct SessionShape: Equatable {
        let subject: String
        let estimatedMinutes: Int
        let scheduledAt: Date
        let status: StudySessionStatus
        let startedAt: Date?
    }

    /// The ordered sequence of `SessionShape`s a schedule makes — its meaning, identity-free.
    private func shape(_ sessions: [StudySession]) -> [SessionShape] {
        sessions.map {
            SessionShape(
                subject: $0.subject,
                estimatedMinutes: $0.estimatedMinutes,
                scheduledAt: $0.scheduledAt,
                status: $0.status,
                startedAt: $0.startedAt
            )
        }
    }

    // MARK: The grid's geometry

    @Test("A valid slot survives canonicalisation unchanged")
    func validSlotIsKept() {
        let kept = input(timeBlocks: [block(3, 6 * 60)]).timeBlocks

        #expect(kept == [block(3, 6 * 60)])
        #expect(kept.first?.durationMinutes == WeeklyAvailabilityGrid.slotMinutes)
    }

    @Test("The first allowed slot starts at 06:00 and a day offers 18 slots")
    func firstAllowedSlotIsSixAm() {
        #expect(WeeklyAvailabilityGrid.dayStartMinute == 6 * 60)
        #expect(WeeklyAvailabilityGrid.slotsPerDay == 18)
        #expect(input(timeBlocks: [block(1, WeeklyAvailabilityGrid.dayStartMinute)]).timeBlocks.count == 1)
    }

    @Test("The last allowed slot starts at 23:00 and ends at 24:00")
    func lastAllowedSlotEndsAtMidnight() {
        let lastStart = WeeklyAvailabilityGrid.dayEndMinute - WeeklyAvailabilityGrid.slotMinutes

        #expect(lastStart == 23 * 60, "the final slot starts at 23:00")
        #expect(lastStart + WeeklyAvailabilityGrid.slotMinutes == WeeklyAvailabilityGrid.dayEndMinute)
        #expect(input(timeBlocks: [block(7, lastStart)]).timeBlocks == [block(7, lastStart)])
    }

    @Test("A weekday outside 1...7 is dropped, never stored")
    func invalidWeekdayIsDropped() {
        let kept = input(timeBlocks: [block(0, 360), block(8, 420), block(-2, 480), block(4, 540)]).timeBlocks

        #expect(kept == [block(4, 540)], "only the in-range weekday survives")
    }

    @Test("Starts outside the 06:00–24:00 window are dropped")
    func timesOutsideWindowAreDropped() {
        // 300 = 05:00 (too early); 1440 = 24:00 (nothing may START at the exclusive end);
        // 1400 would run past 24:00. 360 is the legal control.
        let kept = input(timeBlocks: [block(2, 300), block(2, 1440), block(2, 1400), block(2, 360)]).timeBlocks

        #expect(kept == [block(2, 360)])
    }

    @Test("Start times that are not on a slot boundary are dropped")
    func misalignedStartsAreDropped() {
        let kept = input(timeBlocks: [block(1, 390), block(1, 450), block(1, 420)]).timeBlocks

        #expect(kept == [block(1, 420)], "half-past the grid is not a slot")
    }

    // MARK: Canonical form

    @Test("Duplicate slots collapse to one")
    func duplicatesCollapse() {
        let kept = input(timeBlocks: [block(5, 720), block(5, 720), block(5, 720)]).timeBlocks

        #expect(kept == [block(5, 720)])
    }

    @Test("Ordering is stable: weekday first, then start minute, whatever the input order")
    func orderingIsStable() {
        let shuffled = [block(7, 1380), block(1, 360), block(1, 1380), block(1, 420)]

        #expect(
            input(timeBlocks: shuffled).timeBlocks
                == [block(1, 360), block(1, 420), block(1, 1380), block(7, 1380)]
        )
    }

    @Test("Several non-contiguous slots on one day are all kept")
    func multipleNonContiguousSlotsPerDay() {
        let kept = input(timeBlocks: [block(6, 360), block(6, 600), block(6, 480)]).timeBlocks

        #expect(kept == [block(6, 360), block(6, 480), block(6, 600)], "gaps are legal; order still canonical")
    }

    // MARK: Wire format and the fields that came before

    @Test("timeBlocks survive an encode/decode round trip")
    func codableRoundTrip() throws {
        let original = input(
            timeBlocks: [block(1, 360), block(4, 1380)],
            blockedDays: [3, 6],
            weeklyHours: 12
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StudyPlanInput.self, from: data)

        #expect(decoded == original, "the grid is exactly what was written")
        #expect(decoded.blockedDays == [3, 6], "the new field does not disturb the old ones")
        #expect(decoded.weeklyHours == 12)
    }

    @Test("A plan written before time blocks existed still decodes")
    func legacyPlanWithoutTimeBlocksStillDecodes() throws {
        // Exactly the shape this app wrote before the grid: no `timeBlocks` key anywhere,
        // but `blockedDays` already present — the two generations must not collide.
        let legacy = """
        {
          "id" : "p2",
          "input" : {
            "subjects" : ["Maths"],
            "weeklyHours" : 12,
            "deadline" : 4000000000,
            "intensity" : "balanced",
            "blockedDays" : [2]
          },
          "sessions" : [],
          "createdAt" : 1000000,
          "updatedAt" : 1000000
        }
        """

        let decoded = try JSONDecoder().decode(StudyPlan.self, from: Data(legacy.utf8))

        #expect(decoded.input.timeBlocks.isEmpty, "a missing key means 'nothing selected'")
        #expect(decoded.input.blockedDays == [2], "existing fields decode exactly as before")
        #expect(decoded.input.weeklyHours == 12)
    }

    @Test("Adding timeBlocks changes neither blockedDays, weeklyHours nor the planner's output")
    func existingBehaviourIsUntouched() {
        let plain = input(blockedDays: [5], weeklyHours: 8)
        let withBlocks = input(
            timeBlocks: [block(1, 360), block(2, 420)],
            blockedDays: [5],
            weeklyHours: 8
        )

        #expect(withBlocks.blockedDays == plain.blockedDays, "blockedDays is not reinterpreted")
        #expect(withBlocks.weeklyHours == plain.weeklyHours, "weeklyHours stays the requested duration")

        // The planner does not read the new field yet, so the schedule it produces is the
        // schedule it produced before this field existed — proven, not assumed. Every
        // scheduler-relevant field is compared in order; only the generated `id` is excluded,
        // because a fresh UUID per session makes whole-session equality impossible by design.
        let scheduled = StudyPlanner.schedule(withBlocks, now: pinnedNow)
        let baseline = StudyPlanner.schedule(plain, now: pinnedNow)

        #expect(scheduled.count == baseline.count, "the same number of sessions")
        #expect(
            shape(scheduled) == shape(baseline),
            "every scheduling field matches; only the generated id is excluded"
        )
    }
}
