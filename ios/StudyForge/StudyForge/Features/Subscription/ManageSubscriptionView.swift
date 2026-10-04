//
//  ManageSubscriptionView.swift
//  StudyForge
//
//  L10 + B13 — `127_Subscription_Manage_Cancel_{M3}` and `23_Settings_Subscription_{M1}`
//  (docs/03 §L / §B). The current plan panel, the payment methods on file, billing history
//  and the cancel-at-period-end action behind a retention dialog.
//
//  WHY THE ROW AND THE SCREEN ARE THE SAME VIEW
//  --------------------------------------------
//  B13 says the settings row "leads to the subscription screen" — they are not two designs,
//  they are one. Rendering the same content from the same view model means a change to the
//  cancellation rules cannot land in one place and not the other.
//

import SwiftUI

struct ManageSubscriptionView: View {

    let container: AppContainer

    @State private var viewModel: ManageSubscriptionViewModel
    @State private var showingCancelConfirm = false

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: ManageSubscriptionViewModel(
            uid: container.session?.id ?? "",
            store: container.subscriptions
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                planPanel

                if viewModel.isPremium {
                    methodsPanel
                    historyPanel
                    cancelSection
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .confirmationDialog(
            viewModel.cancelConfirmTitle,
            isPresented: $showingCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(viewModel.confirmCancelTitle, role: .destructive) {
                Task { await viewModel.cancel() }
            }
            Button(viewModel.keepPlanTitle, role: .cancel) {}
        } message: {
            Text(viewModel.cancelConfirmBody)
        }
    }

    // MARK: Plan panel (B13)

    private var planPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.currentPlanLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.planValue)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            if let renewal = viewModel.renewalText {
                Text(renewal)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            if let autoRenew = viewModel.autoRenewText {
                Text(autoRenew)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            if !viewModel.isPremium {
                Text(viewModel.freeBody)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    PaywallView(container: container)
                } label: {
                    Text(viewModel.upgradeTitle)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Payment methods (L10)

    private var methodsPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.paymentMethodsTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.methods, id: \.self) { method in
                HStack(spacing: Spacing.s3) {
                    Image(systemName: method.symbolName)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .accessibilityHidden(true)

                    Text(viewModel.methodName(method))
                        .font(.sfBody)
                        .foregroundStyle(ColorTokens.textPrimary)

                    Spacer(minLength: Spacing.s2)

                    if viewModel.defaultMethod == method {
                        Text(viewModel.defaultBadge)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.primary)
                    } else {
                        Button(viewModel.makeDefaultTitle) {
                            viewModel.makeDefault(method)
                        }
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.primary)
                    }
                }
                .frame(minHeight: Layout.minTouchTarget)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Billing history (L10)

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.historyTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            if viewModel.hasHistory {
                ForEach(viewModel.receipts) { receipt in
                    SFDetailRow(row: DetailRow(
                        id: receipt.id,
                        label: receipt.paidAt.formatted(date: .abbreviated, time: .omitted),
                        value: MoneyText.price(receipt.amountFils)
                    ))
                }
            } else {
                Text(viewModel.noHistoryTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Cancel (L10)

    private var cancelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if viewModel.canCancel {
                Button(role: .destructive) {
                    showingCancelConfirm = true
                } label: {
                    HStack {
                        Text(viewModel.cancelTitle)
                        if viewModel.isCancelling {
                            Spacer(minLength: Spacing.s2)
                            ProgressView().controlSize(.small)
                        }
                    }
                    .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
                }
                .disabled(viewModel.isCancelling)
            } else if viewModel.subscription?.isEndingAtPeriodEnd == true {
                Text(viewModel.cancelledNote)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Previews

#Preview("B13 / L10 Subscription — free") {
    NavigationStack {
        ManageSubscriptionView(container: .previewing())
    }
}
