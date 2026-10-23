# 14, Per-member AI-agent handover

> **One file per member.** Hand the whole file to an AI coding agent and it has
> everything it needs: identity, the rules, the features, the open TODOs, the git
> protocol, the verification commands, and the definition of done.

| Member | Handle | Student ID | Handover file | Their features |
|---|---|---|---|---|
| **Mohammed Almadhoon** | M2 | `202401702` | [TODO-M2-mohammed.md](TODO-M2-mohammed.md) | F03 · F04 · F05 · F11 · F15 (co) |
| **Tasbeeh Saeed** | M3 | `202305409` | [TODO-M3-tasbeeh.md](TODO-M3-tasbeeh.md) | F06 · F07 · F13 · F15 (co) |
| **Shahad Ashoor** | M4 | `202305767` | [TODO-M4-shahad.md](TODO-M4-shahad.md) | F08 · F09 · F10 · F12 |
| **Fatema Ghareeb** | M5 | `202304804` | [TODO-M5-fatema.md](TODO-M5-fatema.md) | F16 · F17 |

M1 (Saleh Abdulla, `202300540`) owns F01, F02 and F14 plus the cross-cutting document and
Figma work, and is not covered by these files.

**Why these files exist.** The **Sprints component (10%) is assessed per person** and the
**VIVA (60%) must be passed by every member**, and as of 8 Oct 2026 every commit in this
repository is authored by M1. Each handover file states a **hard acceptance criterion**:
*at least two of that member's features must carry a real, tested, committed change under
their own git identity.* M5's file was added on **14 Oct 2026**, the day Fatema joined and
filled the brief's default fifth seat.

---

## 1. The conflict problem, and how it is solved

Four members will run agents against this repository **at the same time**. Two failure
modes are predictable and both are expensive:

| Failure mode | Defence |
|---|---|
| An agent commits to `main` or `develop` | GitHub **rejects a member push** (a pull request is required), `tools/commit.sh` refuses locally, `tools/check-lane.sh` refuses locally. The **owner account is deliberately exempt** from the server check, so for the owner the two local guards are the only defence: never disable them, never let an agent push straight to `develop`, and treat `--owner` / `owner --allow-protected` as hotfix-only flags — an agent prompt must never contain them |
| An agent edits another member's file, causing a merge conflict | **A disjoint file lane per member**, enforced by `tools/check-lane.sh` |

### Verified: the lanes do not overlap

**204 files** are reachable across the four members' *modify* lanes, **no file is claimed by two
members, and no tracked app file is in no lane at all.** Re-measured 23 Oct 2026 by parsing the
guard's own `DIRS` / `TOUCH` / `OWNED_DIRS` / `CARVE_OUTS` arrays and testing every tracked app
file against them, rather than recounting by hand:

```
app files              : 392   ios/StudyForge/StudyForge + StudyForgeTests
  M1 (project level)   : 202   the app entry point and router, the design system, Resources,
                               the preview assets, the existing test files, and F01/F02/F14
  M2 · M3 · M4 · M5    :  77 · 54 · 68 · 5        (204 in the four modify-lanes)
  member-vs-member     :   0   no file sits in two members' lanes
  owner meets member   :  14   in the owner's lane AND one member's — see the note below
  member-only files    : 190   the 204 minus those 14; and 202 + 190 = 392
  in no lane at all    :   0   ← was 167 before the 22 Oct pass; see the correction below
```

> **Correction, 23 Oct 2026 — this block read *190 … 71 · 51 · 63 · 5 · claimed by two: 0*.**
> The 190 was right as a **partition** of the 392 app files, but wrong as a **per-member lane
> size**: it had quietly excluded the files a member holds that the owner also holds, so
> *"claimed by two: 0"* was true only of member-versus-member pairs. The **14** files the owner
> and a member both hold are **13 existing test files** in `StudyForgeTests/` — which the owner
> holds as a directory, and which M2, M3 and M4 each name individually in `TOUCH`
> (`AIRouterTests`, `AIVocabularyTests`, `FlashcardGenerateViewModelTests`,
> `FlashcardReviewViewModelTests`, `SummaryFlowViewModelTests`, `CohortSnapshotTests`,
> `NotificationViewModelTests`, `StudyPlannerTests`, `AdminTests`, `BookmarkStoreTests`,
> `BookmarkViewModelTests`, `GroupStoreTests`, `GroupViewModelTests`) — plus
> **`Features/Library/MaterialLibraryView.swift`**, the one file where a member's lane meets the
> owner's, already described in the note under §2. **No member-vs-member overlap exists**, so the
> lane map still does the job it was built for; but on those 14 files the two agents are **M1 and
> one member**, and that edit is rebased before it is pushed, never forced.

