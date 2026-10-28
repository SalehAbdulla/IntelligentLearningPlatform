import SwiftUI

struct SummaryResultView: View {

    let viewModel: SummaryScreensViewModel
    let summary: GeneratedSummary
    let router: AIRouter
    let learningStyle: LearningStyle

    @Environment(AppContainer.self) private var container: AppContainer?

    @State private var isShowingSource = false
    @State private var opensViewerAfterSource = false
    @State private var isShowingViewer = false
    @State private var isEditing = false
    @State private var isConfirmingDiscard = false
    @State private var isMakingCards = false
    @State private var isShowingCardsUnavailable = false
    @State private var isPickingFolder = false
    @State private var isShowingFolderUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                Button {
                    if viewModel.isSaved {
                        viewModel.backToConfigure()
                    } else {
                        isConfirmingDiscard = true
                    }
                } label: {
                    Label(L10n.commonBack.string, systemImage: "chevron.backward")
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget)
                }

                HStack(alignment: .top, spacing: Spacing.s3) {
                    Text(summary.title)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                    Button {
                        isShowingSource = true
                    } label: {
                        Text(summary.source.chipTitle)
                            .font(.sfCaption.weight(.semibold))
                            .foregroundStyle(ColorTokens.onError)
                            .padding(.horizontal, Spacing.s3)
                            .frame(minWidth: 100, minHeight: 26)
                            .background(ColorTokens.success, in: .capsule)
                            .frame(minHeight: Layout.minTouchTarget, alignment: .top)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SummaryCopy.sourceAccessibility(label: L10n.summarySource.string, page: summary.source.pageLabel))
                }

                if summary.showsAIDraftLabel {
                    Label(SummaryCopy.aiDrafted, systemImage: "sparkles")
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                tldrCard

                sectionTitle(L10n.summaryKeyPointsHeading.string)
                keyPoints

                if !summary.glossary.isEmpty {
                    sectionTitle(L10n.summaryGlossaryHeading.string)
                    ForEach(summary.glossary) { item in
                        glossaryCard(item)
                    }
                }

                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.save() } })
                }

                actions
                    .padding(.top, Spacing.s2)

                if viewModel.isSaved {
                    HStack(spacing: Spacing.s3) {
                        Label(L10n.summarySavedTitle.string, systemImage: "checkmark.circle.fill")
                            .font(.sfFootnote.weight(.semibold))
                            .foregroundStyle(ColorTokens.successText)
                        Spacer(minLength: 0)
                        Button {
                            if container != nil {
                                isPickingFolder = true
                            } else {
                                isShowingFolderUnavailable = true
                            }
                        } label: {
                            Label(SummaryCopy.addToFolder, systemImage: "folder.badge.plus")
                                .font(.sfFootnote.weight(.semibold))
                                .foregroundStyle(ColorTokens.primary)
                                .frame(minHeight: Layout.minTouchTarget)
                        }
                    }
                    .transition(.opacity)
                } else if viewModel.hasUnsavedChanges {
                    Label(SummaryCopy.edited, systemImage: "pencil.circle.fill")
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.warningText)
                }
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .sensoryFeedback(.success, trigger: viewModel.isSaved) { _, saved in saved }
        .sheet(isPresented: $isShowingSource, onDismiss: {
            if opensViewerAfterSource {
                opensViewerAfterSource = false
                isShowingViewer = true
            }
        }) {
            SummarySourceSheet(source: summary.source) {
                opensViewerAfterSource = true
                isShowingSource = false
            }
        }
        .sheet(isPresented: $isShowingViewer) {
            SummaryMaterialViewer(material: viewModel.material, source: summary.source)
        }
        .sheet(isPresented: $isEditing) {
            SummaryEditSheet(viewModel: viewModel, summary: summary)
        }
        .sheet(isPresented: $isMakingCards) {
            if let container {
                FlashcardGenerateView(
                    initialMaterial: viewModel.material,
                    materialStore: container.materials,
                    deckStore: container.decks,
                    router: router,
                    learningStyle: learningStyle
                )
            }
        }
        .sheet(isPresented: $isPickingFolder) {
            if let container, let id = viewModel.savedSummaryID {
                SummaryFolderSheet(
                    summaryID: id,
                    summaryTitle: summary.title,
                    store: container.folders,
                    userName: container.session?.displayName ?? ""
                )
            }
        }
        .confirmationDialog(SummaryCopy.discardTitle, isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button(SummaryCopy.discardConfirm, role: .destructive) {
                viewModel.backToConfigure()
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: {
            Text(SummaryCopy.discardMessage)
        }
        .alert(SummaryCopy.folderTitle, isPresented: $isShowingFolderUnavailable) {
            Button(L10n.commonDone.string, role: .cancel) {}
        } message: {
            Text(SummaryCopy.folderUnavailable)
        }
        .alert(SummaryCopy.cardsTitle, isPresented: $isShowingCardsUnavailable) {
            Button(L10n.commonDone.string, role: .cancel) {}
        } message: {
            Text(SummaryCopy.cardsUnavailable)
        }
    }

    private var tldrCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(SummaryCopy.tldr)
                .font(.sfFootnote.weight(.semibold))
            Text(summary.tldr)
                .font(.sfCallout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(ColorTokens.onPrimaryContainer)
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var keyPoints: some View {
        switch summary.style {
        case .bullets:
            VStack(spacing: Spacing.s2) {
                ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
                        Circle()
                            .fill(ColorTokens.primary)
                            .frame(width: 7, height: 7)
                            .accessibilityHidden(true)
                        Text(point)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s2)
                    .frame(minHeight: 36)
                    .summaryGlass(cornerRadius: 10)
                }
            }
        case .narrative:
            Text(summary.keyPoints.map { $0.hasSuffix(".") ? $0 : $0 + "." }.joined(separator: " "))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass(strong: true)
        case .cornell:
            VStack(spacing: 0) {
                ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: Spacing.s3) {
                        Text(verbatim: "Q\(index + 1)")
                            .font(.sfFootnote.weight(.semibold))
                            .foregroundStyle(ColorTokens.primary)
                            .frame(width: Spacing.s8, alignment: .leading)
                        Text(point)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.s3)
                    if index < summary.keyPoints.count - 1 {
                        Divider()
                    }
                }
            }
            .summaryGlass(strong: true)
        }
    }

    private func glossaryCard(_ item: SummaryGlossaryItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(item.term)
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textPrimary)
            Text(item.definition)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.confidenceLabel)
                .font(.sfCaption)
                .foregroundStyle(item.isHighConfidence ? ColorTokens.successText : ColorTokens.warningText)
                .padding(.top, Spacing.s1)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(strong: true)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        HStack(spacing: Spacing.s2) {
            Button(SummaryCopy.edit) { isEditing = true }
                .buttonStyle(SummaryActionButtonStyle())
                .disabled(viewModel.isSaving)

            Button {
                Task { await viewModel.save() }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(ColorTokens.primary)
                } else {
                    Text(viewModel.isSaved ? SummaryCopy.saved : SummaryCopy.save)
                }
            }
            .buttonStyle(SummaryActionButtonStyle())
            .disabled(viewModel.isSaved || viewModel.isSaving)
            .accessibilityLabel(viewModel.isSaving ? L10n.summarySaving.string : (viewModel.isSaved ? SummaryCopy.saved : SummaryCopy.save))

            ShareLink(item: summary.shareText, subject: Text(summary.title)) {
                Text(SummaryCopy.share)
            }
            .buttonStyle(SummaryActionButtonStyle())

            Button(SummaryCopy.cards) {
                if container != nil {
                    isMakingCards = true
                } else {
                    isShowingCardsUnavailable = true
                }
            }
            .buttonStyle(SummaryActionButtonStyle(isPrimary: true))
            .accessibilityLabel(L10n.libraryMakeCards.string)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.sfSubhead)
            .foregroundStyle(ColorTokens.textPrimary)
            .padding(.top, Spacing.s1)
            .accessibilityAddTraits(.isHeader)
    }
}

struct SummaryActionButtonStyle: ButtonStyle {
    var isPrimary = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfFootnote.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isPrimary ? ColorTokens.onError : ColorTokens.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
            .background {
                if isPrimary {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ColorTokens.primary)
                } else {
                    Color.clear.summaryGlass(cornerRadius: 10)
                }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : (isEnabled ? 1 : 0.5))
    }
}
