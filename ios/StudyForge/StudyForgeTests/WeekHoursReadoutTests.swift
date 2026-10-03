//
//  WeekHoursReadoutTests.swift
//  StudyForgeTests
//
//  The plural rule behind the study-hours readout.
//
//  Worth its own suite because the failure is invisible in English and embarrassing in
//  Arabic: the slider's low end passes through 1, 2 and 3, which Arabic renders as three
//  different words, and a single `%d ساعات` would read "1 ساعات" at the bottom of the range.
//  The category selection is pure, so it is tested as data rather than by reading rendered
//  strings — which also keeps these tests independent of the language the tests run in.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Week hours readout")
struct WeekHoursReadoutTests {

    @Test(
        "A count picks the plural category its language needs",
        arguments: [
            (1, WeekHoursReadout.Form.one),
            (2, WeekHoursReadout.Form.two),
            (3, WeekHoursReadout.Form.few),
            (5, WeekHoursReadout.Form.few),
            (10, WeekHoursReadout.Form.few),
            (11, WeekHoursReadout.Form.many),
            (12, WeekHoursReadout.Form.many),
            (40, WeekHoursReadout.Form.many),
        ]
    )
    func formMatchesTheCount(hours: Int, expected: WeekHoursReadout.Form) {
        #expect(WeekHoursReadout.form(for: hours) == expected)
    }

    @Test("The category boundaries are Arabic's, not English's")
    func boundariesAreTheLanguageBoundaries() {
        // English has two forms, so a naive implementation would treat 1 as special and
        // everything else as plural. Arabic splits 2 out on its own AND ends its `few` at
        // 10. Both boundaries are asserted here because both are one character away from
        // being wrong (`case 3...11`, or `case 2` folded into `many`).
        #expect(WeekHoursReadout.form(for: 2) == .two)
        #expect(WeekHoursReadout.form(for: 11) == .many)
        #expect(WeekHoursReadout.form(for: 10) == .few)
    }

    @Test("The whole slider range is covered by a category")
    func everySelectableHourHasAForm() {
        // 1...40 is `ProfileSetupStudyGoalsViewModel.hoursRange`. A gap here would fall
        // through to `many` and read as a counted phrase for a count that needs a fixed one.
        for hours in ProfileSetupStudyGoalsViewModel.hoursRange {
            #expect(WeekHoursReadout.Form.allCases.contains(WeekHoursReadout.form(for: hours)))
        }
    }

    @Test("The fixed forms carry no leftover format specifier")
    func fixedFormsHaveNoPlaceholder() {
        // `one` and `two` are phrases the number is already part of ("ساعتان" means "two
        // hours"), so they are resolved with no arguments. A stray `%d` in one of them would
        // be handed to `String(format:)` with nothing to substitute, which is undefined
        // rather than merely ugly — so it is asserted, not assumed.
        for hours in [1, 2] {
            #expect(
                !WeekHoursReadout.string(for: hours).contains("%"),
                "the fixed form for \(hours) still expects an argument"
            )
        }
    }

    @Test("The counted forms include the number")
    func countedFormsShowTheNumber() {
        // The readout is the only place a student can SEE the slider's value, so a dropped
        // placeholder would leave them moving a control with no visible setting.
        #expect(WeekHoursReadout.string(for: 12).contains("12"))
    }

    @Test("Different counts read differently")
    func eachCategoryReadsDifferently() {
        let readouts = [1, 2, 3, 12].map(WeekHoursReadout.string(for:))
        #expect(Set(readouts).count == readouts.count, "two categories produced identical copy")
    }

    @Test("A negative count reads as its magnitude rather than falling through")
    func negativeCountsUseTheirMagnitude() {
        // The slider cannot produce a negative, but the function is not the slider's private
        // helper: it is a general readout, and `-1` selecting `many` would be silently wrong
        // in any future caller.
        #expect(WeekHoursReadout.form(for: -1) == .one)
    }
}
