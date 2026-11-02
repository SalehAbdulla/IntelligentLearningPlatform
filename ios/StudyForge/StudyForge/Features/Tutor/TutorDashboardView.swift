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

// Accessibility: each metric card and roster row reads as one element, the decorative glyph is hidden, and
// the section list is a container of labelled rows.

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

    /// The dashboard body is a **`List`**, and that is a constraint, not a style.
    ///
    /// J02 asks for an "archive swipe action" on the course cards, and SwiftUI only honours
    /// `.swipeActions` on rows inside a `List`. The alternative is `swipeActionsContainer()` —
    /// an **iOS 27** API — which this file used behind `#available(iOS 27.0, *)`. That guard is
    /// right for *runtime* availability and wrong for *compile* time: the symbol does not exist
    /// in the iOS 26 SDK, so the project stopped building on the stable Xcode a marker would
    /// use, to gain one gesture. `60dbfe0` removed the call — but left `.swipeActions` behind,
    /// where a `ScrollView` ignores it silently, so the archive looked implemented and did
    /// nothing.
    ///
    /// A `List` with `.swipeActions` has worked since **iOS 15**, so this needs no preview SDK.
    /// The cost is that every block is now a row and has to say what the old `VStack` gave it
    /// for free — see `dashboardRow`.
    @ViewBuilder
    private var content: some View {
        courseList
    }

    /// The whole dashboard — the KPI grid, the review banner, the create action and the courses —
    /// as rows of ONE `List`, so that the course rows can carry J02's swipe.
    private var courseList: some View {
        List {
            dashboardRow(gapAbove: Layout.screenMargin) { kpiRow }

            if let badge = viewModel.reviewBadge {
                dashboardRow(gapAbove: Spacing.s6) { reviewBanner(badge) }
            }

            dashboardRow(gapAbove: Spacing.s6) { createLink }

            dashboardRow(gapAbove: Spacing.s6) { coursesHeading }

            ForEach(viewModel.courses) { course in
                dashboardRow(gapAbove: Spacing.s3) {
                    NavigationLink {
                        CourseDetailView(container: container, courseId: course.id)
                    } label: {
                        courseCard(course)
                    }
                    .buttonStyle(.plain)
                }
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // The old `ScrollView` ended with `padding(Layout.screenMargin)`. A `List` does not, so
        // without this the last card sits flush against the tab bar.
        .contentMargins(.bottom, Layout.screenMargin, for: .scrollContent)
    }

    /// One dashboard block, as a `List` row.
    ///
    /// A `List` row arrives with chrome the old `ScrollView` never drew — a separator, a row
    /// background, the list's own insets — and with no vertical rhythm between rows at all.
    /// This puts the design back. `gapAbove` is the `VStack(spacing:)` the blocks used to sit in,
    /// and the two frames reproduce the old centring: the content column is capped at
    /// `Layout.maxContentWidth` and then centred inside the full width of the row.
    private func dashboardRow<Content: View>(
        gapAbove: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, Layout.screenMargin)
            .padding(.top, gapAbove)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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
                .foregroundStyle(isAlert && value != "0" ? ColorTokens.warningText : ColorTokens.textPrimary)

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

    /// J02's "courses" heading. It is its own row now, so it needs no spacing of its own — the
    /// row's `gapAbove` is what separates it from the KPI grid above and the first card below.
    private var coursesHeading: some View {
        Text(viewModel.coursesHeading)
            .font(.sfSubhead)
            .foregroundStyle(ColorTokens.textSecondary)
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
