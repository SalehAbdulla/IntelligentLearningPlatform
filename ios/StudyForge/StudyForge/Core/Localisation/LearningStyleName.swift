//
//  LearningStyleName.swift
//  StudyForge
//
//  The localised name and sample preview for a learning style.
//
//  WHY THIS IS NOT A PROPERTY ON `LearningStyle`
//  --------------------------------------------
//  `LearningStyle` lives in Core/Profile and deliberately carries no user-facing copy: its
//  `displayName` is English and unlocalised (the type documents that, and says not to use it
//  as screen copy), and its `promptDirective` is written for a model, not a student.
//  Resolving a style to the words a student READS is a localisation concern, so it sits with
//  the other readouts — `WeekHoursReadout` is the same shape for a number.
//
//  WHY ONE PLACE RATHER THAN ONE PER SCREEN
//  ---------------------------------------
//  The name is now shown in two places: B02's cards, where the student chooses, and B04's
//  summary, where the choice is read back. A second copy of "Read / write" would be the copy
//  that gets edited when the first is not. The switches here are exhaustive, so a fifth
//  style cannot reach a student as a blank card OR a blank summary line without a compile
//  error naming this file.
//

import Foundation

/// User-facing copy for a learning style.
enum LearningStyleName {

    /// The style's localised name, e.g. "Read / write" / "قراءة وكتابة".
    static func string(for style: LearningStyle) -> String {
        switch style {
        case .visual: L10n.profileStyleVisualTitle.string
        case .verbal: L10n.profileStyleVerbalTitle.string
        case .readWrite: L10n.profileStyleReadWriteTitle.string
        case .kinesthetic: L10n.profileStyleKinestheticTitle.string
        }
    }

    /// The sample-output line B02 puts on the card — what this style changes about the
    /// generated material, in the words a student reads.
    static func preview(for style: LearningStyle) -> String {
        switch style {
        case .visual: L10n.profileStyleVisualPreview.string
        case .verbal: L10n.profileStyleVerbalPreview.string
        case .readWrite: L10n.profileStyleReadWritePreview.string
        case .kinesthetic: L10n.profileStyleKinestheticPreview.string
        }
    }
}
