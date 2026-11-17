import Foundation

struct TutorEncouragement: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let courseId: String
    let studentUid: String
    let announcementId: String
    let message: String
    let sentAt: Date

    init(
        id: String = UUID().uuidString,
        courseId: String,
        studentUid: String,
        announcementId: String,
        message: String,
        sentAt: Date = .now
    ) {
        self.id = id
        self.courseId = courseId
        self.studentUid = studentUid
        self.announcementId = announcementId
        self.message = message
        self.sentAt = sentAt
    }
}

protocol TutorEncouragementLog: Sendable {
    func entries(courseId: String, studentUid: String) async throws -> [TutorEncouragement]
    func record(_ entry: TutorEncouragement) async throws
}

actor InMemoryTutorEncouragementLog: TutorEncouragementLog {

    private var stored: [TutorEncouragement]
    private var failure: TutorError?

    init(seededWith entries: [TutorEncouragement] = []) {
        self.stored = entries
    }

    func entries(courseId: String, studentUid: String) async throws -> [TutorEncouragement] {
        if let failure { throw failure }
        return stored
            .filter { $0.courseId == courseId && $0.studentUid == studentUid }
            .sorted { $0.sentAt > $1.sentAt }
    }

    func record(_ entry: TutorEncouragement) async throws {
        if let failure { throw failure }
        stored.removeAll { $0.id == entry.id }
        stored.append(entry)
    }

    func forceFailure(_ error: TutorError?) {
        failure = error
    }
}

actor FileTutorEncouragementLog: TutorEncouragementLog {

    static let shared = FileTutorEncouragementLog()

    private let fileURL: URL
    private var cache: [TutorEncouragement]?

    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("tutor-encouragements.json")
    }

    func entries(courseId: String, studentUid: String) async throws -> [TutorEncouragement] {
        try load()
            .filter { $0.courseId == courseId && $0.studentUid == studentUid }
            .sorted { $0.sentAt > $1.sentAt }
    }

    func record(_ entry: TutorEncouragement) async throws {
        var current = try load()
        current.removeAll { $0.id == entry.id }
        current.append(entry)
        try persist(current)
    }

    private func load() throws -> [TutorEncouragement] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let decoded = try JSONDecoder().decode([TutorEncouragement].self, from: Data(contentsOf: fileURL))
            cache = decoded
            return decoded
        } catch {
            throw TutorError.storageFailed
        }
    }

    private func persist(_ entries: [TutorEncouragement]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
            cache = entries
        } catch {
            throw TutorError.storageFailed
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
