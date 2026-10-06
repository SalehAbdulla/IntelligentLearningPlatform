//
//  FlashcardReviewView.swift
//  StudyForge
//
//  E05–E07 — the review session: front, reveal, rate, then a session summary. The view model
//  explains why "Again" does not re-queue.
//

import SwiftUI

// TODO(M4 · F04): Add VoiceOver support to the review screen. It has none today, so the card
// side, the reveal action and the four rating buttons are unusable with VoiceOver.
// Done when: the card front/back is announced, "reveal" is a labelled button, and each rating
// button announces the interval it would set.

struct FlashcardReviewView: View {

    @State private var viewModel: FlashcardReviewViewModel
    @Environment(\.dismiss) private var dismiss

    init(deck: Deck, store: any DeckStore) {
        _viewModel = State(initialValue: FlashcardReviewViewModel(deck: deck, store: store))
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
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { dismiss() }
                }
            }
        }
    }

    // MARK: Review

    private var reviewing: some View {
        VStack(spacing: Spacing.s6) {
            ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.cards.count))
                .tint(ColorTokens.primary)

            Text(viewModel.progress)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            Spacer(minLength: 0)

            if let card = viewModel.currentCard {
                cardView(card)
            }

            Spacer(minLength: 0)

            if viewModel.isShowingAnswer {
                ratingButtons
            } else {
                Text(viewModel.tapToReveal)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }

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
                    Text(citation)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: .capsule)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: Spacing.s12 * 4)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.xl)
                .strokeBorder(ColorTokens.outline, lineWidth: 1)
        }
        .contentShape(.rect)
        .onTapGesture {
            if !viewModel.isShowingAnswer { viewModel.reveal() }
        }
    }

    private var ratingButtons: some View {
        HStack(spacing: Spacing.s2) {
            ratingButton(.again)
            ratingButton(.hard)
            ratingButton(.good)
            ratingButton(.easy)
        }
    }

    private func ratingButton(_ rating: ReviewRating) -> some View {
        Button {
            Task { await viewModel.rate(rating) }
        } label: {
            VStack(spacing: Spacing.s1) {
                Text(viewModel.ratingTitle(rating))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(viewModel.intervalLabel(for: rating))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s3)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(ColorTokens.outline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: Spacing.s6) {
            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.successText)

            Text(viewModel.sessionTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(spacing: Spacing.s2) {
                statRow(viewModel.reviewedLabel, "\(viewModel.reviewedCount)")
                statRow(viewModel.accuracyLabel, "\(viewModel.accuracyPercent)%")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))

            SFPrimaryButton(title: viewModel.doneTitle) { dismiss() }

            Button(viewModel.keepGoingTitle) { viewModel.keepGoing() }
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)

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
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Spacer(minLength: 0)
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            SFPrimaryButton(title: L10n.commonDone.string) { dismiss() }
            Spacer(minLength: 0)
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("E05 Review") {
    FlashcardReviewView(
        deck: Deck(
            id: "preview",
            title: "Normalisation",
            cards: [
                Flashcard(front: "What is 3NF?", back: "No transitive dependencies.",
                          provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)),
            ]
        ),
        store: InMemoryDeckStore()
    )
}
