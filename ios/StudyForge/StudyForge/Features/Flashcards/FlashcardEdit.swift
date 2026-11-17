import Foundation

struct FlashcardEdit: Equatable {
    var front: String
    var back: String
    var tags: [String] = []
    var deckId: String?
    var imageData: Data?
    var removesImage = false
}

enum FlashcardTags {

    static let maxCount = 6
    static let maxLength = 24

    static func normalized(_ raw: String) -> String? {
        let stripped = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .lowercased()
        let joined = stripped.split(whereSeparator: \.isWhitespace).joined(separator: "-")
        guard !joined.isEmpty, joined != FlashcardLimits.flagTag else { return nil }
        return String(joined.prefix(maxLength))
    }

    static func visible(_ tags: [String]) -> [String] {
        tags.filter { $0 != FlashcardLimits.flagTag }
    }

    static func adding(_ raw: String, to tags: [String]) -> [String] {
        guard let tag = normalized(raw), !tags.contains(tag), visible(tags).count < maxCount else { return tags }
        return tags + [tag]
    }

    static func merged(_ edited: [String], keepingFlagFrom original: [String]) -> [String] {
        let cleaned = visible(edited).reduce(into: [String]()) { result, tag in
            if !result.contains(tag) { result.append(tag) }
        }
        let limited = Array(cleaned.prefix(maxCount))
        return original.contains(FlashcardLimits.flagTag) ? limited + [FlashcardLimits.flagTag] : limited
    }
}
