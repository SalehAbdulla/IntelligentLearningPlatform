//
//  DeveloperAccountSwitcher.swift
//  StudyForge
//
//  A DEBUG-only way to become any of the four demo accounts, so a demo never has to type
//  an address and a password.
//
//  WHY IT SIGNS IN FOR REAL
//  ------------------------
//  It would be easy to fabricate a `UserSession` here — this is a developer tool, and the
//  app has launch-argument hatches that do exactly that. It is deliberately not done, for
//  two reasons:
//
//    1. **A fabricated session proves nothing.** The four accounts exist to demonstrate
//       that the ROLE MODEL works — that a tutor claim reaches the tutor studio and a
//       student claim does not. Swapping a struct would demonstrate the struct.
//    2. **It would bypass the rules.** `firestore.rules` decides what a session may read
//       and write from the role on the ID token. A client-side swap would show screens the
//       server would refuse to fill, which is a demo that fails the moment it touches data.
//
//  So it calls `AuthService.signIn`, exactly as `LoginView` does, and the role comes back
//  from the token through `CustomClaims`. If the accounts do not exist, this fails — and it
//  says so, and names the command that creates them.
//

#if DEBUG
import SwiftUI

@MainActor
@Observable
final class DeveloperAccountSwitcherModel {

    private let auth: any AuthService

    /// The account mid-sign-in, so its row can show progress instead of looking inert.
    private(set) var busyEmail: String?

    /// A readable failure, or `nil`. Cleared at the start of every attempt.
    private(set) var error: String?

    init(auth: any AuthService) {
        self.auth = auth
    }

    var isBusy: Bool { busyEmail != nil }

    /// Signs in as `account`, replacing whatever session is current.
    ///
    /// - Returns: whether it worked, so the sheet knows whether to dismiss itself.
    func signIn(as account: DemoAccount) async -> Bool {
        guard busyEmail == nil else { return false }

        busyEmail = account.email
        error = nil
        defer { busyEmail = nil }

        do {
            // Sign OUT first. Switching while signed in would otherwise leave the previous
            // session's Firestore listeners attached to a token that is no longer current —
            // the "I switched accounts and still see the old data" bug, which is much
            // harder to diagnose in a demo than here.
            try? await auth.signOut()

            _ = try await auth.signIn(email: account.email, password: DemoAccounts.password)
            return true
        } catch {
            // `AppError.from` is the app's single mapping from any error to user-facing copy
            // (docs/04 §8), so this cannot leak a raw Firebase code into the sheet.
            let appError = AppError.from(error)
            self.error = "\(appError.title) — \(appError.message)"
            return false
        }
    }
}

/// The switcher sheet: the four accounts, which one is current, and a way to become each.
struct DeveloperAccountSwitcherSheet: View {

    let container: AppContainer

    @Environment(\.dismiss) private var dismiss
    @State private var model: DeveloperAccountSwitcherModel

    init(container: AppContainer) {
        self.container = container
        _model = State(initialValue: DeveloperAccountSwitcherModel(auth: container.auth))
    }

    /// The seeded account this session is signed in as, or `nil` for a real account.
    private var current: DemoAccount? {
        DemoAccounts.account(forEmail: container.session?.email)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(DemoAccounts.all) { account in
                        row(account)
                    }
                } header: {
                    Text("Demo accounts")
                } footer: {
                    footer
                }
            }
            .navigationTitle("Switch account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ account: DemoAccount) -> some View {
        Button {
            Task {
                if await model.signIn(as: account) { dismiss() }
            }
        } label: {
            HStack(spacing: Spacing.s3) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(account.displayName)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)

                    Text(account.email)
                        .font(.sfMono)
                        .foregroundStyle(ColorTokens.textSecondary)

                    Text("\(account.role.displayName) · \(account.plan.displayName) · \(account.reaches)")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.s2)

                if model.busyEmail == account.email {
                    ProgressView()
                } else if current?.id == account.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(ColorTokens.primary)
                        .accessibilityLabel("Currently signed in")
                }
            }
            .frame(minHeight: Layout.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(model.isBusy)
    }

    /// The failure, and then the thing to do about it.
    ///
    /// The commonest reason a demo account will not sign in is that it was never created,
    /// and "wrong credentials" does not say that — so the hint is always visible rather than
    /// only appearing after a failure.
    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let error = model.error {
                Text(error)
                    .foregroundStyle(ColorTokens.warningText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(
                "Developer tool, DEBUG builds only. The password is \"\(DemoAccounts.password)\". "
                + "If an account does not exist yet, create all four with "
                + "`npm run seed:accounts` in backend/."
            )
        }
    }
}

// MARK: - The toolbar entry point

/// Contributes a `key` toolbar button that opens the switcher.
///
/// A modifier rather than a view so the two call sites are one line each, and so the
/// DEBUG-only `#if` lives in ONE place instead of being repeated at both.
private struct DeveloperAccountSwitcherModifier: ViewModifier {

    let container: AppContainer

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = true
                    } label: {
                        Image(systemName: "key")
                    }
                    .accessibilityLabel("Developer account switcher")
                }
            }
            .sheet(isPresented: $isPresented) {
                DeveloperAccountSwitcherSheet(container: container)
            }
    }
}

#else

/// A no-op in a release build. There is no developer switcher to offer — but the modifier
/// still exists, so the call sites stay one line each and carry no `#if` of their own.
private struct DeveloperAccountSwitcherModifier: ViewModifier {
    let container: AppContainer
    func body(content: Content) -> some View { content }
}

#endif

extension View {
    /// A `key` toolbar button that becomes any of the four seeded demo accounts.
    ///
    /// Apply it **inside** a `NavigationStack` — it contributes a `ToolbarItem`, and a
    /// toolbar item with no navigation bar to attach to is silently dropped.
    ///
    /// DEBUG only. In a release build the modifier is a no-op, and `DemoAccounts`, the sheet
    /// and the model are not compiled in at all — so a shipping app cannot offer a way to
    /// become another account, and the demo password is not in the binary.
    func developerAccountSwitcher(_ container: AppContainer) -> some View {
        modifier(DeveloperAccountSwitcherModifier(container: container))
    }
}
