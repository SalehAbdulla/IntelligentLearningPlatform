# 12, Git Workflow: Branches, Commits & Pull Requests

> **Tutor guidance (confirmed):** using AI to write code is **acceptable**. What *is* required is a **branch-based workflow with meaningful, well-scoped commits, pushed regularly.**
>
> This document is the team's git contract. It is not housekeeping, git history is the primary evidence for the **Sprints (10%, individual)** component and for traceability in the **60% must-pass VIVA**.

---

## 1. Why this matters beyond tidiness

| Reason | Detail |
|---|---|
| **The tutor requires it** | Branches + meaningful commits are the stated expectation, not a preference |
| **Sprints are assessed individually (10%)** | Git history is the only scalable, timestamped proof of who did what, when |
| **The VIVA is must-pass (60%)** | A marker may ask "show me where your feature was built." Branch and commit history answers instantly |
| **LO3, professional standards** | A clean, conventional history is exactly what "documentation and programming conventions" means in practice |
| **It protects the demo** | `main` stays working; risky work lives on branches, so nothing half-finished reaches the demo build |
| **It makes AI-assisted work reviewable** | Since AI writes much of the code, small commits are the mechanism that makes review actually possible |

> **The one-line version:** *a branch per piece of work, a commit per file, a meaningful message on every commit, pushed every day.*

---

## 2. Branch model

```
main        ●───────────────●────────────────●───────────────  (stable, demo-ready, protected)
             ╲             ╱ ╲              ╱
develop       ●───●───●───●    ●───●───●───●                  (sprint integration, protected)
               ╲   ╱ ╲   ╱      ╲   ╱ ╲   ╱
feat/*          ●─●   ●─●        ●─●   ●─●                     (one feature per branch)
```

| Branch | Purpose | Who pushes to it | Protected? |
|---|---|---|---|
| **`main`** | Stable, always builds and runs. This is the demo/release line | **Nobody directly**, only merged from `develop` or `release/*` via PR | ✅ Yes |
| **`develop`** | Integration: the current state of the sprint | **Nobody directly**, only merged from feature branches via PR | ✅ Yes |
| **`feat/<Fxx>-<slug>`** | One feature, one branch, one owner | The feature's developer | No |
| **`fix/<slug>`** | A bug fix | Whoever finds and fixes it | No |
| **`docs/<slug>`** | Documentation only | Whoever writes it | No |
| **`chore/<slug>`** | Tooling, config, dependencies | Whoever owns it | No |
| **`release/sprint-<N>`** | Sprint freeze: final QA before `main` | Sprint lead | No |

### 2.1 Branch naming

```
feat/F04-sm2-scheduling
feat/F02-vision-ocr-extraction
feat/F15-rag-retrieval
fix/F13-tap-webhook-idempotency
docs/design-document-background-research
docs/sprint-2-retrospective
chore/firebase-emulator-config
release/sprint-3
```

**Rules:** lowercase · hyphenated · feature branches **must** carry the feature ID (that is what makes your sprint evidence searchable) · delete the branch after merge.

### 2.2 Which branch do I branch from?

- **Feature / fix / chore / docs work → branch from `develop`.**
- **Hotfix to a broken demo → branch from `main`**, then merge back into **both** `main` and `develop`.
- **Releasing to `main` → open a PR from `develop` into `main`.** Never push or fast-forward `main` directly; §3.1 explains why this is now enforced rather than advisory.

---

## 3. The golden rules

| # | Rule | Why |
|---|---|---|
| 1 | **Never commit directly to `main` or `develop`.** Always via a branch and a PR | Protects the demo build and creates review evidence |
| 2 | **One file per commit**, wherever the change is separable | The tutor's explicit requirement; makes history granular and attributable |
| 3 | **Every commit message is meaningful**, type, scope, and what changed | `update` or `fix stuff` is a non-commit |
| 4 | **Push at least once a day** while working | Continuous progress evidence is what the sprint component rewards |
| 5 | **Never rewrite pushed history** (no force-push to shared branches) | Others may have based work on it |
| 6 | **Never commit secrets**, `GoogleService-Info.plist`, keys, `.env` | Already gitignored; verify before every commit |
| 7 | **`main` must always build and run** | It is the demo line; a red `main` is the day's top priority |
| 8 | **Delete your branch after merge** | Keeps the branch list readable |

