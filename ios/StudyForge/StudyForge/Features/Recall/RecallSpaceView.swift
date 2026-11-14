//
//  RecallSpaceView.swift
//  StudyForge
//
//  F17 — O01, `148_RecallSpace_Home_DueToday_{M5}` (docs/03 §O). One queue across every deck.
//
//  WHY ONE SCREEN AND NOT "STUDY THIS DECK"
//  ---------------------------------------
//  The question a student actually has on a Tuesday evening is "what does everything owe me
//  today?", and answering it by opening six decks is how revision stops happening. This screen is
//  that answer: a single due-today total, the four state counters above the Start action, and a
//  scope filter for the days when the learner does want one deck.
//
//  WHY IT OPENS THE SITTING IN A SHEET RATHER THAN NAVIGATING
//  ------------------------------ ---------------------------
//  A sitting is finite and it ends: it either runs out of cards or the learner closes it. A sheet
//  says that, keeps the counter underneath as the place it returns to, and lets the dismiss rebuild
//  the queue so the numbers on this screen agree with what was just answered. Navigation would put
//  the session in the back stack, where "Close with progress saved" would be a lie.
//
//  WHY THE COPY IS REUSED
//  ----------------------
//  `Core/Localisation/` is M1's lane, so F17 adds no `L10n` cases and no bare key strings — see
//  `L10n.swift`'s header for why a screen must never carry a raw key. Every label below therefore
//  resolves an existing F04 key, which is the same approach `StudyPlanWizardView` documents. The
//  one wording compromise is O01's four counters: `deck.dueLabel` labels the young bucket, because
//  the catalogue has New / Learning / Mastered but no word for "young", and "Due" is at least true
//  of every young card in a due queue. A `recall.*` family would replace all four in one commit.
//
//  WHY `isEmpty` AND `hasAnyCards` ARE BOTH READ
//  -------------------------------------------
//  "Nothing due" and "no cards at all" are different screens: the first wants the next due time,
//  the second wants a prompt to build a deck. Collapsing them would tell a brand-new learner they
//  are "all caught up" on work they never created.
//

import SwiftUI

/// O01's counter labels, and O02's state chip — one mapping so the two screens can never disagree
/// about what a state is called.
extension RecallCardState {

    /// The localised name of a card state.
    ///
    /// `young` reads "Due": the catalogue's `deck.dueLabel`. It is truthful for this screen because
    /// every card in the queue is due, and it is the closest existing word for "graduated but not
    /// yet mature". See the file header for why the key was reused rather than added.
    var title: String {
        switch self {
        case .new: L10n.deckNewLabel.string
        case .learning: L10n.deckLearningLabel.string
        case .young: L10n.deckDueLabel.string
        case .mature: L10n.deckMasteredLabel.string
        }
    }
}

struct RecallSpaceView: View {

    @State private var viewModel: RecallSpaceViewModel

    /// True while the sitting's sheet is up. The sitting itself owns its own lifecycle.
    @State private var isSessionPresented = false

    /// The learning steps still in progress when the sitting closed. Held here so the rebuild on
    /// dismiss puts those cards back in the queue instead of forgetting that they are mid-step.
    @State private var sessionSteps: [String: Int] = [:]

    private let deckStore: any DeckStore

    init(deckStore: any DeckStore, settingsStore: any RecallSettingsStore) {
        self.deckStore = deckStore
        _viewModel = State(initialValue: RecallSpaceViewModel(
            deckStore: deckStore,
            settingsStore: settingsStore
        ))
    }

    var body: some View {
        Group {
            // `.idle` is treated as loading: nothing has been read yet, so drawing the summary
            // would flash a "0 due" that is not true — it is merely unknown.
            if viewModel.isLoading || viewModel.state == .idle {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.reload() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                queueSummary
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(L10n.flashcardReviewTitle.string)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isSessionPresented, onDismiss: { onSessionClosed() }) {
            session
        }
    }

    // MARK: The queue

    private var queueSummary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                dueHeader
                counters

                if viewModel.deferredByLimit > 0 {
                    deferredNote
                }

                // A filter for a learner with one deck would be a control that can only do nothing.
                if viewModel.decks.count > 1 {
                    scopeFilter
                }

                SFPrimaryButton(
                    title: L10n.deckStudyNow.string,
                    isEnabled: viewModel.dueTotal > 0
                ) {
                    isSessionPresented = true
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    /// The number the learner came for.
    private var dueHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text("\(viewModel.dueTotal)")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.primary)

            Text(L10n.deckDueLabel.string)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        // One statement rather than a number read before its label.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.dueTotal) \(L10n.deckDueLabel.string)")
    }

