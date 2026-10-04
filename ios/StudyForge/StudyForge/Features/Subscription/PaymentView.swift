//
//  PaymentView.swift
//  StudyForge
//
//  L04 / L07 / L08 / L09 — `121_Payment_Method_Select`, `124_Payment_Processing`,
//  `125_Payment_Success_Receipt` and `126_Payment_Failed_Retry` (docs/03 §L).
//
//  WHY THE BACK BUTTON IS HIDDEN MID-TRANSACTION
//  ---------------------------------------------
//  L07's copy says "don't close the app" because a charge may be in flight. An enabled
//  back button invites exactly that gesture, so it is disabled while processing AND while a
//  receipt is on screen — the only ways out are the button the design provides.
//

import SwiftUI

struct PaymentView: View {

    let container: AppContainer

    /// Called when the flow is finished, so the whole checkout stack can be popped rather
    /// than leaving the order summary behind a completed purchase.
    let onFinish: () -> Void

    @State private var viewModel: PaymentViewModel

    init(container: AppContainer, order: Order, onFinish: @escaping () -> Void = {}) {
        self.container = container
        self.onFinish = onFinish
        _viewModel = State(initialValue: PaymentViewModel(order: order, gateway: container.payments))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error)
                }

                switch viewModel.phase {
                case .choosing:
                    choosing
                case .processing:
                    processing
                case .succeeded(_, let subscription):
                    success(subscription: subscription)
                case .failed(let reason):
                    failure(reason: reason)
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isProcessing || viewModel.receipt != nil)
    }

    // MARK: L04 — method select

    private var choosing: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            Text(viewModel.methodTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: Spacing.s3) {
                ForEach(viewModel.methods, id: \.self) { method in
                    methodRow(method)
                }
            }

            if viewModel.method.isRedirect {
                Text(viewModel.redirectNote)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SFPrimaryButton(
                title: viewModel.payTitle,
                action: { Task { await viewModel.pay() } }
            )

            Text(viewModel.secureNote)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func methodRow(_ method: PaymentMethod) -> some View {
        let isSelected = viewModel.method == method

        return Button {
            viewModel.method = method
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: method.symbolName)
                    .font(.sfTitleS)
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                Text(viewModel.methodName(method))
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)
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

    // MARK: L07 — processing

    private var processing: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(spacing: Spacing.s3) {
                ProgressView()
                Text(viewModel.processingTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
            }

            Text(viewModel.processingNote)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.neverDoubleTitle)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: L08 — success receipt

    private func success(subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            Label {
                Text(viewModel.successTitle).font(.sfTitleM)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .foregroundStyle(ColorTokens.success)

            Text(viewModel.successBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let receipt = viewModel.receipt {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(viewModel.receiptTitle)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)

                    ForEach(viewModel.receiptRows(receipt)) { row in
                        SFDetailRow(row: row)
                    }
                }
                .padding(Spacing.s4)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
            }

            VStack(alignment: .leading, spacing: Spacing.s3) {
                Text(viewModel.unlockedTitle)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                ForEach(viewModel.unlockedRows(subscription.plan)) { row in
                    SFDetailRow(row: row)
                }
            }
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))

            SFPrimaryButton(title: viewModel.doneTitle, action: onFinish)
        }
    }

    // MARK: L09 — failure

    private func failure(reason: PaymentFailureReason) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            SFErrorBanner(error: reason.asAppError)

            if viewModel.canRetrySameMethod {
                SFPrimaryButton(
                    title: viewModel.retryTitle,
                    action: { Task { await viewModel.pay() } }
                )
            }

            Button(viewModel.otherMethodTitle) { viewModel.chooseAnotherMethod() }
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }
}

// MARK: - Previews

#Preview("L04 Payment method") {
    NavigationStack {
        PaymentView(
            container: .previewing(),
            order: Order(
                uid: "uid_preview",
                plan: .plus,
                term: .annual,
                subtotalFils: 17_273,
                discountFils: 0,
                vatFils: 1_727,
                totalFils: 19_000,
                currency: MoneyCurrency.bhd,
                promoCode: nil
            )
        )
    }
}
