//
//  RecallSpaceViewModelTests.swift
//  StudyForgeTests
//
//  Tests for F17's Recall Space entry point: the store that holds a learner's options, and the
//  view model that turns "every deck" into one due-today queue.
//
//  THE TEST THAT MATTERS MOST is `gathersAcrossDecks`: a queue that only ever saw one deck would
//  look right on a single-deck account while being a duplicate of F04 rather than a study space.
//  The rest cover the empty states, the ceilings and the rollback on a failed save — all of which
//  are silent when wrong.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Store

@Suite("Recall settings store (F17)")
struct RecallSettingsStoreTests {

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("recall-settings-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private var custom: RecallSettings {
        RecallSettings(
            learningStepMinutes: [1, 5, 10],
            newCardsPerDay: 12,
            maxReviewsPerDay: 80,
            graduatingIntervalDays: 2,
            matureAfterDays: 14
        )
    }

    @Test("A learner who has never saved anything gets the defaults, not an error")
    func missingFileIsDefaults() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try await FileRecallSettingsStore(directory: directory).settings() == .default)
    }

    @Test("The options survive a file round-trip, read back by a second instance")
    func fileRoundTrip() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileRecallSettingsStore(directory: directory).save(custom)

        // A fresh instance, so the assertion reads the file rather than the first store's cache.
        #expect(try await FileRecallSettingsStore(directory: directory).settings() == custom)
    }

    @Test("A corrupt file is a storage failure, not a silent reset to the defaults")
    func corruptFileFails() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("this is not json".utf8)
            .write(to: directory.appendingPathComponent("recallSettings.json"))

        await #expect(throws: RecallSettingsError.storageFailed) {
            try await FileRecallSettingsStore(directory: directory).settings()
        }
    }

    @Test("What is saved is already clamped, so a hand-edited document cannot break the ladder")
    func savedValuesAreClamped() async throws {
        let store = InMemoryRecallSettingsStore()
        try await store.save(RecallSettings(learningStepMinutes: [], newCardsPerDay: -5))
        let saved = try await store.settings()

        #expect(saved.learningStepMinutes == [1, 10])
        #expect(saved.newCardsPerDay == 0)
    }

    // MARK: Reading an untrusted document

    @Test("A hand-edited document cannot hand a negative ceiling to the queue")
    func handEditedDocumentIsClamped() throws {
        // Not a cosmetic check. `RecallQueueBuilder` calls `prefix(settings.maxReviewsPerDay)`,
        // and `prefix(_:)` traps on a negative length, so this value has to be clamped on the way
        // in — an unclamped -1 is a crash on the Recall Space, not a wrong number on it.
        let hostile = """
        {
          "learningStepMinutes": [-5, 0],
          "newCardsPerDay": -3,
          "maxReviewsPerDay": -1,
          "graduatingIntervalDays": 0,
          "matureAfterDays": -30
        }
        """

        let decoded = try JSONDecoder().decode(RecallSettings.self, from: Data(hostile.utf8))

        #expect(decoded.learningStepMinutes == [1, 10], "a negative ladder falls back to Anki's")
        #expect(decoded.newCardsPerDay == 0)
        #expect(decoded.maxReviewsPerDay == 0)
        #expect(decoded.graduatingIntervalDays == 1, "graduation is always at least a day")
        #expect(decoded.matureAfterDays == 1, "maturity can never sit below the graduating interval")
    }

    @Test("A document that predates a field keeps that field's default")
    func missingFieldFallsBackToDefault() throws {
        // An older build wrote fewer fields. Failing the whole read would turn a routine upgrade
        // into an error state, so the absent field takes its default instead.
        let partial = """
        { "newCardsPerDay": 5 }
        """

        let decoded = try JSONDecoder().decode(RecallSettings.self, from: Data(partial.utf8))

        #expect(decoded.newCardsPerDay == 5)
        #expect(decoded.learningStepMinutes == [1, 10])
        #expect(decoded.maxReviewsPerDay == 200)
    }

    @Test("A complete round-trip is unchanged by the clamping, field for field")
    func roundTripPreservesEveryField() throws {
        // The guard against the custom decode silently dropping or renaming a field: encode what
        // the settings screen saved, read it back, and demand the identical value.
        let encoded = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(RecallSettings.self, from: encoded)

        #expect(decoded == custom)
    }

    @Test("A hostile file read back through the store is clamped, not rejected")
    func hostileFileIsClampedOnRead() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{ "maxReviewsPerDay": -1 }"#.utf8)
            .write(to: directory.appendingPathComponent("recallSettings.json"))

        let settings = try await FileRecallSettingsStore(directory: directory).settings()

        #expect(settings.maxReviewsPerDay == 0)
        #expect(settings.newCardsPerDay == 20, "a field the document omits keeps its default")
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryRecallSettingsStore()
        await store.forceFailure(.storageFailed)

        await #expect(throws: RecallSettingsError.self) {
            try await store.settings()
        }
    }

    @Test("A settings failure maps to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(
            RecallSettingsError.storageFailed.asAppError
                == AppError.server(reference: "recall-settings-store-failed")
        )
    }
}