    /// O01's four state counters. A row rather than a chart: the numbers are small and the point is
    /// "what kind of work is waiting", not a trend.
    private var counters: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(RecallCardState.allCases) { state in
                counterCell(state)
            }
        }
    }

    private func counterCell(_ state: RecallCardState) -> some View {
        VStack(spacing: Spacing.s1) {
            Text("\(viewModel.count(of: state))")
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(state.title)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Layout.minTouchTarget * 1.4)
        .padding(.vertical, Spacing.s2)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.title): \(viewModel.count(of: state))")
    }

    /// "18 more due tomorrow", surfaced rather than hidden — a queue that silently truncates
    /// teaches the learner not to trust the number.
    private var deferredNote: some View {
        Text("\(L10n.deckDueLabel.string) · \(viewModel.deferredByLimit)")
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.textSecondary)
            .accessibilityLabel(
                "\(L10n.deckDueLabel.string): \(viewModel.deferredByLimit)"
            )
    }


    // MARK: Scope

    /// O06's deck filter. Scoping rebuilds the queue in memory rather than re-reading the store, so
    /// switching is instant and works offline.
    private var scopeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                scopeChip(title: L10n.searchScopeAll.string, deckId: nil)
                ForEach(viewModel.decks) { deck in
                    scopeChip(title: deck.title, deckId: deck.id)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func scopeChip(title: String, deckId: String?) -> some View {
        let isSelected = viewModel.deckFilter == deckId

        return Button {
            viewModel.selectDeck(deckId)
        } label: {
            Text(title)
                .font(.sfCaption)
                .foregroundStyle(
                    isSelected ? ColorTokens.onPrimaryContainer : ColorTokens.textSecondary
                )
                .lineLimit(1)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(
                    isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                    in: .capsule
                )
                .overlay {
                    Capsule().strokeBorder(ColorTokens.outline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .frame(minHeight: Layout.minTouchTarget)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Nothing due

    @ViewBuilder
    private var nextDue: some View {
        if let nextDueAt = viewModel.nextDueAt {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(L10n.deckDueLabel.string)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                Text(nextDueAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Image(systemName: viewModel.hasAnyCards ? "checkmark.circle.fill" : "rectangle.stack")
                .font(.sfDisplayL)
                .foregroundStyle(
                    viewModel.hasAnyCards ? ColorTokens.successText : ColorTokens.primary
                )
                .accessibilityHidden(true)

            Text(
                viewModel.hasAnyCards
                    ? L10n.flashcardEmptyTitle.string
                    : L10n.deckEmptyTitle.string
            )
            .font(.sfTitleM)
            .foregroundStyle(ColorTokens.textPrimary)

            Text(
                viewModel.hasAnyCards
                    ? L10n.flashcardEmptyBody.string
                    : L10n.deckEmptyBody.string
            )
            .font(.sfCallout)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            nextDue
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
    }

    // MARK: The sitting

    private var session: some View {
        RecallSessionView(
            items: viewModel.items,
            decks: viewModel.decks,
            store: deckStore,
            settings: viewModel.settings,
            learningSteps: viewModel.learningSteps,
            onClose: { steps in sessionSteps = steps }
        )
    }

    /// Rebuilds the queue once the sitting is gone.
    ///
    /// The learning steps are handed back first: a card answered "Again" three seconds before the
    /// learner closed the sheet is due inside this sitting, and forgetting that would quietly drop
    /// it until tomorrow. The reload then re-reads every deck, so the counters show what the
    /// ratings actually wrote.
    private func onSessionClosed() {
        Task {
            viewModel.setLearningSteps(sessionSteps)
            await viewModel.reload()
        }
    }
}

// MARK: - Previews

#Preview("O01 Recall Space — two decks due") {
    NavigationStack {
        RecallSpaceView(
            deckStore: InMemoryDeckStore(seededWith: [
                Deck(
                    id: "d1",
                    title: "Normalisation",
                    cards: [
                        Flashcard(
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
                Deck(
                    id: "d2",
                    title: "Transactions",
                    cards: [
                        Flashcard(
                            front: "What is a dirty read?",
                            back: "Reading uncommitted data.",
                            provenance: AIProvenance(
                                materialId: "m2",
                                pageNumbers: [31],
                                confidence: .medium
                            )
                        ),
                    ]
                ),
            ]),
            settingsStore: InMemoryRecallSettingsStore()
        )
    }
}
