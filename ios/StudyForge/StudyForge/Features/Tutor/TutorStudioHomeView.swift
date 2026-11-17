import SwiftUI

struct TutorStudioHomeView: View {

    let container: AppContainer

    @State private var viewModel: TutorStudioHomeViewModel
    @State private var isCreating = false
    @State private var courseToArchive: Course?

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: TutorStudioHomeViewModel(
            uid: container.session?.id ?? "",
            store: container.courses
        ))
    }

    private var isConfirmingArchive: Binding<Bool> {
        Binding(
            get: { courseToArchive != nil },
            set: { if !$0 { courseToArchive = nil } }
        )
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    header
                    content
                }
                .padding(.horizontal, TutorStudioLayout.margin)
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
            NavigationStack {
                CourseEditorView(container: container, course: nil)
            }
        }
        .confirmationDialog(
            TutorStudioCopy.archiveTitle,
            isPresented: isConfirmingArchive,
            titleVisibility: .visible,
            presenting: courseToArchive
        ) { course in
            Button(TutorStudioCopy.archive, role: .destructive) {
                Task { await viewModel.setArchived(course, archived: true) }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: { course in
            Text(TutorStudioCopy.archiveMessage(course.name))
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    private var header: some View {
        HStack(spacing: Spacing.s3) {
            Text(TutorStudioCopy.homeTitle)
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                isCreating = true
            } label: {
                Label(TutorStudioCopy.createCourse, systemImage: "plus")
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
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s10)
        } else if let error = viewModel.error, viewModel.courses.isEmpty {
            SFErrorBanner(error: error, onRecover: reload)
        } else if viewModel.isEmpty {
            emptyState
        } else {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: reload)
            }
            kpis
            reviewBanner
            courseList
        }
    }

    private var kpis: some View {
        let cohort = viewModel.cohort
        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Spacing.s2), GridItem(.flexible(), spacing: Spacing.s2)],
            spacing: Spacing.s2
        ) {
            TutorKPITile(value: cohort.students.formatted(), label: TutorStudioCopy.kpiStudents)
            TutorKPITile(value: cohort.activeThisWeek.formatted(), label: TutorStudioCopy.kpiActive)
            TutorKPITile(value: TutorStudioCopy.percent(cohort.averageMastery), label: TutorStudioCopy.kpiMastery)
            TutorKPITile(
                value: viewModel.atRiskCount.formatted(),
                label: TutorStudioCopy.kpiAtRisk,
                tint: viewModel.atRiskCount > 0 ? ColorTokens.error : ColorTokens.textPrimary
            )
        }
    }

    @ViewBuilder
    private var reviewBanner: some View {
        if viewModel.pendingReviewCount > 0 {
            NavigationLink {
                TutorReviewQueueView(container: container, courseIds: viewModel.courseIdsForReview)
                    .onDisappear(perform: reload)
            } label: {
                HStack(spacing: Spacing.s3) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(ColorTokens.primary)
                        .accessibilityHidden(true)
                    Text(TutorStudioCopy.pendingReview(viewModel.pendingReviewCount))
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .accessibilityHidden(true)
                }
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget + Spacing.s3)
                .background(ColorTokens.primary.opacity(0.14), in: .rect(cornerRadius: Radius.m))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(ColorTokens.primary.opacity(0.5), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            TutorSectionHeader(title: TutorStudioCopy.yourCourses)

            if !viewModel.archivedCourses.isEmpty {
                SummaryOptionPicker(
                    title: TutorStudioCopy.showLabel,
                    options: [false, true],
                    selection: $viewModel.showsArchived,
                    optionTitle: { $0 ? TutorStudioCopy.archivedTab : TutorStudioCopy.activeTab }
                )
            }

            ForEach(viewModel.visibleCourses) { course in
                NavigationLink {
                    TutorCourseHubView(container: container, courseId: course.id)
                        .onDisappear(perform: reload)
                } label: {
                    TutorCourseCard(
                        course: course,
                        detail: TutorStudioCopy.courseDetail(viewModel.studentCount(for: course), course.liveMaterialCount())
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if course.isArchived {
                        Button {
                            Task { await viewModel.setArchived(course, archived: false) }
                        } label: {
                            Label(TutorStudioCopy.unarchive, systemImage: "tray.and.arrow.up")
                        }
                    } else {
                        Button(role: .destructive) {
                            courseToArchive = course
                        } label: {
                            Label(TutorStudioCopy.archive, systemImage: "archivebox")
                        }
                    }
                }
            }

            Text(TutorStudioCopy.coursesFooter)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(.top, Spacing.s2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 44))
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)
            Text(TutorStudioCopy.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(TutorStudioCopy.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            SFPrimaryButton(title: TutorStudioCopy.createCourse) {
                isCreating = true
            }
        }
        .padding(Spacing.s6)
        .frame(maxWidth: .infinity)
        .summaryGlass(cornerRadius: 14, strong: true)
        .padding(.top, Spacing.s6)
    }
}

#Preview("99 Tutor home") {
    NavigationStack {
        TutorStudioHomeView(container: .previewing())
    }
}
