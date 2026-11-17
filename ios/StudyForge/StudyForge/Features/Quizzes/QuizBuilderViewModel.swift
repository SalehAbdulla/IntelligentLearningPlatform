import Foundation

@MainActor
@Observable
final class QuizBuilderViewModel {

    enum Phase: Equatable {
        case choosingSource
        case configuring
        case generating
        case ready
    }

    static let countRange = 5...30
    static let countStep = 5
    static let defaultCount = 10
    static let timerOptions = [5, 10, 15, 20, 30]
    static let defaultTimerMinutes = 15
    static let focusMaxCharacters = 120
    static let focusTopicLimit = 5
    static let minimumSourceCharacters = 200

    private(set) var materials: [Material] = []
    private(set) var hasLoadedMaterials = false
    private(set) var selectedMaterial: Material?
    let startedWithMaterial: Bool

    var questionType: QuizQuestionType = .mixed
    private(set) var count = QuizBuilderViewModel.defaultCount
    var difficulty: QuizDifficulty = .medium
    var timerEnabled = true
    var timerMinutes = QuizBuilderViewModel.defaultTimerMinutes
    var focusText = ""

    private(set) var isGenerating = false
    private(set) var error: AppError? = nil
    private(set) var generationMessage: String? = nil
    private(set) var quiz: Quiz? = nil
    private(set) var droppedCount = 0

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
        self.selectedMaterial = initialMaterial
        self.startedWithMaterial = initialMaterial != nil
        self.materialStore = materialStore
        self.quizStore = quizStore
        self.router = router
        self.learningStyle = learningStyle
    }

    var phase: Phase {
        if quiz != nil { return .ready }
        if isGenerating { return .generating }
        if selectedMaterial != nil { return .configuring }
        return .choosingSource
    }

    var focusTopics: [String] {
        var seen = Set<String>()
        return focusText
            .components(separatedBy: CharacterSet(charactersIn: ",\n;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .prefix(Self.focusTopicLimit)
            .map { $0 }
    }

    var isSourceTooShort: Bool {
        guard let selectedMaterial else { return false }
        return selectedMaterial.text.trimmingCharacters(in: .whitespacesAndNewlines).count < Self.minimumSourceCharacters
    }

    var canGenerate: Bool {
        selectedMaterial != nil && !isSourceTooShort && !isGenerating
    }

    var lowConfidenceCount: Int {
        quiz?.questions.filter { $0.provenance.confidence == .low }.count ?? 0
    }

    var settingsSummary: String {
        QuizCopy.settingsSummary(QuizCopy.typeTitle(questionType), QuizCopy.difficultyTitle(difficulty))
    }

    var generateTitle: String { QuizCopy.generateQuiz }

    func loadMaterials() async {
        guard !hasLoadedMaterials else { return }
        do {
            materials = try await materialStore.all()
        } catch {
            self.error = AppError.from(error)
        }
        hasLoadedMaterials = true
    }

    func choose(_ material: Material) {
        selectedMaterial = material
        generationMessage = nil
        error = nil
    }

    func changeMaterial() {
        guard !startedWithMaterial, !isGenerating else { return }
        selectedMaterial = nil
        generationMessage = nil
    }

    func setCount(_ value: Int) {
        count = min(max(value, Self.countRange.lowerBound), Self.countRange.upperBound)
    }

    func limitFocus() {
        if focusText.count > Self.focusMaxCharacters {
            focusText = String(focusText.prefix(Self.focusMaxCharacters))
        }
    }

    func generate() async {
        guard canGenerate, let material = selectedMaterial else { return }
        error = nil
        generationMessage = nil
        droppedCount = 0
        isGenerating = true
        defer { isGenerating = false }

        let request = QuizRequest(
            context: AIGenerationContext(
                materialId: material.id,
                text: material.text,
                language: .english,
                learningStyle: learningStyle
            ),
            questionCount: count,
            questionType: questionType,
            difficulty: difficulty,
            focusTopics: focusTopics
        )

        do {
            let generated = try await router.makeQuiz(request)
            try Task.checkCancellation()
            let questions = QuizQuestionShaper.shaped(generated.value, type: questionType, provenance: generated.provenance)
            droppedCount = max(0, generated.value.count - questions.count)
            guard !questions.isEmpty else {
                generationMessage = QuizCopy.noQuestions
                return
            }
            let existing = (try? await quizStore.all())?.filter { $0.materialId == material.id }.count ?? 0
            let quiz = Quiz(
                title: QuizCopy.quizTitle(material.title, existing + 1),
                materialId: material.id,
                questionType: questionType,
                questions: questions,
                timerMinutes: timerEnabled ? timerMinutes : nil
            )
            try Task.checkCancellation()
            try await quizStore.add(quiz)
            self.quiz = quiz
        } catch is CancellationError {
            return
        } catch {
            self.error = AppError.from(error)
        }
    }

    func startOver() {
        quiz = nil
        droppedCount = 0
    }
}
