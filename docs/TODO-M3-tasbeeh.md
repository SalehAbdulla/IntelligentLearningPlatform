# TODO — Tasbeeh Saeed · M3 · `202300549`

> **Hand this entire file to your AI coding agent.** It is self-contained: identity,
> the rules, your features, your open TODOs, the git protocol, and the definition of
> done. Created 8 Oct 2026.
>
> Companion reading (the agent should open these): [doc 12](12-GIT-WORKFLOW.md) for the
> git contract, [doc 13](13-PER-MEMBER-TASKS.md) for the starter briefs,
> [doc 02](02-FEATURE-LIST-OWNERSHIP.md) §2 and §7 for ownership and the test rotation,
> and **[CONTRIBUTING.md](../CONTRIBUTING.md)** for the full guide: setup, conventions,
> testing, evidence, troubleshooting and VIVA readiness.

---

## 0. THE TWO RULES THAT KEEP US OUT OF CONFLICT — read this before anything

Three members will run AI agents against this repository **at the same time**. Two
things must never happen, because both cost the team marks and hours:

1. **Working on `main` or `develop`.** Both are protected with `enforce_admins`, so a
   direct push is *rejected by GitHub*. Work on a branch of your own, always.
2. **Editing a file that belongs to someone else.** That is what produces merge
   conflicts. Your lane below is exact, and there is a script that enforces it.

### Rule 1 — your own branch, and only four branch names

One branch **per feature**, branched from `develop`. Only these patterns are yours:

```
feat/F06-<slug>    feat/F07-<slug>    feat/F13-<slug>    feat/F15-<slug>
```

```bash
bash tools/new-branch.sh feat/F06-exam-dates
bash tools/new-branch.sh feat/F07-student-home
```

Never `git switch develop` to "just quickly fix something". Never `git push origin main`.

### Rule 2 — your own files

**You may modify these** (and nothing else):

| Area | Files |
|---|---|
| F06 planning | `Core/Planning/StudyPlan.swift` · `StudyPlanner.swift` · `StudyPlanStore.swift` · `FileStudyPlanStore.swift` · `InMemoryStudyPlanStore.swift` |
| F06/F07 wizard + progress | `Features/StudyPlan/StudyPlanWizardView.swift` · `StudyPlanWizardViewModel.swift` · `StudyPlanViewModel.swift` · `StudySessionDetailView.swift` · `Features/Progress/ProgressDashboardView.swift` |
| F07 home | `Features/Home/SignedInHomeView.swift` |
| F07 tutor metrics | `Core/Tutor/CohortSnapshot.swift` |
| F13 payments | everything under `Core/Payments/` and `Features/Subscription/` |
| Tests | `StudyForgeTests/StudyPlannerTests.swift` · `NotificationViewModelTests.swift` · `CohortSnapshotTests.swift` |

**You may add NEW files** inside: `Core/Planning/` · `Core/Payments/` ·
`Features/StudyPlan/` · `Features/Progress/` · `Features/Subscription/` ·
`StudyForgeTests/`

**SHARED — allowed, but follow the protocol** (see below):
`App/AppContainer.swift` · `Resources/en.lproj/Localizable.strings` ·
`Resources/ar.lproj/Localizable.strings`

**OFF LIMITS, no exceptions:**

| Path | Owner |
|---|---|
| `Core/AI/`, `Features/Flashcards/`, `Features/Summaries/`, `Features/Quizzes/`, `Features/Tutor/` | Mohammed (M2) |
| `Core/Groups/`, `Core/Bookmarks/`, `Core/Folders/`, `Features/Groups/`, `Features/Bookmarks/`, `Features/Admin/` | Shahad (M4) |
| `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`, `README.md`, `.mailmap` | Saleh (M1) |
| `ios/StudyForge/StudyForge.xcodeproj/` | nobody, ever |

### Why there is almost no conflict here (know this, so you don't fight it)

The Xcode project uses **`PBXFileSystemSynchronizedRootGroup`** for both `StudyForge`
and `StudyForgeTests`. That means **Xcode syncs the folder automatically, so adding a
new `.swift` file does NOT require editing `project.pbxproj`** — normally the single
worst conflict source in an Xcode repository, and here it is simply gone.

> **So: create new Swift files directly in the folder (or from the terminal). Do NOT use
> Xcode's File → "Add Files…" dialog, and never hand-edit `project.pbxproj`.**

### The guard — run this before every commit and every push

```bash
bash tools/check-lane.sh M3
```

It refuses if you are on `main`/`develop`, lists every file your branch is about to
change, and tells you whether each one is **yours**, **new (yours)**, **SHARED**, or
**OUT OF LANE / FORBIDDEN**. Exit 1 means stop and fix it.

### The SHARED-file protocol

Only three files are shared. Keep any change to them **1–2 lines**, and before pushing:

