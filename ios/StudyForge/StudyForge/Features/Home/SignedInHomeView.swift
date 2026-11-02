//
//  SignedInHomeView.swift
//  StudyForge
//
//  F07 / B05 — `15_Home_Dashboard_Student`: where an authenticated user lands until the
//  role-specific tab bars exist.
//
//  WHAT THIS SCREEN IS
//  -------------------
//  The student home as the design draws it: a greeting with the streak pill, today's plan,
//  the due-cards badge, and the four quick actions (Upload, Summarise, Quizzes, Plan).
//  Every number on it is read from stores the app already keeps — the streak from
//  `ProgressCalculator` through the dashboard's view model, today's sessions from the plan
//  store, the due count from the deck store — so nothing is faked: an element whose source
//  has no data stays hidden rather than showing an invented value.
//
//  It also still answers F01's diagnostic question. The capability card renders WHO the app
//  thinks you are and WHICH capabilities the ID token granted, so when claims are
//  misconfigured the bug surfaces here — role and plan are exactly what `CustomClaims`
//  resolves — instead of being guessed at from a missing tab.
//
//  The S0 development surfaces stay reachable from here, DEBUG-only, so they remain
//  demonstrable without cluttering the product path.
//

import SwiftUI

// Accessibility: the greeting header reads as one statement with the streak as its own labelled
// value, each plan row announces its subject, duration and time, and every destination is a
// labelled `NavigationLink` with a 44 pt target, so the home reads as a list of places to go
// rather than bare glyphs.

struct SignedInHomeView: View {

    let container: AppContainer

    /// B05's data: today's plan, the streak and the due-cards count (F07).
    @State private var homeViewModel: StudentHomeViewModel

    /// Sign-out is asynchronous; the button shows progress rather than appearing inert.
    @State private var isSigningOut = false

    init(container: AppContainer) {
        self.container = container
        _homeViewModel = State(initialValue: StudentHomeViewModel(
            store: container.studyPlans,
            materials: container.materials,
            decks: container.decks,
            quizzes: container.quizzes,
            profile: container.profile
        ))
    }

    private var session: UserSession? { container.session }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    if let session {
                        homeHeader(for: session)
                    }

                    todayPlanCard

                    if homeViewModel.hasLoaded {
                        dueCardsLink(count: homeViewModel.dueCards)
                    }

                    quickActions

                    if let session {
                        capabilitiesCard(for: session)
                    }

                    progressLink
                    foldersLink
                    bookmarksLink
                    groupsLink
                    notificationsLink
                    searchLink
                    coachLink
                    profileLink
                    subscriptionLink
                    settingsLink

                    // K07 is an ADMIN surface: offering it to a student would be a control they can
                    // never use, which is worse than no control — the same rule the folder and
                    // bookmark screens apply to permissions.
                    if session?.role == .admin {
                        adminLink
                    }

                    // F11 is a TUTOR surface, gated the same way. `isTutor` is true for a tutor OR
                    // an admin, matching `firestore.rules`' `isTutor()` — so the link and the rules
                    // agree about who may open the studio.
                    if session?.isTutor == true {
                        tutorLink
                    }

                    #if DEBUG
                    developmentCard
                    #endif