### 3.1 Enforcement, and the one deliberate exemption

Branch protection without `enforce_admins` was **advisory, not real**: a member could still
push straight to a protected branch, so the rule existed on paper only. Pull requests are what
produce the review evidence the Sprints and LO3 marks are read from, so the **PR requirement is
enforced for every member account**, and it is verified below.

**The repository owner is exempt from admin enforcement on purpose** (decided 8 Oct 2026).
There is one manager on this project, who already merges every PR; locking the manager out of
their own integration branch buys the team nothing. `enforce_admins` is therefore **off**, so
the owner may push directly, while every other account still has to go through a pull request.

| Setting | `main` | `develop` |
|---|---|---|
| Pull request required before merging | ✅ all members | ✅ all members |
| Admin enforcement (`enforce_admins`) | ❌ off, owner exempt by decision | ❌ off, owner exempt by decision |
| Force-push blocked | ✅ | ✅ |
| Branch deletion blocked | ✅ | ✅ |

What the exemption does **not** change:

- **The conventions, by default.** `tools/commit.sh` and `tools/check-lane.sh` still refuse
  `main`/`develop` for every account, the owner included. The exemption is **not silent**: the
  owner gets past those two guards only by asking for it —
  `bash tools/commit.sh --owner <path> "<message>"` or
  `bash tools/check-lane.sh owner --allow-protected` — and both print a warning naming this
  decision before they do anything. A member running either command is refused exactly as
  before, and neither flag relaxes the one-file-per-commit, Conventional-Commit or
  secret-scanning rules.
- **The members.** Their pushes to `main`/`develop` are still rejected:
  `GH006: Changes must be made through a pull request`.
- **The normal path.** Every feature, including the owner's own, still goes through a branch and
  a PR. The exemption buys exactly one thing: an owner-side hotfix path for a broken `main`.

**The owner's lane, without any bypass.** `bash tools/check-lane.sh owner` runs the same guard
against the owner's lane — the project level (`docs/`, `deliverables/`, `tools/`, `research/`,
`CONTRIBUTING.md`, `README.md`, `.github/`, `.vscode/`) plus the F01/F02/F14 app areas — and
still refuses `backend/` and the `.xcodeproj`. It is the flag-free form, so it is the one to run
before an ordinary owner commit: it catches a stray edit to a member's feature file (OUT OF LANE,
exit 1) while leaving the owner's own files green. `--allow-protected` is the only argument that
also permits `main`/`develop`.

**Verified live on 8 Oct 2026**, with the §11.1 command, on both branches:

```
main     pr_required=true enforce_admins=false force_push=false deletions=false
develop  pr_required=true enforce_admins=false force_push=false deletions=false
```

The check was run before the handover because the configuration had drifted from this section's
claim: `enforce_admins` was still **`true`**, which left the owner as protected as anyone else
and would have rejected the owner hotfix path below with `GH006`. It was corrected with the
surgical endpoint, which changes nothing but that one field:

```bash
gh api -X DELETE repos/SalehAbdulla/IntelligentLearningPlatform/branches/main/protection/enforce_admins
gh api -X DELETE repos/SalehAbdulla/IntelligentLearningPlatform/branches/develop/protection/enforce_admins
```

Before that change was applied, the collaborator list was checked (`gh api
repos/{owner}/{repo}/collaborators`): **no teammate account has admin**, so the exemption
exempts the owner alone. If the §11.1 command prints anything else at any point, the
configuration has drifted and this section is wrong.

**Emergency procedure.** A broken `main` can be fixed directly by the owner (the exemption is
already in place):

```bash
bash tools/check-lane.sh owner --allow-protected   # prints OWNER BYPASS, then checks the lane
bash tools/commit.sh --owner --push <path> "<message>"
```

Record what happened and why in the decision log. A member still needs a PR,
so if `develop` is broken and no reviewer is reachable, escalate to the owner rather than
disabling anything.

