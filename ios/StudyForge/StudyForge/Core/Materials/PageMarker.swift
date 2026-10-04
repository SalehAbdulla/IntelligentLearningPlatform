//
//  PageMarker.swift
//  StudyForge
//
//  The marker the extractor writes between pages, and the one piece of page structure that
//  survives extraction.
//
//  WHY THIS EXISTS
//  ---------------
//  `TextExtractor` concatenates a PDF's pages into one string. That is all F03–F05 need, but it
//  destroys the ONE fact a citation cannot be reconstructed without: which page a passage came
//  from. F15's `76_Coach_Citation_SourceSheet` promises a page number, and docs/05 §2 defines
//  each chunk as "page + offset", so the boundary has to be recorded at extraction time — there
//  is nowhere later to recover it from.
//
//  WHY EXTRACTION OWNS THE FORMAT
//  ------------------------------
//  The producer defines the wire format and the consumer reads it, never the other way round: a
//  marker defined in `Core/Coach` would make F02 depend on F15. This file lives beside the
//  extractor for that reason, and every reader goes through `parse`.
//

import Foundation

/// The page-boundary marker written into extracted text.
enum PageMarker {

    /// Marks the start of a page. A printable, greppable form rather than a control character,
    /// so the extracted text stays inspectable in a debugger and a marker can be found by eye.
    static func forPage(_ number: Int) -> String { "\n[page \(number)]\n" }

    /// The marker without its trailing newline, for matching.
    private static let pattern = #"\[page (\d+)\]"#

    /// Splits text at the page markers, returning `(pageNumber, body)` pairs.
    ///
    /// Text before the first marker is returned with `page: nil` — an HTML or plain-text import
    /// has no pages, and inventing page 1 for it would put a page number on a citation that has
    /// no page.
    static func parse(_ text: String) -> [(page: Int?, body: String)] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [(nil, text)]
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard !matches.isEmpty else { return [(nil, text)] }

        var sections: [(page: Int?, body: String)] = []

        // Anything before the first marker has no page.
        if let first = matches.first, first.range.location > 0,
           let preamble = Range(NSRange(location: 0, length: first.range.location), in: text) {
            let body = String(text[preamble])
            if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sections.append((nil, body))
            }
        }

        for (index, match) in matches.enumerated() {
            guard let markerRange = Range(match.range, in: text),
                  let captured = Range(match.range(at: 1), in: text),
                  let page = Int(text[captured])
            else { continue }

            let bodyStart = markerRange.upperBound
            let bodyEnd = index + 1 < matches.count
                ? Range(matches[index + 1].range, in: text)?.lowerBound ?? text.endIndex
                : text.endIndex

            guard bodyStart <= bodyEnd else { continue }
            sections.append((page, String(text[bodyStart..<bodyEnd])))
        }

        return sections
    }
}
