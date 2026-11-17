import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard presentation (F04)")
struct FlashcardPresentationTests {

    private func card(_ type: CardType, front: String, back: String, reps: Int = 0) -> Flashcard {
        Flashcard(
            front: front,
            back: back,
            cardType: type,
            provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
            sr: SpacedRepetitionState(reps: reps)
        )
    }

    @Test("A question card shows its front, then its back")
    func questionCard() {
        let presentation = FlashcardPresentation(card(.qa, front: "What is a leaf?", back: "A node with no children."))
        #expect(presentation.prompt == "What is a leaf?")
        #expect(presentation.answer == "A node with no children.")
        #expect(!presentation.isReversed)
    }

    @Test("A reversible card is asked the normal way first")
    func reversibleStartsForward() {
        let presentation = FlashcardPresentation(card(.reversible, front: "Stack", back: "LIFO structure"))
        #expect(presentation.prompt == "Stack")
        #expect(!presentation.isReversed)
    }

    @Test("A reversible card alternates direction after each success")
    func reversibleAlternates() {
        let once = FlashcardPresentation(card(.reversible, front: "Stack", back: "LIFO structure", reps: 1))
        let twice = FlashcardPresentation(card(.reversible, front: "Stack", back: "LIFO structure", reps: 2))
        #expect(once.isReversed)
        #expect(once.prompt == "LIFO structure")
        #expect(once.answer == "Stack")
        #expect(!twice.isReversed)
    }

    @Test("A cloze answer fills the underscore blank with the term")
    func clozeUnderscores() {
        let presentation = FlashcardPresentation(card(.cloze, front: "A ____ has at most two children.", back: "binary tree"))
        #expect(presentation.prompt == "A ____ has at most two children.")
        #expect(presentation.answer == "A binary tree has at most two children.")
    }

    @Test("Bracket and brace blanks are filled too")
    func clozeOtherBlanks() {
        #expect(FlashcardPresentation.filled("Search is [...] in a balanced BST.", with: "O(log n)") == "Search is O(log n) in a balanced BST.")
        #expect(FlashcardPresentation.filled("The {{c1::root}} has no parent.", with: "root") == "The root has no parent.")
    }

    @Test("An explanation under the term stays on its own line")
    func clozeKeepsExplanation() {
        let filled = FlashcardPresentation.filled("A ____ has no children.", with: "leaf\nIt sits at the bottom of the tree.")
        #expect(filled == "A leaf has no children.\nIt sits at the bottom of the tree.")
    }

    @Test("A cloze card with no blank falls back to its back")
    func clozeWithoutBlank() {
        #expect(!FlashcardPresentation.hasBlank("No gap here"))
        #expect(FlashcardPresentation(card(.cloze, front: "No gap here", back: "term")).answer == "term")
    }
}
