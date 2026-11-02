import SwiftUI

enum FlashcardLimits {
    static let countOptions = [10, 20, 30, 50]
    static let defaultCount = 20
    static let deckTitleMaxCharacters = 60
    static let frontMaxCharacters = 200
    static let backMaxCharacters = 400
    static let masteredIntervalDays = 30
    static let flagTag = "flagged"
    static let revealMilliseconds = 1_500
}

enum CardMastery: Equatable {
    case new
    case learning
    case mastered

    init(_ state: SpacedRepetitionState) {
        if state.interval >= FlashcardLimits.masteredIntervalDays {
            self = .mastered
        } else if state.reps > 0 || state.lapses > 0 {
            self = .learning
        } else {
            self = .new
        }
    }

    var color: Color {
        switch self {
        case .new: ColorTokens.outline
        case .learning: ColorTokens.warning
        case .mastered: ColorTokens.success
        }
    }

    var title: String {
        switch self {
        case .new: L10n.deckNewLabel.string
        case .learning: L10n.deckLearningLabel.string
        case .mastered: L10n.deckMasteredLabel.string
        }
    }
}

enum FlashcardEditorTarget: Identifiable {
    case edit(Flashcard)
    case create

    var id: String {
        switch self {
        case .edit(let card): card.id
        case .create: "create"
        }
    }
}

struct FlashcardAnswer: Equatable {
    let headline: String
    let detail: String?

    var isShort: Bool { headline.count <= 40 }

    init(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
        headline = lines.first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? trimmed
        let rest = lines.count > 1 ? String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""
        detail = rest.isEmpty ? nil : rest
    }
}

enum FlashcardText {

    static func normalized(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func clamp(_ text: String, to limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) : text
    }

    static func cleaned(_ text: String, limit: Int) -> String {
        clamp(text.trimmingCharacters(in: .whitespacesAndNewlines), to: limit)
    }

    static func relative(_ date: Date, now: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func dueLabel(_ date: Date, now: Date = .now) -> String {
        let calendar = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(date, inSameDayAs: now) {
            return FlashcardCopy.todayAt(time)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return FlashcardCopy.tomorrowAt(time)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(Int(seconds.rounded()), 0)
        if total < 60 {
            return FlashcardCopy.seconds(total)
        }
        return FlashcardCopy.minutes(Int((Double(total) / 60).rounded()))
    }
}

extension Deck {

    var masteryShare: Double {
        guard !cards.isEmpty else { return 0 }
        let limit = Double(FlashcardLimits.masteredIntervalDays)
        let total = cards.reduce(0.0) { $0 + min(Double($1.sr.interval), limit) / limit }
        return total / Double(cards.count)
    }

    var masteryPercent: Int { Int((masteryShare * 100).rounded()) }

    var lastReviewedAt: Date? {
        cards.compactMap { card -> Date? in
            guard card.sr.reps > 0 || card.sr.lapses > 0 else { return nil }
            return Calendar.current.date(byAdding: .day, value: -card.sr.interval, to: card.sr.dueAt)
        }
        .max()
    }

    func nextDueDate(after now: Date = .now) -> Date? {
        cards.map { $0.sr.dueAt }.filter { $0 > now }.min()
    }

    var subjectColor: Color { ColorTokens.Subject.color(for: id) }
}

extension Flashcard {
    var isFlagged: Bool { tags.contains(FlashcardLimits.flagTag) }
}

extension FlashcardDifficulty {
    static let levels: [FlashcardDifficulty] = [.recall, .mixed, .understanding]

    var levelTitle: String {
        switch self {
        case .recall: FlashcardCopy.difficultyEasy
        case .mixed: FlashcardCopy.difficultyMedium
        case .understanding: FlashcardCopy.difficultyHard
        }
    }
}

extension CardType {
    var shortTitle: String {
        switch self {
        case .qa: FlashcardCopy.typeQa
        case .cloze: FlashcardCopy.typeCloze
        case .imageOcclusion: FlashcardCopy.typeImage
        case .reversible: FlashcardCopy.typeReverse
        }
    }
}

extension ReviewRating {
    var fill: Color {
        switch self {
        case .again: ColorTokens.error
        case .hard: ColorTokens.warning
        case .good: ColorTokens.primary
        case .easy: ColorTokens.Subject.cyan
        }
    }

    var ink: Color {
        switch self {
        case .again, .good: ColorTokens.onError
        case .hard, .easy: ColorTokens.onAccent
        }
    }
}

struct FlashcardProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorTokens.outline)
                Capsule()
                    .fill(ColorTokens.primary)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

struct FlashcardMasteryRing: View {
    let share: Double
    var lineWidth: CGFloat = 6

    private var clamped: Double { min(max(share, 0), 1) }
    private var percent: Int { Int((clamped * 100).rounded()) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.outline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(ColorTokens.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "\(percent)%")
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
        }
        .padding(lineWidth / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(FlashcardCopy.mastery(percent))
    }
}
