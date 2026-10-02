//
//  QuizGenerateViewModel.swift
//  StudyForge
//
//  Presentation logic for F05's generation path — F02's config, F03's generating, and the
//  "review your questions" step in one stateful sheet, mirroring the flashcard flow.
//
//  WHY THE SOURCE IS OPTIONAL
//  --------------------------
//  The quizzes list's "new quiz" button opens with nothing chosen (a material picker first), while
//  a future "make quiz" library shortcut would open with a material already chosen.
//

import Foundation

@MainActor
@Observable
final class QuizGenerateViewModel {

    enum Phase: Equatable {
        case choosingSource
        case configuring
        case generating
        case review
        case saved
    }

    private(set) var materials: [Material] = []
    private(set) var selectedMaterial: Material?

    /// Optional because `SFSegmentedField` models "nothing chosen yet" as `nil`.
    var questionType: QuizQuestionType? = .mixed
    var count: Int? = 10

    /// The quiz name the student can edit before saving. Empty means "use the material's title".
    var quizTitle = ""

    private(set) var isGenerating = false
    private(set) var isSaving = false
    private(set) var error: AppError?
    private(set) var questions: [QuizQuestion] = []
    private(set) var savedQuiz: Quiz?

    private let materialStore: any MaterialStore
    private let quizStore: any QuizStore
    private let router: AIRouter
    private let learningStyle: LearningStyle

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        quizStore: any QuizStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        self.materialStore = materialStore
        self.quizStore = quizStore
        self.router = router
        self.learningStyle = learningStyle
        self.selectedMaterial = initialMaterial
    }

    // MARK: Phase

    var phase: Phase {
        if savedQuiz != nil { return .saved }
        if !questions.isEmpty { return .review }
        if isGenerating { return .generating }
        if selectedMaterial != nil { return .configuring }
        return .choosingSource
    }

    // MARK: Copy

    var title: String { L10n.quizGenerateTitle.string }
    var sourceLabel: String { L10n.quizSourceLabel.string }
    var sourcePrompt: String { L10n.quizSourcePrompt.string }
    var typeLabel: String { L10n.quizTypeLabel.string }
    var countLabel: String { L10n.quizCountLabel.string }
    var generateTitle: String { L10n.quizGenerate.string }
    var generatingTitle: String { L10n.quizGeneratingTitle.string }
    var generatingBody: String { L10n.quizGeneratingBody.string }
    var reviewHeading: String { L10n.quizReviewHeading.string }
    var nameLabel: String { L10n.quizNameLabel.string }
    var namePlaceholder: String { selectedMaterial?.title ?? "" }
    var saveTitle: String { L10n.quizSave.string }
    var savingTitle: String { L10n.quizSaving.string }
    var savedTitle: String { L10n.quizSavedTitle.string }
    var savedBody: String { L10n.quizSavedBody.string }

    func typeTitle(_ type: QuizQuestionType) -> String {
        switch type {
        case .multipleChoice: L10n.quizTypeMultipleChoice.string
        case .trueFalse: L10n.quizTypeTrueFalse.string
        case .shortAnswer: L10n.quizTypeShortAnswer.string
        case .mixed: L10n.quizTypeMixed.string
        }
    }

    // MARK: Actions

    func loadMaterials() async {
        guard materials.isEmpty else { return }
        do {
            materials = try await materialStore.all()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func choose(_ material: Material) {
        selectedMaterial = material
        quizTitle = ""
    }

    func generate() async {
        guard !isGenerating, let material = selectedMaterial, let count, let questionType else { return }
        error = nil
        questions = []
        isGenerating = true
        defer { isGenerating = false }

        let context = AIGenerationContext(
            materialId: material.id,
            text: material.text,
            language: .english,
            learningStyle: learningStyle
        )

        do {
            let generated = try await router.makeQuiz(
                QuizRequest(context: context, questionCount: count, questionType: questionType)
            )
            questions = generated.value.map {
                QuizQuestion(
                    stem: $0.stem,
                    options: $0.options,
                    correctOptionIndex: $0.correctOptionIndex,
                    explanation: $0.explanation,
                    topic: $0.topic,
                    provenance: generated.provenance
                )
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func saveQuiz() async {
        guard !questions.isEmpty, savedQuiz == nil, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let name = quizTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let quiz = Quiz(
            title: name.isEmpty ? (selectedMaterial?.title ?? title) : name,
            materialId: selectedMaterial?.id,
            questionType: questionType ?? .mixed,
            questions: questions
        )

        do {
            try await quizStore.add(quiz)
            savedQuiz = quiz
        } catch {
            self.error = AppError.from(error)
        }
    }
}
