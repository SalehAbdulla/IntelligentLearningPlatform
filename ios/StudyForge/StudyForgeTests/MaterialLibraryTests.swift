//
//  MaterialLibraryTests.swift
//  StudyForgeTests
//
//  Tests for C08, the library screen.
//
//  The load-bearing one is `noMatchesIsNotEmptiness`: telling a student who mistyped that they
//  have no materials would read as though their library had been wiped, so "nothing matched" and
//  "nothing stored" are kept as different states.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Material library (C08)")
@MainActor
struct MaterialLibraryTests {

    private func material(
        title: String,
        text: String = "body text",
        tags: [String] = [],
        createdAt: Date = .now
    ) -> Material {
        Material(title: title, source: .pdf, text: text, tags: tags, createdAt: createdAt)
    }

    @Test("An empty store shows the empty state, not a failed one")
    func emptyLibrary() async {
        let viewModel = MaterialLibraryViewModel(store: InMemoryMaterialStore())

        await viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.error == nil)
        #expect(viewModel.visibleMaterials.isEmpty)
        #expect(viewModel.hasNoMatches == false)
    }

    @Test("A populated store shows the materials, newest first")
    func loadedLibrary() async {
        let store = InMemoryMaterialStore(seededWith: [
            material(title: "Older", createdAt: .now.addingTimeInterval(-3600)),
            material(title: "Newer"),
        ])
        let viewModel = MaterialLibraryViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.visibleMaterials.map(\.title) == ["Newer", "Older"])
        #expect(viewModel.isEmpty == false)
    }

    @Test("Search matches the title, the tags and the extracted text")
    func searchMatchesTitleTagsAndText() async {
        let store = InMemoryMaterialStore(seededWith: [
            material(
                title: "Lecture 4",
                text: "normalisation removes redundancy",
                tags: ["databases"]
            ),
            material(
                title: "Big-O sheet",
                text: "binary search is logarithmic",
                tags: ["complexity"]
            ),
        ])
        let viewModel = MaterialLibraryViewModel(store: store)
        await viewModel.load()

        viewModel.query = "lecture"
        #expect(viewModel.visibleMaterials.map(\.title) == ["Lecture 4"])

        // A tag.
        viewModel.query = "complex"
        #expect(viewModel.visibleMaterials.map(\.title) == ["Big-O sheet"])

        // A word INSIDE the document — which is what "searchable" means in the brief.
        viewModel.query = "redundancy"
        #expect(viewModel.visibleMaterials.map(\.title) == ["Lecture 4"])
    }

    @Test("Search is case-insensitive and ignores surrounding whitespace")
    func searchIsForgiving() async {
        let viewModel = MaterialLibraryViewModel(
            store: InMemoryMaterialStore(seededWith: [material(title: "Lecture 4")])
        )
        await viewModel.load()

        viewModel.query = "  LECTURE  "

        #expect(viewModel.visibleMaterials.count == 1)
    }

    @Test("No matches is a different state from an empty library")
    func noMatchesIsNotEmptiness() async {
        let viewModel = MaterialLibraryViewModel(
            store: InMemoryMaterialStore(seededWith: [material(title: "Lecture 4")])
        )
        await viewModel.load()

        viewModel.query = "nothing matches this"

        #expect(viewModel.hasNoMatches)
        #expect(viewModel.isEmpty == false)
    }

    @Test("Deleting the last material leaves the library empty")
    func deletingTheLastMaterialEmptiesTheLibrary() async {
        let store = InMemoryMaterialStore(seededWith: [material(title: "Only one")])
        let viewModel = MaterialLibraryViewModel(store: store)
        await viewModel.load()
        let only = viewModel.visibleMaterials[0]

        await viewModel.delete(only)

        // The view model reloads rather than mutating its array, so the empty state appears.
        #expect(viewModel.isEmpty)
    }

    @Test("A store failure is reported rather than swallowed")
    func failureIsReported() async {
        let store = InMemoryMaterialStore()
        await store.forceFailure(.storageFailed)
        let viewModel = MaterialLibraryViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.error == AppError.server(reference: "material-store-failed"))
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = MaterialLibraryViewModel(store: InMemoryMaterialStore())

        #expect(viewModel.title == L10n.libraryTitle.string)
        #expect(viewModel.searchPrompt == L10n.librarySearchPlaceholder.string)
        #expect(viewModel.emptyTitle == L10n.libraryEmptyTitle.string)
        #expect(viewModel.emptyBody == L10n.libraryEmptyBody.string)
        #expect(viewModel.noMatchesTitle == L10n.libraryNoMatchesTitle.string)
        #expect(viewModel.noMatchesBody == L10n.libraryNoMatchesBody.string)
    }

    @Test("Every source has a name and an icon")
    func everySourceIsNamed() {
        for source in MaterialSource.allCases {
            #expect(!source.title.isEmpty, "\(source) has no name")
            #expect(!source.symbolName.isEmpty, "\(source) has no icon")
        }
    }
}
