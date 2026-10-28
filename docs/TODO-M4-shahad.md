# TODO — Shahad Ashoor · M4 · `202305767`

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

## ⚑ 28 Oct 2026 — nothing of yours is in the repository yet. Here is the smallest real first commit.

**Verified against the remote today:**

| What | Measured |
|---|---|
| Commits | `git log --all --no-merges --author=202305767` returns **0** |
| Branches | **no branch of yours exists on `origin`** — 21 branches, none matching `feat/F(08\|09\|10\|12)-` |
| Pull requests | **none opened from your account** |
| Your artefacts | `research/sprints/sprint-1/shahad-contribution.md` and `research/cheatsheets/shahad.md` are still **empty templates** |

**That is now the whole of the Sprints risk.** M2 has **36** commits, M3 has **12** (both features merged) and M5 has **22** — and the Sprints component is **10%, assessed per person**, read off `git shortlog`. This is not a statement about your work; it is that the repository cannot see it, and a mark cannot be read from a branch that does not exist.

**The first commit, ready to run** — your starter brief from [doc 13](13-PER-MEMBER-TASKS.md), made turnkey:

| | |
|---|---|
| **Feature** | **F10** Bookmarks — yours |
| **The problem** | `ios/StudyForge/StudyForge/Core/Bookmarks/BookmarkStore.swift:14` — the bookmarks screen shows an **empty store** today, so a Firestore implementation behind the existing protocol is what makes it demonstrable and what survives a reinstall |
| **Your files** | `Core/Bookmarks/` (yours) · `Features/Bookmarks/*` (already written against the protocol) · `App/AppContainer.swift` — the one **declared SHARED file**, so a 1–2 line edit, and rebase before pushing |
| **Acceptance** | a Swift Testing case proving a **round-trip** (write, read back, owner-only), and the `TODO(M4 · F10)` marker deleted in its own commit |
| **Run this** | `bash tools/new-branch.sh feat/F10-firestore-bookmarks` → `bash tools/check-lane.sh M4` → `bash tools/commit.sh <file> "feat(F10): add a Firestore-backed BookmarkStore"` → `gh pr create --base develop --fill` **the same day** |

**Then the other two, both in your lane and both already marked:** `Core/Groups/StudyGroup.swift:34` (the `PresenceProvider` seam) and `Core/Groups/LiveQuizSession.swift:16` (reconnect and resync for a disconnected player) — both **F09**, which is yours too.

