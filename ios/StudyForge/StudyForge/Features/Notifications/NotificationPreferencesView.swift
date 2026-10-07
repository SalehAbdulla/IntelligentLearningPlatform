//
//  NotificationPreferencesView.swift
//  StudyForge
//
//  B09 — `19_Settings_Notifications_{M1}` (docs/03 §B, P1). Per-type toggles, quiet hours, and the
//  way into the permission primer (M02).
//

import SwiftUI

// The "send a test reminder" row fires one local notification on demand, so notifications can be
// demonstrated and verified without waiting for a scheduled session (docs/11 §6).

// Accessibility: the per-type and quiet-hours controls are native `Toggle`s (name and on/off come for
// free), each quiet-hours picker announces its label and current value, and the test-reminder button
// announces its outcome.

struct NotificationPreferencesView: View {

    @State private var viewModel: NotificationPreferencesViewModel
    @State private var isPriming = false

    private let authorizer: any NotificationAuthorizer

    init(
        store: any NotificationStore,
        authorizer: any NotificationAuthorizer,
        scheduler: any NotificationScheduler = InMemoryNotificationScheduler()
    ) {
        self.authorizer = authorizer
        _viewModel = State(initialValue: NotificationPreferencesViewModel(
            store: store,
            authorizer: authorizer,
            scheduler: scheduler
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                perTypeToggles
                quietHours
                testReminder

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

    // MARK: Test reminder

    /// A row that fires one notification now, so the feature can be shown without waiting for a
    /// scheduled session, and so the outcome is visible rather than guessed at.
    private var testReminder: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Button {
                Task { await viewModel.sendTestReminder() }
            } label: {
                HStack(spacing: Spacing.s3) {
                    Image(systemName: "bell.badge")
                        .font(.sfBody)
                        .foregroundStyle(ColorTokens.primary)
                        .accessibilityHidden(true)

                    Text(L10n.notificationTestReminder.string)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)

                    Spacer(minLength: 0)

                    if viewModel.isSendingTestReminder {
                        ProgressView().controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSendingTestReminder)

            switch viewModel.testReminderOutcome {
            case .idle:
                EmptyView()
            case .sent:
                Text(L10n.notificationTestReminderSent.string)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.successText)
                    .fixedSize(horizontal: false, vertical: true)
            case .denied:
                Text(L10n.notificationPermissionDenied.string)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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