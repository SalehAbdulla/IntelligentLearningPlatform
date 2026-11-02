import Foundation

enum FlashcardCopy {

    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: "Flashcards")
    }

    static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: arguments)
    }

    static var decksTitle: String { text("flashcards.decks.title") }
    static var newDeck: String { text("flashcards.decks.new") }
    static func cardCount(_ count: Int) -> String {
        count == 1 ? text("flashcards.cards.one") : format("flashcards.cards.count", count)
    }
    static func dueBadge(_ count: Int) -> String { format("flashcards.decks.due", count) }
    static func lastReviewed(_ relative: String) -> String { format("flashcards.decks.lastReviewed", relative) }
    static var notReviewed: String { text("flashcards.decks.notReviewed") }
    static func mastery(_ percent: Int) -> String { format("flashcards.decks.mastery", percent) }
    static func duePill(_ count: Int) -> String { format("flashcards.decks.duePill", count) }
    static var emptyTitle: String { text("flashcards.decks.emptyTitle") }
    static var emptyBody: String { text("flashcards.decks.emptyBody") }
    static var makeFlashcards: String { text("flashcards.decks.make") }
    static var deleteDeck: String { text("flashcards.deck.delete") }
    static var deleteDeckTitle: String { text("flashcards.deck.deleteTitle") }
    static func deleteDeckMessage(_ title: String) -> String { format("flashcards.deck.deleteMessage", title) }

    static var generateTitle: String { text("flashcards.generate.title") }
    static var chooseMaterial: String { text("flashcards.generate.chooseMaterial") }
    static var noMaterials: String { text("flashcards.generate.noMaterials") }
    static var countLabel: String { text("flashcards.generate.count") }
    static var difficultyLabel: String { text("flashcards.generate.difficulty") }
    static var difficultyEasy: String { text("flashcards.difficulty.easy") }
    static var difficultyMedium: String { text("flashcards.difficulty.medium") }
    static var difficultyHard: String { text("flashcards.difficulty.hard") }
    static var typeLabel: String { text("flashcards.generate.type") }
    static var typeQa: String { text("flashcards.type.qa") }
    static var typeCloze: String { text("flashcards.type.cloze") }
    static var typeImage: String { text("flashcards.type.image") }
    static var typeReverse: String { text("flashcards.type.reverse") }
    static var rangeLabel: String { text("flashcards.generate.range") }
    static func pageRange(_ first: Int, _ last: Int) -> String { format("flashcards.generate.pages", first, last) }
    static var wholeMaterial: String { text("flashcards.generate.whole") }
    static var fromPage: String { text("flashcards.generate.from") }
    static var toPage: String { text("flashcards.generate.to") }
    static func generateCount(_ count: Int) -> String { format("flashcards.generate.button", count) }
    static var materialEmpty: String { text("flashcards.generate.error.empty") }
    static var rangeEmpty: String { text("flashcards.generate.error.range") }
    static var noCards: String { text("flashcards.generate.error.noCards") }

    static var generatingHeading: String { text("flashcards.generating.heading") }
    static func generatedProgress(_ done: Int, _ total: Int) -> String { format("flashcards.generating.progress", done, total) }
    static var preparing: String { text("flashcards.generating.preparing") }
    static func generatingAccessibility(_ engine: String) -> String { format("flashcards.generating.a11y", engine) }
    static func question(_ text: String) -> String { format("flashcards.preview.question", text) }
    static func answer(_ text: String) -> String { format("flashcards.preview.answer", text) }

    static var reviewHeading: String { text("flashcards.draft.heading") }
    static var reviewHint: String { text("flashcards.draft.hint") }
    static func duplicates(_ count: Int) -> String { format("flashcards.draft.duplicates", count) }
    static var removeDuplicates: String { text("flashcards.draft.removeDuplicates") }
    static var duplicateChip: String { text("flashcards.draft.duplicate") }
    static var addCard: String { text("flashcards.draft.add") }
    static var saveTo: String { text("flashcards.draft.saveTo") }
    static var newDeckOption: String { text("flashcards.draft.newDeck") }
    static var deckName: String { text("flashcards.draft.deckName") }
    static func saveCards(_ count: Int) -> String {
        count == 1 ? text("flashcards.draft.saveOne") : format("flashcards.draft.save", count)
    }
    static var startOver: String { text("flashcards.draft.startOver") }
    static var discardCardsTitle: String { text("flashcards.draft.discardTitle") }
    static var discardCardsMessage: String { text("flashcards.draft.discardMessage") }
    static var discard: String { text("flashcards.discard") }
    static var keepEditing: String { text("flashcards.keepEditing") }
    static var savedTitle: String { text("flashcards.saved.title") }
    static func savedBody(_ count: Int, _ title: String) -> String { format("flashcards.saved.body", count, title) }
    static var studyNow: String { text("flashcards.studyNow") }
    static var done: String { text("flashcards.done") }
    static var save: String { text("flashcards.save") }

    static var editCard: String { text("flashcards.editor.edit") }
    static var newCard: String { text("flashcards.editor.new") }
    static var front: String { text("flashcards.editor.front") }
    static var back: String { text("flashcards.editor.back") }
    static var frontPlaceholder: String { text("flashcards.editor.frontPlaceholder") }
    static var backPlaceholder: String { text("flashcards.editor.backPlaceholder") }
    static var cardBlank: String { text("flashcards.editor.blank") }
    static var deleteCard: String { text("flashcards.editor.delete") }
    static var deleteCardTitle: String { text("flashcards.editor.deleteTitle") }
    static var deleteCardMessage: String { text("flashcards.editor.deleteMessage") }
    static var discardChangesTitle: String { text("flashcards.editor.discardTitle") }
    static func characters(_ count: Int, _ limit: Int) -> String { format("flashcards.characters", count, limit) }

    static var editDeck: String { text("flashcards.deck.edit") }
    static var renameDeck: String { text("flashcards.deck.rename") }
    static var renamePrompt: String { text("flashcards.deck.renamePrompt") }
    static var deckMissing: String { text("flashcards.deck.missing") }
    static var noCardsYet: String { text("flashcards.deck.noCards") }
    static func caughtUp(_ when: String) -> String { format("flashcards.deck.caughtUp", when) }
    static func cardState(_ front: String, _ state: String) -> String { format("flashcards.deck.cardState", front, state) }
    static var flagged: String { text("flashcards.deck.flagged") }

    static func progress(_ current: Int, _ total: Int) -> String { format("flashcards.review.progress", current, total) }
    static var tapAnywhere: String { text("flashcards.review.tap") }
    static var howWell: String { text("flashcards.review.howWell") }
    static func cite(_ label: String) -> String { format("flashcards.review.cite", label) }
    static var flag: String { text("flashcards.review.flag") }
    static var unflag: String { text("flashcards.review.unflag") }
    static var undo: String { text("flashcards.review.undo") }
    static var close: String { text("flashcards.review.close") }
    static var endSessionTitle: String { text("flashcards.review.endTitle") }
    static func endSessionMessage(_ count: Int) -> String { format("flashcards.review.endMessage", count) }
    static var endSession: String { text("flashcards.review.end") }
    static var keepReviewing: String { text("flashcards.review.keep") }

    static var sessionComplete: String { text("flashcards.summary.title") }
    static var reviewed: String { text("flashcards.summary.reviewed") }
    static var accuracy: String { text("flashcards.summary.accuracy") }
    static var time: String { text("flashcards.summary.time") }
    static func breakdown(again: Int, hard: Int, good: Int, easy: Int) -> String {
        format("flashcards.summary.breakdown", again, hard, good, easy)
    }
    static func nextReview(_ when: String) -> String { format("flashcards.summary.next", when) }
    static func dueAgain(_ count: Int) -> String { format("flashcards.summary.dueAgain", count) }
    static var keepGoing: String { text("flashcards.summary.keepGoing") }
    static var nothingDueTitle: String { text("flashcards.empty.title") }
    static var nothingDueBody: String { text("flashcards.empty.body") }

    static func todayAt(_ time: String) -> String { format("flashcards.date.today", time) }
    static func tomorrowAt(_ time: String) -> String { format("flashcards.date.tomorrow", time) }
    static func seconds(_ value: Int) -> String { format("flashcards.duration.seconds", value) }
    static func minutes(_ value: Int) -> String { format("flashcards.duration.minutes", value) }
}
