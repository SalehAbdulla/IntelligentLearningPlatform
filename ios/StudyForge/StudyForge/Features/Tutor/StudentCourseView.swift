import SwiftUI

struct StudentReading: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

struct StudentCourseView: View {

    let container: AppContainer

    @State private var viewModel: StudentCourseViewModel
    @State private var reading: StudentReading?
    @State private var playingQuiz: Quiz?

    init(container: AppContainer, joined: JoinedCourse) {
        self.container = container
        _viewModel = State(initialValue: StudentCourseViewModel(
            joined: joined,
            store: container.courses,
            materials: container.materials,
            decks: container.decks,
            quizzes: container.quizzes,
            log: FileTutorEncouragementLog.shared
        ))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    header
                    if viewModel.isPending {
                        pendingState
                    } else {
                        if let notice = viewModel.notice {
                            Label(notice, systemImage: "checkmark.circle.fill")
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.successText)
                        }
                        if let error = viewModel.error {
                            SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                        }
                        messages
                        announcements
                        materials
                        studyContent
                        if viewModel.hasLoaded && !viewModel.hasContent {
                            Text(TutorStudioCopy.courseNothingYet)
                                .font(.sfCallout)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .padding(Spacing.s4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .summaryGlass()
                        }
                    }
                }
                .padding(.horizontal, TutorStudioLayout.margin)
                .padding(.vertical, Spacing.s4)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle(viewModel.course.code)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(item: $reading) { reading in
            readerSheet(reading)
        }
        .fullScreenCover(item: $playingQuiz) { quiz in
            QuizPlayerView(quiz: quiz, store: container.quizzes, plans: container.studyPlans)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(viewModel.course.name)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if viewModel.upcomingCount > 0 {
                Text(TutorStudioCopy.upcomingMaterials(viewModel.upcomingCount))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }

    private var pendingState: some View {
        Label(TutorStudioCopy.pendingBody, systemImage: "hourglass")
            .font(.sfCallout)
            .foregroundStyle(ColorTokens.textSecondary)
            .padding(Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .summaryGlass(strong: true)
    }

    @ViewBuilder
    private var messages: some View {
        if !viewModel.messages.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.fromYourTutor)
                ForEach(viewModel.messages) { message in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(message.message)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(message.sentAt.formatted(.relative(presentation: .named)))
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.primary.opacity(0.12), in: .rect(cornerRadius: Radius.m))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var announcements: some View {
        if !viewModel.announcements.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.announcementsTitle)
                ForEach(viewModel.announcements) { announcement in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(announcement.title)
                            .font(.sfSubhead)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(announcement.body)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                        Text((announcement.sentAt ?? announcement.scheduledFor ?? announcement.createdAt).formatted(.relative(presentation: .named)))
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .summaryGlass(strong: true)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var materials: some View {
        if !viewModel.liveMaterials.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.materialsTitle)
                ForEach(viewModel.liveMaterials) { published in
                    Button {
                        Task {
                            if let material = await viewModel.material(for: published) {
                                reading = StudentReading(title: material.title, body: material.text)
                            } else {
                                reading = StudentReading(title: published.title, body: TutorStudioCopy.materialUnavailable)
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.s3) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(ColorTokens.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(published.title)
                                    .font(.sfSubhead)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Text(published.publishedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.sfCaption)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward")
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .accessibilityHidden(true)
                        }
                        .padding(Spacing.s4)
                        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget + Spacing.s2, alignment: .leading)
                        .summaryGlass(strong: true)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var studyContent: some View {
        if !viewModel.approvedItems.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TutorSectionHeader(title: TutorStudioCopy.studyContentTitle, trailing: TutorStudioCopy.approvedByTutor)
                ForEach(viewModel.approvedItems) { item in
                    contentCard(item)
                }
            }
        }
    }

    private func contentCard(_ item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Label(TutorStudioCopy.reviewItemTitle(TutorStudioCopy.kindTitle(item.kind), item.materialTitle), systemImage: item.kind.symbolName)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.text(for: item))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(3)
            HStack {
                Spacer()
                action(for: item)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(cornerRadius: 14, strong: true)
    }

    @ViewBuilder
    private func action(for item: ReviewItem) -> some View {
        let isBusy = viewModel.busyItemId == item.id
        switch item.kind {
        case .summary:
            Button(TutorStudioCopy.read) {
                reading = StudentReading(title: item.materialTitle, body: viewModel.text(for: item))
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .fixedSize()
        case .flashcards:
            let added = viewModel.addedDeckItemIds.contains(item.id)
            Button {
                Task { await viewModel.addToDecks(item) }
            } label: {
                Label(
                    added ? TutorStudioCopy.addedDeck : TutorStudioCopy.addDeck(viewModel.cardCount(for: item)),
                    systemImage: added ? "checkmark" : "plus"
                )
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .fixedSize()
            .disabled(added || isBusy)
        case .quiz:
            Button {
                Task {
                    if let quiz = await viewModel.quiz(for: item) {
                        playingQuiz = quiz
                    }
                }
            } label: {
                Label(TutorStudioCopy.takeQuiz(viewModel.questionCount(for: item)), systemImage: "checklist")
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .fixedSize()
            .disabled(isBusy)
        }
    }

    private func readerSheet(_ reading: StudentReading) -> some View {
        NavigationStack {
            ScrollView {
                Text(reading.body)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .textSelection(.enabled)
                    .padding(TutorStudioLayout.margin)
                    .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle(reading.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) { self.reading = nil }
                }
            }
        }
    }
}
