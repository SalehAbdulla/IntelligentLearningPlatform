# TODO — Tasbeeh Saeed · M3 · `202305409`

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

## ⚡ The four things that actually go wrong — read this before anything else

**Every problem a member has hit so far has been one of these four.** They take ten minutes to get
right, and they are what the Sprints mark — **10%, assessed individually** — is read from.

| # | Do this | **Not** this | What goes wrong otherwise |
|---|---|---|---|
| **1** | `git config --local user.email "202305409@student.polytechnic.bh"` | your GitHub or personal email | A commit under an address that is not your student address is **invisible to `git shortlog`** — the work exists and counts for nobody. `.mailmap` cannot rescue an address that was never yours |
| **2** | `bash tools/new-branch.sh feat/F06-study-plan` | `git switch -c` by hand | The tool branches from **current `develop`** and refuses an invalid name. A hand-made branch was once **84 commits behind** `develop`, carried 32 unrelated merge commits, and had uppercase in its name that no tool would accept |
| **3** | `bash tools/commit.sh <file> "feat(F06): …"` | `git commit -m "…"` | The tool refuses a non-conventional message, refuses `main`/`develop`, and scans for secrets. Messages like `configure view` and `updates` have been committed by hand instead, and none of them survive the rubric |
| **4** | `gh pr create --base develop --fill` **the same day** | leaving it local and pushing later | **CI runs on every push to a feature branch now**, so a broken push goes red in ~11 minutes. A branch with **no PR** is invisible: one member's did not compile for hours and nobody knew |

> **The one-line version:** *set your identity, branch with the tool, commit with the tool, open the
> PR.* In that order, every time.

> **And expect your PR to sit "blocked" until it has one approving review.** `develop` requires it
> ([doc 12 §3.1](12-GIT-WORKFLOW.md)) and GitHub will not let you merge it yourself. **That is the
> process working, not a rejection.** Post the link in the group chat and it gets reviewed — but plan
> for the review to take a day, so a PR opened the night before a deadline will not be merged by it.

---

## ⚡ DO THIS FIRST — a review today (15 minutes, and it unblocks the whole team)

**Added 28 Oct 2026 by M1.** Five pull requests are `MERGEABLE` and **not one of them has a single
review**. `develop` requires one approving review, so nothing can merge — including the one-line
change that unblocks the rest. Yours would be the first pair of eyes the team has had.

```bash
bash tools/review-packet.sh 146     # start here — one line, about fifteen seconds to read
bash tools/review-packet.sh 131     # the big one: the rules, the CI step, the AI lane
bash tools/review-packet.sh 145     # docs only, no code
bash tools/review-packet.sh 135     # F03 AI summaries — Mohammed's screens
bash tools/review-packet.sh 134     # F06 — the two exam-date copy keys, YOUR feature
```

The packet prints what the PR *claims*, the files where the risk is (biggest diffs first), the tests
that are the proof, and the three questions to answer. Then leave the review:

```bash
gh pr review <number> --approve --body "Reviewed. Checked: ..."
gh pr review <number> --comment --body "path/File.swift:120 — <what is wrong>"
```

**`--comment` is a real outcome.** Finding something is worth more than an approval nobody meant, and
it still counts as your work. What is **not** an outcome is an approval produced by the packet and not
by reading the diff.

**#134 is your own feature** — `F06`, the two exam-date copy keys — so reviewing it is also the
quickest way to see what "done" looks like in this repository before you write your own.

### Then the part that actually carries your mark

**Measured 28 Oct 2026 from `git shortlog -sne origin/develop`:** you have **12 commits on
`develop`** and **two merged pull requests** — #130 (F06, exam dates) and #133 (F07, student home).
That is clean work: every subject is a Conventional Commit, **one file per commit**, and the messages
say *what changed* rather than *that something changed*. It is the standard this repository asks for,
and you are already meeting it.

> **A correction to this file, and it matters.** An earlier version of this section said *"your lane
> has shipped nothing — 0 branches, 0 commits, 0 reviews"*. **That was wrong**, and the way it was
> wrong is worth knowing because an agent will make the same mistake: the measurement used
> `git log --author=tasbeeh`, and **git's `--author` is case-sensitive**, so a lowercase pattern
> matched none of your `Tasbeeh Saeed` commits. `git shortlog -sne` is the tool that cannot lie about
> this, and it credits you with all twelve. If you ever measure contribution, use that one.

