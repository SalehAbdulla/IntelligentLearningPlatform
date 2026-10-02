//
//  QuizListViewModel.swift
//  StudyForge
//
//  Presentation logic for F01 — the student's quiz history, read from the local store.
//

import Foundation

@MainActor
@Observable
final class QuizListViewModel {

    private(set) var state: LoadState<[Quiz]> = .idle

    private let store: any QuizStore

    init(store: any QuizStore) {
        self.store = store
    }

    // MARK: Derived

    var quizzes: [Quiz] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    // MARK: Copy

    var title: String { L10n.quizTitle.string }
    var emptyTitle: String { L10n.quizEmptyTitle.string }
    var emptyBody: String { L10n.quizEmptyBody.string }
    var retakeTitle: String { L10n.quizRetake.string }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let quizzes = try await store.all()
            state = quizzes.isEmpty ? .empty : .loaded(quizzes)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func delete(_ quiz: Quiz) async {
        do {
            try await store.delete(id: quiz.id)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
