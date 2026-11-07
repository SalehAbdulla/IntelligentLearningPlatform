//
//  BookmarkFirestoreMapper.swift
//  StudyForge
//
//  Converts BookmarkCollection and Bookmark to and from their Firestore document
//  representations for `collections/{id}` and `bookmarks/{id}` (docs/05 §2.5).
//
//  WHY A SEPARATE MAPPER
//  ---------------------
//  The Firestore store (Stage 2) owns reachability, retries and the offline queue.
//  This mapper owns only one thing: which document field holds which model
//  property, and how Dates become storable values and back. Splitting them means
//  a unit test can prove the field layout is correct without a Firebase project,
//  an emulator, or even the Firebase SDK imported into the test target
//  (docs/04 §8: the test target never imports FirebaseFirestore).
//
//  WHY DATES ARE STORED AS TIMEINTERVAL, NOT TIMESTAMP
//  ---------------------------------------------------
//  Firestore natively stores dates as Timestamp, and the app target can write a
//  `Date` directly because the SDK bridges it. But `Timestamp` is a Firebase type,
//  so a test that asserts on it would have to import FirebaseFirestore, which the
//  test target does not (docs/04 §306). Writing `timeIntervalSince1970` as a
//  `Double` keeps every field a plain Foundation type, so the mapper round-trips
//  in a pure unit test on any machine.
//
//  ONE DOCUMENT PER BOOKMARK, KEYED BY ITS OWN ID
//  ------------------------------------------------
//  docs/05 §2.5 puts `bookmarks/{id}` in its own top-level collection, keyed by
//  `collectionId` (the composite index `ownerUid` + `collectionId` + `createdAt`
//  in `backend/firestore.indexes.json` proves this). The collection document
//  itself holds only metadata (`name`, `ownerUid`, timestamps) — bookmarks are
//  read separately and re-attached by the store.
//

import Foundation

/// Converts `BookmarkCollection` and `Bookmark` to and from Firestore document
/// dictionaries for `collections/{id}` and `bookmarks/{id}`.
///
/// All conversion is pure Foundation: dates are `Double`
/// (`timeIntervalSince1970`), nothing here imports Firebase. This keeps the
/// mapper testable without a Firebase project or emulator.
struct BookmarkFirestoreMapper {

    /// Cannot be instantiated: this is a namespace for static conversion
    /// functions, mirroring `AuthInput` (Core/Auth/AuthService.swift).
    private init() {}

    // MARK: - Field names

    /// Field that names the owning student. Matched by the owner-only rules in
    /// `backend/firestore.rules` (`ownerUid == uid()`), so a student can never
    /// read or write another student's collection.
    private static let ownerUidField = "ownerUid"

    /// The id of the collection a bookmark belongs to. Used both to file the
    /// bookmark under its collection and to query `bookmarks` by `collectionId`.
    private static let collectionIdField = "collectionId"

    // MARK: - collections/{id}

    /// Encodes a collection as the document data written to `collections/{id}`.
    ///
    /// The document id is `collection.id`; it is not written as a field because
    /// Firestore documents already carry their id in `documentID`, and writing
    /// it would be redundant.
    ///
    /// - Parameter ownerUid: the signed-in student's uid, supplied by the store
    ///   from `AuthService.currentSession()?.id`. The mapper never reads auth
    ///   itself, so it stays pure and testable.
    /// - Returns: a dictionary of plain Foundation types ready for
    ///   `Firestore.firestore().collection("collections").document(id).setData(_:)`.
    static func collectionDocument(
        _ collection: BookmarkCollection,
        ownerUid: String
    ) -> [String: Any] {
        [
            "name": collection.name,
            ownerUidField: ownerUid,
            "createdAt": collection.createdAt.timeIntervalSince1970,
            "updatedAt": collection.updatedAt.timeIntervalSince1970,
        ]
    }

    /// Decodes a `collections/{id}` document back into a `BookmarkCollection`.
    ///
    /// Returns `nil` when the document lacks a required field, so the store can
    /// distinguish "document missing" (snapshot does not exist) from "document
    /// present but malformed" (decoding failure). Bookmarks are not decoded
    /// here: they live in `bookmarks/{id}` and are fetched separately.
    static func collection(from data: [String: Any], id: String) -> BookmarkCollection? {
        guard
            let name = data["name"] as? String,
            let createdAtInterval = data["createdAt"] as? Double,
            let updatedAtInterval = data["updatedAt"] as? Double
        else { return nil }

        return BookmarkCollection(
            id: id,
            name: name,
            bookmarks: [],   // bookmarks live in `bookmarks/{id}`, fetched separately
            createdAt: Date(timeIntervalSince1970: createdAtInterval),
            updatedAt: Date(timeIntervalSince1970: updatedAtInterval)
        )
    }

    // MARK: - bookmarks/{id}

    /// Encodes a bookmark as the document data written to `bookmarks/{id}`.
    ///
    /// - Parameter collectionId: the id of the collection this bookmark is filed
    ///   under. Stored as `collectionId` so the store can query all bookmarks of
    ///   a collection (`whereField("collectionId", isEqualTo: collectionId)`).
    /// - Parameter ownerUid: the signed-in student's uid, supplied by the store.
    static func bookmarkDocument(
        _ bookmark: Bookmark,
        collectionId: String,
        ownerUid: String
    ) -> [String: Any] {
        [
            "kind": bookmark.kind.rawValue,
            "referenceId": bookmark.referenceId,
            "title": bookmark.title,
            "savedOffline": bookmark.savedOffline,
            "savedAt": bookmark.savedAt.timeIntervalSince1970,
            collectionIdField: collectionId,
            ownerUidField: ownerUid,
        ]
    }

    /// Decodes a `bookmarks/{id}` document back into a `Bookmark`.
    ///
    /// Returns `nil` when the document lacks a required field. `savedOffline`
    /// defaults to `false` when absent, so older documents written before the
    /// offline flag existed still decode.
    static func bookmark(from data: [String: Any], id: String) -> Bookmark? {
        guard
            let kindRaw = data["kind"] as? String,
            let kind = BookmarkKind(rawValue: kindRaw),
            let referenceId = data["referenceId"] as? String,
            let title = data["title"] as? String,
            let savedAtInterval = data["savedAt"] as? Double
        else { return nil }

        let savedOffline = data["savedOffline"] as? Bool ?? false

        return Bookmark(
            id: id,
            kind: kind,
            referenceId: referenceId,
            title: title,
            savedOffline: savedOffline,
            savedAt: Date(timeIntervalSince1970: savedAtInterval)
        )
    }
}
