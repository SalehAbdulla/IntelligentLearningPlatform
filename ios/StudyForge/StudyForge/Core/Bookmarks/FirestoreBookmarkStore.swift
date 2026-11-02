//
//  FirestoreBookmarkStore.swift
//  StudyForge
//
//  F10: a Firestore-backed BookmarkStore behind the existing protocol
//  (`collections/{id}`, `bookmarks/{id}`, owner-only rules).
//
//  This file is built one commit at a time. This commit adds the actor
//  shell, its properties, its initializer, the owner-uid helper, and the
//  read methods (`bookmarks(for:)`, `all()`, `collection(id:)`). Protocol
//  conformance to `BookmarkStore` and the write/delete methods (`add(_:)`,
//  `delete(id:)`) are added in later commits.
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
/// and the read methods. Protocol conformance and write/delete methods are
/// added in later commits.
actor FirestoreBookmarkStore {

    private let db = Firestore.firestore()
    private let auth: any AuthService

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
}