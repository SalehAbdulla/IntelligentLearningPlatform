# Contributing to StudyForge

**The full guide for every member of this project.** Read it once end to end, then keep
it open for the first week — after that, the *Quick reference* at the bottom is usually
enough.

> **New teammate, start here:** §2 gets you running in about 30 minutes, §3 tells you
> exactly which files are yours, and §4 is the loop you repeat every day.

---

## The 60-second version

| | |
|---|---|
| **What we are building** | **StudyForge** — an iOS app that turns any study material into summaries, flashcards, quizzes and a study plan. SwiftUI + Swift 6, Firebase, on-device-first AI. |
| **Your work is marked per person** | The **Sprints component (10%) is individual**. Your own commits, tests and logs are the only evidence. |
| **The app is the critical path** | **iOS App Implementation & Demonstration is 60% and a hard pass gate.** If it fails, the course is failed regardless of everything else. |
| **The three rules** | 1. **Never commit to `main` or `develop`.** 2. **One commit per file.** 3. **Commit only code you can explain out loud.** |
| **Before every commit** | `bash tools/check-lane.sh M2` (or M3 / M4) |
| **Your handover file** | `docs/TODO-M2-mohammed.md` · `docs/TODO-M3-tasbeeh.md` · `docs/TODO-M4-shahad.md` |

---

## 1. What this project is, and what is actually marked

### 1.1 The assessment model

| # | Component | Weight | Type | Must pass? | Status |
|---|---|---|---|---|---|
| 1 | Individual App | 10% | Individual | - | ✅ complete |
| 2 | Design Document | 10% | Group | - | due **22 Oct 2026** |
| 3 | Prototype (Figma) | 10% | Group | - | due **12 Nov 2026** |
| 4 | **Sprints** | **10%** | **Individual** | - | continuous |
| 5 | **iOS App Implementation & Demonstration** | **60%** | Group | ⛔ **MUST PASS** | continuous + in-person VIVA |

**Two conditions must both hold to pass the course:** an aggregate mark ≥ 60%, **and** a
pass in the 60% App Implementation & Demonstration.

### 1.2 Why that ordering changes how you should work

- **The app outranks everything.** If a day has to be sacrificed, it is sacrificed from
  Figma or documentation, **never** from the app, the demo rehearsal or your sprint
  evidence. (Cut-line protocol: `docs/01-ROADMAP-PHASES-TODOLIST.md` §14.)
- **The Sprints mark cannot be done for you.** It is read off `git log --author`. A
  helpful teammate does not raise it.
- **The VIVA is where the app mark is confirmed or lost.** The brief requires that *each
  student can present and explain any part of the app*. Using AI to write code is
  **explicitly permitted** by the tutor. Submitting code you cannot explain is not — see
  the *comprehension contract*, `docs/10-SPRINT-PLAN.md` §9.

### 1.3 The three-layer architecture, in one line each

| Layer | What it is | Where |
|---|---|---|
| **App** | The product. All features, state, design system, AI router, offline cache. | `ios/` |
| **Backend** | ~95% declarative Firebase config + 3 small Cloud Functions. No server of ours runs. | `backend/` |
| **Everything else** | Planning docs, research/evidence, deliverables, tooling. Project-level. | `docs/`, `research/`, `deliverables/`, `tools/` |

### 1.4 The 15 features

| Owner | Features |
|---|---|
| **M1** Saleh Abdulla `202300540` | F01 Auth & Onboarding · F02 Upload & Library · F14 Notifications |
| **M2** Mohammed Almadhoon `202401702` | F03 Summary · F04 Flashcards · F05 Quiz · F11 Tutor Studio · F15 Companion (co) |
| **M3** Tasbeeh Saeed `202300549` | F06 Study Plan · F07 Progress · F13 Payments · F15 Companion (co) |
| **M4** Shahad Ashoor `202305767` | F08 Folders · F09 Group Spaces · F10 Bookmarks · F12 Admin |

Full detail, including who tests what: `docs/02-FEATURE-LIST-OWNERSHIP.md`.

---

## 2. Get set up — about 30 minutes, once

### 2.1 Prerequisites

| Tool | Version | Why |
|---|---|---|
| **Xcode** | 26.6 or newer (verified on **27.0**) | iOS 26+ target, Swift 6 |
| **iOS Simulator runtime** | iOS 26.5 and 27.0 | Build and test |
| **Swift** | 6.4 | Language mode |
| **Node.js** | 24.15 | Firebase CLI only |
| **Firebase CLI** | latest (`npm i -g firebase-tools`) | Emulators and rules tests |
| **GitHub CLI** | latest (`gh`) | Creating PRs from the terminal |
| **Figma desktop** | latest | Reading the prototype (M1 edits it) |
| A **physical iPhone** | any, with your Apple ID on it | The demo must run on real hardware |

### 2.2 Clone, and set your identity — do this first

```bash
git clone https://github.com/SalehAbdulla/IntelligentLearningPlatform.git
cd IntelligentLearningPlatform
```

**Your commits must be traceable to you.** Git records whatever `user.name` /
`user.email` are set at commit time, and getting this wrong is invisible until a marker
tries to count your work. Set it **repo-locally** so it does not affect your other
projects:

```bash
# replace with YOUR name and YOUR student ID
git config --local user.name  "Mohammed Almadhoon"
git config --local user.email "202401702@student.polytechnic.bh"
```

| Member | Name | Student ID | Email to use |
|---|---|---|---|
| M1 | Saleh Abdulla | `202300540` | `202300540@student.polytechnic.bh` |
| M2 | Mohammed Almadhoon | `202401702` | `202401702@student.polytechnic.bh` |
| M3 | Tasbeeh Saeed | `202300549` | `202300549@student.polytechnic.bh` |
| M4 | Shahad Ashoor | `202305767` | `202305767@student.polytechnic.bh` |

