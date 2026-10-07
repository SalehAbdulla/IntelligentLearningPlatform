//
//  ImportMaterialViewModel.swift
//  StudyForge
//
//  Presentation logic for the import path — C03's source choice, C05's on-device extraction,
//  C06's success and C07's error, in one sheet rather than four screens.
//
//  WHY TWO SOURCES AND NOT FIVE
//  ---------------------------
//  Paste text, and a PDF chosen from Files. docs/03 §C also draws Photos, a camera scan and a
//  pasted link: the first two need Vision and a camera session, neither of which this build has
//  wired, and a link needs a network fetch with failure modes of its own. The two here are the
//  ones that run end to end TODAY, on the device, with no new capability — and the PDF is the one
//  the sprint gate names.
//
//  WHY THE STEPS ARE ONE SHEET
//  --------------------------
//  The design splits them so each can carry its own progress and error state. With two sources
//  and sub-second extraction, four screens would be four dismissals for one action; the states the
//  design cares about (working, failed, done) are all present, they are just drawn in place.
//

import Foundation

//  WHY A DUPLICATE IS CAUGHT BEFORE IT IS WRITTEN
//  ---------------------------------------------
//  The same material imported twice is almost never wanted: it doubles the library entry, and every
//  AI feature would then generate from it twice: two summaries, two decks, two sets of cards for one
//  piece of material. So the extracted text's hash (the same `textHash` the AI cache keys on) is
//  checked against the library before the write, and the student chooses Replace or Keep both
//  (docs/02 §6, the F02 "duplicate file" edge case) rather than the app guessing on their behalf.

@MainActor
@Observable
final class ImportMaterialViewModel {

    /// What the student chose to bring in.
    enum Source: String, CaseIterable, Identifiable {
        case text
        case pdf

        var id: String { rawValue }
    }

    // MARK: Bound state

    var source: Source

    var title = ""
    var pastedText = ""
    var tagsText = ""

    // MARK: Derived state

    private(set) var isImporting = false
    private(set) var error: AppError?
    private(set) var titleError: String?
    private(set) var textError: String?

    /// Set once something was imported, so the sheet can close itself and the library reload.
    private(set) var didImport = false

    /// The library item a pending import would duplicate, when one was found. Non-`nil` means the
    /// student is being asked what to do, and the import is held until they answer.
    private(set) var duplicate: Material?

    /// The import waiting on that answer.
    private var pendingImport: Material?

    var isResolvingDuplicate: Bool { duplicate != nil }

    private let store: any MaterialStore
    private let extractor: any TextExtractor

    init(
        store: any MaterialStore,
        extractor: any TextExtractor = PdfKitTextExtractor(),
        source: Source = .text
    ) {
        self.store = store
        self.extractor = extractor
        self.source = source
    }

    // MARK: Copy

    var sheetTitle: String { L10n.importTitle.string }
    var pasteTextTitle: String { L10n.importSourceTextTitle.string }
    var pasteTextDetail: String { L10n.importSourceTextDetail.string }
    var choosePdfTitle: String { L10n.importSourcePdfTitle.string }
    var choosePdfDetail: String { L10n.importSourcePdfDetail.string }
    var nameLabel: String { L10n.importNameLabel.string }
    var namePlaceholder: String { L10n.importNamePlaceholder.string }
    var textLabel: String { L10n.importTextLabel.string }
    var textHint: String { L10n.importTextHint.string }
    var tagsLabel: String { L10n.importTagsLabel.string }
    var tagsHint: String { L10n.importTagsHint.string }
    var submitTitle: String { L10n.importSubmit.string }
    var submittingTitle: String { L10n.importSubmitting.string }
    var duplicateTitle: String { L10n.importDuplicateTitle.string }
    var duplicateReplaceTitle: String { L10n.importDuplicateReplace.string }
    var duplicateKeepBothTitle: String { L10n.importDuplicateKeepBoth.string }

    /// The prompt's message, naming the item already in the library so the student knows what it is.
    var duplicateMessage: String { L10n.importDuplicateBody.string(duplicate?.title ?? "") }

    var isSubmitEnabled: Bool { !isImporting }

    // MARK: Actions

    func importPastedText() async {
        guard !isImporting else { return }
        reset()

        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validate(name: name, text: text) else { return }

        isImporting = true
        defer { isImporting = false }

        await addIfUnique(
            Material(title: name, source: .text, text: text, tags: parsedTags())
        )
    }

    /// Imports a PDF the student chose from Files.
    ///
    /// The title falls back to the file's name, because a student who just wants the text in
    /// should not have to type a name it already has.
    func importPDF(at url: URL) async {
        guard !isImporting else { return }
        reset()

        // A file from Files or iCloud lives outside this app's container, so it has to be opened
        // through a security-scoped grant — released afterwards whatever the outcome, or the
        // grant leaks for the life of the process.
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        isImporting = true
        defer { isImporting = false }

        do {
            let extracted = try await extractor.extractText(fromPDFAt: url)

            let typed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let fromFile = url.deletingPathExtension().lastPathComponent

            await addIfUnique(
                Material(
                    title: typed.isEmpty ? fromFile : typed,
                    source: .pdf,
                    text: extracted.text,
                    pageCount: extracted.pageCount,
                    tags: parsedTags()
                )
            )
        } catch {
            self.error = AppError.from(error)
        }
    }

    // MARK: Helpers

    /// Writes the material, unless its text is already in the library, in which case it is held and
    /// the student is asked instead. See the note at the top of the file.
    private func addIfUnique(_ material: Material) async {
        do {
            let existing = try await store.all().first {
                $0.textHash == material.textHash && $0.id != material.id
            }

            guard let existing else {
                try await store.add(material)
                didImport = true
                return
            }

            duplicate = existing
            pendingImport = material
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Replaces the copy already in the library with the new one: the student meant to update it.
    func replaceDuplicate() async {
        guard let pendingImport, let duplicate else { return }
        await resolve {
            try await self.store.delete(id: duplicate.id)
            try await self.store.add(pendingImport)
        }
    }

    /// Keeps both: the student knows they have two versions and wants the second one too.
    func keepBoth() async {
        guard let pendingImport else { return }
        await resolve { try await self.store.add(pendingImport) }
    }

    /// Dismisses the prompt without importing, leaving the filled-in form on screen.
    func cancelDuplicate() {
        duplicate = nil
        pendingImport = nil
    }

    /// Runs the chosen write, reports a failure, and clears the held import either way: a prompt
    /// that outlived its decision would be worse than an error.
    private func resolve(_ write: () async throws -> Void) async {
        do {
            try await write()
            didImport = true
        } catch {
            self.error = AppError.from(error)
        }
        duplicate = nil
        pendingImport = nil
    }

    private func reset() {
        error = nil
        titleError = nil
        textError = nil
    }

    private func validate(name: String, text: String) -> Bool {
        if name.isEmpty { titleError = L10n.importErrorName.string }
        if text.isEmpty { textError = L10n.importErrorText.string }
        return titleError == nil && textError == nil
    }

    /// Tags from the comma-separated field: trimmed, blanks dropped, de-duplicated
    /// case-insensitively while keeping the student's own spelling of the first one they typed.
    private func parsedTags() -> [String] {
        var seen = Set<String>()
        return tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }
}
