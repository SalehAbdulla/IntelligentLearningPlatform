//
//  CoachChatView.swift
//  StudyForge
//
//  H02 + H03 + H07 + H08 — `74_Coach_Chat_Conversation`, `75_Coach_ExplainLevel_Toggle`,
//  `79_Coach_RateResponse` and `80_Coach_OnDeviceUnavailable_Fallback` (docs/03 §H).
//
//  WHY H08 IS RENDERED IN PLACE
//  ----------------------------
//  Frame 80 is a screen, but it is reached by a failure INSIDE this conversation, not by
//  navigation. Pushing a new screen would lose the question the student just typed; rendering the
//  fallback where the answer would have appeared keeps the composer on screen so they can carry on
//  offline or upgrade the engine without retyping.
//

import SwiftUI

struct CoachChatView: View {

    let container: AppContainer

    @State private var viewModel: CoachChatViewModel
    @State private var initialQuestion: String?
    @State private var selectedCitation: Citation?
    @State private var isRating = false

    init(container: AppContainer, thread: CoachThread?, initialQuestion: String?) {
        self.container = container
        self.initialQuestion = initialQuestion
        _viewModel = State(initialValue: CoachChatViewModel(
            uid: container.session?.id ?? "",
            thread: thread ?? CoachThread(),
            service: container.coachService,
            store: container.coach
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error)
                }

                if viewModel.isUnavailable {
                    CoachUnavailableView(container: container)
                }

                ForEach(viewModel.messages) { message in
                    bubble(message)
                }

                if viewModel.isThinking {
                    HStack(spacing: Spacing.s2) {
                        ProgressView()
                        Text(viewModel.thinkingTitle)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { composer }
        .task { await viewModel.startIfNeeded(question: initialQuestion) }
        .sheet(item: $selectedCitation) { citation in
            CitationSheetView(citation: citation)
        }
        .sheet(isPresented: $isRating) {
            FeedbackSheetView { stars, reasons, comment in
                Task { await viewModel.rate(stars: stars, reasons: reasons, comment: comment) }
            }
        }
        .onChange(of: viewModel.level) { _, _ in
            Task { await viewModel.reask() }
        }
    }

    // MARK: Message bubble (H02)

    @ViewBuilder
    private func bubble(_ message: CoachMessage) -> some View {
        VStack(alignment: message.role == .student ? .trailing : .leading, spacing: Spacing.s2) {
            Text(message.text)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: message.role == .student ? .trailing : .leading)
                .padding(Spacing.s4)
                .background(
                    message.role == .student ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                    in: .rect(cornerRadius: Radius.l)
                )

            if message.role == .coach {
                coachFooter(message)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .student ? .trailing : .leading)
    }

    @ViewBuilder
    private func coachFooter(_ message: CoachMessage) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if !message.isGrounded {
                Text(viewModel.ungroundedBadge)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.warning)
            }

            if !message.citations.isEmpty {
                Text(viewModel.citationsLabel)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)

                // Citation chips (H02 → H04).
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(message.citations) { citation in
                            Button {
                                selectedCitation = citation
                            } label: {
                                Text(citationLabel(citation))
                                    .font(.sfCaption)
                                    .foregroundStyle(ColorTokens.primary)
                                    .padding(.horizontal, Spacing.s3)
                                    .padding(.vertical, Spacing.s2)
                                    .background(ColorTokens.primaryContainer, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button(viewModel.helpfulTitle) {
                viewModel.ratingMessage = message
                isRating = true
            }
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.primary)
        }
    }

    private func citationLabel(_ citation: Citation) -> String {
        [citation.materialTitle, citation.pageLabel].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Composer (H03)

    private var composer: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            // The depth control re-asks the last question at a new level (H03). The question is
            // unchanged; only the depth of the answer is.
            Picker(viewModel.levelLabel, selection: $viewModel.level) {
                ForEach(viewModel.levels, id: \.self) { level in
                    Text(viewModel.levelName(level)).tag(level)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .bottom, spacing: Spacing.s3) {
                SFTextField(
                    label: viewModel.title,
                    text: $viewModel.draft,
                    placeholder: viewModel.placeholder,
                    submitLabel: .send,
                    autocorrectionDisabled: false,
                    onSubmit: { Task { await viewModel.send() } }
                )

                Button(viewModel.sendTitle) {
                    Task { await viewModel.send() }
                }
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
                .disabled(!viewModel.canSend)
            }
        }
        .padding(Layout.screenMargin)
        .background(.bar)
    }
}

// MARK: - H08 Graceful degradation

/// Frame 80 — what the student sees when no engine could answer.
struct CoachUnavailableView: View {

