//
//  OnboardingViewModel.swift
//  StudyForge
//
//  Pager state for A02–A04.
//
//  The rules worth knowing:
//   · **Skip completes.** Skipping is not the same as "not yet" — a user who skips has
//     made a decision, and showing them the pager again on the next launch punishes them
//     for it. Both paths set the flag.
//   · **`advance()` on the last page completes.** This means the pager cannot get stuck
//     one page short, where the only way forward is Skip.
//   · **Bounds are clamped.** The page index can be moved by a swipe gesture as well as by
//     the button, and a swipe past the end must not index out of bounds.
//

import Foundation

@MainActor
@Observable
final class OnboardingViewModel {

    /// The slide currently on screen.
    private(set) var index = 0

    /// Set when onboarding is finished, so the caller can advance the flow.
    private(set) var isFinished = false

    private let store: any OnboardingStore

    /// - Parameter startingPage: where the pager opens. Defaults to the first slide;
    ///   overridden in DEBUG from a launch argument so a specific slide can be shown
    ///   without swiping (see `RootView`).
    init(store: any OnboardingStore, startingPage: OnboardingPage = .valueProp) {
        self.store = store
        self.index = startingPage.rawValue
    }

    // MARK: Derived state

    var page: OnboardingPage { OnboardingPage.allCases[index] }

    /// Drives "Primary" → "Get started" on the final slide.
    var isOnLastPage: Bool { page.isLast }

    /// Position for the page indicator.
    var position: Int { page.position }

    var pageCount: Int { OnboardingPage.count }

    /// The primary button's label — the last slide invites the user in rather than
    /// nudging them along.
    var primaryTitle: String {
        L10n.onboardingNext.string
    }

    var skipTitle: String { L10n.onboardingSkip.string }

    // MARK: Actions

    /// Moves forward, completing onboarding if this was the last page.
    func advance() {
        guard !isFinished else { return }

        if index == OnboardingPage.count - 1 {
            complete()
        } else {
            index += 1
        }
    }

    /// Jumps to a page. Used by the page dots.
    func select(_ page: OnboardingPage) {
        guard !isFinished else { return }
        index = page.rawValue
    }

    /// Records the page the user swiped to, clamped to the valid range.
    ///
    /// A swipe is not a completion: swiping *onto* the last page should not finish
    /// onboarding, because the user has not yet answered the "Get started" prompt.
    func didSwipe(to rawIndex: Int) {
        guard !isFinished else { return }
        index = min(max(rawIndex, 0), OnboardingPage.count - 1)
    }

    /// Finishes onboarding without advancing to a next page.
    func skip() {
        complete()
    }

    // MARK: Completion

    private func complete() {
        store.markCompleted()
        isFinished = true
    }
}
