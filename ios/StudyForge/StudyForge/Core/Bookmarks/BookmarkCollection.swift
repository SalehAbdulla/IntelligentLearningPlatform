//
//  BookmarkCollection.swift
//  StudyForge
//
//  F10 — the student's own collections of saved references, and the references in them
//  (docs/03 §I, I15–I18; docs/05 §2.5 `collections` + `bookmarks`).
//
//  WHY THE TYPE IS `BookmarkCollection` AND NOT `Collection`
//  --------------------------------------------------------
//  docs/03 names the screen "Bookmarks / Collections" and docs/05 §2.5 names the Firestore
//  collection `collections`. The Swift type cannot be `Collection`: that is a standard-library
//  PROTOCOL, and a struct shadowing it turns every generic that says `Collection` into a coin
//  toss. `BookmarkCollection` reads as the same thing on screen without the trap.
//
//  WHY THE BOOKMARKS LIVE ON THE COLLECTION
//  ----------------------------------------
//  Exactly the reasoning behind `SharedFolder`. Firestore keeps `bookmarks/{id}` in its own
//  top-level collection keyed by `collectionId` — the composite index in
//  `backend/firestore.indexes.json` (`ownerUid`, `collectionId`, `createdAt`) says so — but the
//  local store has no size limit and every screen needs the whole collection at once, so a
//  `BookmarkCollection` owns its bookmarks here and the store seam hides the future split.
//
//  ONE COLLECTION PER BOOKMARK, ON PURPOSE
//  --------------------------------------
//  I17's save sheet is a picker with a checkmark, and it is a single-select one: a bookmark is
//  filed under exactly one collection, which is what makes `collectionId` a single field in
//  docs/05 §2.5. Filing one reference under several collections is a different data shape
//  (a join document), and inventing it here would put the app ahead of its own schema.
//
//  A BOOKMARK IS A REFERENCE, NOT A COPY
//  -------------------------------------
//  `referenceId` points at the artefact where it already lives; `title` is a snapshot so the list
//  renders without loading the target. Copying would fork the student's deck the moment they
//  bookmarked it — the same mistake F08 avoids for shared-folder items.
//

import Foundation

/// What kind of artefact a bookmark points at, and the source-type icon its row shows (I16).
enum BookmarkKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case material
    case deck
    case summary
    case quiz
    case folder

    var id: String { rawValue }

    /// The source-type icon I16 calls for.
    ///
    /// Deliberately close to `FolderItemKind.symbolName`, plus the `folder` case a bookmark can
    /// point at but a folder item cannot. Kept as its own switch rather than shared, because the
    /// two vocabularies are allowed to diverge the moment one screen gains a kind the other has
    /// no business offering.
    var symbolName: String {
        switch self {
        case .material: "doc.richtext"
        case .deck: "rectangle.stack"
        case .summary: "text.alignleft"
        case .quiz: "checklist"
        case .folder: "folder"
        }
    }
}

/// A saved reference the student filed in one of their collections (docs/05 §2.5 `bookmarks/{id}`).
struct Bookmark: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var kind: BookmarkKind

    /// The id of the underlying artefact (a material, deck, summary, quiz or folder).
    var referenceId: String

    /// A copied label, so a collection can list a bookmark without loading the artefact.
    var title: String

    /// Whether the student asked for this one to be available with no connection.
    ///
    /// This is I17's "also save offline" and the whole reason I18 can claim an offline-first
    /// story: the badge on I15 is not decoration, it is this flag aggregated.
    var savedOffline: Bool

    let savedAt: Date

    init(
        id: String = UUID().uuidString,
        kind: BookmarkKind,
        referenceId: String,
        title: String,
        savedOffline: Bool = false,
        savedAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.referenceId = referenceId
        self.title = title
        self.savedOffline = savedOffline
        self.savedAt = savedAt
    }
}

/// A named collection of bookmarks the student owns.
struct BookmarkCollection: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var name: String
    var bookmarks: [Bookmark]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        bookmarks: [Bookmark] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.bookmarks = bookmarks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// How many bookmarks are saved for offline use.
    var offlineCount: Int { bookmarks.filter(\.savedOffline).count }

    /// Whether anything here is offline-available — what lights the badge on I15.
    var hasOffline: Bool { offlineCount > 0 }

    /// Whether the collection already holds a reference to the given artefact.
    ///
    /// Guards the duplicate the design's save sheet can otherwise create: saving the same material
    /// twice would list it twice and offer it once. Mirrors `SharedFolder.contains(referenceId:kind:)`.
    func contains(referenceId: String, kind: BookmarkKind) -> Bool {
        bookmarks.contains { $0.referenceId == referenceId && $0.kind == kind }
    }
}