> **Lesson worth keeping:** a rule that can be silently bypassed is not a rule. That is why the
> PR requirement stays enforced for the members whose work is assessed, and why the guards live
> in executable tools (`tools/commit.sh`, `tools/check-lane.sh`) as well as in settings.

```
remote: error: GH006: Protected branch update failed for refs/heads/develop.
remote: - Changes must be made through a pull request.
 ! [remote rejected] develop -> develop (protected branch hook declined)
```

That test was run from a **member account** (while admin enforcement was still on) and it is the
expected result for every member today, because the PR requirement is unchanged. The owner is the
one exception, by the 8 Oct 2026 decision above.

---

## 4. Commit message format

Conventional Commits, with a **scope that names the feature or area**.

```
<type>(<scope>): <subject>

[optional body, why, not what]
[optional footer, refs]
```

| Type | Use for | Example |
|---|---|---|
| `feat` | New feature or capability | `feat(F04): SM-2 interval calculation and lapse handling` |
| `fix` | Bug fix | `fix(F13): verify Tap webhook signature before writing entitlement` |
| `test` | Tests only | `test(F12): add negative security-rules test for subscription writes` |
| `docs` | Documentation | `docs(F06): plan wizard flow diagram and acceptance criteria` |
| `refactor` | Restructure, no behaviour change | `refactor(F02): extract OCR chunking into MaterialExtractor` |
| `chore` | Config, dependencies, tooling | `chore: enable Firebase emulator suite locally` |
| `style` | Formatting only (rarely justified) | `style: apply swift-format to Features/Auth` |
| `perf` | Performance | `perf(F15): cache embeddings to avoid re-indexing on launch` |

**Scope values:** `F01`–`F15` for feature work · area scopes for everything else: `app`, `ios`, `firebase`, `tools`, `docs`, `ci`, `deps`, `release`.

**Subject rules:** imperative mood ("add", not "added") · no trailing full stop · under ~72 characters · says *what changed*, the body says *why*.

### 4.1 What "meaningful" means, bad vs good

| ❌ Not a meaningful commit | ✅ Meaningful |
|---|---|
| `update` | `feat(F03): add summary length selector (short / standard / exam-ready)` |
| `fix stuff` | `fix(F05): auto-submit quiz when the timer expires` |
| `changes` | `refactor(F06): move plan scheduling maths into StudyPlanner` |
| `wip` | `feat(F02): add Vision OCR page-offset extraction (WIP – no error path yet)` |
| `final` | `docs(design-doc): add competitor teardown table and references` |
| `asdfasdf` | `test(F04): cover SM-2 lapse case with a 21-day interval` |
| *5 files in one commit, no message* | *5 separate commits, each named for its own file* |

> **Test to apply before committing:** *could a marker read this message, open the diff, and understand what you did and why, without asking you?* If not, rewrite it.

---

## 5. The per-file commit workflow

Use `tools/commit.sh` (see §7) or do it by hand:

```bash
# ── 1. Start work: branch from develop ────────────────────────────────
git switch develop
git pull origin develop
git switch -c feat/F04-sm2-scheduling

# ── 2. Do the work (with whatever tools you like, AI is fine) ─────────

# ── 3. Commit ONE FILE at a time, each with its own meaningful message ─
git add ios/StudyForge/StudyForge/Core/Scheduling/SpacedRepetition.swift
git commit -m "feat(F04): implement SM-2 interval calculation"

git add ios/StudyForge/StudyForge/Features/Flashcards/FlashcardsViewModel.swift
git commit -m "feat(F04): wire SM-2 intervals into the review view model"

git add ios/StudyForge/StudyForge/Features/Flashcards/FlashcardReviewView.swift
git commit -m "feat(F04): show next-due interval under each rating button"

git add ios/StudyForge/StudyForgeTests/SpacedRepetitionTests.swift
git commit -m "test(F04): cover SM-2 lapse and interval-growth cases"

# ── 4. Push the branch (do this daily while working) ──────────────────
git push -u origin feat/F04-sm2-scheduling

# ── 5. Open a PR into develop, get it reviewed, merge ────────────────
gh pr create --base develop --title "feat(F04): flashcard spaced repetition" \
             --body-file .github/PULL_REQUEST_TEMPLATE.md
```

