# Contribution Log, `Tasbeeh Saeed` · Sprint `2`

> **This file is my individual sprint evidence.** A row goes in **within 24 hours** of each session.
> Never back-fill a whole sprint at once — it reads as fabricated and defeats the purpose.
>
> Rules (from [doc 10 §6](../../../docs/10-SPRINT-PLAN.md)):
> - one row per work session
> - every row links to evidence a marker can open
> - **never** back-fill a whole sprint at once, it reads as fabricated

| Field | Value |
|---|---|
| **Name** | Tasbeeh Saeed |
| **Student ID** | `202305409` |
| **Sprint** | S2 |
| **Dates** | Mon 19 Oct to Sun 1 Nov 2026 |
| **My assigned tasks** | S2-M3: planner + cost governor; primary tester for F13 is now M5, so I keep F02, F08, F10, F14 — evidence: authored commits, rules-test result, 4 test logs (from [doc 10 §4](../../../docs/10-SPRINT-PLAN.md) and the [S2 goal](goal.md)) |

---

## Work log

| Date | Feature / task ID | What I personally did | Evidence (commit / PR / file) | Hours | Blocker |
|---|---|---|---|---|---|
| 20 Oct | F06 | Follow-up: removed the stale exam-date TODO; covered the exam-date changes and fixed the identity comparisons; opened the PR | `50ae6ae` `649a1c3` (both 20 Oct) · PR [#130](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/130) (created 20 Oct, merged 22 Oct, merge `196bf0b`; CI pass [run 39458663881](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/39458663881), iOS 7m16s) | 1.5 | |
| 22–23 Oct | F07 | Signed-in student home: the view, its view model, and the view-model test suite | `1bc7d7b` `1200751` `da71d06` (all 22 Oct) · PR [#133](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/133) (created 22 Oct, merged 23 Oct, merge `afd293f`; CI pass [runs 39854890334](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/39854890334) / [39857494140](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/39857494140)) | 4 | |
| 28 Oct | F13 | Audit of the whole subscription stack (~40 files: `Core/Payments/`, `Features/Subscription/`, the AI cost governor, backend functions) and the new business-rules, edge-case and status-matrix sections of the design document; 8 documentation files updated | **Not yet committed — whereabouts unverified**: the edits are not in any worktree status at the 6–7 Nov check and were never committed by me; `docs/` and `deliverables/` are the owner's lane, so M1 must confirm whether the owner commit route took them or the edits were lost | 3 | docs/deliverables are M1's lane — awaiting confirmation from M1 |
| 28 Oct | F13 / repo | Reviewed the five open PRs with substantive bodies; measured that #131's red `Repo checks` is the `OUT OF LANE` failure that #146 fixes, so the required merge order is #146 → #131; approved all five | reviews **APPROVED** at 2026-10-28T13:35:32Z on [#134](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/134) [#135](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/135) [#145](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/145) [#131](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/131) [#146](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/146) | 1 | |
| 28 Oct | F13 / R25 | Closed R25 (docs/09): pinned the AI daily budget reset to the injected clock with `budgetResetIgnoresLastRequestDate`, in a new in-lane test file — the suite the TODO names is in nobody's TOUCH list, so modifying it is OUT OF LANE for everyone | `0852bed` · PR [#147](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/147) (created and merged 28 Oct, merge `a65d4e5`; CI pass [runs 40700044119](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/40700044119) / [40700198017](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/40700198017), iOS 11m14s / 11m35s — the run this row waited for has concluded green) | 1 | no Xcode on this Windows machine (docs/18) — CI is the test evidence, quoted here once the run concludes |

## Sprint summary

- **Tasks completed:** F06 per-course exam dates finished and **merged** — PR [#130](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/130), opened 20 Oct, merged 22 Oct (merge `196bf0b`), Saleh approved, CI green ([run 39458663881](https://github.com/SalehAbdulla/IntelligentLearningPlatform/actions/runs/39458663881)); F07 signed-in student home implemented with its view-model test suite and **merged** — PR [#133](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/133), opened 22 Oct, merged 23 Oct (merge `afd293f`), Saleh approved, CI green (2 runs); R25 closed with the clock-pinned AI daily-budget regression test — PR [#147](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/147), created and merged 28 Oct (merge `a65d4e5`), Saleh approved ("a genuine regression pin"), CI green (2 runs); five teammate PRs reviewed with a documented lane/merge-order analysis and **approved** (all at 2026-10-28T13:35:32Z); the ~40-file F13 subscription-stack audit performed (work-log row above; commit route pending).
- **Tasks slipped (and why):** the F13 audit's `docs/`/`deliverables/` edits are still **uncommitted and their whereabouts unverified** — not in the working tree at the 6–7 Nov check and never committed by me; those paths are M1's lane, so M1 must confirm whether the owner route took them or the edits were lost; the four tester logs (**F02, F08, F10, F14**) and the emulator rules-test result were **not produced in S1 or S2** — outstanding; no `hand:`-tagged planner/cost-governor commits exist against the S1/S2 goal wording (`git log --grep="hand:"` is empty).
- **What I personally demoed at the review:** — no dated S2 demo artefact exists in the repo; outstanding against the sprint DoD.
- **What I learned / what I'd do differently:** — to be completed personally at the review (not evidenced here).

> **Post-sprint note (period boundary):** work dated **2–7 Nov** — PRs [#151](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/151) [#152](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/152) [#153](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/153) [#154](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/154), the published `feat/F06-session-reminders-granular` branch (38 commits, HEAD `0743dfab08dc91501b595e502ab24de73bc68e96`), and Saleh's CI-fix commit `710e3ec` — belongs to **S3 (2–15 Nov, [doc 10 §3](../../../docs/10-SPRINT-PLAN.md))** and is deliberately **not** recorded in this S1/S2 evidence; it will be recorded in the Sprint 3 contribution log.

## Evidence index

| Type | Link |
|---|---|
| Merged PRs I authored | [#130](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/130) (F06 exam dates, merged 22 Oct), [#133](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/133) (F07 student home, merged 23 Oct), [#147](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/147) (F13 R25 budget-reset pin, merged 28 Oct) |
| Hand-written commits | None tagged `hand:` (`git log --all --author="Tasbeeh" --grep="hand:"` → empty) — outstanding against the goal wording |
| Review notes on AI-generated code | Reviews of 28 Oct 2026, all **APPROVED** at 13:35:32Z: [#131](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/131) [#134](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/134) [#135](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/135) [#145](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/145) [#146](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/146) |
| Test logs (features I tested) | — **outstanding**: none for F02, F08, F10, F14 (`research/testing/` holds only F03/F07/F09/F15, authored by M1) |
| Sprint review recording / screenshots | — missing for S1 and S2 in the repo |
| Figma frames named `Tasbeeh_202305409` | `LF_77_Coach_StudyPath_Recommended_Tasbeeh_202305409.png`, `LF_78_Coach_QuizMe_Voice_Tasbeeh_202305409.png`, `LF_148`–`LF_154` (F17) under `deliverables/design-document/mockups/figures/` (authorship split recorded 24 Oct, `docs/TODOLIST.md`) |

## Honesty check, answer these before submitting

- [ ] Could I explain **every line** of what I claim to have done, if asked to open the file?
- [ ] Does my evidence appear **throughout** the sprint, not clustered on the last day?
- [ ] Did I actually **demo** my own work at the review, rather than describing it?
- [ ] Is there at least one piece of work I did **without** an AI tool?
