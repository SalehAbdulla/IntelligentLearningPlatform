import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz attempt log and drafts (F05)")
struct QuizAttemptLogTests {

    private func record(_ id: String, quiz: String = "quiz", at seconds: TimeInterval = 0) -> QuizAttemptRecord {
        QuizAttemptRecord(
            id: id,
            quizId: quiz,
            questionIds: ["q1", "q2"],
            durationSeconds: 90,
            flaggedQuestionIds: ["q2"],
            typedAnswers: ["q1": "rotations"],
            credits: ["q1": .half],
            completedAt: Date(timeIntervalSince1970: seconds)
        )
    }

    private func draft(_ quiz: String) -> QuizDraft {
        QuizDraft(
            quizId: quiz,
            questionIds: ["q1", "q2"],
            responses: [QuizResponse(questionId: "q1", selectedOptionIndex: 2, isCorrect: false)],
            typedAnswers: [:],
            credits: [:],
            flaggedQuestionIds: ["q1"],
            currentIndex: 1,
            deadline: Date(timeIntervalSince1970: 600),
            elapsedSeconds: 40,
            savedAt: Date(timeIntervalSince1970: 100)
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    @Test("The in-memory log returns a quiz's records newest first")
    func inMemoryOrdering() async throws {
        let log = InMemoryQuizAttemptLog(seededWith: [record("a", at: 10), record("b", at: 20), record("c", quiz: "other")])

        #expect(try await log.records(forQuiz: "quiz").map(\.id) == ["b", "a"])
        #expect(try await log.record(id: "c")?.quizId == "other")
    }

    @Test("Saving a record twice keeps one copy")
    func saveReplaces() async throws {
        let log = InMemoryQuizAttemptLog()
        try await log.save(record("a"))
        var updated = record("a")
        updated.durationSeconds = 120
        try await log.save(updated)

        let records = try await log.records(forQuiz: "quiz")
        #expect(records.count == 1)
        #expect(records.first?.durationSeconds == 120)
    }

    @Test("Removing a quiz's records leaves other quizzes alone")
    func removeForQuiz() async throws {
        let log = InMemoryQuizAttemptLog(seededWith: [record("a"), record("c", quiz: "other")])
        try await log.removeRecords(forQuiz: "quiz")

        #expect(try await log.records(forQuiz: "quiz").isEmpty)
        #expect(try await log.records(forQuiz: "other").count == 1)
    }

    @Test("A forced failure surfaces as a storage error")
    func forcedFailure() async {
        let log = InMemoryQuizAttemptLog()
        await log.forceFailure(.storageFailed)

        await #expect(throws: QuizError.storageFailed) {
            try await log.save(record("a"))
        }
    }

    @Test("The file log keeps records between launches")
    func fileRoundTrip() async throws {
        let directory = temporaryDirectory()
        try await FileQuizAttemptLog(directory: directory).save(record("a", at: 5))

        let reopened = FileQuizAttemptLog(directory: directory)
        let stored = try await reopened.record(id: "a")
        #expect(stored == record("a", at: 5))
        #expect(stored?.credits["q1"] == .half)
    }

    @Test("The file log reports an unreadable file")
    func fileCorrupt() async throws {
        let directory = temporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appendingPathComponent("quiz-attempts.json"))

        await #expect(throws: QuizError.storageFailed) {
            try await FileQuizAttemptLog(directory: directory).records(forQuiz: "quiz")
        }
    }

    @Test("Drafts are kept per quiz and cleared after submitting")
    func inMemoryDrafts() async throws {
        let drafts = InMemoryQuizDraftStore()
        try await drafts.save(draft("quiz"))
        try await drafts.save(draft("other"))

        #expect(await drafts.draftQuizIds() == ["quiz", "other"])
        #expect(await drafts.draft(forQuiz: "quiz")?.currentIndex == 1)

        await drafts.clear(quizId: "quiz")
        #expect(await drafts.draft(forQuiz: "quiz") == nil)
    }

    @Test("The file draft store survives a relaunch")
    func fileDrafts() async throws {
        let directory = temporaryDirectory()
        try await FileQuizDraftStore(directory: directory).save(draft("quiz"))

        let reopened = FileQuizDraftStore(directory: directory)
        #expect(await reopened.draft(forQuiz: "quiz") == draft("quiz"))

        await reopened.clear(quizId: "quiz")
        #expect(await FileQuizDraftStore(directory: directory).draftQuizIds().isEmpty)
    }
}
