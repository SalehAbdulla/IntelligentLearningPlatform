//
//  Spacing.swift
//  StudyForge
//
//  Layout tokens: a strict 4 pt grid plus the radius and motion ladders.
//  Only these values are permitted — see docs/06-DESIGN-SYSTEM.md §1.3–1.4
//

import SwiftUI

/// Spacing scale. A strict 4 pt grid; arbitrary values are not allowed.
enum Spacing {
    /// 4 — icon to label.
    static let s1: CGFloat = 4
    /// 8 — inside chips and badges.
    static let s2: CGFloat = 8
    /// 12 — tight card padding, list-row vertical.
    static let s3: CGFloat = 12
    /// 16 — **default** screen margin and card padding.
    static let s4: CGFloat = 16
    /// 20 — between related groups.
    static let s5: CGFloat = 20
    /// 24 — between sections.
    static let s6: CGFloat = 24
    /// 32 — before major headings.
    static let s8: CGFloat = 32
    /// 40 — empty-state spacing.
    static let s10: CGFloat = 40
    /// 48 — breathing room above a primary CTA.
    static let s12: CGFloat = 48
}

/// Corner radii.
enum Radius {
    /// 8 — chips, tags, small inputs.
    static let s: CGFloat = 8
    /// 12 — buttons, text fields, grouped lists.
    static let m: CGFloat = 12
    /// 16 — cards and sheets.
    static let l: CGFloat = 16
    /// 24 — hero cards and modals.
    static let xl: CGFloat = 24
    /// Fully rounded — avatars, pills, progress rings.
    static let full: CGFloat = 999
}

/// Layout constants.
enum Layout {
    /// The single horizontal screen margin used everywhere.
    static let screenMargin: CGFloat = Spacing.s4
    /// Content cap so iPad layouts stay readable.
    static let maxContentWidth: CGFloat = 640
    /// Minimum tappable area. Apple's guidance, and a WCAG target-size requirement.
    static let minTouchTarget: CGFloat = 44
}

/// Motion ladder. Every animation respects Reduce Motion — see `Motion.respecting(_:)`.
enum Motion {

    /// 100 ms — press feedback, checkboxes.
    static let instant: Animation = .easeOut(duration: 0.10)
    /// 180 ms — tab switch, chip selection.
    static let quick: Animation = .easeOut(duration: 0.18)
    /// 280 ms — card expand, list insertion.
    static let standard: Animation = .spring(response: 0.28, dampingFraction: 0.8)
    /// 420 ms — flashcard flip, streak increment, score ring.
    static let emphasis: Animation = .spring(response: 0.42, dampingFraction: 0.7)
    /// 320 ms — sheet presentation and dismissal.
    static let sheet: Animation = .spring(response: 0.32, dampingFraction: 1.0)

    /// Returns a cross-fade when Reduce Motion is on, or the given animation otherwise.
    /// No animation in the app should bypass this.
    static func respecting(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : animation
    }
}
