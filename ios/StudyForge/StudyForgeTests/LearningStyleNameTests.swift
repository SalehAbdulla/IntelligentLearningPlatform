//
//  LearningStyleNameTests.swift
//  StudyForgeTests
//
//  The shared style copy that B02's cards and B04's summary both read. A blank name would
//  reach a student as an empty card or an empty summary line, and the switch being exhaustive
//  only helps if every case actually resolves to copy.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Learning style names")
struct LearningStyleNameTests {

    @Test("Every style has a non-empty name and preview")
    func everyStyleIsNamed() {
        for style in LearningStyle.allCases {
            #expect(!LearningStyleName.string(for: style).isEmpty, "\(style) has no name")
            #expect(!LearningStyleName.preview(for: style).isEmpty, "\(style) has no preview")
        }
    }

    @Test("No two styles share a name, so a summary line cannot be ambiguous")
    func namesAreDistinct() {
        let names = LearningStyle.allCases.map(LearningStyleName.string(for:))

        #expect(Set(names).count == LearningStyle.allCases.count)
    }

    @Test("The name is the catalogue's, not the enum's unlocalised display name")
    func namesComeFromTheCatalogue() {
        // `LearningStyle.displayName` is English and unlocalised by design; the screen copy
        // must come from `L10n`, which is what makes the Arabic build correct.
        let expected = [
            LearningStyle.visual: L10n.profileStyleVisualTitle.string,
            .verbal: L10n.profileStyleVerbalTitle.string,
            .readWrite: L10n.profileStyleReadWriteTitle.string,
            .kinesthetic: L10n.profileStyleKinestheticTitle.string,
        ]

        for (style, name) in expected {
            #expect(LearningStyleName.string(for: style) == name)
        }
    }
}
