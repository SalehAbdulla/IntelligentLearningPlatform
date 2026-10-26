//
//  RecallSessionViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F17's sitting: the learning ladder, graduation at the learner's own interval, the
//  scheduler taking over for reviews, honest progress, and the three ways a sitting can shrink
//  underneath the learner (a deletion, a tightened ceiling, a failed save).
//

import Foundation
import Testing
@testable import StudyForge

/// Pinned so an interval is an exact date instead of "about a day after the test happened to run".
private let pinnedNow = Date(timeIntervalSince1970: 1_760_000_000)

@Suite("Recall session (F17)")
@MainActor
struct RecallSessionViewModelTests {

    // MARK: Fixtures

    private func card(
        id: String,
        sr: SpacedRepetitionState = SpacedRepetitionState(),
        pages: [Int] = [12]
    ) -> Flashcard {
        Flashcard(
            id: id,
            front: "Question \(id)",
            back: "Answer \(id)",
            provenance: AIProvenance(materialId: "m", pageNumbers: pages, confidence: .high),
            sr: sr
        )
    }

    private func deck(id: String = "d1", title: String = "Biology", cards: [Flashcard]) -> Deck {
        Deck(id: id, title: title, cards: cards)
    }

    /// Builds a sitting over one deck, with the store seeded so a rating has somewhere to land.
    ///
    /// `states` and `steps` line up by position / card id with `cards`, which is what lets a test say
    /// "this card is half-way up the ladder" without a builder round trip.
    private func makeSession(
        cards: [Flashcard],
        states: [RecallCardState]? = nil,
        steps: [String: Int] = [:],
        settings: RecallSettings = .default
    ) -> (RecallSessionViewModel, InMemoryDeckStore) {
        let builtDeck = deck(cards: cards)
        let store = InMemoryDeckStore(seededWith: [builtDeck])
        let stateList = states ?? Array(repeating: .new, count: cards.count)

        let items = cards.enumerated().map { index, card in
            RecallQueueItem(
                id: card.id,
                deckId: builtDeck.id,
                deckTitle: builtDeck.title,
                card: card,
                state: stateList[index],
                learningStep: steps[card.id]
            )
        }

        let viewModel = RecallSessionViewModel(
            items: items,
            decks: [builtDeck],
            store: store,
            settings: settings,
            learningSteps: steps,
            now: { pinnedNow }
        )
        return (viewModel, store)
    }

    /// A card that graduated and came due yesterday: SM-2's turn, not the ladder's.
    private func reviewState() -> SpacedRepetitionState {
        SpacedRepetitionState(
            interval: 6,
            dueAt: pinnedNow.addingTimeInterval(-86_400),
            reps: 3
        )
    }

    // MARK: Showing a card

    @Test("The question is shown first, and reveal shows the answer")
    func frontThenBack() {
        let (viewModel, _) = makeSession(cards: [card(id: "c1")])

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.currentCard?.front == "Question c1")
        #expect(viewModel.deckTitle == "Biology")
        #expect(viewModel.stateChip == .new)
        #expect(viewModel.citationLabel == "p.12")
        #expect(viewModel.isShowingAnswer == false)

        viewModel.reveal()

