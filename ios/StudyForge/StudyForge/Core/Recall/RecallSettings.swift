//
//  RecallSettings.swift
//  StudyForge
//
//  F17 — the Anki-style deck options behind the Active Recall Space (docs/03 §O, O01 and O04).
//
//  WHY THE LEARNING STEPS ARE MINUTES AND NOT DAYS
//  -----------------------------------------------
//  The SM-2 engine in `Core/Scheduling/SpacedRepetition.swift` only knows whole days: its first
//  success schedules the card one day out. The Anki behaviour learners actually feel is the
//  SHORT step — you see a new card again inside the same sitting, twice, before it is allowed
//  to vanish for a day. That is a property of the sitting, not of the long-term schedule, so it
//  is modelled here and the SM-2 engine is never changed. One scheduler, one source of truth
//  for intervals; this file only decides WHEN the scheduler is asked.
//
//  WHY THESE ARE PER-LEARNER AND NOT PER-DECK
//  -----------------------------------------
//  A first-year student and a final-year student want different new-card ceilings, and the
//  ceiling is about the PERSON's daily capacity rather than the subject. One document per
//  learner (`recallSettings/{uid}`, owner-only per `firestore.rules`) matches how Anki's deck
//  options are used in practice, and it keeps the security rule trivial to reason about.
//
//  WHY THERE IS NO UI COPY IN THIS FILE
//  ------------------------------------
//  Every string the screens show is added with those screens, in M5's own commit, because the
//  localisation keys live in a SHARED file (`Localizable.strings`, both languages, 910 keys
//  checked for parity by `tools/check-strings.py`). Shipping a model that quietly introduced
//  untranslated copy would break that check and the Arabic build with it, so the model exposes
//  stable identifiers and the copy arrives with the views.
//

import Foundation

/// How well established a card is. Anki's four states, which O01 counts and O05 charts.
///
/// Derived rather than stored: every one of these is a pure function of the card's SM-2 state
/// plus the learner's settings, so there is no fifth thing to keep in sync and no migration if
/// the thresholds change.
enum RecallCardState: String, Sendable, Equatable, CaseIterable, Codable, Identifiable {
    /// Never reviewed.
    case new
    /// Started, still working through the learning steps.
    case learning
    /// Graduated, but the interval is still short.
    case young
    /// Graduated, and the interval has reached the maturity threshold.
    case mature

    var id: String { rawValue }

    // TODO(M5 · F17): Add the localised titles for O01's state counters, together with the
    // other Recall Space copy, in the same commit that touches `Localizable.strings` for both
    // languages. Done when: `python3 tools/check-strings.py` still reports key parity and the
    // counters render in English and Arabic.
}

/// F17's deck options: the learning steps and the daily ceilings.
///
/// Every field is clamped in `init`, so a value decoded from an older or hand-edited document
/// can never produce a zero-length step, a negative ceiling or a maturity threshold below the
/// graduating interval. A stored document is untrusted input like any other.
struct RecallSettings: Equatable, Sendable, Codable {

    /// Minutes a new card spends in each learning step before it graduates.
    ///
    /// Anki's default is `[1, 10]`: see the card again after a minute, then after ten.
    var learningStepMinutes: [Int]

    /// The most new cards introduced per day, across every deck in the Recall Space.
    var newCardsPerDay: Int

    /// The most reviews of already-seen cards per day.
    var maxReviewsPerDay: Int

    /// The interval in days a card graduates to when it leaves the learning steps.
    var graduatingIntervalDays: Int

    /// The interval in days at which a card stops being `young` and becomes `mature`.
    var matureAfterDays: Int

    /// Anki's own defaults, which is what O04 shows a learner who has never opened the screen.
    static let `default` = RecallSettings()

    init(
        learningStepMinutes: [Int] = [1, 10],
        newCardsPerDay: Int = 20,
        maxReviewsPerDay: Int = 200,
        graduatingIntervalDays: Int = 1,
        matureAfterDays: Int = 21
    ) {
        // A step list is the one field that can be empty, and an empty list would mean a new
        // card has nowhere to go before graduating. Falling back to the default keeps that
        // state unreachable rather than merely unlikely.
        let steps = learningStepMinutes.filter { $0 > 0 }.sorted()
        self.learningStepMinutes = steps.isEmpty ? [1, 10] : steps

        self.newCardsPerDay = max(0, newCardsPerDay)
        self.maxReviewsPerDay = max(0, maxReviewsPerDay)

        let graduate = max(1, graduatingIntervalDays)
        self.graduatingIntervalDays = graduate
        // Maturity below graduation would make a card mature the instant it graduates, which
        // is a contradiction rather than a preference.
        self.matureAfterDays = max(graduate, matureAfterDays)
    }

