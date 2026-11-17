import Foundation

struct QuizDraft: Equatable, Sendable, Codable {
    let quizId: String
    var questionIds: [String]
    var responses: [QuizResponse]
    var typedAnswers: [String: String]
    var credits: [String: QuizCredit]
    var flaggedQuestionIds: [String]
    var currentIndex: Int
    var deadline: Date?
    var elapsedSeconds: Int
    var savedAt: Date
}

protocol QuizDraftStore: Sendable {
    func draft(forQuiz quizId: String) async -> QuizDraft?
    func draftQuizIds() async -> Set<String>
    func save(_ draft: QuizDraft) async throws
    func clear(quizId: String) async
}

actor InMemoryQuizDraftStore: QuizDraftStore {

    private var drafts: [String: QuizDraft]

    init(seededWith drafts: [QuizDraft] = []) {
        self.drafts = Dictionary(drafts.map { ($0.quizId, $0) }, uniquingKeysWith: { _, last in last })
    }

    func draft(forQuiz quizId: String) async -> QuizDraft? {
        drafts[quizId]
    }

    func draftQuizIds() async -> Set<String> {
        Set(drafts.keys)
    }

    func save(_ draft: QuizDraft) async throws {
        drafts[draft.quizId] = draft
    }

    func clear(quizId: String) async {
        drafts[quizId] = nil
    }
}