> **Never** commit under someone else's identity, and **never** push another member's
> work under your own name. Both are treated as fabrication.

Verify it took:

```bash
git config --local user.name && git config --local user.email
git switch develop && git pull
```

### 2.3 Running on the Simulator (no setup needed)

```bash
bash tools/run-ios.sh              # build + install + launch on "iPhone 17"
bash tools/run-ios.sh "iPhone Air" # pick a different simulator by name
```

> Xcode 27 replaced `Simulator.app` with **Device Hub**, so `open -a Simulator` no longer
> works. Use the script, or the VS Code task *iOS: run on simulator*.

### 2.4 Running on your real iPhone (one-time setup)

A real device needs a signing team and a bundle identifier your own Apple ID can
provision. **Those two values are deliberately kept out of the repo**, so the shared
project stays on `develop` instead of forking a long-lived "device" branch.

```bash
cp tools/device.local.env.example tools/device.local.env
# then edit it and fill in both values:
#   DEVICE_BUNDLE_ID="com.yourname.studyforge"
#   DEVICE_TEAM="XXXXXXXXXX"     # Xcode > Settings > Accounts > your team

bash tools/run-device.sh --list          # see your paired devices
bash tools/run-device.sh                 # first paired iPhone
bash tools/run-device.sh "My iPhone"     # pick by name
```

`tools/device.local.env` is gitignored — keep it that way.

### 2.5 Verify your setup — 5 minutes, do not skip

```bash
# 1. the toolchain works at all
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

# 2. the suite is green BEFORE you change anything (expect 723 tests, 117 suites)
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# 3. the repo's own safety nets
python3 tools/verify-docs.py       # planning-doc links and ownership integrity
python3 tools/check-strings.py     # English/Arabic parity, 910 keys
bash tools/todos.sh                # every open TODO, grouped by owner

# 4. the lane guard knows who you are
bash tools/check-lane.sh M2        # or M3 / M4 — expect "REFUSING" on develop, exit 1
```

Then **practise the whole cycle once** on a throwaway branch, so your first real branch
is not your first branch:

```bash
bash tools/new-branch.sh chore/practice-yourname
echo "practice" > "practice-yourname.txt"
bash tools/commit.sh --push "practice-yourname.txt" "chore: practise the branch and commit workflow"
gh pr create --base develop --fill
gh pr merge --merge --delete-branch
```

### 2.6 VS Code tasks (optional, saves typing)

`.vscode/tasks.json` already defines: *iOS: run on simulator* · *iOS: run on device* ·
*iOS: build (simulator)* · *iOS: run unit tests* · *iOS: open Device Hub* ·
*iOS: clean build folder*. Run them with **Cmd-Shift-P → Tasks: Run Task**.

---

## 3. Know what you own — features *and* files

### 3.1 Your features (and the ≥2 rule)

The brief requires every developer to own **at least two features**. Each of us owns three
or more:

| Member | Develops | Primary tester for |
|---|---|---|
| **M1** Saleh | F01, F02, F14 | F03, F07, F09, F15 |
| **M2** Mohammed | F03, F04, F05, F11, F15 (co) | F06, F12, F13 |
| **M3** Tasbeeh | F06, F07, F13, F15 (co) | F02, F08, F10, F14 |
| **M4** Shahad | F08, F09, F10, F12 | F01, F04, F05, F11 |

**Nobody tests a feature they developed.** For every feature the developer, the primary
tester and the secondary tester are three different people, so each feature is read
independently by at least three members. Log those tests in `research/testing/`.

The rotation matrix is `docs/02-FEATURE-LIST-OWNERSHIP.md` §7.

### 3.2 Your file lane — this is what prevents merge conflicts

Three members may be running AI agents at the same time. To make that safe, **every file
belongs to exactly one lane**, and the three lanes are verified disjoint: **47 files
across the three modify-lanes, zero claimed by two members.**

**Run this before every commit and push:**

```bash
bash tools/check-lane.sh M2      # or M3 / M4
```

It refuses `main`/`develop`, lists every file your branch would change, and classifies
each as **yours**, **new (yours)**, **SHARED**, or **OUT OF LANE / FORBIDDEN**.

| | M2 Mohammed | M3 Tasbeeh | M4 Shahad |
|---|---|---|---|
| **Branches** | `feat/F03-*` `F04-*` `F05-*` `F11-*` `F15-*` | `feat/F06-*` `F07-*` `F13-*` `F15-*` | `feat/F08-*` `F09-*` `F10-*` `F12-*` |
| **Owns** | `Core/AI/`, `Features/{Flashcards,Summaries,Quizzes,Tutor}/`, `Core/Admin/AIConfiguration.swift` | `Core/{Planning,Payments}/`, `Features/{StudyPlan,Progress,Subscription}/`, `Features/Home/SignedInHomeView.swift`, `Core/Tutor/CohortSnapshot.swift` | `Core/{Groups,Bookmarks,Folders}/`, `Features/{Groups,Folders,Bookmarks,Admin}/` |

| Path | Owner |
|---|---|
| `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`, `README.md`, `CONTRIBUTING.md`, `.mailmap` | **M1 only** |
| `ios/StudyForge/StudyForge.xcodeproj/` | **nobody, ever** |

Full lane detail: `docs/14-COLLEAGUE-AI-AGENT-PROMPTS.md` §2, and your own handover file
(`docs/TODO-M2-mohammed.md`, `docs/TODO-M3-tasbeeh.md`, `docs/TODO-M4-shahad.md`).

### 3.3 The three shared files

Only three files are shared. Keep any change to them **1–2 lines**, and rebase immediately
before pushing:

- `ios/StudyForge/StudyForge/App/AppContainer.swift` — **the single injection point**
- `ios/StudyForge/StudyForge/Resources/en.lproj/Localizable.strings`
- `ios/StudyForge/StudyForge/Resources/ar.lproj/Localizable.strings`

