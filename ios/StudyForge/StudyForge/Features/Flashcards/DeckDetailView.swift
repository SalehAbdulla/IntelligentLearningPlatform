//
//  DeckDetailView.swift
//  StudyForge
//
//  E04 — `45_Deck_Detail_{M2}` (docs/03 §E, P0). One deck's counters and cards, with the "Study
//  now" entry into the review session.
//

import SwiftUI

struct DeckDetailView: View {

    @State private var viewModel: DeckDetailViewModel
    @State private var isStudying = false

    private let store: any DeckStore

    init(deckId: String, store: any DeckStore) {
        self.store = store
        _viewModel = State(initialValue: DeckDetailViewModel(deckId: deckId, store: store))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if let deck = viewModel.deck {
                content(deck)
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.deck?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isStudying, onDismiss: {
            Task { await viewModel.load() }
        }) {
            if let deck = viewModel.deck {
                FlashcardReviewView(deck: deck, store: store)
            }
        }
        .task { await viewModel.load() }
    }

    private func content(_ deck: Deck) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                counters

                SFPrimaryButton(
                    title: viewModel.studyNowTitle,
                    isEnabled: !deck.cards.isEmpty,
                    action: { isStudying = true }
                )

                if deck.cards.isEmpty {
                    Text(L10n.deckEmptyBody.string)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                } else {
                    cardList
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var counters: some View {
        HStack(spacing: Spacing.s2) {
            counter(viewModel.dueLabel, viewModel.dueCount)
            counter(viewModel.newLabel, viewModel.newCount)
            counter(viewModel.learningLabel, viewModel.learningCount)
            counter(viewModel.masteredLabel, viewModel.masteredCount)
        }
    }

    private func counter(_ label: String, _ value: Int) -> some View {
        VStack(spacing: Spacing.s1) {
            Text("\(value)")
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s3)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }

    private var cardList: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.cardsHeading)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.offset) { _, card in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(card.front)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(card.back)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s3)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("E04 Deck detail") {
    NavigationStack {
        DeckDetailView(
            deckId: "preview",
            store: InMemoryDeckStore(seededWith: [
                Deck(
                    id: "preview",
                    title: "Normalisation",
                    cards: [
                        Flashcard(front: "What is 3NF?", back: "No transitive dependencies.",
                                  provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)),
                        Flashcard(front: "What is 1NF?", back: "Atomic values.",
                                  provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)),
                    ]
                )
            ])
        )
    }
}
