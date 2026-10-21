import Foundation

@MainActor
@Observable
final class SummaryScreensViewModel {

    var length: SummaryLength = .standard
    var style: SummaryStyle = .bullets
    var language: OutputLanguage = .english
    var focusTopics = ""

    private(set) var step: SummaryStep = .configure
    private(set) var engine: SummaryEngine = .onDevice
    private(set) var summary: GeneratedSummary?
    private(set) var savedSummaryID: String?
    private(set) var hasUnsavedChanges = false
    private(set) var isSaving = false
    private(set) var error: AppError?

    let material: Material

    private let router: AIRouter
    private let store: any SummaryStore
    private let learningStyle: LearningStyle

    @ObservationIgnored private var generationTask: Task<Void, Never>?
    @ObservationIgnored private var generationID = UUID()

    init(
        material: Material,
        router: AIRouter,
        store: any SummaryStore,
        learningStyle: LearningStyle = .visual
    ) {
        self.material = material
        self.router = router
        self.store = store
        self.learningStyle = learningStyle
        self.engine = predictedEngine
    }

    var fileName: String {
        material.source == .pdf && !material.title.lowercased().hasSuffix(".pdf")
            ? "\(material.title).pdf"
            : material.title
    }

    var topics: [String] {
        focusTopics
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var focusError: String? {
        let topics = self.topics
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
        let text = material.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return "This material has no readable text yet. Re-import it and try again."
        }
        if text.count < SummaryLimits.minimumSourceCharacters {
            return "This material is too short to summarise. Add at least \(SummaryLimits.minimumSourceCharacters) characters of text."
        }
        return nil
    }

    var canGenerate: Bool {
        step == .configure && focusError == nil && materialError == nil
    }

    var isSaved: Bool {
        savedSummaryID != nil && !hasUnsavedChanges
    }

    var dailyLimit: Int { router.governor.limit }

    var remainingToday: Int { router.governor.remaining }

    var predictedEngine: SummaryEngine {
        switch router.decide(for: .summarize) {
        case .preferred(let tier), .fellBack(_, let tier, _):
            return SummaryEngine(tier: tier)
        case .noneAvailable:
            return .onDevice
        }
    }

    var showsCloudAllowance: Bool {
        predictedEngine == .cloud || isQuotaBlocked
    }

    var isQuotaBlocked: Bool {
        guard case .noneAvailable(let reasons) = router.decide(for: .summarize) else { return false }
        return reasons.values.contains(.quotaExhausted)
    }

    var onDeviceUnavailableReason: AIUnavailableReason? {
        router.tierStatus.first { $0.tier == .onDevice }?.availability.reason
    }

    var canUseOnDevice: Bool {
        onDeviceUnavailableReason == nil
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

    @discardableResult
    func generate() -> Task<Void, Never>? {
        guard canGenerate else { return nil }
        if isQuotaBlocked {
            error = nil
            step = .quotaExceeded
            return nil
        }
        return start(forceOnDevice: false)
    }

    @discardableResult
    func switchToOnDevice() -> Task<Void, Never>? {
        guard canUseOnDevice, materialError == nil else {
            error = .onDeviceAIUnavailable
            step = .configure
            return nil
        }
        return start(forceOnDevice: true)
    }

    func cancelGeneration() {
        guard step == .generating else { return }
        generationTask?.cancel()
        generationTask = nil
        generationID = UUID()
        engine = predictedEngine
        step = .configure
    }

    func backToConfigure() {
        generationTask?.cancel()
        generationTask = nil
        generationID = UUID()
        summary = nil
        savedSummaryID = nil
        hasUnsavedChanges = false
        error = nil
        engine = predictedEngine
        step = .configure
    }

    func dismissError() {
        error = nil
    }

    func save() async {
        guard let summary, !isSaved, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let id = savedSummaryID ?? UUID().uuidString
        do {
            try await store.add(summary.stored(id: id))
            savedSummaryID = id
            hasUnsavedChanges = false
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }

    func editError(title: String, tldr: String, keyPoints: [String]) -> String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Give the summary a title."
        }
        if tldr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "The TL;DR can't be empty."
        }
        if keyPoints.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return "Keep at least one key point."
        }
        return nil
    }

    func applyEdits(title: String, tldr: String, keyPoints: [String]) {
        guard var edited = summary, editError(title: title, tldr: tldr, keyPoints: keyPoints) == nil else { return }
        edited.title = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(SummaryLimits.titleMaxCharacters))
        edited.tldr = String(tldr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(SummaryLimits.tldrMaxCharacters))
        edited.keyPoints = keyPoints
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(SummaryLimits.keyPointMaxCount)
            .map { String($0.prefix(SummaryLimits.keyPointMaxCharacters)) }
        guard edited != summary else { return }
        summary = edited
        hasUnsavedChanges = true
    }

    func resetText(now: Date = .now) -> String {
        let minutes = max(Int(router.governor.resetsAt.timeIntervalSince(now) / 60), 1)
        return "\(minutes / 60) h \(minutes % 60) m"
    }

    private func start(forceOnDevice: Bool) -> Task<Void, Never> {
        generationTask?.cancel()
        let id = UUID()
        generationID = id
        error = nil
        summary = nil
        savedSummaryID = nil
        hasUnsavedChanges = false
        engine = forceOnDevice ? .onDevice : predictedEngine
        step = .generating

        let request = SummaryRequest(
            context: AIGenerationContext(
                materialId: material.id,
                text: material.text,
                language: language,
                learningStyle: learningStyle
            ),
            length: length,
            style: style,
            focusTopics: topics.joined(separator: ", ")
        )

        let task = Task { [weak self] in
            guard let self else { return }
            await self.run(request, id: id, forceOnDevice: forceOnDevice)
        }
        generationTask = task
        return task
    }

    private func run(_ request: SummaryRequest, id: UUID, forceOnDevice: Bool) async {
        let previousPolicy = router.policy
        if forceOnDevice {
            router.policy = .offlineOnly
        }

        let outcome: Result<AIGenerated<AISummary>, any Error>
        do {
            outcome = .success(try await router.summarize(request))
        } catch {
            outcome = .failure(error)
        }

        if forceOnDevice {
            router.policy = previousPolicy
        }

        guard id == generationID, step == .generating, !Task.isCancelled else { return }
        generationTask = nil

        switch outcome {
        case .success(let generated):
            summary = SummaryGrounding.summary(
                from: generated,
                material: material,
                fileName: fileName,
                length: request.length,
                style: request.style,
                language: request.context.language
            )
            engine = SummaryEngine(tier: generated.tier)
            step = .result
        case .failure(let failure):
            if !forceOnDevice, hitQuota(failure) {
                step = .quotaExceeded
            } else {
                error = AppError.from(failure)
                engine = predictedEngine
                step = .configure
            }
        }
    }

    private func hitQuota(_ failure: any Error) -> Bool {
        if let aiError = failure as? AIError, aiError == .unavailable(.quotaExhausted) {
            return true
        }
        if case .noneAvailable(let reasons) = router.lastDecision {
            return reasons.values.contains(.quotaExhausted)
        }
        return false
    }
}
