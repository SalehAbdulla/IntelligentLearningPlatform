//
//  FirestoreBookmarkStore.swift
//  StudyForge
//
//  F10: a Firestore-backed BookmarkStore behind the existing protocol
//  (`collections/{id}`, `bookmarks/{id}`, owner-only rules).
//
//  This file is built one commit at a time. This commit adds the actor
//  shell, its properties, its initializer, the owner-uid helper, the read
//  methods (`bookmarks(for:)`, `all()`, `collection(id:)`), and the write
//  methods (`add(_:)` and its `syncBookmarks` helper). Protocol conformance
//  to `BookmarkStore` and `delete(id:)` are added in later commits.
//
//  WHY AN ACTOR
//  ------------
//  Mirrors `InMemoryBookmarkStore` and `FileBookmarkStore`: both are actors,
//  so every serialised call sees a consistent view of Firestore without the
//  caller managing locks.
//
//  OWNER-ONLY SCOPING
//  ------------------
//  Every read and write is scoped to the signed-in student's `ownerUid`,
//  taken from `AuthService.currentSession()?.id`. The Firestore rules
//  (`backend/firestore.rules:482–492`) enforce the same on the server, so a
//  student can never read or write another student's collection or bookmark.
//  If nobody is signed in, every call throws `BookmarkError.storageFailed`.
//
//  WHY NO PROTOCOL CONFORMANCE YET
//  -------------------------------
//  `BookmarkStore` requires four methods (`all`, `collection(id:)`, `add(_:)`,
//  `delete(id:)`). Declaring conformance before all four exist would not
//  compile, and adding placeholder stubs would leave a half-implemented store
//  in the history. Conformance is added only when all four methods exist.
//

import Foundation
import FirebaseFirestore

