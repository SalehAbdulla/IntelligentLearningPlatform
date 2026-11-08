//
//  Appearance.swift
//  StudyForge
//
//  Rule A — dark mode is the base and the default.
//
//  WHY THE DEFAULT LIVES IN THE ENUM, NOT IN THE VIEW
//  --------------------------------------------------
//  `@AppStorage` returns the value declared at the property when the key has never been
//  written, so declaring the default once here means "first launch is dark" is a property of
//  the model rather than of whichever view happens to read it first. Any view that reads the
//  key gets the same answer, and the Settings picker cannot drift from the root scheme.
//
//  WHY `system` IS `nil`, NOT A THIRD COLOUR SCHEME
//  ------------------------------------------------
//  `.preferredColorScheme(nil)` is how SwiftUI is told "no opinion, follow the system".
//  Storing `system` as its own scheme would force us to choose a scheme at runtime and
//  re-implement the system's own decision.
//
//  WHY RAW STRING STORAGE
//  ----------------------
//  `@AppStorage` can persist a `RawRepresentable` whose `RawValue` is `String`, so the
//  preference round-trips as "dark" / "light" / "system" in `UserDefaults`. A migration that
//  renamed a case would surface as an unknown raw value and fall back to `.dark`, which is
//  the safe direction for this app.
//

import SwiftUI

/// The user's appearance preference, persisted across launches.
enum AppAppearance: String, CaseIterable, Identifiable, Sendable {

    case dark
    case light
    case system

    /// The `UserDefaults` key. One declaration, read by the root view and by Settings.
    static let storageKey = "studyforge.appearance"

    /// First install launches in dark mode regardless of the device setting (Rule A).
    static let `default`: AppAppearance = .dark

    var id: String { rawValue }

    /// What to hand `.preferredColorScheme`. `nil` follows the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }

    var displayName: String {
        switch self {
        case .dark: L10n.appearanceDark.string
        case .light: L10n.appearanceLight.string
        case .system: L10n.appearanceSystem.string
        }
    }

    /// One SF Symbol per option, monochrome, so the row reads as a control rather than as art.
    var symbolName: String {
        switch self {
        case .dark: "moon.fill"
        case .light: "sun.max.fill"
        case .system: "circle.lefthalf.filled"
        }
    }
}

// MARK: - Previews

#Preview("Appearance options") {
    List {
        ForEach(AppAppearance.allCases) { option in
            Label(option.displayName, systemImage: option.symbolName)
        }
    }
}

#Preview("Appearance options — dark") {
    List {
        ForEach(AppAppearance.allCases) { option in
            Label(option.displayName, systemImage: option.symbolName)
        }
    }
    .preferredColorScheme(.dark)
}
