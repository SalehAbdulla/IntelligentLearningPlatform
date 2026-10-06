# Sprint S1, Per-Member Plan

| Field | Value |
|---|---|
| **Sprint** | S1 |
| **Dates** | Mon 5 Oct to Sun 18 Oct 2026 |
| **Sprint lead** | M1, Saleh Abdulla |
| **Theme** | Core loop MVP, and getting all four members contributing under their own names |

> Sprint labels follow the assumed five-sprint cadence in [doc 01 §1](../../../docs/01-ROADMAP-PHASES-TODOLIST.md) and [doc 10 §3](../../../docs/10-SPRINT-PLAN.md). Confirm with the tutor ([doc 09 Q9](../../../docs/09-RISKS-OPEN-QUESTIONS.md)) and renumber if the course defines its own boundaries.

## Sprint goal, one sentence

> *"Every feature of the core loop demonstrably works, and every member has authored, tested, documented and demoed at least one piece of work under their own name."*

The second clause is deliberately in the goal. Sprint evidence is assessed per person, and it cannot be created at the end.

## Demoable outcome

1. The core loop runs on a device: sign up, upload a real PDF, get a grounded summary, generate cards, review them.
2. Each member demonstrates something they personally built, fixed, tested or documented.
3. `main` builds clean and the unit suite passes.

## Per-member tasks

| Member | Task ID | What they own this sprint | Evidence they produce |
|---|---|---|---|
| **M1** Saleh | S1-M1 | F01/F02/F14 green; test F03, F07, F09, F15; hand the other members their files | merged PRs, 4 test logs, sprint goal + review |
| **M2** Mohammed | S1-M2 | Take ownership of F03/F04/F05/F11/F15; hand-write SM-2 + retrieval; test F06, F12, F13 | authored commits, AI-accuracy notes, 3 test logs |
| **M3** Tasbeeh | S1-M3 | Take ownership of F06/F07/F13/F15; hand-write the planner + cost governor; test F02, F08, F10, F14 | authored commits, rules-test result, 4 test logs |
| **M4** Shahad | S1-M4 | Take ownership of F08/F09/F10/F12; accessibility + RTL passes; Figma wiring; test F01, F04, F05, F11 | authored commits, a11y evidence, 4 test logs |

## Risks this sprint

| Risk | Likelihood | Response |
|---|---|---|
| Three members have no committed contribution yet | High | [doc 13](../../../docs/13-PER-MEMBER-TASKS.md): each member reviews, corrects and tests their own features, and commits under their own identity |
| Contribution logs get back-filled at the end | Medium | Fill them within 24h of each session, per [doc 10 §6](../../../docs/10-SPRINT-PLAN.md) |

## Definition of done (from [doc 10 §8](../../../docs/10-SPRINT-PLAN.md))

- [ ] The demoable outcome demos live, from the real app
- [ ] Every member demonstrated something they personally built or fixed
- [ ] Every member's contribution log is written and evidence-linked
- [ ] Slipped scope recorded and re-planned
- [ ] `main` builds clean, zero warnings, tests pass

## Sprint artefacts checklist

- [ ] `goal.md` (this file)
- [ ] `board.png`, task board snapshot at sprint end
- [ ] `review.mp4` or `review/`, each member demoing their own work
- [ ] `retro.md`, one thing to keep, one to change
- [ ] `saleh-contribution.md` · `mohammed-contribution.md` · `tasbeeh-contribution.md` · `shahad-contribution.md`