> **Prefer not to touch them.** If a new type needs injecting, give it a **default-valued
> parameter** instead of editing `AppContainer`, and the shared file disappears from your
> diff entirely.

### 3.4 Why adding new files is safe here

`project.pbxproj` uses **`PBXFileSystemSynchronizedRootGroup`** for both `StudyForge` and
`StudyForgeTests`. Xcode syncs those folders automatically, so **adding a new `.swift`
file does not modify the project file** — normally the worst conflict source in an Xcode
repository, and here it is structurally eliminated.

> **Create new Swift files directly in the folder** (Finder, VS Code, or the terminal).
> **Do not** use Xcode's *File → Add Files…* dialog, and never hand-edit
> `project.pbxproj`.

---

## 4. The daily loop

```
1. SYNC
   git switch develop && git pull

2. BRANCH   (one branch per feature, always from develop)
   bash tools/new-branch.sh feat/F04-hard-grade-tracking

3. PLAN FIRST
   Write the plan before the code: which files, which seam, which test,
   the exact commit sequence, and what could break.

4. WORK IN SMALL STEPS
   change one file -> build -> test -> commit that file
   bash tools/check-lane.sh M2                  # before the commit
   bash tools/commit.sh <path> "feat(F04): ..."

5. PUSH DAILY
   git fetch origin && git rebase origin/develop
   bash tools/commit.sh --push <path> "test(F04): ..."

6. PR -> REVIEW -> MERGE
   gh pr create --base develop --title "feat(F04): ..." \
      --body-file .github/PULL_REQUEST_TEMPLATE.md
   Reviewer = the named tester for that feature.
   Merge, delete the branch, then log the work in your contribution log.
```

**Why plan before coding.** The plan is what makes the change reviewable, and it is what
lets you write the commit messages before you are tired. For AI-assisted work it matters
even more: a plan you write is a plan you can defend in the VIVA.

**Why push daily.** A thin `git log --author="<you>"` means a thin individual mark, and it
is fixable *that week*, not at the VIVA.

---

## 5. Git: the rules

The full contract is `docs/12-GIT-WORKFLOW.md`. The parts you will use every day:

### 5.1 Branch model

```
main        ●───────────────●────────────────●        stable, demo-ready, PROTECTED
             ╲             ╱ ╲              ╱
develop       ●───●───●───●    ●───●───●───●           integration, PROTECTED
               ╲   ╱ ╲   ╱      ╲   ╱ ╲   ╱
feat/*          ●─●   ●─●        ●─●   ●─●              one feature per branch
```

| Branch | Who pushes | Protected |
|---|---|---|
| `main` | nobody directly — merges only, from `develop` or `release/*` | ✅ |
| `develop` | nobody directly — merges only, from feature branches | ✅ |
| `feat/<Fxx>-<slug>` | the feature's developer | no |
| `fix/<slug>` · `docs/<slug>` · `chore/<slug>` | whoever owns it | no |
| `release/sprint-<N>` | the sprint lead | no |

**Branch naming:** lowercase, hyphenated, and **feature branches must carry the feature
ID** — that is what makes your sprint evidence searchable.

```
feat/F04-hard-grade-tracking      fix/F13-tap-webhook-idempotency
feat/F09-presence-seam            docs(F06)-plan-wizard-flow
```

```bash
bash tools/new-branch.sh feat/F04-hard-grade-tracking   # creates from up-to-date develop and pushes
```

> ⚠️ **Both `main` and `develop` require a pull request.** A direct push from a **member
> account** is rejected by GitHub. Verified: `GH006: Changes must be made through a pull
> request.` The **repository owner is deliberately exempt** from admin enforcement (decided
> 8 Oct 2026, because there is a single manager who merges every PR), so the owner may push
> directly. That exemption applies to nobody else, and the owner still uses a branch and a PR
> for every normal change. It is never silent either: the owner's short forms are
> `bash tools/commit.sh --owner …` and `bash tools/check-lane.sh owner --allow-protected`, both
> of which print the decision they are acting under. Details:
> [doc 12 §3.1](docs/12-GIT-WORKFLOW.md).

### 5.2 One file per commit

**One file per commit, each with its own message.** A commit touching five files forces a
reviewer to hold five unrelated thoughts at once, and it destroys attribution.

```bash
# ✅ good — reads as a narrative of the work
bash tools/commit.sh Core/Scheduling/SpacedRepetition.swift    "feat(F04): implement SM-2 interval calculation"
bash tools/commit.sh Features/Flashcards/FlashcardsViewModel.swift "feat(F04): wire SM-2 intervals into the review view model"
bash tools/commit.sh StudyForgeTests/SpacedRepetitionTests.swift "test(F04): cover SM-2 lapse and interval growth"

# ❌ bad
git add -A && git commit -m "updates"
```

**Exception:** a genuinely atomic multi-file change (a protocol and its only conformer)
may share a commit — say so in the message body.

### 5.3 Commit messages — Conventional Commits

```
<type>(<scope>): <subject>
```

Types: `feat` · `fix` · `test` · `docs` · `refactor` · `chore` · `style` · `perf`.
Scope: `F01`–`F15`, or an area scope (`app`, `ios`, `firebase`, `tools`, `docs`, `ci`).

| ❌ Not meaningful | ✅ Meaningful |
|---|---|
| `update` | `feat(F03): add summary length selector (short / standard / exam-ready)` |
| `fix stuff` | `fix(F05): auto-submit the quiz when the timer expires` |
| `changes` | `refactor(F06): move plan scheduling maths into StudyPlanner` |
| `wip` | `feat(F02): add Vision OCR page-offset extraction (WIP, no error path yet)` |
| `final` | `docs(design-doc): add competitor teardown table and references` |

**The test to apply:** *could a marker read this message, open the diff, and understand what
you did and why, without asking you?* If not, rewrite it.

