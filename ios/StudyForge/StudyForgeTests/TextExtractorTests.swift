//
//  TextExtractorTests.swift
//  StudyForgeTests
//
//  On-device PDF extraction. The PDFs are BUILT here rather than checked in as fixtures: a
//  generated document proves the extractor works on real PDF bytes, and it keeps a binary blob
//  out of the repository.
//
//  The distinction the error copy depends on is `emptyPDFIsNoTextFound`: a page with no words in
//  it is not a broken file, and telling a student their file is unreadable when the real problem
//  is that it has no text sends them looking for a fault that is not there.
//

import Foundation
import PDFKit
import Testing
import UIKit
@testable import StudyForge

@Suite("Text extraction")
struct TextExtractorTests {

    /// A real PDF, rendered in the test.
    private func writePDF(text: String, pages: Int = 1) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).pdf")

        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
            .pdfData { context in
                for _ in 0..<pages {
                    context.beginPage()
                    guard !text.isEmpty else { continue }
                    (text as NSString).draw(
                        at: CGPoint(x: 60, y: 60),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 16)]
                    )
                }
            }

        try data.write(to: url)
        return url
    }

    @Test("Text comes out of a PDF, on the device")
    func extractsText() async throws {
        let url = try writePDF(text: "Normalisation removes redundancy.")

        let extracted = try await PdfKitTextExtractor().extractText(fromPDFAt: url)

        #expect(extracted.text.contains("Normalisation"))
        #expect(extracted.text.contains("redundancy"))
        #expect(extracted.pageCount == 1)
        #expect(extracted.isBlank == false)
    }

    @Test("Every page is read, and the page count comes back")
    func readsEveryPage() async throws {
        let url = try writePDF(text: "Page body", pages: 3)

        let extracted = try await PdfKitTextExtractor().extractText(fromPDFAt: url)

        #expect(extracted.pageCount == 3)
        // Three pages of the same line: the result is the pages joined, not just the first.
        #expect(extracted.text.components(separatedBy: "Page body").count - 1 == 3)
    }

    @Test("A PDF with no text is noTextFound, not unreadable")
    func emptyPDFIsNoTextFound() async throws {
        let url = try writePDF(text: "")

        await #expect(throws: MaterialError.noTextFound) {
            _ = try await PdfKitTextExtractor().extractText(fromPDFAt: url)
        }
    }

    @Test("A file that is not a PDF is unreadable")
    func notAPDFIsUnreadable() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).pdf")
        try Data("this is not a pdf".utf8).write(to: url)

        await #expect(throws: MaterialError.unreadable) {
            _ = try await PdfKitTextExtractor().extractText(fromPDFAt: url)
        }
    }
}
