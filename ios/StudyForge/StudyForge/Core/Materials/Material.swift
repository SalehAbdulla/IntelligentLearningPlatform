//
//  Material.swift
//  StudyForge
//
//  A library item: something the student brought in, plus the text extracted from it.
//
//  WHY THE EXTRACTED TEXT LIVES ON THE RECORD
//  -----------------------------------------
//  Because every AI feature reads it and none of them should run extraction twice. `text` is
//  what a summary is generated from, what a flashcard citation is checked against, and what the
//  library's search field matches on. Keeping it beside the source means extraction happens once,
//  at import, rather than on every generation.
//
//  WHERE THE FILE IS, AND WHY THIS TYPE DOES NOT SAY
//  -----------------------------------------------
//  Cloud Storage is bypassed (D24, docs/09 R21): the raw material stays on the device, because
//  the model that reads it runs there too. So `Material` records WHAT was imported and what came
//  out of it, and where the bytes actually live is the store's business — which is why
//  docs/05 §3's `storagePath` has no counterpart here, deliberately.
//

import Foundation

/// Where a material came from.
enum MaterialSource: String, Sendable, CaseIterable, Identifiable, Codable {

    case pdf
    case image
    case scan
    case link
    case text

    var id: String { rawValue }

    /// The value stored and matched on.
    ///
    /// Written out rather than derived from the case name, for the same reason
    /// `LearningStyle.storageValue` is: it is a wire format (docs/05 §3 lists
    /// `pdf | image | scan | link | text`), so renaming a Swift case must not silently rewrite it.
    var storageValue: String {
        switch self {
        case .pdf: "pdf"
        case .image: "image"
        case .scan: "scan"
        case .link: "link"
        case .text: "text"
        }
    }

    /// The icon a library row shows for this source.
    var symbolName: String {
        switch self {
        case .pdf: "doc.richtext"
        case .image: "photo"
        case .scan: "doc.viewfinder"
        case .link: "link"
        case .text: "text.alignleft"
        }
    }

    /// The localised name, for a row's accessibility label.
    var title: String {
        switch self {
        case .pdf: L10n.materialSourcePdf.string
        case .image: L10n.materialSourceImage.string
        case .scan: L10n.materialSourceScan.string
        case .link: L10n.materialSourceLink.string
        case .text: L10n.materialSourceText.string
        }
    }
}

/// A material in the student's library.
struct Material: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var title: String

    /// The course it is filed under, when it has one. `nil` for a loose import.
    var courseId: String?

    var source: MaterialSource

    /// The text extracted from the source — see the note at the top of the file.
    var text: String

    /// Page count, when the source had pages. `nil` for text and links.
    var pageCount: Int?

    var tags: [String]
    let createdAt: Date

    /// SHA-256 of the text.
    ///
    /// Computed rather than stored, so it cannot drift from the text it describes — and so it is
    /// always defined, which matters twice over: `firestore.rules` requires a `textHash` on
    /// create, and the AI response cache keys on the same digest.
    var textHash: String { ContentHash.sha256Hex(of: text) }

    /// How much text was extracted, for the import summary that proves it worked.
    var characterCount: Int { text.count }

    /// Whether nothing was extractable — a scan with no recognisable text.
    var hasNoText: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    init(
        id: String = UUID().uuidString,
        title: String,
        courseId: String? = nil,
        source: MaterialSource,
        text: String,
        pageCount: Int? = nil,
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.courseId = courseId
        self.source = source
        self.text = text
        self.pageCount = pageCount
        self.tags = tags
        self.createdAt = createdAt
    }
}

#if DEBUG
extension Material {

    /// A small, obviously-fake library, for previews and the `-seedLibrary` launch argument.
    ///
    /// DEBUG only: sample content must never be reachable in a shipping build, where an empty
    /// library is the honest state.
    static let samples: [Material] = [
        Material(
            title: "Lecture 4 — Normalisation",
            courseId: "cs201",
            source: .pdf,
            text: "Normalisation removes redundancy by decomposing relations. First normal form requires atomic values; second normal form removes partial dependencies; third normal form removes transitive dependencies.",
            pageCount: 22,
            tags: ["databases", "normalisation"],
            createdAt: .now.addingTimeInterval(-86_400 * 2)
        ),
        Material(
            title: "Data Structures — week 3 scan",
            courseId: "c_104",
            source: .scan,
            text: "A hash table maps keys to buckets. Collisions are resolved by chaining or open addressing. Load factor is the ratio of stored entries to buckets.",
            pageCount: 6,
            tags: ["hashing"],
            createdAt: .now.addingTimeInterval(-86_400)
        ),
        Material(
            title: "Big-O cheat sheet",
            source: .link,
            text: "Binary search is O(log n) because each comparison halves the search space. Merge sort is O(n log n) in every case; quicksort is O(n log n) on average and O(n²) in the worst case.",
            tags: ["complexity"],
            createdAt: .now
        ),
    ]
}
#endif
