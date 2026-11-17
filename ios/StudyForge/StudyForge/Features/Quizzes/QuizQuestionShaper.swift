import Foundation

enum QuizQuestionKind: Equatable, Sendable {
    case multipleChoice
    case trueFalse
    case shortAnswer

    init(_ question: QuizQuestion) {
        switch question.options.count {
        case 1: self = .shortAnswer
        case 2: self = .trueFalse
        default: self = .multipleChoice
        }
    }
}

enum QuizQuestionShaper {

    static let maxOptions = 4

    static func kind(at index: Int, for type: QuizQuestionType) -> QuizQuestionKind {
        switch type {
        case .multipleChoice: .multipleChoice
        case .trueFalse: .trueFalse
        case .shortAnswer: .shortAnswer
        case .mixed:
            switch index % 4 {
            case 1: .trueFalse
            case 3: .shortAnswer
            default: .multipleChoice
            }
        }
    }

    static func shaped(
        _ generated: [AIQuizQuestion],
        type: QuizQuestionType,
        provenance: AIProvenance,
        trueLabel: String = QuizCopy.trueOption,
        falseLabel: String = QuizCopy.falseOption
    ) -> [QuizQuestion] {
        var seenStems = Set<String>()
        var result: [QuizQuestion] = []
        for (index, item) in generated.enumerated() {
            guard let question = shape(
                item,
                kind: kind(at: index, for: type),
                index: index,
                provenance: provenance,
                trueLabel: trueLabel,
                falseLabel: falseLabel
            ) else { continue }
            let key = question.stem.lowercased()
            guard seenStems.insert(key).inserted else { continue }
            result.append(question)
        }
        return result
    }

    static func shape(
        _ item: AIQuizQuestion,
        kind: QuizQuestionKind,
        index: Int,
        provenance: AIProvenance,
        trueLabel: String,
        falseLabel: String
    ) -> QuizQuestion? {
        let stem = clean(item.stem)
        guard !stem.isEmpty, item.options.indices.contains(item.correctOptionIndex) else { return nil }
        let correct = clean(item.options[item.correctOptionIndex])
        guard !correct.isEmpty else { return nil }

        let topic = clean(item.topic).isEmpty ? QuizCopy.generalTopic : clean(item.topic)
        let explanation = clean(item.explanation)
        let distractors = distinctDistractors(item.options, correct: correct)

        func make(_ stem: String, _ options: [String], _ answer: Int) -> QuizQuestion {
            QuizQuestion(
                stem: stem,
                options: options,
                correctOptionIndex: answer,
                explanation: explanation,
                topic: topic,
                provenance: provenance
            )
        }

        if isTrueFalse(item.options) {
            return make(stem, [trueLabel, falseLabel], correct.lowercased() == "true" ? 0 : 1)
        }

        switch kind {
        case .multipleChoice:
            guard !distractors.isEmpty else { return make(stem, [correct], 0) }
            var options = Array(distractors.prefix(maxOptions - 1))
            let position = index % (options.count + 1)
            options.insert(correct, at: position)
            return make(stem, options, position)
        case .trueFalse:
            let showsCorrect = index % 2 == 0 || distractors.isEmpty
            let claim = showsCorrect ? correct : distractors[0]
            return make(QuizCopy.trueFalseStem(stem, claim), [trueLabel, falseLabel], showsCorrect ? 0 : 1)
        case .shortAnswer:
            return make(stem, [correct], 0)
        }
    }

    static func isTrueFalse(_ options: [String]) -> Bool {
        options.count == 2 && Set(options.map { clean($0).lowercased() }) == ["true", "false"]
    }

    static func distinctDistractors(_ options: [String], correct: String) -> [String] {
        var seen: Set<String> = [correct.lowercased()]
        var result: [String] = []
        for option in options {
            let value = clean(option)
            guard !value.isEmpty, seen.insert(value.lowercased()).inserted else { continue }
            result.append(value)
        }
        return result
    }

    static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
