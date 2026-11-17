import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard review log (F04)")
struct FlashcardReviewLogTests {

    private func entry(_ id: String, at date: Date = .now) -> FlashcardReviewEntry {
        FlashcardReviewEntry(id: id, deckId: "d1", cardId: "c-\(id)", rating: .good, intervalDays: 1, reviewedAt: date)
    }

    @Test("The in-memory log keeps entries in review order")
    func inMemoryOrder() async throws {
        let log = InMemoryFlashcardReviewLog()
        try await log.append(entry("b", at: .now))
        try await log.append(entry("a", at: .now.addingTimeInterval(-60)))
        let ids = try await log.entries().map(\.id)
        #expect(ids == ["a", "b"])
    }

    @Test("Appending the same entry twice keeps one copy")
    func appendIsIdempotent() async throws {
        let log = InMemoryFlashcardReviewLog()
        try await log.append(entry("a"))
        try await log.append(entry("a"))
        #expect(try await log.entries().count == 1)
    }

    @Test("Removing an entry drops it from the log")
    func removeDropsEntry() async throws {
        let log = InMemoryFlashcardReviewLog(seededWith: [entry("a"), entry("b")])
        try await log.remove(id: "a")
        #expect(try await log.entries().map(\.id) == ["b"])
    }

    @Test("A forced failure surfaces as a storage error")
    func forcedFailure() async {
        let log = InMemoryFlashcardReviewLog()
        await log.forceFailure(.storageFailed)
        await #expect(throws: DeckError.storageFailed) {
            try await log.append(entry("a"))
        }
    }

    @Test("The file log survives a new instance on the same folder")
    func filePersists() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let first = FileFlashcardReviewLog(directory: folder)
        try await first.append(entry("a"))
        try await first.append(entry("b"))
        try await first.remove(id: "a")
        let second = FileFlashcardReviewLog(directory: folder)
        #expect(try await second.entries().map(\.id) == ["b"])
    }

    @Test("A missing file reads as an empty log")
    func missingFileIsEmpty() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let log = FileFlashcardReviewLog(directory: folder)
        #expect(try await log.entries().isEmpty)
    }
}
