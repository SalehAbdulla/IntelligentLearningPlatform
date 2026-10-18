import Foundation

enum SummaryStep: Equatable {
    case configure
    case generating
    case result
    case quotaExceeded
}

enum SummaryEngine: Equatable {
    case onDevice
    case cloud

    var badgeTitle: String {
        switch self {
        case .onDevice: L10n.summaryEngineOnDevice.string
        case .cloud: L10n.summaryEngineFirebaseAI.string
        }
    }

    var symbolName: String {
        switch self {
        case .onDevice: "bolt.fill"
        case .cloud: "cloud.fill"
        }
    }
}

enum SummaryLimits {
    static let focusMaxCharacters = 120
    static let focusMaxTopics = 5
    static let focusMaxTopicCharacters = 40
    static let tldrMaxCharacters = 300
    static let keyPointMaxCharacters = 120
    static let keyPointMaxCount = 8
}

struct SummaryGlossaryItem: Identifiable, Equatable {
    let id = UUID()
    let term: String
    let definition: String
    let confidence: Double

    var isHighConfidence: Bool { confidence >= 0.8 }

    var confidenceLabel: String {
        let level = confidence >= 0.8 ? "high" : confidence >= 0.5 ? "medium" : "low"
        return "Confidence: \(level) · \(String(format: "%.2f", confidence))"
    }
}

struct SummarySource: Equatable {
    let page: Int
    let fileName: String
    let quote: String
    let relevance: Double

    var chipTitle: String { "p.\(page) cite" }
    var relevanceLabel: String { "Relevance \(String(format: "%.2f", relevance))" }
}

struct GeneratedSummary: Equatable {
    var title: String
    var tldr: String
    var keyPoints: [String]
    var glossary: [SummaryGlossaryItem]
    var source: SummarySource
    var style: SummaryStyle

    var shareText: String {
        var lines = [title, "", "TL;DR", tldr, "", "Key points"]
        lines += keyPoints.map { "• \($0)" }
        if !glossary.isEmpty {
            lines += ["", "Glossary"]
            lines += glossary.map { "\($0.term): \($0.definition)" }
        }
        lines += ["", "Source: \(source.fileName), p.\(source.page)"]
        return lines.joined(separator: "\n")
    }
}

extension SummaryLength {
    var optionTitle: String {
        switch self {
        case .short: L10n.summaryLengthShort.string
        case .standard: L10n.summaryLengthStandard.string
        case .examReady: L10n.summaryLengthExamReady.string
        }
    }

    var keyPointCount: Int {
        switch self {
        case .short: 2
        case .standard: 4
        case .examReady: 6
        }
    }
}

extension SummaryStyle {
    var optionTitle: String {
        switch self {
        case .bullets: L10n.summaryStyleBullets.string
        case .narrative: L10n.summaryStyleNarrative.string
        case .cornell: L10n.summaryStyleCornell.string
        }
    }
}

extension OutputLanguage {
    var optionTitle: String {
        switch self {
        case .english: L10n.summaryLanguageEnglish.string
        case .arabic: L10n.summaryLanguageArabic.string
        }
    }
}

enum SummaryMock {
    static func make(
        material: Material,
        fileName: String,
        length: SummaryLength,
        style: SummaryStyle,
        focusTopics: [String]
    ) -> GeneratedSummary {
        let sentences = material.text
            .split(whereSeparator: { ".!?؟\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let tldr = sentences.first.map { $0 + "." } ?? material.title
        var points = Array(sentences.dropFirst().prefix(length.keyPointCount))
        if points.isEmpty {
            points = [tldr]
        }
        for topic in focusTopics where points.count < SummaryLimits.keyPointMaxCount {
            points.append("Focus: \(topic)")
        }

        let glossary = material.tags.prefix(3).enumerated().map { index, tag in
            SummaryGlossaryItem(
                term: tag.capitalized,
                definition: "A key term covered in \(material.title).",
                confidence: max(0.92 - Double(index) * 0.2, 0.3)
            )
        }

        let quoteSource = sentences.last ?? String(material.text.prefix(120))

        return GeneratedSummary(
            title: "\(material.title) — Summary",
            tldr: tldr,
            keyPoints: points,
            glossary: glossary,
            source: SummarySource(
                page: max((material.pageCount ?? 1) / 2, 1),
                fileName: fileName,
                quote: "\"…\(quoteSource)…\"",
                relevance: 0.92
            ),
            style: style
        )
    }
}
