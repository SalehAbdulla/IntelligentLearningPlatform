//
//  AnnouncementComposeView.swift
//  StudyForge
//
//  J09 — `107_Tutor_Announcement_Compose_{M2}` (docs/03 §J, P1). The message editor, the
//  template starters, the audience selector and the send-now / schedule pair.
//

import SwiftUI

struct AnnouncementComposeView: View {

    let container: AppContainer

    @State private var viewModel: AnnouncementComposeViewModel

    init(container: AppContainer, courseId: String) {
        self.container = container
        _viewModel = State(initialValue: AnnouncementComposeViewModel(
            uid: container.session?.id ?? "",
            courseId: courseId,
            store: container.courses
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error)
                }

                if let confirmation = viewModel.confirmationText {
                    Label(confirmation, systemImage: "checkmark.circle.fill")
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                editor
                templates
                audienceSection
                scheduleSection

                if let message = viewModel.validationMessage, !viewModel.isSending {
                    Text(message)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.error)
                        .fixedSize(horizontal: false, vertical: true)
                }

                actions
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            SFTextField(
                label: viewModel.titleLabel,
                text: $viewModel.title,
                placeholder: viewModel.titlePlaceholder
            )

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(viewModel.bodyLabel)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                TextEditor(text: $viewModel.body)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .frame(minHeight: 160)
                    .padding(Spacing.s2)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                    .accessibilityLabel(viewModel.bodyLabel)
            }
        }
    }

    // MARK: Templates

    private var templates: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.templatesHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.templates) { template in
                Button {
                    viewModel.applyTemplate(template)
                } label: {
                    Text(template.title)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
                }
            }
        }
    }

    // MARK: Audience (J09)

    private var audienceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.audienceLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.audiences, id: \.self) { audience in
                audienceRow(audience)
            }
        }
    }

    private func audienceRow(_ audience: AnnouncementAudience) -> some View {
        let isSelected = viewModel.audience == audience

        return Button {
            viewModel.audience = audience
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: audience.symbolName)
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                Text(viewModel.audienceName(audience))
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)

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

    // MARK: Schedule (J09)

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Toggle(viewModel.scheduleTitle, isOn: $viewModel.wantsSchedule)
                .font(.sfCallout)
                .tint(ColorTokens.primary)

            if viewModel.wantsSchedule {
                DatePicker(
                    viewModel.scheduleTitle,
                    selection: $viewModel.scheduledFor,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.sfCallout)
                .tint(ColorTokens.primary)
            }
        }
    }

    // MARK: Actions

    private var actions: some View {
        Group {
            if viewModel.wantsSchedule {
                SFPrimaryButton(
                    title: viewModel.scheduleTitle,
                    isLoading: viewModel.isSending,
                    isEnabled: viewModel.canSend,
                    action: { Task { await viewModel.schedule() } }
                )
            } else {
                SFPrimaryButton(
                    title: viewModel.sendNowTitle,
                    isLoading: viewModel.isSending,
                    isEnabled: viewModel.canSend,
                    action: { Task { await viewModel.sendNow() } }
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("J09 Announcement") {
    NavigationStack {
        AnnouncementComposeView(container: .previewing(), courseId: Course.sample.id)
    }
}
