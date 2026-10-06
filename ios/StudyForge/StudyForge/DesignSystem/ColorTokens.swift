//
//  ColorTokens.swift
//  StudyForge
//
//  THE colour source of truth. Figma variables mirror these names exactly;
//  a token changes in both places or it does not change.
//  Rationale, contrast ratios and AA/AAA verdicts: docs/06-DESIGN-SYSTEM.md §1.1
//

import SwiftUI

// MARK: - Hex helper

extension Color {
    /// Builds a colour from a 0xRRGGBB literal.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A colour that resolves differently in light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Tokens

/// Brand and semantic colour tokens.
///
/// **The rule most teams get wrong:** `accent` (Ember) and the semantic fills are
/// *fill* colours, not *text* colours. White on Ember fails WCAG AA (2.8:1), so any
/// label sitting on an Ember or success fill must use `onAccent`, which is near-black.
enum ColorTokens {

    // MARK: Brand

    /// Apple's blue family, darkened to #0062CC so `primary` also clears AA as *text*:
    /// 5.80:1 on the light surface, 5.55:1 on `surfaceVariant`, 5.00:1 on
    /// `primaryContainer` and 4.97:1 on the most tinted point of the canvas. `primary`
    /// is used as text in 26 places, and Apple's #007AFF (4.0:1 on white) and #0071E3
    /// (4.02:1 on the tint) are both too light for that. Dark mode keeps Apple's #0A84FF.
    static let primary            = Color(light: 0x0062CC, dark: 0x0A84FF)
    static let primaryContainer   = Color(light: 0xE1F0FF, dark: 0x0B2B4A)
    /// 8.79:1 on `primaryContainer` in light mode, 10.11:1 in dark. AAA both ways.
    static let onPrimaryContainer = Color(light: 0x00427A, dark: 0xB9DCFF)

    /// Ember — the AI/generation accent. **Fill only, never text on light.**
    static let accent             = Color(light: 0xF97316, dark: 0xFB923C)

    /// Text placed on `accent` or other saturated fills. 6.4:1 on Ember.
    static let onAccent           = Color(hex: 0x0F172A)

    /// Gold — achievement badges and highlights. Decorative only.
    static let accentGold         = Color(light: 0xFACC15, dark: 0xFDE047)

    /// Ember as *text*, the darker burnt orange that passes AA (5.2:1 on `surface`,
    /// 4.9:1 on the glass stat card). Use this, never `accent`, for ember-coloured text.
    static let accentText         = Color(light: 0xC2410C, dark: 0xFDBA74)

    /// Teal — collaboration surfaces. **Fill only.**
    static let secondary          = Color(light: 0x14B8A6, dark: 0x2DD4BF)

    /// Teal as *text*. 5.5:1 on `surface`, 5.2:1 on the glass stat card over the
    /// most tinted canvas point, so it clears AA where the fill token does not.
    static let secondaryText      = Color(light: 0x0F766E, dark: 0x5EEAD4)

    // MARK: Semantic

    static let success            = Color(light: 0x10B981, dark: 0x34D399)
    /// Success as *text* — the darker green that actually passes AA (5.5:1).
    static let successText        = Color(light: 0x047857, dark: 0x6EE7B7)
    static let warning            = Color(light: 0xF59E0B, dark: 0xFBBF24)
    /// Amber as *text*, the darker shade that passes AA (5.0:1 on `surface`, 4.8:1 on
    /// the glass stat card). Use this, never `warning`, for amber-coloured text.
    static let warningText        = Color(light: 0xB45309, dark: 0xFCD34D)
    static let error              = Color(light: 0xDC2626, dark: 0xF87171)
    static let onError            = Color(hex: 0xFFFFFF)

    // MARK: Surfaces

    static let surface            = Color(light: 0xFFFFFF, dark: 0x0B1220)
    static let surfaceVariant     = Color(light: 0xF8FAFC, dark: 0x131C2E)
    static let outline            = Color(light: 0xE2E8F0, dark: 0x263149)

    // MARK: Text

    /// 17.9:1 on light surface — AAA.
    static let textPrimary        = Color(light: 0x0F172A, dark: 0xF1F5F9)
    /// 7.6:1 on light surface — AAA.
    static let textSecondary      = Color(light: 0x475569, dark: 0xCBD5E1)
    /// 2.6:1 — **disabled and decorative use only, never body text.**
    static let textTertiary       = Color(light: 0x94A3B8, dark: 0x64748B)

    // MARK: Subject coding

    /// Eight hues for course tags, calendar blocks and radar axes.
    /// Used as fills with `onAccent` labels, never as text.
    enum Subject {
        static let blue   = Color(hex: 0x0062CC)
        static let teal   = Color(hex: 0x14B8A6)
        static let rose   = Color(hex: 0xF43F5E)
        static let amber  = Color(hex: 0xF59E0B)
        static let mint   = Color(hex: 0x00C7BE)
        static let cyan   = Color(hex: 0x06B6D4)
        static let lime   = Color(hex: 0x84CC16)
        static let slate  = Color(hex: 0x64748B)

        /// Eight hues, deliberately with no violet or pink in the set, so a stack of
        /// course tags cannot assemble itself into the AI-gradient look.
        static let all: [Color] = [blue, teal, rose, amber, mint, cyan, lime, slate]

        /// Deterministic colour for a subject so the same course always looks the same.
        static func color(for key: String) -> Color {
            guard !key.isEmpty else { return slate }
            let hash = key.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
            return all[hash % all.count]
        }
    }
}