> **Correction, 22 Oct 2026 — the lane map described directories, and the guard implemented files.**
> docs/14 and CONTRIBUTING have described each member's lane as a set of *directories* since the
> handover ("`Core/AI/`, `Features/{Flashcards,Summaries,Quizzes,Tutor}/`…"), but `tools/check-lane.sh`
> gave members only **individual file lists**, and `NEW` — the only directory mechanism it had —
> applies exclusively to files that **do not exist yet**. An audit of the tracked tree found the
> consequence: **167 of the 394 app files were in no lane at all**, including
> `Core/Scheduling/SpacedRepetition.swift` (which M2's own starter brief tells him to hand-write),
> all seventeen `Core/Payments/` files (M3's F13), the whole `Features/Admin/` screen set (M4's F12),
> and **the three files M5's own TODOs point at** — she could not have started. Every one of those
> would have produced the same `OUT OF LANE` that stopped M3 on the Coach screens. The guard now has
> a per-member `DIRS` list (the owner's `OWNED_DIRS`, applied to members), so a member's lane is the
> directories their features live in — existing files and new files alike. **Three files stay with
> someone else inside another member's directories**, and they are declared once in the guard's
> `CARVE_OUTS` rather than left to list order: `Core/Tutor/CohortSnapshot.swift` (M3), and
> `Core/Admin/AIConfiguration.swift` (M2), `Features/Groups/GroupChat*` + `Moderation/` (M5).
> Verified both ways in a clone: every member reaches the files their own brief names, and each
> carve-out is still refused to the member who does not own it. The previous version of this block
> read *69 files*; the count was re-measured from the file and the tree, not recounted by hand.

> **Correction, 22 Oct 2026 — this block read *49 files, M2 14 · M3 15 · M4 18 · M5 2*, and had
> been stale since 17 Oct**, when the Coach retrieval/planner files were given lanes because
> `LocalRetrievalService.swift` broke the stable-Xcode build and no member could fix it
> legitimately. Re-measured against `tools/check-lane.sh` rather than recounted by hand: **M2 19 ·
> M3 22 · M4 18 · M5 2 = 61** before this pass, **69** after it. The same pass gave
> `Features/Coach/` an owner — seven files that were in **no lane at all**, found by M3 while
> auditing her own F15 work — and gave M2 the one line of `Features/Library/` that F03 needs, so
> that `check-lane.sh M2` stops failing a member for a seam the lane map had left unowned. See
> the note under §2. **Counts are reproducible:** extract the four `TOUCH` arrays from
> `tools/check-lane.sh` and count them; the overlap check is a set intersection, not a reading.

`tools/check-lane.sh M2|M3|M4|M5` re-checks this on every commit and push, from the member's
own side:

| Situation | Result |
|---|---|
| On `main` or `develop` | refused, exit 1 |
| Detached HEAD | refused, exit 1 |
| Only that member's files changed | lane OK, exit 0 |
| A file from another member's area changed | STOP, exit 1 |
| A `docs/`, `deliverables/`, `tools/`, `backend/` or `.xcodeproj` file changed | STOP, exit 1 |
| A declared SHARED file changed | lane OK + a rebase protocol, exit 0 |

### The one structural reason conflicts are unlikely here

`ios/StudyForge/StudyForge.xcodeproj/project.pbxproj` uses
**`PBXFileSystemSynchronizedRootGroup`** for `StudyForge` and `StudyForgeTests`. Xcode
therefore syncs those folders automatically, so **adding a new `.swift` file does not
modify the project file** — normally the single worst conflict source in an Xcode
repository. The guard forbids touching the `.xcodeproj` regardless.

---

## 2. The lane map at a glance

| | M2 Mohammed | M3 Tasbeeh | M4 Shahad | M5 Fatema |
|---|---|---|---|---|
| **Branches** | `feat/F03-*` `F04-*` `F05-*` `F11-*` `F15-*` | `feat/F06-*` `F07-*` `F13-*` `F15-*` | `feat/F08-*` `F09-*` `F10-*` `F12-*` | `feat/F16-*` `F17-*` |
| **Owns** | **Directories:** `Core/{AI,Flashcards,Quizzes,Scheduling,Summaries,Tutor}/`, `Features/{Flashcards,Quizzes,Summaries,Tutor}/`. **Plus the files:** `Core/Admin/AIConfiguration.swift`, `Features/Coach/{CoachHome,CoachChat,CitationSheet}*.swift` (screens 73–76, 79, 80), `Features/Library/MaterialLibraryView.swift`. **Minus:** `Core/Tutor/CohortSnapshot.swift` (M3's) | **Directories:** `Core/{Payments,Planning,Progress}/`, `Features/{Progress,StudyPlan,Subscription}/`. **Plus the files:** `Features/Home/SignedInHomeView.swift`, `Core/Tutor/CohortSnapshot.swift`, `Features/Coach/StudyPath{View,ViewModel}.swift` (screens 77, 78) | **Directories:** `Core/{Admin,Bookmarks,Folders}/`, `Features/{Admin,Bookmarks,Folders,Groups}/`. **Plus the files:** `Core/Groups/{StudyGroup,LiveQuizSession,GroupStore,FileGroupStore,InMemoryGroupStore}.swift`. **Minus:** `Core/Admin/AIConfiguration.swift` (M2's), `Features/Groups/GroupChat*` + `Moderation/` (M5's) | **Directories:** `Core/{Recall,Groups/Moderation}/`, `Features/{Recall,Groups/Moderation}/`. **Plus the files:** `Features/Groups/GroupChatView.swift`, `GroupChatViewModel.swift` |
| **May add new files in** | `…/Core/AI/`, `…/Features/{Flashcards,Summaries,Quizzes,Tutor}/`, `StudyForgeTests/` | `…/Core/{Planning,Payments}/`, `…/Features/{StudyPlan,Progress,Subscription}/`, `…/Features/Coach/` (screen 78, P2 — not built yet), `StudyForgeTests/` | `…/Core/{Groups,Bookmarks,Folders}/`, `…/Features/{Folders,Bookmarks,Admin}/`, `StudyForgeTests/` | `…/Core/Groups/Moderation/`, `…/Core/Recall/`, `…/Features/Groups/Moderation/`, `…/Features/Recall/`, `StudyForgeTests/` |
| **Primary tester for** | F06, F12, F17 | F02, F08, F10, F14 | F04, F11, F16 | F01, F05, F13 |
| **May touch, with care** | `AppContainer.swift`, `en/ar Localizable.strings` | same | same | same |
| **Off limits to all** | `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`, `README.md`, `.mailmap`, `*.xcodeproj` — **this is the M2–M5 rule.** `check-lane.sh owner` treats the first five, plus `research/` and the repo-level files, as **the owner's own lane**; only `*.xcodeproj` is off limits to everyone. See the note below | | | |

> **Correction, 18 Oct 2026: `backend/` was forbidden to *everyone*, including the owner.** That
> contradicted [doc 10 §4](../docs/10-SPRINT-PLAN.md), which assigns **M1** the Firebase project and
> the rules skeleton in **S0**, and the security audit plus rules re-test in **S5** — the lane map
> forbade the one directory the plan gives the owner. `tools/check-lane.sh` now lists `backend/` in
> the owner's `OWNED_DIRS` and drops it from the owner's `FORBIDDEN_RE`. **It stays forbidden for
> M2–M5**, who never need it: their work is in `ios/`, and the emulator means they can run and test
> everything locally without touching the project. Verified both ways — the owner sees `yours`, and
> `check-lane.sh M2` still prints `FORBIDDEN` for the same files.

> **The one shared directory, and how it stays safe.** `Core/Groups/` and `Features/Groups/`
> are split by *file*, not by directory: **M4 owns the F09 group-space and live-quiz files at
> the top level, and M5 owns only the `Moderation/` subdirectory plus the two chat files.**
> This is the one place where two members' prefixes meet, and it is deliberate — F16 extends
> F09's chat. Before 14 Oct `GroupChatView.swift` and `GroupChatViewModel.swift` were in **no
> member's lane at all**, so nobody could modify them; they are now M5's.

> **The other split directory, added 22 Oct 2026: `Features/Coach/`.** F15 is the one feature
> two members own (docs/02 §5) and its screens are assigned **by name** in
> [doc 03 §H](03-SCREEN-INVENTORY.md) — **M2 has 73–76, 79 and 80; M3 has 77 and 78.** The files
> that draw them were in **no lane at all** until now, so the member doc 03 names as screen 77's
> owner could neither implement nor test it: `check-lane.sh M3` refused both files. Found by M3
> herself, in a read-only audit of her own F15 work, not by a failed build. Both halves now have
> their files — **M2 five, M3 two** — plus `…/Features/Coach/` in M3's NEW list for screen 78,
> which does not exist yet.
>
> **`Features/Library/MaterialLibraryView.swift` is the one file where a member's lane meets the
> owner's.** F03's entry point is the library's summarise sheet, M2's change there is **one line**
> (`SummaryFlowView` → `SummaryScreensView`, `48999d5`), and his handover file never named
> `Features/Library/` as off limits — so `check-lane.sh M2` was failing him on a seam the lane map
> had left unowned. It is his now; the owner keeps the rest of the directory (F02), and an edit
> there from either side is rebased before it is pushed, never forced.
>
> **Operational note, and it will bite somebody:** the guard runs from **your branch's own copy**
> of `tools/check-lane.sh`. A lane change therefore reaches you only once you merge or rebase
> `develop` into your branch — until then your branch still runs the old lists and refuses the
> files this note says are yours. Verified in both directions on 22 Oct 2026: `feat/F03-AI-SUMMARY`
> fails on the stale copy and passes after `develop` is merged in.

**Shared files** (all four members, 1–2 line edits only, rebase before pushing):
`App/AppContainer.swift` · `Resources/en.lproj/Localizable.strings` ·
`Resources/ar.lproj/Localizable.strings`

Only **M4 genuinely needs** a shared file — one line in `AppContainer` to select the
Firestore bookmark store. The M2, M3 and M5 handover files instruct the agent to prefer a
default-valued parameter so the container does not need to change at all, which removes
the shared file from their diffs entirely.

---

## 3. Tools that enforce this

| Tool | What it does |
|---|---|
| `tools/check-lane.sh M2\|M3\|M4` | **New.** Refuses protected branches and out-of-lane files; prints a per-file verdict. Run before every commit and push |
| `tools/check-lane.sh owner [--allow-protected]` | **Owner only.** The same guard for M1's lane (the project level plus F01/F02/F14). Members never need it, and none of you can use it: it refuses a member's app file just as `check-lane.sh M2` refuses `docs/`. The `--allow-protected` form is the owner's documented, loudly-printed hotfix path ([doc 12 §3.1](12-GIT-WORKFLOW.md)) |
| `tools/new-branch.sh feat/Fxx-slug` | Creates a correctly named branch from `develop` and pushes it |
| `tools/commit.sh [--push] [--multi]` | One file per commit, Conventional Commits, refuses `main`/`develop` |
| `tools/todos.sh` | Lists every in-code TODO grouped by owner |
| `python3 tools/check-strings.py` | English/Arabic key parity (912 keys, 910 until PR #134 lands) after any `.strings` change |
| `python3 tools/verify-docs.py` | Internal links, screen inventory, ownership integrity |
| `bash tools/check-submission.sh` | **The pre-submission gate.** Runs `verify-docs`, `check-strings`, `check-tokens` and `check-release`, then every section 4 and 5 item against its evidence. Exits non-zero while anything is open |
| `bash tools/check-tokens.sh` | Colour-token parity between `docs/06` section 1.1 and `ColorTokens.swift` |
| `bash tools/check-release.sh` | **New.** Fails when a whole directory exists on `develop` and is absent from `main`. Added after `main` was found **233 commits behind**, missing four evidence folders, unnoticed across 30 releases |

---

## 4. What M1 does after the three agents have run

```bash
# nobody should have committed to main or develop directly
git log --oneline origin/develop -10

# all five members must now appear, not just Saleh
git shortlog -sne --all

# each member's own commits
git log --author="Mohammed" --oneline
git log --author="Tasbeeh"   --oneline
git log --author="Shahad"    --oneline
git log --author="Fatema"    --oneline

# the per-member TODO count should have dropped from 3/3/3
bash tools/todos.sh

# the suite must still be green
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# the safety nets must still pass
python3 tools/verify-docs.py
python3 tools/check-strings.py
```

**The controlling sentence, worth repeating to each member.** *A strong teammate does not
raise your Sprints mark. Your own attributable, timestamped evidence is the only thing
that counts, and it has to exist before the sprint review, not be assembled after it.*
See [doc 13 §9](13-PER-MEMBER-TASKS.md).

