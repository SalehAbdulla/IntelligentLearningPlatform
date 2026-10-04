//
//  TutorDashboardView.swift
//  StudyForge
//
//  J01 + J02 — `99_Home_Dashboard_Tutor_{M2}` and `100_Tutor_Course_List_{M2}`
//  (docs/03 §J, P0/P1). The cohort KPI row, the pending-review badge, the create action and
//  the tutor's courses.
//
//  WHY THE REVIEW QUEUE IS REACHED THROUGH A COURSE
//  ------------------------------------------------
//  `reviewQueue/{itemId}` carries a `courseId` and the rules scope it to a tutor's courses, so
//  the queue is inherently per-course. The dashboard's badge therefore REPORTS the total (it is
//  cohort-wide information) and the course is what you open to work the queue — rather than a
//  combined screen the data model does not describe.
//

import SwiftUI

struct TutorDashboardView: View {

    let container: AppContainer

    @State private var viewModel: TutorDashboardViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: TutorDashboardViewModel(
            uid: container.session?.id ?? "",
            store: container.courses
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if #available(iOS 27.0, *) {
            // J02's archive swipe. Rows outside a `List` only respond to `swipeActions` when the
            // enclosing scroll container opts in, which is what `swipeActionsContainer()` does
            // (SDK 27). On earlier systems the gesture is simply absent.
            courseScroll.swipeActionsContainer()
        } else {
            courseScroll
        }
    }

    private var courseScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                kpiRow

                if let badge = viewModel.reviewBadge {
                    reviewBanner(badge)
                }

                createLink
                courseList
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: KPI row (J01)

    private var kpiRow: some View {
        let cohort = viewModel.cohort

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.s3),
                GridItem(.flexible(), spacing: Spacing.s3),
            ],
            spacing: Spacing.s3
        ) {
            kpiTile(value: "\(cohort.students)", label: viewModel.studentsLabel)
            kpiTile(value: "\(cohort.activeThisWeek)", label: viewModel.activeLabel)
            kpiTile(value: "\(cohort.averageMastery)%", label: viewModel.masteryLabel)
            kpiTile(value: "\(cohort.atRisk)", label: viewModel.atRiskLabel, isAlert: true)
        }
    }

    private func kpiTile(value: String, label: String, isAlert: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(value)
                .font(.sfTitleM)
                .foregroundStyle(isAlert && value != "0" ? ColorTokens.warning : ColorTokens.textPrimary)

            Text(label)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    private func reviewBanner(_ badge: String) -> some View {
        Label(badge, systemImage: "checkmark.seal")
            .font(.sfBodyEmph)
            .foregroundStyle(ColorTokens.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Create (J01)

    private var createLink: some View {
        NavigationLink {
            CourseEditorView(container: container, course: nil)
        } label: {
            Text(viewModel.createCourseTitle)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Course list (J02)

    private var courseList: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.coursesHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.courses) { course in
                NavigationLink {
                    CourseDetailView(container: container, courseId: course.id)
                } label: {
                    courseCard(course)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button {
                        Task { await viewModel.setArchived(course, archived: !course.isArchived) }
                    } label: {
                        Label(
                            viewModel.archiveActionTitle(course),
                            systemImage: course.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }
                    .tint(ColorTokens.primary)
                }
            }
        }
    }

    private func courseCard(_ course: Course) -> some View {
        HStack(spacing: Spacing.s3) {
            RoundedRectangle(cornerRadius: Radius.s)
                .fill(course.coverColour)
                .frame(width: 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(course.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(course.code)
                    .font(.sfMono)
                    .foregroundStyle(ColorTokens.textSecondary)

                Text("\(viewModel.enrolmentLabel(course)) · \(viewModel.materialLabel(course))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)

                Text(viewModel.termLabel(course))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: 0)

            if course.isArchived {
                Text(viewModel.archivedBadge)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .background(ColorTokens.surface, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .frame(minHeight: Layout.minTouchTarget)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: Empty state (J01)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(viewModel.noCoursesBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                CourseEditorView(container: container, course: nil)
            } label: {
                Text(viewModel.createCourseTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("J01 Tutor dashboard") {
    NavigationStack {
        TutorDashboardView(container: .previewing())
    }
}
