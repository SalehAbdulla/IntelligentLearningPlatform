import Foundation

struct SummaryTimeoutError: Error, Equatable {}

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
    private(set) var servedFromCache = false
    private(set) var error: AppError?

    let material: Material

    private let router: AIRouter
    private let store: any SummaryStore
    private let learningStyle: LearningStyle
    private let cache: SummaryResponseCache
    private let timeout: Duration

    @ObservationIgnored private var generationTask: Task<Void, Never>?
    @ObservationIgnored private var generationID = UUID()

    init(
        material: Material,
        router: AIRouter,
        store: any SummaryStore,
        learningStyle: LearningStyle = .visual,
        cache: SummaryResponseCache = .shared,
        timeout: Duration = SummaryLimits.generationTimeout
    ) {
        self.material = material
        self.router = router
        self.store = store
        self.learningStyle = learningStyle
        self.cache = cache
        self.timeout = timeout
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
            return SummaryCopy.focusTooMany(SummaryLimits.focusMaxTopics)
        }
        if topics.contains(where: { $0.count > SummaryLimits.focusMaxTopicCharacters }) {
            return SummaryCopy.focusTooLong(SummaryLimits.focusMaxTopicCharacters)
        }
        if topics.contains(where: { $0.rangeOfCharacter(from: .alphanumerics) == nil }) {
            return SummaryCopy.focusSymbols
        }
        if Set(topics.map { $0.lowercased() }).count != topics.count {
            return SummaryCopy.focusRepeated
        }
        return nil
    }

    var materialWordCount: Int {
        SummaryLimits.wordCount(of: material.text)
    }

    var materialError: String? {
        if material.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return SummaryCopy.materialEmpty
        }
        let words = materialWordCount
        if words < SummaryLimits.minimumSourceWords {
            return SummaryCopy.materialShort(minimum: SummaryLimits.minimumSourceWords, actual: words)
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
        servedFromCache = false
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
            return SummaryCopy.editTitleError
        }
        if tldr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return SummaryCopy.editTldrError
        }
        if keyPoints.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return SummaryCopy.editPointsError
        }
        return nil
    }

    func applyEdits(title: String, tldr: String, keyPoints: [String], showsAIDraftLabel: Bool? = nil) {
        guard var edited = summary, editError(title: title, tldr: tldr, keyPoints: keyPoints) == nil else { return }
        edited.title = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(SummaryLimits.titleMaxCharacters))
        edited.tldr = String(tldr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(SummaryLimits.tldrMaxCharacters))
        edited.keyPoints = keyPoints
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(SummaryLimits.keyPointMaxCount)
            .map { String($0.prefix(SummaryLimits.keyPointMaxCharacters)) }
        if let showsAIDraftLabel {
            edited.showsAIDraftLabel = showsAIDraftLabel
        }
        guard edited != summary else { return }
        summary = edited
        hasUnsavedChanges = true
    }

    func resetText(now: Date = .now) -> String {
        let minutes = max(Int(router.governor.resetsAt.timeIntervalSince(now) / 60), 1)
        return SummaryCopy.reset(hours: minutes / 60, minutes: minutes % 60)
    }

    private func start(forceOnDevice: Bool) -> Task<Void, Never> {
        generationTask?.cancel()
        let id = UUID()
        generationID = id
        error = nil
        summary = nil
        savedSummaryID = nil
        hasUnsavedChanges = false
        servedFromCache = false
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
        let key = SummaryResponseCache.key(for: request)
        if let cached = await cache.value(for: key) {
            guard id == generationID, step == .generating, !Task.isCancelled else { return }
            finish(with: cached, request: request, fromCache: true)
            return
        }

        guard id == generationID, step == .generating, !Task.isCancelled else { return }
        if !forceOnDevice, isQuotaBlocked {
            generationTask = nil
            engine = predictedEngine
            step = .quotaExceeded
            return
        }

        let previousPolicy = router.policy
        if forceOnDevice {
            router.policy = .offlineOnly
        }

        let outcome: Result<AIGenerated<AISummary>, any Error>
        do {
            outcome = .success(try await summarizeWithTimeout(request))
        } catch {
            outcome = .failure(error)
        }

        if forceOnDevice {
            router.policy = previousPolicy
        }

        guard id == generationID, step == .generating, !Task.isCancelled else { return }

        switch outcome {
        case .success(let generated):
            await cache.store(generated, for: key)
            guard id == generationID, step == .generating else { return }
            finish(with: generated, request: request, fromCache: false)
        case .failure(let failure):
            generationTask = nil
            if !forceOnDevice, hitQuota(failure) {
                step = .quotaExceeded
            } else {
                error = failure is SummaryTimeoutError ? .timedOut : AppError.from(failure)
                engine = predictedEngine
                step = .configure
            }
        }
    }

    private func finish(with generated: AIGenerated<AISummary>, request: SummaryRequest, fromCache: Bool) {
        generationTask = nil
        summary = SummaryGrounding.summary(
            from: generated,
            material: material,
            fileName: fileName,
            length: request.length,
            style: request.style,
            language: request.context.language
        )
        servedFromCache = fromCache
        engine = SummaryEngine(tier: generated.tier)
        step = .result
    }

    private func summarizeWithTimeout(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        let router = self.router
        let timeout = self.timeout
        return try await withThrowingTaskGroup(of: AIGenerated<AISummary>.self) { group in
            group.addTask {
                try await router.summarize(request)
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw SummaryTimeoutError()
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw SummaryTimeoutError()
            }
            return first
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
