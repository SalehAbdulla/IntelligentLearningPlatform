import SwiftUI

struct FlashcardReviewView: View {

    @State private var viewModel: FlashcardReviewViewModel
    @State private var isConfirmingEnd = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let margin = Layout.screenMargin + Spacing.s3

    init(deck: Deck, store: any DeckStore) {
        _viewModel = State(initialValue: FlashcardReviewViewModel(deck: deck, store: store))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            Group {
                switch viewModel.phase {
                case .reviewing: reviewing
                case .summary: summary
                case .empty: emptyState
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.phase)
        .interactiveDismissDisabled(viewModel.hasUnfinishedProgress)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isShowingAnswer) { _, isShowing in isShowing }
        .sensoryFeedback(.success, trigger: viewModel.phase) { _, phase in phase == .summary }
        .confirmationDialog(
            FlashcardCopy.endSessionTitle,
            isPresented: $isConfirmingEnd,
            titleVisibility: .visible
        ) {
            Button(FlashcardCopy.endSession) { dismiss() }
            Button(FlashcardCopy.keepReviewing, role: .cancel) {}
        } message: {
            Text(FlashcardCopy.endSessionMessage(viewModel.reviewedCount))
        }
    }

    private var reviewing: some View {
        VStack(spacing: Spacing.s4) {
            topBar

            FlashcardProgressBar(fraction: viewModel.progressFraction)

            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: nil)
            }

            if let card = viewModel.currentCard {
                flipCard(card)
                    .id(card.id)
                    .transition(cardTransition)
                    .padding(.top, Spacing.s4)
            }

