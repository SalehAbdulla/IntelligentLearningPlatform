import SwiftUI

struct QuizPlayerView: View {

    private struct Run: Identifiable {
        let id = UUID()
        let questions: [QuizQuestion]?
    }

    @State private var quiz: Quiz
    @State private var run = Run(questions: nil)

    private let store: any QuizStore
    private let log: any QuizAttemptLog
    private let drafts: any QuizDraftStore
    private let plans: (any StudyPlanStore)?

    init(
        quiz: Quiz,
        store: any QuizStore,
        log: any QuizAttemptLog = FileQuizAttemptLog.shared,
        drafts: any QuizDraftStore = FileQuizDraftStore.shared,
        plans: (any StudyPlanStore)? = nil
    ) {
        _quiz = State(initialValue: quiz)
        self.store = store
        self.log = log
        self.drafts = drafts
        self.plans = plans
    }

    var body: some View {
        QuizSessionView(
            quiz: quiz,
            questions: run.questions,
            store: store,
            log: log,
            drafts: drafts,
            plans: plans
        ) { updated, questions in
            quiz = updated
            run = Run(questions: questions)
        }
        .id(run.id)
    }
}

struct QuizSessionView: View {

    @State private var viewModel: QuizSessionViewModel
    @State private var offline = OfflineMonitor()
    @State private var isConfirmingLeave = false
    @State private var isReviewing = false
    @State private var isShowingAttempts = false
    @State private var retakesAfterAttempts = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isAnswerFieldFocused: Bool

