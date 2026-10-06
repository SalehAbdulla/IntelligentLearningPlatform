//
//  WeekHoursReadout.swift
//  StudyForge
//
//  Turns a weekly-hours figure into a localised readout — "1 hour a week", "12 hours a
//  week", "ساعتان أسبوعيًا".
//
//  WHY THIS IS NOT JUST `L10n.x.string(hours)`
//  ------------------------------------------
//  Because Arabic does not have two plural forms, it has six categories, and this slider
//  steps through all of the low ones: a student dragging it down passes through 1, 2 and 3,
//  which in Arabic are three different words. `%d ساعات` would read as "1 ساعات" at the
//  bottom of the range, and a single `%d ساعة` would read as "2 ساعة" — wrong in a way an
//  Arabic-speaking assessor would see immediately, on a screen whose whole job is to be
//  clear about a number.
//
//  So the *form* is chosen from the count using the CLDR categories, and the catalogue
//  supplies wording for each. English needs two of the four (`one` and `many`); Arabic
//  needs all four. A form a language does not distinguish is still defined in its catalogue
//  rather than left missing, because the choice belongs to the language, not to the caller.
//
//  The same reasoning as `TargetGrade`: the app reasons about the RULE, the catalogue holds
//  the words.
//

import Foundation

enum WeekHoursReadout {

    /// Which plural category a count falls into.
    ///
    /// Named for the CLDR categories rather than for their English names, because the
    /// mapping is Arabic's: `few` is 3–10 and `many` is 11 and above, which is not how
    /// English thinks about numbers at all.
    enum Form: Sendable, CaseIterable {
        case one
        case two
        case few
        case many

        /// The catalogue key carrying this form's wording.
        var key: L10n {
            switch self {
            case .one: .profileStudyGoalsHoursOne
            case .two: .profileStudyGoalsHoursTwo
            case .few: .profileStudyGoalsHoursFew
            case .many: .profileStudyGoalsHoursMany
            }
        }
    }

    /// The category for a count.
    ///
    /// Covers the slider's whole range (1–40). Arabic's `2` is a category of its own, and
    /// 11+ collapses into `many`; the 100+ case that CLDR sends back to `few` cannot occur
    /// here, which is why the range is asserted by the view rather than handled by a branch
    /// nothing can reach.
    static func form(for hours: Int) -> Form {
        switch abs(hours) {
        case 1: .one
        case 2: .two
        case 3...10: .few
        default: .many
        }
    }

    /// The readout for a count, in the device's language.
    static func string(for hours: Int) -> String {
        switch form(for: hours) {
        // `one` and `two` are fixed phrases: the number is part of the wording, which is
        // what makes them read naturally in Arabic, where "ساعتان" already means "two
        // hours" and repeating the digit would be wrong.
        case .one, .two: form(for: hours).key.string()
        case .few, .many: form(for: hours).key.string(hours)
        }
    }
}