/// A `BookmarkStore` backed by Firestore, built one method at a time.
///
/// This commit declares the actor, its dependencies, its owner-uid helper,
/// the read methods, and the write methods. Protocol conformance and
/// `delete(id:)` are added in later commits.
actor FirestoreBookmarkStore {

    private let db = Firestore.firestore()
    private let auth: any AuthService

    /// Firestore's hard cap on the operations in a single `WriteBatch`. The
    /// bookmark reconciliation splits into batches of at most this many.
    private static let batchLimit = 500

    init(auth: any AuthService) {
        self.auth = auth
    }

    // MARK: Owner-uid scoping

    /// The signed-in student's uid, taken from `AuthService.currentSession()?.id`.
    ///
    /// - Throws: `BookmarkError.storageFailed` when nobody is signed in, so that
    ///   no read or write can ever target another student's data.
    private func ownerUidOrThrow() throws -> String {
        guard let uid = auth.currentSession()?.id else {
            throw BookmarkError.storageFailed
        }
        return uid
    }

    /// Every bookmark filed under `collectionId` and owned by the signed-in
    /// student, decoded through `BookmarkFirestoreMapper`.
    ///
    /// - Throws: `BookmarkError.storageFailed` if the Firestore read fails.
    private func bookmarks(for collectionId: String, ownerUid: String) async throws -> [Bookmark] {
        do {
            let snapshot = try await db.collection("bookmarks")
                .whereField("collectionId", isEqualTo: collectionId)
                .whereField("ownerUid", isEqualTo: ownerUid)
                .getDocuments()
            var bookmarks: [Bookmark] = []
            for document in snapshot.documents {
                guard let data = document.data() else { throw BookmarkError.storageFailed }
                guard let bookmark = BookmarkFirestoreMapper.bookmark(from: data, id: document.documentID) else {
                    throw BookmarkError.storageFailed
                }
                bookmarks.append(bookmark)
            }
            return bookmarks
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    /// Every collection owned by the signed-in student, most recently updated first.
    ///
    /// Queries `collections` by `ownerUid` only and sorts in memory —
    /// `backend/firestore.indexes.json` has no
    /// `collections(ownerUid, updatedAt)` composite index, and this file must not
    /// touch `backend/`, so `order(by:)` is avoided.
    ///
    /// - Throws: `BookmarkError.storageFailed` if the Firestore read fails.
    func all() async throws -> [BookmarkCollection] {
        let ownerUid = try ownerUidOrThrow()
        do {
            let snapshot = try await db.collection("collections")
                .whereField("ownerUid", isEqualTo: ownerUid)
                .getDocuments()
            var collections: [BookmarkCollection] = []
            for document in snapshot.documents {
                guard let data = document.data() else { throw BookmarkError.storageFailed }
                guard let collection = BookmarkFirestoreMapper.collection(from: data, id: document.documentID)
                else { throw BookmarkError.storageFailed }
                collections.append(collection)
            }
            // Attach each collection's bookmarks, then sort most recently updated first.
            for index in collections.indices {
                collections[index].bookmarks = try await bookmarks(
                    for: collections[index].id, ownerUid: ownerUid)
            }
            return collections.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    /// One collection owned by the signed-in student, or `nil` when nothing is
    /// stored under that id.
    ///
    /// - Throws: `BookmarkError.storageFailed` if the Firestore read fails.
    func collection(id: String) async throws -> BookmarkCollection? {
        let ownerUid = try ownerUidOrThrow()
        do {
            let document = try await db.collection("collections").document(id).getDocument()
            guard document.exists else { return nil }
            guard let data = document.data() else { throw BookmarkError.storageFailed }
            guard let collection = BookmarkFirestoreMapper.collection(from: data, id: document.documentID)
            else { throw BookmarkError.storageFailed }
            var result = collection
            result.bookmarks = try await bookmarks(for: id, ownerUid: ownerUid)
            return result
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    // MARK: Writes

    /// Stores a collection, replacing any existing one with the same id, and
    /// makes the bookmarks under it match `collection.bookmarks` exactly.
    ///
    /// The collection document is written first, then `syncBookmarks` reconciles
    /// the bookmarks under it. Each Firestore write goes through a `WriteBatch`,
    /// so a group of writes lands atomically rather than one document at a time.
    ///
    /// - Throws: `BookmarkError.storageFailed` if any Firestore write fails.
    func add(_ collection: BookmarkCollection) async throws {
        let ownerUid = try ownerUidOrThrow()
        do {
            // Rewrite the collection document in its own atomic batch.
            let batch = db.batch()
            batch.setData(
                BookmarkFirestoreMapper.collectionDocument(collection, ownerUid: ownerUid),
                forDocument: db.collection("collections").document(collection.id))
            try await batch.commit()

            // Reconcile the bookmarks under this collection.
            try await syncBookmarks(
                for: collection.id,
                bookmarks: collection.bookmarks,
                ownerUid: ownerUid)
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    /// Rewrites the bookmarks under `collectionId` to match `bookmarks` exactly:
    /// writes or updates every bookmark in the array, and deletes any existing
    /// bookmark document that is no longer present.
    ///
    /// A Firestore `WriteBatch` is capped at 500 operations, so the operations
    /// are committed in chunks of at most `batchLimit`. Each chunk is atomic on
    /// its own; a collection large enough to need more than one chunk is
    /// unlikely, but the chunking keeps the code correct if it ever happens.
    ///
    /// - Throws: `BookmarkError.storageFailed` if any Firestore read or write fails.
    private func syncBookmarks(
        for collectionId: String,
        bookmarks: [Bookmark],
        ownerUid: String
    ) async throws {
        do {
            // Which bookmarks already exist under this collection, so the ones
            // no longer in the array can be deleted rather than left behind.
            // Scoped by ownerUid as well as collectionId, so the reconciliation
            // read can never see another student's bookmarks.
            let existingSnapshot = try await db.collection("bookmarks")
                .whereField("collectionId", isEqualTo: collectionId)
                .whereField("ownerUid", isEqualTo: ownerUid)
                .getDocuments()
            let newIds = Set(bookmarks.map { $0.id })
            let removed = existingSnapshot.documents.filter { !newIds.contains($0.documentID) }

            var batch = db.batch()
            var operations = 0

            // Deletes first: a bookmark removed from the collection must not linger.
            for document in removed {
                if operations == Self.batchLimit {
                    try await batch.commit()
                    batch = db.batch()
                    operations = 0
                }
                batch.deleteDocument(document.reference)
                operations += 1
            }

            // Then writes: every bookmark currently in the collection.
            for bookmark in bookmarks {
                if operations == Self.batchLimit {
                    try await batch.commit()
                    batch = db.batch()
                    operations = 0
                }
                batch.setData(
                    BookmarkFirestoreMapper.bookmarkDocument(
                        bookmark, collectionId: collectionId, ownerUid: ownerUid),
                    forDocument: db.collection("bookmarks").document(bookmark.id))
                operations += 1
            }

            // Commit whatever is left (an empty final batch is skipped).
            if operations > 0 {
                try await batch.commit()
            }
        } catch {
            throw BookmarkError.storageFailed
        }
    }
}