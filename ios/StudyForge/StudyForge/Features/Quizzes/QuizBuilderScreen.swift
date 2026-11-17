import SwiftUI

struct QuizBuilderScreen: View {

    static let revealStepMilliseconds = 90

    @State private var viewModel: QuizBuilderViewModel
    @State private var generationTask: Task<Void, Never>?
    @State private var revealedCount = 0
    @State private var isRevealing = false
    @State private var playingQuiz: Quiz?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocusFieldActive: Bool

    private let quizStore: any QuizStore
    private let log: any QuizAttemptLog
    private let drafts: any QuizDraftStore
    private let plans: (any StudyPlanStore)?
    private let onFinish: () -> Void
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        quizStore: any QuizStore,
        router: AIRouter,
        log: any QuizAttemptLog = FileQuizAttemptLog.shared,
        drafts: any QuizDraftStore = FileQuizDraftStore.shared,
        plans: (any StudyPlanStore)? = nil,
        learningStyle: LearningStyle = .visual,
        onFinish: @escaping () -> Void = {}
    ) {
        self.quizStore = quizStore
        self.log = log
        self.drafts = drafts
        self.plans = plans
        self.onFinish = onFinish
        _viewModel = State(initialValue: QuizBuilderViewModel(
            initialMaterial: initialMaterial,
            materialStore: materialStore,
            quizStore: quizStore,
            router: router,
            learningStyle: learningStyle
        ))
    }

    private var isBusy: Bool { viewModel.isGenerating || isRevealing }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            Group {
                if isBusy {
                    generating
                } else {
                    switch viewModel.phase {
                    case .choosingSource: sourcePicker
                    case .configuring, .generating, .ready: configure
                    }
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: isBusy)
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.phase)
        .interactiveDismissDisabled(isBusy)
        .task { await viewModel.loadMaterials() }
        .onDisappear { generationTask?.cancel() }
        .fullScreenCover(item: $playingQuiz, onDismiss: finish) { quiz in
            QuizPlayerView(quiz: quiz, store: quizStore, log: log, drafts: drafts, plans: plans)
        }
    }

    private func finish() {
        onFinish()
        dismiss()
    }

    private var topBar: some View {
        HStack {
            if viewModel.phase == .configuring && !viewModel.startedWithMaterial {
                Button {
                    viewModel.changeMaterial()
                } label: {
                    Label(L10n.commonBack.string, systemImage: "chevron.backward")
                }
            }
            Spacer()
            Button(L10n.commonCancel.string) { dismiss() }
        }
        .font(.sfCallout)
        .tint(ColorTokens.primary)
        .frame(minHeight: Layout.minTouchTarget)
    }

    private func titleBlock(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(title)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Label(subtitle, systemImage: "doc.text")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.sfFootnote.weight(.semibold))
            .foregroundStyle(ColorTokens.textSecondary)
    }

    private var sourcePicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                topBar
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(QuizCopy.builderTitle)
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(QuizCopy.chooseMaterial)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                if !viewModel.hasLoadedMaterials {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.s8)
                } else if viewModel.materials.isEmpty && viewModel.error == nil {
                    Label(QuizCopy.noMaterials, systemImage: "tray")
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .padding(Spacing.s4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .summaryGlass(strong: true)
                }

                ForEach(viewModel.materials) { material in
                    Button {
                        viewModel.choose(material)
                    } label: {
                        materialRow(material)
                    }
                    .buttonStyle(.plain)
                }

                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: nil)
                }
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    private func materialRow(_ material: Material) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: material.source.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(width: Spacing.s6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(material.title)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(material.source.title)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget + Spacing.s3, alignment: .leading)
        .summaryGlass(strong: true)
        .contentShape(Rectangle())
    }

    private var configure: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                topBar
                titleBlock(QuizCopy.builderTitle, subtitle: viewModel.selectedMaterial?.title)

                SummaryOptionPicker(
                    title: QuizCopy.typeLabel,
                    options: QuizQuestionType.allCases,
                    selection: $viewModel.questionType,
                    optionTitle: { QuizCopy.typeShortTitle($0) }
                )

                countField

                SummaryOptionPicker(
                    title: QuizCopy.difficultyLabel,
                    options: QuizDifficulty.allCases,
                    selection: $viewModel.difficulty,
                    optionTitle: { QuizCopy.difficultyTitle($0) }
                )

                timerField

                focusField

                if viewModel.isSourceTooShort {
                    warning(QuizCopy.tooShort)
                }

                if let message = viewModel.generationMessage {
                    warning(message)
                }

                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { startGeneration() })
                }

                SFPrimaryButton(title: viewModel.generateTitle, isEnabled: viewModel.canGenerate) {
                    startGeneration()
                }
                .padding(.top, Spacing.s2)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func warning(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.warningText)
            .padding(Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .summaryGlass()
    }

    private var countBinding: Binding<Int> {
        Binding(
            get: { viewModel.count },
            set: { viewModel.setCount($0) }
        )
    }

    private var countField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(QuizCopy.countLabel)
            Stepper(
                value: countBinding,
                in: QuizBuilderViewModel.countRange,
                step: QuizBuilderViewModel.countStep
            ) {
                Text(viewModel.count.formatted())
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .monospacedDigit()
            }
            .accessibilityLabel(QuizCopy.countLabel)
            .accessibilityValue(QuizCopy.questionCount(viewModel.count))
            .padding(.horizontal, Spacing.s4)
            .frame(minHeight: 52)
            .summaryGlass()
        }
    }

    private var timerField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(QuizCopy.timerLabel)
            VStack(spacing: 0) {
                Toggle(isOn: $viewModel.timerEnabled) {
                    Text(viewModel.timerEnabled ? QuizCopy.minutes(viewModel.timerMinutes) : QuizCopy.timerOff)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                .tint(ColorTokens.primary)
                .frame(minHeight: 52)

                if viewModel.timerEnabled {
                    Picker(QuizCopy.timerLabel, selection: $viewModel.timerMinutes) {
                        ForEach(QuizBuilderViewModel.timerOptions, id: \.self) { minutes in
                            Text(minutes.formatted()).tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, Spacing.s3)
                    .accessibilityValue(QuizCopy.minutes(viewModel.timerMinutes))
                }
            }
            .padding(.horizontal, Spacing.s4)
            .summaryGlass()
        }
    }

    private var focusField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(QuizCopy.focusLabel)
            TextField(QuizCopy.focusPlaceholder, text: $viewModel.focusText, axis: .vertical)
                .font(.sfCallout)
                .lineLimit(1...3)
                .focused($isFocusFieldActive)
                .submitLabel(.done)
                .onChange(of: viewModel.focusText) { viewModel.limitFocus() }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
                .frame(minHeight: 52)
                .summaryGlass()
            Text(QuizCopy.focusFooter)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
            if !viewModel.focusTopics.isEmpty {
                SFChipFlow(spacing: Spacing.s2) {
                    ForEach(viewModel.focusTopics, id: \.self) { topic in
                        QuizTopicChip(title: topic)
                    }
                }
            }
        }
    }

    private var generating: some View {
        let total = viewModel.quiz?.questions.count ?? viewModel.count
        let done = viewModel.quiz == nil ? 0 : min(revealedCount, total)

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                Text(QuizCopy.generatingTitle)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .padding(.top, Spacing.s12)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.settingsSummary)
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.onPrimaryContainer)
                    .padding(.horizontal, Spacing.s3)
                    .frame(minHeight: 26)
                    .background(ColorTokens.primaryContainer, in: .capsule)

                Text(QuizCopy.generatingProgress(done, total))
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.s6)

                FlashcardProgressBar(fraction: total == 0 ? 0 : Double(done) / Double(total))

                if viewModel.quiz == nil {
                    Text(QuizCopy.preparing)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Label(QuizCopy.grounded, systemImage: "checkmark.seal.fill")
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.successText)
                    Text(QuizCopy.groundedBody)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass(strong: true)
                .padding(.top, Spacing.s4)

                if viewModel.droppedCount > 0 {
                    Text(QuizCopy.dropped(viewModel.droppedCount))
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.warningText)
                }
            }
            .padding(.horizontal, margin)
            .accessibilityElement(children: .combine)
            .accessibilityValue(QuizCopy.generatingProgress(done, total))
            .accessibilityAddTraits(.updatesFrequently)

            Spacer(minLength: Spacing.s6)

            Button(L10n.commonCancel.string) {
                cancelGeneration()
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    private func startGeneration() {
        guard viewModel.canGenerate else { return }
        isFocusFieldActive = false
        revealedCount = 0
        generationTask?.cancel()
        generationTask = Task {
            await viewModel.generate()
            guard !Task.isCancelled, let quiz = viewModel.quiz else { return }
            await reveal(quiz)
        }
    }

    private func reveal(_ quiz: Quiz) async {
        isRevealing = true
        defer { isRevealing = false }
        if reduceMotion {
            revealedCount = quiz.questions.count
        } else {
            for step in 1...max(quiz.questions.count, 1) {
                try? await Task.sleep(for: .milliseconds(Self.revealStepMilliseconds))
                if Task.isCancelled { return }
                revealedCount = step
            }
        }
        try? await Task.sleep(for: .milliseconds(Self.revealStepMilliseconds * 3))
        guard !Task.isCancelled else { return }
        playingQuiz = quiz
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isRevealing = false
        revealedCount = 0
        if let quiz = viewModel.quiz {
            viewModel.startOver()
            Task { try? await quizStore.delete(id: quiz.id) }
        }
    }
}

#Preview("52 Make a quiz") {
    QuizBuilderScreen(
        initialMaterial: Material.samples.first,
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        quizStore: InMemoryQuizStore(),
        router: AIRouter.standard(governor: AICostGovernor()),
        log: InMemoryQuizAttemptLog(),
        drafts: InMemoryQuizDraftStore()
    )
}
