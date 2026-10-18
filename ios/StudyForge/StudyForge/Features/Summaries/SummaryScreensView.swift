import SwiftUI

struct SummaryScreensView: View {

    @State private var viewModel: SummaryScreensViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let onMakeCards: ((GeneratedSummary) -> Void)?
    private let onUpgrade: (() -> Void)?
    private let onOpenSource: ((SummarySource) -> Void)?

    init(
        material: Material,
        engine: SummaryEngine = .cloud,
        usedToday: Int = 0,
        dailyLimit: Int = 3,
        onMakeCards: ((GeneratedSummary) -> Void)? = nil,
        onUpgrade: (() -> Void)? = nil,
        onOpenSource: ((SummarySource) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: SummaryScreensViewModel(
            material: material,
            engine: engine,
            usedToday: usedToday,
            dailyLimit: dailyLimit
        ))
        self.onMakeCards = onMakeCards
        self.onUpgrade = onUpgrade
        self.onOpenSource = onOpenSource
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            Group {
                switch viewModel.step {
                case .configure:
                    SummaryConfigureView(viewModel: viewModel, onClose: { dismiss() })
                case .generating:
                    SummaryGeneratingView(viewModel: viewModel)
                case .result:
                    if let summary = viewModel.summary {
                        SummaryResultView(
                            viewModel: viewModel,
                            summary: summary,
                            onMakeCards: onMakeCards,
                            onOpenSource: onOpenSource
                        )
                    } else {
                        Color.clear.onAppear { viewModel.backToConfigure() }
                    }
                case .quotaExceeded:
                    SummaryQuotaView(viewModel: viewModel, onUpgrade: onUpgrade)
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.step)
        .interactiveDismissDisabled(viewModel.step == .generating || (viewModel.step == .result && !viewModel.isSaved))
    }
}

#Preview("F03 Summary") {
    SummaryScreensView(material: Material.samples[0])
}

#Preview("F03 Quota") {
    SummaryScreensView(material: Material.samples[0], usedToday: 3)
}
