import Foundation
import Testing
@testable import StudyForge

@Suite("Short answer marking (F05)")
struct QuizAnswerMarkerTests {

    @Test("A matching answer earns full credit whatever its case and punctuation")
    func exactMatch() {
        #expect(QuizAnswerMarker.credit(for: "In-order", expected: "in order") == .full)
        #expect(QuizAnswerMarker.credit(for: "  ROTATIONS. ", expected: "Rotations") == .full)
    }

    @Test("Filler words do not change the mark")
    func fillerIgnored() {
        #expect(QuizAnswerMarker.credit(for: "the longest path to a leaf", expected: "Longest path to a leaf") == .full)
    }

    @Test("Half of the key words earns half credit")
    func halfCredit() {
        #expect(QuizAnswerMarker.credit(for: "longest path", expected: "longest path to leaf node") == .half)
    }

    @Test("A wrong or empty answer earns nothing")
    func noCredit() {
        #expect(QuizAnswerMarker.credit(for: "number of nodes", expected: "longest path to a leaf") == .zero)
        #expect(QuizAnswerMarker.credit(for: "   ", expected: "anything") == .zero)
    }

    @Test("Padding a right answer with unrelated words drops it to half credit")
    func paddedAnswer() {
        #expect(QuizAnswerMarker.credit(for: "rotations heaps stacks queues graphs", expected: "rotations") == .half)
    }

    @Test("Numbers are marked like words")
    func numbers() {
        #expect(QuizAnswerMarker.credit(for: "0", expected: "0") == .full)
        #expect(QuizAnswerMarker.credit(for: "1", expected: "0") == .zero)
    }

    @Test("Answers are cut to the maximum length")
    func limitsLength() {
        let long = String(repeating: "a", count: QuizAnswerMarker.maxAnswerLength + 20)
        #expect(QuizAnswerMarker.limited(long).count == QuizAnswerMarker.maxAnswerLength)
        #expect(QuizCredit.half.points == 0.5)
    }
}
