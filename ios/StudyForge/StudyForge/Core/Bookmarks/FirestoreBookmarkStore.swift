//
//  FirestoreBookmarkStore.swift
//  StudyForge
//
//  F10: a Firestore-backed BookmarkStore behind the existing protocol
//  (`collections/{id}`, `bookmarks/{id}`, owner-only rules).
//
//  This file is built one commit at a time. This commit adds only the actor
//  shell, its properties, its initializer, and the owner-uid helper. Protocol
//  conformance to `BookmarkStore` and all read/write/delete methods are added
//  in later commits, so nothing here conforms to or references the protocol yet.
//
//  WHY AN ACTOR
//  ------------
//  Mirrors `InMemoryBookmarkStore` and `FileBookmarkStore`: both are actors,
//  so every serialised call sees a consistent view of Firestore without the
//  caller managing locks.
//
//  OWNER-ONLY SCOPING
//  ------------------
//  Every read and write will be scoped to the signed-in student's `ownerUid`,
//  taken from `AuthService.currentSession()?.id`. The Firestore rules
//  (`backend/firestore.rules:482–492`) enforce the same on the server, so a
//  student can never read or write another student's collection or bookmark.
//  If nobody is signed in, every call throws `BookmarkError.storageFailed`.
//
//  WHY NO PROTOCOL CONFORMANCE YET
//  -------------------------------
//  `BookmarkStore` requires four methods (`all`, `collection(id:)`, `add(_:)`,
//  `delete(id:)`). Declaring conformance before any of them exist would not
//  compile, and adding placeholder stubs would leave a half-implemented store
//  in the history. Conformance is added only when all four methods exist.
//

import Foundation
import FirebaseFirestore

/// A `BookmarkStore` backed by Firestore, built one method at a time.
///
/// This commit declares the actor, its dependencies, and its owner-uid helper.
/// Protocol conformance and read/write/delete methods are added in later commits.
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
}