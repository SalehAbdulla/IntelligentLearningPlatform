# 14, Per-member AI-agent handover

> **One file per member.** Hand the whole file to an AI coding agent and it has
> everything it needs: identity, the rules, the features, the open TODOs, the git
> protocol, the verification commands, and the definition of done.

| Member | Handle | Student ID | Handover file | Their features |
|---|---|---|---|---|
| **Mohammed Almadhoon** | M2 | `202401702` | [TODO-M2-mohammed.md](TODO-M2-mohammed.md) | F03 · F04 · F05 · F11 · F15 (co) |
| **Tasbeeh Saeed** | M3 | `202300549` | [TODO-M3-tasbeeh.md](TODO-M3-tasbeeh.md) | F06 · F07 · F13 · F15 (co) |
| **Shahad Ashoor** | M4 | `202305767` | [TODO-M4-shahad.md](TODO-M4-shahad.md) | F08 · F09 · F10 · F12 |

M1 (Saleh Abdulla, `202300540`) owns F01, F02 and F14 plus the cross-cutting document and
Figma work, and is not covered by these files.

**Why these files exist.** The **Sprints component (10%) is assessed per person** and the
**VIVA (60%) must be passed by every member**, and as of 8 Oct 2026 every commit in this
repository is authored by M1. Each handover file states a **hard acceptance criterion**:
*at least two of that member's features must carry a real, tested, committed change under
their own git identity.*

---

## 1. The conflict problem, and how it is solved

Three members will run agents against this repository **at the same time**. Two failure
modes are predictable and both are expensive:

| Failure mode | Defence |
|---|---|
| An agent commits to `main` or `develop` | GitHub branch protection with `enforce_admins: true` **rejects** the push; `tools/commit.sh` refuses locally; `tools/check-lane.sh` refuses locally |
| An agent edits another member's file, causing a merge conflict | **A disjoint file lane per member**, enforced by `tools/check-lane.sh` |

### Verified: the lanes do not overlap

**47 files** are reachable across the three members' *modify* lanes, and **zero of them is
claimed by two members.** The three lanes were checked programmatically:

```
TOUCH files            M2 14 · M3 15 · M4 18   (47 total)
claimed by two members : none
also declared SHARED   : none
```

`tools/check-lane.sh M2|M3|M4` re-checks this on every commit and push, from the member's
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

| | M2 Mohammed | M3 Tasbeeh | M4 Shahad |
|---|---|---|---|
| **Branches** | `feat/F03-*` `F04-*` `F05-*` `F11-*` `F15-*` | `feat/F06-*` `F07-*` `F13-*` `F15-*` | `feat/F08-*` `F09-*` `F10-*` `F12-*` |
| **Owns** | `Core/AI/`, `Features/Flashcards/`, `Features/Summaries/`, `Features/Quizzes/`, `Features/Tutor/`, `Core/Admin/AIConfiguration.swift` | `Core/Planning/`, `Core/Payments/`, `Features/StudyPlan/`, `Features/Progress/`, `Features/Subscription/`, `Features/Home/SignedInHomeView.swift`, `Core/Tutor/CohortSnapshot.swift` | `Core/Groups/`, `Core/Bookmarks/`, `Core/Folders/`, `Features/Groups/`, `Features/Folders/`, `Features/Bookmarks/`, `Features/Admin/` |
| **May add new files in** | `…/Core/AI/`, `…/Features/{Flashcards,Summaries,Quizzes,Tutor}/`, `StudyForgeTests/` | `…/Core/{Planning,Payments}/`, `…/Features/{StudyPlan,Progress,Subscription}/`, `StudyForgeTests/` | `…/Core/{Groups,Bookmarks,Folders}/`, `…/Features/{Groups,Folders,Bookmarks,Admin}/`, `StudyForgeTests/` |
| **Primary tester for** | F06, F12, F13 | F02, F08, F10, F14 | F01, F04, F05, F11 |
| **May touch, with care** | `AppContainer.swift`, `en/ar Localizable.strings` | same | same |
| **Off limits to all** | `docs/`, `deliverables/`, `backend/`, `tools/`, `.github/`, `README.md`, `.mailmap`, `*.xcodeproj` | | |

**Shared files** (all three members, 1–2 line edits only, rebase before pushing):
`App/AppContainer.swift` · `Resources/en.lproj/Localizable.strings` ·
`Resources/ar.lproj/Localizable.strings`

Only **M4 genuinely needs** a shared file — one line in `AppContainer` to select the
Firestore bookmark store. The M2 and M3 handover files instruct the agent to prefer a
default-valued parameter so the container does not need to change at all, which removes
the shared file from their diffs entirely.

---

## 3. Tools that enforce this

| Tool | What it does |
|---|---|
| `tools/check-lane.sh M2\|M3\|M4` | **New.** Refuses protected branches and out-of-lane files; prints a per-file verdict. Run before every commit and push |
| `tools/new-branch.sh feat/Fxx-slug` | Creates a correctly named branch from `develop` and pushes it |
| `tools/commit.sh [--push] [--multi]` | One file per commit, Conventional Commits, refuses `main`/`develop` |
| `tools/todos.sh` | Lists every in-code TODO grouped by owner |
| `python3 tools/check-strings.py` | English/Arabic key parity (910 keys) after any `.strings` change |
| `python3 tools/verify-docs.py` | Internal links, screen inventory, ownership integrity |

---

## 4. What M1 does after the three agents have run

```bash
# nobody should have committed to main or develop directly
git log --oneline origin/develop -10

# all four members must now appear, not just Saleh
git shortlog -sne --all

# each member's own commits
git log --author="Mohammed" --oneline
git log --author="Tasbeeh"   --oneline
git log --author="Shahad"    --oneline

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

