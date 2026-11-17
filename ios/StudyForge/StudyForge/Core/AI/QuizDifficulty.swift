import Foundation

enum QuizDifficulty: String, Sendable, CaseIterable, Codable {
    case easy
    case medium
    case hard

    var promptGuidance: String {
        switch self {
        case .easy:
            "Keep every question to direct recall of definitions and facts the material states."
        case .medium:
            "Mix recall with questions that ask the student to apply or compare ideas from the material."
        case .hard:
            "Favour application and analysis questions with close distractors, still answerable from the material alone."
        }
    }
}
