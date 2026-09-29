//
//  TypeScale.swift
//  StudyForge
//
//  Type tokens. System font (SF Pro) so Dynamic Type and Arabic glyph shaping
//  come for free — a deliberate accessibility decision, not a shortcut.
//  Scale and rules: docs/06-DESIGN-SYSTEM.md §1.2
//

import SwiftUI

extension Font {

    // MARK: Scale
    //
    // Minimum body size is 17 pt. Nothing user-facing goes below 11 pt.
    // All sizes scale with Dynamic Type up to AX5.

    /// Splash, score rings, large numerals.
    static let sfDisplayL = Font.system(size: 34, weight: .bold)
    /// Screen titles.
    static let sfTitleL   = Font.system(size: 28, weight: .bold)
    /// Section headers and card titles.
    static let sfTitleM   = Font.system(size: 22, weight: .semibold)
    /// List-row titles and tab labels.
    static let sfTitleS   = Font.system(size: 17, weight: .semibold)
    /// Default body text.
    static let sfBody     = Font.system(size: 17, weight: .regular)
    /// Emphasis within body text.
    static let sfBodyEmph = Font.system(size: 17, weight: .semibold)
    /// Secondary body text.
    static let sfCallout  = Font.system(size: 16, weight: .regular)
    /// Overlines and grouped-section headers.
    static let sfSubhead  = Font.system(size: 15, weight: .semibold)
    /// Metadata and timestamps.
    static let sfFootnote = Font.system(size: 13, weight: .regular)
    /// Chips and badges — never below this.
    static let sfCaption  = Font.system(size: 12, weight: .regular)
    /// OTP codes, invite codes and charge references.
    static let sfMono     = Font.system(size: 15, weight: .regular, design: .monospaced)
}

/// Accessibility profiles that adjust typography without changing the scale ladder.
/// Toggled from `20_Settings_Accessibility` (docs/03-SCREEN-INVENTORY.md, group B).
enum TypeProfile: String, Codable, Sendable, CaseIterable {
    case standard
    case dyslexiaFriendly

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .dyslexiaFriendly: "Dyslexia friendly"
        }
    }

    /// Extra line height as a multiple of the base line height.
    /// Dyslexia-friendly text needs materially more leading, not just a different face.
    var lineHeightMultiplier: Double {
        switch self {
        case .standard: 1.0
        case .dyslexiaFriendly: 1.4
        }
    }

    /// Extra tracking. Note: Arabic must never be negatively tracked.
    var tracking: Double {
        switch self {
        case .standard: 0
        case .dyslexiaFriendly: 0.05
        }
    }
}
