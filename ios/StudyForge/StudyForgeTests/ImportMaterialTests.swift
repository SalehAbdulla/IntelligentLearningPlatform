//
//  ImportMaterialTests.swift
//  StudyForgeTests
//
//  Tests for the import path: a source in, a library item out.
//
//  The two that matter are `pastedTextIsCleanedAndDeDuplicated` — the tags a student types are
//  messy, and a library full of "Databases" and "databases" is a library nobody can filter — and
//  `aChosenPDFKeepsItsFileNameAsTheTitle`, because making someone name a file that already has a
//  name is how an import screen becomes a chore.
//

import Foundation
import Testing
@testable import StudyForge

/// A stand-in extractor, so the PDF path can be tested without a real file.
private struct StubExtractor: TextExtractor {
    func extractText(fromPDFAt url: URL) async throws -> ExtractedText {
        ExtractedText(text: "extracted body", pageCount: 12)
    }
}

private struct FailingExtractor: TextExtractor {
    let error: MaterialError
    func extractText(fromPDFAt url: URL) async throws -> ExtractedText {
        throw error
    }
}

@Suite("Import material")
@MainActor
struct ImportMaterialTests {

    private func model(store: InMemoryMaterialStore = InMemoryMaterialStore()) -> ImportMaterialViewModel {
        ImportMaterialViewModel(store: store)
    }

    // MARK: Pasted text

    @Test("Pasted text becomes a material, trimmed, with its tags tidied")
    func pastedTextIsCleanedAndDeDuplicated() async {
        let store = InMemoryMaterialStore()
        let viewModel = model(store: store)
        viewModel.title = "  Lecture 4  "
        viewModel.pastedText = "  Normalisation removes redundancy.  "
        viewModel.tagsText = "databases, , Databases , normalisation"

        await viewModel.importPastedText()

        let all = try? await store.all()
        #expect(viewModel.didImport)
        #expect(all?.count == 1)
        #expect(all?.first?.title == "Lecture 4")
        #expect(all?.first?.text == "Normalisation removes redundancy.")
        #expect(all?.first?.source == .text)
        // Blanks dropped, de-duplicated case-insensitively, the student's own spelling kept.
        #expect(all?.first?.tags == ["databases", "normalisation"])
    }

    @Test("A blank title or a blank body is refused, and nothing is written")
    func blanksAreRefused() async {
        let store = InMemoryMaterialStore()
        let viewModel = model(store: store)

        await viewModel.importPastedText()

        #expect(viewModel.titleError == L10n.importErrorName.string)
        #expect(viewModel.textError == L10n.importErrorText.string)
        #expect(viewModel.didImport == false)
        let all = try? await store.all()
        #expect(all?.isEmpty == true)
    }

    // MARK: A chosen PDF

    @Test("A chosen PDF is extracted, and its file name becomes the title")
    func aChosenPDFKeepsItsFileNameAsTheTitle() async {
        let store = InMemoryMaterialStore()
        let viewModel = ImportMaterialViewModel(store: store, extractor: StubExtractor())

        await viewModel.importPDF(at: URL(fileURLWithPath: "/tmp/Lecture 7 - Indexing.pdf"))

        let all = try? await store.all()
        #expect(viewModel.didImport)
        #expect(all?.first?.title == "Lecture 7 - Indexing")
        #expect(all?.first?.source == .pdf)
        #expect(all?.first?.text == "extracted body")
        #expect(all?.first?.pageCount == 12)
    }

    @Test("A typed title beats the file name")
    func aTypedTitleBeatsTheFileName() async {
        let store = InMemoryMaterialStore()
        let viewModel = ImportMaterialViewModel(store: store, extractor: StubExtractor())
        viewModel.title = "Indexing (week 7)"

        await viewModel.importPDF(at: URL(fileURLWithPath: "/tmp/lecture7.pdf"))

        let all = try? await store.all()
        #expect(all?.first?.title == "Indexing (week 7)")
    }

