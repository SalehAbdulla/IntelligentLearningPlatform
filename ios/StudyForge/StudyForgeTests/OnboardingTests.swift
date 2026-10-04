//
//  OnboardingTests.swift
//  StudyForgeTests
//
//  Tests for the onboarding pager (A02–A04).
//
//  The behaviour worth pinning down is the difference between the two ways a user can move:
//  the next button can FINISH onboarding, a swipe can only change page. Get that wrong and
//  the screen dismisses itself the moment someone swipes onto the last slide — before they
//  have answered the "Get started" prompt.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Onboarding pager")
@MainActor
struct OnboardingViewModelTests {

    private func model(
        startingAt page: OnboardingPage = .valueProp
    ) -> (OnboardingViewModel, InMemoryOnboardingStore) {
        let store = InMemoryOnboardingStore()
        return (OnboardingViewModel(store: store, startingPage: page), store)
    }

    @Test("There are exactly three slides, in order, with contiguous raw values")
    func threeSlidesInOrder() {
        #expect(OnboardingPage.count == 3)
        #expect(OnboardingPage.allCases.map(\.position) == [1, 2, 3])
        // Raw values drive the TabView tags, so a gap would break swipe selection in a way
        // no compiler check would catch.
        #expect(OnboardingPage.allCases.map(\.rawValue) == [0, 1, 2])
    }

    @Test("Only the last slide reports itself as last")
    func onlyTheLastSlideIsLast() {
        #expect(OnboardingPage.valueProp.isLast == false)
        #expect(OnboardingPage.howItWorks.isLast == false)
        #expect(OnboardingPage.privacy.isLast)
    }

    @Test("The button advances one slide at a time without completing")
    func buttonAdvances() {
        let (viewModel, store) = model()

        viewModel.advance()
        #expect(viewModel.index == 1)
        #expect(viewModel.isFinished == false)
        #expect(store.hasCompletedOnboarding == false, "mid-flow must not record completion")

        viewModel.advance()
        #expect(viewModel.index == 2)
        #expect(viewModel.isFinished == false)
    }

    @Test("Advancing past the last slide completes onboarding and persists it")
    func advancingPastTheEndCompletes() {
        let (viewModel, store) = model(startingAt: .privacy)

        viewModel.advance()

        #expect(viewModel.isFinished)
        #expect(viewModel.index == 2, "completing must not walk off the end of the pages")
        #expect(store.hasCompletedOnboarding)
    }

    @Test("Skipping completes onboarding — it is not a deferral")
    func skippingCompletes() {
        // A user who skips has made a decision. Re-showing the pager next launch punishes
        // them for it, so the flag is set on both routes.
        let (viewModel, store) = model()

        viewModel.skip()

        #expect(viewModel.isFinished)
        #expect(store.hasCompletedOnboarding)
    }

    @Test("Swiping onto the last slide does NOT complete onboarding")
    func swipingOntoTheLastSlideDoesNotComplete() {
        // The regression this test exists for. Swiping is navigation; only the button
        // answers the prompt.
        let (viewModel, store) = model()

        viewModel.didSwipe(to: 2)

        #expect(viewModel.index == 2)
        #expect(viewModel.isFinished == false)
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test("A swipe beyond either end is clamped rather than crashing")
    func swipesAreClamped() {
        // The index is also driven by a gesture, so it cannot be trusted to be in range.
        let (viewModel, _) = model()

        viewModel.didSwipe(to: 99)
        #expect(viewModel.index == OnboardingPage.count - 1)

        viewModel.didSwipe(to: -5)
        #expect(viewModel.index == 0)
    }

    @Test("Selecting a page jumps straight to it")
    func selectingJumps() {
        let (viewModel, _) = model()

        viewModel.select(.howItWorks)
        #expect(viewModel.index == 1)

        viewModel.select(.valueProp)
        #expect(viewModel.index == 0)
    }

    @Test("An already-finished pager ignores further input")
    func finishedPagerIgnoresInput() {
        // `onFinish` is called from `onChange`, so there is a frame where the view is still
        // mounted. Input in that window must not undo the completion.
        let (viewModel, store) = model()

        viewModel.skip()
        #expect(viewModel.isFinished)

        viewModel.advance()
        viewModel.didSwipe(to: 0)
        viewModel.select(.privacy)

        #expect(viewModel.isFinished)
        #expect(viewModel.index == 0, "the index should not have moved")
        #expect(store.hasCompletedOnboarding)
    }

    @Test("The pager opens on the requested slide")
    func startingPageIsHonoured() {
        let (viewModel, _) = model(startingAt: .privacy)
        #expect(viewModel.index == 2)
        #expect(viewModel.isOnLastPage)
    }

    @Test("The indicator reports 1-based positions and the real page count")
    func indicatorPositions() {
        let (viewModel, _) = model()

        #expect(viewModel.position == 1)
        #expect(viewModel.pageCount == 3)

        viewModel.advance()
        #expect(viewModel.position == 2)
    }
}
