import SwiftUI

struct SummaryScreensView: View {

    @State private var viewModel: SummaryScreensViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let router: AIRouter
    private let learningStyle: LearningStyle

    init(
        material: Material,
        router: AIRouter,
        store: any SummaryStore,
        learningStyle: LearningStyle = .visual
    ) {
        _viewModel = State(initialValue: SummaryScreensViewModel(
            material: material,
            router: router,
            store: store,
            learningStyle: learningStyle
        ))
        self.router = router
        self.learningStyle = learningStyle
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
                            router: router,
                            learningStyle: learningStyle
                        )
                    } else {
                        Color.clear.onAppear { viewModel.backToConfigure() }
                    }
                case .quotaExceeded:
                    SummaryQuotaView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.step)
        .interactiveDismissDisabled(viewModel.step == .generating || (viewModel.step == .result && !viewModel.isSaved))
        .onDisappear { viewModel.cancelGeneration() }
    }
}

private extension Material {
    static var previewTrees: Material {
        Material(
            title: "Lecture 4 — Trees",
            source: .pdf,
            text: PageMarker.forPage(12) + String(repeating: "A tree is a hierarchy with one root. Each node holds children, enabling fast search. A binary tree has at most two children per node, enabling logarithmic search in balanced cases. Traversal can be in-order, pre-order or post-order. A leaf is a node with no children. Height and depth measure distance from the leaves and from the root. ", count: 4),
            pageCount: 20,
            tags: ["trees", "binary tree"]
        )
    }
}

#Preview("F03 Summary") {
    SummaryScreensView(
        material: .previewTrees,
        router: AIRouter(
            providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .seconds(2))],
            governor: AICostGovernor()
        ),
        store: InMemorySummaryStore()
    )
}

#Preview("F03 Quota") {
    let governor = AICostGovernor()
    governor.seed(usedToday: governor.limit)
    return SummaryScreensView(
        material: .previewTrees,
        router: AIRouter(
            providers: [.firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)],
            governor: governor
        ),
        store: InMemorySummaryStore()
    )
}
