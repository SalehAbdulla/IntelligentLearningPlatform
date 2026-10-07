//
//  PlanCompareView.swift
//  StudyForge
//
//  L02 — `119_Paywall_FeatureCompare_{M3}` (docs/03 §L, P1). The per-tier comparison table.
//
//  WHY IT IS A TABLE AND NOT MORE PLAN CARDS
//  -----------------------------------------
//  L01 answers "what does it cost?"; L02 answers "what do I get?". Those are different
//  questions and the answer to the second is a matrix — AI generations, materials and
//  group spaces vary independently per tier, and a card layout hides the comparison the
//  screen exists to make.
//

import SwiftUI

// Accessibility: this screen is a comparison table, not a row of cards, so each ROW is combined into a
// single element a student swipes through, reading "AI generations, unlimited, 15, 15" per tier.

struct PlanCompareView: View {

    let viewModel: PaywallViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Grid(alignment: .leading, horizontalSpacing: Spacing.s4, verticalSpacing: Spacing.s3) {
                    GridRow {
                        Text(L10n.subscriptionCompareTitle.string)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                        ForEach(viewModel.plans, id: \.self) { plan in
                            Text(viewModel.planName(plan))
                                .font(.sfBodyEmph)
                                .foregroundStyle(ColorTokens.textPrimary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Divider()

                    featureRow(L10n.subscriptionFeatureAI.string, aiText)
                    featureRow(L10n.subscriptionFeatureMaterials.string) { limitText($0.includedMaterials) }
                    featureRow(L10n.subscriptionFeatureGroups.string) { limitText($0.includedGroupSpaces) }
                }

                VStack(alignment: .leading, spacing: Spacing.s3) {
                    ForEach(viewModel.plans.filter(\.isPaid), id: \.self) { plan in
                        Button {
                            viewModel.selectedPlan = plan
                            dismiss()
                        } label: {
                            Text(L10n.subscriptionChoose.string(viewModel.planName(plan)))
                                .font(.sfBodyEmph)
                                .foregroundStyle(ColorTokens.primary)
                                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
                        }
                    }
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.compareTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Rows

    @ViewBuilder
    private func featureRow(
        _ title: String,
        _ value: @escaping (SubscriptionPlan) -> String
    ) -> some View {
        GridRow {
            Text(title)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.plans, id: \.self) { plan in
                Text(value(plan))
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// `nil` means unlimited in the catalogue, which reads as "Unlimited" rather than "—".
    private func limitText(_ value: Int?) -> String {
        guard let value else { return L10n.subscriptionUnlimited.string }
        return "\(value)"
    }

    /// `dailyAIGenerationLimit` uses `Int.max` as its "unlimited" sentinel, so it is
    /// translated here rather than compared in the view.
    private func aiText(_ plan: SubscriptionPlan) -> String {
        plan.dailyAIGenerationLimit == .max
            ? L10n.subscriptionUnlimited.string
            : "\(plan.dailyAIGenerationLimit)"
    }
}

// MARK: - Previews

#Preview("L02 Compare plans") {
    NavigationStack {
        PlanCompareView(
            viewModel: PaywallViewModel(
                uid: "uid_preview",
                store: InMemorySubscriptionStore(),
                gateway: SimulatedTapGateway(store: InMemorySubscriptionStore(), latency: .zero)
            )
        )
    }
}
