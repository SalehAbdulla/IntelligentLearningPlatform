# 13, Per-Member Task Todos

> Operational, tickable task list, one section per member. Derived from the allocation in [doc 10 §4](10-SPRINT-PLAN.md) and the ownership in [doc 02](02-FEATURE-LIST-OWNERSHIP.md). Every task below produces evidence a marker can **open**, because the Sprints component is assessed per person and the VIVA requires that every member can explain and demo any part.

**Why this file exists, stated plainly.** As of writing, every commit in this repository is authored by **M1**. The Sprints component (10%) is assessed **individually**, and the VIVA (60%, must pass) requires **every member** to explain and demonstrate parts of the app. With no attributed commits, **M2, M3 and M4 currently have no individual sprint evidence**, which is a real risk to both marks. This file, plus the per-member artefacts it points at, is the fix. Work started from here on is attributed; work already done by M1 stands as M1's and is not back-fillable.

---

## 0. Every member, before anything else (about 30 minutes)

- [ ] Set your git identity **repo-locally**, exactly as [doc 12 §12](12-GIT-WORKFLOW.md) specifies, so your commits are attributable:
  ```bash
  git config --local user.name  "Your Full Name"
  git config --local user.email "<studentID>@student.polytechnic.bh"
  ```
- [ ] Read [doc 10 §5](10-SPRINT-PLAN.md) (the only evidence that counts) and [§9](10-SPRINT-PLAN.md) (the comprehension contract).
- [ ] Confirm your identity in [`.mailmap`](../.mailmap) so `git shortlog` counts you correctly.
- [ ] Work on your **own branch** per feature, branched from `develop`: `bash tools/new-branch.sh feat/Fxx-short-slug`, and commit with `bash tools/commit.sh <path> "feat(Fxx): ..."`. Never commit to `main` or `develop`.
- [ ] Copy `research/sprints/TEMPLATE-contribution.md` to `research/sprints/sprint-<N>/<yourname>-contribution.md` and fill it **within 24 hours** of each work session. Do not back-fill a whole sprint at once, it reads as fabricated.
- [ ] Copy `research/cheatsheets/TEMPLATE.md` to `research/cheatsheets/<yourname>.md` and keep it current from now to the freeze.

> **The honest route for a feature already built by M1:** you cannot claim authorship of code you did not write. You **can** own it by reviewing it, finding and fixing a real defect, writing and running its tests, documenting it, and demoing it. That is legitimate contribution and it is exactly what the comprehension contract rewards.

---

## M1, Saleh Abdulla (`202300540`)

**Develops:** F01 (auth and roles), F02 (upload and library), F14 (notifications).
**Tests:** F03, F07, F09, F15.

- [ ] Keep F01/F02/F14 green; add any missing error and empty states.
- [ ] Write and commit **test logs** for the four features you test (F03, F07, F09, F15) in `research/testing/`.
- [ ] **Split the codebase so others can own it:** hand each member their feature's key files and a 5-line explanation, so they can begin reviewing and correcting.
- [ ] Author the **sprint review recording** and the per-sprint goal for the current sprint (`research/sprints/sprint-<N>/goal.md`).
- [ ] Keep the security model current: rules + emulator tests as F12/F13 land.
- [ ] Cheat sheet: `research/cheatsheets/saleh.md`.

## M2, Mohammed Almadhoon (`202401702`)

**Develops:** F03 (summary), F04 (flashcards and SM-2), F05 (quiz), F11 (tutor studio), F15 (co: RAG and retrieval).
**Tests:** F06, F12, F13.

- [ ] **Take ownership of your five features.** Open each in the app, read the code, and find at least one real improvement per feature; commit it yourself (`git log --author` must show you).
- [ ] Own the **AI-quality story**: write prompt-evaluation notes and an accuracy review of generated summaries, cards and quiz answers (this is a headline innovation, §13 items 1, 2).
- [ ] Hand-write the parts that matter: the **SM-2 interval maths** and the **retrieval scoring**, so there is at least one piece of your work with no AI tool behind it.
- [ ] Write and commit **test logs** for F06, F12, F13 in `research/testing/`.
- [ ] Demo your own features at the sprint review.
- [ ] Cheat sheet: `research/cheatsheets/mohammed.md`.

## M3, Tasbeeh Saeed (`202300549`)

**Develops:** F06 (study plan), F07 (progress), F13 (subscription and payments), F15 (co: planner and AI router).
**Tests:** F02, F08, F10, F14.

- [ ] **Take ownership of your four features.** Read the code, make a real change in each, and commit it under your own name.
- [ ] Own the **architecture and payments** story: document the `PaymentGateway` abstraction and the Tap sandbox flow (the ethics finding in the design document §16.1 is yours to defend).
- [ ] Hand-write the parts that matter: the **scheduler / planner** logic and the **AI cost-governor** budget maths.
- [ ] Write and commit **test logs** for F02, F08, F10, F14 in `research/testing/`.
- [ ] Run the **emulator rules tests** and record the result (security is a coding-convention and LO3 talking point).
- [ ] Demo your own features at the sprint review.
- [ ] Cheat sheet: `research/cheatsheets/tasbeeh.md`.

## M4, Shahad Ashoor (`202305767`)

**Develops:** F08 (shared folders), F09 (group spaces), F10 (bookmarks), F12 (admin).
**Tests:** F01, F04, F05, F11.

