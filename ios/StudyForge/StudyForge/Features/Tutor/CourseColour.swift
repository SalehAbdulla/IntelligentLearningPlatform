//
//  CourseColour.swift
//  StudyForge
//
//  F11 — the cover colours J03 offers and every course surface draws.
//
//  WHY THE PALETTE LIVES IN THE VIEW LAYER
//  ---------------------------------------
//  `Course.colourIndex` is an INDEX into a palette rather than a stored hex string, so a
//  design-token change repaints every course instead of leaving stale colours baked into
//  documents. That only works if the palette is the DESIGN SYSTEM's, which means this file is
//  presentation, not domain — `Course` stays Foundation-only and previewable without SwiftUI.
//

import SwiftUI

/// The cover palette. Indices are stable: course 2 keeps its colour when a new one is added
/// in the middle only if nobody reorders this array, so append rather than insert.
enum CourseColour {

    /// The design system's own subject palette.
    ///
    /// Reused rather than invented: docs/06 introduces these eight hues as *"eight hues for
    /// course tags, calendar blocks and radar axes"* — and a course cover is exactly a course
    /// tag at card size. A private list here would drift from the tokens the calendar and the
    /// radar already use.
    static let palette: [Color] = ColorTokens.Subject.all

    /// How many colours a course may choose from.
    static var count: Int { palette.count }

    /// The colour for an index, wrapped so a stale document can never index out of bounds and
    /// crash a list.
    static func colour(at index: Int) -> Color {
        guard count > 0 else { return ColorTokens.primary }
        return palette[((index % count) + count) % count]
    }
}

extension Course {

    /// The course's cover colour.
    var coverColour: Color { CourseColour.colour(at: colourIndex) }
}
