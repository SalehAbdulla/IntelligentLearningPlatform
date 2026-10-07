//
//  TaxonomyTerm.swift
//  StudyForge
//
//  F12: one term in the platform's controlled vocabulary (docs/03 section K, K06).
//
//  WHY SUBJECTS AND TAGS SHARE ONE TYPE
//  ------------------------------------
//  They are the same thing with different scope: a subject is a coarse category content is filed
//  under, a tag is a finer one. Both are named, both are counted, both get merged when they drift.
//  One type with a `kind` keeps K06 a single screen, which is what the frame draws.
//
//  WHY THE USAGE COUNT IS STORED
//  -----------------------------
//  K06 asks for a usage count per term, and it is what makes "merge duplicates" safe: an admin can
//  see that "Bio" is used 3 times before folding it into "Biology" (which gains those 3), rather than
//  merging blind and orphaning content.
//

import Foundation

/// What kind of term this is.
enum TaxonomyKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case subject
    case tag

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subject: L10n.adminTaxonomyKindSubject.string
        case .tag: L10n.adminTaxonomyKindTag.string
        }
    }
}

/// One subject or tag.
struct TaxonomyTerm: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var name: String
    var kind: TaxonomyKind

    /// How many pieces of content carry this term. Drives the count in K06 and the merge maths.
    var usageCount: Int

    /// Display order within its kind. Rewritten by drag-to-reorder.
    var sortIndex: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        kind: TaxonomyKind,
        usageCount: Int = 0,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.usageCount = usageCount
        self.sortIndex = sortIndex
    }

    var isUnused: Bool { usageCount == 0 }
}

#if DEBUG
extension TaxonomyTerm {

    /// A small, obviously-fake vocabulary, for previews.
    ///
    /// DEBUG only, and never seeded on device: a real taxonomy is shared platform data, and a
    /// shipping build inventing terms would let an admin edit a vocabulary that is not real.
    static let samples: [TaxonomyTerm] = [
        TaxonomyTerm(id: "t_1", name: "Biology", kind: .subject, usageCount: 42, sortIndex: 0),
        TaxonomyTerm(id: "t_2", name: "Bio", kind: .subject, usageCount: 3, sortIndex: 1),
        TaxonomyTerm(id: "t_3", name: "Mathematics", kind: .subject, usageCount: 28, sortIndex: 2),
        TaxonomyTerm(id: "t_4", name: "exam", kind: .tag, usageCount: 61, sortIndex: 0),
        TaxonomyTerm(id: "t_5", name: "revision", kind: .tag, usageCount: 34, sortIndex: 1),
        TaxonomyTerm(id: "t_6", name: "draft", kind: .tag, usageCount: 0, sortIndex: 2),
    ]
}
#endif