- [ ] **Take ownership of your four features.** Read the code, make a real change in each, and commit it under your own name.
- [ ] Own the **UI/UX and accessibility** story: run the VoiceOver, Dynamic Type (AX5), contrast and RTL passes and record the evidence (this is your contribution to the must-pass VIVA and to SDG 10).
- [ ] Own the **Figma prototype**: the frames already carry your student ID (`Shahad_202305767`); extend and wire them, and produce the `.fig` export checkpoint.
- [ ] Write and commit **test logs** for F01, F04, F05, F11 in `research/testing/`.
- [ ] Coordinate the **sprint review recording** so every member is filmed demoing their own work.
- [ ] Cheat sheet: `research/cheatsheets/shahad.md`.

---

## Every sprint, every member, these artefacts

A member does not count as having contributed in a sprint until these exist for that sprint:

- [ ] `research/sprints/sprint-<N>/goal.md` includes your row in the per-member table (task ID, what you own, the evidence you will produce).
- [ ] `research/sprints/sprint-<N>/<yourname>-contribution.md` is filled in **as you go**, one row per session.
- [ ] At least one **authored commit or PR** on a feature you own or test (`git log --author="<you>"`).
- [ ] A **test log** for any feature you are the named tester of.
- [ ] You **demoed your own work** at the sprint review (recorded).
- [ ] `research/cheatsheets/<yourname>.md` is current.

## How a marker reads this

| They look at | They should find |
|---|---|
| `git shortlog -sne main` | four names, each with a real, spread-out commit count |
| `git log --author="<you>"` | commits through the sprint, not one dump on the last day |
| `research/sprints/sprint-N/` | a goal, a contribution log per member, a retro, a review recording |
| `research/testing/` | test logs where the tester is not the developer |
| `research/cheatsheets/` | one page per member that answers "where does this live and why?" |
| The Figma file | frames named with each member's own student ID |

> **The controlling sentence:** a strong teammate does not raise your Sprints mark. Your own attributable, timestamped evidence is the only thing that counts, and it has to exist **before** the review, not be assembled after it.

---

## Starter briefs: turnkey first commits (prepared by M1, 7 Oct 2026)

> M1's task in section **M1** is "split the codebase so others can own it". These three briefs do that: each is one real TODO from the code, with the files, the seam, the acceptance criterion and the exact commit to make. The work stays the teammate's to read, change, test and commit, so the git history stays theirs.

### M2: track "Hard" separately from "correct" in SM-2

- **TODO:** `ios/StudyForge/StudyForge/Features/Flashcards/FlashcardReviewViewModel.swift:119`
- **What it is:** a "Hard" grade is an SM-2 *success*, but it is not the same as "Good" or "Easy", so the session summary currently folds it into `correctCount`.
- **Key files:** `FlashcardReviewViewModel.swift` (rating to count), `Core/Scheduling/SpacedRepetition.swift` (the SM-2 maths), `Features/Flashcards/FlashcardReviewView.swift` (the summary that shows the counts).
- **Done when:** the summary reports Hard distinctly, and a Swift Testing case in `StudyForgeTests/FlashcardReviewViewModelTests.swift` proves a Hard grade is counted separately. Delete the TODO marker.
- **Suggested:** branch `feat/F04-hard-grade-tracking`; commit `feat(F04): track the Hard grade separately in the session summary`.

### M3: per-course exam dates that feed the planner

- **TODO:** `ios/StudyForge/StudyForge/Core/Planning/StudyPlan.swift:100` (docs/09 Q11)
- **What it is:** exam dates belong on the *plan*, not the profile, so a date cannot go stale; they have to reach the planner.
- **Key files:** `Core/Planning/StudyPlan.swift` (the model), `Core/Planning/StudyPlanner.swift` (the scheduler, which should weight a near exam harder), `Features/StudyPlan/StudyPlanWizardView.swift` (capture UI).
- **Done when:** dates can be entered and stored on the plan, the planner uses them, and a test proves a nearer exam changes the plan.
- **Suggested:** branch `feat/F06-exam-dates`; commit `feat(F06): capture per-course exam dates and feed the planner`.

### M4: a Firestore-backed BookmarkStore

- **TODO:** `ios/StudyForge/StudyForge/Core/Bookmarks/BookmarkStore.swift:14` (docs/05 §2.5)
- **What it is:** the bookmarks screen shows an empty store today; a Firestore implementation behind the existing protocol is what makes it demonstrable and survives a reinstall.
- **Key files:** `Core/Bookmarks/BookmarkStore.swift` (the protocol), `App/AppContainer.swift` (the single injection point), `Features/Bookmarks/*` (already written against the protocol).
- **Done when:** the implementation exists (`collections/{id}`, `bookmarks/{id}`, owner-only), `AppContainer` can select it, and a test proves a round-trip. Delete the TODO marker.
- **Suggested:** branch `feat/F10-firestore-bookmarks`; commit `feat(F10): add a Firestore-backed BookmarkStore`.

> Each brief ends the same way: a reviewed, tested, committed change under the teammate's own git identity, plus a two-line note in `research/sprints/sprint-<N>/<name>-contribution.md`. That is exactly the evidence the "How a marker reads this" section looks for.

<!-- ##APPEND## -->