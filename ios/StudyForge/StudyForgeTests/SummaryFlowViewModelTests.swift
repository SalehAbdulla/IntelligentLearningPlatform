//
//  SummaryFlowViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F03's generation and save flow.
//
//  The two that matter are `shortSourceIsRefused` — a material under 200 words must fail with a
//  reason the student can act on, not a generic apology — and `quotaExceededSurfacesTheQuotaError`,
//  because D07's whole promise is "never a raw error".
//

import Foundation
import Testing
@testable import StudyForge

/// A provider that claims to be available but always fails with an exhausted quota — the
/// "cloud allowance spent" case the router must turn into a specific, actionable error.
private struct QuotaExhaustedProvider: AIProvider {
    let tier: AITier = .onDevice
    var availability: AIAvailability { .available }

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        throw AIError.unavailable(.quotaExhausted)
    }
    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        throw AIError.unavailable(.quotaExhausted)
    }
    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        throw AIError.unavailable(.quotaExhausted)
    }
    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        throw AIError.unavailable(.quotaExhausted)
    }
}

@Suite("Summary flow (F03)")
@MainActor
struct SummaryFlowViewModelTests {

    private let sampleText = """
    Third normal form (3NF) is a database normalisation level used in relational design. \
    A relation is in 3NF when it is already in second normal form and has no transitive dependencies. \
    Reaching 3NF reduces data redundancy and prevents update anomalies at the cost of additional joins. \
    First normal form requires atomic values so each column holds a single value. \
    Second normal form removes partial dependencies on part of a composite key.
    """

    private func material(text: String? = nil) -> Material {
        Material(title: "Lecture 4 — Normalisation", source: .text, text: text ?? sampleText)
    }

    private func model(
        material: Material,
        store: any SummaryStore = InMemorySummaryStore()
    ) -> SummaryFlowViewModel {
        SummaryFlowViewModel(
            material: material,
            router: AIRouter(
                providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
                governor: AICostGovernor()
            ),
            store: store
        )
    }

    // MARK: Generation

    @Test("Generating produces a result with a citation and an engine badge")
    func generateSucceeds() async {
        let viewModel = model(material: material())

        await viewModel.generate()

        #expect(viewModel.result != nil)
        #expect(viewModel.phase == .result)
        #expect(!viewModel.tldr.isEmpty)
        #expect(!viewModel.keyPoints.isEmpty)
        #expect(viewModel.engineBadge == L10n.summaryEngineFirebaseAI.string)
        #expect(viewModel.citationLabel == "p.1", "the mock cites page 1")
    }

    @Test("A material with too little text is refused with a clear reason")
    func shortSourceIsRefused() async {
        let viewModel = model(material: material(text: "Too short."))

        await viewModel.generate()

        #expect(viewModel.result == nil)
        #expect(viewModel.phase == .configuring)
        #expect(
            viewModel.error == AppError.materialUnreadable(
                reason: "There wasn't enough text in that material to work with."
            )
        )
    }

    @Test("An exhausted quota surfaces the quota error, never a raw failure")
    func quotaExceededSurfacesTheQuotaError() async {
        let viewModel = SummaryFlowViewModel(
            material: material(),
            router: AIRouter(providers: [.onDevice: QuotaExhaustedProvider()], governor: AICostGovernor()),
            store: InMemorySummaryStore()
        )

        await viewModel.generate()

        guard case .aiQuotaExceeded = viewModel.error else {
            Issue.record("expected .aiQuotaExceeded, got \(String(describing: viewModel.error))")
            return
        }
    }

    // MARK: Saving

    @Test("Saving persists the generated summary against its source material")
    func savePersists() async throws {
        let store = InMemorySummaryStore()
        let viewModel = model(material: material(), store: store)

        await viewModel.generate()
        await viewModel.save()

        #expect(viewModel.savedSummary != nil)
        #expect(viewModel.phase == .saved)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.tldr == viewModel.tldr)
        #expect(all.first?.materialId == viewModel.material.id)
    }

    @Test("Saving before generating is a no-op")
    func saveWithoutResultIsNoOp() async throws {
        let store = InMemorySummaryStore()
        let viewModel = model(material: material(), store: store)

        await viewModel.save()

        #expect(viewModel.savedSummary == nil)
        #expect(try await store.all().isEmpty)
    }

    @Test("A store that refuses the write is reported rather than swallowed")
    func storeFailureIsReported() async {
        let store = InMemorySummaryStore()
        let viewModel = model(material: material(), store: store)

        await viewModel.generate()
        await store.forceFailure(.storageFailed)
        await viewModel.save()

        #expect(viewModel.error == AppError.server(reference: "summary-store-failed"))
        #expect(viewModel.savedSummary == nil)
    }

    // MARK: Copy

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model(material: material())

        #expect(viewModel.title == L10n.summaryTitle.string)
        #expect(viewModel.lengthLabel == L10n.summaryLengthLabel.string)
        #expect(viewModel.styleLabel == L10n.summaryStyleLabel.string)
        #expect(viewModel.languageLabel == L10n.summaryLanguageLabel.string)
        #expect(viewModel.generateTitle == L10n.summaryGenerate.string)
        #expect(viewModel.generatingTitle == L10n.summaryGeneratingTitle.string)
        #expect(viewModel.tldrHeading == L10n.summaryTldrHeading.string)
        #expect(viewModel.keyPointsHeading == L10n.summaryKeyPointsHeading.string)
        #expect(viewModel.glossaryHeading == L10n.summaryGlossaryHeading.string)
        #expect(viewModel.saveTitle == L10n.summarySave.string)
        #expect(viewModel.savedTitle == L10n.summarySavedTitle.string)

        #expect(viewModel.lengthTitle(.short) == L10n.summaryLengthShort.string)
        #expect(viewModel.styleTitle(.narrative) == L10n.summaryStyleNarrative.string)
        #expect(viewModel.languageTitle(.arabic) == L10n.summaryLanguageArabic.string)
    }
}
