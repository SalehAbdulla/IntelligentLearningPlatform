//
//  SpacedRepetitionTests.swift
//  StudyForgeTests
//
//  Tests for the SM-2 scheduler — the maths the whole review loop trusts.
//
//  These exist because the interval calculation is the one place a subtle sign error silently turns
//  "review again in 6 days" into "review again never", and the failure mode only shows up days
//  later in a real session.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("SM-2 scheduler")
struct SpacedRepetitionTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private var newState: SpacedRepetitionState {
        SpacedRepetitionState(ease: 2.5, interval: 0, dueAt: now, reps: 0, lapses: 0)
    }

    private func approx(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 0.000_000_1
    }

    @Test("The first successful review schedules a one-day interval")
    func firstReviewIsOneDay() {
        let next = SpacedRepetition.nextState(newState, rating: .good, now: now)
        #expect(next.interval == 1)
        #expect(next.reps == 1)
        #expect(next.lapses == 0)
        #expect(next.dueAt == Calendar.current.date(byAdding: .day, value: 1, to: now))
    }

    @Test("The second successful review schedules a six-day interval")
    func secondReviewIsSixDays() {
        let once = SpacedRepetition.nextState(newState, rating: .good, now: now)
        let twice = SpacedRepetition.nextState(once, rating: .good, now: now)
        #expect(twice.interval == 6)
        #expect(twice.reps == 2)
    }

    @Test("From the third review on, the interval grows by the ease factor")
    func intervalGrowsByEase() {
        let once = SpacedRepetition.nextState(newState, rating: .good, now: now)   // 1 day
        let twice = SpacedRepetition.nextState(once, rating: .good, now: now)      // 6 days
        let third = SpacedRepetition.nextState(twice, rating: .good, now: now)
        #expect(third.interval == 15, "round(6 × 2.5)")
        #expect(third.reps == 3)
    }

    @Test("Again is a lapse: interval resets, reps reset, ease drops")
    func againIsALapse() {
        let once = SpacedRepetition.nextState(newState, rating: .good, now: now)
        let lapsed = SpacedRepetition.nextState(once, rating: .again, now: now)
        #expect(lapsed.interval == 0)
        #expect(lapsed.reps == 0)
        #expect(lapsed.lapses == 1)
        #expect(lapsed.dueAt == now, "a lapsed card is due immediately")
        #expect(approx(lapsed.ease, 1.7), "2.5 − 0.8")
    }

    @Test("Hard nudges ease down, Good keeps it, Easy nudges it up")
    func easeAdjustments() {
        #expect(approx(SpacedRepetition.nextState(newState, rating: .hard, now: now).ease, 2.36))
        #expect(approx(SpacedRepetition.nextState(newState, rating: .good, now: now).ease, 2.5))
        #expect(approx(SpacedRepetition.nextState(newState, rating: .easy, now: now).ease, 2.6))
    }

    @Test("The ease factor never falls below the floor of 1.3")
    func easeFloor() {
        var state = newState
        for _ in 0..<20 {
            state = SpacedRepetition.nextState(state, rating: .again, now: now)
        }
        #expect(state.ease == 1.3)
        #expect(state.lapses == 20)
    }
}