`tools/commit.sh` **rejects** non-conventional messages and a list of banned words
(`update`, `wip`, `stuff`, `final`, `misc`, …), so this is enforced, not advisory.

### 5.4 Pushing

```bash
# first push sets upstream tracking
git push -u origin feat/F04-hard-grade-tracking

# or let the helper do it
bash tools/commit.sh --push <path> "feat(F04): ..."
```

- **Push at least once a day** while working. Continuous evidence is what the sprint
  component rewards.
- **Rebase `develop` into your branch daily**, so branches stay short-lived (days, not
  weeks):
  ```bash
  git fetch origin && git rebase origin/develop
  ```
- **Never force-push a shared branch.** Revert instead.
- **Never commit secrets.** `GoogleService-Info.plist`, keys, `.env`,
  `*.xcconfig.local` and `tools/device.local.env` are gitignored — check `git status`
  before staging anything.

### 5.5 Pull requests and review

Every branch reaches `develop` through a PR. **Even if you review it yourself, the PR body
is evidence.**

```bash
gh pr create --base develop \
  --title "feat(F04): track the Hard grade separately in SM-2" \
  --body-file .github/PULL_REQUEST_TEMPLATE.md
```

The template asks for four things you must actually complete:

1. **A 3-sentence plain-English explanation** of what the code does and why. This is a
   **gate, not a formality** — if you cannot write it, you do not understand the change
   yet. (`docs/10-SPRINT-PLAN.md` §9.)
2. **Traceability:** feature ID, sprint, screens touched, rubric row, branch.
3. **How it was tested:** unit tests, **physical device** (model + iOS version),
   simulator, and which states you verified (loading / empty / error / offline).
4. **AI-assistance disclosure:** which tools, for what, what you corrected, and which part
   was hand-written. Using AI is permitted; disclosing it is required.

| PR field | Requirement |
|---|---|
| **Title** | Conventional Commit style: `feat(F04): …` |
| **Base** | `develop` (or `main` for a hotfix) |
| **Reviewer** | the named **tester** for that feature (`docs/02 §7`) |
| **CI** | must build clean with **zero warnings** before merge |
| **Merge style** | regular merge or rebase-merge — **do not squash your per-file commits into one**, the per-file history is the point |

**Reviewer checklist** (from the PR template): builds clean · no secrets · no
`allow read, write: if true` in rules · loading/empty/error/offline handled · no
hard-coded user-facing strings (English **and** Arabic) · no AI call on the main thread ·
commit messages meaningful, one file per commit.

### 5.6 Resolving a conflict

Conflicts should be rare here (disjoint lanes, synchronized Xcode folders). When one
happens:

```bash
git fetch origin
git rebase origin/develop
#  git reports the conflicting files
#  open each one, keep BOTH sides' intent, remove the <<<<<<< ======= >>>>>>> markers
git add <resolved-file>
git rebase --continue
```

**Rules for a conflict:**
- If the conflicting file is **outside your lane**, stop and ask the person who owns it
  instead of resolving it yourself.
- If it is a **shared file** (`AppContainer.swift`, the two `.strings`), keep the change
  to the minimum and take both sides' additions.
- If you touched a `.strings` file, run `python3 tools/check-strings.py` afterwards.
- To abandon a rebase: `git rebase --abort` (you are back where you started, nothing lost).

---

## 6. Building, running and testing

All commands run from the repository root.

### 6.1 Build

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Expect `** BUILD SUCCEEDED **`. **Zero warnings** is the standard — a warning you added is
a review rejection.

### 6.2 Test

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Expect `Test run with 723 tests in 117 suites passed`. **Never commit a red build.** Your
change should *raise* that number, not just keep it green.

### 6.3 Run

```bash
bash tools/run-ios.sh                 # simulator
bash tools/run-device.sh              # physical iPhone (see §2.4)
bash tools/run-device.sh --list       # list paired devices
```

### 6.4 The repository's own safety nets

| Command | Checks | When to run |
|---|---|---|
| `bash tools/check-lane.sh M2` | branch protection + file lane | **before every commit and push** |
| `bash tools/check-lane.sh owner [--allow-protected]` | the same guard for M1's lane — the project level plus F01/F02/F14; `--allow-protected` adds `main`/`develop` and prints `OWNER BYPASS` | owner only, before an owner commit |
| `bash tools/todos.sh` | open in-code TODOs by owner | after finishing a TODO |
| `python3 tools/check-strings.py` | English/Arabic key parity (910 keys × 2) | after touching any `.strings` |
| `python3 tools/verify-docs.py` | doc links, screen inventory, ownership integrity | after touching `docs/` |
| `bash tools/check-tokens.sh` | Figma ↔ SwiftUI token parity | ⚠️ **currently a stub** — it prints a TODO and does not actually check. Do not rely on it (`docs/TODOLIST.md` §9). |

---

## 7. Code conventions

### 7.1 Read before you write — this codebase explains itself

Every non-obvious file opens with a comment block explaining **why it exists**, not what it
does. Before adding a file:

1. **Read three neighbouring files** in the same folder.
2. Match their structure: header comment → types → extension order → MARK sections.
3. Follow the language mode: **Swift 6, strict concurrency**. New types are `Sendable`;
   view models are `@MainActor`.

> **Never make an AI call on the main thread.** It is on the reviewer checklist.

### 7.2 Dependencies are injected through `AppContainer`

`App/AppContainer.swift` is the single composition root. Screens receive their stores and
services from it, so every screen can be previewed and tested with in-memory doubles.

The pattern used everywhere in this codebase:

```swift
// the seam
protocol BookmarkStore: Sendable {
    func all() async throws -> [BookmarkCollection]
    func add(_ collection: BookmarkCollection) async throws
}

// a real implementation, and an in-memory double for previews and tests
struct FileBookmarkStore: BookmarkStore { … }
final class InMemoryBookmarkStore: BookmarkStore { … }
```

