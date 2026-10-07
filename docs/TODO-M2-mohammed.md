# TODO — Mohammed Almadhoon · M2 · `202401702`

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
feat/F03-<slug>    feat/F04-<slug>    feat/F05-<slug>
feat/F11-<slug>    feat/F15-<slug>
```

```bash
bash tools/new-branch.sh feat/F04-hard-grade-tracking
bash tools/new-branch.sh feat/F15-prompt-template-store
```

Never `git switch develop` to "just quickly fix something". Never `git push origin main`.

### Rule 2 — your own files

**You may modify these** (and nothing else):

| Area | Files |
|---|---|
| F15 AI | `Core/AI/PromptTemplates.swift` · `Core/AI/AITier.swift` · `Core/AI/AIRouter.swift` · `Core/AI/AIProvider.swift` · `Core/AI/OnDeviceProvider.swift` |
| F15 admin config | `Core/Admin/AIConfiguration.swift` |
| F04 / F03 / F05 flashcards | everything in `Features/Flashcards/` |
| Tests | `StudyForgeTests/AIRouterTests.swift` · `AIVocabularyTests.swift` · `FlashcardReviewViewModelTests.swift` · `FlashcardGenerateViewModelTests.swift` · `SummaryFlowViewModelTests.swift` |

**You may add NEW files** inside: `Core/AI/` · `Features/Flashcards/` ·
`Features/Summaries/` · `Features/Quizzes/` · `Features/Tutor/` · `StudyForgeTests/`

**SHARED — allowed, but follow the protocol** (see below):
`App/AppContainer.swift` · `Resources/en.lproj/Localizable.strings` ·
`Resources/ar.lproj/Localizable.strings`

**OFF LIMITS, no exceptions:**

| Path | Owner |
|---|---|
| `Core/Planning/`, `Features/StudyPlan/`, `Features/Home/`, `Features/Progress/` | Tasbeeh (M3) |
| `Core/Groups/`, `Core/Bookmarks/`, `Core/Folders/`, `Features/Groups/`, `Features/Bookmarks/`, `Features/Admin/` | Shahad (M4) |
| `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`, `README.md`, `.mailmap` | Saleh (M1) |
| `ios/StudyForge/StudyForge.xcodeproj/` | nobody, ever |

### Why there is almost no conflict here (know this, so you don't fight it)

The Xcode project uses **`PBXFileSystemSynchronizedRootGroup`** for both `StudyForge`
and `StudyForgeTests`. That means **Xcode syncs the folder automatically, so adding a
new `.swift` file does NOT require editing `project.pbxproj`** — which is normally the
single worst conflict source in an Xcode repository, and here it is simply gone.

> **So: create new Swift files directly in the folder (or from the terminal). Do NOT use
> Xcode's File → "Add Files…" dialog, and never hand-edit `project.pbxproj`.**

### The guard — run this before every commit and every push

```bash
bash tools/check-lane.sh M2
```

It refuses if you are on `main`/`develop`, lists every file your branch is about to
change, and tells you whether each one is **yours**, **new (yours)**, **SHARED**, or
**OUT OF LANE / FORBIDDEN**. Exit 1 means stop and fix it. Verified behaviour:

| Situation | Result |
|---|---|
| On `main` or `develop` | refused, exit 1 |
| Only your files changed | lane OK, exit 0 |
| A file from another member's area changed | STOP, exit 1 |
| A `docs/`, `deliverables/`, `tools/` or `backend/` file changed | STOP, exit 1 |
| A SHARED file changed | lane OK, plus the rebase protocol, exit 0 |

### The SHARED-file protocol

Only three files are shared. Keep any change to them **1–2 lines**, and before pushing:

```bash
git fetch origin && git rebase origin/develop   # always rebase before you push
bash tools/check-lane.sh M2                     # re-check
python3 tools/check-strings.py                  # only if a .strings file changed
```

If the push is rejected, rebase again. **Never force-push.**

---

## 1. Who you are (the agent must do this first)

```bash
git config --local user.name  "Mohammed Almadhoon"
git config --local user.email "202401702@student.polytechnic.bh"
```

Every commit must be attributable to me. My **Sprints mark is 10% and assessed per
person**, and the **VIVA is 60% and must pass**, so I have to be able to explain every
line I claim. Then read: `docs/12-GIT-WORKFLOW.md`, `docs/13-PER-MEMBER-TASKS.md`
(my section + the starter briefs), `docs/02-FEATURE-LIST-OWNERSHIP.md` §2 and §7, and
`research/sprints/sprint-1/goal.md` (my row is **S1-M2**).

---

## 2. My features — **at least two of them must ship**

| ID | Feature |
|---|---|
| **F03** | AI Summary & Notes |
| **F04** | Flashcards & Spaced Repetition |
| **F05** | Quiz Generation & Analytics |
| **F11** | Tutor Content Studio |
| **F15** | AI Study Companion *advanced feature, co-owned with Tasbeeh (M3)* |

> **HARD ACCEPTANCE CRITERION.** By the end, **at least TWO** of the features above must
> carry a real, tested, committed change authored under my git identity. Touching only
> one feature does **not** satisfy the rubric. If only one is achieved, the agent must
> say so plainly rather than claiming otherwise.

Recommended pair: **F04 + F15**, because they carry all three of my open TODOs.

---

## 3. My open TODOs (confirm with `bash tools/todos.sh`)

**F04 — track "Hard" separately from "correct"**
`ios/StudyForge/StudyForge/Features/Flashcards/FlashcardReviewViewModel.swift:119`
A "Hard" grade is an SM-2 *success*, but it is not the same as "Good"/"Easy", so the
session summary currently folds it into `correctCount`.
*Done when:* a `hardCount` is exposed, shown on the summary
(`Features/Flashcards/FlashcardReviewView.swift`), and a test asserts that "Hard"
increments `hardCount` and **not** `correctCount`.

**F15 — `PromptTemplateStore`**
`ios/StudyForge/StudyForge/Core/AI/PromptTemplates.swift:22`
Introduce a `PromptTemplateStore` protocol and a Firestore-backed implementation so
prompts can improve without an app release (docs/04 §4). Keep the static templates as
the default conformer.
*Done when:* the store is injected, a fake store can override a template in a test, and
the default output is unchanged.
*Prefer a default-valued init parameter* so `AppContainer` (a SHARED file) does not need
to change at all. That is one less conflict for the whole team.

**F15 — the planned tier engine**
`ios/StudyForge/StudyForge/Core/AI/AITier.swift:114`
Implement the engine behind the existing `AIProvider` seam (`Core/AI/AIRouter.swift`).
Until it exists, `.notImplemented` is the honest state.
*Done when:* the engine conforms to `AIProvider`, is registered for its tier, and a
router test proves it is chosen when it reports available.

Each TODO comment already states its own *"Done when"*. Treat that as the acceptance
test, and **delete the TODO marker** once it is met — in its own commit.

**Blast-radius warning.** `PromptTemplates` is also referenced by
`Core/AI/OnDeviceProvider.swift`, `Core/Admin/AIConfiguration.swift` and
`StudyForgeTests/SummaryFlowViewModelTests.swift`. Keep the existing static API
**backward compatible** so those callers do not have to change; all four files are in my
lane either way, but smaller diffs mean fewer conflicts.

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
bash tools/new-branch.sh feat/F04-hard-grade-tracking
bash tools/new-branch.sh feat/F15-prompt-template-store

# 2. check your lane
bash tools/check-lane.sh M2

# 3. ONE COMMIT PER FILE — never batch unrelated files together
bash tools/commit.sh <path> "feat(F04): expose hardCount in the session summary"

# 4. push when the task is complete, and keep pushing as you go
bash tools/commit.sh --push <path> "test(F04): assert Hard increments hardCount only"

# ...or several files with their own messages, then push, in one command
bash tools/commit.sh --push --multi \
  <p1> "feat(F04): expose hardCount" \
  <p2> "test(F04): cover the Hard grade" \
  <p3> "docs(F04): delete the satisfied TODO marker"
```

