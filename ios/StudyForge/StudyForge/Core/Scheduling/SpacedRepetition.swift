//
//  SpacedRepetition.swift
//  StudyForge
//
//  The SM-2 scheduling engine that turns a student's rating into the next due date.
//
//  WHY THIS IS HAND-WRITTEN AND PURE
//  ---------------------------------
//  This is the one piece of maths the whole review loop depends on, and it must be deterministic
//  and testable without a device or a clock. A pure function over a `SpacedRepetitionState` is
//  exactly that: same state + same rating in, same state out, every time. It is also the piece the
//  sprint plan calls out as "hand-written code on the parts that matter" (docs/10 §4).
//
//  THE ALGORITHM
//  -------------
//  Standard SuperMemo-2 (SM-2), with the four review buttons mapped to SM-2 quality grades:
//  Again = 0 · Hard = 3 · Good = 4 · Easy = 5. Quality below 3 is a lapse: the interval resets and
//  the ease factor drops; quality 3+ grows the interval and nudges ease by the textbook formula.
//
//  The ease factor has a floor of 1.3, so a card a student keeps failing can never spiral to an
//  interval of zero days forever — it stays "hard but reviewable" rather than "broken".
//

import Foundation

/// How the student answered a card. The four buttons on the review back face.
enum ReviewRating: String, Sendable, CaseIterable, Codable {
    case again
    case hard
    case good
    case easy

    /// The SM-2 quality grade this button represents.
    var quality: Int {
        switch self {
        case .again: 0
        case .hard: 3
        case .good: 4
        case .easy: 5
        }
    }
}

/// A card's scheduling state: how well it is known and when it is next due.
struct SpacedRepetitionState: Equatable, Sendable, Codable {

    /// Ease factor. Starts at 2.5, floors at 1.3. Higher means the interval grows faster.
    var ease: Double

    /// The current interval in whole days. 0 means "new" or "lapsed" (due now).
    var interval: Int

    /// When the card is next due. Equal to `now` while `interval` is 0.
    var dueAt: Date

    /// Successful reviews in a row (quality 3+). Reset to 0 on a lapse.
    var reps: Int

    /// How many times the card has lapsed (quality below 3).
    var lapses: Int

    init(
        ease: Double = 2.5,
        interval: Int = 0,
        dueAt: Date = .now,
        reps: Int = 0,
        lapses: Int = 0
    ) {
        self.ease = ease
        self.interval = interval
        self.dueAt = dueAt
        self.reps = reps
        self.lapses = lapses
    }

    /// Whether the card is due now — either it has never been reviewed, or its due date has passed.
    func isDue(now: Date = .now) -> Bool {
        dueAt <= now
    }
}

/// The SM-2 scheduler. A namespace of pure functions, not a type to instantiate.
enum SpacedRepetition {

    /// The floor below which the ease factor never falls.
    static let minimumEase = 1.3

    /// Computes the state after the student rates a card with `rating`.
    ///
    /// Pure and deterministic: the same `state`, `rating` and `now` always yield the same result,
    /// which is what makes the interval maths unit-testable without waiting a day.
    static func nextState(
        _ state: SpacedRepetitionState,
        rating: ReviewRating,
        now: Date
    ) -> SpacedRepetitionState {
        var next = state

        if rating.quality >= 3 {
            next.reps += 1
            // The interval uses the PRE-adjustment ease, exactly as SM-2 specifies: the ease
            // factor is updated after the interval is computed, never before.
            next.interval = Self.interval(
                repetitions: next.reps,
                previousInterval: state.interval,
                ease: state.ease
            )
        } else {
            next.reps = 0
            next.interval = 0
            next.lapses += 1
        }

        next.ease = Self.adjustedEase(state.ease, quality: rating.quality)
        next.dueAt = Self.dueDate(days: next.interval, from: now)
        return next
    }

    /// The textbook SM-2 interval ladder: 1 day after the first success, 6 after the second, and
    /// `interval × ease` (rounded) thereafter.
    static func interval(repetitions: Int, previousInterval: Int, ease: Double) -> Int {
        switch repetitions {
        case 1: return 1
        case 2: return 6
        default: return max(1, Int((Double(previousInterval) * ease).rounded()))
        }
    }

    /// The textbook SM-2 ease update: `EF' = EF + (0.1 − (5−q)·(0.08 + (5−q)·0.02))`, floored.
    static func adjustedEase(_ ease: Double, quality: Int) -> Double {
        let delta = 0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)
        return max(minimumEase, ease + delta)
    }

    /// `now` plus `days`, or `now` itself when the interval is zero (a lapsed card is due now).
    static func dueDate(days: Int, from now: Date) -> Date {
        guard days > 0 else { return now }
        return Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
    }
}
