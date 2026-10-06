//
//  CoachHomeViewModel.swift
//  StudyForge
//
//  F15 — H01 (`73_Coach_Home_{M2}`): the ask bar, the suggestions, the library scope and the
//  student's conversations.
//

import Foundation

@MainActor
@Observable
final class CoachHomeViewModel {

    private(set) var state: LoadState<[CoachThread]> = .idle
    private(set) var materials: [Material] = []
    private(set) var error: AppError?

    /// H01's ask bar.
    var askText = ""

    private let store: any CoachStore
    private let materialStore: any MaterialStore
    private let service: CoachService

    init(store: any CoachStore, materials: any MaterialStore, service: CoachService) {
        self.store = store
        self.materialStore = materials
        self.service = service
    }

    // MARK: Derived

    var threads: [CoachThread] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var hasLibrary: Bool { !materials.isEmpty }

    var canAsk: Bool {
        !askText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// H01's library-scope chip. Empty scope means the whole library, so the chip says so rather
    /// than showing "0".
    var scopeLabel: String {
        materials.isEmpty
            ? L10n.coachScopeAll.string
            : L10n.coachScopeAll.string + " · \(materials.count)"
    }

    var suggestions: [String] {
        [
            L10n.coachSuggestionExplain.string,
            L10n.coachSuggestionQuiz.string,
            L10n.coachSuggestionCompare.string,
        ]
    }

    // MARK: Copy

    var title: String { L10n.coachTitle.string }
    var subtitle: String { L10n.coachHomeSubtitle.string }
    var askPlaceholder: String { L10n.coachAskPlaceholder.string }
    var askTitle: String { L10n.coachAsk.string }
    var emptyTitle: String { L10n.coachEmptyTitle.string }
    var emptyBody: String { L10n.coachEmptyBody.string }
    var newThreadTitle: String { L10n.coachNewThread.string }
    var pathTitle: String { L10n.coachPathTitle.string }

    // MARK: Actions

    /// Loads the conversations and rebuilds the retrieval index.
    ///
    /// The re-index happens here rather than per question: embedding a whole library on every
    /// keystroke would make the ask bar feel broken, and a student who has just imported a
    /// material expects it to be searchable on the next screen.
    func load() async {
        state = .loading
        do {
            materials = (try? await materialStore.all()) ?? []
            await service.reindex()
            state = .from(try await store.threads())
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Creates an empty conversation for a question, and returns it so the caller can push the chat.
    func startThread(question: String) -> CoachThread {
        CoachThread(title: "", messages: [], scope: [])
    }

    func delete(_ thread: CoachThread) async {
        do {
            try await store.deleteThread(id: thread.id)
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }
}
