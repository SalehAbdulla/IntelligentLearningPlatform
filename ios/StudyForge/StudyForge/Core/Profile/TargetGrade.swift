//
//  TargetGrade.swift
//  StudyForge
//
//  The grade a student is aiming for (B03).
//
//  A PLACEHOLDER SCALE, AND MARKED AS ONE
//  -------------------------------------
//  docs/03 §B names a "target-grade selector" and stops there: no grade vocabulary exists
//  anywhere in this repository, so the scale below was chosen, not looked up. That is the
//  same position the course catalogue was in, and it is handled the same way — the
//  placeholder is isolated in one file so that answering the question is an edit rather
//  than a refactor (docs/09 Q12 asks for the institution's real bands).
//
//  What the app actually needs is the ORDER, not the bands: "a student aiming higher
//  should be pushed harder" is expressed by `ambition`, so swapping A–D for Distinction /
//  Merit / Pass, or for percentages, changes the labels and leaves the behaviour alone.
//
//  WHY THE LETTERS ARE NOT LOCALISED
//  --------------------------------
//  A grade letter is notation rather than prose, in the same way a numeral is: an Arabic
//  transcript writes A, B, C, D too. So the segment titles come from `displayName` instead
//  of the catalogue. A scale made of WORDS would be translated — that is the one change
//  Q12's answer would have to make here.
//

import Foundation

/// The grade a student is aiming for.
enum TargetGrade: String, Sendable, CaseIterable, Identifiable {

    /// Ordered highest first, which is how the selector reads.
    case a
    case b
    case c
    case d

    var id: String { rawValue }

    /// The value stored in `users/{uid}.targetGrade`.
    ///
    /// Written in full rather than derived from the case name, for the same reason as
    /// `LearningStyle.storageValue`: this is a wire format read by whatever queries the
    /// profile, so it is a compatibility surface. The uppercase letters are also what a
    /// transcript shows.
    var storageValue: String {
        switch self {
        case .a: "A"
        case .b: "B"
        case .c: "C"
        case .d: "D"
        }
    }

    /// The non-localised name, used as the selector's segment title. See the note above on
    /// why a grade letter is not translated.
    var displayName: String { storageValue }

    /// How high the student is aiming, 1 (a pass) to 4 (the top grade).
    ///
    /// This is what later features should read. F06's planner compares it to decide how
    /// much revision to schedule, and that comparison must survive a change of scale —
    /// which is exactly why it is a separate value from the stored letter.
    var ambition: Int {
        switch self {
        case .a: 4
        case .b: 3
        case .c: 2
        case .d: 1
        }
    }
}
