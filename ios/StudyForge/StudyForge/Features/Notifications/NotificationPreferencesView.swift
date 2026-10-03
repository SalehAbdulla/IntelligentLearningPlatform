//
//  NotificationPreferencesView.swift
//  StudyForge
//
//  B09 — `19_Settings_Notifications_{M1}` (docs/03 §B, P1). Per-type toggles, quiet hours, and the
//  way into the permission primer (M02).
//

import SwiftUI

struct NotificationPreferencesView: View {

    @State private var viewModel: NotificationPreferencesViewModel
    @State private var isPriming = false

    private let authorizer: any NotificationAuthorizer

    init(store: any NotificationStore, authorizer: any NotificationAuthorizer) {
        self.authorizer = authorizer
        _viewModel = State(initialValue: NotificationPreferencesViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                perTypeToggles
                quietHours

                Button(L10n.notificationPermissionEnable.string) { isPriming = true }
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)

                SFPrimaryButton(
                    title: viewModel.saveTitle,
                    isLoading: viewModel.isSaving,
                    action: { Task { await viewModel.save() } },
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
        .task { await viewModel.load() }
        .sheet(isPresented: $isPriming) {
            NotificationPermissionView(authorizer: authorizer) { isPriming = false }
        }
    }

    // MARK: Per-type

    private var perTypeToggles: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            ForEach(viewModel.muteableKinds) { kind in
                Toggle(
                    kind.title,
                    isOn: Binding(
                        get: { viewModel.isOn(kind) },
                        set: { viewModel.setOn(kind, $0) }
                    )
                )
                .tint(ColorTokens.primary)
                .font(.sfBodyEmph)
            }
        }
    }

    // MARK: Quiet hours

    private var quietHours: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Toggle(viewModel.quietHoursTitle, isOn: $viewModel.quietHoursEnabled)
                .tint(ColorTokens.primary)
                .font(.sfBodyEmph)

            Text(viewModel.quietHoursCaption)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // The pickers appear only when quiet hours are on, so the common case stays short.
            if viewModel.quietHoursEnabled {
                HStack(spacing: Spacing.s4) {
                    hourPicker(selection: $viewModel.quietStartHour)
                    Text("–")
                        .foregroundStyle(ColorTokens.textSecondary)
                        .accessibilityHidden(true)
                    hourPicker(selection: $viewModel.quietEndHour)
                }
                .padding(.top, Spacing.s1)
            }
        }
    }

    private func hourPicker(selection: Binding<Int>) -> some View {
        Menu {
            ForEach(viewModel.hours, id: \.self) { hour in
                Button(viewModel.hourTitle(hour)) { selection.wrappedValue = hour }
            }
        } label: {
            Text(viewModel.hourTitle(selection.wrappedValue))
                .font(.sfMono)
                .foregroundStyle(ColorTokens.primary)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .frame(minHeight: Layout.minTouchTarget)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        }
        .accessibilityLabel(viewModel.quietHoursTitle)
        .accessibilityValue(viewModel.hourTitle(selection.wrappedValue))
    }
}

// MARK: - Previews

#Preview("B09 Notification settings") {
    NavigationStack {
        NotificationPreferencesView(
            store: InMemoryNotificationStore(),
            authorizer: InMemoryNotificationAuthorizer()
        )
    }
}