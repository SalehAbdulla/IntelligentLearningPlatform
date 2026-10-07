//
//  CheckoutView.swift
//  StudyForge
//
//  L03 — `120_Checkout_OrderSummary_BHD_{M3}` (docs/03 §L, P0). The order summary: plan and
//  term, subtotal / discount / VAT / total in BHD, a promo-code field, the terms checkbox
//  and the one primary action that opens payment.
//
//  WHY TERMS GATE THE BUTTON
//  -------------------------
//  A subscription is a commitment, and the design asks for an explicit agreement. Making
//  it a real gate rather than a decorative checkbox is a one-line change here and an
//  honest one to describe in the VIVA: the payment cannot start until it is ticked.
//

import SwiftUI

// Accessibility: the order-summary rows and the pay button are already covered by the shared
// components (`SFDetailRow` announces a label and a value; `SFPrimaryButton` announces its working
// state), so this screen only has to hide the decorative divider between the subtotal and the total.

struct CheckoutView: View {

    let container: AppContainer

    /// Called when the payment flow finishes, so the checkout itself pops too.
    let onFinish: () -> Void

    @State private var viewModel: CheckoutViewModel
    @State private var showingPayment = false

    init(
        container: AppContainer,
        plan: SubscriptionPlan,
        term: BillingTerm,
        onFinish: @escaping () -> Void = {}
    ) {
        self.container = container
        self.onFinish = onFinish
        _viewModel = State(initialValue: CheckoutViewModel(
            uid: container.session?.id ?? "",
            plan: plan,
            term: term
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                summary
                promo
                terms
                SFPrimaryButton(
                    title: viewModel.proceedTitle,
                    isEnabled: viewModel.canProceed,
                    action: { showingPayment = true }
                )
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingPayment) {
            if let order = viewModel.order {
                PaymentView(container: container, order: order, onFinish: onFinish)
            }
        }
    }

    // MARK: Order summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFDetailRow(row: DetailRow(id: "plan", label: viewModel.planLabel, value: viewModel.planValue))
            SFDetailRow(row: DetailRow(id: "term", label: viewModel.termLabel, value: viewModel.termValue))
            SFDetailRow(row: DetailRow(id: "subtotal", label: viewModel.subtotalLabel, value: viewModel.subtotalValue))

            if viewModel.hasDiscount {
                SFDetailRow(row: DetailRow(id: "discount", label: viewModel.discountLabel, value: viewModel.discountValue))
            }

            SFDetailRow(row: DetailRow(id: "vat", label: viewModel.vatLabel, value: viewModel.vatValue))

            Divider()
                .accessibilityHidden(true)

            SFDetailRow(row: DetailRow(id: "total", label: viewModel.totalLabel, value: viewModel.totalValue))
        }
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Promo (L03)

    private var promo: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(alignment: .bottom, spacing: Spacing.s3) {
                SFTextField(
                    label: viewModel.promoLabel,
                    text: $viewModel.promoInput,
                    placeholder: viewModel.promoPlaceholder,
                    submitLabel: .done,
                    onSubmit: { viewModel.applyPromo() }
                )

                Button(viewModel.promoApplyTitle) { viewModel.applyPromo() }
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget)
            }

            if let message = viewModel.promoMessage {
                Text(message)
                    .font(.sfFootnote)
                    .foregroundStyle(viewModel.promoIsError ? ColorTokens.error : ColorTokens.successText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Terms

    private var terms: some View {
        Toggle(viewModel.termsTitle, isOn: $viewModel.termsAccepted)
            .font(.sfCallout)
            .tint(ColorTokens.primary)
    }
}

// MARK: - Previews

#Preview("L03 Order summary") {
    NavigationStack {
        CheckoutView(container: .previewing(), plan: .plus, term: .annual)
    }
}
