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
}