    private let store: any QuizStore
    private let log: any QuizAttemptLog
    private let onRetake: (Quiz, [QuizQuestion]?) -> Void
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        quiz: Quiz,
        questions: [QuizQuestion]? = nil,
        store: any QuizStore,
        log: any QuizAttemptLog,
        drafts: any QuizDraftStore,
        plans: (any StudyPlanStore)?,
        onRetake: @escaping (Quiz, [QuizQuestion]?) -> Void
    ) {
        self.store = store
        self.log = log
        self.onRetake = onRetake
        _viewModel = State(initialValue: QuizSessionViewModel(
            quiz: quiz,
            questions: questions,
            store: store,
            log: log,
            drafts: drafts,
            plans: plans
        ))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            Group {
                if viewModel.phase == .finished {
                    finished
                } else if let question = viewModel.currentQuestion {
                    questionScreen(question)
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.phase)
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: viewModel.currentIndex)
        .onReceive(ticker) { _ in
            Task { await viewModel.tick() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await viewModel.tick() }
            case .background: Task { await viewModel.pause() }
            default: break
            }
        }
        .task {
            offline.start()
            await viewModel.resume()
        }
        .onDisappear { offline.stop() }
        .sensoryFeedback(trigger: viewModel.currentOutcome) { _, outcome in
            Self.feedback(for: outcome)
        }
        .alert(QuizCopy.submitTitle, isPresented: confirmingSubmit) {
            Button(QuizCopy.submitNow) {
                Task { await viewModel.confirmSubmit() }
            }
            Button(QuizCopy.reviewUnanswered) {
                viewModel.reviewUnanswered()
            }
            Button(L10n.commonCancel.string, role: .cancel) {
                viewModel.cancelSubmit()
            }
        } message: {
            Text(submitMessage)
        }
        .alert(QuizCopy.leaveTitle, isPresented: $isConfirmingLeave) {
            Button(QuizCopy.leave, role: .destructive) {
                Task {
                    await viewModel.pause()
                    dismiss()
                }
            }
            Button(QuizCopy.keepGoing, role: .cancel) {}
        } message: {
            Text(QuizCopy.leaveMessage)
        }
        .sheet(isPresented: $isReviewing) {
            if let result = viewModel.result {
                QuizAnswerReviewView(result: result)
            }
        }
        .sheet(isPresented: $isShowingAttempts, onDismiss: retakeAfterAttemptsIfNeeded) {
            QuizAttemptsView(quiz: viewModel.quiz, store: store, log: log) {
                retakesAfterAttempts = true
                isShowingAttempts = false
            }
        }
    }

    nonisolated private static func feedback(for outcome: QuizOutcome?) -> SensoryFeedback? {
        guard let outcome else { return nil }
        switch outcome {
        case .correct: return .success
        case .partial: return .warning
        case .incorrect: return .error
        case .skipped: return nil
        }
    }

    private var confirmingSubmit: Binding<Bool> {
        Binding(
            get: { viewModel.isConfirmingSubmit },
            set: { if !$0 { viewModel.cancelSubmit() } }
        )
    }

    private var submitMessage: String {
        var parts = [
            QuizCopy.unanswered(viewModel.unansweredNumbers.count),
            QuizCopy.unansweredBody(viewModel.unansweredNumbers)
        ]
        if let time = viewModel.timeText {
            parts.append(QuizCopy.submitTimeLeft(time))
        }
        return parts.joined(separator: "\n")
    }

    private func retakeAfterAttemptsIfNeeded() {
        guard retakesAfterAttempts else { return }
        retakesAfterAttempts = false
        onRetake(viewModel.quiz, nil)
    }

    private var header: some View {
        HStack(spacing: Spacing.s3) {
            Button {
                isConfirmingLeave = true
            } label: {
                Image(systemName: "xmark")
                    .font(.sfBody.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(QuizCopy.closeQuiz)

            Text(viewModel.progressText)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()

            Spacer(minLength: 0)

            if let time = viewModel.timeText {
                QuizTimerBadge(text: time, isLow: viewModel.isRunningLow)
            }

            Button(QuizCopy.submit) {
                Task { await viewModel.requestSubmit() }
            }
            .font(.sfCallout.weight(.semibold))
            .tint(ColorTokens.primary)
            .frame(minHeight: Layout.minTouchTarget)
            .disabled(viewModel.isSaving)
        }
    }

    private func questionScreen(_ question: QuizQuestion) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.s2) {
                header
                FlashcardProgressBar(fraction: viewModel.progressFraction)
                if offline.isOffline {
                    Label(QuizCopy.offline, systemImage: "wifi.slash")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, margin)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    if viewModel.isWeakTopicRetake {
                        QuizTopicChip(title: QuizCopy.weakRetake)
                    }

                    Text(question.stem)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    if viewModel.isLowConfidence(question) {
                        Label(QuizCopy.lowConfidence, systemImage: "exclamationmark.triangle.fill")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.warningText)
                    }

                    if QuizQuestionKind(question) == .shortAnswer {
                        shortAnswer(question)
                    } else {
                        options(question)
                    }

                    if viewModel.phase == .feedback {
                        feedbackPanel(question)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    flagButton(question)
                }
                .padding(.horizontal, margin)
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s4)
            }
            .scrollDismissesKeyboard(.interactively)

            footer(question)
                .padding(.horizontal, margin)
                .padding(.bottom, Spacing.s4)
        }
    }

    private func optionState(_ index: Int, in question: QuizQuestion) -> QuizOptionState {
        guard viewModel.phase == .feedback else {
            return viewModel.pendingOption == index ? .selected : .idle
        }
        let chosen = viewModel.currentResponse?.selectedOptionIndex
        if index == question.correctOptionIndex { return .correct }
        if index == chosen { return .chosenWrong }
        return .dimmed
    }

    private func optionTag(_ state: QuizOptionState, in question: QuizQuestion) -> String? {
        let choseWrong = viewModel.currentResponse.map { !$0.isCorrect } ?? false
        switch state {
        case .correct where choseWrong: return QuizCopy.correctTag
        case .chosenWrong: return QuizCopy.yoursTag
        default: return nil
        }
    }

    private func options(_ question: QuizQuestion) -> some View {
        VStack(spacing: Spacing.s3) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                let state = optionState(index, in: question)
                Button {
                    viewModel.choose(index)
                } label: {
                    QuizOptionRow(
                        text: option,
                        state: state,
                        tag: optionTag(state, in: question),
                        accessibilityText: QuizCopy.option(index + 1, question.options.count, option)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.phase != .answering)
                .accessibilityAddTraits(state == .selected ? .isSelected : [])
            }
        }
    }

    private func shortAnswer(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if viewModel.phase == .answering {
                TextField(QuizCopy.answerPlaceholder, text: $viewModel.draftAnswer, axis: .vertical)
                    .font(.sfCallout)
                    .lineLimit(1...4)
                    .focused($isAnswerFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { viewModel.check() }
                    .onChange(of: viewModel.draftAnswer) {
                        if viewModel.draftAnswer.count > QuizAnswerMarker.maxAnswerLength {
                            viewModel.draftAnswer = QuizAnswerMarker.limited(viewModel.draftAnswer)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s3)
                    .frame(minHeight: 52)
                    .summaryGlass(strong: true)
            } else if let typed = viewModel.typedAnswers[question.id] {
                Text(QuizCopy.yourTypedAnswer(typed))
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .summaryGlass(strong: true)
            }
        }
    }

    private func outcomeLabel(_ outcome: QuizOutcome) -> some View {
        let (title, symbol, color): (String, String, Color) = switch outcome {
        case .correct: (QuizCopy.correct, "checkmark.circle.fill", ColorTokens.successText)
        case .partial: (QuizCopy.partial, "circle.lefthalf.filled", ColorTokens.warningText)
        case .incorrect, .skipped: (QuizCopy.incorrect, "xmark.circle.fill", ColorTokens.error)
        }
        return Label(title, systemImage: symbol)
            .font(.sfSubhead)
            .foregroundStyle(color)
    }

    private func feedbackPanel(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if let outcome = viewModel.currentOutcome {
                outcomeLabel(outcome)
            }
            if QuizQuestionKind(question) == .shortAnswer, question.options.indices.contains(question.correctOptionIndex) {
                Text(QuizCopy.modelAnswer(question.options[question.correctOptionIndex]))
                    .font(.sfCallout.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            if !question.explanation.isEmpty {
                Text(question.explanation)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.s2) {
                QuizCitationChip(label: viewModel.citationLabel(for: question))
                QuizTopicChip(title: QuizCopy.topicTag(question.topic))
                Spacer(minLength: 0)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(strong: true)
        .accessibilityElement(children: .combine)
    }

    private func flagButton(_ question: QuizQuestion) -> some View {
        HStack {
            Spacer()
            Button {
                viewModel.toggleFlag()
            } label: {
                Label(
                    viewModel.isFlagged(question) ? QuizCopy.unflag : QuizCopy.flag,
                    systemImage: viewModel.isFlagged(question) ? "flag.fill" : "flag"
                )
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(viewModel.isFlagged(question) ? ColorTokens.warningText : ColorTokens.textSecondary)
                .frame(minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func footer(_ question: QuizQuestion) -> some View {
        if viewModel.phase == .feedback {
            VStack(spacing: Spacing.s2) {
                SFPrimaryButton(
                    title: viewModel.isLastQuestion ? QuizCopy.seeResults : QuizCopy.nextQuestion,
                    isLoading: viewModel.isSaving
                ) {
                    Task { await viewModel.next() }
                }
                if viewModel.currentOutcome != .correct && viewModel.canAddToPlan {
                    Button {
                        Task { await viewModel.addToRevisionPlan() }
                    } label: {
                        Label(
                            viewModel.isInRevisionPlan(question) ? QuizCopy.addedToPlan : QuizCopy.addToPlan,
                            systemImage: viewModel.isInRevisionPlan(question) ? "checkmark" : "plus"
                        )
                    }
                    .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
                    .disabled(viewModel.isInRevisionPlan(question) || viewModel.isAddingToPlan)
                }
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: nil)
                }
            }
        } else {
            HStack(spacing: Spacing.s3) {
                Button(QuizCopy.skip) {
                    isAnswerFieldFocused = false
                    Task { await viewModel.skip() }
                }
                .buttonStyle(SummarySecondaryButtonStyle(outlined: true))

                SFPrimaryButton(title: QuizCopy.next, isEnabled: viewModel.canCheck) {
                    isAnswerFieldFocused = false
                    viewModel.check()
                }
            }
        }
    }

    @ViewBuilder
    private var finished: some View {
        if let result = viewModel.result {
            QuizScorecardView(
                result: result,
                error: viewModel.error,
                onReview: { isReviewing = true },
                onRetakeWeak: { onRetake(viewModel.quiz, result.weakQuestions) },
                onRetakeAll: { onRetake(viewModel.quiz, nil) },
                onAllAttempts: { isShowingAttempts = true },
                onDone: { dismiss() }
            )
        } else {
            VStack(spacing: Spacing.s4) {
                Text(QuizCopy.noAttempts)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                Button(QuizCopy.done) { dismiss() }
                    .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            }
            .padding(margin)
        }
    }
}

#Preview("54 Take quiz") {
    QuizPlayerView(
        quiz: QuizPreviewData.treesQuiz,
        store: InMemoryQuizStore(seededWith: [QuizPreviewData.treesQuiz]),
        log: InMemoryQuizAttemptLog(),
        drafts: InMemoryQuizDraftStore(),
        plans: InMemoryStudyPlanStore()
    )
}
