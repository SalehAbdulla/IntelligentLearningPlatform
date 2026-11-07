# Contribution Log, `Saleh Abdulla` · Sprint `2`

> **This file is my individual sprint evidence.** A row goes in **within 24 hours** of each session.
> Never back-fill a whole sprint at once — it reads as fabricated and defeats the purpose.
>
> Rules (from [doc 10 §6](../../../docs/10-SPRINT-PLAN.md)):
> - one row per work session
> - every row links to evidence a marker can open
> - **never** back-fill a whole sprint at once, it reads as fabricated

| Field | Value |
|---|---|
| **Name** | Saleh Abdulla |
| **Student ID** | `202300540` |
| **Sprint** | S2 |
| **Dates** | Mon 19 Oct to Sun 1 Nov 2026 |
| **My assigned tasks** | S2-M1: land M5 and F16/F17 through every planning doc and the tooling **before 22 Oct**; keep F01/F02/F14 green; test F03, F07, F09, F15 (from [doc 10 §4](../../../docs/10-SPRINT-PLAN.md)) |

---

## Work log

| Date | Feature / task ID | What I personally did | Evidence (commit / PR / file) | Hours | Blocker |
|---|---|---|---|---|---|
| **2026-10-19** | S2-M1 · risks & a flaky test | Costed two open risks (R26, Q14/R25) against the code rather than a guess, and made the countdown test wait on the countdown instead of on the CI runner. | PR **#127** `docs/q14-r25-decision` · **#128** `fix/flaky-countdown-test` · **#129** `docs/todolist-126-128` |  | — |
| **2026-10-22** | S2-M1 · lanes, CI & M2's merge | Made the lane rules **machine-checked** rather than documentary and corrected the published status claims; landed Mohammed's F03 (AI summaries) work on his behalf. | PR **#131** `docs/coach-lane-and-member-audit` · **#135** `feat/F03-ai-summary` |  | — |
| **2026-10-23** | S2-M1 · F06 lane boundary & Design Document | Added the two F06 exam-date keys in **M1's own lane** — the boundary that stopped M3 — and froze the Design Document submission state with the rebuilt PDF. | PR **#134** `fix/f06-exam-date-copy` · **#136** `docs/design-document-submission` |  | — |
| **2026-10-24** | S2-M1 · Design Document & usability | Built the Design Document **Word export** in the university template, the §17.3 usability pack (protocol, consent, SUS scorer), the tracked submission bundle/zip, and the M5 tester-row corrections. | PR **#137**–**#144** |  | — |
| **2026-10-27** | S2-M1 · checklist reconciliation | Reconciled the stale `docs/01`, `docs/08` and `docs/10` checklists against the artefacts — every box that moved carries a dated verdict **and** the artefact it was checked against. | PR **#145** `docs/reconcile-stale-checklists` |  | — |
| **2026-10-28** | S2-M1 · Tier-1 AI, lanes & demo | Ran the **Tier-1 cloud AI provider** myself and recorded its lane exception deliberately rather than bypassing it; fixed the guard so every member can commit their own contribution log; corrected two Phase-5 claims; wrote the demo AI-key run sheet. | PR **#146** · **#148** `chore/lane-contribution-logs` · **#149** `docs/phase5-nav-bar-and-counts` · **#150** `docs/demo-ai-key` |  | — |
| **2026-10-30** | S2-M1 · pre-VIVA prep | Wrote the owner's pre-VIVA task list into the demo run sheet, recorded for the next session. | `7b9125f` `docs/demo-ai-key` |  | — |

---

## Sprint summary

- **Tasks completed:** F16/F17 landed and named through every planning doc and the tooling before 22 Oct; the **Tier-1 cloud AI provider** built and wired (lane exception recorded); the Design Document **Word export**, submission bundle and usability pack; the lane guard made **machine-checked**; the stale checklists reconciled. F01/F02/F14 stayed green.
- **Tasks slipped (and why):** the **§17.3 usability test** (needs five participants), the **P5-16 walkthrough recording**, and the **portal submission** — all human actions, none of them engineering. Recorded rather than dropped.
- **What I personally demoed at the sprint review:** *(to confirm — only I can answer this)*
- **What I learned / what I'd do differently:** *(to confirm — only I can answer this)*

## Evidence index

| Type | Link |
|---|---|
| Merged PRs I authored | **#127**–**#150** (per-row mapping in the work log above) |
| Hand-written commits (`git log --author="Saleh" --grep="hand:"`) | `git log --author="Saleh Abdulla" --grep="hand:"` |
| Review notes on AI-generated code | [`research/reviews/`](../../reviews/README.md) |
| Test logs (features I tested) | [`research/testing/`](../../testing/README.md) — F03, F07, F09, F15 |
| Sprint review recording / screenshots | *outstanding — needs a filmed review* |
| Figma frames named with my student ID | groups A, B, C and `LF_142`–`LF_147` in [doc 03](../../../docs/03-SCREEN-INVENTORY.md) |

## Honesty check, answer these before submitting

- [ ] Could I explain **every line** of what I claim to have done, if asked to open the file?
- [ ] Does my evidence appear **throughout** the sprint, not clustered on the last day?
- [ ] Did I actually **demo** my own work at the review, rather than describing it?
- [ ] Is there at least one piece of work I did **without** an AI tool?

---

> **Honest note on the spread — I must confirm this before submitting.** These rows were
> reconstructed from the merged pull requests on **7 Nov 2026**, not entered within 24 hours of each
> session as the rule above asks. The **dates and evidence links are real** — every row names a
> merged PR or a commit hash — but the **hours are left blank on purpose**: only I can put an honest
> number in that column, and a filled-in column I did not write reads as fabricated. I will replace
> this note with the true spread once I have set the hours, and I will state which sessions an AI
> tool helped with and which it did not.
