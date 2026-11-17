import Foundation

actor FileQuizDraftStore: QuizDraftStore {

    static let shared = FileQuizDraftStore()

    private let fileURL: URL
    private var cache: [String: QuizDraft]?

    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("quiz-drafts.json")
    }

    func draft(forQuiz quizId: String) async -> QuizDraft? {
        load()[quizId]
    }

    func draftQuizIds() async -> Set<String> {
        Set(load().keys)
    }

    func save(_ draft: QuizDraft) async throws {
        var current = load()
        current[draft.quizId] = draft
        try persist(current)
    }

    func clear(quizId: String) async {
        var current = load()
        guard current.removeValue(forKey: quizId) != nil else { return }
        try? persist(current)
    }

    private func load() -> [String: QuizDraft] {
        if let cache { return cache }
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: QuizDraft].self, from: data) else {
            cache = [:]
            return [:]
        }
        cache = decoded
        return decoded
    }

    private func persist(_ drafts: [String: QuizDraft]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(drafts)
            try data.write(to: fileURL, options: .atomic)
            cache = drafts
        } catch {
            throw QuizError.storageFailed
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