                    signOutButton
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .task { await homeViewModel.load() }
            .background(ColorTokens.surface)
            .navigationTitle(L10n.sessionHomeTitle.string)
            .navigationBarTitleDisplayMode(.large)
            // DEBUG only: the `key` toolbar button, so a demo can switch accounts from here
            // rather than having to sign out first. It is the same modifier the log-in screen
            // uses — one entry point, two places it is reachable from.
            .developerAccountSwitcher(container)
        }
    }

    // MARK: Greeting header (B05)

    /// The greeting header: the student's name, with the streak pill when `ProgressCalculator`
    /// has real activity to count. The pill is omitted rather than zeroed while the snapshot
    /// has no data — a "0 day streak" would claim a fact the stores cannot support.
    private func homeHeader(for session: UserSession) -> some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            Text(session.displayName)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let days = homeViewModel.streakDays {
                streakPill(days: days)
            }
        }
    }

    private func streakPill(days: Int) -> some View {
        HStack(spacing: Spacing.s1) {
            Image(systemName: "flame.fill")
                .font(.sfFootnote)
            Text(homeViewModel.streakValue(days))
                .font(.sfBodyEmph)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .background(ColorTokens.primaryContainer, in: Capsule())
        .foregroundStyle(ColorTokens.textPrimary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(homeViewModel.streakLabel)
        .accessibilityValue(homeViewModel.streakValue(days))
    }

    // MARK: Today's plan (B05)

    /// The plan hero card. The whole card taps through to the week view, as the design's
    /// "taps into the plan" requires, and a failed read shows the banner instead of claiming
    /// the student has no plan.
    @ViewBuilder
    private var todayPlanCard: some View {
        if let error = homeViewModel.planError {
            SFErrorBanner(error: error, onRecover: { Task { await homeViewModel.load() } })
        } else {
            NavigationLink {
                StudyPlanView(store: container.studyPlans)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    HStack(spacing: Spacing.s2) {
                        Text(homeViewModel.planHeading)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Spacer(minLength: Spacing.s2)
                        Image(systemName: "chevron.right")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    planCardContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.s4)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var planCardContent: some View {
        if !homeViewModel.hasLoaded {
            // Before the stores have answered, no claim at all — not even "no plan".
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if homeViewModel.plan == nil {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(homeViewModel.planEmptyTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(homeViewModel.planEmptyBody)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if homeViewModel.todaySessions.isEmpty {
            Text(homeViewModel.planNoSessionsTitle)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(Array(homeViewModel.todaySessions.prefix(3))) { session in
                    planRow(session)
                }
            }
        }
    }

    /// One row of today's plan — the week view's session row, read-only: the actions (mark done,
    /// skip, reschedule) live in G06 where the full session is on screen.
    private func planRow(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(session.subject)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .strikethrough(session.status == .completed)

            Text("\(homeViewModel.planDuration(session.estimatedMinutes)) · \(session.scheduledAt.formatted(date: .omitted, time: .shortened))")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(session.status == .skipped ? 0.6 : 1)
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

    // MARK: Due-cards badge (B05)

    /// The due-cards badge: how many cards SM-2 has due across every deck, tapping into the deck
    /// list (E01). Rendered once loading has finished either way: with the count the store
    /// produced (including a genuine 0), or — when the read failed — the route alone, because a
    /// zero the store never reported must not be shown.
    private func dueCardsLink(count: Int?) -> some View {
        NavigationLink {
            DeckListView(
                materialStore: container.materials,
                deckStore: container.decks,
                router: container.ai
            )
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: "rectangle.stack")
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.primary)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    if let count {
                        Text("\(count)")
                            .font(.sfTitleM)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("\(L10n.deckTitle.string) · \(L10n.deckDueLabel.string)")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        // The deck store did not answer: keep the route, drop the number —
                        // a count it never produced would be invented.
                        Text(L10n.deckTitle.string)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                }

                Spacer(minLength: Spacing.s2)

                Image(systemName: "chevron.right")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.deckTitle.string)
            .accessibilityValue(count.map { "\($0) \(L10n.deckDueLabel.string)" } ?? "")
        }
        .buttonStyle(.plain)
    }

    // MARK: Quick actions (B05)

    /// The four quick actions the design routes through this screen. Upload and Summarise both
    /// open the library because F02's import flow and F03's per-material generate sheet live
    /// there — there is no material-agnostic route into either action.
    private var quickActions: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.s3),
                GridItem(.flexible(), spacing: Spacing.s3),
            ],
            spacing: Spacing.s3
        ) {
            NavigationLink {
                libraryDestination
            } label: {
                quickTile(L10n.onboardingStepUploadTitle.string, systemImage: "square.and.arrow.up")
            }
            NavigationLink {
                libraryDestination
            } label: {
                quickTile(L10n.librarySummarise.string, systemImage: "doc.text")
            }
            NavigationLink {
                QuizListView(
                    materialStore: container.materials,
                    quizStore: container.quizzes,
                    router: container.ai
                )
            } label: {
                quickTile(L10n.quizTitle.string, systemImage: "checklist")
            }
            NavigationLink {
                StudyPlanView(store: container.studyPlans)
            } label: {
                quickTile(L10n.planTitle.string, systemImage: "calendar")
            }
        }
    }

    private func quickTile(_ title: String, systemImage: String) -> some View {
        VStack(spacing: Spacing.s2) {
            Image(systemName: systemImage)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.primary)
            Text(title)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
        .padding(Spacing.s3)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    /// The library (C08) — both Upload and Summarise land here.
    private var libraryDestination: some View {
        MaterialLibraryView(
            store: container.materials,
            summaryStore: container.summaries,
            deckStore: container.decks,
            router: container.ai,
            bookmarkStore: container.bookmarks
        )
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

    // MARK: Bookmarks

    /// The way into bookmark collections (I15).
    ///
    /// Carries the library's stores as well, so the empty state's "Browse your library" CTA (I18)
    /// can push the library directly rather than bouncing the student back to this screen.
    private var bookmarksLink: some View {
        NavigationLink {
            CollectionListView(
                store: container.bookmarks,
                materials: container.materials,
                summaries: container.summaries,
                decks: container.decks,
                router: container.ai
            )
        } label: {
            Label(L10n.bookmarkTitle.string, systemImage: "bookmark")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Groups

    /// The way into group revision spaces (I08).
    private var groupsLink: some View {
        NavigationLink {
            GroupListView(
                store: container.groups,
                materials: container.materials,
                quizzes: container.quizzes,
                me: session?.displayName ?? ""
            )
        } label: {
            Label(L10n.groupTitle.string, systemImage: "person.3")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Notifications

    /// The way into the notification inbox (M01).
    private var notificationsLink: some View {
        NavigationLink {
            NotificationsInboxView(
                store: container.notifications,
                plans: container.studyPlans
            )
        } label: {
            Label(L10n.notificationInboxTitle.string, systemImage: "bell")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Subscription

    /// The way into the paywall / manage screen (L01, L10). The designed route is a row inside
    /// B08's settings; until that row exists, the home carries the direct link.
    private var subscriptionLink: some View {
        NavigationLink {
            PaywallView(container: container)
        } label: {
            Label(L10n.subscriptionTitle.string, systemImage: "creditcard")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Settings

    /// The way into settings (B08).
    private var settingsLink: some View {
        NavigationLink {
            SettingsView(container: container)
        } label: {
            Label(L10n.notificationSettingsTitle.string, systemImage: "gearshape")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Search

    /// The way into global search (M05).
    private var searchLink: some View {
        NavigationLink {
            GlobalSearchView(
                materials: container.materials,
                summaries: container.summaries,
                decks: container.decks,
                quizzes: container.quizzes,
                folders: container.folders,
                bookmarks: container.bookmarks,
                recents: container.recentSearches
            )
        } label: {
            Label(L10n.searchTitle.string, systemImage: "magnifyingglass")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Admin

    /// The way into the admin area (K01). Admin only.
    private var adminLink: some View {
        NavigationLink {
            AdminDashboardView(container: container)
        } label: {
            Label(L10n.adminDashboardTitle.string, systemImage: "person.badge.key")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Tutor studio

    /// The way into the tutor content studio (J01). Tutor and admin only — see the gate at the
    /// call site.
    private var tutorLink: some View {
        NavigationLink {
            TutorDashboardView(container: container)
        } label: {
            Label(L10n.tutorDashboardTitle.string, systemImage: "person.crop.rectangle.stack")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Study companion

    /// The way into the coach (H01). The designed route is a tab in the student spine, which
    /// does not exist yet, so the home carries the link until the tab bar lands.
    private var coachLink: some View {
        NavigationLink {
            CoachHomeView(container: container)
        } label: {
            Label(L10n.coachTitle.string, systemImage: "sparkles")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Profile

    /// The way into the profile.
    ///
    /// The designed way into B06 is a tab or a settings row that does not exist yet, so the home
    /// carries the link for now. It goes to B06, whose shortcut list opens B07 — the designed
    /// home → profile → edit chain rather than a direct jump to the editor.
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

