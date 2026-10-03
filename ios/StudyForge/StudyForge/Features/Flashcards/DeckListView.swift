//
//  DeckListView.swift
//  StudyForge
//
//  E01 — `42_Decks_List_{M2}` (docs/03 §E, P0). Every deck the student has built, with the four
//  states designed rather than improvised.
//

import SwiftUI

struct DeckListView: View {

    @State private var viewModel: DeckListViewModel
    @State private var isCreating = false

    private let materialStore: any MaterialStore
    private let deckStore: any DeckStore
    private let router: AIRouter

    init(
        materialStore: any MaterialStore,
        deckStore: any DeckStore,
        router: AIRouter
    ) {
        self.materialStore = materialStore
        self.deckStore = deckStore
        self.router = router
        _viewModel = State(initialValue: DeckListViewModel(store: deckStore))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                deckList
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.deckNewDeck.string)
            }
        }
        .sheet(isPresented: $isCreating) {
            FlashcardGenerateView(
                initialMaterial: nil,
                materialStore: materialStore,
                deckStore: deckStore,
                router: router
            )
        }
        .task { await viewModel.load() }
    }

    private var deckList: some View {
        List {
            ForEach(viewModel.decks) { deck in
                NavigationLink {
                    DeckDetailView(deckId: deck.id, store: deckStore)
                } label: {
                    row(deck)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ deck: Deck) -> some View {
        HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(deck.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text("\(deck.cards.count) \(L10n.deckCardsHeading.string)")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)

            if deck.dueCount() > 0 {
                Text("\(deck.dueCount())")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.onAccent)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .background(ColorTokens.accent, in: .capsule)
                    .accessibilityLabel("\(deck.dueCount()) \(L10n.deckDueLabel.string)")
            }
        }
        .padding(.vertical, Spacing.s2)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("E01 Decks — empty") {
    NavigationStack {
        DeckListView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            deckStore: InMemoryDeckStore(),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}