    @Test("A file that cannot be read is reported, and nothing is written")
    func anUnreadableFileIsReported() async {
        let store = InMemoryMaterialStore()
        let viewModel = ImportMaterialViewModel(
            store: store,
            extractor: FailingExtractor(error: .noTextFound)
        )

        await viewModel.importPDF(at: URL(fileURLWithPath: "/tmp/blank-scan.pdf"))

        #expect(viewModel.error == MaterialError.noTextFound.asAppError)
        #expect(viewModel.didImport == false)
        let all = try? await store.all()
        #expect(all?.isEmpty == true)
    }

    @Test("A store that refuses the write is reported rather than swallowed")
    func aStoreFailureIsReported() async {
        let store = InMemoryMaterialStore()
        await store.forceFailure(.storageFailed)
        let viewModel = model(store: store)
        viewModel.title = "Lecture 4"
        viewModel.pastedText = "body"

        await viewModel.importPastedText()

        #expect(viewModel.error == AppError.server(reference: "material-store-failed"))
        #expect(viewModel.didImport == false)
    }

    // MARK: Duplicates

    @Test("The same text twice asks, and Replace swaps the copy")
    func duplicatePromptsAndReplaceSwaps() async {
        let store = InMemoryMaterialStore()
        let first = model(store: store)
        first.title = "Lecture 4"
        first.pastedText = "Normalisation removes redundancy."
        await first.importPastedText()
        #expect(first.didImport)

        // The same body under a new title is still a duplicate of what is already in the library.
        let second = model(store: store)
        second.title = "Lecture 4 (updated)"
        second.pastedText = "Normalisation removes redundancy."
        await second.importPastedText()

        #expect(second.isResolvingDuplicate, "a duplicate must prompt, not silently add a copy")
        #expect(second.didImport == false)

        await second.replaceDuplicate()

        let all = try? await store.all()
        #expect(second.didImport)
        #expect(all?.count == 1)
        #expect(all?.first?.title == "Lecture 4 (updated)")
    }

    @Test("Keep both adds the second copy alongside")
    func duplicateKeepBothKeepsTwo() async {
        let store = InMemoryMaterialStore()
        let first = model(store: store)
        first.title = "A"
        first.pastedText = "same body"
        await first.importPastedText()

        let second = model(store: store)
        second.title = "B"
        second.pastedText = "same body"
        await second.importPastedText()
        #expect(second.isResolvingDuplicate)
        await second.keepBoth()

        let all = try? await store.all()
        #expect(second.didImport)
        #expect(all?.count == 2)
    }

    @Test("Cancelling the prompt imports nothing and changes nothing")
    func duplicateCancelChangesNothing() async {
        let store = InMemoryMaterialStore()
        let first = model(store: store)
        first.title = "A"
        first.pastedText = "same body"
        await first.importPastedText()

        let second = model(store: store)
        second.title = "B"
        second.pastedText = "same body"
        await second.importPastedText()
        second.cancelDuplicate()

        let all = try? await store.all()
        #expect(second.isResolvingDuplicate == false)
        #expect(second.didImport == false)
        #expect(all?.count == 1)
    }

    // MARK: Copy

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model()

        #expect(viewModel.sheetTitle == L10n.importTitle.string)
        #expect(viewModel.pasteTextTitle == L10n.importSourceTextTitle.string)
        #expect(viewModel.pasteTextDetail == L10n.importSourceTextDetail.string)
        #expect(viewModel.choosePdfTitle == L10n.importSourcePdfTitle.string)
        #expect(viewModel.choosePdfDetail == L10n.importSourcePdfDetail.string)
        #expect(viewModel.nameLabel == L10n.importNameLabel.string)
        #expect(viewModel.namePlaceholder == L10n.importNamePlaceholder.string)
        #expect(viewModel.textLabel == L10n.importTextLabel.string)
        #expect(viewModel.textHint == L10n.importTextHint.string)
        #expect(viewModel.tagsLabel == L10n.importTagsLabel.string)
        #expect(viewModel.tagsHint == L10n.importTagsHint.string)
        #expect(viewModel.submitTitle == L10n.importSubmit.string)
        #expect(viewModel.submittingTitle == L10n.importSubmitting.string)
    }
}
