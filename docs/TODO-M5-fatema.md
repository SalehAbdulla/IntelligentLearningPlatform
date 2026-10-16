# TODO — Fatema Ghareeb · M5 · `202304804`

> **Hand this entire file to your AI coding agent.** It is self-contained: identity,
> the rules, your features, your open TODOs, the git protocol, and the definition of
> done. Created 14 Oct 2026, the day Fatema joined the group.
>
> Companion reading (the agent should open these): [doc 12](12-GIT-WORKFLOW.md) for the
> git contract, [doc 13](13-PER-MEMBER-TASKS.md) for the starter briefs,
> [doc 02](02-FEATURE-LIST-OWNERSHIP.md) §2, §4 and §7 for ownership and the test rotation,
> [doc 14](14-COLLEAGUE-AI-AGENT-PROMPTS.md) §2 for the lane map, and
> **[CONTRIBUTING.md](../CONTRIBUTING.md)** for the full guide: setup, conventions,
> testing, evidence, troubleshooting and VIVA readiness.

---

## 0.0 First, two minutes of setup — you cannot push until this is done

**Your GitHub access is already in place.** Verified against the GitHub API on **14 Oct 2026**:
`FatemaGhareeb` is an **accepted collaborator with write access** on
`SalehAbdulla/IntelligentLearningPlatform`, so nothing is blocking you. (M2 and M4 are still
pending — that is their problem, not yours, and it is tracked as [doc 09](09-RISKS-OPEN-QUESTIONS.md) R23.)

So all you have to do is clone and set your identity:

```bash
gh auth status                        # confirm you are signed in as FatemaGhareeb
git clone https://github.com/SalehAbdulla/IntelligentLearningPlatform.git
cd IntelligentLearningPlatform
git config --local user.name  "Fatema Ghareeb"
git config --local user.email "202304804@student.polytechnic.bh"
python3 tools/verify-docs.py          # proves the clone is complete
```

> **Set the identity repo-locally and exactly as above.** It is the identity the marker reads
> `git log --author="Fatema"` against, and `.mailmap` already canonicalises it. Committing
> under anyone else's identity is treated as fabrication.

Your access is **write**, deliberately: a pull request is required on `main` and `develop` for
every member, and only the repository owner is exempt from admin enforcement
([doc 12 §3.1](12-GIT-WORKFLOW.md)).

---

## 0. THE TWO RULES THAT KEEP US OUT OF CONFLICT — read this before anything

Four members will run AI agents against this repository **at the same time**. Two things must
never happen, because both cost the team marks and hours:

1. **Working on `main` or `develop`.** Both require a pull request, so a direct push from your
   account is *rejected by GitHub*. Work on a branch of your own, always.
2. **Editing a file that belongs to someone else.** That is what produces merge conflicts.
   Your lane below is exact, and there is a script that enforces it.

### Rule 1 — your own branch, and only two branch names

One branch **per feature**, branched from `develop`. Only these patterns are yours:

```
feat/F16-<slug>    feat/F17-<slug>
```

```bash
bash tools/new-branch.sh feat/F16-moderated-group-chat
bash tools/new-branch.sh feat/F17-recall-space
```

Never `git switch develop` to "just quickly fix something". Never `git push origin main`.

### Rule 2 — your own files

**You may modify these, and nothing else:**

| Area | Files |
|---|---|
| F16 chat UI | `Features/Groups/GroupChatView.swift` · `GroupChatViewModel.swift` |

> **Why only two files, when you own two features.** F16 extends the group chat that M4 owns
> (F09). To keep the two lanes disjoint the boundary is drawn by *file*, not by directory:
> M4 keeps every F09 group-space and live-quiz file, and you take exactly these two chat files
> plus your own subdirectories below. **Before 14 Oct those two files appeared in no member's
> lane at all**, so nobody could modify them; F16 is the feature that needs them, so they are
> yours now.

**You may add NEW files** inside:

```
ios/StudyForge/StudyForge/Core/Groups/Moderation/      ← F16 model, policy, stores
ios/StudyForge/StudyForge/Core/Recall/                 ← F17 queue, settings, engine
ios/StudyForge/StudyForge/Features/Groups/Moderation/  ← F16 screens
ios/StudyForge/StudyForge/Features/Recall/             ← F17 screens
ios/StudyForge/StudyForgeTests/                        ← your test suites
```

**The one boundary to respect:** in `Core/Groups/` and `Features/Groups/`, M4 owns the top
level and **you own only the `Moderation/` subdirectory** (plus the two chat files above).
Do not add a file directly into `Core/Groups/` or `Features/Groups/`.

**Shared files** — anyone may touch these, but keep the change to **1–2 lines** and rebase
`develop` immediately before pushing:

- `ios/StudyForge/StudyForge/App/AppContainer.swift`
- `ios/StudyForge/StudyForge/Resources/en.lproj/Localizable.strings`
- `ios/StudyForge/StudyForge/Resources/ar.lproj/Localizable.strings`