        #expect(viewModel.isShowingAnswer)
        #expect(viewModel.currentCard?.back == "Answer c1")
        #expect(viewModel.currentCard?.id == "c1", "revealing must not skip the card")
    }

    @Test("A new card enters the learning steps instead of being scheduled for tomorrow")
    func newCardEntersSteps() async throws {
        let (viewModel, store) = makeSession(cards: [card(id: "c1")])

        await viewModel.rate(.good)

        #expect(viewModel.phase == .reviewing, "two default steps, so Good cannot graduate yet")
        #expect(viewModel.learningSteps["c1"] == 1)
        #expect(viewModel.stateChip == .learning)
        #expect(viewModel.currentCard?.id == "c1")

        let saved = try await store.deck(id: "d1")
        #expect(saved?.cards.first?.sr.interval == 0, "SM-2 is untouched while the card is learning")
        #expect(saved?.cards.first?.sr.reps == 0)
    }

    // MARK: The ladder

    @Test("The two-step ladder graduates a card and writes it back")
    func ladderGraduates() async throws {
        let (viewModel, store) = makeSession(
            cards: [card(id: "c1")],
            states: [.learning],
            steps: ["c1": 0]
        )

        await viewModel.rate(.hard)
        #expect(viewModel.learningSteps["c1"] == 0, "Hard repeats the step")
        #expect(viewModel.remainingCount == 1)
        #expect(viewModel.phase == .reviewing)

        await viewModel.rate(.good)
        #expect(viewModel.learningSteps["c1"] == 1)
        #expect(viewModel.phase == .reviewing)

        await viewModel.rate(.good)
        #expect(viewModel.phase == .summary)
        #expect(viewModel.learningSteps["c1"] == nil)
        #expect(viewModel.graduatedCount == 1)
        #expect(viewModel.answeredCount == 3)

        let saved = try await store.deck(id: "d1")
        let graduated = try #require(saved?.cards.first?.sr)
        #expect(graduated.interval == 1)
        #expect(graduated.reps == 1)
        #expect(graduated.dueAt == SpacedRepetition.dueDate(days: 1, from: pinnedNow))
    }

    @Test("Easy graduates at the learner's interval, not at the engine's one day")
    func easyGraduationUsesSettings() async throws {
        var settings = RecallSettings.default
        settings.graduatingIntervalDays = 4
        let (viewModel, store) = makeSession(cards: [card(id: "c1")], settings: settings)

        await viewModel.rate(.easy)

        #expect(viewModel.phase == .summary)
        let saved = try await store.deck(id: "d1")
        let graduated = try #require(saved?.cards.first?.sr)
        #expect(graduated.interval == 4, "nextState would have written 1")
        #expect(graduated.dueAt == SpacedRepetition.dueDate(days: 4, from: pinnedNow))
        #expect(graduated.reps == 1, "graduated, not still new")
    }

    @Test("The learning steps never touch the ease factor")
    func stepsLeaveEaseAlone() async throws {
        let ease = SpacedRepetitionState().ease
        let (viewModel, store) = makeSession(cards: [card(id: "c1")])

        await viewModel.rate(.again)
        await viewModel.rate(.hard)
        await viewModel.rate(.good)

        let saved = try await store.deck(id: "d1")
        #expect(saved?.cards.first?.sr.ease == ease)
    }

    // MARK: Reviews

    @Test("A graduated review is rescheduled by the SM-2 engine, field for field")
    func reviewUsesScheduler() async throws {
        let before = reviewState()
        let (viewModel, store) = makeSession(cards: [card(id: "c1", sr: before)], states: [.young])

        await viewModel.rate(.good)

        let saved = try await store.deck(id: "d1")
        let after = try #require(saved?.cards.first?.sr)
        #expect(after == SpacedRepetition.nextState(before, rating: .good, now: pinnedNow))
        #expect(viewModel.graduatedCount == 0, "a review is scheduled, not graduated")
        #expect(viewModel.phase == .summary)
    }

    @Test("Again on a review puts the card back through the steps in the same sitting")
    func againReentersSteps() async throws {
        let (viewModel, store) = makeSession(cards: [card(id: "c1", sr: reviewState())], states: [.young])

        await viewModel.rate(.again)

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.remainingCount == 1)
        #expect(viewModel.learningSteps["c1"] == 0)
        #expect(viewModel.stateChip == .learning)
        #expect(viewModel.againCount == 1)

        let lapsedDeck = try await store.deck(id: "d1")
        let lapsed = try #require(lapsedDeck?.cards.first?.sr)
        #expect(lapsed.lapses == 1)

        await viewModel.rate(.good)
        await viewModel.rate(.good)

        #expect(viewModel.phase == .summary)
        let relearnedDeck = try await store.deck(id: "d1")
        let relearned = try #require(relearnedDeck?.cards.first?.sr)
        #expect(relearned.interval == 1)
    }

    // MARK: Progress

    @Test("Progress counts finished cards, not answers, and never runs ahead of the sitting")
    func progressCountsFinishedCards() async {
        let (viewModel, _) = makeSession(
            cards: [card(id: "c1"), card(id: "c2"), card(id: "c3")],
            states: [.learning, .new, .new],
            steps: ["c1": 0]
        )
        #expect(viewModel.total == 3)

        await viewModel.rate(.hard) // c1 stays, moves to the back

        #expect(viewModel.answeredCount == 1)
        #expect(viewModel.completedCount == 0, "an answer is not a finished card")
        #expect(viewModel.progressFraction == 0)
        #expect(viewModel.currentCard?.id == "c2")

        await viewModel.rate(.easy) // c2 graduates

        #expect(viewModel.completedCount == 1)
        #expect(viewModel.progressFraction == 1.0 / 3.0)
        #expect(viewModel.total == 3)
    }

    @Test("A card that keeps coming back does not change the sitting's size")
    func totalsStayStable() async {
        let (viewModel, _) = makeSession(cards: [card(id: "c1")])

        for _ in 0..<5 {
            await viewModel.rate(.again)
        }

        #expect(viewModel.total == 1)
        #expect(viewModel.remainingCount == 1)
        #expect(viewModel.completedCount == 0)
        #expect(viewModel.againCount == 5)
        #expect(viewModel.answeredCount == 5)
        #expect(viewModel.phase == .reviewing)
    }

    // MARK: Shrinking underneath the learner

    @Test("A card deleted elsewhere mid-sitting is dropped, and the sitting still finishes")
    func cardDeletedMidSession() async {
        let (viewModel, _) = makeSession(cards: [card(id: "c1"), card(id: "c2")])

        await viewModel.rate(.easy) // c1 graduates, c2 is on screen
        #expect(viewModel.completedCount == 1)
        #expect(viewModel.currentCard?.id == "c2")

        let withoutC2 = deck(cards: [card(id: "c1")])
        viewModel.refresh(decks: [withoutC2])

        #expect(viewModel.remainingCount == 0)
        #expect(viewModel.phase == .summary)
        #expect(viewModel.total == 1, "the deleted card must not stay in the denominator")
        #expect(viewModel.completedCount == 1)
    }

    @Test("A card deleted mid-sitting does not hand its revealed answer to the next card")
    func deletionClearsReveal() {
        let (viewModel, _) = makeSession(cards: [card(id: "c1"), card(id: "c2")])
        viewModel.reveal()

        viewModel.refresh(decks: [deck(cards: [card(id: "c2")])])

        #expect(viewModel.currentCard?.id == "c2")
        #expect(viewModel.isShowingAnswer == false)
    }

    @Test("Changing settings mid-sitting leaves the answer being read on screen")
    func settingsChangeKeepsReveal() {
        let (viewModel, _) = makeSession(cards: [card(id: "c1"), card(id: "c2")])
        viewModel.reveal()

        viewModel.update(settings: .default)

        #expect(viewModel.currentCard?.id == "c1")
        #expect(viewModel.isShowingAnswer)
    }

    @Test("Tightening the new-card ceiling mid-sitting defers the cards not yet seen")
    func tightenedCeilingDefers() async {
        let (viewModel, _) = makeSession(cards: [card(id: "c1"), card(id: "c2"), card(id: "c3")])

        var tighter = RecallSettings.default
        tighter.newCardsPerDay = 1
        viewModel.update(settings: tighter)

        #expect(viewModel.remainingCount == 1)
        #expect(viewModel.deferredCount == 2, "deferred, and said so")
        #expect(viewModel.total == 1, "the sitting is now the one card it may still ask")
        #expect(viewModel.completedCount == 0)
        #expect(viewModel.phase == .reviewing)
    }

    @Test("A failed save keeps the answer, reports the error, and writes nothing")
    func failedSaveIsReported() async throws {
        let (viewModel, store) = makeSession(cards: [card(id: "c1")])
        await store.forceFailure(.storageFailed)

        await viewModel.rate(.easy)

        #expect(viewModel.phase == .summary, "the learner's answer is not thrown away")
        #expect(viewModel.completedCount == 1)
        #expect(viewModel.error == DeckError.storageFailed.asAppError)

        await store.forceFailure(nil)
        let saved = try await store.deck(id: "d1")
        #expect(saved?.cards.first?.sr.reps == 0, "nothing reached the store")
    }

    @Test("An empty queue is empty, and rating it does nothing")
    func emptySitting() async {
        let (viewModel, _) = makeSession(cards: [])

        #expect(viewModel.phase == .empty)
        #expect(viewModel.currentCard == nil)
        #expect(viewModel.citationLabel == nil)
        #expect(viewModel.preview(for: .good) == nil)
        #expect(viewModel.progressFraction == 0)

        await viewModel.rate(.good)

        #expect(viewModel.answeredCount == 0)
        #expect(viewModel.phase == .empty)
    }

    // MARK: Rating hints

    @Test("The rating hints name the step or the interval the engine would write")
    func previews() {
        let (viewModel, _) = makeSession(cards: [card(id: "c1")])

let hardPreview = RecallSessionViewModel.RatingPreview(
staysInSteps: true,
stepMinutes: 1,
intervalDays: nil
)
 
let goodPreview = RecallSessionViewModel.RatingPreview(
staysInSteps: true,
stepMinutes: 10,
intervalDays: nil
)
 
let easyPreview = RecallSessionViewModel.RatingPreview(
staysInSteps: false,
stepMinutes: nil,
intervalDays: 1
)
 
#expect(viewModel.preview(for: .hard) == hardPreview)
#expect(viewModel.preview(for: .good) == goodPreview)
#expect(viewModel.preview(for: .easy) == easyPreview)

        let review = reviewState()
        let (reviewSession, _) = makeSession(cards: [card(id: "c2", sr: review)], states: [.young])

        #expect(
            reviewSession.preview(for: .good)?.intervalDays
                == SpacedRepetition.nextState(review, rating: .good, now: pinnedNow).interval
        )
        #expect(reviewSession.preview(for: .again)?.staysInSteps == true)
        #expect(reviewSession.preview(for: .again)?.stepMinutes == 1)
    }
}
