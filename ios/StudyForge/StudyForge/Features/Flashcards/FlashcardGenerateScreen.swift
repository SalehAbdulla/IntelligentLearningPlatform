import SwiftUI

struct FlashcardGenerateScreen: View {

    private enum DiscardIntent {
        case close
        case restart
    }

    @State private var viewModel: FlashcardGenerateViewModel
    @State private var generationTask: Task<Void, Never>?
    @State private var revealedCount = 0
    @State private var isRevealPending = false
    @State private var editorTarget: FlashcardEditorTarget?
    @State private var discardIntent: DiscardIntent = .restart
    @State private var isConfirmingDiscard = false
    @State private var studyDeck: Deck?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let deckStore: any DeckStore
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        deckStore: any DeckStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        self.deckStore = deckStore
        _viewModel = State(initialValue: FlashcardGenerateViewModel(
            initialMaterial: initialMaterial,
            materialStore: materialStore,
            deckStore: deckStore,
            router: router,
            learningStyle: learningStyle
        ))
    }

    private var isBusy: Bool {
        viewModel.isGenerating || (isRevealPending && !viewModel.cards.isEmpty)
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()

            Group {
                if isBusy {
                    generating
                } else {
                    switch viewModel.phase {
                    case .choosingSource: sourcePicker
                    case .configuring, .generating: configure
                    case .review: review
                    case .saved: saved
                    }
                }
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .transition(.opacity)
        }
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: isBusy)
        .animation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion), value: viewModel.phase)
        .interactiveDismissDisabled(isBusy || viewModel.phase == .review || viewModel.isSaving)
        .task {
            await viewModel.loadMaterials()
            await viewModel.loadDecks()
        }
        .onDisappear {
            generationTask?.cancel()
        }
        .sheet(item: $editorTarget) { target in
            editor(for: target)
        }
        .fullScreenCover(item: $studyDeck, onDismiss: { dismiss() }) { deck in
            FlashcardReviewView(deck: deck, store: deckStore)
        }
        .confirmationDialog(
            FlashcardCopy.discardCardsTitle,
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button(FlashcardCopy.discard, role: .destructive) {
                viewModel.discardCards()
                if discardIntent == .close {
                    dismiss()
                }
            }
            Button(FlashcardCopy.keepEditing, role: .cancel) {}
        } message: {
            Text(FlashcardCopy.discardCardsMessage)
        }
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
            Button(L10n.commonCancel.string) {
                if viewModel.phase == .review {
                    discardIntent = .close
                    isConfirmingDiscard = true
                } else {
                    dismiss()
                }
            }
            .disabled(viewModel.isSaving)
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
                Text(subtitle)
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

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.error {
            SFErrorBanner(error: error, onRecover: nil)
        }
    }

    private var sourcePicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                topBar
                titleBlock(FlashcardCopy.generateTitle, subtitle: FlashcardCopy.chooseMaterial)

                if !viewModel.hasLoadedMaterials && viewModel.error == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.s8)
                } else if viewModel.hasLoadedMaterials && viewModel.materials.isEmpty {
                    Label(FlashcardCopy.noMaterials, systemImage: "tray")
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

                errorBanner
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
                titleBlock(FlashcardCopy.generateTitle, subtitle: viewModel.selectedMaterial?.title)

                SummaryOptionPicker(
                    title: FlashcardCopy.countLabel,
                    options: FlashcardLimits.countOptions,
                    selection: countBinding,
                    optionTitle: { $0.formatted() }
                )

                SummaryOptionPicker(
                    title: FlashcardCopy.difficultyLabel,
                    options: FlashcardDifficulty.levels,
                    selection: difficultyBinding,
                    optionTitle: { $0.levelTitle }
                )

                SummaryOptionPicker(
                    title: FlashcardCopy.typeLabel,
                    options: CardType.allCases,
                    selection: typeBinding,
                    optionTitle: { $0.shortTitle }
                )

                rangeField

                if let materialError = viewModel.materialError {
                    Label(materialError, systemImage: "exclamationmark.triangle.fill")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.error)
                        .padding(Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .summaryGlass()
                }

                errorBanner

                SFPrimaryButton(title: viewModel.generateButtonTitle, isEnabled: viewModel.canGenerate) {
                    startGeneration()
                }
                .padding(.top, Spacing.s12 - Spacing.s6)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    private var countBinding: Binding<Int> {
        Binding(
            get: { viewModel.count ?? FlashcardLimits.defaultCount },
            set: { viewModel.count = $0 }
        )
    }

    private var difficultyBinding: Binding<FlashcardDifficulty> {
        Binding(
            get: { viewModel.difficulty ?? .mixed },
            set: { viewModel.difficulty = $0 }
        )
    }

    private var typeBinding: Binding<CardType> {
        Binding(
            get: { viewModel.cardType ?? .qa },
            set: { viewModel.cardType = $0 }
        )
    }

    private var firstPageBinding: Binding<Int> {
        Binding(
            get: { viewModel.firstPage },
            set: { viewModel.setFirstPage($0) }
        )
    }

    private var lastPageBinding: Binding<Int> {
        Binding(
            get: { viewModel.lastPage },
            set: { viewModel.setLastPage($0) }
        )
    }

    private var rangeField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(FlashcardCopy.rangeLabel)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(viewModel.rangeTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)

                if viewModel.hasPageRange {
                    Stepper(value: firstPageBinding, in: 1...viewModel.pageCount) {
                        Text(FlashcardCopy.fromPage + " " + viewModel.firstPage.formatted())
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    Stepper(value: lastPageBinding, in: 1...viewModel.pageCount) {
                        Text(FlashcardCopy.toPage + " " + viewModel.lastPage.formatted())
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(ColorTokens.outline, lineWidth: 1)
            )
        }
    }

    private var generating: some View {
        let total = viewModel.isGenerating ? viewModel.requestedCount : viewModel.cards.count
        let done = viewModel.isGenerating ? 0 : min(revealedCount, total)

        return VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    Text(FlashcardCopy.generatingHeading)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .padding(.top, Spacing.s12)

                    Label(viewModel.engine.badgeTitle, systemImage: viewModel.engine.symbolName)
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s4)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.m))

                    Text(FlashcardCopy.generatedProgress(done, total))
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.s3)

                    FlashcardProgressBar(fraction: total == 0 ? 0 : Double(done) / Double(total))

                    if viewModel.isGenerating {
                        Text(FlashcardCopy.preparing)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                        SummarySkeletonCard()
                    } else if viewModel.cards.indices.contains(done - 1) {
                        previewCard(viewModel.cards[done - 1])
                    }
                }
                .padding(.horizontal, margin)
            }
            .scrollDisabled(true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(FlashcardCopy.generatingAccessibility(viewModel.engine.badgeTitle))
            .accessibilityValue(FlashcardCopy.generatedProgress(done, total))
            .accessibilityAddTraits(.updatesFrequently)

            Button(L10n.commonCancel.string) {
                cancelGeneration()
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    private func previewCard(_ card: Flashcard) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(FlashcardCopy.question(card.front))
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(3)
            Text(FlashcardCopy.answer(card.back))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(3)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .summaryGlass(cornerRadius: 14, strong: true)
        .id(card.id)
        .transition(.opacity)
    }

    private var review: some View {
        let duplicates = viewModel.duplicateIDs

        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    topBar
                    titleBlock(FlashcardCopy.reviewHeading, subtitle: FlashcardCopy.reviewHint)

                    if !duplicates.isEmpty {
                        duplicateBanner(count: duplicates.count)
                    }

                    LazyVStack(spacing: Spacing.s2) {
                        ForEach(viewModel.cards) { card in
                            draftRow(card, isDuplicate: duplicates.contains(card.id))
                        }
                    }

                    Button {
                        editorTarget = .create
                    } label: {
                        Label(FlashcardCopy.addCard, systemImage: "plus")
                    }
                    .buttonStyle(SummarySecondaryButtonStyle())

                    destination

                    errorBanner
                }
                .padding(.horizontal, margin)
                .padding(.bottom, Spacing.s4)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: Spacing.s2) {
                SFPrimaryButton(
                    title: viewModel.saveTitle,
                    isLoading: viewModel.isSaving,
                    isEnabled: !viewModel.cards.isEmpty,
                    action: { Task { await viewModel.saveDeck() } },
                    loadingTitle: viewModel.savingDeckTitle
                )
                Button(FlashcardCopy.startOver) {
                    discardIntent = .restart
                    isConfirmingDiscard = true
                }
                .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal, margin)
            .padding(.vertical, Spacing.s3)
        }
    }

    private func duplicateBanner(count: Int) -> some View {
        HStack(spacing: Spacing.s3) {
            Label(FlashcardCopy.duplicates(count), systemImage: "exclamationmark.triangle.fill")
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.warningText)
            Spacer(minLength: Spacing.s2)
            Button(FlashcardCopy.removeDuplicates) {
                withAnimation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion)) {
                    viewModel.removeDuplicates()
                }
            }
            .font(.sfFootnote.weight(.semibold))
            .tint(ColorTokens.primary)
            .frame(minHeight: Layout.minTouchTarget)
        }
        .padding(.horizontal, Spacing.s4)
        .summaryGlass(strong: true)
    }

    private func draftRow(_ card: Flashcard, isDuplicate: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.s2) {
            Button {
                editorTarget = .edit(card)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    if isDuplicate {
                        Text(FlashcardCopy.duplicateChip)
                            .font(.sfCaption.weight(.semibold))
                            .foregroundStyle(ColorTokens.warningText)
                    }
                    Text(card.front)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(card.back)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.s3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(FlashcardCopy.editCard)

            Button {
                withAnimation(Motion.respecting(Motion.standard, reduceMotion: reduceMotion)) {
                    viewModel.removeCard(id: card.id)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.error)
                    .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.cards.count <= 1)
            .opacity(viewModel.cards.count <= 1 ? 0.4 : 1)
            .accessibilityLabel(L10n.commonDelete.string)
        }
        .padding(.leading, Spacing.s4)
        .padding(.trailing, Spacing.s1)
        .summaryGlass(strong: true)
    }

    private var destination: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(FlashcardCopy.saveTo)

            Menu {
                Button(FlashcardCopy.newDeckOption) {
                    viewModel.targetDeckID = nil
                }
                ForEach(viewModel.decks) { deck in
                    Button(deck.title) {
                        viewModel.targetDeckID = deck.id
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.targetDeck?.title ?? FlashcardCopy.newDeckOption)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.sfFootnote)
                        .accessibilityHidden(true)
                }
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.s4)
                .frame(maxWidth: .infinity, minHeight: 52)
                .summaryGlass()
            }

            if viewModel.targetDeckID == nil {
                TextField(
                    "",
                    text: $viewModel.deckTitle,
                    prompt: Text(viewModel.deckNamePlaceholder).foregroundStyle(ColorTokens.textTertiary)
                )
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .submitLabel(.done)
                .onChange(of: viewModel.deckTitle) {
                    viewModel.limitDeckTitle()
                }
                .padding(.horizontal, Spacing.s4)
                .frame(minHeight: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(ColorTokens.outline, lineWidth: 1)
                )
                .accessibilityLabel(FlashcardCopy.deckName)

                HStack {
                    Text(FlashcardCopy.deckName)
                    Spacer()
                    Text(FlashcardCopy.characters(viewModel.deckTitle.count, FlashcardLimits.deckTitleMaxCharacters))
                        .monospacedDigit()
                }
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }

    private var saved: some View {
        VStack(spacing: Spacing.s4) {
            Spacer(minLength: 0)

            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(ColorTokens.onAccent)
                .frame(width: 64, height: 64)
                .background(ColorTokens.success, in: .circle)
                .accessibilityHidden(true)

            Text(viewModel.savedTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(FlashcardCopy.savedBody(viewModel.cards.count, viewModel.savedDeck?.title ?? ""))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Spacing.s3) {
                SFPrimaryButton(title: FlashcardCopy.studyNow) {
                    studyDeck = viewModel.savedDeck
                }
                Button(FlashcardCopy.done) {
                    dismiss()
                }
                .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            }
            .padding(.top, Spacing.s6)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, margin)
        .sensoryFeedback(.success, trigger: viewModel.savedDeck != nil) { _, isSaved in isSaved }
    }

    @ViewBuilder
    private func editor(for target: FlashcardEditorTarget) -> some View {
        switch target {
        case .edit(let card):
            FlashcardEditorSheet(
                title: FlashcardCopy.editCard,
                front: card.front,
                back: card.back,
                onSave: { front, back in
                    viewModel.updateCard(id: card.id, front: front, back: back)
                },
                onDelete: viewModel.cards.count > 1 ? { viewModel.removeCard(id: card.id) } : nil
            )
        case .create:
            FlashcardEditorSheet(
                title: FlashcardCopy.newCard,
                front: "",
                back: "",
                onSave: { front, back in
                    viewModel.addCard(front: front, back: back)
                }
            )
        }
    }

    private func startGeneration() {
        guard viewModel.canGenerate else { return }
        revealedCount = 0
        isRevealPending = true
        generationTask?.cancel()
        generationTask = Task {
            await viewModel.generate()
            guard !Task.isCancelled, !viewModel.cards.isEmpty else {
                isRevealPending = false
                return
            }
            await revealCards()
        }
    }

    private func revealCards() async {
        let total = viewModel.cards.count
        guard !reduceMotion, total > 1 else {
            revealedCount = total
            isRevealPending = false
            return
        }
        let step = Duration.milliseconds(max(FlashcardLimits.revealMilliseconds / total, 25))
        for index in 1...total {
            withAnimation(.easeOut(duration: 0.15)) {
                revealedCount = index
            }
            do {
                try await Task.sleep(for: step)
            } catch {
                break
            }
        }
        isRevealPending = false
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isRevealPending = false
        viewModel.discardCards()
    }
}

#Preview("E02 Generate from material") {
    FlashcardGenerateScreen(
        initialMaterial: Material.samples[0],
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        deckStore: InMemoryDeckStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}

#Preview("E02 Choose a material") {
    FlashcardGenerateScreen(
        initialMaterial: nil,
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        deckStore: InMemoryDeckStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}