If you touch a `.strings` file you **must** run `python3 tools/check-strings.py` (English and
Arabic key parity, 910 keys) before pushing.

**Off limits, always:** `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`,
`README.md`, `.mailmap`, and `ios/StudyForge/StudyForge.xcodeproj/` (nobody touches the
project file, ever — the folder is a `PBXFileSystemSynchronizedRootGroup`, so adding a new
`.swift` file does **not** require touching it).

**Enforce it, do not trust it:**

```bash
bash tools/check-lane.sh M5
```

Exit 0 = safe to commit and push. Exit 1 = stop and fix.

---

## 1. What you own

| | |
|---|---|
| **Handle** | M5 |
| **Features** | **F16** Admin-Moderated Group Chat · **F17** Active Recall Space |
| **Primary tester for** | **F01** (M1's auth) · **F05** (M2's quiz) · **F13** (M3's payments) |
| **Figma frame suffix** | `Fatema_202304804` — frames **142–154**, groups **N** and **O** |
| **Team role** | Collaboration & Recall lead |

You own **two** features, the rubric's minimum, and both are **net-new**: each brings its own
Swift module, its own Figma frame group, its own security rules and its own tests. You also
carry a full three-feature testing rotation. Effort, not feature count, is what is balanced —
see [doc 02 §3](02-FEATURE-LIST-OWNERSHIP.md).

### F16 · Admin-Moderated Group Chat (P0)

**What it is.** Every group's chat carries a **permanent moderator** — an admin who is always a
member of the space, cannot be removed by the group owner, is visibly badged in the member list
and the message list, and can moderate any message.

**Flow.** Open a group's chat → the admin presence banner and shield badge render → post and
read messages → the moderator pins an announcement → long-press any message → **Hide for
everyone / Delete / Pin / Flag** → a reason sheet is captured → the message is replaced by a
"Removed by a moderator" tombstone → the action is written to the append-only audit log.

**Edge cases you must handle.** The group owner tries to remove or demote the moderator
(refused, with the reason shown) · the moderator hides a message while a member is typing ·
the member is muted or slow-mode is on · a moderation action is taken offline (queues, resolves
on reconnect) · a message that is already hidden is reported.

**Data.** `groups/{id}/messages/{msgId}` (gains `hiddenAt`, `hiddenBy`, `hiddenReason`,
`pinnedBy`) · `groups/{id}/moderation/{actionId}` · `groups/{id}/members/{uid}` (the moderator
role) · `auditLog/{id}`.

### F17 · Active Recall Space, Anki-style (P0)

**What it is.** A single **Recall Space** that gathers everything due across **every** deck —
Anki's "Study"/filtered-deck idea — with the mechanics the current per-deck review (F04) does
not have: **learning steps** (1m → 10m) before a card graduates, **daily limits** (new
cards/day, max reviews/day), the **new / learning / young / mature** card states, and
**retention, heatmap and streak** statistics.

**Flow.** Open the Recall Space → the due-today queue is built across every deck → counts are
shown by card state → optionally filter by deck or tag → start the session → reveal → rate
Again / Hard / Good / Easy with the next interval shown → learning steps graduate the card →
session summary → retention, heatmap and streak update.

**Edge cases you must handle.** Nothing due (show the next due time) · the daily new-card or
review limit is reached · a learning card answered Again returns to step 1 · a card is deleted
by another screen mid-session · the daily limits or learning steps change mid-session · offline.

**Data.** `decks/{id}/cards/{cardId}` (the `sr` state gains `learningStep`) ·
`recallSettings/{uid}`.

> **The one hard constraint on F17.** The SM-2 scheduler in
> `Core/Scheduling/SpacedRepetition.swift` is **hand-written, pure and tested**, and it is the
> single source of truth for intervals. F17 **calls** `SpacedRepetition.nextState`; it must
> **never** copy, re-implement or duplicate that maths. If you believe it needs to change,
> say so first — it is M2's headline "written by hand" evidence and F04 depends on it.
> F17 also gets **its own** `RecallSessionViewModel`; do **not** edit
> `Features/Flashcards/FlashcardReviewViewModel.swift`, which belongs to M2.

---

## 2. Your open TODOs

Run `bash tools/todos.sh M5` for the live list. Each task is marked in the code as
`// TODO(M5 · Fxx):` with a `// Done when:` acceptance line. The starting set:

- `Core/Groups/Moderation/GroupModeration.swift` — the moderator model and the
  "cannot be removed" policy (F16)
- `Core/Recall/RecallQueue.swift` — the cross-deck due-today queue and its state counts (F17)
- `Core/Recall/RecallSettings.swift` — learning steps and daily limits (F17)

Delete each marker in its own commit when the `Done when:` line is genuinely satisfied.

---

## 3. The git protocol — the tutor's stated requirement

```bash
bash tools/new-branch.sh feat/F17-recall-space     # from an up-to-date develop
# ... make ONE logical change ...
bash tools/check-lane.sh M5                        # must exit 0
bash tools/commit.sh --push \
  ios/StudyForge/StudyForge/Core/Recall/RecallQueue.swift \
  "feat(F17): build the cross-deck due-today queue"
```

Rules, from [doc 12](12-GIT-WORKFLOW.md):

1. **Never** commit to `main` or `develop`. `tools/commit.sh` refuses, and GitHub rejects it.
2. **One file per commit.** `tools/commit.sh` warns if you bundle more than one.
3. **Conventional Commit messages only** — `feat(F17): …`, `test(F16): …`, `fix(F16): …`.
   A message like `update` or `wip` is rejected.
4. **Push every day you work.** A single commit dump at the deadline reads as fabricated.
5. **Open a pull request** when the feature works: `gh pr create --base develop --fill`.
6. Disclose AI use in the PR body, and never commit a secret
   (`tools/commit.sh` scans for keys).

---

## 4. Verification commands — run these before you say "done"

```bash
bash tools/check-lane.sh M5            # lane is disjoint
bash tools/todos.sh M5                 # your open count has dropped
python3 tools/verify-docs.py           # docs still consistent
python3 tools/check-strings.py         # only if you touched a .strings file

xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Tests use **Swift Testing** (`@Suite` / `@Test`), never XCTest. Follow the existing suites in
`ios/StudyForge/StudyForgeTests/`.

---

## 5. My evidence — this is 10% of my mark, per person

| Artefact | What goes in it |
|---|---|
| `research/sprints/sprint-2/fatema-contribution.md` | one row per work session, with the commit hash. Fill it in within 24 hours of the work. **Never back-fill a whole sprint in one go**, and never claim more than the commits show |
| `research/testing/F01-fatema.md`, `F05-fatema.md`, `F13-fatema.md` | test logs. **You are the primary tester for F01, F05 and F13** — nobody tests a feature they developed. Record the exact steps you ran, the observed result, any defect found, and whether it is fixed. Finding a real defect beats a clean pass, but never invent one |
| `research/reviews/*` | notes on the AI-generated code you reviewed and corrected |
| `research/cheatsheets/fatema.md` | keep the quick-reference current for F16 and F17 |
| The Figma file | frames **142–154** named `…_Fatema_202304804` (groups N and O) |

`research/testing/` and `research/reviews/` may not exist yet — create them, and name files
distinctly (e.g. `F01-fatema.md`) so nobody collides.

---

## 6. Rules of engagement

- **Stay in my lane** (§0). `Features/Groups/GroupChat{View,ViewModel}.swift`,
  `Core/Groups/Moderation/`, `Core/Recall/`, `Features/Groups/Moderation/`,
  `Features/Recall/`, and `StudyForgeTests/`.
- **Do not edit `docs/`, `deliverables/`, `backend/`, `tools/`, or the `.xcodeproj`.**
- **Do not edit the Figma file** — M1 owns it. If you find a design or accessibility problem
  there, write it up in `research/reviews/` and report it.
- **Do not edit `Core/Scheduling/SpacedRepetition.swift`** (§1), and do not edit any file in
  another member's lane to make your feature work. If F17 seems to need it, stop and tell me.
- Match the existing code style: this codebase has heavy, deliberate comments explaining
  **why**. Read three neighbouring files before adding one.
- Small, reviewable diffs. Do not refactor unrelated code.
- **Never** weaken or delete an existing test to make a new one pass. If a test now looks
  wrong, explain why first.
- No new third-party dependencies without asking.
- **Every line must be something I can explain out loud in the VIVA.** If you are about to
  write something I could not explain, stop and tell me instead.
- If you are blocked, say so plainly with the error, rather than working around it.

---

## 7. Definition of done — report against this checklist

```
[ ] A written plan was produced BEFORE any code was written
[ ] At least TWO of my features (F16 F17) have a real, tested, committed change
[ ] Every changed file was committed SEPARATELY with a Conventional Commit message
[ ] `bash tools/check-lane.sh M5` exits 0 on my branch
[ ] The shared-file edit (if any) is 1-2 lines, and I rebased develop before pushing
[ ] Nothing was ever committed to main or develop
[ ] Everything is pushed to a feat/F16-* or feat/F17-* branch
[ ] `xcodebuild build` succeeds and the full unit suite passes
[ ] New tests exist, and they FAIL without the change
[ ] F16: a test proves the moderator cannot be removed, and that a hidden message stays hidden
[ ] F17: a test proves the queue gathers cards from MORE THAN ONE deck
[ ] F17: the interval maths still comes from `SpacedRepetition.nextState` (not duplicated)
[ ] `FlashcardReviewViewModel.swift` and `SpacedRepetition.swift` are UNCHANGED
[ ] If a live Firestore round-trip could not be verified, that is stated plainly
[ ] The satisfied TODO markers were deleted, in their own commit
[ ] `bash tools/todos.sh M5` shows a lower open count for M5
[ ] My contribution log has a row per session, with commit hashes
[ ] Test logs exist for F01, F05 and F13
[ ] I have told the team anything in this checklist that was NOT achieved
```
