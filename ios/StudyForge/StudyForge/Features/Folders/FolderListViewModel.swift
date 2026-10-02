//
//  FolderListViewModel.swift
//  StudyForge
//
//  Presentation logic for I01 — the shared folders the student manages.
//
//  WHO IS "ME"
//  -----------
//  There is no server yet, so every folder on this device was created by the signed-in student, and
//  the role pill reads "Owner". A folder the student was INVITED to — where their own role would be
//  Viewer or Editor — only exists once a real backend grants it, and the UI is already written to
//  show whatever `SharedFolder` records rather than assuming ownership.
//

import Foundation

@MainActor
@Observable
final class FolderListViewModel {

    // MARK: Bound state

    /// The new folder's name, bound to the create sheet's field.
    var name = ""

    private(set) var isCreating = false

    private(set) var state: LoadState<[SharedFolder]> = .idle

    private let store: any FolderStore

    init(store: any FolderStore) {
        self.store = store
    }

    // MARK: Derived

    var folders: [SharedFolder] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    // MARK: Copy

    var title: String { L10n.folderTitle.string }
    var newFolderTitle: String { L10n.folderNewFolder.string }
    var emptyTitle: String { L10n.folderEmptyTitle.string }
    var emptyBody: String { L10n.folderEmptyBody.string }
    var nameLabel: String { L10n.folderNameLabel.string }
    var namePlaceholder: String { L10n.folderNamePlaceholder.string }
    var createTitle: String { L10n.folderCreate.string }
    var creatingTitle: String { L10n.folderCreating.string }
    var ownerRoleTitle: String { L10n.folderRoleOwner.string }

    func itemCount(_ folder: SharedFolder) -> String {
        L10n.folderItemCount.string(folder.items.count)
    }

    func memberCount(_ folder: SharedFolder) -> String {
        L10n.folderMemberCount.string(folder.members.count)
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let folders = try await store.all()
            state = folders.isEmpty ? .empty : .loaded(folders)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Creates a folder owned by `ownerName`. The owner is always an `edit` member, which is what
    /// makes the permission rows below them meaningful.
    func create(ownerName: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isCreating else { return }

        isCreating = true
        defer { isCreating = false }

        let folder = SharedFolder(
            name: trimmed,
            members: [FolderMember(name: ownerName, permission: .edit, isOwner: true)]
        )

        do {
            try await store.add(folder)
            name = ""
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func delete(_ folder: SharedFolder) async {
        do {
            try await store.delete(id: folder.id)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}