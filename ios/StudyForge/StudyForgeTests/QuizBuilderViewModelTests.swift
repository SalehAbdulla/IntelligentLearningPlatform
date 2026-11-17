import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz builder (F05)")
@MainActor
struct QuizBuilderViewModelTests {

    private let sampleText = """
    A binary search tree keeps smaller keys on the left and larger keys on the right. \
    In-order traversal of a binary search tree visits the keys in sorted order. \
    An AVL tree stays balanced by rotating nodes after inserts and deletes. \
    The height of a tree is the number of edges on the longest path from the root to a leaf. \
    A leaf is a node with no children, and the root is the only node without a parent.
    """

    private func material(text: String? = nil, title: String = "Lecture 4") -> Material {
        Material(title: title, source: .text, text: text ?? sampleText)
    }

    private func model(
        material: Material?,
        quizStore: any QuizStore = InMemoryQuizStore(),
        materials: [Material]? = nil
    ) -> QuizBuilderViewModel {
        QuizBuilderViewModel(
            initialMaterial: material,
            materialStore: InMemoryMaterialStore(seededWith: materials ?? [material].compactMap { $0 }),
            quizStore: quizStore,
            router: AIRouter(
                providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
                governor: AICostGovernor()
            )
        )
    }

    @Test("The config step starts on the Figma defaults")
    func defaults() {
        let viewModel = model(material: material())

        #expect(viewModel.phase == .configuring)
        #expect(viewModel.questionType == .mixed)
        #expect(viewModel.count == QuizBuilderViewModel.defaultCount)
        #expect(viewModel.difficulty == .medium)
        #expect(viewModel.timerEnabled)
        #expect(viewModel.timerMinutes == 15)
        #expect(viewModel.canGenerate)
    }

    @Test("Without a material the builder asks for one first")
    func choosesSource() async {
        let source = material()
        let viewModel = model(material: nil, materials: [source])

        #expect(viewModel.phase == .choosingSource)
        await viewModel.loadMaterials()
        #expect(viewModel.materials.map(\.id) == [source.id])

        viewModel.choose(source)
        #expect(viewModel.phase == .configuring)

        viewModel.changeMaterial()
        #expect(viewModel.phase == .choosingSource)
    }

    @Test("The question count stays inside its range")
    func countClamped() {
        let viewModel = model(material: material())

        viewModel.setCount(100)
        #expect(viewModel.count == QuizBuilderViewModel.countRange.upperBound)
        viewModel.setCount(1)
        #expect(viewModel.count == QuizBuilderViewModel.countRange.lowerBound)
    }

    @Test("Focus topics are split, trimmed, de-duplicated and capped")
    func focusTopics() {
        let viewModel = model(material: material())
        viewModel.focusText = " AVL trees, traversal,avl TREES ; heaps\nheight, leaves, roots"

        #expect(viewModel.focusTopics == ["AVL trees", "traversal", "heaps", "height", "leaves"])

        viewModel.focusText = String(repeating: "x", count: 300)
        viewModel.limitFocus()
        #expect(viewModel.focusText.count == QuizBuilderViewModel.focusMaxCharacters)
    }

    @Test("Too little source text blocks generation")
    func shortSourceBlocked() async {
        let viewModel = model(material: material(text: "Too short."))

        #expect(viewModel.isSourceTooShort)
        #expect(!viewModel.canGenerate)
        await viewModel.generate()
        #expect(viewModel.quiz == nil)
    }

    @Test("Generating saves a timed quiz with the chosen settings")
    func generateSaves() async throws {
        let store = InMemoryQuizStore()
        let source = material()
        let viewModel = model(material: source, quizStore: store)
        viewModel.questionType = .multipleChoice
        viewModel.setCount(5)
        viewModel.timerMinutes = 10

        await viewModel.generate()

        let quiz = try #require(viewModel.quiz)
        #expect(viewModel.phase == .ready)
        #expect(quiz.questions.count == 5)
        #expect(quiz.timerMinutes == 10)
        #expect(quiz.materialId == source.id)
        #expect(quiz.questionType == .multipleChoice)
        #expect(quiz.title == QuizCopy.quizTitle(source.title, 1))
        #expect(try await store.quiz(id: quiz.id) == quiz)
    }

    @Test("Turning the timer off makes an untimed quiz")
    func untimed() async throws {
        let viewModel = model(material: material())
        viewModel.timerEnabled = false

        await viewModel.generate()

        #expect(try #require(viewModel.quiz).timerMinutes == nil)
    }

    @Test("A second quiz on the same material is numbered after the first")
    func numbersQuizzes() async throws {
        let source = material()
        let store = InMemoryQuizStore(seededWith: [Quiz(title: "Old", materialId: source.id, questionType: .mixed, questions: [])])
        let viewModel = model(material: source, quizStore: store)

        await viewModel.generate()

        #expect(try #require(viewModel.quiz).title == QuizCopy.quizTitle(source.title, 2))
    }

    @Test("Short answer quizzes keep one model answer per question")
    func shortAnswerQuiz() async throws {
        let viewModel = model(material: material())
        viewModel.questionType = .shortAnswer

        await viewModel.generate()

        let quiz = try #require(viewModel.quiz)
        #expect(quiz.questions.allSatisfy { QuizQuestionKind($0) == .shortAnswer })
    }

    @Test("A failed save is shown and no quiz starts")
    func saveFailure() async {
        let store = InMemoryQuizStore()
        await store.forceFailure(.storageFailed)
        let viewModel = model(material: material(), quizStore: store)

        await viewModel.generate()

        #expect(viewModel.quiz == nil)
        #expect(viewModel.error != nil)
        #expect(viewModel.phase == .configuring)
    }

    @Test("Starting over clears the generated quiz")
    func startOver() async {
        let viewModel = model(material: material())
        await viewModel.generate()

        viewModel.startOver()

        #expect(viewModel.quiz == nil)
        #expect(viewModel.phase == .configuring)
    }
}
