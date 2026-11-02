import SwiftUI

struct DecksHomeView: View {

    @State private var viewModel: DecksHomeViewModel
    @State private var isCreating = false
    @State private var studyDeck: Deck?
    @State private var deckToDelete: Deck?

    private let materialStore: any MaterialStore
    private let deckStore: any DeckStore
    private let router: AIRouter
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        materialStore: any MaterialStore,
        deckStore: any DeckStore,
        router: AIRouter
    ) {
        self.materialStore = materialStore
        self.deckStore = deckStore
        self.router = router
        _viewModel = State(initialValue: DecksHomeViewModel(store: deckStore))
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { deckToDelete != nil },
            set: { if !$0 { deckToDelete = nil } }
        )
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    header
                    content
                }
                .padding(.horizontal, margin)
                .padding(.bottom, Spacing.s6)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isCreating, onDismiss: reload) {
            FlashcardGenerateScreen(
                initialMaterial: nil,
                materialStore: materialStore,
                deckStore: deckStore,
                router: router
            )
        }
        .fullScreenCover(item: $studyDeck, onDismiss: reload) { deck in
            FlashcardReviewView(deck: deck, store: deckStore)
        }
        .confirmationDialog(
            FlashcardCopy.deleteDeckTitle,
            isPresented: isConfirmingDelete,
            titleVisibility: .visible,
            presenting: deckToDelete
        ) { deck in
            Button(FlashcardCopy.deleteDeck, role: .destructive) {
                Task { await viewModel.delete(deck) }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: { deck in
            Text(FlashcardCopy.deleteDeckMessage(deck.title))
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            Text(FlashcardCopy.decksTitle)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                isCreating = true
            } label: {
                Label(FlashcardCopy.newDeck, systemImage: "plus")
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.onError)
                    .padding(.horizontal, Spacing.s3)
                    .frame(minHeight: 34)
                    .background(ColorTokens.primary, in: .rect(cornerRadius: 10))
                    .frame(minHeight: Layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Spacing.s4)
        .padding(.bottom, Spacing.s3)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s10)
        } else if let error = viewModel.error, viewModel.decks.isEmpty {
            SFErrorBanner(error: error, onRecover: reload)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: reload)
            }

            ForEach(viewModel.decks) { deck in
                NavigationLink {
                    DeckOverviewView(deckId: deck.id, store: deckStore)
                } label: {
                    deckCard(deck)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        deckToDelete = deck
                    } label: {
                        Label(FlashcardCopy.deleteDeck, systemImage: "trash")
                    }
                }
            }

            let due = viewModel.totalDue()
            if due > 0 {
                Button {
                    studyDeck = viewModel.mostDueDeck()
                } label: {
                    Label(FlashcardCopy.duePill(due), systemImage: "bolt.fill")
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.onError)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(ColorTokens.primary, in: .capsule)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.s4)
            }
        }
    }

    private func deckCard(_ deck: Deck) -> some View {
        let due = deck.dueCount()
        let reviewed = deck.lastReviewedAt.map { FlashcardCopy.lastReviewed(FlashcardText.relative($0)) }
            ?? FlashcardCopy.notReviewed

        return HStack(alignment: .center, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(deck.title)
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(FlashcardCopy.cardCount(deck.cards.count))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)

                HStack(spacing: Spacing.s2) {
                    Text(FlashcardCopy.dueBadge(due))
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(due > 0 ? ColorTokens.onAccent : ColorTokens.textSecondary)
                        .padding(.horizontal, Spacing.s3)
                        .frame(minHeight: 22)
                        .background(due > 0 ? ColorTokens.accent : SummaryGlass.fill.opacity(0.85), in: .capsule)
                        .monospacedDigit()

                    Text(reviewed)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, Spacing.s2)
            }

            Spacer(minLength: 0)

            FlashcardMasteryRing(share: deck.masteryShare)
                .frame(width: 72, height: 72)
        }
        .padding(.vertical, Spacing.s4)
        .padding(.leading, Spacing.s5)
        .padding(.trailing, Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(alignment: .leading) {
            deck.subjectColor
                .frame(width: 6)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .summaryGlass(cornerRadius: Radius.l, strong: true)
        .contentShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(ColorTokens.primary)
                .frame(width: 72, height: 72)
                .background(ColorTokens.primaryContainer, in: .circle)
                .accessibilityHidden(true)

            Text(FlashcardCopy.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(FlashcardCopy.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(title: FlashcardCopy.makeFlashcards) {
                isCreating = true
            }
            .padding(.top, Spacing.s4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.s10)
    }
}

#Preview("E01 Decks") {
    NavigationStack {
        DecksHomeView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            deckStore: InMemoryDeckStore(seededWith: [
                Deck(
                    title: "Trees & Graphs",
                    cards: [
                        Flashcard(
                            front: "What is a leaf node?",
                            back: "A node with no children.",
                            provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high)
                        ),
                        Flashcard(
                            front: "Define tree height",
                            back: "The longest path from the root to a leaf.",
                            provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high),
                            sr: SpacedRepetitionState(interval: 6, dueAt: .now.addingTimeInterval(86_400 * 4), reps: 2)
                        )
                    ]
                )
            ]),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}

#Preview("E01 Decks — empty") {
    NavigationStack {
        DecksHomeView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            deckStore: InMemoryDeckStore(),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}
