import Foundation

struct CourseDirectoryEntry: Identifiable, Equatable, Sendable, Codable {
    let courseId: String
    var code: String
    var name: String
    var tutorUid: String
    var enrolmentMode: EnrolmentMode
    var isArchived: Bool

    var id: String { courseId }

    init(course: Course) {
        self.courseId = course.id
        self.code = course.code
        self.name = course.name
        self.tutorUid = course.tutorUid
        self.enrolmentMode = course.enrolmentMode
        self.isArchived = course.isArchived
    }

    static func normalized(_ code: String) -> String {
        code.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    var joinKey: String { Self.normalized(code) }
}

protocol CourseDirectory: Sendable {
    func entries() async throws -> [CourseDirectoryEntry]
    func entry(code: String) async throws -> CourseDirectoryEntry?
    func register(_ courses: [Course]) async throws
}

actor InMemoryCourseDirectory: CourseDirectory {

    private var stored: [String: CourseDirectoryEntry]

    init(seededWith courses: [Course] = []) {
        self.stored = Dictionary(courses.map { ($0.id, CourseDirectoryEntry(course: $0)) }, uniquingKeysWith: { _, last in last })
    }

    func entries() async throws -> [CourseDirectoryEntry] {
        stored.values.sorted { $0.code < $1.code }
    }

    func entry(code: String) async throws -> CourseDirectoryEntry? {
        let key = CourseDirectoryEntry.normalized(code)
        guard !key.isEmpty else { return nil }
        return stored.values.first { $0.joinKey == key }
    }

    func register(_ courses: [Course]) async throws {
        for course in courses {
            stored[course.id] = CourseDirectoryEntry(course: course)
        }
    }
}

actor FileCourseDirectory: CourseDirectory {

    static let shared = FileCourseDirectory()

    private let fileURL: URL
    private var cache: [String: CourseDirectoryEntry]?

    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("course-directory.json")
    }

    func entries() async throws -> [CourseDirectoryEntry] {
        try load().values.sorted { $0.code < $1.code }
    }

    func entry(code: String) async throws -> CourseDirectoryEntry? {
        let key = CourseDirectoryEntry.normalized(code)
        guard !key.isEmpty else { return nil }
        return try load().values.first { $0.joinKey == key }
    }

    func register(_ courses: [Course]) async throws {
        guard !courses.isEmpty else { return }
        var current = try load()
        for course in courses {
            current[course.id] = CourseDirectoryEntry(course: course)
        }
        try persist(current)
    }

    private func load() throws -> [String: CourseDirectoryEntry] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = [:]
            return [:]
        }
        do {
            let decoded = try JSONDecoder().decode([String: CourseDirectoryEntry].self, from: Data(contentsOf: fileURL))
            cache = decoded
            return decoded
        } catch {
            throw TutorError.storageFailed
        }
    }

    private func persist(_ entries: [String: CourseDirectoryEntry]) throws {
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