// MARK: - View model

/// Wraps the in-memory store and counts `all()` reads, so a test can prove the scope filter
/// rebuilds the queue instead of going back to the store.
private actor CountingDeckStore: DeckStore {

    private let inner: InMemoryDeckStore
    private var readCount = 0

    init(seededWith decks: [Deck] = []) {
        self.inner = InMemoryDeckStore(seededWith: decks)
    }

    func all() async throws -> [Deck] {
        readCount += 1
        return try await inner.all()
    }

    func deck(id: String) async throws -> Deck? { try await inner.deck(id: id) }
    func add(_ deck: Deck) async throws { try await inner.add(deck) }
    func delete(id: String) async throws { try await inner.delete(id: id) }

    func reads() -> Int { readCount }
}

@Suite("Recall space (F17)")
@MainActor
struct RecallSpaceViewModelTests {

    private let now = Date(timeIntervalSince1970: 2_000_000)

    // MARK: Fixtures

    private func card(_ id: String, sr: SpacedRepetitionState) -> Flashcard {
        Flashcard(
            id: id,
            front: "front \(id)",
            back: "back \(id)",
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high),
            sr: sr
        )
    }

    /// A card that has never been reviewed — Anki's "new".
    private func newCard(_ id: String) -> Flashcard {
        card(id, sr: SpacedRepetitionState(ease: 2.5, interval: 0, dueAt: now, reps: 0, lapses: 0))
    }

    /// A graduated card, due at `dueAt`, with the given interval in days.
    private func reviewCard(_ id: String, interval: Int, dueAt: Date) -> Flashcard {
        card(id, sr: SpacedRepetitionState(ease: 2.5, interval: interval, dueAt: dueAt,
                                           reps: 3, lapses: 0))
    }

    private func deck(_ id: String, _ title: String, _ cards: [Flashcard]) -> Deck {
        Deck(id: id, title: title, cards: cards)
    }

    private func makeViewModel(
        decks: [Deck],
        settings: RecallSettings = .default
    ) -> (RecallSpaceViewModel, InMemoryDeckStore, InMemoryRecallSettingsStore) {
        let fixedNow = now
        let deckStore = InMemoryDeckStore(seededWith: decks)
        let settingsStore = InMemoryRecallSettingsStore(seededWith: settings)
        let viewModel = RecallSpaceViewModel(
            deckStore: deckStore,
            settingsStore: settingsStore,
            now: { fixedNow }
        )
        return (viewModel, deckStore, settingsStore)
    }

    // MARK: The headline behaviour

    @Test("The space gathers due cards from MORE THAN ONE deck")
    func gathersAcrossDecks() async {
        let (viewModel, _, _) = makeViewModel(decks: [
            deck("d1", "Chemistry", [newCard("c1"), newCard("c2")]),
            deck("d2", "Biology", [reviewCard("r1", interval: 6, dueAt: now)])
        ])

        await viewModel.load()

        #expect(viewModel.dueTotal == 3)
        #expect(Set(viewModel.items.map(\.deckId)) == ["d1", "d2"])
        #expect(viewModel.count(of: .new) == 2)
        #expect(viewModel.count(of: .young) == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    // MARK: Empty states

    @Test("Nothing due is an empty state that still names the next due card")
    func nothingDueNamesTheNextCard() async {
        let tomorrow = now.addingTimeInterval(86_400)
        let inThreeDays = now.addingTimeInterval(86_400 * 3)
        let (viewModel, _, _) = makeViewModel(decks: [
            deck("d1", "Chemistry", [reviewCard("c1", interval: 6, dueAt: inThreeDays)]),
            deck("d2", "Biology", [reviewCard("c2", interval: 6, dueAt: tomorrow)])
        ])

        await viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.dueTotal == 0)
        #expect(viewModel.nextDueAt == tomorrow)
        #expect(viewModel.hasAnyCards)
    }

    @Test("A learner with no cards is a different empty state from an all-caught-up one")
    func noCardsIsNotAllCaughtUp() async {
        let (viewModel, _, _) = makeViewModel(decks: [deck("d1", "Empty", [])])

        await viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.hasAnyCards == false)
        #expect(viewModel.nextDueAt == nil)
        #expect(viewModel.deferredByLimit == 0)
    }

    // MARK: Ceilings and scoping

    @Test("The daily new-card ceiling defers the rest, and the count is reported")
    func ceilingDefersTheRest() async {
        let (viewModel, _, _) = makeViewModel(
            decks: [deck("d1", "Chemistry", (1...3).map { newCard("c\($0)") })],
            settings: RecallSettings(newCardsPerDay: 1)
        )

        await viewModel.load()

        #expect(viewModel.dueTotal == 1)
        #expect(viewModel.deferredByLimit == 2)
        #expect(viewModel.count(of: .new) == 1)
    }

    @Test("Scoping to one deck re-builds the queue without another store read")
    func scopingDoesNotReReadTheStore() async {
        let fixedNow = now
        let deckStore = CountingDeckStore(seededWith: [
            deck("d1", "Chemistry", [newCard("c1")]),
            deck("d2", "Biology", [newCard("c2")])
        ])
        let viewModel = RecallSpaceViewModel(
            deckStore: deckStore,
            settingsStore: InMemoryRecallSettingsStore(),
            now: { fixedNow }
        )

        await viewModel.load()
        let readsAfterLoad = await deckStore.reads()
        #expect(viewModel.items.count == 2)
        #expect(readsAfterLoad == 1)

        viewModel.selectDeck("d2")
        let readsAfterFilter = await deckStore.reads()
        #expect(viewModel.items.map(\.id) == ["c2"])
        #expect(readsAfterFilter == 1, "the filter is applied to the decks already in memory")

        viewModel.selectDeck(nil)
        #expect(viewModel.items.count == 2)
    }

    // MARK: Session hand-off

    @Test("A card inside a learning step comes first, ahead of new cards")
    func learningStepsComeFirst() async {
        let (viewModel, _, _) = makeViewModel(
            decks: [deck("d1", "Chemistry", [newCard("new-1"), newCard("learning-1")])]
        )
        viewModel.setLearningSteps(["learning-1": 1])

        await viewModel.load()

        #expect(viewModel.items.first?.id == "learning-1")
        #expect(viewModel.count(of: .learning) == 1)
        #expect(viewModel.count(of: .new) == 1)
    }

    // MARK: Settings

    @Test("Saving a tighter ceiling rebuilds the queue and persists the choice")
    func savingSettingsRebuilds() async {
        let (viewModel, _, settingsStore) = makeViewModel(
            decks: [deck("d1", "Chemistry", [newCard("c1"), newCard("c2")])]
        )
        await viewModel.load()
        #expect(viewModel.dueTotal == 2)

        await viewModel.saveSettings(RecallSettings(newCardsPerDay: 0))
        let persisted = try? await settingsStore.settings()

        #expect(viewModel.dueTotal == 0)
        #expect(viewModel.isEmpty)
        #expect(viewModel.deferredByLimit == 2, "both cards are reported rather than forgotten")
        #expect(persisted?.newCardsPerDay == 0)
    }

    @Test("A failed save restores the previous options and shows the error")
    func failedSaveRollsBack() async {
        let (viewModel, _, settingsStore) = makeViewModel(
            decks: [deck("d1", "Chemistry", [newCard("c1")])]
        )
        await viewModel.load()
        await settingsStore.forceFailure(.storageFailed)

        await viewModel.saveSettings(RecallSettings(newCardsPerDay: 0))

        #expect(viewModel.settings == .default)
        #expect(viewModel.error == AppError.server(reference: "recall-settings-store-failed"))
        #expect(viewModel.dueTotal == 1, "the queue is untouched by the failed save")
    }

    @Test("A deck-store failure becomes the app's own error, not a raw throw")
    func deckFailureMapsToAppError() async {
        let fixedNow = now
        let deckStore = InMemoryDeckStore()
        await deckStore.forceFailure(.storageFailed)
        let viewModel = RecallSpaceViewModel(
            deckStore: deckStore,
            settingsStore: InMemoryRecallSettingsStore(),
            now: { fixedNow }
        )

        await viewModel.load()

        #expect(viewModel.error == AppError.server(reference: "deck-store-failed"))
        #expect(viewModel.items.isEmpty)
    }
}