Rules that are enforced, not advisory:

- `tools/commit.sh` **refuses** to commit on `main`/`develop`, refuses a non-Conventional
  message, and rejects "update"/"fix stuff" style messages.
- Scope every message with the feature ID: `feat(F04): …`, `test(F15): …`.
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
bash tools/check-lane.sh M2      # lane still clean
bash tools/todos.sh              # my open count went DOWN
bash tools/run-ios.sh            # optional: see it running
```

Never commit a red build. If the build or a test fails, fix it first.

---

## 7. My evidence — this is 10% of my mark, per person

| Artefact | What goes in it |
|---|---|
| `research/sprints/sprint-1/mohammed-contribution.md` | one row per work session, with the commit hash. Fill it in for what I actually did. **Never back-fill a whole sprint in one go**, and never claim more than the commits show |
| `research/testing/F06-*.md`, `F12-*.md`, `F13-*.md` | test logs. **I am the primary tester for F06, F12 and F13** — nobody tests a feature they developed. Record what I ran, the exact steps, the observed result, any defect found, and whether it is fixed. Finding a real defect beats a clean pass, but never invent one |
| `research/reviews/*` | notes on the AI-generated code I reviewed and corrected |
| `research/cheatsheets/mohammed.md` | keep the quick-reference current for my features |

`research/testing/` and `research/reviews/` do not exist yet — create them (they are in
my lane; name files distinctly, e.g. `F06-mohammed.md`, so nobody collides).

---

## 8. Rules of engagement

- **Stay in my lane** (§0). `ios/` minus the other members' folders, plus `research/`.
- **Do not edit `docs/`, `deliverables/`, `backend/`, `tools/`, or the `.xcodeproj`.**
  If a doc is wrong, say so rather than editing it.
- Match the existing code style: this codebase has heavy, deliberate comments explaining
  **why**. Read three neighbouring files before adding one.
- Tests use **Swift Testing** (`@Suite` / `@Test`), not XCTest. Follow the existing suites.
- Small, reviewable diffs. Do not refactor unrelated code.
- Do not weaken or delete an existing test to make a new one pass. If a test now looks
  wrong, explain why before changing it.
- No new third-party dependencies without asking.
- **Every line must be something I can explain out loud in the VIVA.** If you are about
  to write something I could not explain, stop and tell me instead.
- If you are blocked, say so plainly with the error, rather than working around it.

---

## 9. Definition of done — report against this checklist

```
[ ] A written plan was produced BEFORE any code was written
[ ] At least TWO of my features (F03 F04 F05 F11 F15) have a real, tested, committed change
[ ] Every changed file was committed SEPARATELY with a Conventional Commit message
[ ] `bash tools/check-lane.sh M2` exits 0 on my branch
[ ] Nothing was ever committed to main or develop
[ ] Everything is pushed to a feat/Fxx-* branch
[ ] `xcodebuild build` succeeds and the full unit suite passes (was 723, now more)
[ ] New tests exist, and they FAIL without the change
[ ] The satisfied TODO markers were deleted, in their own commit
[ ] `bash tools/todos.sh` shows a lower open count for M2
[ ] My contribution log has a row per session, with commit hashes
[ ] Test logs exist for F06, F12 and F13
[ ] I have told the team anything in this checklist that was NOT achieved
```


