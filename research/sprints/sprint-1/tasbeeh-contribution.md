# Contribution Log, Tasbeeh Saeed · Sprint 1

> My individual sprint evidence. Fill a row in **within 24 hours** of each session. Never back-fill a whole sprint at once.

| Field | Value |
|---|---|
| **Name** | Tasbeeh Saeed |
| **Student ID** | `202305409` |
| **Sprint** | S1 |
| **Dates** | Mon 5 Oct to Sun 18 Oct 2026 |
| **My assigned tasks** | Own F06, F07, F13, F15; test F02, F08, F10, F14 (from [doc 10 §4](../../../docs/10-SPRINT-PLAN.md)) |

## Work log

| Date | Feature / task ID | What I personally did | Evidence (commit / PR / file) | Hours | Blocker |
|---|---|---|---|---|---|
| 18 Oct | F06 | Per-course exam dates: plan model and store, planner never schedules a subject on or after its exam, wizard deadline-step capture, plus the storage and planner test suites | `4ca72a6` `9472e06` `e280843` `50335f6` `5c16fca` `8a420e3` `72e1f39` | 4 | |
> **Sprint boundary ([doc 10 §3](../../../docs/10-SPRINT-PLAN.md)):** this log keeps only **S1 (5–18 Oct)** sessions. The rows originally drafted here for **20 Oct, 22–23 Oct and 28 Oct** fall inside **S2 (19 Oct – 1 Nov)** and are preserved — with their CI evidence completed — in the [Sprint 2 contribution log](../sprint-2/tasbeeh-contribution.md). PR #130 spans both sprints (implemented 18 Oct here; opened 20 Oct and merged 22 Oct there) and is counted **once** as a single feature deliverable.

## Sprint summary

- **Tasks completed:** Ownership of F06, F07, F13 and F15 taken under my name (S1-M3, [doc 10 §4](../../../docs/10-SPRINT-PLAN.md) and the [S1 goal](goal.md)) — **ownership only for F15: no F15 implementation code was written in S1 or S2.** My F15 artefacts this period are the Figma frames named `Tasbeeh_202305409` (`LF_77`, `LF_78`), listed in the [Sprint 2 log](../sprint-2/tasbeeh-contribution.md); the F15 code scope remained untouched. In one S1 session on **18 Oct** the per-course exam-date feature was implemented end to end — plan model and store, planner never schedules a subject on or after its exam, wizard deadline-step capture, plus the storage and planner test suites — as 7 commits (`4ca72a6` `9472e06` `e280843` `50335f6` `5c16fca` `8a420e3` `72e1f39`, all 18 Oct, author `Tasbeeh Saeed`). PR [#130](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/130), opened 20 Oct and merged 22 Oct, completes this work; those events fall in S2 and are recorded there (one feature, split by session date, **not counted twice**).
- **Tasks slipped (and why):** PR #130's follow-up, review and merge slipped past S1's end into S2. The S1-M3 evidence items **not produced in S1**: the four tester logs (F02, F08, F10, F14), the emulator rules-test result, and any `hand:`-tagged planner/cost-governor commits (`git log --all --author="Tasbeeh" --grep="hand:"` is empty) — all outstanding as of this log. The S1 sprint artefacts `board.png`, `review.mp4` and `retro.md` are also absent from `research/sprints/sprint-1/` (group-level gap).
- **What I personally demoed at the review:** — no dated S1 demo artefact exists in the repo; outstanding against the sprint DoD.
- **What I learned / what I'd do differently:** — to be completed personally at the review (not evidenced here).

## Evidence index

| Type | Link |
|---|---|
| Merged PRs I authored | [#130](https://github.com/SalehAbdulla/IntelligentLearningPlatform/pull/130) (F06 exam dates — implemented 18 Oct in S1; opened 20 Oct, merged 22 Oct in S2; merge `196bf0b`) |
| Hand-written commits | None tagged `hand:` (`git log --all --author="Tasbeeh" --grep="hand:"` → empty) — outstanding against the S1-M3 goal |
| Review notes on AI-generated code | — none in S1 (the five approvals of 28 Oct are S2 evidence, recorded in the [Sprint 2 log](../sprint-2/tasbeeh-contribution.md)) |
| Test logs (F02, F08, F10, F14) | — **outstanding**: none produced in S1 (`research/testing/` holds only F03/F07/F09/F15, authored by M1) |
| Emulator rules-test result | — outstanding (not produced in S1) |
| Sprint review recording | — missing for S1 (no recording in `research/sprints/sprint-1/`) |
| Figma frames named `Tasbeeh_202305409` | — none dated within S1; the frame set (`LF_77`, `LF_78`, `LF_148`–`LF_154`) is listed in the [Sprint 2 log](../sprint-2/tasbeeh-contribution.md) |