### 5.1 Why one file per commit (not one file per change)

A commit touching five files forces a reviewer to hold five unrelated thoughts at once, and it destroys attribution when several people work on the same feature area. One file per commit means:

- the diff is trivially reviewable
- `git log --follow <file>` gives a clean history per file
- blame is accurate
- a bad change is revertable in isolation
- the commit list reads as a **narrative of the work**, which is exactly what the sprint component assesses

**Exception:** a genuinely atomic multi-file change (e.g. a protocol and its only conformer) may share a commit, but say so in the message body.

---

## 6. Pull requests

Every branch reaches `develop` through a PR. Even if you review it yourself, **the PR body is evidence.**

| PR field | Requirement |
|---|---|
| **Title** | Conventional Commit style: `feat(F04): flashcard spaced repetition` |
| **Base** | `develop` (or `main` for a hotfix) |
| **Body** | Use `.github/PULL_REQUEST_TEMPLATE.md`, it asks for the feature ID, screens touched, rubric row affected, evidence, and a 3-sentence plain-English explanation |
| **Reviewer** | The named **tester** for that feature ([doc 02 §7](02-FEATURE-LIST-OWNERSHIP.md)) |
| **Evidence** | Test log, screenshots, or a recording |
| **CI** | Must build clean with zero warnings before merge |

**Merge style:** squash-merge is acceptable for a feature branch, but **do not squash your per-file commits into one**, the per-file history is the point. Use a regular merge commit, or rebase-merge which preserves individual commits.


---

## 7. Helper tooling

### `tools/commit.sh`, commit one file with a meaningful message, then push

```bash
# Commit a single file
bash tools/commit.sh <path> "feat(F04): implement SM-2 interval calculation"

# Commit several files, one commit each (path/message pairs)
bash tools/commit.sh --multi \
  SpacedRepetition.swift    "feat(F04): implement SM-2 interval calculation" \
  FlashcardsViewModel.swift "feat(F04): wire SM-2 intervals into the review view model"

# Commit and push the current branch
bash tools/commit.sh --push <path> "fix(F13): verify webhook signature"
```

The script enforces the rules for you: it **refuses to run on `main` or `develop`** (rule 1), **rejects a meaningless or non-conventional message** (rule 3), **blocks secret files and key contents** (rule 6), and warns if a commit bundles more than one file (rule 2).

### `tools/new-branch.sh`

```bash
bash tools/new-branch.sh feat/F04-sm2-scheduling
```
Creates a correctly-named branch from an up-to-date `develop` and pushes it with upstream tracking.

---

## 8. Command cheat sheet

```bash
# ── daily ──────────────────────────────────────────────────────────────
git switch develop && git pull                 # start from current integration
git switch -c feat/F07-progress-dashboard      # new branch for your work
git status                                     # what have I changed?
git add <one file> && git commit -m "type(scope): subject"
git push -u origin HEAD                        # push the branch, set upstream

# ── keep your branch current (do this daily on long branches) ─────────
git switch develop && git pull
git switch feat/F07-progress-dashboard
git rebase develop                             # or: git merge develop

# ── finish ────────────────────────────────────────────────────────────
gh pr create --base develop --fill            # open the PR
gh pr merge --merge --delete-branch          # merge, keep per-file commits, tidy up

# ── release to main (ALSO via PR, main is protected against direct pushes) ──
gh pr create --base main --head develop \
  --title "release(sprint-N): merge develop into main" \
  --body "Sprint N complete. Golden path verified. See research/sprints/sprint-N/."
gh pr merge --merge

# ── investigate (evidence for sprints and the VIVA) ───────────────────
git log --oneline --author="Saleh" --since="2 weeks ago"
git log --follow ios/StudyForge/StudyForge/Features/Flashcards/FlashcardsViewModel.swift
git log --grep="F04" --oneline
git shortlog -sn                              # commits per author
git diff develop...feat/F04-sm2-scheduling    # what this branch adds

# ── recover ───────────────────────────────────────────────────────────
git restore <file>                            # discard uncommitted changes
git revert <sha>                              # undo a pushed commit safely
git stash && git stash pop                    # park work temporarily
```

