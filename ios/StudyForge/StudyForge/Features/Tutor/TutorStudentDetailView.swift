import SwiftUI

struct TutorStudentDetailView: View {

    let container: AppContainer

    @State private var viewModel: TutorStudentDetailViewModel
    @State private var isComposing = false
    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, enrollment: Enrollment, course: Course) {
        self.container = container
        let uid = container.session?.id ?? ""
        _viewModel = State(initialValue: TutorStudentDetailViewModel(
            enrollment: enrollment,
            course: course,
            uid: uid,
            store: container.courses,
            log: FileTutorEncouragementLog.shared,
            progressSource: LocalStudentProgressSource(
                ownerUid: uid,
                quizzes: container.quizzes,
                quizLog: FileQuizAttemptLog.shared,
                reviewLog: FileFlashcardReviewLog.shared
            )
        ))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    header
                    if !viewModel.flags.isEmpty {
                        SFChipFlow(spacing: Spacing.s2) {
                            ForEach(viewModel.flags) { flag in
                                TutorRiskBadge(flag: flag)
                            }
                        }
                    }
                    radar
                    topics
                    activity
                    encouragementHistory
                    privacyNote
                    actions
                }
                .padding(.horizontal, TutorStudioLayout.margin)
                .padding(.vertical, Spacing.s4)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isComposing) {
            composer
        }
        .sensoryFeedback(.success, trigger: viewModel.didSend) { _, sent in sent }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                Text(viewModel.enrollment.studentName)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if viewModel.isAtRisk {
                    Text(TutorStudioCopy.atRisk)
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(ColorTokens.onError)
                        .padding(.horizontal, Spacing.s2)
                        .frame(minHeight: 22)
                        .background(ColorTokens.error, in: .capsule)
                }
            }
            Text(viewModel.summaryLine)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(TutorStudioCopy.cohortComparison(viewModel.enrollment.masteryPercent, viewModel.cohortAverage))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }

    private var radar: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            TutorSectionHeader(title: viewModel.topics.count >= TutorStudentDetailViewModel.minimumRadarAxes ? TutorStudioCopy.topicMastery : TutorStudioCopy.progressProfile)
            SFRadarChart(axes: viewModel.radarAxes)
                .frame(height: 220)
                .padding(Spacing.s3)
                .summaryGlass(strong: true)
        }
    }

    @ViewBuilder
    private var topics: some View {
        if !viewModel.topics.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(viewModel.topics) { topic in
                    HStack(spacing: Spacing.s3) {
                        Text(topic.topic)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProgressView(value: topic.fraction)
                            .tint(topic.fraction < 0.6 ? ColorTokens.error : ColorTokens.success)
                            .frame(width: 110)
                        Text(TutorStudioCopy.percent(topic.percent))
                            .font(.sfFootnote.weight(.semibold))
                            .foregroundStyle(ColorTokens.textPrimary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } else if viewModel.hasLoaded {
            Text(TutorStudioCopy.noSharedProgress)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass()
        }
    }

    @ViewBuilder
    private var activity: some View {
        if !viewModel.activity.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.recentActivity)
                ForEach(viewModel.activity) { item in
                    HStack(spacing: Spacing.s3) {
                        Image(systemName: item.kind.symbolName)
                            .foregroundStyle(ColorTokens.primary)
                            .frame(width: Spacing.s6)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.sfCallout)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text(activityDetail(item))
                                .font(.sfCaption)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        Spacer(minLength: 0)
                        TutorMasteryPill(percent: item.percent)
                    }
                    .padding(Spacing.s3)
                    .summaryGlass(strong: true)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func activityDetail(_ item: TutorActivity) -> String {
        let date = item.date.formatted(.relative(presentation: .named))
        guard let seconds = item.durationSeconds else { return date }
        return TutorStudioCopy.activityDetail(date, QuizInsights.durationText(seconds))
    }

    @ViewBuilder
    private var encouragementHistory: some View {
        if !viewModel.encouragements.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.encouragementsSent)
                ForEach(viewModel.encouragements) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(3)
                        Text(entry.sentAt.formatted(.relative(presentation: .named)))
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .padding(Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .summaryGlass()
                }
            }
        }
    }

    private var privacyNote: some View {
        Label(TutorStudioCopy.privacyNote, systemImage: "lock.shield")
            .font(.sfCaption)
            .foregroundStyle(ColorTokens.textSecondary)
    }

    private var actions: some View {
        VStack(spacing: Spacing.s2) {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: nil)
            }
            SFPrimaryButton(
                title: viewModel.didSend ? TutorStudioCopy.encouragementSent : TutorStudioCopy.sendEncouragement,
                isEnabled: viewModel.enrollment.status == .active
            ) {
                isComposing = true
            }
            Button(TutorStudioCopy.backToRoster) { dismiss() }
                .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
        }
    }

    private var composer: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(TutorStudioCopy.messagePlaceholder, text: $viewModel.message, axis: .vertical)
                        .lineLimit(4...8)
                        .onChange(of: viewModel.message) { viewModel.limitMessage() }
                } footer: {
                    Text(TutorStudioCopy.encouragementFooter(viewModel.firstName))
                }
            }
            .navigationTitle(TutorStudioCopy.sendEncouragement)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isComposing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(TutorStudioCopy.send) {
                        Task {
                            if await viewModel.sendEncouragement() { isComposing = false }
                        }
                    }
                    .disabled(!viewModel.canSend)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("106 Student progress") {
    NavigationStack {
        TutorStudentDetailView(
            container: .previewing(),
            enrollment: Enrollment(
                courseId: Course.sample.id,
                uid: "uid_b",
                studentName: "Mohammed A.",
                studentNumber: "202401702",
                masteryPercent: 54,
                lastActiveAt: .now.addingTimeInterval(-86_400)
            ),
            course: Course.sample
        )
    }
}
