import Foundation
import Testing
@testable import StudyForge

@Suite("Summary screens (F03)")
@MainActor
struct SummaryScreensViewModelTests {

    private let sampleText = PageMarker.forPage(12) + """
    A tree is a hierarchy with one root node at the top. \
    Each node holds children, enabling fast search over sorted keys. \
    A binary tree has at most two children per node, enabling logarithmic search in balanced cases. \
    Traversal visits nodes in-order, pre-order or post-order. \
    A leaf is a node with no children. \
    Height counts edges to the deepest leaf while depth counts edges from the root.
    """

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
        store: any SummaryStore = InMemorySummaryStore()
    ) -> SummaryScreensViewModel {
        SummaryScreensViewModel(
            material: material ?? self.material(),
            router: router ?? self.router(),
            store: store
        )
    }

    @Test("Generating moves to the result with a grounded summary from the router")
    func generateProducesResult() async throws {
        let viewModel = model()

        await viewModel.generate()?.value

        #expect(viewModel.step == .result)
        let summary = try #require(viewModel.summary)
        #expect(summary.title == "Lecture 4 — Trees — Summary")
        #expect(summary.tier == .firebaseAI)
        #expect(!summary.keyPoints.isEmpty)
        #expect(viewModel.engine == .cloud)
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

    @Test("With the allowance spent, generating shows the quota screen instead of an error")
    func exhaustedQuotaShowsQuotaScreen() async {
        let governor = AICostGovernor()
        governor.seed(usedToday: governor.limit)
        let viewModel = model(router: router(governor: governor))

        let task = viewModel.generate()
        await task?.value

        #expect(task == nil)
        #expect(viewModel.step == .quotaExceeded)
        #expect(viewModel.error == nil)
        #expect(viewModel.summary == nil)
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

    @Test("Cancelling mid-generation returns to configure and drops the late result")
    func cancelDropsResult() async {
        let viewModel = model(router: router(providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .seconds(5))]))

        let task = viewModel.generate()
        #expect(viewModel.step == .generating)
        viewModel.cancelGeneration()
        await task?.value

        #expect(viewModel.step == .configure)
        #expect(viewModel.summary == nil)
    }

    @Test("A material under the minimum length cannot be summarised")
    func shortMaterialIsRefused() async {
        let viewModel = model(material: material(text: "Too short to summarise."))

        #expect(viewModel.materialError != nil)
        #expect(viewModel.canGenerate == false)
        #expect(viewModel.generate() == nil)
        #expect(viewModel.step == .configure)
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
