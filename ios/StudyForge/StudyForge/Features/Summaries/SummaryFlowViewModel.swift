//
//  SummaryFlowViewModel.swift
//  StudyForge
//
//  Presentation logic for F03 — D01's configure, D02's generating, D03's result and D07's error
//  in one stateful sheet rather than four screens.
//
//  WHY ONE SHEET
//  -------------
//  The design splits these so each can carry its own progress and error state (docs/03 §D). With
//  generation that completes in under a second against the mock and sub-second on a device, four
//  screens would be four dismissals for one action. The states the design cares about — working,
//  failed, result — are all present; they are drawn in place, exactly as the import path does.
//
//  WHY THE ROUTER, NOT A PROVIDER
//  ------------------------------
//  A feature must never hard-code an engine. The router decides, and — crucially — falls back
//  when the preferred tier is unavailable, which is the difference between "no on-device model
//  in the Simulator, so nothing works" and "the mock stands in and the screen stays developable".
//

import Foundation

@MainActor
@Observable
final class SummaryFlowViewModel {

    /// Which state the sheet is drawing.
    enum Phase: Equatable {
        case configuring
        case generating
        case result
        case saved
    }

    // MARK: Bound configuration

    /// Optional because `SFSegmentedField` models "nothing chosen yet" as `nil`. Defaulted to a
    /// sensible value so the Generate button is usable immediately, while the control still gets
    /// the correct optional binding type it was designed around.
    var length: SummaryLength? = .standard
    var style: SummaryStyle? = .bullets
    var language: OutputLanguage? = .english

    /// D01's focus-topics field. Empty means "cover the material evenly".
    var focusTopics = ""

    // MARK: Derived state

    private(set) var isGenerating = false
    private(set) var isSaving = false
    private(set) var error: AppError?

    /// The generated result, once it exists. Carries the value AND the provenance/tier the result
    /// screen cites.
    private(set) var result: AIGenerated<AISummary>?

    /// Set once the summary has been saved, so the sheet can show the confirmation state.
    private(set) var savedSummary: Summary?

    let material: Material

    private let router: AIRouter
    private let store: any SummaryStore
    private let learningStyle: LearningStyle

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
    }

    // MARK: Phase

    var phase: Phase {
        if isGenerating { return .generating }
        if savedSummary != nil { return .saved }
        if result != nil { return .result }
        return .configuring
    }

    // MARK: Copy

    var title: String { L10n.summaryTitle.string }
    var lengthLabel: String { L10n.summaryLengthLabel.string }
    var styleLabel: String { L10n.summaryStyleLabel.string }
    var languageLabel: String { L10n.summaryLanguageLabel.string }
    var focusLabel: String { L10n.summaryFocusLabel.string }
    var focusPlaceholder: String { L10n.summaryFocusPlaceholder.string }
    var generateTitle: String { L10n.summaryGenerate.string }
    var generatingTitle: String { L10n.summaryGeneratingTitle.string }
    var generatingBody: String { L10n.summaryGeneratingBody.string }
    var tldrHeading: String { L10n.summaryTldrHeading.string }
    var keyPointsHeading: String { L10n.summaryKeyPointsHeading.string }
    var glossaryHeading: String { L10n.summaryGlossaryHeading.string }
    var saveTitle: String { L10n.summarySave.string }
    var savingTitle: String { L10n.summarySaving.string }
    var savedTitle: String { L10n.summarySavedTitle.string }
    var savedBody: String { L10n.summarySavedBody.string }
    var sourceTitle: String { L10n.summarySource.string }

    var isGenerateEnabled: Bool { !isGenerating }

    func lengthTitle(_ length: SummaryLength) -> String {
        switch length {
        case .short: L10n.summaryLengthShort.string
        case .standard: L10n.summaryLengthStandard.string
        case .examReady: L10n.summaryLengthExamReady.string
        }
    }

    func styleTitle(_ style: SummaryStyle) -> String {
        switch style {
        case .bullets: L10n.summaryStyleBullets.string
        case .narrative: L10n.summaryStyleNarrative.string
        case .cornell: L10n.summaryStyleCornell.string
        }
    }

    func languageTitle(_ language: OutputLanguage) -> String {
        switch language {
        case .english: L10n.summaryLanguageEnglish.string
        case .arabic: L10n.summaryLanguageArabic.string
        }
    }

    // MARK: Result accessors

    var tldr: String { result?.value.tldr ?? "" }

    var keyPoints: [String] { result?.value.keyPoints ?? [] }

    var glossary: [SummaryTerm] {
        (result?.value.glossary ?? []).map { SummaryTerm(term: $0.term, definition: $0.definition) }
    }

    var hasGlossary: Bool { !glossary.isEmpty }

    /// The privacy badge the result screen shows — localised, because the tier is user-facing copy.
    var engineBadge: String? {
        guard let tier = result?.tier else { return nil }
        switch tier {
        case .onDevice: return L10n.summaryEngineOnDevice.string
        case .firebaseAI: return L10n.summaryEngineFirebaseAI.string
        case .cloudFunction: return L10n.summaryEngineCloudFunction.string
        }
    }

    var confidenceLabel: String? {
        guard let confidence = result?.provenance.confidence else { return nil }
        switch confidence {
        case .high: return L10n.summaryConfidenceHigh.string
        case .medium: return L10n.summaryConfidenceMedium.string
        case .low: return L10n.summaryConfidenceLow.string
        }
    }

    /// The citation chip text. Falls back to a localised "Source" when there is no page number,
    /// rather than letting the AI layer's English fallback reach the screen.
    var citationLabel: String? {
        guard let provenance = result?.provenance else { return nil }
        return provenance.pageNumbers.isEmpty ? L10n.summarySource.string : provenance.citationLabel
    }

    // MARK: Actions

    func generate() async {
        guard !isGenerating, let length, let style, let language else { return }
        resetForNewGeneration()
        isGenerating = true
        defer { isGenerating = false }

        let context = AIGenerationContext(
            materialId: material.id,
            text: material.text,
            language: language,
            learningStyle: learningStyle
        )

        do {
            result = try await router.summarize(
                SummaryRequest(context: context, length: length, style: style, focusTopics: focusTopics)
            )
        } catch {
            self.error = AppError.from(error)
        }
    }

    func save() async {
        guard let result, savedSummary == nil, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let summary = Summary(
            title: material.title,
            length: length ?? .standard,
            style: style ?? .bullets,
            language: language ?? .english,
            tldr: result.value.tldr,
            keyPoints: result.value.keyPoints,
            glossary: result.value.glossary.map { SummaryTerm(term: $0.term, definition: $0.definition) },
            provenance: result.provenance,
            tier: result.tier
        )

        do {
            try await store.add(summary)
            savedSummary = summary
        } catch {
            self.error = AppError.from(error)
        }
    }

    // MARK: Helpers

    private func resetForNewGeneration() {
        error = nil
        result = nil
        savedSummary = nil
    }
}
