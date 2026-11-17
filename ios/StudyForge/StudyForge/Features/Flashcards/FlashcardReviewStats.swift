import Foundation

enum FlashcardReviewStats {

    static func streak(
        _ entries: [FlashcardReviewEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let days = Set(entries.map { calendar.startOfDay(for: $0.reviewedAt) })
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        var cursor = today
        if !days.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func reviewedToday(
        _ entries: [FlashcardReviewEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        entries.filter { calendar.isDate($0.reviewedAt, inSameDayAs: now) }.count
    }
}
