//
//  FolderDetailViewModel.swift
//  StudyForge
//
//  Presentation logic for I02 (folder detail with Items/Members), I04 (invite) and I06 (per-member
//  permissions).
//
//  WHY IT RELOADS BY ID
//  --------------------
//  Adding an item or changing a permission rewrites the folder, so the screen reads it back from the
//  store rather than mutating a held copy. One source of truth means the header counts and the lists
//  beneath them can never disagree.
//

import Foundation

@MainActor
@Observable
final class FolderDetailViewModel {

    private(set) var state: LoadState<SharedFolder> = .idle

    /// A rejected member name — the design's "inviting an existing member" edge case, surfaced beside
    /// the field rather than as a banner.
    private(set) var memberError: String?

    private let folderId: String
    private let folders: any FolderStore
    private let materials: any MaterialStore

    init(folderId: String, folders: any FolderStore, materials: any MaterialStore) {
        self.folderId = folderId
        self.folders = folders
        self.materials = materials
    }

    // MARK: Derived

    var folder: SharedFolder? { state.value }
    var items: [FolderItem] { state.value?.items.sorted { $0.addedAt > $1.addedAt } ?? [] }
    var members: [FolderMember] { state.value?.members ?? [] }
    var isLoading: Bool { state.isLoading }

    /// Set when an action (adding an item, changing a permission) fails.
    ///
    /// Kept SEPARATE from `state` so a failed action does not blank out the folder that is already on
    /// screen — the student keeps the folder and sees the error above it.
    private(set) var error: AppError?

    /// Whether the student may add items to this folder.
    ///
    /// The owner always may. For anyone else it follows their permission — which is why "Add item" is
    /// HIDDEN rather than disabled: a control the student can never use is worse than no control.
    var canAddItems: Bool { folder?.owner != nil || members.contains { $0.permission.canAddItems } }

    // MARK: Copy

    var itemsTabTitle: String { L10n.folderItemsTab.string }
    var membersTabTitle: String { L10n.folderMembersTab.string }
    var noItemsTitle: String { L10n.folderNoItems.string }
    var addItemTitle: String { L10n.folderAddItem.string }
    var addItemsSheetTitle: String { L10n.folderAddItemsTitle.string }
    var addMemberTitle: String { L10n.folderAddMember.string }
    var memberNameLabel: String { L10n.folderMemberNameLabel.string }
    var memberNamePlaceholder: String { L10n.folderMemberNamePlaceholder.string }
    var permissionLabel: String { L10n.folderPermissionLabel.string }
    var ownerRoleTitle: String { L10n.folderRoleOwner.string }

    func permissionTitle(_ permission: FolderPermission) -> String {
        switch permission {
        case .view: L10n.folderPermissionView.string
        case .comment: L10n.folderPermissionComment.string
        case .edit: L10n.folderPermissionEdit.string
        }
    }

    func itemCountTitle(_ count: Int) -> String { L10n.folderItemCount.string(count) }
    func memberCountTitle(_ count: Int) -> String { L10n.folderMemberCount.string(count) }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            guard let folder = try await folders.folder(id: folderId) else {
                state = .empty
                return
            }
            state = .loaded(folder)
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Materials that are not already shared here, for the add-item picker.
    func availableMaterials() async -> [Material] {
        guard let folder else { return [] }
        do {
            return try await materials.all().filter {
                !folder.contains(referenceId: $0.id, kind: .material)
            }
        } catch {
            self.error = AppError.from(error)
            return []
        }
    }

    // MARK: Items

    func addMaterial(_ material: Material) async {
        await mutate { folder in
            guard !folder.contains(referenceId: material.id, kind: .material) else { return }
            folder.items.append(
                FolderItem(kind: .material, referenceId: material.id, title: material.title)
            )
        }
    }

    func removeItem(_ item: FolderItem) async {
        await mutate { $0.items.removeAll { $0.id == item.id } }
    }

    // MARK: Members

    func addMember(name: String, permission: FolderPermission) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard folder?.contains(memberNamed: trimmed) != true else {
            memberError = L10n.folderMemberExists.string
            return
        }
        memberError = nil
        await mutate { $0.members.append(FolderMember(name: trimmed, permission: permission)) }
    }

    func setPermission(_ permission: FolderPermission, for member: FolderMember) async {
        // The owner's access is not editable — there is nothing to demote them to.
        guard !member.isOwner else { return }
        await mutate { folder in
            guard let index = folder.members.firstIndex(where: { $0.id == member.id }) else { return }
            folder.members[index].permission = permission
        }
    }

    func removeMember(_ member: FolderMember) async {
        guard !member.isOwner else { return }
        await mutate { $0.members.removeAll { $0.id == member.id } }
    }

    func clearMemberError() { memberError = nil }

    // MARK: Mutation

    /// Applies a change to the folder and persists it, then reloads so the screen shows what was
    /// actually stored rather than what we hoped was stored.
    private func mutate(_ change: (inout SharedFolder) -> Void) async {
        guard var folder else { return }
        change(&folder)
        folder.updatedAt = .now
        do {
            try await folders.add(folder)
            state = .loaded(folder)
        } catch {
            self.error = AppError.from(error)
        }
    }
}