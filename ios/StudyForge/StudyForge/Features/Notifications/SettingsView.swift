//
//  SettingsView.swift
//  StudyForge
//
//  B08 — `18_Settings_Main_{M1}` (docs/03 §B, P1). The grouped settings hub.
//
//  WHY SOME OF THE DESIGNED ROWS ARE ABSENT
//  ----------------------------------------
//  B08 lists Account · Notifications · Accessibility · Language · AI & Data · Subscription · Sign out.
//  Only the first two and Sign out have somewhere to go today: the accessibility and language switches
//  belong to the RTL/accessibility pass, AI & Data to the admin config (F12), and Subscription to
//  payments (F13). A row that leads nowhere is worse than a row that is not there, so the rest are
//  recorded here rather than rendered inert.
//
//  WHY IT TAKES THE CONTAINER
//  --------------------------
//  A settings hub is the one screen whose whole job is to reach other screens, and those screens are
//  built from different services. Passing each one individually would make this the most coupled file
//  in the app; passing the container is honest about what a hub is.
//

import SwiftUI

struct SettingsView: View {

    let container: AppContainer

    @State private var isSigningOut = false

    var body: some View {
        List {
            Section(L10n.notificationSettingsAccount.string) {
                NavigationLink {
                    ProfileView(container: container)
                } label: {
                    Label(L10n.profileViewTitle.string, systemImage: "person.crop.circle")
                }
            }

            Section(L10n.notificationSettingsTitle.string) {
                NavigationLink {
                    NotificationPreferencesView(
                        store: container.notifications,
                        authorizer: container.notificationAuthorizer
                    )
                } label: {
                    Label(L10n.notificationInboxTitle.string, systemImage: "bell")
                }
            }

            Section {
                Button(role: .destructive) {
                    signOut()
                } label: {
                    HStack {
                        Label(L10n.sessionSignOut.string, systemImage: "rectangle.portrait.and.arrow.right")
                        if isSigningOut {
                            Spacer(minLength: Spacing.s2)
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                .disabled(isSigningOut)
            }
        }
        .background(ColorTokens.surface)
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.notificationSettingsTitle.string)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signOut() {
        isSigningOut = true
        Task {
            defer { isSigningOut = false }
            try? await container.auth.signOut()
        }
    }
}

// MARK: - Previews

#Preview("B08 Settings") {
    NavigationStack {
        SettingsView(container: .previewing())
    }
}