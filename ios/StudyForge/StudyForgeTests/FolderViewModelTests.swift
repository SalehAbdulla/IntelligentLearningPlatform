//
//  FolderViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the folder list and detail flows.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Folder list (F08)")
@MainActor
struct FolderListViewModelTests {

    @Test("An empty store shows the empty state")
    func emptyStore() async {
        let viewModel = FolderListViewModel(store: InMemoryFolderStore())
        await viewModel.load()
        #expect(viewModel.isEmpty)
    }

    @Test("Creating a folder makes the creator its owner with edit rights")
    func createOwnsTheFolder() async throws {
        let store = InMemoryFolderStore()
        let viewModel = FolderListViewModel(store: store)
        viewModel.name = "  Database revision  "

        await viewModel.create(ownerName: "Sara Ali")

        let folder = try await store.all().first
        #expect(folder?.name == "Database revision", "name is trimmed")
        #expect(folder?.owner?.name == "Sara Ali")
        #expect(folder?.owner?.permission == .edit)
        #expect(viewModel.name.isEmpty, "the field is cleared after creating")
    }

    @Test("A blank name creates nothing")
    func blankNameIsRefused() async throws {
        let store = InMemoryFolderStore()
        let viewModel = FolderListViewModel(store: store)
        viewModel.name = "   "

        await viewModel.create(ownerName: "Sara Ali")

        #expect(try await store.all().isEmpty)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = FolderListViewModel(store: InMemoryFolderStore())

        #expect(viewModel.title == L10n.folderTitle.string)
        #expect(viewModel.emptyTitle == L10n.folderEmptyTitle.string)
        #expect(viewModel.createTitle == L10n.folderCreate.string)
        #expect(viewModel.ownerRoleTitle == L10n.folderRoleOwner.string)
        #expect(viewModel.itemCount(SharedFolder(name: "x")) == L10n.folderItemCount.string(0))
    }
}

@Suite("Folder detail (F08)")
@MainActor
struct FolderDetailViewModelTests {

    private func folder(items: [FolderItem] = [], members: [FolderMember] = []) -> SharedFolder {
        SharedFolder(id: "f1", name: "Database revision", members: members, items: items)
    }

    private func model(
        folder: SharedFolder,
        materials: any MaterialStore = InMemoryMaterialStore()
    ) async -> (FolderDetailViewModel, InMemoryFolderStore) {
        let store = InMemoryFolderStore(seededWith: [folder])
        let viewModel = FolderDetailViewModel(folderId: folder.id, folders: store, materials: materials)
        await viewModel.load()
        return (viewModel, store)
    }

    @Test("Adding a material shares it; adding it again does nothing")
    func addMaterialDeDuplicates() async throws {
        let material = Material(title: "Lecture 4", source: .text, text: "body")
        let (viewModel, store) = await model(
            folder: folder(),
            materials: InMemoryMaterialStore(seededWith: [material])
        )

        await viewModel.addMaterial(material)
        await viewModel.addMaterial(material)

        #expect(viewModel.items.count == 1)
        #expect(try await store.folder(id: "f1")?.items.count == 1)
    }

    @Test("Only materials not already shared are offered")
    func availableMaterialsExcludeShared() async {
        let a = Material(title: "A", source: .text, text: "a")
        let b = Material(title: "B", source: .text, text: "b")
        let (viewModel, _) = await model(
            folder: folder(items: [FolderItem(kind: .material, referenceId: a.id, title: a.title)]),
            materials: InMemoryMaterialStore(seededWith: [a, b])
        )

        let available = await viewModel.availableMaterials()
        #expect(available.map(\.title) == ["B"])
    }

    @Test("Inviting someone already in the folder is refused with a reason")
    func duplicateMemberIsRefused() async {
        let (viewModel, _) = await model(
            folder: folder(members: [FolderMember(name: "Omar", permission: .view)])
        )

        await viewModel.addMember(name: "omar", permission: .edit)

        #expect(viewModel.memberError == L10n.folderMemberExists.string)
        #expect(viewModel.members.count == 1, "no duplicate was added")
    }

    @Test("A permission change is persisted")
    func setPermissionPersists() async throws {
        let member = FolderMember(name: "Omar", permission: .view)
        let (viewModel, store) = await model(folder: folder(members: [member]))

        await viewModel.setPermission(.edit, for: member)

        #expect(try await store.folder(id: "f1")?.members.first { $0.name == "Omar" }?.permission == .edit)
    }

    @Test("The owner cannot be demoted or removed")
    func ownerIsProtected() async {
        let owner = FolderMember(name: "Sara", permission: .edit, isOwner: true)
        let (viewModel, _) = await model(folder: folder(members: [owner]))

        await viewModel.setPermission(.view, for: owner)
        await viewModel.removeMember(owner)

        #expect(viewModel.members.count == 1)
        #expect(viewModel.members.first?.permission == .edit)
    }

    @Test("A folder with an owner may add items")
    func ownerCanAddItems() async {
        let (viewModel, _) = await model(
            folder: folder(members: [FolderMember(name: "Sara", permission: .edit, isOwner: true)])
        )
        #expect(viewModel.canAddItems)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _) = await model(folder: folder())

        #expect(viewModel.itemsTabTitle == L10n.folderItemsTab.string)
        #expect(viewModel.membersTabTitle == L10n.folderMembersTab.string)
        #expect(viewModel.addItemTitle == L10n.folderAddItem.string)
        #expect(viewModel.permissionTitle(.edit) == L10n.folderPermissionEdit.string)
    }
}