**Add a new conforming type; do not change the protocol.** Protocol changes ripple into
every conformer and caller — `BookmarkStore` alone is referenced by 17 files.

### 7.3 Design system — never raw values

`ios/StudyForge/StudyForge/DesignSystem/` is the single source of truth, kept in sync with
the Figma file (`docs/06-DESIGN-SYSTEM.md`).

| Token group | Use | Never |
|---|---|---|
| `ColorTokens.primary`, `.surface`, `.textPrimary`, … | every colour | a raw `Color(red:…)` or hex literal |
| `Spacing.s1` … `s12` (4 pt grid) | every gap and padding | `padding(13)` |
| `Radius.s / m / l / xl / full` | every corner | `cornerRadius: 11` |
| `Layout.screenMargin`, `.maxContentWidth`, `.minTouchTarget` (44) | screen layout | a hard-coded 44 |
| `Motion.*` | every animation — **respects Reduce Motion** | a bare `.animation(.easeIn)` |

Prebuilt components live in `DesignSystem/Components/` — **use them instead of rolling your
own**: `SFPrimaryButton`, `SFTextField`, `SFPasswordField`, `SFPasswordStrengthMeter`,
`SFChoiceChip`, `SFChipFlow`, `SFRadioCard`, `SFSegmentedField`, `SFSlider`, `SFDetailRow`,
`SFErrorBanner`, `SFOfflineBanner`, `SFPageDots`, `SFMonogram`, `SFRadarChart`,
`SFPipelineDiagram`, `SFFieldStyle`.

**Accessibility is part of the definition of done:** 44 pt minimum targets, Dynamic Type to
AX5, VoiceOver labels on every control, contrast that clears WCAG AA. Prove it, do not
claim it — there are built Figma frames for large text (`138`) and Arabic RTL (`139`).

### 7.4 Localisation — no hard-coded user-facing strings

The app ships **English and Arabic**. Every visible string goes through the typed `L10n`
enum:

```swift
// ✅
Text(L10n.authLoginTitle.string)

// ❌ renders the literal key on screen, and nothing fails
Text(NSLocalizedString("auth.login.titel", comment: ""))
// ❌
Text("Log in")
```

**Adding a string means three edits, in one commit each:**

1. a case in `Core/Localisation/L10n.swift`
2. the English entry in `Resources/en.lproj/Localizable.strings`
3. the Arabic entry in `Resources/ar.lproj/Localizable.strings`

Then run `python3 tools/check-strings.py` — it fails on a missing key, an extra key, a
duplicate, a placeholder mismatch (`%d` vs `%@` is a runtime crash), or an empty value.
`L10nTests` additionally asserts every enum case resolves to a real translation.

> The two `.strings` files are **shared**. Keep the edit minimal and rebase before pushing.

### 7.5 House style, in one table

| Rule | Because |
|---|---|
| Comments explain **why**, never restate the code | The code already says what |
| No `try!`, no force-unwrap in production paths | A crash is a failed demo |
| Errors map to the app's own `AppError` vocabulary | One user-facing error language |
| Handle **loading · empty · error · offline** on every screen | On the reviewer checklist, and in the prototype |
| No randomness in schedulers, scoring or simulation | They must be deterministic for tests |
| If it needs "now", **inject** the clock | Tests pin a date instead of racing one |
| Prefer a default-valued parameter over editing `AppContainer` | Keeps the shared file out of your diff |

---

## 8. Testing

### 8.1 The framework is Swift Testing, not XCTest

New tests use `@Suite` and `@Test`. Follow the existing suites — do not introduce XCTest.

```swift
import Testing
@testable import StudyForge

@Suite("Flashcard review (F04)")
@MainActor
struct FlashcardReviewViewModelTests {

    @Test("A Hard grade increments hardCount but not correctCount")
    func hardGradeIsTrackedSeparately() async {
        let model = makeModel()
        await model.rate(.hard)
        #expect(model.hardCount == 1)
        #expect(model.correctCount == 0)
    }
}
```

### 8.2 What a good test looks like here

| Rule | Why |
|---|---|
| **The test must fail without your change.** Run it before and after. | Otherwise it proves nothing |
| Test the **seam**, not the view | View models and services, with in-memory doubles |
| Use `InMemory…` doubles already in the codebase (`InMemoryBookmarkStore`, `InMemoryStudyPlanStore`, `InMemoryGroupStore`, `InMemoryNotificationStore`, `MockProvider`, …) | Fast, deterministic, no Firebase needed |
| **Pin the clock** — never assert on `Date.now` | Otherwise it flakes at midnight |
| **No randomness** in schedulers or simulation | They are deterministic by design so tests can assert |
| Cover the **edge case**, not just the happy path | A lapse case, an empty store, a failed write |
| One clear assertion per `@Test` where possible | A failing name tells you what broke |

### 8.3 Do not weaken existing tests

If a test now looks wrong, **explain why before changing it**. Deleting or loosening a test
to make your change pass is the fastest way to lose the VIVA.

### 8.4 Independent testing (the rotation)

You are the **primary tester** for four features you did not build (see §3.1). That is not
a formality — it is how the whole team gets to understand the whole app, which the brief
requires.

Write a log per feature in `research/testing/`, named `<Fxx>-<yourname>.md`:

```markdown
# Test log — F06 Study Plan (tester: Mohammed Almadhoon, M2)

| | |
|---|---|
| Build | `main` @ a1b2c3d |
| Device | iPhone 15, iOS 26.5 |
| Date | 12 Oct 2026 |

## Cases
| # | Steps | Expected | Observed | Result |
|---|---|---|---|---|
| 1 | Wizard 1 → 4, Generate | Week calendar fills | Filled, 12 sessions | PASS |
| 2 | Delete availability for one day | Sessions re-planned | No session on that day | PASS |
| 3 | Set an exam date, regenerate | No session after the exam | One session scheduled ON the exam day | **FAIL** → bug D-07 |
| 4 | Airplane mode, open calendar | Cached plan + offline banner | Plan shown, no banner | **FAIL** → bug D-08 |

## Defects raised
- **D-07** planner can schedule a session on the exam date itself.
- **D-08** offline banner missing on the calendar.
```

