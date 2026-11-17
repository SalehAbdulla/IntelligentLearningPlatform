import SwiftUI

struct TutorCourseHubView: View {

    let container: AppContainer

    @State private var viewModel: TutorCourseHubViewModel
    @State private var isInviting = false
    @State private var isPublishing = false
    @State private var studentToRemove: Enrollment?

    init(container: AppContainer, courseId: String) {
        self.container = container
        _viewModel = State(initialValue: TutorCourseHubViewModel(
            uid: container.session?.id ?? "",
            courseId: courseId,
            store: container.courses
        ))
    }

    private var isConfirmingRemove: Binding<Bool> {
        Binding(
            get: { studentToRemove != nil },
            set: { if !$0 { studentToRemove = nil } }
        )
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s4) {
                        content
                    }
                    .padding(.horizontal, TutorStudioLayout.margin)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
                .refreshable { await viewModel.load() }
                .scrollDismissesKeyboard(.interactively)

                if let course = viewModel.course {
                    footer(course)
                }
            }
        }
        .navigationTitle(viewModel.course.map { TutorStudioCopy.rosterTitle($0.code) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { await viewModel.load() }
        .sheet(isPresented: $isInviting) {
            inviteSheet
        }
        .sheet(isPresented: $isPublishing, onDismiss: reload) {
            if let course = viewModel.course {
                TutorPublishView(container: container, course: course)
            }
        }
        .confirmationDialog(
            TutorStudioCopy.removeTitle,
            isPresented: isConfirmingRemove,
            titleVisibility: .visible,
            presenting: studentToRemove
        ) { enrollment in
            Button(TutorStudioCopy.removeStudent, role: .destructive) {
                Task { await viewModel.remove(enrollment) }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: { enrollment in
            Text(TutorStudioCopy.removeMessage(enrollment.studentName))
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    isInviting = true
                } label: {
                    Label(TutorStudioCopy.inviteStudents, systemImage: "person.badge.plus")
                }
                if let course = viewModel.course {
                    NavigationLink {
                        TutorGradebookView(container: container, course: course)
                    } label: {
                        Label(TutorStudioCopy.exportGradebook, systemImage: "square.and.arrow.up")
                    }
                    NavigationLink {
                        CourseEditorView(container: container, course: course)
                            .onDisappear(perform: reload)
                    } label: {
                        Label(TutorStudioCopy.editCourse, systemImage: "pencil")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .accessibilityLabel(TutorStudioCopy.courseActions)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s10)
        } else if let error = viewModel.error, viewModel.course == nil {
            SFErrorBanner(error: error, onRecover: reload)
        } else if let course = viewModel.course {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: reload)
            }
            summary(course)
            reviewLink(course)
            rosterControls
            roster(course)
        }
    }

    private func summary(_ course: Course) -> some View {
        let cohort = viewModel.cohort
        return VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(course.name)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.s2) {
                TutorKPITile(value: cohort.students.formatted(), label: TutorStudioCopy.kpiStudents)
                TutorKPITile(value: TutorStudioCopy.percent(cohort.averageMastery), label: TutorStudioCopy.kpiMastery)
                TutorKPITile(value: viewModel.count(.atRisk).formatted(), label: TutorStudioCopy.kpiAtRisk)
            }
        }
    }

    @ViewBuilder
    private func reviewLink(_ course: Course) -> some View {
        NavigationLink {
            TutorReviewQueueView(container: container, courseIds: [course.id])
                .onDisappear(perform: reload)
        } label: {
            HStack {
                Label(TutorStudioCopy.reviewQueueTitle, systemImage: "sparkles")
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                if viewModel.pendingReviewCount > 0 {
                    Text(viewModel.pendingReviewCount.formatted())
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.onError)
                        .padding(.horizontal, Spacing.s2)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(ColorTokens.primary, in: .capsule)
                }
                Image(systemName: "chevron.forward")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.s4)
            .frame(minHeight: Layout.minTouchTarget + Spacing.s2)
            .summaryGlass(strong: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rosterControls: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)
                TextField(TutorStudioCopy.searchPlaceholder, text: $viewModel.query)
                    .font(.sfCallout)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(.horizontal, Spacing.s4)
            .frame(minHeight: 44)
            .summaryGlass()

            TutorFilterChips(options: TutorRosterFilter.allCases, selection: $viewModel.filter) { filter in
                TutorStudioCopy.filterTitle(filter, count: viewModel.count(filter))
            }

            Picker(TutorStudioCopy.sortLabel, selection: $viewModel.sort) {
                ForEach(TutorRosterSort.allCases) { sort in
                    Text(TutorStudioCopy.sortTitle(sort)).tag(sort)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private func roster(_ course: Course) -> some View {
        if !viewModel.hasStudents {
            VStack(spacing: Spacing.s3) {
                Text(TutorStudioCopy.rosterEmptyTitle)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(TutorStudioCopy.rosterEmptyBody(course.code))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                Button {
                    isInviting = true
                } label: {
                    Label(TutorStudioCopy.inviteStudents, systemImage: "person.badge.plus")
                }
                .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            }
            .padding(Spacing.s5)
            .frame(maxWidth: .infinity)
            .summaryGlass(strong: true)
        } else if viewModel.searchFoundNothing {
            Text(TutorStudioCopy.noMatch)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass()
        } else {
            VStack(spacing: 0) {
                rosterHeader
                ForEach(viewModel.roster) { enrollment in
                    NavigationLink {
                        TutorStudentDetailView(container: container, enrollment: enrollment, course: course)
                    } label: {
                        rosterRow(enrollment)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if enrollment.status == .pending {
                            Button {
                                Task { await viewModel.approve(enrollment) }
                            } label: {
                                Label(TutorStudioCopy.approveStudent, systemImage: "checkmark")
                            }
                        }
                        Button(role: .destructive) {
                            studentToRemove = enrollment
                        } label: {
                            Label(TutorStudioCopy.removeStudent, systemImage: "person.badge.minus")
                        }
                    }
                    if enrollment.id != viewModel.roster.last?.id {
                        Divider().overlay(SummaryGlass.border)
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .summaryGlass(cornerRadius: 14, strong: true)
        }
    }

    private var rosterHeader: some View {
        HStack {
            Text(TutorStudioCopy.columnStudent)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(TutorStudioCopy.columnMastery)
                .frame(width: 64)
            Text(TutorStudioCopy.columnActive)
                .frame(width: 72, alignment: .trailing)
        }
        .font(.sfCaption.weight(.semibold))
        .foregroundStyle(ColorTokens.textSecondary)
        .padding(.vertical, Spacing.s3)
        .accessibilityHidden(true)
    }

    private func rosterRow(_ enrollment: Enrollment) -> some View {
        HStack(spacing: Spacing.s2) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.s1) {
                    Text(enrollment.studentName)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                    if viewModel.isAtRisk(enrollment) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.error)
                            .accessibilityLabel(TutorStudioCopy.atRisk)
                    }
                }
                Text(enrollment.status == .pending ? TutorStudioCopy.statusTitle(.pending) : enrollment.studentNumber)
                    .font(.sfCaption)
                    .foregroundStyle(enrollment.status == .pending ? ColorTokens.warningText : ColorTokens.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TutorMasteryPill(percent: enrollment.masteryPercent)
                .frame(width: 64)
            Text(viewModel.lastActiveText(enrollment))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 72, alignment: .trailing)
        }
        .frame(minHeight: Layout.minTouchTarget + Spacing.s2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func footer(_ course: Course) -> some View {
        HStack(spacing: Spacing.s3) {
            Button {
                isPublishing = true
            } label: {
                Label(TutorStudioCopy.publishMaterial, systemImage: "doc.badge.plus")
            }
            .buttonStyle(SummaryActionButtonStyle(isPrimary: true))
            .disabled(course.isArchived)

            NavigationLink {
                AnnouncementComposeView(container: container, courseId: course.id)
            } label: {
                Label(TutorStudioCopy.writeAnnouncement, systemImage: "megaphone")
            }
            .buttonStyle(SummaryActionButtonStyle())
            .disabled(course.isArchived)
        }
        .padding(.horizontal, TutorStudioLayout.margin)
        .padding(.vertical, Spacing.s3)
        .background(.ultraThinMaterial)
    }

    private var inviteSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(TutorStudioCopy.inviteNamePlaceholder, text: $viewModel.inviteName)
                        .textContentType(.name)
                    TextField(TutorStudioCopy.inviteNumberPlaceholder, text: $viewModel.inviteNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } footer: {
                    if let message = viewModel.inviteMessage {
                        Text(message)
                            .foregroundStyle(ColorTokens.error)
                    } else if viewModel.course?.enrolmentMode == .approval {
                        Text(TutorStudioCopy.inviteApprovalFooter)
                    }
                }
            }
            .onChange(of: viewModel.inviteName) { viewModel.limitInviteFields() }
            .onChange(of: viewModel.inviteNumber) { viewModel.limitInviteFields() }
            .navigationTitle(TutorStudioCopy.inviteStudents)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isInviting = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(TutorStudioCopy.invite) {
                        Task {
                            if await viewModel.invite() { isInviting = false }
                        }
                    }
                    .disabled(!viewModel.canInvite)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("102 Roster") {
    NavigationStack {
        TutorCourseHubView(container: .previewing(), courseId: Course.sample.id)
    }
}
