import Foundation
import Testing
@testable import StudyForge

@Suite("Summary screens (F03)")
@MainActor
struct SummaryScreensViewModelTests {

    private let paragraph = """
    A tree is a hierarchy with one root node at the top. \
    Each node holds children, enabling fast search over sorted keys. \
    A binary tree has at most two children per node, enabling logarithmic search in balanced cases. \
    Traversal visits nodes in-order, pre-order or post-order. \
    A leaf is a node with no children. \
    Height counts edges to the deepest leaf while depth counts edges from the root.
    """

    private var sampleText: String {
        PageMarker.forPage(12) + String(repeating: paragraph + " ", count: 4)
    }

    private func words(_ count: Int) -> String {
        Array(repeating: "tree", count: count).joined(separator: " ")
    }

    private func material(text: String? = nil) -> Material {
        Material(title: "Lecture 4 — Trees", source: .pdf, text: text ?? sampleText, pageCount: 20)
    }

    private func router(
        providers: [AITier: any AIProvider] = [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
        governor: AICostGovernor = AICostGovernor()
    ) -> AIRouter {
        AIRouter(providers: providers, governor: governor)
    }

    private func model(
        material: Material? = nil,
        router: AIRouter? = nil,
        store: any SummaryStore = InMemorySummaryStore(),
        cache: SummaryResponseCache = SummaryResponseCache(),
        timeout: Duration = .seconds(30)
    ) -> SummaryScreensViewModel {
        SummaryScreensViewModel(
            material: material ?? self.material(),
            router: router ?? self.router(),
            store: store,
            cache: cache,
            timeout: timeout
        )
    }

    @Test("The sample material is long enough to summarise")
    func sampleIsLongEnough() {
        #expect(SummaryLimits.wordCount(of: sampleText) >= SummaryLimits.minimumSourceWords)
    }

    @Test("Generating moves to the result with a grounded summary from the router")
    func generateProducesResult() async throws {
        let viewModel = model()

        await viewModel.generate()?.value

        #expect(viewModel.step == .result)
        let summary = try #require(viewModel.summary)
        #expect(summary.title == SummaryCopy.summaryTitle("Lecture 4 — Trees"))
        #expect(summary.tier == .firebaseAI)
        #expect(!summary.keyPoints.isEmpty)
        #expect(summary.showsAIDraftLabel)
        #expect(viewModel.engine == .cloud)
        #expect(viewModel.servedFromCache == false)
    }

    @Test("The source sheet quotes a sentence that really exists in the material")
    func sourceIsGroundedInTheMaterial() async {
        let material = self.material()
        let viewModel = model(material: material)

        await viewModel.generate()?.value

        let source = viewModel.summary?.source
        #expect(source?.page == viewModel.summary?.provenance.pageNumbers.min())
        #expect(source.map { material.text.contains($0.excerpt) } == true)
        #expect(source.map { (0...1).contains($0.relevance) } == true)
        #expect(source?.fileName == "Lecture 4 — Trees.pdf")
    }

    @Test("A cloud generation spends one of today's free generations")
    func cloudGenerationSpendsQuota() async {
        let governor = AICostGovernor()
        let viewModel = model(router: router(governor: governor))
        let before = viewModel.remainingToday

        await viewModel.generate()?.value

        #expect(viewModel.remainingToday == before - 1)
    }

    @Test("Asking again for the same summary is served from the cache without spending quota")
    func repeatRequestIsServedFromCache() async {
        let governor = AICostGovernor()
        let viewModel = model(router: router(governor: governor))

        await viewModel.generate()?.value
        let first = viewModel.summary
        let afterFirst = viewModel.remainingToday
        viewModel.backToConfigure()
        await viewModel.generate()?.value

        #expect(viewModel.step == .result)
        #expect(viewModel.servedFromCache)
        #expect(viewModel.remainingToday == afterFirst)
        #expect(viewModel.summary?.tldr == first?.tldr)
    }

    @Test("A different length is a different cache entry")
    func differentOptionsMissTheCache() async {
        let governor = AICostGovernor()
        let viewModel = model(router: router(governor: governor))

        await viewModel.generate()?.value
        let afterFirst = viewModel.remainingToday
        viewModel.backToConfigure()
        viewModel.length = .examReady
        await viewModel.generate()?.value

        #expect(viewModel.servedFromCache == false)
        #expect(viewModel.remainingToday == afterFirst - 1)
    }

    @Test("With the allowance spent, generating shows the quota screen instead of an error")
    func exhaustedQuotaShowsQuotaScreen() async {
        let governor = AICostGovernor()
        governor.seed(usedToday: governor.limit)
        let viewModel = model(router: router(governor: governor))

        await viewModel.generate()?.value

        #expect(viewModel.step == .quotaExceeded)
        #expect(viewModel.error == nil)
        #expect(viewModel.summary == nil)
    }

    @Test("A cached summary is still served when the allowance is spent")
    func cacheBeatsTheQuotaScreen() async {
        let governor = AICostGovernor()
        let viewModel = model(router: router(governor: governor))
        await viewModel.generate()?.value
        viewModel.backToConfigure()
        governor.seed(usedToday: governor.limit)

        await viewModel.generate()?.value

        #expect(viewModel.step == .result)
        #expect(viewModel.servedFromCache)
    }

    @Test("Switching to on-device generates without spending the cloud allowance")
    func switchToOnDeviceBypassesQuota() async {
        let governor = AICostGovernor()
        governor.seed(usedToday: governor.limit)
        let router = self.router(
            providers: [
                .onDevice: MockProvider(tier: .onDevice, latency: .zero),
                .firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero),
            ],
            governor: governor
        )
        router.policy = .cloudFirst
        let viewModel = model(router: router)

        await viewModel.switchToOnDevice()?.value

        #expect(viewModel.step == .result)
        #expect(viewModel.summary?.tier == .onDevice)
        #expect(viewModel.engine == .onDevice)
        #expect(governor.remaining == 0)
        #expect(router.policy == .cloudFirst)
    }

