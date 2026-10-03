//
//  SFMonogramTests.swift
//  StudyForgeTests
//
//  The initials rule behind the avatar. It lives with the component rather than in each screen's
//  view model, so this is the single place it is pinned — B06 and B07 both draw it.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Monogram initials")
struct SFMonogramTests {

    @Test("Two name parts give two letters")
    func twoPartsGiveTwoLetters() {
        #expect(SFMonogram.initials(from: "Sara Ali") == "SA")
    }

    @Test("One name part gives one letter — 'up to two', not 'always two'")
    func onePartGivesOneLetter() {
        #expect(SFMonogram.initials(from: "Madonna") == "M")
    }

    @Test("Case does not matter, and the result is upper-cased")
    func resultIsUpperCased() {
        #expect(SFMonogram.initials(from: "sara ali") == "SA")
    }

    @Test("A hyphen separates parts too, and a third part is ignored")
    func partsAreSplitAndLimited() {
        #expect(SFMonogram.initials(from: "Jean-Luc Picard") == "JL")
        #expect(SFMonogram.initials(from: "Ana Maria Lopez") == "AM")
    }

    @Test("Surrounding whitespace is not a name part")
    func whitespaceIsTrimmed() {
        #expect(SFMonogram.initials(from: "  Sara Ali  ") == "SA")
    }

    @Test("Nothing to take a letter from gives a deliberate placeholder")
    func emptyGivesPlaceholder() {
        #expect(SFMonogram.initials(from: "") == "?")
        #expect(SFMonogram.initials(from: "   ") == "?")
    }
}
