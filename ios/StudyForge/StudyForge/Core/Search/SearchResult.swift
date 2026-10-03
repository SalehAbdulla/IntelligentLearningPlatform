//
//  SearchResult.swift
//  StudyForge
//
//  M05 — one line in the unified search results (docs/03 §M, P0).
//
//  WHY SEARCH IS A READ OVER THE EXISTING STORES
//  ---------------------------------------------
//  The design searches "materials, summaries, decks, quizzes, folders, bookmarks" — six things the
//  app already keeps. Inventing a seventh index would mean a second copy of every title to keep in
//  step, so search reads the six stores and projects each hit into one `SearchResult`. The
//  projection is what gives the results screen a uniform row without the stores agreeing on a
//  shape, which they never will: a deck has cards, a folder has members.
//
//  WHY THE HAYSTACK IS ON THE RESULT
//  ---------------------------------
//  A result matches on more than its title — a material matches its tags and its extracted text, a
//  deck matches what is written on its cards. `haystack` is that matchable text, built once when the
//  corpus is loaded so filtering is a string comparison rather than a second pass over six models.
//  It is NEVER rendered; the row shows `title` and `subtitle`.
//

import Foundation

/// What kind of thing a hit is. M05's result-type tabs, and the scope chips.
enum SearchResultKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case material
    case summary
    case deck
    case quiz
    case folder
    case bookmark

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .material: "doc.richtext"
        case .summary: "text.alignleft"
        case .deck: "rectangle.stack"
        case .quiz: "checklist"
        case .folder: "folder"
        case .bookmark: "bookmark"
        }
    }

    /// The localised name, for the scope chip and the row's accessibility label.
    var title: String {
        switch self {
        case .material: L10n.searchKindMaterial.string
        case .summary: L10n.searchKindSummary.string
        case .deck: L10n.searchKindDeck.string
        case .quiz: L10n.searchKindQuiz.string
        case .folder: L10n.searchKindFolder.string
        case .bookmark: L10n.searchKindBookmark.string
        }
    }
}

/// One hit, projected from whatever store it came from.
struct SearchResult: Identifiable, Equatable, Sendable {

    /// Kinds can share a reference id (a material and a deck both being "m1"), so the identity is
    /// the pair — otherwise two hits would collide in a list.
    let id: String

    let kind: SearchResultKind
    let referenceId: String
    let title: String
    let subtitle: String

    /// Everything this hit matches on. Never rendered — see the note at the top of the file.
    let haystack: String

    init(kind: SearchResultKind, referenceId: String, title: String, subtitle: String, haystack: String) {
        self.id = "\(kind.rawValue):\(referenceId)"
        self.kind = kind
        self.referenceId = referenceId
        self.title = title
        self.subtitle = subtitle
        self.haystack = haystack.lowercased()
    }

    /// Whether this hit matches a query. Case-insensitive, substring — the behaviour a search field
    /// has trained everyone to expect.
    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return false }
        return haystack.contains(needle)
    }
}