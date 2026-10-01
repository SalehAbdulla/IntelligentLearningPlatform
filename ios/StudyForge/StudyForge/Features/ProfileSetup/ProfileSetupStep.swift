//
//  ProfileSetupStep.swift
//  StudyForge
//
//  The wizard's steps, in order.
//
//  WHY THE COUNT IS A CONSTANT AND NOT `allCases.count`
//  ---------------------------------------------------
//  The order and the total come from the DESIGN (docs/03 §B: B01 academic → B02 learning
//  style → B03 study goals, with B04 as the confirmation screen). Deriving the total from
//  the cases that happen to exist would have made B01 and B02 claim "Step 1 of 2" /
//  "Step 2 of 2" and then silently renumber themselves to "of 3" the day B03 landed — a
//  student mid-wizard would see the flow get longer behind them, and nobody would notice,
//  because the change looks like progress rather than a bug.
//
//  `designedCount` is therefore the design's three, and it does not change as steps land.
//

import Foundation

/// One step of the profile wizard.
enum ProfileSetupStep: Int, CaseIterable, Sendable {

    /// B01 — `11_ProfileSetup_Academic_{M1}`.
    case academic

    /// B02 — `12_ProfileSetup_LearningStyle_{M1}`.
    case learningStyle

    /// B03 — `13_ProfileSetup_StudyGoals_{M1}`. The last step, which is why its button says
    /// Finish rather than Continue.
    case studyGoals

    // B04 (`14_ProfileSetup_Complete_{M1}`) is the confirmation screen, not a step: it has
    // no answer to collect, so it does not belong in this sequence.

    /// How many steps the wizard has in the design, including the ones still to be built.
    static let designedCount = 3

    /// Where a wizard starts.
    static var first: ProfileSetupStep { allCases[0] }

    /// 1-based position, for the "Step N of M" indicator a student reads.
    var number: Int { rawValue + 1 }

    /// The localised position label, e.g. "Step 2 of 3".
    var label: String { L10n.profileStep.string(number, Self.designedCount) }

    /// The step after this one, or `nil` when this is the last one.
    ///
    /// `nil` is what moves the flow to its confirmation screen (B04). With all three steps
    /// present, the wizard finishes because it is finished, not because something is missing.
    /// B04 collects no answer of its own, so it is not a step and does not appear here — the
    /// flow shows it once this returns `nil`, and the student dismisses it.
    var next: ProfileSetupStep? { ProfileSetupStep(rawValue: rawValue + 1) }
}