```bash
git fetch origin && git rebase origin/develop   # always rebase before you push
bash tools/check-lane.sh M3                     # re-check
python3 tools/check-strings.py                  # only if a .strings file changed
```

If the push is rejected, rebase again. **Never force-push.**

---

## 1. Who you are (the agent must do this first)

```bash
git config --local user.name  "Tasbeeh Saeed"
git config --local user.email "202300549@student.polytechnic.bh"
```

Every commit must be attributable to me. My **Sprints mark is 10% and assessed per
person**, and the **VIVA is 60% and must pass**, so I have to be able to explain every
line I claim. Then read: `docs/12-GIT-WORKFLOW.md`, `docs/13-PER-MEMBER-TASKS.md`
(my section + the starter briefs), `docs/02-FEATURE-LIST-OWNERSHIP.md` §2 and §7, and
`research/sprints/sprint-1/goal.md` (my row is **S1-M3**).

---

## 2. My features — **at least two of them must ship**

| ID | Feature |
|---|---|
| **F06** | Study Plan & Adaptive Re-planning — *my lead feature* |
| **F07** | Progress Tracking |
| **F13** | Subscription & Payments (Tap Payments) |
| **F15** | AI Study Companion *advanced feature, co-owned with Mohammed (M2)* |

> **HARD ACCEPTANCE CRITERION.** By the end, **at least TWO** of the features above must
> carry a real, tested, committed change authored under my git identity. Touching only
> one feature does **not** satisfy the rubric. If only one is achieved, the agent must
> say so plainly rather than claiming otherwise.

Recommended pair: **F06 + F07**, because they carry two of my three open TODOs and they
are the planner work I am expected to own.

---

## 3. My open TODOs (confirm with `bash tools/todos.sh`)

**F06 — per-course exam dates that feed the planner**
`ios/StudyForge/StudyForge/Core/Planning/StudyPlan.swift:100`
Exam dates belong on the **plan**, not the profile, so a date cannot go stale
(docs/09 Q11).
Files: `Core/Planning/StudyPlan.swift` (the model) · `Core/Planning/StudyPlanner.swift`
(the scheduler, which should weight a near exam harder) ·
`Features/StudyPlan/StudyPlanWizardView.swift` (wizard step 3 of 4, which already draws
a "+ Add deadline" control).
*Done when:* dates can be entered and stored on the plan, the planner avoids scheduling
after them, and a test covers a plan that respects one.

**F07 — the real student home (B05)**
`ios/StudyForge/StudyForge/Features/Home/SignedInHomeView.swift:148`
Replace the placeholder with the designed home: greeting, today's plan, streak, and the
quick-action tiles — then retire the ad-hoc library and profile links that exist only
because the real home does not.
The Figma reference is `15_Home_Dashboard_Student` and `69_Progress_Dashboard` in
`deliverables/prototype/figma-link.txt` (read it, do not edit it).
*Done when:* the designed home exists and this file no longer explains itself as a
placeholder.

**F14 — a test-only task, not one of my features**
`ios/StudyForge/StudyForgeTests/NotificationViewModelTests.swift:11`
F14 belongs to M1 and **I am its primary tester**. Add a test that quiet hours suppress
a scheduled reminder, and that a reminder outside quiet hours is delivered.

Each TODO comment already states its own *"Done when"*. Treat that as the acceptance
test, and **delete the TODO marker** once it is met — in its own commit.

**Blast-radius warning.** `StudyPlanner` is also referenced by
`Features/StudyPlan/StudyPlanViewModel.swift`, `StudyPlanWizardViewModel.swift` and
`Core/Tutor/CohortSnapshot.swift`. All are in my lane, but prefer **additive** changes
(an optional parameter, a new field with a default) over changing an existing signature,
so those callers keep compiling untouched.

**Optional third feature, F13.** Tap Payments: paywall, BHD order summary with 10% VAT,
method select, card entry, processing, receipt, and the failed-retry path. Files under
`Core/Payments/` and `Features/Subscription/` are in my lane, and I may add new files
there. **Ask before starting it** — it has an external dependency (a Tap sandbox account,
docs/09 R22).

**Planner determinism — non-negotiable.** `StudyPlanner` already has passing tests. NO
unseeded randomness, and NO reading the machine's clock inside the scheduling maths. If
the planner needs "now", it must be **injectable** so a test can pin it. Write the test at
a fixed date first, then make it pass.

---

## 4. Make a solid plan FIRST, then continue implementing

Before changing a single file, produce a written plan and show it to me. Per feature:

- the feature ID, the files you will touch, and the seam you will use
- the exact test that proves it works (file name and test name)
- the exact commit sequence — **one row per file, with the real commit message**
- what could break, and how you will know

Then **continue implementing** without waiting for further approval, unless something is
genuinely ambiguous. Do not start coding before the plan exists.

