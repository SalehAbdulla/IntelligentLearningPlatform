import Foundation

struct FlashcardPresentation: Equatable {
    let prompt: String
    let answer: String
    let isReversed: Bool

    init(_ card: Flashcard) {
        switch card.cardType {
        case .reversible where card.sr.reps % 2 == 1:
            prompt = card.back
            answer = card.front
            isReversed = true
        case .cloze:
            prompt = card.front
            answer = Self.filled(card.front, with: card.back)
            isReversed = false
        default:
            prompt = card.front
            answer = card.back
            isReversed = false
        }
    }

    static let blankPatterns = [
        "\\{\\{[^}]*\\}\\}",
        "\\[\\s*(\\.\\.\\.|…)?\\s*\\]",
        "_{2,}"
    ]

    static func hasBlank(_ sentence: String) -> Bool {
        blankPatterns.contains { sentence.range(of: $0, options: .regularExpression) != nil }
    }

    static func filled(_ sentence: String, with back: String) -> String {
        let parts = FlashcardAnswer(back)
        for pattern in blankPatterns {
            guard let range = sentence.range(of: pattern, options: .regularExpression) else { continue }
            var completed = sentence
            completed.replaceSubrange(range, with: parts.headline)
            guard let detail = parts.detail else { return completed }
            return completed + "\n" + detail
        }
        return back
    }
}
