//
//  CourseDetailView.swift
//  StudyForge
//
//  J04 + J05 + J10 — `102_Tutor_Course_Roster_{M2}`, `103_Tutor_Material_Publish_{M2}` and
//  `108_Tutor_Gradebook_Export_{M2}` (docs/03 §J).
//
//  WHY THE GRADEBOOK IS A SHARE LINK AND NOT AN "EXPORT" BUTTON
//  ------------------------------------------------------------
//  J10 says "Export CSV / PDF". The honest iOS way to hand a file to another app is the system
//  share sheet — it reaches Files, Mail, Numbers and AirDrop without the app writing to a
//  location it does not own. So the CSV is written to a temporary file and offered through
//  `ShareLink`, and the row says what has to happen first when there is nothing to export.
//

import SwiftUI

struct CourseDetailView: View {

    let container: AppContainer

    @State private var viewModel: CourseDetailViewModel
    @State private var showingPublish = false
    @State private var showingInvite = false
    @State private var gradebookURL: URL?

    init(container: AppContainer, courseId: String) {
        self.container = container
        _viewModel = State(initialValue: CourseDetailViewModel(
            uid: container.session?.id ?? "",
            courseId: courseId,
            store: container.courses,
            materials: container.materials
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                header
                tutorActions
                publishedSection
                rosterSection
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.searchPlaceholder
        )
        .task {
            await viewModel.load()
            writeGradebook()
        }
        .sheet(isPresented: $showingPublish) { publishSheet }
        .sheet(isPresented: $showingInvite) { inviteSheet }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(spacing: Spacing.s3) {
                RoundedRectangle(cornerRadius: Radius.s)
                    .fill(viewModel.course?.coverColour ?? ColorTokens.primary)
                    .frame(width: 6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(viewModel.title)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)

                    Text(viewModel.course?.code ?? "")
                        .font(.sfMono)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }

            Text("\(viewModel.cohort.students) · \(viewModel.cohort.averageMastery)%")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Tutor actions — the way into J06, J07, J09 and J03

    private var tutorActions: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            NavigationLink {
                ReviewQueueView(container: container, courseId: viewModel.courseId)
            } label: {
                actionRow(viewModel.reviewTitle, symbol: "checkmark.seal")
            }

            NavigationLink {
                AnnouncementComposeView(container: container, courseId: viewModel.courseId)
            } label: {
                actionRow(viewModel.announceTitle, symbol: "megaphone")
            }

            if let course = viewModel.course {
                NavigationLink {
                    CourseEditorView(container: container, course: course)
                } label: {
                    actionRow(L10n.tutorEditCourse.string, symbol: "pencil")
                }
            }

            shareGradebook
        }
    }

    private func actionRow(_ label: String, symbol: String) -> some View {
        Label(label, systemImage: symbol)
            .font(.sfBodyEmph)
            .foregroundStyle(ColorTokens.primary)
            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
    }

