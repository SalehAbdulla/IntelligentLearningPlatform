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
}