---

## 5. Branch, one commit per file, push when the task is done

```bash
# 1. one branch per feature, from develop
bash tools/new-branch.sh feat/F06-exam-dates
bash tools/new-branch.sh feat/F07-student-home

# 2. check your lane
bash tools/check-lane.sh M3

# 3. ONE COMMIT PER FILE — never batch unrelated files together
bash tools/commit.sh <path> "feat(F06): store per-course exam dates on the plan"

# 4. push when the task is complete, and keep pushing as you go
bash tools/commit.sh --push <path> "test(F06): prove the planner respects an exam date"

# ...or several files with their own messages, then push, in one command
bash tools/commit.sh --push --multi \
  <p1> "feat(F06): add examDates to StudyPlanInput" \
  <p2> "feat(F06): weight near exams harder in the scheduler" \
  <p3> "test(F06): cover a plan that respects an exam date"
```

Rules that are enforced, not advisory:

- `tools/commit.sh` **refuses** to commit on `main`/`develop`, refuses a non-Conventional
  message, and rejects "update"/"fix stuff" style messages.
- Scope every message with the feature ID: `feat(F06): …`, `test(F14): …`.
- Never commit secrets: `GoogleService-Info.plist`, keys, `.env`, `*.xcconfig.local`.
- Never rewrite pushed history. No force-push.

---

## 6. Verify before claiming anything is done

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The whole suite must pass — it is **723 tests today**, and my change should raise that
number. Then:

```bash
bash tools/check-lane.sh M3      # lane still clean
bash tools/todos.sh              # my open count went DOWN
bash tools/run-ios.sh            # see the planner actually running
```

Never commit a red build. If the build or a test fails, fix it first.

---

## 7. My evidence — this is 10% of my mark, per person

| Artefact | What goes in it |
|---|---|
| `research/sprints/sprint-1/tasbeeh-contribution.md` | one row per work session, with the commit hash. Fill it in for what I actually did. **Never back-fill a whole sprint in one go**, and never claim more than the commits show |
| `research/testing/F02-*.md`, `F08-*.md`, `F10-*.md`, `F14-*.md` | test logs. **I am the primary tester for F02, F08, F10 and F14** — nobody tests a feature they developed. Record what I ran, the exact steps, the observed result, any defect found, and whether it is fixed. Finding a real defect beats a clean pass, but never invent one |
| `research/reviews/*` | notes on the AI-generated code I reviewed and corrected |
| `research/cheatsheets/tasbeeh.md` | keep the quick-reference current for my features |

`research/testing/` and `research/reviews/` do not exist yet — create them (they are in
my lane; name files distinctly, e.g. `F02-tasbeeh.md`, so nobody collides).

---

## 8. Rules of engagement

- **Stay in my lane** (§0). `Core/Planning/`, `Core/Payments/`, `Features/StudyPlan/`,
  `Features/Progress/`, `Features/Subscription/`, `Features/Home/SignedInHomeView.swift`,
  `Core/Tutor/CohortSnapshot.swift`, plus `research/`.
- **Do not edit `docs/`, `deliverables/`, `backend/`, `tools/`, or the `.xcodeproj`.**
  If a doc is wrong, say so rather than editing it.
- Match the existing code style: this codebase has heavy, deliberate comments explaining
  **why**. Read three neighbouring files before adding one.
- Tests use **Swift Testing** (`@Suite` / `@Test`), not XCTest. Follow the existing suites.
- Small, reviewable diffs. Do not refactor unrelated code.
- Do not weaken or delete an existing test to make a new one pass — especially the planner
  tests. If a test now looks wrong, explain why before changing it.
- No new third-party dependencies without asking.
- **Every line must be something I can explain out loud in the VIVA.** If you are about
  to write something I could not explain, stop and tell me instead.
- If you are blocked, say so plainly with the error, rather than working around it.

---

## 9. Definition of done — report against this checklist

```
[ ] A written plan was produced BEFORE any code was written
[ ] At least TWO of my features (F06 F07 F13 F15) have a real, tested, committed change
[ ] Every changed file was committed SEPARATELY with a Conventional Commit message
[ ] `bash tools/check-lane.sh M3` exits 0 on my branch
[ ] Nothing was ever committed to main or develop
[ ] Everything is pushed to a feat/Fxx-* branch
[ ] `xcodebuild build` succeeds and the full unit suite passes (was 723, now more)
[ ] New tests exist, and they FAIL without the change
[ ] The planner is still deterministic: no unseeded randomness, no hidden clock
[ ] The satisfied TODO markers were deleted, in their own commit
[ ] `bash tools/todos.sh` shows a lower open count for M3
[ ] My contribution log has a row per session, with commit hashes
[ ] Test logs exist for F02, F08, F10 and F14
[ ] I have told the team anything in this checklist that was NOT achieved
```