**What is genuinely at zero is your review count** — and that is what the top of this file is about.
`research/sprints/sprint-1/tasbeeh-contribution.md` is also still empty. The Sprints component is
**10%, assessed per person**, and the VIVA (60%) has to be passed by every member.

**Start with R25 in [§3](#3-my-open-todos-confirm-with-bash-toolstodossh)** — it is decided, it is
under an hour, and it is inside your lane.

### The commit rule, for your agent — one file, one message

**One file per commit, with a subject that says what changed.** This is not a style preference: it is
what makes a change reviewable, revertable, and attributable to a feature.

```bash
bash tools/commit.sh path/To/File.swift "feat(F06): never schedule a subject on or after its exam"
```

`tools/commit.sh` writes **one commit per file**, refuses a non-conventional subject, refuses
`main`/`develop`, and scans for secrets. Several files in one run is fine — pass `<path> "<message>"`
pairs, one pair per file, or use `--multi`. What is never fine is `git commit -am "update"`, or
`git add .` followed by a single message: a commit carrying eight files cannot be reviewed, cannot be
reverted, and names no feature.

**CI enforces the same rules server-side** (`tools/check-commits.sh`, run on every push), and it reads
the rules **from `develop`** — so no branch can relax them. A subject already pushed cannot be
reworded without a force-push, which [doc 12 §5](12-GIT-WORKFLOW.md) forbids; the only other remedies
are an allowlist entry with a written reason or a rewrite agreed with the team. **Get it right at the
commit.**

**Your own twelve are the model:** `4ca72a6 feat(F06): store per-course exam dates on the plan` is one
file, one idea, and a subject that will still make sense in six months.

> **One identity note, so your agent does not "fix" it:** your earlier commits are authored as
> `202300549@student.polytechnic.bh` — two digits transposed. `.mailmap` maps that to your real ID
> `202305409`, which is why `git shortlog` credits you with all twelve. **Do not rewrite those
> commits.** New commits must use `202305409`, as the first table row above says.

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
feat/F06-<slug>    feat/F07-<slug>    feat/F13-<slug>    feat/F15-<slug>
```

```bash
bash tools/new-branch.sh feat/F06-exam-dates
bash tools/new-branch.sh feat/F07-student-home
```

Never `git switch develop` to "just quickly fix something". Never `git push origin main`.

### Rule 2 — your own files

**You may modify these** (and nothing else):

| Area | Yours |
|---|---|
| **F06 · F07 · F13 — everything in these directories** | `Core/Planning/` · `Core/Payments/` · `Core/Progress/` · `Features/StudyPlan/` · `Features/Progress/` · `Features/Subscription/` |
| F06/F07 named files | `Features/Home/SignedInHomeView.swift` (F07's home) · `Core/Tutor/CohortSnapshot.swift` (F07's tutor metrics) |
| F15 screen 77 (+ 78) | `Features/Coach/StudyPathView.swift` · `StudyPathViewModel.swift` · and `Features/Coach/` for screen 78, which does not exist yet |
| Tests | `StudyForgeTests/StudyPlannerTests.swift` · `NotificationViewModelTests.swift` · `CohortSnapshotTests.swift` |

> **Corrected 22 Oct 2026 — your lane used to be a list of individual files, and it was too small.**
> All **seventeen** files in `Core/Payments/` already existed and **none** was in your lane, so the
> F13 work your brief describes could not be started; the same was true of `Core/Progress/`, and of
> the two `Features/Coach/StudyPath*` files that implement screen 77 — the screen the inventory names
> you as the owner of. An audit of the tracked tree found **167 of the 394 app files were in no lane
> at all**. Your lane is now the **directories** your features live in, existing files and new ones
> alike. Full detail: [doc 14 §2](14-COLLEAGUE-AI-AGENT-PROMPTS.md).

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
git config --local user.email "202305409@student.polytechnic.bh"
```

> **⚑ 23 Oct 2026 — your student ID was corrected: `202300549` → `202305409`.** The old one
> transposed two digits, and it had propagated into every roster, the tooling, your git config
> and this file. **Use `202305409@student.polytechnic.bh` from now on.** Three things worth
> knowing:
>
> - **Your merged commits keep the old address, and that is fine.** They were pushed and merged
>   before the correction, and rewriting merged history is not an option. `.mailmap` now maps the
>   old address to you, so `git shortlog` still counts all **12** of them — verified, it reads
>   `12  Tasbeeh Saeed <202305409@student.polytechnic.bh>`. If a marker asks, that is the answer.
> - **Type the domain in lower case** (`student.polytechnic.bh`, not `Student.`). The check that
>   reads identities matches the domain case-sensitively. The capitalised form is aliased too, so
>   it will not fail — but lower case is the convention and the safer habit.
> - **The old ID still appears in the Figma frame suffix** (`Tasbeeh_202300549`), in the 18 mockup
>   PNG filenames, and in the Design Document that lists them. Those are artifact *names* rather
>   than identities, and renaming them means editing the Figma file and rebuilding the PDF — a
>   separate decision, not yet taken. Nothing you need to do about it.

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

> **⚑ 23 Oct 2026 — two lines waiting for you, and they close the last F06 copy defect.**
> The review of your F06 PR recorded one thing rather than waving it through: the per-course
> exam-date rows reuse the subjects heading, so the word *"exam"* never appears on screen, and the
> toggle and the date control in each row carry **the same** accessibility label. You wrote the
> same seam into the code yourself — *"`Core/Localisation/` sits in M1's OWNED_DIRS, so editing
> `L10n.swift` would put this commit outside M3's lane. If the team wants the word 'exam' spelled
> out per row, M1 adds a key and this becomes a one-line swap."* **M1 has now added the keys** —
> `plan.examDatesHeading` ("When are your exams?") and `plan.examDateLabel` ("Exam date"), with
> their Arabic copy, in **PR #134**. The two lines that *use* them are yours, because
> `Features/StudyPlan/` is your lane and an owner edit there would be refused by the guard exactly
> as your edit of `L10n.swift` was. **Do not "tidy away" the two keys** — they are unused until
> these two lines land, and that is deliberate.
>
> ```swift
> // ios/StudyForge/StudyForge/Features/StudyPlan/StudyPlanWizardView.swift
> // 1. in `perSubjectExamDates` — the heading now says what the rows are
> -            Text(viewModel.subjectsHeading)
> +            Text(L10n.planExamDatesHeading.string)
>
> // 2. in `examDateRow` — the date control stops being labelled with the subject alone
>                  )
>                  .font(.sfBody)
> +                .accessibilityLabel("\(subject), \(L10n.planExamDateLabel.string)")
> ```
>
> ```bash
> bash tools/new-branch.sh feat/F06-exam-date-copy
> bash tools/check-lane.sh M3        # that one file is yours — it should pass first time
> bash tools/commit.sh --push ios/StudyForge/StudyForge/Features/StudyPlan/StudyPlanWizardView.swift \
>   "fix(F06): label the exam-date rows and their date controls"
> gh pr create --base develop --fill
> ```
>
> **And the other thing only you can do:** `research/sprints/sprint-1/tasbeeh-contribution.md` is
> still an empty template. Your two merged PRs (`196bf0b`, `afd293f`) are attributable and real,
> but the Sprints component — **10%, assessed per person** — is read off that file, and a log
> filled in at the end reads as back-filled. Two rows now beat six rows later.

**F06 — per-course exam dates that feed the planner — ✅ DONE, merged as `196bf0b` (PR #130)**
`ios/StudyForge/StudyForge/Core/Planning/StudyPlan.swift:100` — the marker is gone from the code
Exam dates belong on the **plan**, not the profile, so a date cannot go stale
(docs/09 Q11).
Files: `Core/Planning/StudyPlan.swift` (the model) · `Core/Planning/StudyPlanner.swift`
(the scheduler, which should weight a near exam harder) ·
`Features/StudyPlan/StudyPlanWizardView.swift` (wizard step 3 of 4, which already draws
a "+ Add deadline" control).
*Done when:* dates can be entered and stored on the plan, the planner avoids scheduling
after them, and a test covers a plan that respects one.

**F07 — the real student home (B05) — ✅ DONE, merged as `afd293f` (PR #133)**
`ios/StudyForge/StudyForge/Features/Home/SignedInHomeView.swift:148` — the placeholder and its
`TODO(M3 · F07)` marker are gone; the designed home exists, and `StudentHomeViewModel` +
`StudentHomeViewModelTests` (7 tests) are yours
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

### ⚑ 28 Oct 2026 — R25 is DECIDED, and the fix is yours. It is under an hour, inside your lane.

**R25** (docs/09 §1) is the highest-scoring open risk on the register and **its owner is you**:
the paywall advertises **three** plan limits and only **one** is enforced. The owner decided it on
**28 Oct 2026 — Option 2: stop advertising the two limits the app does not enforce** — and
deliberately did **not** write it, because `Features/Subscription/` and `Core/Payments/` are your
lane, and because this is the one change that turns a promise the product does not keep into a
claim it does. **Two files, no new dependency, one test** — the cheapest real contribution left on
the project, and it is F13, your feature.

| | |
|---|---|
| **Files** | `Features/Subscription/PlanCompareView.swift` (lines 45–46) · `Features/Subscription/PaymentViewModel.swift` (lines 157–158) |
| **The seam** | both call `plan.includedMaterials` / `plan.includedGroupSpaces`, which exist **only for display**: `grep -rn 'includedMaterials' ios/` outside `PaymentCatalogue` and the tests returns these two files and nothing else. **Do not delete the `PaymentCatalogue` values or their tests** — `PaymentCatalogueTests` asserts 20/200/∞ and 1/5/∞, and those assertions stay green |
| **What to do** | remove the *materials* and *group spaces* comparison rows from `PlanCompareView`'s table and from `PaymentViewModel`'s `DetailRow` list, so the paywall sells what is genuinely metered (**AI generations/day**, which *is* enforced by `AICostGovernor`) and what is genuinely unlimited (**on-device AI, on every tier including Free**). If it reads thin without them, say so in the plan and let the owner decide — do not silently keep a row you cannot enforce |
| **Acceptance test** | a **new** Swift Testing file in `StudyForgeTests/` — e.g. `PaywallHonestLimitsTests.swift` — asserting the entitlement rows **no longer contain** the `materials` and `groups` ids while the AI-allowance row **still does**. **Do not edit an existing test file.** `PaywallViewModelTests`, `PaymentFlowViewModelTests`, `PaymentCatalogueTests` and `DeveloperAccountSwitcherTests` appear in **no member's TOUCH list** — your `StudyForgeTests/` entry is a **NEW-files prefix**, not a licence to modify what is already there. **Nothing needs updating anyway**, verified 28 Oct 2026: **no test asserts those two rows** (the only `detailRows` assertions are `StudyPlanViewModelTests`, a different view model), and `PaymentCatalogueTests` asserts the catalogue *values* — 20/200/∞ and 1/5/∞ — which stay green because the catalogue is not touched |
| **Branch / commit** | `bash tools/new-branch.sh feat/F13-paywall-honest-limits` · `feat(F13): stop advertising the two plan limits the app does not enforce` |
| **Done when** | `grep -rn 'includedMaterials\|includedGroupSpaces' ios/StudyForge/StudyForge/Features/` returns **nothing**, the tests above pass, and the R25 line in `docs/TODOLIST.md` §8 can be ticked |

> **Why this is a contribution and not a tidy-up.** A marker reads the paywall and asks *"is the
> limit enforced, or just displayed?"* — one grep away. Option 1 (wiring the caps) is the better
> end state and is recorded as follow-on work, but it crosses `Features/Materials/` and
> `Features/Groups/` and cannot be done honestly in the time left. **Option 2 is the fix that
> cannot make the product dishonest.**

> ### ⚠️ Status check, 28 Oct 2026 — R25 is still OPEN, and here is exactly what remains
>
> M3 shipped real work that day: `ios/StudyForge/StudyForgeTests/AICostGovernorResetTests.swift`
> (PR #147 — `Repo checks` **and** `iOS build and test` both green), pinning the AI daily budget
> reset to the **clock** rather than to the last request. Good work, and it is F13's — **but it is
> not R25.** R25's own `Done when` is a grep, and it still fails:
>
> ```text
> $ grep -rn 'includedMaterials\|includedGroupSpaces' ios/StudyForge/StudyForge/Features/
> Features/Subscription/PaymentViewModel.swift:157
> Features/Subscription/PaymentViewModel.swift:158
> Features/Subscription/PlanCompareView.swift:45
> Features/Subscription/PlanCompareView.swift:46
> ```
>
> **Four lines, two files, still advertising two limits the app does not enforce.** Everything above
> the table still stands: remove those four rows, add the acceptance test
> (`PaywallHonestLimitsTests.swift` — asserting the `materials` and `groups` rows are **gone** while
> the AI-allowance row **remains**), and R25 is closed. Under an hour, inside your lane, and still the
> highest-scoring open risk on the register.
>
> **The two blockers that held it up are fixed**, in PR #148: `AICostGovernorTests.swift` is now in
> M3's `TOUCH` list, and the rule that refused **every** member their own contribution log is
> corrected. Both must land on `develop` before they take effect — that is the guard's bootstrap
> property, not an oversight.

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
bash tools/check-lane.sh M3      # lane still clean. Needs WSL or Git Bash — see docs/18
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


