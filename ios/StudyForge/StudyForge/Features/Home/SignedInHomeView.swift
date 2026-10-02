//
//  SignedInHomeView.swift
//  StudyForge
//
//  Where an authenticated user lands until the role-specific tab bars exist.
//
//  WHY THIS IS A REAL SCREEN AND NOT A STUB
//  ----------------------------------------
//  F01's goal is "get a verified user onto the correct role home". The role homes (5-tab
//  student spine, 4-tab tutor, 4-tab admin — docs/03 §5) belong to later features. Rather
//  than fake one, this screen does the honest thing: it confirms WHO the app thinks you
//  are and WHICH capabilities it has granted you.
//
//  That makes it genuinely useful during development. When claims are misconfigured, the
//  bug surfaces here — role and plan are exactly what `CustomClaims` resolves — so a bad
//  token is diagnosed at a glance instead of by guessing at a tab bar.
//
//  The S0 development surfaces stay reachable from here, DEBUG-only, so they remain
//  demonstrable without cluttering the product path.
//

import SwiftUI

struct SignedInHomeView: View {

    let container: AppContainer

    /// Sign-out is asynchronous; the button shows progress rather than appearing inert.
    @State private var isSigningOut = false

    private var session: UserSession? { container.session }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    if let session {
                        identityCard(for: session)
                        capabilitiesCard(for: session)
                    }

                    libraryLink
                    flashcardsLink
                    quizzesLink
                    studyPlanLink
                    progressLink
                    foldersLink
                    profileLink

                    #if DEBUG
                    developmentCard
                    #endif

                    signOutButton
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(L10n.sessionHomeTitle.string)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Identity

    private func identityCard(for session: UserSession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(session.displayName)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            // Selectable so a uid can be pasted into the Firebase console while debugging.
            Text(session.id)
                .font(.sfMono)
                .foregroundStyle(ColorTokens.textSecondary)
                .textSelection(.enabled)

            Text(L10n.sessionHomeBody.string(session.role.displayName))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: Capabilities

    private func capabilitiesCard(for session: UserSession) -> some View {
        // Rendered from the resolved session, which comes from the ID token's claims. If
        // this ever disagrees with the Firestore document, the CLAIMS are authoritative —
        // they are what Firestore rules read.
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(L10n.homeCapabilitiesHeading.string)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            capabilityRow(L10n.homeRoleLabel.string, session.role.displayName)
            capabilityRow(L10n.homePlanLabel.string, session.plan.displayName)
            capabilityRow(
                L10n.homeTutorStudioLabel.string,
                session.isTutor ? L10n.homeAvailable.string : L10n.homeUnavailable.string
            )
            capabilityRow(L10n.homeStudyGroupsLabel.string, "\(session.groupIds.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Library

    /// The way into the library (C08).
    ///
    /// The designed routes are the student home's quick-action tiles and tab bar (B05, F07),
    /// neither of which exists yet, so the placeholder home carries the link for now — the same
    /// reason it carries the profile link.
    private var libraryLink: some View {
        NavigationLink {
            MaterialLibraryView(
                store: container.materials,
                summaryStore: container.summaries,
                deckStore: container.decks,
                router: container.ai
            )
        } label: {
            Label(L10n.libraryTitle.string, systemImage: "books.vertical")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Flashcards

    /// The way into the deck list (E01).
    private var flashcardsLink: some View {
        NavigationLink {
            DeckListView(
                materialStore: container.materials,
                deckStore: container.decks,
                router: container.ai
            )
        } label: {
            Label(L10n.deckTitle.string, systemImage: "rectangle.stack")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Quizzes

    /// The way into the quiz history (F01).
    private var quizzesLink: some View {
        NavigationLink {
            QuizListView(
                materialStore: container.materials,
                quizStore: container.quizzes,
                router: container.ai
            )
        } label: {
            Label(L10n.quizTitle.string, systemImage: "checklist")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Study plan

    /// The way into the study plan (G06).
    private var studyPlanLink: some View {
        NavigationLink {
            StudyPlanView(store: container.studyPlans)
        } label: {
            Label(L10n.planTitle.string, systemImage: "calendar")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Progress

    /// The way into the progress dashboard (G10/G11).
    private var progressLink: some View {
        NavigationLink {
            ProgressDashboardView(
                materials: container.materials,
                decks: container.decks,
                quizzes: container.quizzes,
                studyPlans: container.studyPlans,
                profile: container.profile
            )
        } label: {
            Label(L10n.progressTitle.string, systemImage: "chart.bar")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Folders

    /// The way into shared folders (I01).
    private var foldersLink: some View {
        NavigationLink {
            FolderListView(
                store: container.folders,
                materials: container.materials,
                ownerName: session?.displayName ?? ""
            )
        } label: {
            Label(L10n.folderTitle.string, systemImage: "folder")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Profile

    /// The way into the profile.
    ///
    /// The home screen is a placeholder (B05 belongs to F07) and the designed way into B06 is a
    /// tab or a settings row that does not exist yet, so it carries the link for now. The link
    /// goes to B06, whose shortcut list opens B07 — the designed home → profile → edit chain
    /// rather than a direct jump to the editor.
    private var profileLink: some View {
        NavigationLink {
            ProfileView(container: container)
        } label: {
            Label(L10n.profileViewTitle.string, systemImage: "person.crop.circle")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    private func capabilityRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer(minLength: Spacing.s2)
            Text(value)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    // MARK: Development surfaces (DEBUG only — these strings are deliberately not
    // localised: they are developer tools and never ship to a user.)

    #if DEBUG
    private var developmentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text("Development")
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            // Answers "which Firebase am I actually talking to?" without a debugger.
            Text("\(container.firebaseSource.displayName) · \(container.environment.displayName)")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            NavigationLink("Design system gallery") { DesignSystemGallery() }
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)

            NavigationLink("AI spike") { AISpikeView() }
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.l))
    }
    #endif

    // MARK: Sign out

    private var signOutButton: some View {
        SFPrimaryButton(
            title: L10n.sessionSignOut.string,
            isLoading: isSigningOut,
            action: {
                isSigningOut = true
                Task {
                    defer { isSigningOut = false }
                    // A failure is not surfaced: there is nothing the user can do, and the
                    // screen is about to be replaced by the signed-out branch regardless.
                    try? await container.auth.signOut()
                }
            }
        )
        .padding(.top, Spacing.s2)
    }
}

// MARK: - Previews

#Preview("Signed in — student") {
    SignedInHomeView(container: .previewing())
}

#Preview("Signed in — tutor on pro") {
    SignedInHomeView(
        container: .previewing(
            session: UserSession(
                id: "uid_tutor",
                displayName: "Dr Ali",
                role: .tutor,
                plan: .pro,
                groupIds: ["g_1042", "g_2088"]
            )
        )
    )
}

