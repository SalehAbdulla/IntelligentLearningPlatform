import Foundation

struct ParsedCard: Equatable, Sendable {
    let front: String
    let back: String
}

struct ParsedQuestion: Equatable, Sendable {
    let stem: String
    let answer: String
}

enum TutorContentParser {

    static let questionPrefixes = ["Q:", "س:"]
    static let answerPrefixes = ["A:", "ج:"]
    static let answerMarks = ["✓"]

    static func blocks(_ text: String) -> [[String]] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { block in
                block.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
            .filter { !$0.isEmpty }
    }

    static func cards(from text: String) -> [ParsedCard] {
        blocks(text).compactMap { lines in
            var front: [String] = []
            var back: [String] = []
            var readingBack = false
            for line in lines {
                if let rest = stripped(line, prefixes: questionPrefixes) {
                    readingBack = false
                    front.append(rest)
                } else if let rest = stripped(line, prefixes: answerPrefixes) {
                    readingBack = true
                    back.append(rest)
                } else if readingBack {
                    back.append(line)
                } else {
                    front.append(line)
                }
            }
            if back.isEmpty, front.count > 1 {
                back = Array(front.dropFirst())
                front = [front[0]]
            }
            let card = ParsedCard(front: front.joined(separator: " "), back: back.joined(separator: " "))
            return card.front.isEmpty || card.back.isEmpty ? nil : card
        }
    }

    static func questions(from text: String) -> [ParsedQuestion] {
        blocks(text).compactMap { lines in
            var stem: [String] = []
            var answer: String?
            for line in lines {
                if let rest = stripped(line, prefixes: answerMarks) {
                    answer = rest
                } else if answer == nil {
                    stem.append(stem.isEmpty ? droppingNumber(line) : line)
                }
            }
            let question = stem.joined(separator: " ")
            guard !question.isEmpty, let answer, !answer.isEmpty else { return nil }
            return ParsedQuestion(stem: question, answer: answer)
        }
    }

    static func stripped(_ line: String, prefixes: [String]) -> String? {
        for prefix in prefixes where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    static func droppingNumber(_ line: String) -> String {
        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty else { return line }
        let rest = line.dropFirst(digits.count)
        guard let first = rest.first, first == "." || first == ")" else { return line }
        return String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
    }
}
