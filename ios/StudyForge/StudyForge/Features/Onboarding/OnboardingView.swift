//
//  OnboardingView.swift
//  StudyForge
//
//  A02–A04 — the three-slide onboarding pager (docs/03 §A, all P0).
//
//  A swipe and a button are different gestures with different meanings, which is the one
//  subtle thing here:
//   · The **button** advances, and on the last page it FINISHES onboarding.
//   · A **swipe** only changes page. Swiping onto the last slide must not complete
//     onboarding, because the user has not yet answered the "Get started" prompt — the
//     screen would dismiss itself out from under their thumb.
//   `viewModel.didSwipe(to:)` enforces that, so the TabView selection is bound through it
//  rather than to the index directly.
//
//  Skipping completes onboarding rather than deferring it: a user who skips has decided,
//  and showing them the pager again next launch punishes the decision.
//

import SwiftUI

// Accessibility: each page's heading reads as one element, the illustration is decorative and hidden, and
// Skip carries a hint about what it does.

struct OnboardingView: View {

    @State private var viewModel: OnboardingViewModel

    /// Raised when onboarding completes, by any route.
    let onFinish: () -> Void

    /// Mirrors `viewModel.index` so the TabView can drive and be driven. Writes go through
    /// `didSwipe` so a swipe cannot accidentally finish the flow.
    private var selection: Binding<Int> {
        Binding(
            get: { viewModel.index },
            set: { viewModel.didSwipe(to: $0) }
        )
    }

    init(
        store: any OnboardingStore,
        startingPage: OnboardingPage = .valueProp,
        onFinish: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OnboardingViewModel(store: store, startingPage: startingPage))
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: selection) {
                ForEach(OnboardingPage.allCases) { page in
                    pageContent(page)
                        .tag(page.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(ColorTokens.surface)
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { onFinish() }
        }
    }

    // MARK: Skip

    private var header: some View {
        HStack {
            Spacer(minLength: 0)

            Button(viewModel.skipTitle) {
                viewModel.skip()
            }
            .font(.sfCallout)
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(minHeight: Layout.minTouchTarget)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(L10n.onboardingSkipHint.string)
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.top, Spacing.s2)
    }

    // MARK: Page

    @ViewBuilder
    private func pageContent(_ page: OnboardingPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                Image(systemName: page.symbolName)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(ColorTokens.primary)
                    .accessibilityHidden(true) // decorative; the title carries the meaning

                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(page.title)
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.body)
                        .font(.sfBody)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                // A03 carries the pipeline diagram instead of a second paragraph.
                if page == .howItWorks {
                    SFPipelineDiagram(steps: PipelineStep.all)
                        .padding(.top, Spacing.s2)
                }

                // A04 carries its three guarantees as explicit claims rather than burying
                // them in prose — it is a trust screen.
                if page == .privacy {
                    privacyClaims
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.top, Spacing.s8)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var privacyClaims: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            claim(L10n.onboardingPrivacyOnDevice.string, symbol: "iphone")
            claim(L10n.onboardingPrivacyCloud.string, symbol: "cloud")
            claim(L10n.onboardingPrivacyTraining.string, symbol: "hand.raised.fill")
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.l))
    }

    private func claim(_ text: String, symbol: String) -> some View {
        Label {
            Text(text)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.onPrimaryContainer)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(ColorTokens.onPrimaryContainer)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: Spacing.s4) {
            SFPageDots(
                count: viewModel.pageCount,
                currentIndex: viewModel.index,
                onSelect: { viewModel.select(OnboardingPage.allCases[$0]) }
            )

            SFPrimaryButton(
                title: viewModel.isOnLastPage
                    ? L10n.onboardingGetStarted.string
                    : viewModel.primaryTitle,
                action: viewModel.advance
            )
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.bottom, Spacing.s6)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("A02–A04 Onboarding") {
    OnboardingView(store: InMemoryOnboardingStore(), onFinish: {})
}

#Preview("A02–A04 Onboarding — already completed") {
    OnboardingView(store: InMemoryOnboardingStore(hasCompletedOnboarding: true), onFinish: {})
}

