//
//  LiveQuizView.swift
//  StudyForge
//
//  I12 + I13 + I14 — `92_GroupSpace_SharedQuiz_Lobby`, `93_..._Live` and `94_..._Results_Leaderboard`
//  (docs/03 §I, P1). Three states of one sheet: the lobby, the live question and the leaderboard.
//
//  WHY ONE SHEET AND NOT THREE SCREENS
//  -----------------------------------
//  The design splits them so each can carry its own chrome; a quiz runs lobby → question → result
//  without pause, and three screens would be three dismissals for one activity. This is the same
//  decision the summary flow (D01/D02/D03/D07) and the flashcard generator (E02/E03/review) already
//  made, so it is the house pattern rather than an exception.
//

import SwiftUI

struct LiveQuizView: View {

    @State private var viewModel: LiveQuizViewModel
    @Environment(\.dismiss) private var dismiss

    /// Drives both clocks: the lobby filling in, and the per-question countdown.
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(group: StudyGroup?, me: String, quizStore: any QuizStore) {
        _viewModel = State(initialValue: LiveQuizViewModel(group: group, me: me, quizStore: quizStore))
    }

    private var title: String {
        viewModel.phase == .results ? viewModel.resultsTitle : viewModel.lobbyTitle
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    switch viewModel.phase {
                    case .lobby: lobby
                    case .question: question
                    case .revealed: revealed
                    case .results: results
                    }

                    if let error = viewModel.error {
                        SFErrorBanner(error: error, onRecover: nil)
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { dismiss() }
                }
            }
            .task {
                await viewModel.load()
                viewModel.readyUp()
            }
            .onReceive(clock) { _ in
                Task { await viewModel.tick() }
            }
        }
    }

    // MARK: I12 — Lobby

    private var lobby: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.groupName)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(viewModel.players) { player in
                    HStack(spacing: Spacing.s3) {
                        Image(systemName: "person.circle.fill")
                            .font(.sfTitleM)
                            .foregroundStyle(ColorTokens.primary)
                            .accessibilityHidden(true)
                        Text(player.name)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Spacer(minLength: Spacing.s2)
                        if player.isReady {
                            Label(viewModel.readyTitle, systemImage: "checkmark.circle.fill")
                                .font(.sfCaption)
                                .foregroundStyle(ColorTokens.successText)
                        } else {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .padding(Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                }
            }

            if viewModel.isHost {
                hostSettings
            } else {
                HStack(spacing: Spacing.s3) {
                    ProgressView().controlSize(.small)
                    Text(viewModel.waitingTitle)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var hostSettings: some View {
        if viewModel.hasQuizzes {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(viewModel.quizzes) { quiz in
                    Button { viewModel.selectedQuizId = quiz.id } label: {
                        HStack(spacing: Spacing.s3) {
                            Image(systemName: viewModel.selectedQuizId == quiz.id
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.sfTitleM)
                                .foregroundStyle(ColorTokens.primary)
                                .accessibilityHidden(true)
                            Text(quiz.title)
                                .font(.sfBodyEmph)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                        }
                        .padding(Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                    }
                    .buttonStyle(.plain)
                }

                SFSegmentedField(
                    label: viewModel.startTitle,
                    selection: .init(
                        get: { viewModel.questionLimit },
                        set: { viewModel.questionLimit = $0 ?? viewModel.questionLimit }
                    ),
                    options: [3, 5, 10],
                    title: { "\($0)" }
                )

                SFPrimaryButton(title: viewModel.startTitle) { viewModel.start() }
            }
        } else {
            Text(viewModel.noQuizzesTitle)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: I13 — Live question

    private var question: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            HStack(spacing: Spacing.s4) {
                timerRing
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(viewModel.questionProgressTitle(
                        (viewModel.session?.currentIndex ?? 0) + 1,
                        of: viewModel.questions.count
                    ))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)

                    Text(viewModel.progressStripTitle(
                        viewModel.session?.answeredCount ?? 0,
                        of: viewModel.players.count
                    ))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                }
                Spacer(minLength: 0)
            }

            if let current = viewModel.currentQuestion {
                Text(current.stem)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: Spacing.s2) {
                    ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                        Button { viewModel.answer(index) } label: {
                            optionRow(option, isCorrect: nil, isMine: false)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.session?.iHaveAnswered ?? false)
                    }
                }
            }

            leaderboardRail
        }
    }

    private var timerRing: some View {
        let total = Double(LiveQuizSession.questionSeconds)
        let fraction = max(0, min(1, Double(viewModel.secondsRemaining) / total))
        return ZStack {
            Circle()
                .stroke(ColorTokens.outline, lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    viewModel.isTimeCritical ? ColorTokens.error : ColorTokens.primary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(viewModel.secondsRemaining)")
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
        }
        .frame(width: Spacing.s10, height: Spacing.s10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.timeLeftTitle(viewModel.secondsRemaining))
    }

    private var leaderboardRail: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.leaderboardTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
            ForEach(viewModel.leaderboard) { player in
                HStack(spacing: Spacing.s3) {
                    Text(player.name)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.s2)
                    Text(viewModel.scoreTitle(player.score))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    // MARK: I13 — Revealed

    private var revealed: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            if let current = viewModel.currentQuestion {
                banner(viewModel.selectedOption == current.correctOptionIndex)

                Text(current.explanation)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s4)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))

                VStack(spacing: Spacing.s2) {
                    ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                        optionRow(
                            option,
                            isCorrect: index == current.correctOptionIndex,
                            isMine: index == viewModel.selectedOption
                        )
                    }
                }

                SFPrimaryButton(title: L10n.commonNext.string) { viewModel.advance() }
            }
        }
    }

    private func banner(_ correct: Bool) -> some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(correct ? L10n.quizCorrect.string : L10n.quizIncorrect.string)
                .font(.sfBodyEmph)
        }
        .foregroundStyle(correct ? ColorTokens.successText : ColorTokens.error)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: I14 — Results

    private var results: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.leaderboardTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { rank, player in
                    leaderboardRow(rank: rank + 1, player: player)
                }
            }

            if !viewModel.topicScores.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(L10n.quizTopicHeading.string)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)
                    ForEach(viewModel.topicScores, id: \.topic) { score in
                        topicBar(score)
                    }
                }
            }

            if viewModel.isReviewing {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    ForEach(viewModel.questions) { question in
                        reviewRow(question)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.s3) {
                SFPrimaryButton(title: viewModel.rematchTitle) { viewModel.rematch() }
                Button(viewModel.reviewTitle) { viewModel.toggleReview() }
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
            }
        }
    }

    private func leaderboardRow(rank: Int, player: LiveQuizPlayer) -> some View {
        HStack(spacing: Spacing.s3) {
            Text(medal(for: rank))
                .font(.sfTitleS)
                .frame(minWidth: Spacing.s6)
            Text(player.name)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Spacing.s2)
            Text(viewModel.scoreTitle(player.score))
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .monospacedDigit()
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            player.id == viewModel.session?.myPlayerId
                ? ColorTokens.primaryContainer
                : ColorTokens.surfaceVariant,
            in: .rect(cornerRadius: Radius.m)
        )
        .accessibilityElement(children: .combine)
    }

    /// Rank medals for the top three, the number after that.
    private func medal(for rank: Int) -> String {
        switch rank {
        case 1: "🥇"
        case 2: "🥈"
        case 3: "🥉"
        default: "\(rank)"
        }
    }

    private func topicBar(_ score: QuizTopicScore) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack {
                Text(score.topic)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                Spacer(minLength: Spacing.s2)
                Text("\(score.percent)%")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorTokens.outline)
                    Capsule()
                        .fill(ColorTokens.primary)
                        .frame(width: geo.size.width * score.fraction)
                }
            }
            .frame(height: Spacing.s2)
        }
        .accessibilityElement(children: .combine)
    }

    private func reviewRow(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(question.stem)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(question.options[question.correctOptionIndex])
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.successText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s3)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    // MARK: Option row

    private func optionRow(_ text: String, isCorrect: Bool?, isMine: Bool) -> some View {
        HStack(spacing: Spacing.s3) {
            Text(text)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: Spacing.s2)
            if let isCorrect {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(isCorrect ? ColorTokens.successText : ColorTokens.error)
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(optionBackground(isCorrect: isCorrect, isMine: isMine), in: .rect(cornerRadius: Radius.m))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.m)
                .stroke(isMine ? ColorTokens.primary : .clear, lineWidth: 2)
        )
        .contentShape(.rect)
    }

    private func optionBackground(isCorrect: Bool?, isMine: Bool) -> Color {
        if isCorrect == true { return ColorTokens.success.opacity(0.15) }
        if isMine && isCorrect == false { return ColorTokens.error.opacity(0.15) }
        return ColorTokens.surfaceVariant
    }
}

// MARK: - Previews

#Preview("I12 Live quiz lobby") {
    LiveQuizView(
        group: StudyGroup(
            name: "Database revision",
            members: [
                GroupMember(name: "Sara Ali", isOwner: true, isOnline: true),
                GroupMember(name: "Omar", isOnline: true),
            ]
        ),
        me: "Sara Ali",
        quizStore: InMemoryQuizStore()
    )
}