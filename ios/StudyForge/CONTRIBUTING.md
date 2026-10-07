# Contributing to StudyForge (iOS)

> **Read this first, then open [`docs/13-PER-MEMBER-TASKS.md`](../../docs/13-PER-MEMBER-TASKS.md) for your personal task list.** Your work only counts if it is committed under your own name, so do step 1 before you touch code.

## 1. Your identity and your branch (once, about 5 minutes)

```bash
cd IntelligentLearningPlatform
git config --local user.name  "Your Full Name"
git config --local user.email "<studentID>@student.polytechnic.bh"   # e.g. 202401702@student.polytechnic.bh
git switch develop && git pull
git switch -c feat/Fxx-short-slug        # e.g. feat/F04-sm2-tuning
```

**Never commit to `main` or `develop`.** One file per commit, via `bash tools/commit.sh <path> "type(Fxx): subject"`. Full rules: [`docs/12-GIT-WORKFLOW.md`](../../docs/12-GIT-WORKFLOW.md).

## 2. Build, run, test

```bash
bash tools/run-ios.sh                     # build + install + launch on the iPhone 17 simulator
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj \
  -scheme StudyForge -destination 'platform=iOS Simulator,name=iPhone 17' test
# -> 723 tests in 117 suites pass. Keep it that way.
```

## 3. How the code is organised (the 60-second version)

- **MVVM.** Each feature folder holds `<Name>View.swift` and an `@Observable` `<Name>ViewModel.swift`. Views render state, view models own logic.
- **No singletons.** Everything is injected through `StudyForge/App/AppContainer.swift`. To add a dependency, add it there and pass it down.
- **States come free.** Use `LoadState` (idle / loading / loaded / failed) and `AppError` from `Core/State/`, so loading and error screens are consistent.
- **Tokens, never literals.** Colours from `ColorTokens`, fonts from `Font.sf*` (`TypeScale.swift`), spacing from `Spacing.swift`. **Never hardcode a hex, a point size, or a user-facing string** (use `L10n`).

## 4. Where to work: feature, owner, and the files to open

Find your feature, open its folder, and change it there. All paths are under `ios/StudyForge/StudyForge/`.

| Feature | Owner | Folder(s) | Start in this file | Tested by |
|---|---|---|---|---|
| **F01** Auth and onboarding | M1 | `Features/Auth`, `Features/Onboarding`, `Features/ProfileSetup`, `Core/Auth` | `AuthFlowView.swift`, `LoginViewModel.swift` | M4 |
| **F02** Upload and library | M1 | `Features/Library`, `Core/Materials` | `MaterialLibraryView.swift`, `ImportMaterialViewModel.swift` | M3 |
| **F03** AI summary | M2 | `Features/Summaries`, `Core/Summaries` | `SummaryFlowViewModel.swift` | M1 |
| **F04** Flashcards and SM-2 | M2 | `Features/Flashcards`, `Core/Scheduling/SpacedRepetition.swift` | `FlashcardReviewViewModel.swift`, `SpacedRepetition.swift` | M4 |
| **F05** Quiz and analytics | M2 | `Features/Quizzes`, `Core/Quizzes` | `QuizGenerateViewModel.swift`, `QuizTakeViewModel.swift` | M4 |
| **F06** Study plan | M3 | `Features/StudyPlan`, `Core/Planning` | `StudyPlanWizardViewModel.swift`, `StudyPlanner.swift` | M2 |
| **F07** Progress | M3 | `Features/Progress`, `Core/Progress` | `ProgressDashboardViewModel.swift`, `ProgressCalculator.swift` | M1 |
| **F08** Shared folders | M4 | `Features/Folders` | `FolderListViewModel.swift`, `FolderDetailViewModel.swift` | M3 |
| **F09** Group spaces | M4 | `Features/Groups`, `Core/Groups` | `LiveQuizViewModel.swift`, `GroupDetailViewModel.swift` | M1 |
| **F10** Bookmarks | M4 | `Features/Bookmarks` | `BookmarkSaveViewModel.swift`, `CollectionListViewModel.swift` | M3 |
| **F11** Tutor studio | M2 | `Features/Tutor` | `TutorDashboardViewModel.swift`, `ReviewQueueViewModel.swift` | M4 |
| **F12** Admin | M4 | `Features/Admin`, `Core/Admin` | `AdminDashboardViewModel.swift`, `AdminUsersViewModel.swift` | M2 |
| **F13** Subscription and payments | M3 | `Features/Subscription`, `Core/Payments` | `CheckoutViewModel.swift`, `PaymentGateway.swift` | M2 |
| **F14** Notifications | M1 | `Features/Notifications` | `NotificationsInboxViewModel.swift` | M3 |
| **F15** AI Study Companion | M2 + M3 | `Features/Coach`, `Core/Coach` | `CoachChatViewModel.swift`, `RetrievalService.swift` | M1 |

Not owned by one feature: `Features/Home` (the signed-in shell), `Features/Search` (global search), `Features/DesignSystemGallery` and `Features/AISpike` (development surfaces). Treat these as shared; coordinate before changing them.

## 4b. Find your TODO tasks

Small, ready-to-implement tasks are marked in the code with your handle:

```
// TODO(M2 · F04): one-line task ...
// Done when: the acceptance criterion
```

- List every open task: `bash tools/todos.sh`
- Find only yours: `grep -rn "TODO(M2" ios/StudyForge --include='*.swift'`
- Work one, then commit with `bash tools/commit.sh <file> "feat(F04): ..."` and **delete the marker**.

Each task is derived from a real gap the code itself records (a comment that says "for now" or "not yet"), so it is a genuine improvement rather than busywork. Pick tasks for features you **own** first, then for features you **test**. If you finish them and want more, take an edge case from `docs/02-FEATURE-LIST-OWNERSHIP.md` §6 for a feature you own.

## 5. Where the tests live

One file per area under `ios/StudyForge/StudyForgeTests/`, named `<Area>Tests.swift` (for example `FlashcardReviewViewModelTests.swift`, `QuizStoreTests.swift`). Add a test with every fix; the suite is Swift Testing (`import Testing`, `@Test`), not XCTest.

## 6. Guardrails

- One file per commit, Conventional Commits, through `tools/commit.sh`. It refuses protected branches and non-conventional messages.
- No secrets in a commit. `tools/commit.sh` scans for them.
- Keep the build at zero warnings and all tests green.
- Never hardcode a colour, font size or user-facing string.

## 7. Where to go for more

| You need | Read |
|---|---|
| Your personal tasks | `docs/13-PER-MEMBER-TASKS.md` |
| Git rules and commands | `docs/12-GIT-WORKFLOW.md` |
| Design tokens and components | `docs/06-DESIGN-SYSTEM.md` |
| Feature scope and screens | `docs/02-FEATURE-LIST-OWNERSHIP.md`, `docs/03-SCREEN-INVENTORY.md` |
| Architecture and the AI router | `docs/04-TECH-ARCHITECTURE-COST.md` |