**And the two things only you can do:**
- **Your test logs.** You are the named tester for **F01, F04, F05 and F11**, and `research/testing/` holds **no log from you** (only M1's four). One log per feature, from a real run.
- **The sprint review recording.** [Doc 13 §M4](13-PER-MEMBER-TASKS.md) assigns you coordinating it, and it is one of the three artefacts missing from **every** sprint folder (`board.png`, `review.mp4`, `retro.md`). Every member must be filmed demoing their own work — which the VIVA (60%, must pass) needs as much as the sprint does.

---


## ⚡ The four things that actually go wrong — read this before anything else

**Every problem a member has hit so far has been one of these four.** They take ten minutes to get
right, and they are what the Sprints mark — **10%, assessed individually** — is read from.

| # | Do this | **Not** this | What goes wrong otherwise |
|---|---|---|---|
| **1** | `git config --local user.email "202305767@student.polytechnic.bh"` | `<your github email>`, or a personal address | **This file used to say `<your github email>`, and that was wrong.** A commit under an address that is not your student address is **invisible to `git shortlog`** — the work exists and counts for nobody |
| **2** | `bash tools/new-branch.sh feat/F09-presence-seam` | `git switch -c` by hand | The tool branches from **current `develop`** and refuses an invalid name. A hand-made branch was once **84 commits behind** `develop`, carried 32 unrelated merge commits, and had uppercase in its name that no tool would accept |
| **3** | `bash tools/commit.sh <file> "feat(F09): …"` | `git commit -m "…"` | The tool refuses a non-conventional message, refuses `main`/`develop`, and scans for secrets. Messages like `configure view` and `updates` have been committed by hand instead, and none of them survive the rubric |
| **4** | `gh pr create --base develop --fill` **the same day** | leaving it local and pushing later | **CI runs on every push to a feature branch now**, so a broken push goes red in ~11 minutes. A branch with **no PR** is invisible: one member's did not compile for hours and nobody knew |

> **The one-line version:** *set your identity, branch with the tool, commit with the tool, open the
> PR.* In that order, every time.

> **And expect your PR to sit "blocked" until it has one approving review.** `develop` requires it
> ([doc 12 §3.1](12-GIT-WORKFLOW.md)) and GitHub will not let you merge it yourself. **That is the
> process working, not a rejection.** Post the link in the group chat and it gets reviewed — but plan
> for the review to take a day, so a PR opened the night before a deadline will not be merged by it.

---

## 0.0 First, two minutes of setup

✅ **Your access is live.** Verified on 16 Oct 2026 against the API: `shaahaadhani43-debug` holds
**write** on `SalehAbdulla/IntelligentLearningPlatform`, and the pending-invitation list is
**empty**. You can clone, branch, commit and open the pull request that your Sprints evidence is
read from.

**Nothing external is blocking you any more.** The only thing that can hold your mark down now is
commits that do not exist — so the next step is yours, and it is small: confirm the clone, set your
own identity, then commit something real today.

```bash
gh auth status                        # or: git config --global user.name / user.email
git clone https://github.com/SalehAbdulla/IntelligentLearningPlatform.git
cd IntelligentLearningPlatform
git config --local user.name  "Shahad Ashoor"
git config --local user.email "202305767@student.polytechnic.bh"
python3 tools/verify-docs.py          # proves the clone is complete
```

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
feat/F08-<slug>    feat/F09-<slug>    feat/F10-<slug>    feat/F12-<slug>
```

```bash
bash tools/new-branch.sh feat/F09-presence-seam
bash tools/new-branch.sh feat/F10-firestore-bookmarks
```

Never `git switch develop` to "just quickly fix something". Never `git push origin main`.

### Rule 2 — your own files

**You may modify these** (and nothing else):

| Area | Yours |
|---|---|
| **F08 · F09 · F10 · F12 — everything in these directories** | `Core/Admin/` · `Core/Bookmarks/` · `Core/Folders/` · `Features/Admin/` · `Features/Bookmarks/` · `Features/Folders/` · `Features/Groups/` |
| F09 group stores (top level of `Core/Groups/`) | `StudyGroup.swift` · `LiveQuizSession.swift` · `GroupStore.swift` · `FileGroupStore.swift` · `InMemoryGroupStore.swift` |
| Tests | `StudyForgeTests/BookmarkStoreTests.swift` · `BookmarkViewModelTests.swift` · `GroupViewModelTests.swift` · `GroupStoreTests.swift` · `AdminTests.swift` |
| **NOT yours, inside your own directories** | `Core/Admin/AIConfiguration.swift` is **M2's** (F15) · `Features/Groups/GroupChatView.swift`, `GroupChatViewModel.swift` and `Features/Groups/Moderation/` are **M5's** (F16) |

> **Corrected 22 Oct 2026 — your lane used to be a list of individual files, and it was too small.**
> An audit of the tracked tree found **167 of the 394 app files were in no lane at all**, including
> your whole `Features/Admin/` screen set, `Features/Bookmarks/`, `Features/Folders/` and all twenty
> `Core/Admin/` files — so the F12 work your brief describes could not be started. Your lane is now
> the **directories** your four features live in, existing files and new ones alike, with the three
> exceptions named in the last row above. Full detail: [doc 14 §2](14-COLLEAGUE-AI-AGENT-PROMPTS.md).

**You may add NEW files** inside: `Core/Groups/` · `Core/Bookmarks/` · `Core/Folders/` ·
`Features/Groups/` · `Features/Folders/` · `Features/Bookmarks/` · `Features/Admin/` ·
`StudyForgeTests/`

**SHARED — allowed, but follow the protocol** (see below):
`App/AppContainer.swift` · `Resources/en.lproj/Localizable.strings` ·
`Resources/ar.lproj/Localizable.strings`

**OFF LIMITS, no exceptions:**

| Path | Owner |
|---|---|
| `Core/AI/`, `Features/Flashcards/`, `Features/Summaries/`, `Features/Quizzes/`, `Features/Tutor/` | Mohammed (M2) |
| `Core/Planning/`, `Core/Payments/`, `Features/StudyPlan/`, `Features/Progress/`, `Features/Subscription/`, `Features/Home/` | Tasbeeh (M3) |
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
bash tools/check-lane.sh M4
```

It refuses if you are on `main`/`develop`, lists every file your branch is about to
change, and tells you whether each one is **yours**, **new (yours)**, **SHARED**, or
**OUT OF LANE / FORBIDDEN**. Exit 1 means stop and fix it.

### The SHARED-file protocol — you are the one member who will need it

`AppContainer.swift` is the single injection point, and your F10 work genuinely needs one
line of it (near line 533, where `bookmarks: FileBookmarkStore()` is chosen). Two rules:

1. **Keep it to 1–2 lines.** Do not restructure that file.
2. **Rebase immediately before you push**, because a teammate may have changed it since
   you branched:

```bash
git fetch origin && git rebase origin/develop   # always rebase before you push
bash tools/check-lane.sh M4                     # re-check
python3 tools/check-strings.py                  # only if a .strings file changed
```

If the push is rejected, rebase again. **Never force-push.**

---

## 1. Who you are (the agent must do this first)

```bash
git config --local user.name  "Shahad Ashoor"
git config --local user.email "202305767@student.polytechnic.bh"
```

Every commit must be attributable to me. My **Sprints mark is 10% and assessed per
person**, and the **VIVA is 60% and must pass**, so I have to be able to explain every
line I claim. Then read: `docs/12-GIT-WORKFLOW.md`, `docs/13-PER-MEMBER-TASKS.md`
(my section + the starter briefs), `docs/02-FEATURE-LIST-OWNERSHIP.md` §2 and §7, and
`research/sprints/sprint-1/goal.md` (my row is **S1-M4**).

---

## 2. My features — **at least two of them must ship**

| ID | Feature |
|---|---|
| **F08** | Shared Study Folders |
| **F09** | Group Revision Spaces — *realtime collaboration, my most complex feature* |
| **F10** | Resource Bookmarking |
| **F12** | Admin Content Management |

> **HARD ACCEPTANCE CRITERION.** By the end, **at least TWO** of the features above must
> carry a real, tested, committed change authored under my git identity. Touching only
> one feature does **not** satisfy the rubric. If only one is achieved, the agent must
> say so plainly rather than claiming otherwise.

Recommended pair: **F09 + F10**, because they carry all three of my open TODOs.

---

## 3. My open TODOs (confirm with `bash tools/todos.sh`)

**F09 — a presence seam (`PresenceProvider`)**
`ios/StudyForge/StudyForge/Core/Groups/StudyGroup.swift:34`
`GroupMember.isOnline` currently drives the I10 presence dots from whatever the last
local value was. Add a protocol so presence comes from a live source.
*Done when:* the provider is injected, a fake provider updates presence in a test, and the
UI reflects it.

**F09 — reconnect / resync for a disconnected player**
`ios/StudyForge/StudyForge/Core/Groups/LiveQuizSession.swift:16`
When a player is shown as disconnected and rejoins, re-derive their state
**deterministically** instead of restarting the session.
*Done when:* a `resync()` re-reads the answers and leaderboard, and a test drives a
disconnect then a reconnect and asserts the **same scores**.

> **Read that file's header comment before you touch it.** The other players' answering is
> deliberately simulated and **DETERMINISTIC** (each player has a fixed skill and answers
> by a rule) so the screens behave identically every run and the tests can assert on them.
> **Do not introduce randomness** to make the demo look livelier — it would break the
> tests and the reproducibility, which is the whole point of the design.

**F10 — a Firestore-backed `BookmarkStore`**
`ios/StudyForge/StudyForge/Core/Bookmarks/BookmarkStore.swift:14`
Add an implementation **behind** the existing protocol, matching docs/05 §2.5
(`collections/{id}`, `bookmarks/{id}`, owner-only rules).
*Done when:* the implementation exists, `AppContainer` can select it, and a test proves a
collection round-trips through it.

> **Do NOT change the `BookmarkStore` protocol.** It is referenced by **17 files**
> including `Features/Library/MaterialLibraryView.swift`,
> `Features/Search/GlobalSearchView.swift` and `Core/Payments/InMemorySubscriptionStore.swift`
> — files that are **not in my lane**. Add a new conforming type; do not edit the seam.

> **Before writing the Firestore store, search the repo** for how the existing stores are
> structured under `Core/` (e.g. `FileBookmarkStore.swift`) and follow the **same**
> pattern rather than inventing one.
>
> **Honesty requirement.** If the Firebase emulator is not configured on this machine you
> cannot verify a live round-trip. In that case: keep the implementation injectable, test
> the logic against the existing in-memory double, and **state plainly in your report that
> a live Firestore round-trip was NOT verified.** Do not claim it was.

Each TODO comment already states its own *"Done when"*. Treat that as the acceptance
test, and **delete the TODO marker** once it is met — in its own commit.

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
bash tools/new-branch.sh feat/F09-presence-seam
bash tools/new-branch.sh feat/F10-firestore-bookmarks

# 2. check your lane
bash tools/check-lane.sh M4

# 3. ONE COMMIT PER FILE — never batch unrelated files together
bash tools/commit.sh <path> "feat(F09): inject a PresenceProvider seam for member presence"

# 4. push when the task is complete, and keep pushing as you go
bash tools/commit.sh --push <path> "test(F10): round-trip a collection through the store"

# ...or several files with their own messages, then push, in one command
bash tools/commit.sh --push --multi \
  <p1> "feat(F10): add a Firestore-backed BookmarkStore" \
  <p2> "feat(F10): select the Firestore store in AppContainer" \
  <p3> "test(F10): cover a collection round-trip"
```

Rules that are enforced, not advisory:

- `tools/commit.sh` **refuses** to commit on `main`/`develop`, refuses a non-Conventional
  message, and rejects "update"/"fix stuff" style messages.
- Scope every message with the feature ID: `feat(F09): …`, `test(F10): …`.
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
bash tools/check-lane.sh M4      # lane still clean. Needs WSL or Git Bash — see docs/18
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
| `research/sprints/sprint-1/shahad-contribution.md` | one row per work session, with the commit hash. Fill it in for what I actually did. **Never back-fill a whole sprint in one go**, and never claim more than the commits show |
| `research/testing/F01-*.md`, `F04-*.md`, `F05-*.md`, `F11-*.md` | test logs. **I am the primary tester for F01, F04, F05 and F11** — nobody tests a feature they developed. Record what I ran, the exact steps, the observed result, any defect found, and whether it is fixed. Finding a real defect beats a clean pass, but never invent one |
| `research/reviews/*` | notes on the AI-generated code I reviewed and corrected. Also where I write up any design or accessibility problem I find in the Figma file |
| `research/cheatsheets/shahad.md` | keep the quick-reference current for my features |

`research/testing/` and `research/reviews/` do not exist yet — create them (name files
distinctly, e.g. `F01-shahad.md`, so nobody collides).

---

## 8. Rules of engagement

- **Stay in my lane** (§0). `Core/Groups/`, `Core/Bookmarks/`, `Core/Folders/`,
  `Features/Groups/`, `Features/Folders/`, `Features/Bookmarks/`, `Features/Admin/`, plus
  `research/`.
- **Do not edit `docs/`, `deliverables/`, `backend/`, `tools/`, or the `.xcodeproj`.**
- **Do not edit the Figma file** — M1 owns it. If I find a design or accessibility problem
  there, write it up in `research/reviews/` and report it.
- Match the existing code style: this codebase has heavy, deliberate comments explaining
  **why**. Read three neighbouring files before adding one.
- Tests use **Swift Testing** (`@Suite` / `@Test`), not XCTest. Follow the existing suites.
- Small, reviewable diffs. Do not refactor unrelated code.
- **Do not add randomness to the live-quiz simulation**, and do not weaken or delete an
  existing test to make a new one pass. If a test now looks wrong, explain why first.
- No new third-party dependencies without asking.
- **Every line must be something I can explain out loud in the VIVA.** If you are about
  to write something I could not explain, stop and tell me instead.
- If you are blocked, say so plainly with the error, rather than working around it.

---

## 9. Definition of done — report against this checklist

```
[ ] A written plan was produced BEFORE any code was written
[ ] At least TWO of my features (F08 F09 F10 F12) have a real, tested, committed change
[ ] Every changed file was committed SEPARATELY with a Conventional Commit message
[ ] `bash tools/check-lane.sh M4` exits 0 on my branch
[ ] The AppContainer edit (if any) is 1-2 lines, and I rebased develop before pushing
[ ] Nothing was ever committed to main or develop
[ ] Everything is pushed to a feat/Fxx-* branch
[ ] `xcodebuild build` succeeds and the full unit suite passes (was 723, now more)
[ ] New tests exist, and they FAIL without the change
[ ] The reconnect/resync test asserts the SAME scores after a reconnect
[ ] No randomness was introduced into the live-quiz simulation
[ ] The BookmarkStore protocol itself was NOT modified
[ ] If a live Firestore round-trip could not be verified, that is stated plainly
[ ] The satisfied TODO markers were deleted, in their own commit
[ ] `bash tools/todos.sh` shows a lower open count for M4
[ ] My contribution log has a row per session, with commit hashes
[ ] Test logs exist for F01, F04, F05 and F11
[ ] I have told the team anything in this checklist that was NOT achieved
```



