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

    init(tier: AITier) {
        self = tier == .onDevice ? .onDevice : .cloud
    }

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
    static let minimumSourceCharacters = 200
    static let focusMaxCharacters = 120
    static let focusMaxTopics = 5
    static let focusMaxTopicCharacters = 40
    static let titleMaxCharacters = 80
    static let tldrMaxCharacters = 300
    static let keyPointMaxCharacters = 160
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
    let page: Int?
    let fileName: String
    let excerpt: String
    let relevance: Double

    var quote: String { "\"…\(excerpt)…\"" }
    var pageLabel: String { page.map { "p.\($0)" } ?? L10n.summarySource.string }
    var chipTitle: String { page.map { "p.\($0) cite" } ?? L10n.summarySource.string }
    var sheetTitle: String { page.map { "\(L10n.summarySource.string) · p.\($0)" } ?? L10n.summarySource.string }
    var relevanceLabel: String { "Relevance \(String(format: "%.2f", relevance))" }
}

struct GeneratedSummary: Equatable {
    var title: String
    var tldr: String
    var keyPoints: [String]
    var glossary: [SummaryGlossaryItem]
    let source: SummarySource
    let style: SummaryStyle
    let length: SummaryLength
    let language: OutputLanguage
    let provenance: AIProvenance
    let tier: AITier

    var engine: SummaryEngine { SummaryEngine(tier: tier) }

    var shareText: String {
        var lines = [title, "", "TL;DR", tldr, "", L10n.summaryKeyPointsHeading.string]
        lines += keyPoints.map { "• \($0)" }
        if !glossary.isEmpty {
            lines += ["", L10n.summaryGlossaryHeading.string]
            lines += glossary.map { "\($0.term): \($0.definition)" }
        }
        lines += ["", "\(L10n.summarySource.string): \(source.fileName), \(source.pageLabel)"]
        return lines.joined(separator: "\n")
    }

    func stored(id: String) -> Summary {
        Summary(
            id: id,
            title: title,
            length: length,
            style: style,
            language: language,
            tldr: tldr,
            keyPoints: keyPoints,
            glossary: glossary.map { SummaryTerm(term: $0.term, definition: $0.definition) },
            provenance: provenance,
            tier: tier
        )
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
