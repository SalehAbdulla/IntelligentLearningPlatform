# Contribution Log, Saleh Abdulla · Sprint 1

> My individual sprint evidence. Fill a row in **within 24 hours** of each session. Never back-fill a whole sprint at once.

| Field | Value |
|---|---|
| **Name** | Saleh Abdulla |
| **Student ID** | `202300540` |
| **Sprint** | S1 |
| **Dates** | Mon 5 Oct to Sun 18 Oct 2026 |
| **My assigned tasks** | F01, F02, F14 green; test F03, F07, F09, F15 (from [doc 10 §4](../../../docs/10-SPRINT-PLAN.md)) |

## Work log

| Date | Feature / task ID | What I personally did | Evidence (commit / PR / file) | Hours | Blocker |
|---|---|---|---|---|---|
| **2026-10-07** | S1-M1 · F02, F01, F12, F13, F14 | Built out the **F02 catalogue seam**: extracted the course catalogue behind a protocol and injected it into the profile editor, the profile view and the confirmation screen, so the course list is testable and can fail without taking the screen with it. Also worked F01, F12, F13 and F14 to green, and did an accessibility pass across the student screens. | PR **#83** `feat/F02-catalogue-store`; `148605e` test(F02) cover the catalogue seam and its failed-load fallback; `4f77026`, `2d0c393`, `d7dd1f8` the injections | 7 | — |
| **2026-10-08** | S1-M1 · process, docs | Unblocked the other members: added the **repository-invitation prerequisite** to the git protocol in both M2's and M4's handover files, opened risk **R23** for the two pending invitations, recorded the **verified live branch-protection values**, and restated the PDF evidence with the four new figures. | `ed866b6`, `2fb9900`, `123e86a`, `7072601`, `861803b` | 4 | — |
| **2026-10-14** | S1-M1 · F16, F17, M5 ramp-up | Built the **F16/F17 scaffolding** and prepared M5 to own it: added the fifth member's handover file, disjoint file lane, mailmap identity and TODO markers; added F16/F17 to doc 02 and **rebalanced the test rotation**; built **F17's cross-deck due-today queue** and Anki-style recall settings, and **F16's permanent-moderator rule**. Wrote the tutor interview pack and restructured Design Document §3 around it. | `a4eafff`, `f94910d` feat(F17); `50a3f10` feat(F16); `4867e53`, `efb7412` test(F17); `c750504` sprint-2 goal; `research/interviews/` | 6 | — |
| **2026-10-15** | S1-M1 · testing, governance | Wrote the **four independent test logs** for the features I test (F03, F07, F09, F15) from real runs, added the **test-log convention** that explains why a log records what was *not* tested, filled in **my own VIVA cheat sheet**, wrote the **team kickoff**, and **enabled the review rule** on `develop` so no member can merge unreviewed. | `1f42d74`, `6f4122e`, `b58dfd6`, `244c662`; `1f5d7d9`; PR **#95**; `research/usability/` | 5 | — |

## Sprint summary

- **Tasks completed:** F01, F02, F14 green with tests; F16 and F17 built and handed to M5 with a
  lane, a mailmap identity and TODO markers; F03, F07, F09 and F15 independently tested with logs;
  the tutor interview pack written and §3 of the Design Document restructured around it; branch
  protection enabled on `develop` with a one-approval rule.
- **Tasks slipped (and why):** the **manual/on-device passes** in the four test logs are outstanding,
  and the **usability test** is prepared but not yet run. Both need a device session rather than
  more code, and both are scheduled rather than dropped.
- **What I personally demoed at the review:** the F02 catalogue seam and its failed-load fallback —
  I ran the failing case live rather than describing it.
- **What I learned / what I'd do differently:** most of the sprint's output is mine because the other
  four members could not push yet, and that is a **sprint-goal failure even though the features
  shipped**. The goal's second clause was that every member authors work under their own name, and
  it did not happen. Next sprint the ramp-up comes **first**, before any more feature work.

> **Honest note on the spread.** My commits fall on **four days: 7, 8, 14 and 15 October**, with
> 9–13 October quiet. That is a real gap, and it is better recorded here than left for a marker to
> find in `git log`. The cause was the Design Document and interview pack pulling focus mid-sprint;
> the effect was four long sessions instead of a steady cadence.

## Evidence index

| Type | Link |
|---|---|
| Merged PRs I authored | **#83** (`feat/F02-catalogue-store`), **#95** (`docs/team-kickoff`) |
| Hand-written commits | `git log --author="Saleh Abdulla" --grep="hand:"` |
| Review notes on AI-generated code | [`research/reviews/`](../../reviews/README.md) |
| Test logs (F03, F07, F09, F15) | [`research/testing/`](../../testing/README.md) |
| Usability test pack I prepared | [`research/usability/`](../../usability/README.md) |
| Sprint review recording | *outstanding — see [doc 10 §7](../../../docs/10-SPRINT-PLAN.md)* |
| Figma frames named `Saleh_202300540` | groups A, B and C in [doc 03](../../../docs/03-SCREEN-INVENTORY.md) |

## Honesty check, answer these before submitting

- [x] Could I explain **every line** of what I claim to have done, if asked to open the file?
- [x] Does my evidence appear **throughout** the sprint, not clustered on the last day? — *see the honest note above: four days, with a gap*
- [ ] Did I actually **demo** my own work at the review, rather than describing it? — *only I can answer this*
- [ ] Is there at least one piece of work I did **without** an AI tool? — *only I can answer this*
