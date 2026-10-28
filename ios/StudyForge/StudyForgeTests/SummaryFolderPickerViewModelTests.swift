import Foundation
import Testing
@testable import StudyForge

@Suite("Summary save to folder (F03 · D06)")
@MainActor
struct SummaryFolderPickerViewModelTests {

    private let owned = SharedFolder(
        name: "Data Structures",
        members: [FolderMember(name: "Mohammed", permission: .edit, isOwner: true)]
    )

    private let sharedEditable = SharedFolder(
        name: "Group revision",
        members: [
            FolderMember(name: "Sara", permission: .edit, isOwner: true),
            FolderMember(name: "Mohammed", permission: .edit),
        ]
    )

    private let sharedViewOnly = SharedFolder(
        name: "Tutor handouts",
        members: [
            FolderMember(name: "Dr Ali", permission: .edit, isOwner: true),
            FolderMember(name: "Mohammed", permission: .view),
        ]
    )

    private func model(_ store: InMemoryFolderStore) -> SummaryFolderPickerViewModel {
        SummaryFolderPickerViewModel(
            summaryID: "summary-1",
            summaryTitle: "Trees — Summary",
            store: store,
            userName: "Mohammed"
        )
    }

    @Test("Rows show which folders are shared and which the student may add to")
    func rowsCarryPermissionAndSharing() async {
        let viewModel = model(InMemoryFolderStore(seededWith: [owned, sharedEditable, sharedViewOnly]))

        await viewModel.load()

        let rows = Dictionary(uniqueKeysWithValues: viewModel.rows.map { ($0.folder.name, $0) })
        #expect(rows["Data Structures"]?.isShared == false)
        #expect(rows["Data Structures"]?.canAdd == true)
        #expect(rows["Group revision"]?.isShared == true)
        #expect(rows["Group revision"]?.canAdd == true)
        #expect(rows["Tutor handouts"]?.canAdd == false)
    }

    @Test("Adding puts the summary into the folder once")
    func addPutsSummaryInFolder() async throws {
        let store = InMemoryFolderStore(seededWith: [owned])
        let viewModel = model(store)
        await viewModel.load()
        let row = try #require(viewModel.rows.first)

        await viewModel.add(to: row)

        let folder = try #require(try await store.folder(id: owned.id))
        #expect(folder.contains(referenceId: "summary-1", kind: .summary))
        #expect(folder.items.first?.title == "Trees — Summary")
        #expect(viewModel.addedFolderName == "Data Structures")
        #expect(viewModel.rows.first?.alreadyContains == true)

        await viewModel.add(to: try #require(viewModel.rows.first))
        let again = try #require(try await store.folder(id: owned.id))
        #expect(again.items.count == 1)
    }

    @Test("A view-only folder is not changed")
    func viewOnlyFolderIsRefused() async throws {
        let store = InMemoryFolderStore(seededWith: [sharedViewOnly])
        let viewModel = model(store)
        await viewModel.load()

        await viewModel.add(to: try #require(viewModel.rows.first))

        let folder = try #require(try await store.folder(id: sharedViewOnly.id))
        #expect(folder.items.isEmpty)
        #expect(viewModel.addedFolderName == nil)
    }

    @Test("Creating a folder inline makes the student its owner and adds the summary")
    func createAndAdd() async throws {
        let store = InMemoryFolderStore()
        let viewModel = model(store)
        await viewModel.load()
        viewModel.newFolderName = "  Exam prep  "

        await viewModel.createAndAdd()

        let folders = try await store.all()
        #expect(folders.count == 1)
        #expect(folders.first?.name == "Exam prep")
        #expect(folders.first?.owner?.name == "Mohammed")
        #expect(folders.first?.contains(referenceId: "summary-1", kind: .summary) == true)
        #expect(viewModel.newFolderName.isEmpty)
    }

    @Test("A blank folder name is refused")
    func blankNameIsRefused() async throws {
        let store = InMemoryFolderStore()
        let viewModel = model(store)
        viewModel.newFolderName = "   "

        await viewModel.createAndAdd()

        #expect(viewModel.validationMessage == SummaryCopy.folderNameError)
        #expect(try await store.all().isEmpty)
    }

    @Test("Search filters folders by name")
    func searchFilters() async {
        let viewModel = model(InMemoryFolderStore(seededWith: [owned, sharedEditable]))
        await viewModel.load()

        viewModel.query = "group"

        #expect(viewModel.rows.map(\.folder.name) == ["Group revision"])

        viewModel.query = "zzz"

        #expect(viewModel.hasNoMatches)
    }
}
