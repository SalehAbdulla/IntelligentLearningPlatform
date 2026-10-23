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

> ## ⚠️ READ THIS FIRST IF YOU HAVE `feat/F03-AI-SUMMARY` CHECKED OUT
>
> **Your branch was rewritten on 23 Oct 2026 by Saleh (M1), with the authorisation recorded in
> [`docs/TODOLIST.md` §0](TODOLIST.md), and its name was corrected the same day** —
> `feat/F03-AI-SUMMARY` → **`feat/F03-ai-summary`**, because an uppercase slug is what
> `tools/new-branch.sh` refuses. **Your clone now points at commits that no longer exist on the
> remote, under a branch name that no longer exists either.** These commands fix both:
>
> ```bash
> git fetch origin
> git branch -m feat/F03-AI-SUMMARY feat/F03-ai-summary   # only if that name is checked out
> git branch -u origin/feat/F03-ai-summary feat/F03-ai-summary
> git reset --hard origin/feat/F03-ai-summary
> git remote prune origin
> ```
>
> **Before you run that: if you have any local work you have not pushed, stop and say so first.**
> The old line now exists in exactly two places — your clone, and a bundle Saleh holds
> (`.git/F03-before-rewrite.bundle`, head `5e4a94e`) — so moving your work across *before* the
> reset is much easier than after it.
>
> **What changed, and why.** The branch had been created from `main` instead of `develop`, so it
> carried **67 commits**: your 36, plus main's entire release line. Three measured consequences:
> the lane guard refused you a file that is yours, GitGuardian went red on one of Saleh's earlier
> commits (PR #34) that your branch happened to contain, and `tools/check-commits.sh` reported
> **5 message failures** — `view`, `configure view`, `edit sheet`, `quate view`, `source sheet` —
> plus a personal author address.
>
> The branch was **rebased onto `develop`**, the five subjects were **reworded from each commit's
> own diff**, and **author *and* committer were set to `Mohammed Almadhoon
> <202401702@student.polytechnic.bh>`** — the identity the Sprints mark is read from. Your pull
> request — now **#135**, because renaming the branch closed #132 — shows **36 commits instead of
> 67**, and the tool reports **0 message failures and 0 identity failures**.
>
> **Nothing about your code changed.** Verified before the push, not after: the branch's net
> change is **byte-identical** — the same 21 files, the same **+2897/−1**. Only the log moved, and
> your commit dates are unchanged, so the sprint timeline still reads honestly.
>
> **This is not a correction of you.** You were committing under the identity this file used to
> tell you to use, on a branch created the way the handover used to describe it. Both were
> documentation defects, and both are now fixed in this file.
>
> **One thing stays red, and it is not yours to fix:** `bash tools/check-lane.sh M2` still reports
> `Features/Library/MaterialLibraryView.swift` as OUT OF LANE until **PR #131** merges and you
> merge `develop` into your branch. That file *is* yours — the corrected guard is simply not on
> `develop` yet.

---

## ⚡ The four things that actually go wrong — read this before anything else

**Every problem a member has hit so far has been one of these four.** They take ten minutes to get
right, and they are what the Sprints mark — **10%, assessed individually** — is read from.

| # | Do this | **Not** this | What goes wrong otherwise |
|---|---|---|---|
| **1** | `git config --local user.email "202401702@student.polytechnic.bh"` | `<your github email>`, or a personal Gmail | **This file used to say `<your github email>`, and that was wrong.** A commit under an address that is not your student address is **invisible to `git shortlog`** — the work exists and counts for nobody |
| **2** | `bash tools/new-branch.sh feat/F04-hard-grade-tracking` | `git switch -c` by hand | The tool branches from **current `develop`** and refuses an invalid name. A hand-made branch was once **84 commits behind** `develop`, carried 32 unrelated merge commits, and had uppercase in its name that no tool would accept |
| **3** | `bash tools/commit.sh <file> "feat(F04): …"` | `git commit -m "…"` | The tool refuses a non-conventional message, refuses `main`/`develop`, and scans for secrets. Messages like `configure view` and `updates` have been committed by hand instead, and none of them survive the rubric |
| **4** | `gh pr create --base develop --fill` **the same day** | leaving it local and pushing later | **CI runs on every push to a feature branch now**, so a broken push goes red in ~11 minutes. A branch with **no PR** is invisible: one member's did not compile for hours and nobody knew, because the only thing that ever looked at it was a person doing it by hand |

> **The one-line version:** *set your identity, branch with the tool, commit with the tool, open the
> PR.* In that order, every time.

> **And expect your PR to sit "blocked" until it has one approving review.** `develop` requires it
> ([doc 12 §3.1](12-GIT-WORKFLOW.md)) and GitHub will not let you merge it yourself. **That is the
> process working, not a rejection.** Post the link in the group chat and it gets reviewed — but plan
> for the review to take a day, so a PR opened the night before a deadline will not be merged by it.

> **And open the PR even when the work is unfinished.** A red PR is a working session. An unopened
> one is a lost afternoon — and the four things above are all things the tooling would have caught.

---

## 0.0 First, two minutes of setup

✅ **Your access is live.** Verified on 16 Oct 2026 against the API: `mohdalmadhon` holds **write**
on `SalehAbdulla/IntelligentLearningPlatform`, and the pending-invitation list is **empty**. You can
clone, branch, commit and open the pull request that your Sprints evidence is read from.

**Nothing external is blocking you any more.** The only thing that can hold your mark down now is
commits that do not exist — so the next step is yours, and it is small: confirm the clone, set your
own identity, then commit something real today.

```bash
gh auth status                        # or: git config --global user.name / user.email
git clone https://github.com/SalehAbdulla/IntelligentLearningPlatform.git
cd IntelligentLearningPlatform
git config --local user.name  "Mohammed Almadhoon"
git config --local user.email "202401702@student.polytechnic.bh"
python3 tools/verify-docs.py          # proves the clone is complete
```

> **`--local`, and the student address — not your GitHub or personal email.** This block used to say
> `<your github email>` and that was simply wrong: a commit under any other address does not appear
> under your name in `git shortlog`, so the work counts for nobody. `.mailmap` canonicalises the
> student address; it cannot rescue an address that was never yours.

Your access is **write**, deliberately: a pull request is required on `main` and `develop` for
every member, and only the repository owner is exempt from admin enforcement
([doc 12 §3.1](12-GIT-WORKFLOW.md)).

---

## 0. THE TWO RULES THAT KEEP US OUT OF CONFLICT — read this before anything

Three members will run AI agents against this repository **at the same time**. Two
things must never happen, because both cost the team marks and hours:

1. **Working on `main` or `develop`.** Both require a pull request, so a direct push from
   your account is *rejected by GitHub*. Work on a branch of your own, always.
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

| Area | Yours |
|---|---|
| **F03 · F04 · F05 · F11 — everything in these directories** | `Core/AI/` · `Core/Flashcards/` · `Core/Quizzes/` · `Core/Scheduling/` · `Core/Summaries/` · `Core/Tutor/` · `Features/Flashcards/` · `Features/Quizzes/` · `Features/Summaries/` · `Features/Tutor/` |
| F15 admin config | `Core/Admin/AIConfiguration.swift` — the one file of yours inside M4's `Core/Admin/` |
| F15 Coach UI (screens 73–76, 79, 80) | `Features/Coach/CoachHomeView.swift` · `CoachHomeViewModel.swift` · `CoachChatView.swift` · `CoachChatViewModel.swift` · `CitationSheetView.swift` |
| F03's entry point | `Features/Library/MaterialLibraryView.swift` — a one-line seam inside the owner's directory |
| Tests | `StudyForgeTests/AIRouterTests.swift` · `AIVocabularyTests.swift` · `FlashcardReviewViewModelTests.swift` · `FlashcardGenerateViewModelTests.swift` · `SummaryFlowViewModelTests.swift` |
| **NOT yours, inside your own directories** | `Core/Tutor/CohortSnapshot.swift` is **M3's** (F07) |

> **Corrected 22 Oct 2026 — your lane used to be a list of individual files, and it was too small.**
> An audit of the tracked tree found **167 of the 394 app files were in no lane at all**, including
> `Core/Scheduling/SpacedRepetition.swift` — which *your own starter brief* tells you to hand-write —
> and the whole Coach UI behind screens 73–76, 79 and 80, which docs/03 assigns to you by name. Your
> lane is now the **directories** your five features live in, existing files and new ones alike, with
> the exception named above. Full detail: [doc 14 §2](14-COLLEAGUE-AI-AGENT-PROMPTS.md).

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

### If you are on a Mac

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### If you are on Windows — **CI is your build machine**

**Xcode is macOS-only, so `xcodebuild` cannot run on your machine at all.** Do not try to
install it; there is no Windows version and no emulator that runs an iOS Simulator. Push your
branch instead — CI builds and tests it on a real macOS runner, for free.

```bash
bash tools/check-lane.sh M2      # lane still clean. Needs WSL or Git Bash — see docs/18
python3 tools/verify-docs.py     # docs, links and ownership integrity
python3 tools/check-strings.py   # only if you touched .strings or .stringsdict
bash tools/todos.sh              # my open count went DOWN, not up

git push                         # CI starts automatically
gh pr checks                     # THE VERDICT
```

The suite is **808 tests in 128 suites**, and my change should raise that number. If CI is red:

```bash
gh run view <run-id> --log-failed              # the failing steps
gh run download <run-id> -n xcodebuild-log     # the raw log, when that is not enough
```

> **Never write "the build passes" unless `gh pr checks` says so.** Quote the CI result or say
> that CI has not run yet. This is the one rule that makes the evidence worth anything, and it
> is the rule an AI agent breaks by default — it will happily tell you something works because
> the code looks right.

**Full guide for a Windows machine, written for your agent to read:**
[`docs/18-WINDOWS-CONTRIBUTING.md`](18-WINDOWS-CONTRIBUTING.md).

Never commit a red build. If CI or a test fails, fix it first.

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


