//
//  LearningStyle.swift
//  StudyForge
//
//  How a student prefers material to be presented — a stored profile attribute that the AI
//  layer reads.
//
//  MOVED HERE FROM Core/AI (B02)
//  ----------------------------
//  It lived with the prompt templates, and carried a note saying it belonged with the user
//  profile "long-term". B02 is that long term: the student now CHOOSES a style and the app
//  STORES it, so the dependency direction decided the home. A preference the profile owns
//  should not live behind a strategy layer that consumes it.
//
//  One type still serves both halves, deliberately. A picker that could store a style the
//  prompt builder does not handle would surface later as "the AI ignores my choice", and
//  the fix would be a mapping between two enums — which is the bug, not the fix.
//
//  WHY THE STORED VALUE IS NOT `rawValue`
//  -------------------------------------
//  `readWrite` is a Swift case name; docs/05 §3 documents the stored vocabulary as
//  `readwrite`. Deriving the wire format from the case name would let a rename in Swift
//  silently rewrite the schema, and every document already holding `readwrite` would stop
//  matching. `storageValue` pins the stored value to the documented one, and a test asserts
//  it, so the two cannot drift apart unnoticed.
//

import Foundation

/// The learning-style profile that changes the SHAPE of generated content, not just its
/// wording — the concrete answer to the brief's "support different learning styles"
/// question (docs/00 §2).
enum LearningStyle: String, Sendable, CaseIterable, Identifiable {

    /// Order matters: `allCases` drives the order of B02's cards, and matches the sequence
    /// in docs/03 §B.
    case visual
    case verbal
    case readWrite
    case kinesthetic

    var id: String { rawValue }

    /// The value stored in `users/{uid}.learningStyle`.
    ///
    /// Pinned to the vocabulary in docs/05 §3: `visual | verbal | readwrite | kinesthetic`.
    /// Written in full rather than derived, because this is a wire format: it is read by
    /// anything that queries the profile, which makes it a compatibility surface rather
    /// than an implementation detail.
    var storageValue: String {
        switch self {
        case .visual: "visual"
        case .verbal: "verbal"
        case .readWrite: "readwrite"
        case .kinesthetic: "kinesthetic"
        }
    }

    /// Reads the STORED vocabulary back into a case, or `nil` for a value this build does
    /// not know.
    ///
    /// The counterpart to `storageValue`, and needed for the same reason it exists: the
    /// stored string is the wire format, so decoding must not go through `rawValue` (which
    /// spells `readWrite` differently and would fail on every document already holding
    /// `readwrite`). `nil` rather than a default, because a style this build does not
    /// understand must not be presented to a student as the one they chose.
    init?(storageValue: String) {
        guard let match = Self.allCases.first(where: { $0.storageValue == storageValue }) else {
            return nil
        }
        self = match
    }

    /// The non-localised name, for diagnostics and logs.
    ///
    /// B02 shows a LOCALISED name instead — an Arabic student must not be offered "Read /
    /// write". Keep this for anything that cannot be localised; do not use it as screen copy.
    var displayName: String {
        switch self {
        case .visual: "Visual"
        case .verbal: "Verbal"
        case .readWrite: "Read / write"
        case .kinesthetic: "Hands-on"
        }
    }

    /// How this style changes the generated output. Injected into every prompt.
    var promptDirective: String {
        switch self {
        case .visual:
            "Favour structure the reader can picture: grouped lists, comparisons, and spatial relationships. Where a process is described, present it as ordered steps."
        case .verbal:
            "Favour explanations that read as natural speech, as if explaining aloud to a classmate. Avoid dense notation."
        case .readWrite:
            "Favour well-organised written prose and precise definitions. Include the source's own terminology."
        case .kinesthetic:
            "Favour concrete examples, worked scenarios and 'what would happen if' applications rather than abstract statements."
        }
    }
}
