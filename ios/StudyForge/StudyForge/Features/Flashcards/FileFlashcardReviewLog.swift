import Foundation

actor FileFlashcardReviewLog: FlashcardReviewLog {

    static let shared = FileFlashcardReviewLog()

    private let fileURL: URL
    private var cache: [FlashcardReviewEntry]?

    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("card-reviews.json")
    }

    func entries() async throws -> [FlashcardReviewEntry] {
        try load().sorted { $0.reviewedAt < $1.reviewedAt }
    }

    func append(_ entry: FlashcardReviewEntry) async throws {
        var current = try load()
        current.removeAll { $0.id == entry.id }
        current.append(entry)
        try persist(current)
    }

    func remove(id: String) async throws {
        var current = try load()
        current.removeAll { $0.id == id }
        try persist(current)
    }

    private func load() throws -> [FlashcardReviewEntry] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([FlashcardReviewEntry].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw DeckError.storageFailed
        }
    }

    private func persist(_ entries: [FlashcardReviewEntry]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
            cache = entries
        } catch {
            throw DeckError.storageFailed
        }
    }

    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
