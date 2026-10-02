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
        }
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