//
//  TextExtractor.swift
//  StudyForge
//
//  Pulls the text out of a source, ON THE DEVICE.
//
//  WHY THIS IS THE WHOLE POINT OF D24
//  ----------------------------------
//  The decision to bypass Cloud Storage (D24, docs/09 R21) only holds up if extraction happens
//  here too. If the text had to be produced by a server, the file would have to be uploaded,
//  which is the Blaze dependency the decision exists to avoid. So extraction is on-device, and
//  everything downstream — summaries, cards, quizzes, search — reads what this produced.
//
//  WHY A PROTOCOL AND NOT A PDFKIT CALL AT THE CALL SITE
//  ----------------------------------------------------
//  Two reasons, and only one of them is testing. The other is that images and camera scans are
//  already designed (C03's source grid) and will need Vision rather than PDFKit; a caller that
//  names PDFKit would have to change when they arrive, and a caller that asks for "the text of
//  this source" will not.
//

import Foundation
import PDFKit

/// The text pulled out of a source, plus what came with it.
struct ExtractedText: Equatable, Sendable {

    let text: String

    /// How many pages the source had, when it had pages.
    let pageCount: Int?

    /// The extracted text with surrounding whitespace removed, for the "is there anything here"
    /// question.
    var isBlank: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Turns a source into text.
protocol TextExtractor: Sendable {

    /// Extracts the text of a PDF at `url`.
    ///
    /// - Throws: `MaterialError.unreadable` when the file is not a PDF this build can open, and
    ///   `MaterialError.noTextFound` when it opens but yields nothing — those are different
    ///   problems with different fixes, so they are different errors.
    func extractText(fromPDFAt url: URL) async throws -> ExtractedText
}

/// The real extractor: PDFKit, on the device.
struct PdfKitTextExtractor: TextExtractor {

    func extractText(fromPDFAt url: URL) async throws -> ExtractedText {
        // `pageCount > 0` and not just non-nil: PDFKit hands back a document object for some
        // files it cannot actually parse, and a "document" with no pages is not a readable PDF —
        // calling it `noTextFound` would send the student looking for a text problem in a file
        // that is simply not a PDF.
        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw MaterialError.unreadable
        }

        // Per page rather than `document.string`, so a page that fails to parse does not take the
        // rest of the document with it — a partly-readable scan is worth more than nothing.
        //
        // The page marker is written BEFORE each page. F03–F05 ignore it (it is just text to a
        // model), while F15's chunker reads it to attribute a passage back to its page — the one
        // fact a citation cannot be reconstructed without. See `PageMarker` for why the boundary
        // must be recorded here rather than derived later.
        var text = ""
        for index in 0..<document.pageCount {
            if let page = document.page(at: index)?.string {
                text += PageMarker.forPage(index + 1)
                text += page
                text += "\n"
            }
        }

        let extracted = ExtractedText(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            pageCount: document.pageCount
        )

        // Checked here rather than by the caller: "opened but empty" is a property of the
        // extraction, and every caller would otherwise have to remember to ask.
        guard !extracted.isBlank else { throw MaterialError.noTextFound }

        return extracted
    }
}