    @Test("Switching to on-device is refused honestly when there is no on-device engine")
    func switchToOnDeviceWithoutEngine() async {
        let governor = AICostGovernor()
        governor.seed(usedToday: governor.limit)
        let viewModel = model(router: router(governor: governor))

        let task = viewModel.switchToOnDevice()

        #expect(task == nil)
        #expect(viewModel.canUseOnDevice == false)
        #expect(viewModel.step == .configure)
        #expect(viewModel.error == .onDeviceAIUnavailable)
    }

    @Test("A generation that runs past the time limit is stopped with the timed-out error")
    func slowGenerationTimesOut() async {
        let viewModel = model(
            router: router(providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .seconds(5))]),
            timeout: .milliseconds(50)
        )

        await viewModel.generate()?.value

        #expect(viewModel.step == .configure)
        #expect(viewModel.error == .timedOut)
        #expect(viewModel.summary == nil)
    }

    @Test("Cancelling mid-generation returns to configure and drops the late result")
    func cancelDropsResult() async {
        let viewModel = model(router: router(providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .seconds(5))]))

        let task = viewModel.generate()
        #expect(viewModel.step == .generating)
        viewModel.cancelGeneration()
        await task?.value

        #expect(viewModel.step == .configure)
        #expect(viewModel.summary == nil)
        #expect(viewModel.error == nil)
    }

    @Test("A material under 200 words cannot be summarised, and 200 words can")
    func shortMaterialIsRefused() {
        let short = model(material: material(text: words(199)))
        let enough = model(material: material(text: words(200)))

        #expect(short.materialError == SummaryCopy.materialShort(minimum: 200, actual: 199))
        #expect(short.canGenerate == false)
        #expect(short.generate() == nil)
        #expect(short.step == .configure)
        #expect(enough.materialError == nil)
        #expect(enough.canGenerate)
    }

    @Test("Words are counted across spaces and line breaks")
    func wordCounting() {
        #expect(SummaryLimits.wordCount(of: "one two\nthree\t four  ") == 4)
        #expect(SummaryLimits.wordCount(of: "   ") == 0)
        #expect(SummaryLimits.wordCount(of: "الشجرة لها جذر واحد") == 4)
    }

    @Test("Invalid focus topics block generation", arguments: [
        "a, b, c, d, e, f",
        "trees, Trees",
        "!!!",
    ])
    func invalidFocusTopicsBlockGeneration(_ topics: String) {
        let viewModel = model()
        viewModel.focusTopics = topics

        #expect(viewModel.focusError != nil)
        #expect(viewModel.canGenerate == false)
    }

    @Test("Saving writes the summary to the store, and saving again after an edit updates it")
    func saveAndResave() async throws {
        let store = InMemorySummaryStore()
        let viewModel = model(store: store)
        await viewModel.generate()?.value

        await viewModel.save()

        #expect(viewModel.isSaved)
        var saved = try await store.all()
        #expect(saved.count == 1)
        #expect(saved.first?.materialId == viewModel.material.id)

        viewModel.applyEdits(title: "My trees notes", tldr: "Edited takeaway.", keyPoints: ["One", "Two"])
        #expect(viewModel.isSaved == false)
        #expect(viewModel.hasUnsavedChanges)

        await viewModel.save()

        saved = try await store.all()
        #expect(saved.count == 1)
        #expect(saved.first?.title == "My trees notes")
        #expect(saved.first?.tldr == "Edited takeaway.")
        #expect(saved.first?.keyPoints == ["One", "Two"])
        #expect(viewModel.isSaved)
    }

    @Test("Turning off the AI-drafted label is an edit, and the shared text follows it")
    func watermarkToggleIsAnEdit() async throws {
        let viewModel = model()
        await viewModel.generate()?.value
        let original = try #require(viewModel.summary)
        #expect(original.shareText.contains(SummaryCopy.shareWatermark))

        viewModel.applyEdits(
            title: original.title,
            tldr: original.tldr,
            keyPoints: original.keyPoints,
            showsAIDraftLabel: false
        )

        let edited = try #require(viewModel.summary)
        #expect(edited.showsAIDraftLabel == false)
        #expect(edited.shareText.contains(SummaryCopy.shareWatermark) == false)
        #expect(edited.provenance == original.provenance)
        #expect(viewModel.hasUnsavedChanges)
    }

    @Test("A storage failure surfaces an error and leaves the summary unsaved")
    func saveFailureSurfacesError() async {
        let store = InMemorySummaryStore()
        await store.forceFailure(.storageFailed)
        let viewModel = model(store: store)
        await viewModel.generate()?.value

        await viewModel.save()

        #expect(viewModel.isSaved == false)
        #expect(viewModel.error != nil)
    }

    @Test("Edits are validated before they are applied")
    func editValidation() async {
        let viewModel = model()
        await viewModel.generate()?.value
        let original = viewModel.summary

        #expect(viewModel.editError(title: " ", tldr: "x", keyPoints: ["y"]) != nil)
        #expect(viewModel.editError(title: "x", tldr: " ", keyPoints: ["y"]) != nil)
        #expect(viewModel.editError(title: "x", tldr: "y", keyPoints: ["", " "]) != nil)

        viewModel.applyEdits(title: "x", tldr: "", keyPoints: ["y"])

        #expect(viewModel.summary == original)
        #expect(viewModel.hasUnsavedChanges == false)
    }

    @Test("Going back clears the result so a fresh generation starts clean")
    func backToConfigureClears() async {
        let viewModel = model()
        await viewModel.generate()?.value
        await viewModel.save()

        viewModel.backToConfigure()

        #expect(viewModel.step == .configure)
        #expect(viewModel.summary == nil)
        #expect(viewModel.isSaved == false)
    }

    @Test("Glossary confidence is higher for terms that appear in the material")
    func glossaryConfidenceReflectsGrounding() {
        let material = self.material()
        let value = AISummary(
            tldr: "Trees",
            keyPoints: ["A leaf is a node with no children"],
            glossary: [
                AIGlossaryTerm(term: "Leaf", definition: "A node with no children."),
                AIGlossaryTerm(term: "Quantum flux", definition: "Unrelated invented concept."),
            ]
        )

        let glossary = SummaryGrounding.glossary(for: value, material: material)

        #expect(glossary.count == 2)
        #expect(glossary[0].isHighConfidence)
        #expect(glossary[1].confidence < 0.5)
    }
}