A real defect reported beats a clean pass, but **never invent one**.

---

## 9. Your evidence — this is what is actually marked

The **Sprints component (10%) is read off evidence a marker can open.** Only these count
(`docs/10-SPRINT-PLAN.md` §5):

| # | Evidence | Where it lives |
|---|---|---|
| 1 | **Authored commits and PRs** on features you own | `git log --author`, the PR list |
| 2 | **Sprint review demo** of your own work | `research/sprints/sprint-N/` |
| 3 | **Review notes on AI-generated code** — what was wrong, what you changed and why | `research/reviews/` |
| 4 | **Test logs** for the features you test | `research/testing/` |
| 5 | Design and decision documents you authored | `docs/` history, decision log |
| 6 | Issue-board items you closed, with linked PRs | GitHub Issues |
| 7 | Figma frames named with your own student ID | the Figma file |
| 8 | **Hand-written code** on the parts that matter | commits you authored directly |

**Deliberately excluded:** prompting alone · reformatting-only commits · a single
end-of-sprint commit dump · meeting attendance without an artefact · work you cannot demo
or explain.

### 9.1 Your contribution log — fill it in *within 24 hours*

`research/sprints/sprint-<N>/<yourname>-contribution.md` (sprint-1 files already exist as
templates):

| Date | Feature | What I personally did | Evidence | Hours | Blocker |
|---|---|---|---|---|---|
| 07 Oct | F04 | Wrote the SM-2 spec; reviewed the AI's interval maths and fixed the lapse case | commit `a1b2c3d` | 4 | none |
| 09 Oct | F04 | Tested 6 card states; found 2 scheduler bugs | `research/testing/F04-mohammed.md` | 2 | needs a rule for Hard |

**Rules:** log within 24 h · one row per work session · always link evidence · **never
back-fill a whole sprint at once** — it reads as fabricated and defeats the point.

### 9.2 Reviewing your own evidence before each sprint review

```bash
# everything I committed this sprint
git log --oneline --author="<my name>" --since="2 weeks ago"

# changes I made myself, not AI-generated (doc 10 §9 rule 4)
git log --oneline --author="<my name>" --grep="hand:"

# my PRs
gh pr list --author="@me" --state all

# did I ever accidentally stage a secret?
git log --all --name-only --pretty=format: | sort -u | grep -Ei 'plist$|\.env|secret|key\.'
```

If the first command returns a thin list, that sprint's individual mark is thin.

---

## 10. Sprint cadence

Work is organised as **five two-week sprints plus S0**. The Design Document deadline (22
Oct) falls inside S2 and the Prototype deadline (12 Nov) inside S3 — both are fixed
constraints *inside* a sprint, never reasons to pause app work.

| Sprint | Dates | Theme | Fixed constraint inside |
|---|---|---|---|
| **S0** | 28 Sep – 4 Oct | Foundation & requirements | — |
| **S1** | 5 – 18 Oct | Core loop MVP | — |
| **S2** | 19 Oct – 1 Nov | Assessment engine | 🚩 **Design Document 22 Oct** |
| **S3** | 2 – 15 Nov | Collaboration & monetisation | 🚩 **Prototype 12 Nov** |
| **S4** | 16 – 29 Nov | Intelligence & polish | — |
| **S5** | 30 Nov – 13 Dec | Hardening & VIVA | ⛔ **Feature freeze 30 Nov** |

### 10.1 The weekly rhythm

| Ceremony | When | Duration | Output |
|---|---|---|---|
| **Sprint planning** | Monday, sprint start | 45 min | Sprint goal + task board with per-member assignments |
| **Async stand-up** | Every weekday | 5 min | Three lines in the team channel: **done · doing · blocked** |
| **Mid-sprint check** | Thursday | 20 min | Unblock, re-scope, protect the sprint goal |
| **Sprint review & demo** | Final Sunday | 60 min | **Every member demos their own work.** Recorded. |
| **Retrospective** | After the review | 30 min | One thing to keep, one thing to change |

**Commit to `research/sprints/sprint-<N>/`:** `goal.md` · `board.png` · `review.mp4` (or
screenshots) · `retro.md` · each member's contribution log.

### 10.2 The comprehension contract

Using AI to write code is **permitted**. The remaining risk is that AI writes code nobody
reads, and then a marker in the VIVA says *"open your feature's view model and explain this
function"* — and "the AI wrote it" fails a must-pass component.

| # | Rule | Enforced by |
|---|---|---|
| 1 | **Disclose AI use on every PR** — which tool, for what | PR template |
| 2 | **Read and review every generated line before committing.** Record what you corrected | `research/reviews/` |
| 3 | **No PR is merged for code you cannot explain** — every PR carries a 3-sentence plain-English explanation | PR template |
| 4 | **Change something yourself each sprint** — a label, a bug, a layout, a validation rule | commit tagged `hand:` |
| 5 | **Weekly "explain it" drill (15 min)** — open *another* member's feature and explain it from the code, unprompted | rotation, logged |
| 6 | **Record a 2-minute walkthrough of your own feature** each sprint | `research/sprints/sprint-N/` |
| 7 | **Keep a one-page cheat sheet:** purpose · key files · data touched · hard parts · limitations | `research/cheatsheets/<name>.md` |
| 8 | **Be able to name the trade-offs** — what you chose, what you rejected, why | cheat sheet + rehearsal |

> Rules 7 and 8 matter most. In the VIVA, "explain any part of the app" is really testing
> whether you know **where things live and why**. A cheat sheet turns that from a risk into
> an advantage.

---

## 11. Definition of done

### 11.1 Your change is done when

