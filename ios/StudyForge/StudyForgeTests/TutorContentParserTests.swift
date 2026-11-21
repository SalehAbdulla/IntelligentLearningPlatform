import Foundation
import Testing
@testable import StudyForge

@Suite("Course directory and published content parsing (F11)")
struct TutorContentParserTests {

    private func course(_ id: String, code: String, mode: EnrolmentMode = .code) -> Course {
        Course(id: id, name: "Course \(id)", code: code, tutorUid: "tutor", enrolmentMode: mode)
    }

    @Test("Cards come back from the drafted text, including edits")
    func parsesCards() {
        let text = """
        Q: What is BFS?
        A: Level-by-level search.

        Q: What is DFS?
        A: Goes deep first,
        then backtracks.

        Just a line with no answer
        """

        #expect(TutorContentParser.cards(from: text) == [
            ParsedCard(front: "What is BFS?", back: "Level-by-level search."),
            ParsedCard(front: "What is DFS?", back: "Goes deep first, then backtracks.")
        ])
    }

    @Test("Arabic prefixes and unprefixed two-line blocks are understood")
    func parsesArabicAndPlain() {
        #expect(TutorContentParser.cards(from: "س: ما هو الجذر؟\nج: العقدة الأولى") == [ParsedCard(front: "ما هو الجذر؟", back: "العقدة الأولى")])
        #expect(TutorContentParser.cards(from: "Front line\nBack line") == [ParsedCard(front: "Front line", back: "Back line")])
    }

    @Test("Quiz questions keep the stem without its number and the checked answer")
    func parsesQuestions() {
        let text = """
        1. Which search goes level by level?
        ✓ BFS

        2) What is the height of a single-node tree?
        ✓ 0

        3. A question the tutor left without an answer
        """

        #expect(TutorContentParser.questions(from: text) == [
            ParsedQuestion(stem: "Which search goes level by level?", answer: "BFS"),
            ParsedQuestion(stem: "What is the height of a single-node tree?", answer: "0")
        ])
        #expect(TutorContentParser.droppingNumber("2024 was a year") == "2024 was a year")
    }

    @Test("The drafter's own format round-trips through the parser")
    func roundTrip() {
        let cards = [AIFlashcard(front: "Front", back: "Back", difficulty: 1)]
        #expect(TutorContentParser.cards(from: TutorReviewDrafter.flashcardText(cards)) == [ParsedCard(front: "Front", back: "Back")])
    }

    @Test("Join codes ignore case, spaces and dashes")
    func normalisedCodes() async throws {
        let directory = InMemoryCourseDirectory(seededWith: [course("c1", code: "CS 201"), course("c2", code: "IT-8108")])

        #expect(try await directory.entry(code: "cs201")?.courseId == "c1")
        #expect(try await directory.entry(code: " it8108 ")?.courseId == "c2")
        #expect(try await directory.entry(code: "XX999") == nil)
        #expect(try await directory.entry(code: "  ") == nil)
    }

    @Test("Registering again updates a course's code and mode")
    func reRegister() async throws {
        let directory = InMemoryCourseDirectory(seededWith: [course("c1", code: "OLD1")])
        try await directory.register([course("c1", code: "NEW1", mode: .approval)])

        #expect(try await directory.entry(code: "OLD1") == nil)
        #expect(try await directory.entry(code: "NEW1")?.enrolmentMode == .approval)
        #expect(try await directory.entries().count == 1)
    }

    @Test("The file directory survives a relaunch")
    func fileDirectory() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try await FileCourseDirectory(directory: folder).register([course("c1", code: "CS201")])

        #expect(try await FileCourseDirectory(directory: folder).entry(code: "cs201")?.name == "Course c1")
    }
}