---

## 9. What this workflow produces as evidence

| Assessed component | What git gives the marker |
|---|---|
| **Sprints (10%, individual)** | Commits per author over time · branches per member · PRs authored and reviewed · daily-push pattern showing continuous progress |
| **iOS App (60%, must pass)** | `main` always builds · feature branches map to the 15 features · `git log --grep="F04"` traces a feature end to end |
| **VIVA** | Point at a branch, show the commits, open the diff, the work is provable in seconds |
| **LO3 (professional standards)** | Conventional Commits, conventional branching, PR templates, no secrets in history |

### 9.1 Reviewing your own evidence before each sprint review

```bash
# Everything I committed this sprint
git log --oneline --author="<my name>" --since="2 weeks ago"

# Changes I made myself (not AI-generated), see doc 10 §9 rule 4
git log --oneline --author="<my name>" --grep="hand:"

# My PRs
gh pr list --author="@me" --state all

# Any secret accidentally staged?
git log --all --name-only --pretty=format: | sort -u | grep -Ei 'plist$|\.env|secret|key\.'
```

If the first command returns a thin list, that sprint's individual mark is thin, and it is fixable that week, not at the VIVA.

---

## 10. Anti-patterns to avoid

| Anti-pattern | Why it hurts | Do this instead |
|---|---|---|
| Committing straight to `main` | Breaks the demo line; no review evidence | Branch from `develop`, PR back |
| One giant commit at the end of a sprint | Reads as fabricated; destroys granularity | Commit per file as you finish each file |
| `git commit -am "updates"` | Bundles unrelated files with a useless message | Stage and commit one file at a time |
| Force-pushing a shared branch | Destroys others' work and history | Revert instead; force-push only your own unshared branch |
| **A commit per file with no meaningful message**, technically split, still useless | The message is what makes the history readable | Name the file's role in the scope and subject (see §4.1) |
| Committing generated code you have never read | Fails the VIVA, not the commit | Review it, then commit it, and note what you changed |
| Long-lived branches (weeks) | Painful merges, stale code | Keep branches to a few days; rebase on `develop` daily |
| Committing `GoogleService-Info.plist` | Secret leak; must be rotated | It is gitignored, verify with `git status` before staging |

---

## 11. Setup checklist (Phase 0)

