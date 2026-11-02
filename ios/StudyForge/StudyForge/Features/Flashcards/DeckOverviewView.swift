import SwiftUI

struct DeckOverviewView: View {

    @State private var viewModel: DeckOverviewViewModel
    @State private var isStudying = false
    @State private var editorTarget: FlashcardEditorTarget?
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isConfirmingDelete = false

    @Environment(\.dismiss) private var dismiss

    private let store: any DeckStore
    private let margin = Layout.screenMargin + Spacing.s3

    init(deckId: String, store: any DeckStore) {
        self.store = store
        _viewModel = State(initialValue: DeckOverviewViewModel(deckId: deckId, store: store))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            content
                .frame(maxWidth: Layout.maxContentWidth)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            if isDeleted { dismiss() }
        }
        .fullScreenCover(isPresented: $isStudying, onDismiss: reload) {
            if let deck = viewModel.deck {
                FlashcardReviewView(deck: deck, store: store)
            }
        }
        .sheet(item: $editorTarget) { target in
            editor(for: target)
        }
        .alert(FlashcardCopy.renameDeck, isPresented: $isRenaming) {
            TextField(FlashcardCopy.deckName, text: $renameText)
            Button(L10n.commonCancel.string, role: .cancel) {}
            Button(FlashcardCopy.save) {
                let title = renameText
                Task { await viewModel.rename(to: title) }
            }
        } message: {
            Text(FlashcardCopy.renamePrompt)
        }
        .confirmationDialog(
            FlashcardCopy.deleteDeckTitle,
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(FlashcardCopy.deleteDeck, role: .destructive) {
                Task { await viewModel.deleteDeck() }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: {
            Text(FlashcardCopy.deleteDeckMessage(viewModel.deck?.title ?? ""))
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
        } else if viewModel.isMissing {
            VStack(spacing: Spacing.s4) {
                Image(systemName: "rectangle.stack.badge.minus")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)
                Text(FlashcardCopy.deckMissing)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                SFPrimaryButton(title: L10n.commonBack.string) { dismiss() }
            }
            .padding(.horizontal, margin)
        } else if let deck = viewModel.deck {
            loaded(deck)
        } else if let error = viewModel.error {
            SFErrorBanner(error: error, onRecover: reload)
                .padding(.horizontal, margin)
        }
    }

    private func loaded(_ deck: Deck) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(deck.title)
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(FlashcardCopy.cardCount(deck.cards.count))
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .padding(.top, Spacing.s4)

                HStack(spacing: Spacing.s2) {
                    counter(viewModel.dueCount, L10n.deckDueLabel.string)
                    counter(viewModel.newCount, L10n.deckNewLabel.string)
                    counter(viewModel.learningCount, L10n.deckLearningLabel.string)
                    counter(viewModel.masteredCount, L10n.deckMasteredLabel.string)
                }

                VStack(spacing: Spacing.s2) {
                    SFPrimaryButton(title: L10n.deckStudyNow.string, isEnabled: viewModel.canStudy) {
                        isStudying = true
                    }
                    if let caughtUp = viewModel.caughtUpText {
                        Label(caughtUp, systemImage: "checkmark.circle.fill")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.successText)
                    }
                }

                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: nil)
                }

                Text(L10n.deckCardsHeading.string)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .padding(.top, Spacing.s2)
                    .accessibilityAddTraits(.isHeader)

                if deck.cards.isEmpty {
                    Text(FlashcardCopy.noCardsYet)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .padding(Spacing.s4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .summaryGlass()
                } else {
                    LazyVStack(spacing: Spacing.s2) {
                        ForEach(deck.cards) { card in
                            cardRow(card)
                        }
                    }
                }

                editMenu
                    .padding(.top, Spacing.s2)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
        .refreshable { await viewModel.load() }
    }

    private func counter(_ value: Int, _ label: String) -> some View {
        VStack(spacing: Spacing.s1) {
            Text(value.formatted())
                .font(.sfTitleM.weight(.bold))
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .summaryGlass()
        .accessibilityElement(children: .combine)
    }

    private func cardRow(_ card: Flashcard) -> some View {
        let mastery = CardMastery(card.sr)

        return Button {
            editorTarget = .edit(card)
        } label: {
            HStack(spacing: Spacing.s3) {
                Circle()
                    .fill(mastery.color)
                    .frame(width: 8, height: 8)
                Text(card.front)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Spacing.s2)
                if card.isFlagged {
                    Image(systemName: "flag.fill")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.warningText)
                }
                Image(systemName: "chevron.forward")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .padding(.horizontal, Spacing.s3)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .summaryGlass(cornerRadius: 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(FlashcardCopy.cardState(card.front, card.isFlagged ? "\(mastery.title), \(FlashcardCopy.flagged)" : mastery.title))
        .accessibilityHint(FlashcardCopy.editCard)
        .accessibilityAddTraits(.isButton)
    }

    private var editMenu: some View {
        Menu {
            Button {
                renameText = viewModel.deck?.title ?? ""
                isRenaming = true
            } label: {
                Label(FlashcardCopy.renameDeck, systemImage: "pencil")
            }
            Button {
                editorTarget = .create
            } label: {
                Label(FlashcardCopy.addCard, systemImage: "plus")
            }
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label(FlashcardCopy.deleteDeck, systemImage: "trash")
            }
        } label: {
            Text(FlashcardCopy.editDeck)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
        }
        .disabled(viewModel.isWorking)
    }

    @ViewBuilder
    private func editor(for target: FlashcardEditorTarget) -> some View {
        switch target {
        case .edit(let card):
            FlashcardEditorSheet(
                title: FlashcardCopy.editCard,
                front: card.front,
                back: card.back,
                onSave: { front, back in
                    Task { await viewModel.updateCard(id: card.id, front: front, back: back) }
                },
                onDelete: {
                    Task { await viewModel.deleteCard(id: card.id) }
                }
            )
        case .create:
            FlashcardEditorSheet(
                title: FlashcardCopy.newCard,
                front: "",
                back: "",
                onSave: { front, back in
                    Task { await viewModel.addCard(front: front, back: back) }
                }
            )
        }
    }
}

#Preview("E04 Deck detail") {
    NavigationStack {
        DeckOverviewView(
            deckId: "preview",
            store: InMemoryDeckStore(seededWith: [
                Deck(
                    id: "preview",
                    title: "Trees & Graphs",
                    cards: [
                        Flashcard(
                            front: "What is a binary tree?",
                            back: "A tree where each node has at most two children.",
                            provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high)
                        ),
                        Flashcard(
                            front: "Define tree height",
                            back: "The longest path from the root to a leaf.",
                            provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high),
                            sr: SpacedRepetitionState(interval: 40, dueAt: .now.addingTimeInterval(86_400 * 40), reps: 4)
                        )
                    ]
                )
            ])
        )
    }
}