    /// The stored field names. Declared rather than synthesised because `init(from:)` below
    /// reads them by hand.
    private enum CodingKeys: String, CodingKey {
        case learningStepMinutes
        case newCardsPerDay
        case maxReviewsPerDay
        case graduatingIntervalDays
        case matureAfterDays
    }

    /// Reads a stored document through the initializer above, so the clamping runs on the way IN.
    ///
    /// WHY THIS IS NOT LEFT TO THE COMPILER
    /// ------------------------------------
    /// A synthesised `Decodable` conformance writes each field straight into the property and
    /// never calls `init`, so the guarantee at the top of this type — "a value decoded from an
    /// older or hand-edited document" is clamped — was not true for the one input that needs it.
    /// The consequence is not a wrong number: `RecallQueueBuilder` passes `maxReviewsPerDay` to
    /// `prefix(_:)`, and a negative value there TRAPS. A learner with a truncated or edited
    /// document would get a crash on launch instead of a screen. Delegating to `init` keeps a
    /// single place that owns the invariants, so they cannot drift from the decode path.
    ///
    /// A field the document does not carry falls back to its default rather than failing the
    /// whole read: a document written by an older build simply predates that field, and refusing
    /// it would turn an upgrade into an error state.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Spelled `RecallSettings()` rather than `.default` because this is the value the
        // defaults are being read FROM, not a value being produced.
        let fallback = RecallSettings()

        self.init(
            learningStepMinutes: try container.decodeIfPresent(
                [Int].self, forKey: .learningStepMinutes
            ) ?? fallback.learningStepMinutes,
            newCardsPerDay: try container.decodeIfPresent(
                Int.self, forKey: .newCardsPerDay
            ) ?? fallback.newCardsPerDay,
            maxReviewsPerDay: try container.decodeIfPresent(
                Int.self, forKey: .maxReviewsPerDay
            ) ?? fallback.maxReviewsPerDay,
            graduatingIntervalDays: try container.decodeIfPresent(
                Int.self, forKey: .graduatingIntervalDays
            ) ?? fallback.graduatingIntervalDays,
            matureAfterDays: try container.decodeIfPresent(
                Int.self, forKey: .matureAfterDays
            ) ?? fallback.matureAfterDays
        )
    }

    /// How many learning steps a card must clear before it graduates.
    var stepCount: Int { learningStepMinutes.count }

    /// The state a card is in, given its SM-2 state and whether it is still learning.
    ///
    /// - Parameters:
    ///   - sr: the card's scheduler state, read but never written here.
    ///   - isLearning: whether the card is still inside the learning steps.
    func state(for sr: SpacedRepetitionState, isLearning: Bool) -> RecallCardState {
        if isLearning { return .learning }
        if sr.reps == 0 && sr.lapses == 0 { return .new }
        return sr.interval >= matureAfterDays ? .mature : .young
    }
}

/// F17's learning-step state machine. Pure, like `SpacedRepetition`, and for the same reason:
/// the same inputs must always produce the same next step, so it is testable without a clock
/// and without a device.
///
/// WHY THIS IS NOT PART OF THE SM-2 ENGINE
/// ---------------------------------------
/// SM-2 answers "when should this card come back, in days?". The learning steps answer "should
/// this card come back in this sitting at all?". They are different questions in different
/// units, and merging them would make both harder to reason about — and would mean editing the
/// hand-written engine that F04 and its tests already depend on.
enum RecallLearning {

    /// What a rating does to a card that is still in the learning steps.
    enum Outcome: Equatable {
        /// Stay in the steps, at this zero-based index.
        case stay(step: Int)
        /// Leave the steps; the SM-2 engine takes over from this interval.
        case graduate(intervalDays: Int)
        /// Back to the first step, because the learner did not know it.
        case restart
    }

    /// The step a rating moves a card to.
    ///
    /// - `again` is a failure: back to the first step, exactly as Anki does.
    /// - `hard` repeats the current step, so the card comes back in the same sitting.
    /// - `good` advances one step, graduating when there are no steps left.
    /// - `easy` graduates immediately, which is the whole point of having the button.
    static func outcome(
        step: Int,
        rating: ReviewRating,
        settings: RecallSettings
    ) -> Outcome {
        switch rating {
        case .again:
            return .restart
        case .hard:
            return .stay(step: min(max(0, step), max(0, settings.stepCount - 1)))
        case .good:
            let next = step + 1
            return next < settings.stepCount
                ? .stay(step: next)
                : .graduate(intervalDays: settings.graduatingIntervalDays)
        case .easy:
            return .graduate(intervalDays: settings.graduatingIntervalDays)
        }
    }

    /// The step a NEW card starts at.
    static let firstStep = 0
}
