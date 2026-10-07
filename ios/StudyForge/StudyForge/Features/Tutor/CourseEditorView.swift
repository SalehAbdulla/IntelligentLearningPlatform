//
//  CourseEditorView.swift
//  StudyForge
//
//  J03 — `101_Tutor_Course_Create_Edit_{M2}` (docs/03 §J, P0). Name and code fields, term date
//  pickers, the cover-colour picker, the enrolment mode and Save.
//
//  WHY THE VALIDATION MESSAGE IS VISIBLE RATHER THAN ONLY A DISABLED BUTTON
//  -----------------------------------------------------------------------
//  The button disables itself so an invalid form cannot be submitted, but it also NAMES what is
//  missing underneath. A greyed-out Save with no explanation is the most common dead end in a
//  form, and it is worse at AX5 where the field may be scrolled out of sight.
//

import SwiftUI

// Accessibility: the colour swatches are labelled and announce their chosen state, the decorative glyphs
// are hidden, and each field row reads as one element.

struct CourseEditorView: View {

    let container: AppContainer

    @State private var viewModel: CourseEditorViewModel

    @Environment(\.dismiss) private var dismiss

    init(container: AppContainer, course: Course?) {
        self.container = container
        _viewModel = State(initialValue: CourseEditorViewModel(
            uid: container.session?.id ?? "",
            store: container.courses,
            existing: course
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error)
                }

                fields
                colourPicker
                modePicker

                if let message = viewModel.validationMessage, !viewModel.isSaving {
                    Text(message)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.error)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SFPrimaryButton(
                    title: viewModel.saveTitle,
                    isLoading: viewModel.isSaving,
                    isEnabled: viewModel.canSave,
                    action: save,
                    loadingTitle: viewModel.savingTitle
                )
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Fields (J03)

    private var fields: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            SFTextField(
                label: viewModel.nameLabel,
                text: $viewModel.name,
                placeholder: viewModel.namePlaceholder
            )

            SFTextField(
                label: viewModel.codeLabel,
                text: $viewModel.code,
                placeholder: viewModel.codePlaceholder,
                autocapitalization: .characters
            )

            DatePicker(
                viewModel.termStartLabel,
                selection: $viewModel.termStart,
                displayedComponents: .date
            )
            .font(.sfCallout)
            .tint(ColorTokens.primary)

            DatePicker(
                viewModel.termEndLabel,
                selection: $viewModel.termEnd,
                displayedComponents: .date
            )
            .font(.sfCallout)
            .tint(ColorTokens.primary)
        }
    }

    // MARK: Cover colour (J03)

    private var colourPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.coverColourTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            HStack(spacing: Spacing.s2) {
                ForEach(0..<CourseColour.count, id: \.self) { index in
                    let isSelected = viewModel.colourIndex == index

                    Button {
                        viewModel.colourIndex = index
                    } label: {
                        Circle()
                            .fill(CourseColour.colour(at: index))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle().strokeBorder(
                                    isSelected ? ColorTokens.textPrimary : .clear,
                                    lineWidth: 2
                                )
                            }
                            .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.coverColourTitle)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    // MARK: Enrolment mode (J03)

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.enrolmentLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(viewModel.modes, id: \.self) { mode in
                modeRow(mode)
            }
        }
    }

    private func modeRow(_ mode: EnrolmentMode) -> some View {
        let isSelected = viewModel.enrolmentMode == mode

        return Button {
            viewModel.enrolmentMode = mode
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: mode.symbolName)
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                Text(viewModel.modeName(mode))
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

    // MARK: Actions

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }
}

// MARK: - Previews

#Preview("J03 New course") {
    NavigationStack {
        CourseEditorView(container: .previewing(), course: nil)
    }
}
