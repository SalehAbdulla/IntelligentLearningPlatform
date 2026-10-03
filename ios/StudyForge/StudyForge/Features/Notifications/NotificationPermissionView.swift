//
//  NotificationPermissionView.swift
//  StudyForge
//
//  M02 — `129_Notification_Permission_Request_{M1}` (docs/03 §M, P0). The primer shown before the
//  system permission prompt, with Enable / Not now.
//

import SwiftUI

struct NotificationPermissionView: View {

    @State private var viewModel: NotificationPermissionViewModel

    /// Called when the student dismisses the primer, whatever they chose.
    private let onDismiss: () -> Void

    init(authorizer: any NotificationAuthorizer, onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: NotificationPermissionViewModel(authorizer: authorizer))
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        Image(systemName: "bell.badge")
                            .font(.sfDisplayL)
                            .foregroundStyle(ColorTokens.primary)
                            .accessibilityHidden(true)

                        Text(viewModel.title)
                            .font(.sfTitleM)
                            .foregroundStyle(ColorTokens.textPrimary)

                        Text(viewModel.body)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.sfCallout)
                            .foregroundStyle(viewModel.isDenied ? ColorTokens.error : ColorTokens.successText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        // Hidden once the answer is in: a control that cannot prompt again is worse
                        // than no control, which is the same rule the folder and bookmark screens use.
                        if !viewModel.isResolved {
                            SFPrimaryButton(
                                title: viewModel.enableTitle,
                                isLoading: viewModel.isRequesting,
                                action: { Task { await viewModel.enable() } }
                            )
                        }

                        Button(viewModel.notNowTitle) { onDismiss() }
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
        }
    }
}

// MARK: - Previews

#Preview("M02 Permission primer") {
    NotificationPermissionView(authorizer: InMemoryNotificationAuthorizer()) {}
}

#Preview("M02 Permission — already granted") {
    NotificationPermissionView(
        authorizer: InMemoryNotificationAuthorizer(status: .granted)
    ) {}
}