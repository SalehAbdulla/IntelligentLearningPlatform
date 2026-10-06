//
//  TextChunk.swift
//  StudyForge
//
//  F15 — a passage of a material, and the chunker that produces it (docs/05 §2
//  `materials/{id}/chunks/{chunkId}`; docs/02 §5's `RetrievalService` contract).
//
//  WHY CHUNK AT ALL
//  ----------------
//  The advanced feature's first technique is retrieval: a question is matched against chunks and
//  only the top few are put in the model's context. That is what makes a grounded answer possible
//  and what keeps a 40-page PDF from being pasted into every prompt. A chunk therefore has to be
//  small enough to be a meaningful citation and large enough to answer from — hence a target size
//  rather than a fixed split, and boundaries that follow paragraphs so a chunk is about one thing.
//
//  WHY THE PAGE IS CARRIED ON THE CHUNK
//  ------------------------------------
//  `76_Coach_Citation_SourceSheet` shows a page number, and the ONLY place that fact exists is the
//  marker `TextExtractor` writes (`PageMarker`). Carrying it on the chunk is what turns "the model
//  said so" into "page 12 says so".
//

import Foundation

/// One passage of a material, with the page it came from.
struct TextChunk: Identifiable, Equatable, Sendable, Codable {

    /// `"{materialId}#{ordinal}"` — derived, so the same material always chunks to the same ids
    /// and a re-index updates rather than duplicates.
    let id: String

    let materialId: String

    /// The passage, as extracted. Never rewritten — a citation must quote the source.
    let text: String

    /// The page it came from, or `nil` for a source that has no pages (a link or pasted text).
    let page: Int?

    /// Position within the material, 0-based. Orders the chunks for reading.
    let ordinal: Int

    /// Character offset of the passage within the extracted text. Approximate by construction —
    /// it accumulates the lengths of the pieces the chunker emitted.
    let startOffset: Int

    init(materialId: String, text: String, page: Int?, ordinal: Int, startOffset: Int) {
        self.id = "\(materialId)#\(ordinal)"
        self.materialId = materialId
        self.text = text
        self.page = page
        self.ordinal = ordinal
        self.startOffset = startOffset
    }
}

/// Splits extracted text into retrievable chunks.
enum TextChunker {

    /// How large a chunk should be, in characters.
    ///
    /// Roughly 150–200 words: long enough to answer a question from, short enough that a citation
    /// points at a passage rather than a chapter.
    static let targetCharacters = 700

    /// Chunks a material's extracted text.
    ///
    /// Page boundaries are respected FIRST, so a chunk never straddles two pages — a citation
    /// spanning a page break would have to name one page and be wrong about the other.
    static func chunk(_ text: String, materialId: String) -> [TextChunk] {
        var chunks: [TextChunk] = []
        var ordinal = 0
        var offset = 0

        for (page, body) in PageMarker.parse(text) {
            for piece in split(body) {
                chunks.append(TextChunk(
                    materialId: materialId,
                    text: piece,
                    page: page,
                    ordinal: ordinal,
                    startOffset: offset
                ))
                ordinal += 1
                offset += piece.count
            }
        }

        return chunks
    }

    /// Packs a page's paragraphs into target-sized pieces.
    ///
    /// Paragraph first, because a chunk about one thing retrieves better than a chunk about four;
    /// an over-long paragraph is then broken at a word boundary rather than mid-word.
    private static func split(_ body: String) -> [String] {
        let paragraphs = body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var pieces: [String] = []
        var current = ""

        for paragraph in paragraphs {
            let groups = paragraph.count <= targetCharacters ? [paragraph] : breakLong(paragraph)

            for group in groups {
                guard !group.isEmpty else { continue }

                if current.isEmpty {
                    current = group
                } else if current.count + group.count + 2 <= targetCharacters {
                    current += "\n\n" + group
                } else {
                    pieces.append(current)
                    current = group
                }
            }
        }

        if !current.isEmpty { pieces.append(current) }
        return pieces
    }

    /// Breaks a paragraph that is longer than a whole chunk, at word boundaries.
    private static func breakLong(_ paragraph: String) -> [String] {
        var pieces: [String] = []
        var remaining = Substring(paragraph)

        while remaining.count > targetCharacters {
            let window = remaining.prefix(targetCharacters)
            let cut = window.lastIndex(of: " ") ?? window.endIndex

            let piece = remaining[remaining.startIndex..<cut]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !piece.isEmpty { pieces.append(piece) }

            remaining = remaining[cut...].drop { $0 == " " }
        }

        let tail = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { pieces.append(tail) }

        return pieces
    }
}
