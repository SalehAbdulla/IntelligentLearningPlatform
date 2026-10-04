//
//  PaywallView.swift
//  StudyForge
//
//  L01 — `118_Paywall_Plans_{M3}` (docs/03 §L, P0). Three plan cards in BHD, a monthly /
//  annual toggle with the saving shown per plan, and the one primary action: continue to
//  the order summary.
//
//  WHY THE TOGGLE RE-PRICES EVERY CARD
//  -----------------------------------
//  The annual price is not the monthly price times twelve with a footnote — it is a
//  different number, and the "save %" badge beside it is computed from the two. Showing
//  the wrong one next to a "save 17 %" badge is the fastest way to look untrustworthy, so
//  the price, the per-month equivalent and the badge all move together with the toggle.
//

import SwiftUI

struct PaywallView: View {

    let container: AppContainer

    @State private var viewModel: PaywallViewModel
    @State private var showingCheckout = false

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: PaywallViewModel(
            uid: container.session?.id ?? "",
            store: container.subscriptions,
            gateway: container.payments
        ))
    }

    /// Checkout is only meaningful for a PAID plan the account does not already hold.
    private var canContinue: Bool {
        viewModel.selectedPlan.isPaid && viewModel.selectedPlan != viewModel.currentPlan
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                header
                termToggle
                planList

                SFPrimaryButton(
                    title: viewModel.continueTitle,
                    isLoading: viewModel.isLoading,
                    isEnabled: canContinue,
                    action: { showingCheckout = true }
                )

                footer
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .navigationDestination(isPresented: $showingCheckout) {
            CheckoutView(
                container: container,
                plan: viewModel.selectedPlan,
                term: viewModel.term,
                onFinish: {
                    // Collapsing this binding pops checkout AND the payment screen pushed on
                    // top of it. The paywall stayed alive underneath, so its `task` will not
                    // re-run — the entitlement is re-read explicitly instead.
                    showingCheckout = false
                    Task { await viewModel.load() }
                }
            )
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.title)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(viewModel.subtitle)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Term toggle (L01)

    private var termToggle: some View {
        Picker(viewModel.subtitle, selection: $viewModel.term) {
            Text(viewModel.monthlyTitle).tag(BillingTerm.monthly)
            Text(viewModel.annualTitle).tag(BillingTerm.annual)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(viewModel.subtitle)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            NavigationLink {
                PlanCompareView(viewModel: viewModel)
            } label: {
                Text(viewModel.compareTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
            }

            Button {
                Task { await viewModel.restore() }
            } label: {
                Text(viewModel.restoreTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
            }
            .disabled(viewModel.isRestoring)

            if viewModel.isPremium {
                NavigationLink {
                    ManageSubscriptionView(container: container)
                } label: {
                    Text(L10n.subscriptionTitle.string)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
                }
            }
        }
    }

    // MARK: Plans (L01)

    private var planList: some View {
        VStack(spacing: Spacing.s3) {
            ForEach(viewModel.plans, id: \.self) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let isSelected = viewModel.selectedPlan == plan

        return Button {
            viewModel.selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    Text(viewModel.planName(plan))
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)

                    if viewModel.isCurrent(plan) {
                        badge(viewModel.currentTitle, tint: ColorTokens.secondary)
                    }

                    Spacer(minLength: Spacing.s2)

                    if viewModel.isRecommended(plan) {
                        badge(viewModel.recommendedTitle, tint: ColorTokens.primary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    Text(viewModel.priceLabel(plan) ?? "")
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)

                    if let perMonth = viewModel.perMonthLabel(plan) {
                        Text("\(perMonth) \(viewModel.perMonthTitle)")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                if let saving = viewModel.savingLabel(plan) {
                    Text(saving)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.successText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .frame(minHeight: Layout.minTouchTarget)
            .background(
                isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                in: .rect(cornerRadius: Radius.l)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l)
                    .strokeBorder(
                        isSelected ? ColorTokens.primary : ColorTokens.outline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.sfCaption)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

// MARK: - Previews

#Preview("L01 Paywall — free account") {
    NavigationStack {
        PaywallView(container: .previewing())
    }
}

