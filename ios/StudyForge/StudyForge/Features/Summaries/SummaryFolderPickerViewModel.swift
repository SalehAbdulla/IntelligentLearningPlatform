import Foundation

@MainActor
@Observable
final class SummaryFolderPickerViewModel {

    struct Row: Identifiable, Equatable {
        let folder: SharedFolder
        let isShared: Bool
        let canAdd: Bool
        let alreadyContains: Bool

        var id: String { folder.id }
        var memberCount: Int { folder.members.count }
    }

    var query = ""
    var newFolderName = ""

    private(set) var folders: [SharedFolder] = []
    private(set) var isLoading = false
    private(set) var isWorking = false
    private(set) var error: AppError?
    private(set) var validationMessage: String?
    private(set) var addedFolderName: String?

    let summaryID: String
    let summaryTitle: String

    private let store: any FolderStore
    private let userName: String

    init(summaryID: String, summaryTitle: String, store: any FolderStore, userName: String) {
        self.summaryID = summaryID
        self.summaryTitle = summaryTitle
        self.store = store
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userName = trimmed.isEmpty ? "Me" : trimmed
    }

    var rows: [Row] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return folders
            .filter { needle.isEmpty || $0.name.lowercased().contains(needle) }
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { folder in
                Row(
                    folder: folder,
                    isShared: folder.members.count > 1,
                    canAdd: canAdd(to: folder),
                    alreadyContains: folder.contains(referenceId: summaryID, kind: .summary)
                )
            }
    }

    var isEmpty: Bool { !isLoading && folders.isEmpty }

    var hasNoMatches: Bool { !folders.isEmpty && rows.isEmpty }

    var canCreate: Bool {
        !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isWorking
    }

    func canAdd(to folder: SharedFolder) -> Bool {
        guard let me = folder.members.first(where: { $0.name.lowercased() == userName.lowercased() }) else {
            return folder.members.allSatisfy { $0.permission.canAddItems }
        }
        return me.isOwner || me.permission.canAddItems
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            folders = try await store.all()
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    func add(to row: Row) async {
        guard row.canAdd, !row.alreadyContains, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        var folder = row.folder
        folder.items.append(FolderItem(kind: .summary, referenceId: summaryID, title: summaryTitle))
        folder.updatedAt = .now
        do {
            try await store.add(folder)
            replace(folder)
            addedFolderName = folder.name
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    func createAndAdd() async {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            validationMessage = SummaryCopy.folderNameError
            return
        }
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        let folder = SharedFolder(
            name: name,
            members: [FolderMember(name: userName, permission: .edit, isOwner: true)],
            items: [FolderItem(kind: .summary, referenceId: summaryID, title: summaryTitle)]
        )
        do {
            try await store.add(folder)
            folders.append(folder)
            newFolderName = ""
            validationMessage = nil
            addedFolderName = folder.name
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func replace(_ folder: SharedFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
        } else {
            folders.append(folder)
        }
    }
}
