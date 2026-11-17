import Foundation

protocol FlashcardImageStore: Sendable {
    func image(for cardId: String) async -> Data?
    func save(_ data: Data, for cardId: String) async throws
    func remove(for cardId: String) async
}

actor InMemoryFlashcardImageStore: FlashcardImageStore {

    private var images: [String: Data]

    init(seededWith images: [String: Data] = [:]) {
        self.images = images
    }

    func image(for cardId: String) async -> Data? {
        images[cardId]
    }

    func save(_ data: Data, for cardId: String) async throws {
        images[cardId] = data
    }

    func remove(for cardId: String) async {
        images[cardId] = nil
    }
}

actor FileFlashcardImageStore: FlashcardImageStore {

    static let shared = FileFlashcardImageStore()

    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? Self.defaultDirectory
    }

    func image(for cardId: String) async -> Data? {
        try? Data(contentsOf: fileURL(for: cardId))
    }

    func save(_ data: Data, for cardId: String) async throws {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: cardId), options: .atomic)
        } catch {
            throw DeckError.storageFailed
        }
    }

    func remove(for cardId: String) async {
        try? FileManager.default.removeItem(at: fileURL(for: cardId))
    }

    private func fileURL(for cardId: String) -> URL {
        let safe = cardId.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" }
            .map(String.init)
            .joined()
        return directory.appendingPathComponent("\(safe.isEmpty ? "card" : safe).jpg")
    }

    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge/CardImages", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("CardImages", isDirectory: true)
    }
}
