import Foundation

struct SummaryMaterialSection: Identifiable, Equatable {
    let id: Int
    let page: Int?
    let body: String
}

enum SummaryGrounding {

    static func sections(of material: Material) -> [SummaryMaterialSection] {
        PageMarker.parse(material.text).enumerated().compactMap { index, section in
            let body = section.body.trimmingCharacters(in: .whitespacesAndNewlines)
            return body.isEmpty ? nil : SummaryMaterialSection(id: index, page: section.page, body: body)
        }
    }

    static func sentences(in text: String) -> [String] {
        text.split(whereSeparator: { ".!?؟\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 3 }
    }

    static func words(in text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 }
        )
    }

    static func coverage(of claim: String, in source: Set<String>) -> Double {
        let claimWords = words(in: claim)
        guard !claimWords.isEmpty else { return 0 }
        return Double(claimWords.intersection(source).count) / Double(claimWords.count)
    }

    static func summary(
        from generated: AIGenerated<AISummary>,
        material: Material,
        fileName: String,
        length: SummaryLength,
        style: SummaryStyle,
        language: OutputLanguage
    ) -> GeneratedSummary {
        let keyPoints = generated.value.keyPoints
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(SummaryLimits.keyPointMaxCount)
        let tldr = generated.value.tldr.trimmingCharacters(in: .whitespacesAndNewlines)

        return GeneratedSummary(
            title: "\(material.title) — Summary",
            tldr: tldr.isEmpty ? (keyPoints.first ?? material.title) : tldr,
            keyPoints: Array(keyPoints),
            glossary: glossary(for: generated.value, material: material),
            source: source(for: generated, material: material, fileName: fileName),
            style: style,
            length: length,
            language: language,
            provenance: generated.provenance,
            tier: generated.tier
        )
    }

    static func glossary(for value: AISummary, material: Material) -> [SummaryGlossaryItem] {
        let sourceWords = words(in: material.text)
        let lowered = material.text.lowercased()
        return value.glossary.compactMap { entry in
            let term = entry.term.trimmingCharacters(in: .whitespacesAndNewlines)
            let definition = entry.definition.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty, !definition.isEmpty else { return nil }
            let termScore = lowered.contains(term.lowercased()) ? 1.0 : 0.0
            let score = 0.5 * termScore + 0.5 * coverage(of: definition, in: sourceWords)
            return SummaryGlossaryItem(term: term, definition: definition, confidence: rounded(score))
        }
    }

    static func source(
        for generated: AIGenerated<AISummary>,
        material: Material,
        fileName: String
    ) -> SummarySource {
        let allSections = Self.sections(of: material)
        let citedPage = generated.provenance.pageNumbers.min()
        let pageSections = allSections.filter { citedPage != nil && $0.page == citedPage }
        let pool = (pageSections.isEmpty ? allSections : pageSections).flatMap { sentences(in: $0.body) }

        let claimWords = words(in: ([generated.value.tldr] + generated.value.keyPoints).joined(separator: " "))
        let scored = pool.map { sentence -> (sentence: String, score: Double) in
            let sentenceWords = words(in: sentence)
            guard !sentenceWords.isEmpty else { return (sentence, 0) }
            return (sentence, Double(sentenceWords.intersection(claimWords).count) / Double(sentenceWords.count))
        }
        let best = scored.max { $0.score < $1.score }
        let fallback = material.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let excerpt = String((best?.sentence ?? fallback).prefix(240))
        let page = citedPage ?? allSections.first(where: { $0.body.contains(excerpt) })?.page

        return SummarySource(
            page: page,
            fileName: fileName,
            excerpt: excerpt,
            relevance: rounded(best?.score ?? 0)
        )
    }

    static func targetSectionID(for source: SummarySource, in sections: [SummaryMaterialSection]) -> Int? {
        if let match = sections.first(where: { $0.body.contains(source.excerpt) }) {
            return match.id
        }
        if let page = source.page, let match = sections.first(where: { $0.page == page }) {
            return match.id
        }
        return sections.first?.id
    }

    private static func rounded(_ value: Double) -> Double {
        (min(max(value, 0), 1) * 100).rounded() / 100
    }
}