    let container: AppContainer

    /// H08's "continue offline": the fallback is dismissible, because a screen that cannot be
    /// closed turns a degradation into a dead end.
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Label(L10n.coachUnavailableTitle.string, systemImage: "cpu")
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.warning)

                Text(L10n.coachUnavailableBody.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.coachCloudPrivacyNote.string)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                // The admin's routing policy is the DEFAULT, applied at launch; this is the
                // student asking for the cloud for the rest of the session because the on-device
                // engine cannot run here (docs/04 §6's graceful degradation).
                SFPrimaryButton(title: L10n.coachUseCloud.string) {
                    container.ai.policy = .cloudFirst
                    dismissed = true
                }

                Button(L10n.coachContinueOffline.string) { dismissed = true }
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        }
    }
}

// MARK: - H07 Feedback sheet

/// Frame 79 — the rating sheet. Stars for the score, chips for the reason.
struct FeedbackSheetView: View {

    let onSubmit: (Int, [FeedbackReason], String?) -> Void

    @State private var stars = 5
    @State private var reasons: Set<FeedbackReason> = []
    @State private var comment = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text(L10n.coachFeedbackHelpful.string)
                            .font(.sfSubhead)
                            .foregroundStyle(ColorTokens.textSecondary)

                        HStack(spacing: Spacing.s2) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    stars = value
                                } label: {
                                    Image(systemName: value <= stars ? "star.fill" : "star")
                                        .font(.sfTitleS)
                                        .foregroundStyle(ColorTokens.accentGold)
                                        .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("\(value)"))
                                .accessibilityAddTraits(value == stars ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text(L10n.coachFeedbackReasons.string)
                            .font(.sfSubhead)
                            .foregroundStyle(ColorTokens.textSecondary)

                        ForEach(FeedbackReason.allCases) { reason in
                            Toggle(reasonName(reason), isOn: binding(for: reason))
                                .font(.sfCallout)
                                .tint(ColorTokens.primary)
                        }
                    }

                    SFTextField(
                        label: L10n.coachFeedbackCommentLabel.string,
                        text: $comment,
                        autocorrectionDisabled: false
                    )

                    SFPrimaryButton(title: L10n.coachFeedbackSubmit.string) {
                        onSubmit(stars, Array(reasons), comment.isEmpty ? nil : comment)
                        dismiss()
                    }
                }
                .padding(Layout.screenMargin)
            }
            .background(ColorTokens.surface)
            .navigationTitle(L10n.coachFeedbackTitle.string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func binding(for reason: FeedbackReason) -> Binding<Bool> {
        Binding(
            get: { reasons.contains(reason) },
            set: { isOn in
                if isOn { reasons.insert(reason) } else { reasons.remove(reason) }
            }
        )
    }

    private func reasonName(_ reason: FeedbackReason) -> String {
        switch reason {
        case .wrong: L10n.coachReasonWrong.string
        case .tooLong: L10n.coachReasonTooLong.string
        case .offTopic: L10n.coachReasonOffTopic.string
        case .notHelpful: L10n.coachReasonNotHelpful.string
        }
    }
}

// MARK: - Previews

#Preview("H02 Coach chat") {
    NavigationStack {
        CoachChatView(container: .previewing(), thread: nil, initialQuestion: nil)
    }
}
