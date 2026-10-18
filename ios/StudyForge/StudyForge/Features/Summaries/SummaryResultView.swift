import SwiftUI

struct SummaryResultView: View {

    let viewModel: SummaryScreensViewModel
    let summary: GeneratedSummary
    let onMakeCards: ((GeneratedSummary) -> Void)?
    let onOpenSource: ((SummarySource) -> Void)?

    @State private var isShowingSource = false
    @State private var isEditing = false
    @State private var isConfirmingDiscard = false
    @State private var isShowingCardsInfo = false

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

                    Button {
                        isShowingSource = true
                    } label: {
                        Text(summary.source.chipTitle)
                            .font(.sfCaption.weight(.semibold))
                            .foregroundStyle(ColorTokens.onAccent)
                            .padding(.horizontal, Spacing.s3)
                            .frame(minHeight: 26)
                            .background(ColorTokens.success, in: .capsule)
                            .frame(minHeight: Layout.minTouchTarget, alignment: .top)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(L10n.summarySource.string), page \(summary.source.page)")
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

                actions
                    .padding(.top, Spacing.s2)

                if viewModel.isSaved {
                    Label(L10n.summarySavedTitle.string, systemImage: "checkmark.circle.fill")
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.successText)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .sensoryFeedback(.success, trigger: viewModel.isSaved) { _, saved in saved }
        .sheet(isPresented: $isShowingSource) {
            SummarySourceSheet(source: summary.source, onOpen: onOpenSource)
        }
        .sheet(isPresented: $isEditing) {
            SummaryEditSheet(viewModel: viewModel, summary: summary)
        }
        .confirmationDialog("Discard this summary?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                viewModel.backToConfigure()
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: {
            Text("It hasn't been saved yet.")
        }
        .alert("Flashcards", isPresented: $isShowingCardsInfo) {
            Button(L10n.commonDone.string, role: .cancel) {}
        } message: {
            Text("Making cards from a summary will be available soon.")
        }
    }

    private var tldrCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("TL;DR")
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
                        Text("Q\(index + 1)")
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
            Button("Edit") { isEditing = true }
                .buttonStyle(SummaryActionButtonStyle())

            Button {
                viewModel.save()
            } label: {
                Text(viewModel.isSaved ? "Saved" : "Save")
            }
            .buttonStyle(SummaryActionButtonStyle())
            .disabled(viewModel.isSaved)

            ShareLink(item: summary.shareText) {
                Text("Share")
            }
            .buttonStyle(SummaryActionButtonStyle())

            Button("Cards") {
                if let onMakeCards {
                    onMakeCards(summary)
                } else {
                    isShowingCardsInfo = true
                }
            }
            .buttonStyle(SummaryActionButtonStyle(isPrimary: true))
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
