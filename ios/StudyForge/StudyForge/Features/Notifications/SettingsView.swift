//
//  SettingsView.swift
//  StudyForge
//
//  B08 — `18_Settings_Main_{M1}` (docs/03 §B, P1). The grouped settings hub.
//
//  WHY SOME OF THE DESIGNED ROWS ARE ABSENT
//  ----------------------------------------
//  B08 lists Account · Notifications · Accessibility · Language · AI & Data · Subscription · Sign out.
//  Account, Notifications, Subscription and Sign out have somewhere to go today. The accessibility and
//  language switches belong to the RTL/accessibility pass and AI & Data to the admin config (F12); a
//  row that leads nowhere is worse than a row that is not there, so those are recorded here rather than
//  rendered inert.
//
//  WHY IT TAKES THE CONTAINER
//  --------------------------
//  A settings hub is the one screen whose whole job is to reach other screens, and those screens are
//  built from different services. Passing each one individually would make this the most coupled file
//  in the app; passing the container is honest about what a hub is.
//

import SwiftUI

// Accessibility: every row is a labelled `NavigationLink`, and sign-out is a labelled destructive button
// that shows its working state instead of appearing inert.

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
                        authorizer: container.notificationAuthorizer,
                        scheduler: container.notificationScheduler
                    )
                } label: {
                    Label(L10n.notificationInboxTitle.string, systemImage: "bell")
                }
            }

            // B13 — the subscription row (F13). It leads to the SAME screen L10 defines, so
            // there is one place where plan, renewal and cancellation are described.
            Section {
                NavigationLink {
                    ManageSubscriptionView(container: container)
                } label: {
                    Label(L10n.subscriptionTitle.string, systemImage: "creditcard")
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