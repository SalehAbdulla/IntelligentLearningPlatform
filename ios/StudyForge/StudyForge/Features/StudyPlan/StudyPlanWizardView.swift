//
//  StudyPlanWizardView.swift
//  StudyForge
//
//  F06's four-step wizard — subjects, availability, deadline, intensity — presented as a sheet. The
//  view model explains why the collected input is a plain value type.
//

import SwiftUI

struct StudyPlanWizardView: View {

    @State private var viewModel: StudyPlanWizardViewModel
    @Environment(\.dismiss) private var dismiss

    /// Called once a plan has been generated, so the week view behind it can reload.
    let onGenerated: () -> Void

    init(store: any StudyPlanStore, onGenerated: @escaping () -> Void) {
        _viewModel = State(initialValue: StudyPlanWizardViewModel(store: store))
        self.onGenerated = onGenerated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Text(viewModel.stepIndicator)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)

                    switch viewModel.step {
                    case .subjects: subjectsStep
                    case .availability: availabilityStep
                    case .deadline: deadlineStep
                    case .intensity: intensityStep
                    }

                    if let error = viewModel.error {
                        SFErrorBanner(error: error, onRecover: nil)
                    }

                    navigationButtons
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { dismiss() }
                        .disabled(viewModel.isSaving)
                }
            }
        }
    }

    // MARK: Subjects

    private var subjectsStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(viewModel.subjectsHeading)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            SFTextField(
                label: viewModel.subjectPlaceholder,
                text: $viewModel.subjectText,
                placeholder: viewModel.subjectPlaceholder,
                submitLabel: .done,
                autocorrectionDisabled: false,
                onSubmit: { viewModel.addSubject() }
            )

            SFPrimaryButton(
                title: viewModel.addSubjectTitle,
                isEnabled: !viewModel.subjectText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                action: { viewModel.addSubject() }
            )

            if !viewModel.subjects.isEmpty {
                SFChipFlow(spacing: Spacing.s2, lineSpacing: Spacing.s2) {
                    ForEach(viewModel.subjects, id: \.self) { subject in
                        subjectChip(subject)
                    }
                }
            }
        }
    }

    private func subjectChip(_ subject: String) -> some View {
        Button { viewModel.removeSubject(subject) } label: {
            HStack(spacing: Spacing.s1) {
                Text(subject)
                Image(systemName: "xmark")
            }
            .font(.sfCaption)
            .foregroundStyle(ColorTokens.onPrimaryContainer)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .background(ColorTokens.primaryContainer, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(subject), \(L10n.commonDelete.string)")
    }

    // MARK: Availability

    private var availabilityStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.availabilityHeading)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            SFSegmentedField(
                label: viewModel.availabilityHeading,
                selection: $viewModel.weeklyHours,
                options: [4, 8, 12, 16, 20],
                title: { "\($0)" }
            )

            // G02, part one: the days the student cannot study. The hours above say HOW MUCH
            // time exists; these chips say WHERE it may not go. No new copy: weekday names come
            // from the system's own localisation (the same `.formatted(.dateTime.weekday)`
            // facility the progress bars use), and state is carried by icon, colour and strike
            // rather than by words this key set does not have.
            SFChipFlow(spacing: Spacing.s2, lineSpacing: Spacing.s2) {
                ForEach(1...7, id: \.self) { weekday in
                    weekdayChip(weekday)
                }
            }
        }
    }

    private func weekdayChip(_ weekday: Int) -> some View {
        let isBlocked = viewModel.blockedDays.contains(weekday)
        return Button { viewModel.toggleBlockedDay(weekday) } label: {
            HStack(spacing: Spacing.s1) {
                Text(weekdayLetter(weekday))
                Image(systemName: isBlocked ? "xmark.circle.fill" : "circle")
            }
            .font(.sfCaption)
            .foregroundStyle(isBlocked ? ColorTokens.error : ColorTokens.textSecondary)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .frame(minHeight: Layout.minTouchTarget)
            .background(
                isBlocked ? ColorTokens.error.opacity(0.10) : ColorTokens.surfaceVariant,
                in: .capsule
            )
            .strikethrough(isBlocked)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(weekdayName(weekday))
        .accessibilityAddTraits(isBlocked ? .isSelected : [])
    }

    /// The weekday's letter in the system language — no project key exists for day names, and
    /// the OS localises this for free (same facility as `ProgressDashboardView`'s bar labels).
    private func weekdayLetter(_ weekday: Int) -> String {
        weekdayDate(weekday).formatted(.dateTime.weekday(.narrow))
    }

    /// VoiceOver gets the full day name, also from the OS.
    private func weekdayName(_ weekday: Int) -> String {
        weekdayDate(weekday).formatted(.dateTime.weekday(.wide))
    }

    /// A date inside the current week carrying this weekday, for the name lookups above.
    private func weekdayDate(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = weekday
        return calendar.date(from: components) ?? Date()
    }

    // MARK: Deadline

    private var deadlineStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.deadlineHeading)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Toggle(viewModel.noDeadlineTitle, isOn: Binding(
                get: { !viewModel.hasDeadline },
                set: { viewModel.hasDeadline = !$0 }
            ))
            .font(.sfBody)
            .tint(ColorTokens.primary)

            if viewModel.hasDeadline {
                DatePicker(
                    viewModel.deadlineHeading,
                    selection: $viewModel.deadline,
                    displayedComponents: .date
                )
                .font(.sfBody)
            }

            if !viewModel.subjects.isEmpty {
                perSubjectExamDates
            }
        }
    }

    // MARK: Per-course exam dates (F06)

    /// One exam-date row per subject the student entered on step 1.
    ///
    /// The copy is entirely reused: `plan.subjectsHeading` asks "What are you studying?", and every
    /// control is labelled with the subject itself, so this adds no localisation key. That is not
    /// laziness — `Core/Localisation/` sits in M1's OWNED_DIRS, so editing `L10n.swift` would put
    /// this commit outside M3's lane. If the team wants the word "exam" spelled out per row, M1
    /// adds a key and this becomes a one-line swap.
    ///
    /// Each row is optional because "this course has no exam yet" is a real answer. Forcing a date
    /// onto every subject would make the planner squeeze horizons the student never set.
    private var perSubjectExamDates: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(viewModel.subjectsHeading)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.subjects, id: \.self) { subject in
                examDateRow(subject)
            }
        }
    }

    private func examDateRow(_ subject: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Toggle(subject, isOn: Binding(
                get: { viewModel.examDates[subject] != nil },
                set: { viewModel.setExamDate(enabled: $0, for: subject) }
            ))
            .font(.sfBody)
            .tint(ColorTokens.primary)

            if let date = viewModel.examDates[subject] {
                DatePicker(
                    subject,
                    selection: Binding(
                        get: { date },
                        set: { viewModel.setExamDate($0, for: subject) }
                    ),
                    displayedComponents: .date
                )
                .font(.sfBody)
            }
        }
    }

    // MARK: Intensity

    private var intensityStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.intensityHeading)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            SFSegmentedField(
                label: viewModel.intensityHeading,
                selection: $viewModel.intensity,
                options: StudyIntensity.allCases,
                title: { viewModel.intensityTitle($0) }
            )

            SFPrimaryButton(
                title: viewModel.generateTitle,
                isLoading: viewModel.isSaving,
                action: {
                    Task {
                        await viewModel.generate()
                        if viewModel.savedPlan != nil { onGenerated(); dismiss() }
                    }
                },
                loadingTitle: viewModel.generateTitle
            )
        }
    }

    // MARK: Navigation

    @ViewBuilder
    private var navigationButtons: some View {
        if !viewModel.isLastStep {
            HStack(spacing: Spacing.s3) {
                if viewModel.step != .subjects {
                    Button(viewModel.commonBackTitle) { viewModel.back() }
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget)
                }

                SFPrimaryButton(
                    title: viewModel.commonNextTitle,
                    isEnabled: viewModel.canContinue,
                    action: { viewModel.next() }
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("G01 Study plan wizard") {
    StudyPlanWizardView(store: InMemoryStudyPlanStore()) {}
}