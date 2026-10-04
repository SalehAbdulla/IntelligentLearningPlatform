//
//  GroupStoreTests.swift
//  StudyForgeTests
//
//  Tests for the group models and their store.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Study group model")
struct StudyGroupModelTests {

    private func group() -> StudyGroup {
        StudyGroup(
            id: "g1",
            name: "Database revision",
            members: [GroupMember(name: "Sara", isOwner: true), GroupMember(name: "Omar")],
            messages: [GroupMessage(senderName: "Omar", text: "Anyone free at 6?")],
            resources: [GroupResource(kind: .material, referenceId: "m1", title: "Lecture 4", pinnedBy: "Omar")]
        )
    }

    @Test("A group round-trips through JSON without losing its contents")
    func codableRoundTrip() throws {
        let original = group()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StudyGroup.self, from: data)

        #expect(decoded == original)
        #expect(decoded.members.count == 2)
        #expect(decoded.resources.first?.kind == .material)
    }

    @Test("The cover seed is derived from the name and never changes")
    func coverSeedIsStable() {
        #expect(StudyGroup.seed(for: "Database revision") == StudyGroup.seed(for: "Database revision"))
        #expect(StudyGroup(name: "A").coverSeed == StudyGroup(name: "A").coverSeed)
    }

    @Test("An invite code is six characters from an unambiguous alphabet")
    func inviteCodeShape() {
        for _ in 0..<50 {
            let code = StudyGroup.makeInviteCode()
            #expect(code.count == 6)
            // I, O, 0 and 1 are excluded so a code read off a screen cannot be mistyped.
            #expect(code.allSatisfy { $0.isLetter || $0.isNumber })
            #expect(!code.contains("0") && !code.contains("O") && !code.contains("1") && !code.contains("I"))
        }
    }

    @Test("A group knows its members and its pins")
    func membershipAndPins() {
        let group = group()
        #expect(group.contains(memberNamed: "sara"), "matching ignores case")
        #expect(group.contains(memberNamed: "Zainab") == false)
        #expect(group.contains(resourceReferenceId: "m1", kind: .material))
        #expect(group.contains(resourceReferenceId: "m1", kind: .deck) == false)
        #expect(group.lastMessage?.text == "Anyone free at 6?")
    }
}

// MARK: - Store

@Suite("Group store")
struct GroupStoreTests {

    private func group(id: String, code: String = "ABC123", updatedAt: Date) -> StudyGroup {
        StudyGroup(id: id, name: "Group", inviteCode: code, createdAt: .now, updatedAt: updatedAt)
    }

    @Test("The in-memory store returns groups most recently updated first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryGroupStore(seededWith: [
            group(id: "old", updatedAt: .now.addingTimeInterval(-3600)),
            group(id: "new", updatedAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryGroupStore()
        let record = group(id: "g1", updatedAt: .now)

        try await store.add(record)
        #expect(try await store.group(id: "g1") == record)

        try await store.delete(id: "g1")
        #expect(try await store.group(id: "g1") == nil)
    }

    @Test("A group is found by its invite code, ignoring case and spacing")
    func inviteCodeLookup() async throws {
        let store = InMemoryGroupStore(seededWith: [group(id: "g1", code: "ABC123", updatedAt: .now)])
        #expect(try await store.group(withInviteCode: " abc123 ")?.id == "g1")
        #expect(try await store.group(withInviteCode: "ZZZZZZ") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryGroupStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: GroupError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists groups across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("group-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileGroupStore(directory: directory).add(group(id: "g1", updatedAt: .now))
        #expect(try await FileGroupStore(directory: directory).group(id: "g1")?.id == "g1")
    }

    @Test("Group failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(
            GroupError.storageFailed.asAppError == AppError.server(reference: "group-store-failed")
        )
        #expect(AppError.from(GroupError.storageFailed) == AppError.server(reference: "group-store-failed"))
        // The two join outcomes are their own copy, not a generic apology.
        #expect(GroupError.codeNotFound.asAppError.message == L10n.groupJoinCodeInvalid.string)
        #expect(GroupError.alreadyAMember.asAppError.message == L10n.groupJoinAlreadyMember.string)
    }
}