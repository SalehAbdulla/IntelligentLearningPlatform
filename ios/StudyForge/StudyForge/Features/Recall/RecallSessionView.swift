//
//  RecallSessionView.swift
//  StudyForge
//
//  F17 — O02 `149_RecallSpace_Session_Front_{M5}` and O03 `150_RecallSpace_Session_Back_Rate_{M5}`
//  (docs/03 §O). The sitting: front, reveal, four ratings that each name the interval they would
//  write, then a summary.
//
//  WHY THIS IS NOT `FlashcardReviewView`
//  -------------------------------------
//  F04 reviews one deck and hands every rating straight to SM-2. A sitting in the Recall Space has
//  two schedulers — the learning steps answer "does this come back in a minute?", `SpacedRepetition`
//  answers "when, in days?" — so F17 has its own view model and its own screen. Reusing F04's would
//  have meant growing the steps inside M2's file.
//
//  WHY EACH BUTTON SHOWS ITS INTERVAL
//  ----------------------------------
//  On the answer face the learner is choosing between four futures, not four adjectives. "Again /
//  <1m" and "Easy / 4 d" say what the tap costs. The numbers come from
//  `RecallSessionViewModel.preview(for:)`, which is the same decision `rate(_:)` then applies — so
//  the button cannot advertise one interval and write another.
//
//  WHY THE CARD IS THE REVEAL CONTROL
//  ----------------------------------
//  Same affordance as F04, deliberately: a learner who has reviewed a deck already knows to tap the
//  card. The hint is a caption, and the card takes the button trait while the answer is hidden so a
//  screen reader user is told it is actionable rather than read a sentence and left to guess.
//
//  WHY THE SUMMARY COUNTS ANSWERS, NOT CARDS
//  -----------------------------------------
//  A card answered "Again" comes back in the same sitting. Counting cards would let the summary
//  report "3 cards" after nine taps, which is true of the queue and a lie about the work. The
//  reviewed figure is `answeredCount`; `completedCount` is what the progress bar uses, where cards
//  are the right unit.
//

import SwiftUI

struct RecallSessionView: View {

    @State private var viewModel: RecallSessionViewModel

    /// True while a rating is being written, so a double tap cannot schedule the same card twice.
    @State private var isRating = false

    @Environment(\.dismiss) private var dismiss

    /// Called with the learning steps still in progress when the sitting closes, so the Recall
    /// Space can put those cards back in its queue rather than forget them.
    private let onClose: (([String: Int]) -> Void)?