| # | Item | Status |
|---|---|---|
| 1 | `develop` branch created from `main` and pushed | ✅ done |
| 2 | Branch protection on **`main`**: PR required for members, force-push blocked, deletion blocked. Admin enforcement **off**: the owner is deliberately exempt (8 Oct 2026) | ✅ done |
| 3 | Branch protection on **`develop`**: PR required for members, force-push blocked, deletion blocked. Admin enforcement **off**: the owner is deliberately exempt (8 Oct 2026) | ✅ done |
| 4 | `.github/PULL_REQUEST_TEMPLATE.md` committed | ✅ done |
| 5 | `tools/commit.sh` + `tools/new-branch.sh` committed, executable and behaviour-tested | ✅ done |
| 6 | Full cycle demonstrated end to end (branch → per-file commits → PR → merge) | ✅ [PR #1](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/1) |
| 7 | Direct push to a protected branch **verified to be rejected from a member account** | ✅ tested, `GH006: Changes must be made through a pull request` |
| 8 | Every member sets `git config user.name` / `user.email` and confirms with `git shortlog -sn` | 🟨 **M1 ✅ done** (`.mailmap` committed, 4 aliases → 1). **M2, M3, M4 ⬜**, convention in [§12](#12-author-identities) |
| 9 | Every member practises the cycle once on a throwaway branch | ⬜ **each member, S0** |

### 11.1 Verify the setup

```bash
# What each branch actually enforces right now, from the API
for b in main develop; do
  printf '%-8s ' "$b"
  gh api repos/SalehAbdulla/IntelligentLearningPlatform/branches/$b/protection \
    --jq '"pr_required=\(.required_pull_request_reviews != null) enforce_admins=\(.enforce_admins.enabled) force_push=\(.allow_force_pushes.enabled) deletions=\(.allow_deletions.enabled)"'
done
```

Expected after the 8 Oct 2026 decision: `pr_required=true enforce_admins=false force_push=false deletions=false`.

- `pr_required=true` is what keeps the review trail for the members.
- `enforce_admins=false` is the owner exemption, deliberate: the owner may push directly, and
  `git push origin develop` from a **member** account still returns
  `GH006: Changes must be made through a pull request`.
- `force_push=false` and `deletions=false` apply to everyone, the owner included.

If the API returns **404**, the protection is implemented as a **ruleset** rather than classic
branch protection, and the equivalent read is:

```bash
gh api repos/SalehAbdulla/IntelligentLearningPlatform/rulesets
```

```bash
# Everyone is committing under their own name, not a shared one
git shortlog -sn --all
```

### 11.2 Per-member onboarding (hand this to each teammate)

```bash
git clone https://github.com/SalehAbdulla/IntelligentLearningPlatform.git
cd IntelligentLearningPlatform

git config user.name  "Their Full Name"
git config user.email "2023xxxxx@<their student email>"

git switch develop && git pull

# practise the whole cycle once on a throwaway branch
bash tools/new-branch.sh chore/practice-<theirname>
echo "practice" > "practice-<theirname>.txt"
bash tools/commit.sh --push "practice-<theirname>.txt" "chore: practise the branch and commit workflow"
gh pr create --base develop --fill
gh pr merge --merge --delete-branch
```

> ⚠️ **Note on this repository's own history:** the initial planning commits, made before this workflow was agreed, went directly to `main`. That is recorded here for honesty. **All work from Sprint S0 onward follows the branch model above**, see [doc 09 §2](09-RISKS-OPEN-QUESTIONS.md), decisions D17–D19.


---

## 12. Author identities

Sprint contribution is read off commit history, so **your commits must be traceable to you**. Git records whatever `user.name` / `user.email` are configured at commit time, and getting this wrong is invisible until a marker tries to count your work.

### The convention

Every member commits as:

```
Full Name <studentID@student.polytechnic.bh>
```

Set it **repo-locally** so it does not affect your other projects:

```bash
git config --local user.name  "Your Full Name"
git config --local user.email "<studentID>@student.polytechnic.bh"
```

| Member | Name | Student ID |
|---|---|---|
| M1 | Saleh Abdulla | `202300540` |
| M2 | Mohammed Almadhoon | `202401702` |
| M3 | Tasbeeh Saeed | `202300549` |
| M4 | Shahad Ashoor | `202305767` |

### Why a `.mailmap` exists

A person can easily accumulate several identities, a personal email from before the convention, a GitHub `noreply` address from merging a PR in the browser, or a typo. Each one splits your commit count in `shortlog`, so you appear to have contributed less than you did.

`.mailmap` fixes the **display** without rewriting history. Add a line per alias:

```
Canonical Name <canonical@email>  Alias Name <alias@email>
Canonical Name <canonical@email>  <alias@email>
```

> ⚠️ **A mailmap is a display layer only.** It does **not** rewrite commits, a raw `git log --format='%ae'` still shows the original address. To see canonical values you must use the mailmap-aware formats (`%aN`, `%aE`, **capital** letter). `git shortlog` is mailmap-aware by default.

### Verify

```bash
git shortlog -sne main                          # one line per member, correct emails
git log main --format='%aN <%aE>' | sort -u     # canonical  (mailmap-aware)
git log main --format='%an <%ae>' | sort -u     # raw        (ignores mailmap)
```

> ⚠️ Use **`main`**, not `--all`. `--all` includes every local ref, and tooling can
> leave extra ones behind, Cline checkpoints (`refs/cline/checkpoints/…`), for
> instance, showed **188** commits where `main` has **184**. Those refs are local and
> never pushed, but they inflate the count a marker would read.

All three lines above should agree on the *people* involved. If the third one shows more identities than the first two, an alias is missing from `.mailmap`, add it.

