import SwiftUI

struct QuizzesHomeView: View {

    @State private var viewModel: QuizzesHomeViewModel
    @State private var isCreating = false
    @State private var playingQuiz: Quiz?
    @State private var historyQuiz: Quiz?
    @State private var pendingRetake: Quiz?
    @State private var quizToDelete: Quiz?

    private let materialStore: any MaterialStore
    private let quizStore: any QuizStore
    private let router: AIRouter
    private let log: any QuizAttemptLog
    private let drafts: any QuizDraftStore
    private let plans: (any StudyPlanStore)?
    private let learningStyle: LearningStyle
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        materialStore: any MaterialStore,
        quizStore: any QuizStore,
        router: AIRouter,
        log: any QuizAttemptLog = FileQuizAttemptLog.shared,
        drafts: any QuizDraftStore = FileQuizDraftStore.shared,
        plans: (any StudyPlanStore)? = nil,
        learningStyle: LearningStyle = .visual
    ) {
        self.materialStore = materialStore
        self.quizStore = quizStore
        self.router = router
        self.log = log
        self.drafts = drafts
        self.plans = plans
        self.learningStyle = learningStyle
        _viewModel = State(initialValue: QuizzesHomeViewModel(store: quizStore, log: log, drafts: drafts))
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { quizToDelete != nil },
            set: { if !$0 { quizToDelete = nil } }
        )
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    header
                    content
                }
                .padding(.horizontal, margin)
                .padding(.bottom, Spacing.s6)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isCreating, onDismiss: reload) {
            QuizBuilderScreen(
                initialMaterial: nil,
                materialStore: materialStore,
                quizStore: quizStore,
                router: router,
                log: log,
                drafts: drafts,
                plans: plans,
                learningStyle: learningStyle
            )
        }
        .fullScreenCover(item: $playingQuiz, onDismiss: reload) { quiz in
            QuizPlayerView(quiz: quiz, store: quizStore, log: log, drafts: drafts, plans: plans)
        }
        .sheet(item: $historyQuiz, onDismiss: startPendingRetake) { quiz in
            QuizAttemptsView(quiz: quiz, store: quizStore, log: log) {
                pendingRetake = quiz
                historyQuiz = nil
            }
        }
        .confirmationDialog(
            QuizCopy.deleteTitle,
            isPresented: isConfirmingDelete,
            titleVisibility: .visible,
            presenting: quizToDelete
        ) { quiz in
            Button(QuizCopy.deleteQuiz, role: .destructive) {
                Task { await viewModel.delete(quiz) }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: { quiz in
            Text(QuizCopy.deleteMessage(quiz.title))
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    private func startPendingRetake() {
        guard let quiz = pendingRetake else { return }
        pendingRetake = nil
        play(quiz)
    }

    private func play(_ quiz: Quiz) {
        Task {
            playingQuiz = await viewModel.quiz(id: quiz.id) ?? quiz
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            Text(QuizCopy.homeTitle)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                isCreating = true
            } label: {
                Label(QuizCopy.newQuiz, systemImage: "plus")
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.onError)
                    .padding(.horizontal, Spacing.s3)
                    .frame(minHeight: 34)
                    .background(ColorTokens.primary, in: .rect(cornerRadius: 10))
                    .frame(minHeight: Layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Spacing.s4)
        .padding(.bottom, Spacing.s3)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s10)
        } else if let error = viewModel.error, viewModel.rows.isEmpty {
            SFErrorBanner(error: error, onRecover: reload)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: reload)
            }
            ForEach(viewModel.rows) { row in
                card(row)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)
            Text(QuizCopy.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(QuizCopy.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            SFPrimaryButton(title: QuizCopy.makeQuiz) {
                isCreating = true
            }
        }
        .padding(Spacing.s6)
        .frame(maxWidth: .infinity)
        .summaryGlass(cornerRadius: 14, strong: true)
        .padding(.top, Spacing.s6)
    }

    private func actionTitle(_ row: QuizSummaryRow) -> String {
        if row.hasDraft { return QuizCopy.resume }
        return row.latest == nil ? QuizCopy.start : QuizCopy.retake
    }

    private func card(_ row: QuizSummaryRow) -> some View {
        let date = row.lastActivity.formatted(.relative(presentation: .named))
        let score = row.latest.map { QuizCopy.scoreLine($0.scoreText, QuizCopy.percent($0.percent)) }

        return VStack(alignment: .leading, spacing: Spacing.s2) {
            Button {
                historyQuiz = row.quiz
            } label: {
                HStack(alignment: .top, spacing: Spacing.s3) {
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(row.quiz.title)
                            .font(.sfSubhead)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(row.hasDraft ? QuizCopy.inProgress : date)
                            .font(.sfFootnote)
                            .foregroundStyle(row.hasDraft ? ColorTokens.warningText : ColorTokens.textSecondary)
                    }
                    Spacer(minLength: 0)
                    if let latest = row.latest, let score {
                        QuizScorePill(text: score, tone: latest.tone)
                    } else {
                        Text(QuizCopy.notTaken)
                            .font(.sfCaption.weight(.semibold))
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(QuizCopy.rowAccessibility(row.quiz.title, score ?? QuizCopy.notTaken, date))
            .accessibilityHint(QuizCopy.history)

            HStack(alignment: .center, spacing: Spacing.s2) {
                if !row.missedTopics.isEmpty {
                    Text(QuizCopy.missed)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                    ForEach(row.missedTopics, id: \.self) { topic in
                        QuizTopicChip(title: topic)
                    }
                } else {
                    Text(QuizCopy.questionCount(row.questionCount))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer(minLength: 0)
                Button(actionTitle(row)) {
                    play(row.quiz)
                }
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.s4)
                .frame(minHeight: 34)
                .overlay(Capsule().strokeBorder(ColorTokens.outline, lineWidth: 1))
                .frame(minHeight: Layout.minTouchTarget)
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(cornerRadius: 14, strong: true)
        .contextMenu {
            Button {
                historyQuiz = row.quiz
            } label: {
                Label(QuizCopy.history, systemImage: "chart.bar")
            }
            Button(role: .destructive) {
                quizToDelete = row.quiz
            } label: {
                Label(QuizCopy.deleteQuiz, systemImage: "trash")
            }
        }
    }
}

#Preview("51 Quizzes") {
    NavigationStack {
        QuizzesHomeView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            quizStore: InMemoryQuizStore(seededWith: [QuizPreviewData.takenQuiz]),
            router: AIRouter.standard(governor: AICostGovernor()),
            log: InMemoryQuizAttemptLog(seededWith: [QuizPreviewData.takenRecord]),
            drafts: InMemoryQuizDraftStore()
        )
    }
}

#Preview("51 Quizzes — empty") {
    NavigationStack {
        QuizzesHomeView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            quizStore: InMemoryQuizStore(),
            router: AIRouter.standard(governor: AICostGovernor()),
            log: InMemoryQuizAttemptLog(),
            drafts: InMemoryQuizDraftStore()
        )
    }
}
