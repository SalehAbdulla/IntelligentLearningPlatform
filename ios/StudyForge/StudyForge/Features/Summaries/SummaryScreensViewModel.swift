import Foundation

@MainActor
@Observable
final class SummaryScreensViewModel {

    var length: SummaryLength = .standard
    var style: SummaryStyle = .bullets
    var language: OutputLanguage = .english
    var focusTopics = ""

    private(set) var step: SummaryStep = .configure
    private(set) var engine: SummaryEngine
    private(set) var summary: GeneratedSummary?
    private(set) var usedToday: Int
    private(set) var isSaved = false

    let material: Material
    let dailyLimit: Int

    private var generationTask: Task<Void, Never>?

    init(material: Material, engine: SummaryEngine = .cloud, usedToday: Int = 0, dailyLimit: Int = 3) {
        self.material = material
        self.engine = engine
        self.usedToday = max(usedToday, 0)
        self.dailyLimit = max(dailyLimit, 0)
    }

    var fileName: String {
        material.source == .pdf ? "\(material.title).pdf" : material.title
    }

    var topics: [String] {
        focusTopics
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var focusError: String? {
        let topics = topics
        if topics.count > SummaryLimits.focusMaxTopics {
            return "Use up to \(SummaryLimits.focusMaxTopics) topics, separated by commas."
        }
        if topics.contains(where: { $0.count > SummaryLimits.focusMaxTopicCharacters }) {
            return "Each topic must be \(SummaryLimits.focusMaxTopicCharacters) characters or fewer."
        }
        if topics.contains(where: { $0.rangeOfCharacter(from: .alphanumerics) == nil }) {
            return "Topics need letters or numbers."
        }
        if Set(topics.map { $0.lowercased() }).count != topics.count {
            return "Remove repeated topics."
        }
        return nil
    }

    var materialError: String? {
        material.hasNoText ? "This material has no readable text yet. Re-import it and try again." : nil
    }

    var canGenerate: Bool {
        step == .configure && focusError == nil && materialError == nil
    }

    var remainingToday: Int {
        max(dailyLimit - usedToday, 0)
    }

    func limitFocusTopics() {
        var cleaned = focusTopics.replacingOccurrences(of: "\n", with: " ")
        if cleaned.count > SummaryLimits.focusMaxCharacters {
            cleaned = String(cleaned.prefix(SummaryLimits.focusMaxCharacters))
        }
        if cleaned != focusTopics {
            focusTopics = cleaned
        }
    }

    func generate() {
        guard canGenerate else { return }
        if engine == .cloud && usedToday >= dailyLimit {
            step = .quotaExceeded
            return
        }
        isSaved = false
        step = .generating
        generationTask?.cancel()
        generationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            self?.finishGeneration()
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        step = .configure
    }

    func switchToOnDevice() {
        engine = .onDevice
        step = .configure
        generate()
    }

    func backToConfigure() {
        generationTask?.cancel()
        generationTask = nil
        summary = nil
        isSaved = false
        step = .configure
    }

    func save() {
        guard summary != nil, !isSaved else { return }
        isSaved = true
    }

    func editError(tldr: String, keyPoints: [String]) -> String? {
        if tldr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "The TL;DR can't be empty."
        }
        if keyPoints.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return "Keep at least one key point."
        }
        return nil
    }

    func applyEdits(tldr: String, keyPoints: [String]) {
        guard summary != nil, editError(tldr: tldr, keyPoints: keyPoints) == nil else { return }
        summary?.tldr = String(tldr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(SummaryLimits.tldrMaxCharacters))
        summary?.keyPoints = keyPoints
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(SummaryLimits.keyPointMaxCount)
            .map { String($0.prefix(SummaryLimits.keyPointMaxCharacters)) }
        isSaved = false
    }

    func resetText(now: Date = .now) -> String {
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let reset = calendar.startOfDay(for: nextDay)
        let minutes = max(Int(reset.timeIntervalSince(now) / 60), 1)
        return "\(minutes / 60) h \(minutes % 60) m"
    }

    private func finishGeneration() {
        guard step == .generating else { return }
        summary = SummaryMock.make(
            material: material,
            fileName: fileName,
            length: length,
            style: style,
            focusTopics: topics
        )
        if engine == .cloud {
            usedToday += 1
        }
        generationTask = nil
        step = .result
    }
}