            footer
        }
        .padding(.horizontal, margin)
        .padding(.bottom, Spacing.s4)
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.currentIndex)
    }

    private var cardTransition: AnyTransition {
        if reduceMotion {
            return AnyTransition.opacity
        }
        return AnyTransition.asymmetric(
            insertion: AnyTransition.move(edge: .trailing).combined(with: AnyTransition.opacity),
            removal: AnyTransition.opacity
        )
    }

    private var topBar: some View {
        HStack {
            Button {
                if viewModel.hasUnfinishedProgress {
                    isConfirmingEnd = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(FlashcardCopy.close)

            Spacer()

            Text(viewModel.progressLabel)
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()

            Spacer()

            Button {
                Task { await viewModel.toggleFlag() }
            } label: {
                Image(systemName: viewModel.isCurrentCardFlagged ? "flag.fill" : "flag")
                    .font(.sfTitleS)
                    .foregroundStyle(viewModel.isCurrentCardFlagged ? ColorTokens.warningText : ColorTokens.textSecondary)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isCurrentCardFlagged ? FlashcardCopy.unflag : FlashcardCopy.flag)
        }
        .padding(.top, Spacing.s2)
    }

    private func flipCard(_ card: Flashcard) -> some View {
        let isShowing = viewModel.isShowingAnswer
        let turns = isShowing && !reduceMotion

        return ZStack {
            face {
                Text(card.front)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .opacity(isShowing ? 0 : 1)

            face {
                backContent(card)
            }
            .opacity(isShowing ? 1 : 0)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(turns ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .animation(Motion.respecting(Motion.emphasis, reduceMotion: reduceMotion), value: isShowing)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isShowing { viewModel.reveal() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isShowing ? card.back : card.front)
        .accessibilityHint(isShowing ? "" : FlashcardCopy.tapAnywhere)
        .accessibilityAddTraits(isShowing ? [] : .isButton)
    }

    private func face<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(Spacing.s8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .summaryGlass(cornerRadius: 20, strong: true)
            .shadow(color: Color.black.opacity(0.12), radius: 16, y: 12)
    }

    private func backContent(_ card: Flashcard) -> some View {
        let answer = FlashcardAnswer(card.back)

        return VStack(spacing: Spacing.s4) {
            Text(answer.headline)
                .font(answer.isShort ? Font.sfTitleL : Font.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            if let detail = answer.detail {
                Text(detail)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }

            if let citation = viewModel.citationLabel {
                Text(FlashcardCopy.cite(citation))
                    .font(.sfCaption.weight(.semibold))
                    .foregroundStyle(ColorTokens.onAccent)
                    .padding(.horizontal, Spacing.s4)
                    .frame(minHeight: 26)
                    .background(ColorTokens.success, in: .capsule)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.isShowingAnswer {
            VStack(spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    ForEach(ReviewRating.allCases, id: \.self) { rating in
                        ratingButton(rating)
                    }
                }
                Text(FlashcardCopy.howWell)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .transition(.opacity)
        } else {
            VStack(spacing: Spacing.s2) {
                Text(FlashcardCopy.tapAnywhere)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                if viewModel.canUndo {
                    Button {
                        Task { await viewModel.undo() }
                    } label: {
                        Label(FlashcardCopy.undo, systemImage: "arrow.uturn.backward")
                            .font(.sfFootnote.weight(.semibold))
                            .frame(minHeight: Layout.minTouchTarget)
                    }
                    .tint(ColorTokens.primary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76 + Spacing.s3 + Spacing.s5)
            .transition(.opacity)
        }
    }

    private func ratingButton(_ rating: ReviewRating) -> some View {
        Button {
            Task { await viewModel.rate(rating) }
        } label: {
            VStack(spacing: Spacing.s1) {
                Text(viewModel.ratingTitle(rating))
                    .font(.sfFootnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(viewModel.intervalLabel(for: rating))
                    .font(.sfCaption)
                    .monospacedDigit()
            }
            .foregroundStyle(rating.ink)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(rating.fill, in: .rect(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRating)
        .accessibilityLabel(viewModel.ratingTitle(rating))
        .accessibilityValue(viewModel.intervalLabel(for: rating))
    }

    private var summary: some View {
        let accuracy = "\(viewModel.accuracyPercent)%"
        let nextText: String? = {
            if viewModel.dueNowCount > 0 {
                return FlashcardCopy.dueAgain(viewModel.dueNowCount)
            }
            if let next = viewModel.nextReviewDate {
                return FlashcardCopy.nextReview(FlashcardText.dueLabel(next))
            }
            return nil
        }()

        return ScrollView {
            VStack(spacing: Spacing.s5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(ColorTokens.onAccent)
                    .frame(width: 64, height: 64)
                    .background(ColorTokens.success, in: .circle)
                    .padding(.top, Spacing.s12 + Spacing.s10)
                    .accessibilityHidden(true)

                Text(FlashcardCopy.sessionComplete)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: Spacing.s2) {
                    statTile(viewModel.reviewedCount.formatted(), FlashcardCopy.reviewed)
                    statTile(accuracy, FlashcardCopy.accuracy)
                    statTile(FlashcardText.duration(viewModel.sessionDuration), FlashcardCopy.time)
                }

                Text(
                    FlashcardCopy.breakdown(
                        again: viewModel.againCount,
                        hard: viewModel.hardCount,
                        good: viewModel.goodCount,
                        easy: viewModel.easyCount
                    )
                )
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.onPrimaryContainer)
                .multilineTextAlignment(.center)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.m))

                if let nextText {
                    Text(nextText)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: Spacing.s3) {
                    if viewModel.dueNowCount > 0 {
                        SFPrimaryButton(title: FlashcardCopy.keepGoing) {
                            viewModel.keepGoing()
                        }
                        Button(FlashcardCopy.done) { dismiss() }
                            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
                    } else {
                        SFPrimaryButton(title: FlashcardCopy.done) { dismiss() }
                    }
                }
                .padding(.top, Spacing.s4)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: Spacing.s1) {
            Text(value)
                .font(.sfTitleM.weight(.bold))
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .summaryGlass()
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Spacer(minLength: 0)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)

            Text(FlashcardCopy.nothingDueTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.nextReviewDate.map { FlashcardCopy.nextReview(FlashcardText.dueLabel($0)) } ?? FlashcardCopy.nothingDueBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(title: FlashcardCopy.done) { dismiss() }
                .padding(.top, Spacing.s4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, margin)
    }
}

#Preview("E05 Review") {
    FlashcardReviewView(
        deck: Deck(
            id: "preview",
            title: "Trees & Graphs",
            cards: [
                Flashcard(
                    front: "What is the time complexity of search in a balanced binary search tree?",
                    back: "O(log n)\nEach comparison halves the remaining tree, so search is logarithmic in a balanced tree.",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [14], confidence: .high)
                ),
                Flashcard(
                    front: "What is a leaf node?",
                    back: "A node with no children.",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high)
                )
            ]
        ),
        store: InMemoryDeckStore()
    )
}

#Preview("E09 Nothing due") {
    FlashcardReviewView(
        deck: Deck(
            title: "Trees & Graphs",
            cards: [
                Flashcard(
                    front: "What is a leaf node?",
                    back: "A node with no children.",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [12], confidence: .high),
                    sr: SpacedRepetitionState(interval: 6, dueAt: .now.addingTimeInterval(86_400), reps: 2)
                )
            ]
        ),
        store: InMemoryDeckStore()
    )
}