```
[ ] A written plan was produced BEFORE any code was written
[ ] Every changed file was committed SEPARATELY, with a Conventional Commit message
[ ] `bash tools/check-lane.sh M<you>` exits 0
[ ] Nothing was ever committed to main or develop
[ ] The branch is pushed, with a PR into develop
[ ] `xcodebuild build` succeeds with ZERO warnings
[ ] The full unit suite passes (was 723 tests, 117 suites — yours should raise it)
[ ] New tests exist for the new behaviour, and they FAIL without the change
[ ] Loading, empty, error and offline states handled
[ ] No hard-coded user-facing strings; English AND Arabic both updated
[ ] `python3 tools/check-strings.py` passes (if a .strings file changed)
[ ] Accessibility: 44 pt targets, Dynamic Type, VoiceOver labels, AA contrast
[ ] The PR template is filled in, including AI disclosure and the 3-sentence explanation
[ ] The tested-on-a-physical-device box is real, not wishful
[ ] You can explain every line out loud
```

### 11.2 The sprint is done when

- [ ] The sprint's demoable outcome actually demos, live, from the real app
- [ ] Every member demonstrated something they personally built or fixed
- [ ] Every member's contribution log is written and evidence-linked
- [ ] Slipped scope is explicitly recorded and re-planned (not silently dropped)
- [ ] The app builds clean on `main` with **zero warnings** and tests passing
- [ ] Sprint artefacts committed to `research/sprints/sprint-<N>/`

---

## 12. Anti-patterns — the things that cost marks

| Anti-pattern | Why it hurts | Do this instead |
|---|---|---|
| Committing straight to `main` | Breaks the demo line, no review evidence — **and it is rejected anyway** | Branch from `develop`, PR back |
| One giant commit at the end of a sprint | Reads as fabricated; destroys granularity | Commit per file as you finish each file |
| `git commit -am "updates"` | Bundles unrelated files with a useless message | Stage and commit one file at a time |
| **A commit per file with no meaningful message** | Technically split, still useless | Name the file's role in the scope and subject |
| Committing generated code you have never read | Fails the VIVA, not the commit | Review it, then commit it, and note what you changed |
| Long-lived branches (weeks) | Painful merges, stale code | Keep branches to a few days; rebase on `develop` daily |
| Force-pushing a shared branch | Destroys others' work and history | Revert instead |
| Committing `GoogleService-Info.plist` | Secret leak; must be rotated | It is gitignored — check `git status` before staging |
| Editing outside your lane | Merge conflicts with the other two agents | `bash tools/check-lane.sh M<you>` before every commit |
| Hand-editing `project.pbxproj` | Unnecessary here, and a guaranteed conflict | Add new files to the folder; Xcode syncs automatically |
| Changing a protocol to add a feature | Ripples into every conformer and caller | Add a new conforming type behind the existing seam |
| Adding a raw colour or `padding(13)` | Design-system drift between Figma and the app | Use `ColorTokens`, `Spacing`, `Radius` |
| Hard-coding a user-facing string | Ships the literal key in Arabic, silently | Add to `L10n` + both `.strings` |
| Deleting a failing test to go green | The fastest way to lose the VIVA | Explain why the test looks wrong first |
| Randomness to make a demo livelier | Breaks the tests and reproducibility **by design** | Keep schedulers and simulations deterministic |
| Building only at the end | A red build discovered at submission time | Build and test before each commit |
| Reporting a defect you did not actually see | Fabrication; it surfaces at the review | Report what you observed, and say when you were unsure |

---

## 13. Troubleshooting

### Git

**"remote: error: GH006: Protected branch update failed"**
You are trying to push to `main` or `develop`, and you are a member account. The pull-request
requirement is working as designed: branch and open a PR instead. The repository owner is the
only exempt account, and only for a hotfix.
```bash
git switch -c feat/Fxx-your-slug          # branch from where you are
git push -u origin feat/Fxx-your-slug
# then reset develop to match origin, if you had local commits on it:
git switch develop && git reset --hard origin/develop
```

**I committed to `develop` by accident, but have not pushed.**
```bash
git switch -c feat/Fxx-your-slug           # move the commit onto a branch
git switch develop && git reset --hard origin/develop
```

**My push is rejected after a teammate merged.** Expected — `AppContainer` and the
`.strings` files are shared. Rebase, then push again:
```bash
git fetch origin && git rebase origin/develop
bash tools/check-lane.sh M<you>
git push
```
Never force-push to resolve this.

**`check-lane.sh` says OUT OF LANE.**
A file outside your lane changed. Look at the path:
```bash
git checkout -- <file>            # discard an accidental edit
git restore --staged <file>       # unstage it, keep the change on disk
git diff --name-only origin/develop
```
If the change is genuinely needed, **ask the owner** — do not force it through.

**`check-lane.sh` says SHARED.** Not an error. Rebase first, keep the edit to 1–2 lines,
re-run the check, then push.

**I committed a secret.**
```bash
# it is in the last commit and not pushed
git rm --cached <file> && git commit --amend --no-edit
```
If it *was* pushed, tell M1 immediately — the credential must be **rotated**, not just
deleted, because it stays in the history.

### Build and run

**`xcodebuild: error: Unable to find a destination matching …`**
The simulator name does not exist on your machine.
```bash
xcrun simctl list devices available | grep iPhone
xcodebuild ... -destination 'platform=iOS Simulator,name=<a name from that list>' test
bash tools/run-ios.sh "<that name>"
```

**Nothing appears when I try to open the Simulator.**
Xcode 27 replaced `Simulator.app` with **Device Hub**:
```bash
open -a /Applications/Xcode.app/Contents/Applications/DeviceHub.app
```
Or use the **iOS: run on simulator** VS Code task, which boots it for you.

**`run-device.sh` fails on signing.**
```bash
ls tools/device.local.env        # must exist (copy from the .example)
cat tools/device.local.env       # both DEVICE_BUNDLE_ID and DEVICE_TEAM filled in
```
`DEVICE_TEAM` is your 10-character team ID: Xcode → Settings → Accounts → your team.

