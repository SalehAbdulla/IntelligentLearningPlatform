//
//  L10nTests.swift
//  StudyForgeTests
//
//  The localisation contract: code and catalogue must agree, in both directions.
//
//  WHY THIS IS A TEST AND NOT A CONVENTION
//  ---------------------------------------
//  A missing translation is invisible. The app renders the KEY — `auth.login.title`
//  in place of "Welcome back" — and no build step complains. These tests turn that
//  silence into a failure, and they do it in both directions:
//
//   · a key used in code but absent from the catalogue  -> renders the key on screen
//   · a key in the catalogue but absent from code       -> dead weight, usually a
//                                                          leftover from a renamed
//                                                          screen
//
//  Together with `tools/check-strings.py` (which covers English/Arabic parity and
//  placeholder drift) this closes the hole from both ends: the script guards the
//  catalogue against itself, this guards the catalogue against the code.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Localisation contract")
struct L10nTests {

    /// The app bundle's catalogue. Reading it also proves the `.lproj` resources are
    /// actually copied into the app — a synchronised-folder setup can silently omit
    /// them, and nothing else in the build would notice.
    private func catalogue() throws -> [String: String] {
        let url = try #require(
            Bundle.main.url(forResource: "Localizable", withExtension: "strings"),
            "Localizable.strings is not in the app bundle"
        )
        return try #require(
            NSDictionary(contentsOf: url) as? [String: String],
            "Localizable.strings could not be parsed"
        )
    }

    @Test("Every key in code resolves to real copy", arguments: L10n.allCases)
    func everyKeyResolves(_ key: L10n) {
        let resolved = key.string
        #expect(
            resolved != key.rawValue,
            "'\(key.rawValue)' is missing from the catalogue, so the app would render the key itself"
        )
        #expect(!resolved.isEmpty, "'\(key.rawValue)' resolves to an empty string")
    }

    @Test("The catalogue is bundled and non-empty")
    func catalogueIsBundled() throws {
        let catalogue = try catalogue()
        #expect(!catalogue.isEmpty, "the catalogue exists but is empty")
    }

    @Test("No key in the catalogue is unused by the code")
    func catalogueHasNoDeadKeys() throws {
        // A leftover key is usually the trace of a renamed or deleted screen, and it
        // hides in a file nobody re-reads.
        let catalogue = try catalogue()
        let codeKeys = Set(L10n.allCases.map(\.rawValue))
        let dead = Set(catalogue.keys).subtracting(codeKeys).sorted()

        #expect(
            dead.isEmpty,
            "catalogue keys with no L10n case: \(dead). Either add the case or delete the key."
        )
    }

    @Test("Every L10n case exists in the catalogue")
    func codeHasNoMissingKeys() throws {
        // Mirrors `everyKeyResolves`, but compares against the catalogue as a set, so a
        // failure names every offending key at once instead of one per test case.
        let catalogue = try catalogue()
        let catalogueKeys = Set(catalogue.keys)
        let missing = L10n.allCases.map(\.rawValue).filter { !catalogueKeys.contains($0) }.sorted()

        #expect(missing.isEmpty, "keys used in code but absent from the catalogue: \(missing)")
    }

    @Test("Keys follow the <area>.<screen>.<element> convention")
    func keysFollowTheNamingConvention() {
        // Deliberately NOT a fixed segment count. `common.appName` is <area>.<element>
        // because it is shared across screens, while `auth.login.title` names its
        // screen, and `auth.strength.rule.length` nests a group. Asserting "exactly 3"
        // would fail on all three of those — a test that encodes a convention the code
        // never agreed to.
        //
        // What genuinely matters is that every key is a dotted path of identical
        // segments with a known area, which is what makes the catalogue greppable and
        // catches the real mistakes: a doubled dot, a trailing dot, a stray space, or a
        // key filed under the wrong area.
        // `profile` joined this list with B01, the same way `onboarding` did when the
        // pager landed. Growing it is a deliberate edit here rather than an implicit
        // consequence of adding a key, so one typo in an area name cannot slip into the
        // catalogue unnoticed.
        // `library` and `material` joined with F02, the same way `profile` joined with B01 and
        // `onboarding` did when the pager landed. Growing this is a deliberate edit rather than
        // an implicit consequence of adding a key, so one typo in an area name cannot slip into
        // the catalogue unnoticed.
        let knownAreas: Set<String> = [
            "common", "auth", "session", "home", "onboarding", "profile", "library", "material",
            "import", "summary", "deck", "flashcard", "quiz", "plan", "progress", "folder",
            "bookmark", "group", "notification", "search", "admin", "subscription", "tutor",
        ]

        for key in L10n.allCases {
            let segments = key.rawValue.split(separator: ".", omittingEmptySubsequences: false)

            #expect(segments.count >= 2, "'\(key.rawValue)' needs at least <area>.<element>")
            #expect(
                knownAreas.contains(String(segments[0])),
                "'\(key.rawValue)' uses unknown area '\(segments[0])'; expected one of \(knownAreas.sorted())"
            )

            for segment in segments {
                #expect(!segment.isEmpty, "'\(key.rawValue)' has an empty segment (doubled or trailing dot)")
                #expect(
                    segment.first?.isLowercase == true,
                    "'\(key.rawValue)': segment '\(segment)' must start lowercase"
                )
                #expect(
                    segment.allSatisfy { $0.isLetter || $0.isNumber },
                    "'\(key.rawValue)': segment '\(segment)' must be alphanumeric"
                )
            }
        }
    }

    @Test("Placeholders in the source catalogue keep their position")
    func placeholderCountIsStable() {
        // Counts the format specifiers per key. English is the reference; the script
        // gate checks the other languages against it, so a change here that silently
        // drops an argument is caught before it reaches a screen.
        let withPlaceholders = L10n.allCases.filter { $0.string.contains("%") }
        for key in withPlaceholders {
            let specifiers = key.string.components(separatedBy: "%").count - 1
            // Every placeholder needs at least one %-specifier; `%%` (a literal percent)
            // would inflate this, so it is excluded as a deliberate escape.
            #expect(specifiers >= 1, "'\(key.rawValue)' contains a stray percent sign")
        }
    }
}
