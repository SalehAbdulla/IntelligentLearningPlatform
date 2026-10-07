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
    //
    // Every token is built on a SYSTEM TEXT STYLE (`Font.system(_:weight:)`), never a fixed
    // point size. That is the whole reason the ladder scales with Dynamic Type up to AX5, which
    // docs/06 §1.2 requires. `Font.system(size:)` would render identically at the default
    // setting and then stay put at accessibility sizes, silently breaking the promise.
    //
    // Each style below is pinned to the text style whose default matches the design ladder, so
    // the default size is unchanged: largeTitle 34, title 28, title2 22, headline 17 (semibold),
    // body 17, callout 16, subheadline 15, footnote 13, caption 12 (caption1).

    /// Splash, score rings, large numerals.
    static let sfDisplayL = Font.system(.largeTitle, weight: .bold)
    /// Screen titles.
    static let sfTitleL   = Font.system(.title, weight: .bold)
    /// Section headers and card titles.
    static let sfTitleM   = Font.system(.title2, weight: .semibold)
    /// List-row titles and tab labels.
    static let sfTitleS   = Font.system(.headline, weight: .semibold)
    /// Default body text.
    static let sfBody     = Font.system(.body)
    /// Emphasis within body text.
    static let sfBodyEmph = Font.system(.body, weight: .semibold)
    /// Secondary body text.
    static let sfCallout  = Font.system(.callout)
    /// Overlines and grouped-section headers.
    static let sfSubhead  = Font.system(.subheadline, weight: .semibold)
    /// Metadata and timestamps.
    static let sfFootnote = Font.system(.footnote)
    /// Chips and badges — never below this.
    static let sfCaption  = Font.system(.caption)
    /// OTP codes, invite codes and charge references.
    static let sfMono     = Font.system(.subheadline, design: .monospaced)
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