**The build suddenly fails with something unrelated to my change.**
```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge clean
rm -rf ~/Library/Developer/Xcode/DerivedData/StudyForge-*
```
Then rebuild. If it still fails, check whether `develop` is green — if it is not, that is a
team stop-the-line problem, not yours.

### Localisation and docs

**`check-strings.py` fails.** It names the key, the file and the reason (missing / extra /
duplicate / placeholder mismatch / empty). Add the key to **both** `.strings` files *and*
the `L10n` enum. A `%d` versus `%@` mismatch is a runtime crash, not a typo.

**`verify-docs.py` fails.** It prints the file and the link that does not resolve. Fix the
relative path or create the file — do not delete the link.

**`check-tokens.sh` prints "TODO: implement…".** That is correct. It is a known stub and
does not actually check anything yet (`docs/TODOLIST.md` §9). Verify tokens by eye against
`docs/06-DESIGN-SYSTEM.md` instead.

### Tests

**A test is flaky.** Almost always a clock or a random value. Inject the date, or seed the
generator — both are required by design in this codebase.

**I think I need Firebase for a test.** You should not. Use the `InMemory…` doubles. If a
test genuinely needs Firestore, raise it with M1 as a design question.

---

## 14. VIVA readiness

The brief requires that *each student can present and explain any part of the app*, and the
60% component is gated on it. Prepare deliberately, starting now — not in S5.

### 14.1 The five habits

| # | Habit | When |
|---|---|---|
| 1 | **Cheat sheet** per member: purpose · key files · data touched · hard parts · limitations | keep current from S2 |
| 2 | **"Explain it" drill** — open a teammate's file, explain it unprompted | weekly, 15 min |
| 3 | **Rotated presentation** — demo a feature you did *not* build | S3, S4, S5 reviews |
| 4 | **Code walkthrough** of your own feature, file by file, with the team | S5 |
| 5 | **Adversarial Q&A** — the team invents the hardest questions and asks each other | S5 |

### 14.2 The question types to be ready for

| Level | Example | Where the answer lives |
|---|---|---|
| **Product** | "Why did you build it this way?" | the decision log, `docs/09` §2 |
| **Architecture** | "Why Firebase? Why on-device AI? How does the router decide?" | `docs/04` |
| **Code** | "Open your view model. What does this function do? What if it fails?" | **your own feature — rehearsed** |
| **Failure** | "What happens with no internet? If the AI returns nonsense? If the payment webhook never arrives?" | `docs/09` §5 |
| **Honesty** | "What doesn't work?" | **always have a real answer** |

> **On the honesty question.** Naming a genuine limitation, with its cause and its plan,
> reads as engineering maturity. Claiming perfection and then failing the follow-up does
> not. This is the same principle behind correcting a `figma-link.txt` that had claimed
> prototype links which did not exist.

### 14.3 The traceability one-pager

Every member carries one page mapping **feature → screens → source files → Firestore
collections → who built it → who tested it**. It mirrors
`docs/02-FEATURE-LIST-OWNERSHIP.md` §8 and answers "where does that live?" instantly. The
marker may pick any feature — you should find it in under ten seconds.

---

## 15. Quick reference

```bash
# ── start of a session ────────────────────────────────────────────────
git switch develop && git pull
bash tools/new-branch.sh feat/Fxx-your-slug

# ── before every commit ───────────────────────────────────────────────
bash tools/check-lane.sh M2                      # M2 | M3 | M4

# ── commit ONE FILE ───────────────────────────────────────────────────
bash tools/commit.sh <path> "feat(Fxx): what changed and why"
bash tools/commit.sh --push <path> "test(Fxx): what it now covers"
bash tools/commit.sh --push --multi <p1> "<m1>" <p2> "<m2>"

# ── build and test ────────────────────────────────────────────────────
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# ── run it ────────────────────────────────────────────────────────────
bash tools/run-ios.sh
bash tools/run-device.sh

# ── the safety nets ───────────────────────────────────────────────────
bash tools/check-lane.sh M2
bash tools/todos.sh
python3 tools/check-strings.py
python3 tools/verify-docs.py

# ── open a PR ─────────────────────────────────────────────────────────
gh pr create --base develop --title "feat(Fxx): ..." \
  --body-file .github/PULL_REQUEST_TEMPLATE.md

# ── my evidence ───────────────────────────────────────────────────────
git log --oneline --author="$(git config user.name)"
git shortlog -sne --all

# ── keep my branch current ────────────────────────────────────────────
git fetch origin && git rebase origin/develop
```

| I need… | Read |
|---|---|
| my tasks and open TODOs | `docs/TODO-M2-mohammed.md` · `TODO-M3-tasbeeh.md` · `TODO-M4-shahad.md` |
| the git contract | `docs/12-GIT-WORKFLOW.md` |
| who owns and tests what | `docs/02-FEATURE-LIST-OWNERSHIP.md` |
| my lane and the guard | `docs/14-COLLEAGUE-AI-AGENT-PROMPTS.md` |
| the design system | `docs/06-DESIGN-SYSTEM.md` |
| architecture and cost | `docs/04-TECH-ARCHITECTURE-COST.md` |
| data model and security rules | `docs/05-DATA-MODEL-SECURITY.md` |
| what is still open | `docs/TODOLIST.md` |
| the VIVA plan | `docs/11-APP-IMPLEMENTATION-VIVA.md` |
| what the marker actually checks | `docs/08-RUBRIC-COVERAGE-MATRIX.md` |
| the product overview | `README.md` |

**And the one sentence that decides your individual mark:**

> *A strong teammate does not raise your Sprints mark. Your own attributable, timestamped
> evidence is the only thing that counts, and it has to exist before the sprint review,
> not be assembled after it.*










