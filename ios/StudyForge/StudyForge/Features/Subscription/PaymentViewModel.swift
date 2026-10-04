//
//  PaymentViewModel.swift
//  StudyForge
//
//  F13 — presentation logic for the payment flow: L04 method select, L07 processing,
//  L08 success receipt and L09 failure (docs/03 §L, all P0).
//
//  WHY THE FOUR SCREENS ARE ONE PHASE MACHINE
//  ------------------------------------------
//  The design draws them as separate frames, but they are one transaction with one state:
//  choosing a method, the charge in flight, and then either a receipt or a reason. Modelling
//  them as an enum means the UI cannot show a receipt and a failure at once, and it cannot
//  forget to stop showing "processing" — the two bugs this kind of flow actually ships with.
//

import Foundation

@MainActor
@Observable
final class PaymentViewModel {

    /// Where the transaction is (L04 → L07 → L08 / L09).
    enum Phase: Equatable {
        case choosing
        case processing
        case succeeded(receipt: PaymentRecord, subscription: Subscription)
        case failed(reason: PaymentFailureReason)
    }

    // MARK: Bound state

    /// The selected payment method (L04).
    var method: PaymentMethod = .card

    private(set) var phase: Phase = .choosing

    /// A failure that happened BEFORE a charge — e.g. no signed-in account. Distinct from
    /// a declined payment, which the failure screen renders.
    private(set) var error: AppError?

    let order: Order

    private let gateway: any PaymentGateway

    init(order: Order, gateway: any PaymentGateway) {
        self.order = order
        self.gateway = gateway
    }

    // MARK: Derived

    var methods: [PaymentMethod] { PaymentMethod.allCases }

    var isProcessing: Bool { if case .processing = phase { return true }; return false }

    var receipt: PaymentRecord? {
        if case .succeeded(let receipt, _) = phase { return receipt }
        return nil
    }

    var failureReason: PaymentFailureReason? {
        if case .failed(let reason) = phase { return reason }
        return nil
    }

    /// Whether the L09 failure screen should offer "Retry" for the SAME method or only
    /// "Try another method". A declined card will decline again; a timeout may not.
    var canRetrySameMethod: Bool { failureReason?.isRetryable ?? false }

    // MARK: Copy

    var title: String { L10n.subscriptionPaymentTitle.string }
    var methodTitle: String { L10n.subscriptionMethodTitle.string }
    var secureNote: String { L10n.subscriptionSecureNote.string }
    var redirectNote: String { L10n.subscriptionRedirectNote.string }
    var processingTitle: String { L10n.subscriptionProcessing.string }
    var processingNote: String { L10n.subscriptionProcessingNote.string }
    var neverDoubleTitle: String { L10n.subscriptionNeverDouble.string }
    var successTitle: String { L10n.subscriptionSuccessTitle.string }
    var receiptTitle: String { L10n.subscriptionReceipt.string }
    var unlockedTitle: String { L10n.subscriptionUnlocked.string }
    var failedTitle: String { L10n.subscriptionFailedTitle.string }
    var retryTitle: String { L10n.commonRetry.string }
    var otherMethodTitle: String { L10n.subscriptionOtherMethod.string }
    var doneTitle: String { L10n.commonDone.string }

    /// The primary button: "Pay BHD 4.900".
    var payTitle: String { L10n.subscriptionPay.string(MoneyText.price(order.totalFils)) }

    var successBody: String {
        guard let subscription = subscriptionFromPhase else { return "" }
        return L10n.subscriptionSuccessBody.string(subscription.plan.displayName)
    }

    private var subscriptionFromPhase: Subscription? {
        if case .succeeded(_, let subscription) = phase { return subscription }
        return nil
    }

    // MARK: Labels

    func methodName(_ method: PaymentMethod) -> String {
        switch method {
        case .card: L10n.subscriptionMethodCard.string
        case .benefitPay: L10n.subscriptionMethodBenefitPay.string
        case .applePay: L10n.subscriptionMethodApplePay.string
        case .knet: L10n.subscriptionMethodKnet.string
        }
    }

    /// The method as the receipt shows it — with the last four when there is a card.
    func receiptMethodLabel(_ receipt: PaymentRecord) -> String {
        var label = methodName(receipt.method)
        if let last4 = receipt.last4 {
            label += " \(L10n.subscriptionCardEnding.string(last4))"
        }
        return label
    }

    /// The receipt's detail lines: amount, method, reference and date.
    func receiptRows(_ receipt: PaymentRecord) -> [DetailRow] {
        [
            DetailRow(
                id: "amount",
                label: L10n.subscriptionReceiptAmount.string,
                value: MoneyText.price(receipt.amountFils)
            ),
            DetailRow(
                id: "method",
                label: L10n.subscriptionReceiptMethod.string,
                value: receiptMethodLabel(receipt)
            ),
            DetailRow(
                id: "reference",
                label: L10n.subscriptionReceiptReference.string,
                value: receipt.tapChargeId
            ),
            DetailRow(
                id: "date",
                label: L10n.subscriptionReceiptDate.string,
                value: receipt.paidAt.formatted(date: .abbreviated, time: .shortened)
            ),
        ]
    }

    /// L08's "unlocked features" — the entitlements of the plan just bought, read from the
    /// catalogue so the receipt cannot promise something the plan does not include.
    func unlockedRows(_ plan: SubscriptionPlan) -> [DetailRow] {
        let unlimited = L10n.subscriptionUnlimited.string
        func count(_ value: Int?) -> String { value.map(String.init) ?? unlimited }

        // `dailyAIGenerationLimit` uses `Int.max` for unlimited, so it is masked here.
        let ai = plan.dailyAIGenerationLimit == .max ? unlimited : "\(plan.dailyAIGenerationLimit)"

        return [
            DetailRow(id: "ai", label: L10n.subscriptionFeatureAI.string, value: ai),
            DetailRow(id: "materials", label: L10n.subscriptionFeatureMaterials.string, value: count(plan.includedMaterials)),
            DetailRow(id: "groups", label: L10n.subscriptionFeatureGroups.string, value: count(plan.includedGroupSpaces)),
        ]
    }

    // MARK: Actions

    /// Requests the charge. On success the ENTITLEMENT comes back from the gateway, which
    /// is the only writer of it — this view model never decides that a plan is owned.
    func pay() async {
        guard !isProcessing else { return }
        error = nil
        phase = .processing

        do {
            switch try await gateway.startCheckout(order: order, method: method) {
            case .succeeded(let subscription, let receipt):
                phase = .succeeded(receipt: receipt, subscription: subscription)
            case .failed(let reason):
                phase = .failed(reason: reason)
            case .cancelled:
                phase = .choosing
            }
        } catch {
            // A thrown error means the charge never started (no session, bad plan). Show it
            // and return to choosing, so the student can act on it.
            self.error = AppError.from(error)
            phase = .choosing
        }
    }

    /// L09's "try another method" — back to the picker with the failure cleared.
    func chooseAnotherMethod() {
        error = nil
        phase = .choosing
    }
}
