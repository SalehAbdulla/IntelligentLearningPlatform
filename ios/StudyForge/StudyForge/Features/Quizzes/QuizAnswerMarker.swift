import Foundation

enum QuizCredit: String, Equatable, Sendable, Codable {
    case full
    case half
    case zero

    var points: Double {
        switch self {
        case .full: 1
        case .half: 0.5
        case .zero: 0
        }
    }
}

enum QuizAnswerMarker {

    static let fullRecall = 0.8
    static let halfRecall = 0.5
    static let minimumPrecision = 0.5
    static let maxAnswerLength = 120

    private static let ignored: Set<String> = [
        "a", "an", "the", "of", "to", "in", "on", "is", "are", "was", "were", "and", "or", "it", "its", "by", "for"
    ]

    static func words(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !ignored.contains($0) }
    }

    static func limited(_ text: String) -> String {
        String(text.prefix(maxAnswerLength))
    }

    static func credit(for answer: String, expected: String) -> QuizCredit {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .zero }

        let given = words(trimmed)
        let wanted = words(expected)
        guard !wanted.isEmpty else {
            return trimmed.lowercased() == expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ? .full : .zero
        }
        guard !given.isEmpty else { return .zero }
        if given == wanted { return .full }

        let givenSet = Set(given)
        let wantedSet = Set(wanted)
        let shared = Double(givenSet.intersection(wantedSet).count)
        let recall = shared / Double(wantedSet.count)
        let precision = shared / Double(givenSet.count)

        if recall >= fullRecall && precision >= minimumPrecision { return .full }
        if recall >= halfRecall { return .half }
        return .zero
    }
}
