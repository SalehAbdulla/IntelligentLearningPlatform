//
//  FolderStoreTests.swift
//  StudyForgeTests
//
//  Tests for the shared-folder models and their store.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Shared folder model")
struct SharedFolderModelTests {

    private func folder() -> SharedFolder {
        SharedFolder(
            id: "f1",
            name: "Database revision",
            members: [FolderMember(name: "Sara Ali", permission: .edit, isOwner: true)],
            items: [FolderItem(kind: .material, referenceId: "m1", title: "Lecture 4")]
        )
    }

    @Test("A folder round-trips through JSON without losing members or items")
    func codableRoundTrip() throws {
        let original = folder()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharedFolder.self, from: data)

        #expect(decoded == original)
        #expect(decoded.owner?.name == "Sara Ali")
        #expect(decoded.items.first?.kind == .material)
    }

    @Test("Only edit may add items")
    func permissionCapabilities() {
        #expect(FolderPermission.edit.canAddItems)
        #expect(FolderPermission.comment.canAddItems == false)
        #expect(FolderPermission.view.canAddItems == false)
    }

    @Test("A folder knows what it already contains")
    func duplicateDetection() {
        let folder = folder()
        #expect(folder.contains(referenceId: "m1", kind: .material))
        #expect(folder.contains(referenceId: "m1", kind: .deck) == false)
        #expect(folder.contains(memberNamed: "sara ali"), "matching ignores case")
        #expect(folder.contains(memberNamed: "Omar") == false)
    }
}

// MARK: - Store

@Suite("Shared folder store")
struct FolderStoreTests {

    private func folder(id: String, updatedAt: Date) -> SharedFolder {
        SharedFolder(id: id, name: "Folder", createdAt: .now, updatedAt: updatedAt)
    }

    @Test("The in-memory store returns folders most recently updated first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryFolderStore(seededWith: [
            folder(id: "old", updatedAt: .now.addingTimeInterval(-3600)),
            folder(id: "new", updatedAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryFolderStore()
        let record = folder(id: "f1", updatedAt: .now)

        try await store.add(record)
        #expect(try await store.folder(id: "f1") == record)

        try await store.delete(id: "f1")
        #expect(try await store.folder(id: "f1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryFolderStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: FolderError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists folders across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("folder-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileFolderStore(directory: directory).add(folder(id: "f1", updatedAt: .now))
        #expect(try await FileFolderStore(directory: directory).folder(id: "f1")?.id == "f1")
    }

    @Test("Folder store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(FolderError.storageFailed.asAppError == AppError.server(reference: "folder-store-failed"))
    }
}