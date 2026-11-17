import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz question shaping (F05)")
struct QuizQuestionShaperTests {

    private let provenance = AIProvenance(materialId: "m", pageNumbers: [3], confidence: .high)

    private func generated(_ index: Int = 0, options: [String]? = nil, correct: Int = 0, topic: String = "Trees") -> AIQuizQuestion {
        AIQuizQuestion(
            stem: "Question \(index)",
            options: options ?? ["Right \(index)", "Wrong A", "Wrong B", "Wrong C"],
            correctOptionIndex: correct,
            explanation: "Because page 3 says so.",
            topic: topic
        )
    }

    @Test("Multiple choice keeps four options and moves the correct one around")
    func multipleChoiceShuffles() {
        let shaped = QuizQuestionShaper.shaped((0..<4).map { generated($0) }, type: .multipleChoice, provenance: provenance)

        #expect(shaped.count == 4)
        #expect(shaped.allSatisfy { $0.options.count == 4 })
        #expect(shaped.allSatisfy { $0.options[$0.correctOptionIndex].hasPrefix("Right") })
        #expect(Set(shaped.map(\.correctOptionIndex)).count > 1)
        #expect(shaped.allSatisfy { QuizQuestionKind($0) == .multipleChoice })
    }

    @Test("True or false turns a claim into two options and alternates true and false")
    func trueFalseFromClaims() {
        let shaped = QuizQuestionShaper.shaped(
            [generated(0), generated(1)],
            type: .trueFalse,
            provenance: provenance,
            trueLabel: "True",
            falseLabel: "False"
        )

        #expect(shaped.map(\.options) == [["True", "False"], ["True", "False"]])
        #expect(shaped[0].correctOptionIndex == 0)
        #expect(shaped[0].stem.contains("Right 0"))
        #expect(shaped[1].correctOptionIndex == 1)
        #expect(shaped[1].stem.contains("Wrong A"))
        #expect(QuizQuestionKind(shaped[0]) == .trueFalse)
    }

    @Test("A question that is already true or false keeps its answer")
    func existingTrueFalseKept() {
        let shaped = QuizQuestionShaper.shaped(
            [generated(0, options: ["True", "False"], correct: 1)],
            type: .multipleChoice,
            provenance: provenance,
            trueLabel: "صح",
            falseLabel: "خطأ"
        )

        #expect(shaped.first?.options == ["صح", "خطأ"])
        #expect(shaped.first?.correctOptionIndex == 1)
    }

    @Test("Short answer keeps only the model answer")
    func shortAnswerKeepsModel() {
        let shaped = QuizQuestionShaper.shaped([generated(0)], type: .shortAnswer, provenance: provenance)

        #expect(shaped.first?.options == ["Right 0"])
        #expect(shaped.first?.correctOptionIndex == 0)
        #expect(shaped.first.map(QuizQuestionKind.init) == .shortAnswer)
    }

    @Test("Mixed quizzes rotate through the three kinds")
    func mixedRotates() {
        let kinds = (0..<4).map { QuizQuestionShaper.kind(at: $0, for: .mixed) }
        #expect(kinds == [.multipleChoice, .trueFalse, .multipleChoice, .shortAnswer])
    }

    @Test("Broken and duplicate questions are dropped")
    func brokenDropped() {
        let broken = AIQuizQuestion(stem: "  ", options: ["A"], correctOptionIndex: 0, explanation: "", topic: "")
        let outOfRange = AIQuizQuestion(stem: "Q", options: ["A", "B"], correctOptionIndex: 5, explanation: "", topic: "")
        let shaped = QuizQuestionShaper.shaped(
            [generated(0), generated(0), broken, outOfRange],
            type: .multipleChoice,
            provenance: provenance
        )

        #expect(shaped.count == 1)
    }

    @Test("Repeated distractors are removed and a missing topic gets a default")
    func cleansOptions() {
        let shaped = QuizQuestionShaper.shaped(
            [generated(0, options: ["Right", "right", " Wrong ", "Wrong"], topic: " ")],
            type: .multipleChoice,
            provenance: provenance
        )

        #expect(shaped.first?.options.count == 2)
        #expect(shaped.first?.topic == QuizCopy.generalTopic)
        #expect(shaped.first?.provenance == provenance)
    }
}
