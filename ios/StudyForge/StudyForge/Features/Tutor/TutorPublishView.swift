import SwiftUI

struct TutorPublishView: View {

    let container: AppContainer

    @State private var viewModel: TutorPublishViewModel
    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, course: Course, selectedMaterialId: String? = nil) {
        self.container = container
        _viewModel = State(initialValue: TutorPublishViewModel(
            uid: container.session?.id ?? "",
            course: course,
            store: container.courses,
            materials: container.materials,
            router: container.ai,
            selectedMaterialId: selectedMaterialId
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SummaryBackdrop()
                if let result = viewModel.result {
                    done(result)
                } else {
                    form
                }
            }
            .navigationTitle(TutorStudioCopy.publishTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.result == nil ? L10n.commonCancel.string : L10n.commonDone.string) { dismiss() }
                        .disabled(viewModel.isPublishing)
                }
            }
            .task { await viewModel.load() }
        }
        .interactiveDismissDisabled(viewModel.isPublishing)
    }

    private var form: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    materialSection
                    if viewModel.selectedMaterial != nil {
                        visibilitySection
                        cohortSection
                        notifySection
                        aiSection
                    }
                    if let error = viewModel.error {
                        SFErrorBanner(error: error, onRecover: nil)
                    }
                }
                .padding(.horizontal, TutorStudioLayout.margin)
                .padding(.vertical, Spacing.s4)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }

            SFPrimaryButton(
                title: TutorStudioCopy.publish,
                isLoading: viewModel.isPublishing,
                isEnabled: viewModel.canPublish,
                action: { Task { await viewModel.publish() } },
                loadingTitle: TutorStudioCopy.publishing
            )
            .padding(.horizontal, TutorStudioLayout.margin)
            .padding(.vertical, Spacing.s3)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.sfFootnote.weight(.semibold))
            .foregroundStyle(ColorTokens.textSecondary)
    }

    @ViewBuilder
    private var materialSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(TutorStudioCopy.materialLabel)
            if !viewModel.hasLoaded {
                ProgressView().frame(maxWidth: .infinity)
            } else if viewModel.materials.isEmpty {
                Label(TutorStudioCopy.noMaterials, systemImage: "tray")
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .summaryGlass(strong: true)
            } else {
                VStack(spacing: Spacing.s2) {
                    ForEach(viewModel.materials) { material in
                        Button {
                            viewModel.selectedMaterialId = material.id
                        } label: {
                            materialRow(material)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func materialRow(_ material: Material) -> some View {
        let isSelected = viewModel.selectedMaterialId == material.id
        return HStack(spacing: Spacing.s3) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : material.source.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(width: Spacing.s6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(material.title)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if isSelected {
                    Text(viewModel.visibilityText)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.warningText)
                } else if viewModel.isPublished(material) {
                    Text(TutorStudioCopy.alreadyPublished)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.successText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget + Spacing.s2, alignment: .leading)
        .background(isSelected ? ColorTokens.primary.opacity(0.12) : Color.clear, in: .rect(cornerRadius: Radius.m))
        .summaryGlass(strong: !isSelected)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(TutorStudioCopy.publishDateLabel)
            VStack(spacing: Spacing.s2) {
                Toggle(TutorStudioCopy.scheduleToggle, isOn: $viewModel.schedules)
                    .tint(ColorTokens.primary)
                if viewModel.schedules {
                    DatePicker(
                        TutorStudioCopy.publishDateLabel,
                        selection: $viewModel.publishDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .font(.sfCallout)
            .padding(Spacing.s4)
            .summaryGlass()
        }
    }

    private var cohortSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            fieldLabel(TutorStudioCopy.targetCohort)
            SFChipFlow(spacing: Spacing.s2) {
                chip(TutorStudioCopy.allCohorts, isOn: viewModel.allTargetsSelected) {
                    viewModel.selectAllTargets()
                }
                ForEach(viewModel.targetCourses) { course in
                    chip(course.code.isEmpty ? course.name : course.code, isOn: viewModel.targetIds.contains(course.id)) {
                        viewModel.toggleTarget(course.id)
                    }
                }
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sfFootnote.weight(isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? ColorTokens.onError : ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.s3)
                .frame(minHeight: 34)
                .background(isOn ? ColorTokens.primary : SummaryGlass.fill.opacity(0.66), in: .capsule)
                .overlay(Capsule().strokeBorder(isOn ? Color.clear : SummaryGlass.border, lineWidth: 1))
                .frame(minHeight: Layout.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var notifySection: some View {
        Toggle(isOn: $viewModel.notifies) {
            VStack(alignment: .leading, spacing: 2) {
                Text(TutorStudioCopy.notifyStudents)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(TutorStudioCopy.notifyFooter)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .tint(ColorTokens.primary)
        .padding(Spacing.s4)
        .summaryGlass()
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Toggle(isOn: $viewModel.draftsAIContent) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(TutorStudioCopy.draftAI)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(TutorStudioCopy.draftAIFooter)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .tint(ColorTokens.primary)

            if viewModel.draftsAIContent {
                SFChipFlow(spacing: Spacing.s2) {
                    ForEach(ReviewKind.allCases) { kind in
                        chip(TutorStudioCopy.kindTitle(kind), isOn: viewModel.draftKinds.contains(kind)) {
                            viewModel.toggleKind(kind)
                        }
                    }
                }
            }
        }
        .padding(Spacing.s4)
        .summaryGlass()
    }

    private func done(_ result: TutorPublishResult) -> some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: result.isScheduled ? "calendar.badge.clock" : "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(ColorTokens.success)
                .accessibilityHidden(true)
            Text(result.isScheduled ? TutorStudioCopy.scheduledTitle : TutorStudioCopy.publishedTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(TutorStudioCopy.publishedBody(result.courses, result.drafted))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            if result.failures > 0 {
                Label(TutorStudioCopy.draftFailures(result.failures), systemImage: "exclamationmark.triangle.fill")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.warningText)
                    .multilineTextAlignment(.center)
            }
            SFPrimaryButton(title: L10n.commonDone.string) { dismiss() }
                .padding(.top, Spacing.s4)
        }
        .padding(TutorStudioLayout.margin)
        .frame(maxWidth: Layout.maxContentWidth)
        .sensoryFeedback(.success, trigger: result)
    }
}

#Preview("103 Publish") {
    TutorPublishView(container: .previewing(), course: Course.sample)
}
