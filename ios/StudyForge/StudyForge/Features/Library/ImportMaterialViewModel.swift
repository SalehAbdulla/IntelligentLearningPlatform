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

        await save(
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

            await save(
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

    private func save(_ material: Material) async {
        do {
            try await store.add(material)
            didImport = true
        } catch {
            self.error = AppError.from(error)
        }
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
