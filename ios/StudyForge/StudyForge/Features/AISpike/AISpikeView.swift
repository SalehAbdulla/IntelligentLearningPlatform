//
//  AISpikeView.swift
//  StudyForge
//
//  The S0 spike screen — a RUNNABLE proof of the AI layer, not a mock-up.
//
//  It answers the three spike questions on the device you are holding:
//    1. Is the on-device model available here, and if not, precisely why?
//    2. Which tier does the router actually pick, for each task?
//    3. Can the framework really fill a `@Generable` type with real content?
//
//  It stays in the app afterwards because it is a genuinely useful diagnostic: when
//  a generation looks wrong, the first question is always "which engine ran it?".
//

import SwiftUI

struct AISpikeView: View {

    @State private var governor: AICostGovernor
    @State private var router: AIRouter

    @State private var state: LoadState<SpikeOutcome> = .idle

    init() {
        let governor = AICostGovernor(plan: .free)
        _governor = State(initialValue: governor)
        _router = State(initialValue: .standard(governor: governor))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    tierSection
                    routingSection
                    runSection
                    budgetSection
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            }
            .background(ColorTokens.surface)
            .navigationTitle("AI Spike")
        }
    }

    // MARK: - 1. Live availability

    private var tierSection: some View {
        section("Engine availability (live)") {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(router.tierStatus, id: \.tier) { status in
                    HStack(alignment: .top, spacing: Spacing.s3) {
                        Circle()
                            .fill(status.availability.isAvailable
                                  ? ColorTokens.success
                                  : ColorTokens.warning)
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: Spacing.s1) {
                            Text(status.tier.displayName).font(.sfTitleS)
                            if let reason = status.availability.reason {
                                Text(reason.title)
                                    .font(.sfFootnote)
                                    .foregroundStyle(ColorTokens.textSecondary)
                                Text(reason.message)
                                    .font(.sfCaption)
                                    .foregroundStyle(ColorTokens.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Ready")
                                    .font(.sfFootnote)
                                    .foregroundStyle(ColorTokens.successText)
                            }
                        }
                    }
                    .foregroundStyle(ColorTokens.textPrimary)
                }
            }
            caption("Expected finding: tier 0 reports simulatorUnsupported in the Simulator, and available on a device with Apple Intelligence enabled. That difference is exactly why the router exists.")
        }
    }

    // MARK: - 2. Routing decisions

    private var routingSection: some View {
        section("Routing decision per task") {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(AITask.allCases, id: \.self) { task in
                    let decision = router.decide(for: task)
                    HStack(spacing: Spacing.s2) {
                        Text(task.displayName)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .frame(width: 130, alignment: .leading)
                        Text(decision.chosenTier?.displayName ?? "none available")
                            .font(.sfMono)
                            .foregroundStyle(decision.chosenTier == nil
                                             ? ColorTokens.error
                                             : ColorTokens.primary)
                        Spacer()
                    }
                }
            }
            caption("The router also reports WHY it fell back when it does, so a surprising routing choice is explainable rather than mysterious.")
        }
    }

    // MARK: - 3. Run it for real

    private var runSection: some View {
        section("Run a real generation") {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                Text(Self.sampleText)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .lineLimit(3)

                Button {
                    Task { await run() }
                } label: {
                    HStack {
                        if state.isLoading { ProgressView().tint(ColorTokens.onError) }
                        Text(state.isLoading ? "Generating…" : "Generate summary + 3 cards")
                            .font(.sfTitleS)
                    }
                    .foregroundStyle(ColorTokens.onError)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    .background(ColorTokens.primary, in: RoundedRectangle(cornerRadius: Radius.m))
                }
                .disabled(state.isLoading)

                outcome
            }
        }
    }

    @ViewBuilder
    private var outcome: some View {
        switch state {
        case .idle:
            EmptyView()

        case .loading:
            Text("Waiting for an engine…")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

        case .loaded(let value):
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    badge("\(value.summary.tier.displayName) · \(value.summary.duration.formatted(.units(allowed: [.seconds, .milliseconds], width: .abbreviated)))")
                    badge(value.summary.provenance.citationLabel)
                }
                Text(value.summary.value.tldr)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                ForEach(Array(value.cards.value.enumerated()), id: \.offset) { index, card in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text("\(index + 1). \(card.front)")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(card.back)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                        Text("difficulty \(card.difficulty)")
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                Text("\(value.cards.value.count) cards · \(value.cards.tier.displayName)")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

        case .empty:
            Text("No content was generated.")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

        case .failed(let error):
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(error.title)
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(error.message)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let action = error.recoveryAction {
                    Text(action).font(.sfCaption).foregroundStyle(ColorTokens.primary)
                }
            }
        }
    }

    // MARK: - 4. Budget

    private var budgetSection: some View {
        section("Cost governor") {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Plan \(governor.plan.rawValue) · used \(governor.usedToday) of \(governor.limit) cloud generations today")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                Text("On-device generation is unlimited and free, so it never counts against this — which is what keeps the free tier viable.")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }


    // MARK: - Actions

    private func run() async {
        state = .loading

        let context = AIGenerationContext(
            materialId: "spike-material",
            text: Self.sampleText,
            language: .english,
            learningStyle: .visual
        )

        do {
            let summary = try await router.summarize(
                SummaryRequest(context: context, length: .short, style: .bullets)
            )
            let cards = try await router.makeFlashcards(
                FlashcardRequest(context: context, count: 3, difficulty: .recall)
            )
            state = .loaded(SpikeOutcome(summary: summary, cards: cards))

        } catch let error as AIError {
            // The AI layer never leaks its own error type into a screen: it is
            // translated into the app's single user-facing error (docs/04 §8).
            state = .failed(error.asAppError)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: - Supporting types

    struct SpikeOutcome: Equatable {
        let summary: AIGenerated<AISummary>
        let cards: AIGenerated<[AIFlashcard]>
    }

    /// Short enough to generate quickly, technical enough that a bad summary or a
    /// hallucinated card is obvious at a glance.
    private static let sampleText = """
    Third normal form (3NF) is a database normalisation level used in relational \
    design. A relation is in 3NF when it is already in second normal form and has no \
    transitive dependencies, meaning that no non-key attribute depends on another \
    non-key attribute. Reaching 3NF reduces data redundancy and prevents update \
    anomalies, at the cost of additional joins at query time.
    """

    // MARK: - Presentation helpers

    @ViewBuilder
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(title)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            content()
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(ColorTokens.outline, lineWidth: 1)
        )
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.sfCaption)
            .foregroundStyle(ColorTokens.onAccent)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(ColorTokens.accent, in: Capsule())
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("AI spike — Simulator") { AISpikeView() }