    @ViewBuilder
    private var shareGradebook: some View {
        if let url = gradebookURL {
            ShareLink(item: url) {
                Label(viewModel.exportTitle, systemImage: "square.and.arrow.up")
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
            }
        } else {
            Text(viewModel.exportEmpty)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
                .frame(minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Published material (J05)

    private var publishedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                Text(viewModel.publishedHeading)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                Spacer(minLength: Spacing.s2)

                Button(viewModel.publishActionTitle) { showingPublish = true }
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.primary)
            }

            if viewModel.publishedMaterials.isEmpty {
                Text(viewModel.publishedNone)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(viewModel.publishedMaterials) { material in
                    HStack(spacing: Spacing.s2) {
                        Text(material.title)
                            .font(.sfBody)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(2)

                        Spacer(minLength: Spacing.s2)

                        Text(viewModel.publishedStatusLabel(material))
                            .font(.sfCaption)
                            .foregroundStyle(
                                material.isLive() ? ColorTokens.successText : ColorTokens.warningText
                            )
                    }
                    .frame(minHeight: Layout.minTouchTarget)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Roster (J04)

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                Text(viewModel.rosterTitle)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                Spacer(minLength: Spacing.s2)

                Button(viewModel.inviteTitle) { showingInvite = true }
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.primary)
            }

            if !viewModel.hasRoster {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(viewModel.rosterEmptyTitle)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)

                    Text(viewModel.rosterEmptyBody)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if viewModel.searchFoundNothing {
                Text(viewModel.rosterNoMatch)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textTertiary)
            } else {
                ForEach(viewModel.roster) { enrollment in
                    rosterRow(enrollment)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    private func rosterRow(_ enrollment: Enrollment) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(spacing: Spacing.s2) {
                Text(enrollment.studentName)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                if enrollment.status == .pending {
                    badge(L10n.tutorPendingBadge.string, tint: ColorTokens.secondary)
                }

                if enrollment.isAtRisk {
                    badge(L10n.tutorAtRiskBadge.string, tint: ColorTokens.warning)
                }

                Spacer(minLength: 0)
            }

            Text("\(viewModel.studentIdLabel) \(enrollment.studentNumber) · \(viewModel.masteryLabel(enrollment))")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.lastActiveLabel(enrollment))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.s2)
        .accessibilityElement(children: .combine)
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.sfCaption)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(tint.opacity(0.14), in: Capsule())
    }

    // MARK: Publish sheet (J05)

    private var publishSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    if viewModel.availableMaterials.isEmpty {
                        Text(viewModel.publishEmpty)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(spacing: Spacing.s2) {
                            ForEach(viewModel.availableMaterials) { material in
                                materialRow(material)
                            }
                        }

                        DatePicker(
                            viewModel.publishDateLabel,
                            selection: $viewModel.publishDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .font(.sfCallout)
                        .tint(ColorTokens.primary)

                        Toggle(viewModel.notifyStudentsTitle, isOn: $viewModel.notifyStudents)
                            .font(.sfCallout)
                            .tint(ColorTokens.primary)

                        SFPrimaryButton(
                            title: viewModel.publishActionTitle,
                            isEnabled: viewModel.canPublish,
                            action: {
                                Task {
                                    if await viewModel.publish() {
                                        showingPublish = false
                                        writeGradebook()
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.publishTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { showingPublish = false }
                }
            }
        }
    }

    private func materialRow(_ material: Material) -> some View {
        let isSelected = viewModel.publishSelection == material.id

        return Button {
            viewModel.publishSelection = material.id
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: material.source.symbolName)
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                Text(material.title)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .frame(minHeight: Layout.minTouchTarget)
            .background(
                isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                in: .rect(cornerRadius: Radius.l)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l)
                    .strokeBorder(
                        isSelected ? ColorTokens.primary : ColorTokens.outline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Invite sheet (J04)

    private var inviteSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    SFTextField(
                        label: viewModel.inviteNameLabel,
                        text: $viewModel.inviteName,
                        placeholder: viewModel.inviteNamePlaceholder,
                        autocapitalization: .words
                    )

                    SFTextField(
                        label: viewModel.inviteNumberLabel,
                        text: $viewModel.inviteNumber,
                        placeholder: "",
                        keyboard: .numberPad
                    )

                    SFPrimaryButton(
                        title: viewModel.inviteTitle,
                        isLoading: viewModel.isInviting,
                        isEnabled: viewModel.canInvite,
                        action: {
                            Task {
                                if await viewModel.invite() {
                                    showingInvite = false
                                    writeGradebook()
                                }
                            }
                        }
                    )
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.inviteTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { showingInvite = false }
                }
            }
        }
    }

    // MARK: Gradebook file (J10)

    /// Writes the CSV after every roster change, so the share link always offers the current
    /// file rather than a stale one left by an earlier export.
    private func writeGradebook() {
        guard viewModel.canExport else {
            gradebookURL = nil
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gradebook-\(viewModel.courseId).csv")

        do {
            try viewModel.gradebookCSV().write(to: url, atomically: true, encoding: .utf8)
            gradebookURL = url
        } catch {
            gradebookURL = nil
        }
    }
}

// MARK: - Previews

#Preview("J04 Course detail") {
    NavigationStack {
        CourseDetailView(container: .previewing(), courseId: Course.sample.id)
    }
}