    init(
        items: [RecallQueueItem],
        decks: [Deck],
        store: any DeckStore,
        settings: RecallSettings,
        learningSteps: [String: Int] = [:],
        onClose: (([String: Int]) -> Void)? = nil
    ) {
        self.onClose = onClose
        _viewModel = State(initialValue: RecallSessionViewModel(
            items: items,
            decks: decks,
            store: store,
            settings: settings,
            learningSteps: learningSteps
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .reviewing: reviewing
                case .summary: summary
                case .empty: emptyState
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.deckTitle ?? L10n.flashcardReviewTitle.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // "Close with progress saved" (O02): every rating is already written, so
                    // closing only hands the in-progress steps back and dismisses.
                    Button(L10n.commonClose.string) { close() }
                }
            }
        }
    }

    private func close() {
        onClose?(viewModel.learningSteps)
        dismiss()

        // Best effort: a learner who closes without tapping "Try again" still gets one more attempt
        // at a write that failed. Fire-and-forget because the sheet is already dismissing and there
        // is nowhere left to report a second failure — but the card is still asked again next launch,
        // which is the honest state, and this can only improve on it.
        if !viewModel.unsavedDeckIds.isEmpty {
            Task { await viewModel.retryFailedSaves() }
        }
    }

    /// A failed write, with a retry that repeats the same save.
    ///
    /// The answer is already in the sitting's in-memory deck and the card has already moved on, so
    /// retrying never asks the learner to answer again — it only asks the store again. `recoverTitle`
    /// is supplied because `SFErrorBanner` draws no button unless the error advertises a recovery,
    /// and "try again" is always the right recovery for a storage fault.
    @ViewBuilder
    private var saveFailure: some View {
        if let error = viewModel.error {
            SFErrorBanner(
                error: error,
                onRecover: { Task { await viewModel.retryFailedSaves() } },
                recoverTitle: L10n.commonRetry.string
            )
        }
    }


    // MARK: Reviewing (O02)

    private var reviewing: some View {
        VStack(spacing: Spacing.s4) {
            ProgressView(value: viewModel.progressFraction)
                .tint(ColorTokens.primary)

            HStack(spacing: Spacing.s2) {
                Text(L10n.flashcardProgress.string(
                    min(viewModel.completedCount + 1, max(viewModel.total, 1)),
                    viewModel.total
                ))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

                Spacer(minLength: Spacing.s2)

                if let state = viewModel.stateChip {
                    // O02's state chip. The same `RecallCardState.title` O01 counts with, so the
                    // two screens cannot call one card two things.
                    Text(state.title)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: .capsule)
                }
            }

            saveFailure

            Spacer(minLength: 0)

            if let card = viewModel.currentCard {
                cardView(card)
            }

            Spacer(minLength: 0)

            if viewModel.isShowingAnswer {
                ratingButtons
            } else {
                Text(L10n.flashcardTapToReveal.string)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: The card

    private func cardView(_ card: Flashcard) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(viewModel.isShowingAnswer ? card.back : card.front)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.isShowingAnswer, let citation = viewModel.citationLabel {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "quote.opening")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.primary)
                        .accessibilityHidden(true)
                    Text(citation)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: .capsule)
                }
            }
        }
        .padding(Spacing.s5)
        .frame(maxWidth: .infinity)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(ColorTokens.outline, lineWidth: 1)
        }
        .contentShape(.rect)
        .onTapGesture {
            if !viewModel.isShowingAnswer { viewModel.reveal() }
        }
        // One element, so the prompt and its citation are read together. While the answer is hidden
        // the card is the reveal control, so it takes the button trait and says so.
        .accessibilityElement(children: .combine)
        .accessibilityHint(viewModel.isShowingAnswer ? "" : L10n.flashcardTapToReveal.string)
        .accessibilityAddTraits(viewModel.isShowingAnswer ? [] : .isButton)
    }

    // MARK: Rating (O03)

    private var ratingButtons: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.s2),
                GridItem(.flexible(), spacing: Spacing.s2),
            ],
            spacing: Spacing.s2
        ) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                ratingButton(rating)
            }
        }
        .disabled(isRating)
    }

    private func ratingButton(_ rating: ReviewRating) -> some View {
        let title = ratingTitle(rating)
        let interval = intervalLabel(for: rating)

        return Button {
            Task { await rate(rating) }
        } label: {
            VStack(spacing: Spacing.s1) {
                Text(title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(rating == .again ? ColorTokens.error : ColorTokens.textPrimary)

                // The future the tap buys, in the units the scheduler would write: minutes while
                // the card is learning, days once it has graduated.
                Text(interval)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s3)
            .frame(minHeight: Layout.minTouchTarget)
            .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.m))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(ColorTokens.outline, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // The label is the rating, the value is the interval it would set: "Good, 10 min".
        .accessibilityLabel(title)
        .accessibilityValue(interval)
    }

    private func rate(_ rating: ReviewRating) async {
        guard !isRating else { return }
        isRating = true
        defer { isRating = false }
        await viewModel.rate(rating)
    }

    private func ratingTitle(_ rating: ReviewRating) -> String {
        switch rating {
        case .again: L10n.flashcardRatingAgain.string
        case .hard: L10n.flashcardRatingHard.string
        case .good: L10n.flashcardRatingGood.string
        case .easy: L10n.flashcardRatingEasy.string
        }
    }

    /// What the button would schedule, from the view model's own preview — never a second copy of
    /// the maths, so the printed interval and the written one cannot drift.
    private func intervalLabel(for rating: ReviewRating) -> String {
        guard let preview = viewModel.preview(for: rating) else {
            return L10n.flashcardIntervalAgain.string
        }

        if preview.staysInSteps, let minutes = preview.stepMinutes {
            return L10n.quizMinutes.string(minutes)
        }

        if let days = preview.intervalDays {
            return days >= 30
                ? L10n.flashcardIntervalMonths.string(max(1, days / 30))
                : L10n.flashcardIntervalDays.string(days)
        }

        return L10n.flashcardIntervalAgain.string
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: Spacing.s6) {
            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.successText)
                .accessibilityHidden(true)

            Text(L10n.flashcardSessionTitle.string)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(spacing: Spacing.s2) {
                statRow(L10n.flashcardSessionReviewed.string, "\(viewModel.answeredCount)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))

            // The answers are kept, but the write failed. Saying so — with a retry — is the only
            // honest option: the cards are asked again rather than silently marked as learned.
            saveFailure

            SFPrimaryButton(title: L10n.commonDone.string) { close() }

            Spacer(minLength: 0)
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer(minLength: Spacing.s2)
            Text(value)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Nothing to answer

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Spacer(minLength: 0)

            Text(L10n.flashcardEmptyTitle.string)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(L10n.flashcardEmptyBody.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(title: L10n.commonDone.string) { close() }

            Spacer(minLength: 0)
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("O02/O03 Recall session") {
    RecallSessionView(
        items: [
            RecallQueueItem(
                id: "c1",
                deckId: "d1",
                deckTitle: "Normalisation",
                card: Flashcard(
                    id: "c1",
                    front: "What is 3NF?",
                    back: "No transitive dependencies.",
                    provenance: AIProvenance(
                        materialId: "m1",
                        pageNumbers: [12],
                        confidence: .high
                    )
                ),
                state: .new,
                learningStep: nil
            ),
        ],
        decks: [
            Deck(
                id: "d1",
                title: "Normalisation",
                cards: [
                    Flashcard(
                        id: "c1",
                        front: "What is 3NF?",
                        back: "No transitive dependencies.",
                        provenance: AIProvenance(
                            materialId: "m1",
                            pageNumbers: [12],
                            confidence: .high
                        )
                    ),
                ]
            ),
        ],
        store: InMemoryDeckStore(),
        settings: .default
    )
}
