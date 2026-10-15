# Sprint S2, Per-Member Plan

| Field | Value |
|---|---|
| **Sprint** | S2 |
| **Dates** | Mon 19 Oct to Sun 1 Nov 2026 |
| **Sprint lead** | M1, Saleh Abdulla |
| **Theme** | Assessment engine, the Design Document deadline, and the fifth member's ramp-up |
| **Fixed constraint inside this sprint** | 🚩 **Design Document due Thu 22 Oct 2026, 23:55** |

> Sprint labels follow the assumed five-sprint cadence in [doc 01 §1](../../../docs/01-ROADMAP-PHASES-TODOLIST.md) and [doc 10 §3](../../../docs/10-SPRINT-PLAN.md). Confirm with the tutor ([doc 09 Q9](../../../docs/09-RISKS-OPEN-QUESTIONS.md)) and renumber if the course defines its own boundaries.

## Sprint goal, one sentence

> *"The assessment engine runs on real data, the Design Document is submitted on time with all 17 features in it, and the member who joined on 14 Oct has two authored, tested, committed features of her own."*

The third clause is deliberate. M5 joined mid-project on **14 Oct 2026**; her sprint evidence starts now, in her own name, and cannot be created at the end.

## Demoable outcome

1. Generate and take a real quiz; a study plan is generated; the progress dashboard is populated from real data.
2. The Design Document is submitted by **22 Oct**, covering all **17 features** and all **154 frames**.
3. **F17's Recall Space** gathers cards due across more than one deck, and **F16's moderator** cannot be removed.
4. Every member demonstrates something they personally built, fixed, tested or documented.

## Per-member tasks

| Member | Task ID | What they own this sprint | Evidence they produce |
|---|---|---|---|
| **M1** Saleh | S2-M1 | Land the fifth member and F16/F17 through every planning doc and the tooling **before 22 Oct**; F01/F02/F14 stay green; test F03, F07, F09, F15 | merged docs PR, green `verify-docs`/`check-lane`, 4 test logs |
| **M2** Mohammed | S2-M2 | F03/F04/F05/F11 stay green; **primary tester for F17**; F15 moves forward | authored commits, F17 test log, AI-accuracy notes |
| **M3 Tasbeeh** | S2-M3 | Planner + cost governor; **primary tester for F13 is now M5**, so M3 keeps F02, F08, F10, F14 | authored commits, rules-test result, 4 test logs |
| **M4 Shahad** | S2-M4 | F08 shared folders; **primary tester for F16**; Figma P0 for groups F, G, I | merged feature, frames, F16 test log |
| **M5 Fatema** | S2-M5 | **F17** Recall Space: cross-deck queue, learning steps, daily limits, session + tests; **F16** moderator model and the "cannot be removed" rules; Figma groups **N** and **O** (frames 142–154) | two features merged, 13 frames named `Fatema_202304804`, test logs for F01/F05/F13 |

## Risks this sprint

| Risk | Likelihood | Response |
|---|---|---|
| The Design Document deadline is **8 days** into the sprint | High | The doc and tooling changes for M5/F16/F17 land first, in one PR, gated by `python3 tools/verify-docs.py` |
| M5's features are not yet in the document when it is submitted | Medium | F16/F17 were added to the document, the frame inventory and the rubric matrix **before** the sprint began |
| Four members still have thin commit history | High | [doc 13](../../../docs/13-PER-MEMBER-TASKS.md) and each member's handover file: review, correct, test, commit under your own identity |
| Contribution logs get back-filled at the end | Medium | Fill them within 24h of each session, per [doc 10 §6](../../../docs/10-SPRINT-PLAN.md) |

## Definition of done (from [doc 10 §8](../../../docs/10-SPRINT-PLAN.md))

- [ ] The demoable outcome demos live, from the real app
- [ ] The Design Document is submitted by 22 Oct, covering all 17 features
- [ ] Every member demonstrated something they personally built or fixed
- [ ] Every member's contribution log is written and evidence-linked
- [ ] Slipped scope recorded and re-planned
- [ ] `main` builds clean, zero warnings, tests pass

## Sprint artefacts checklist

- [ ] `goal.md` (this file)
- [ ] `board.png`, task board snapshot at sprint end
- [ ] `review.mp4` or `review/`, each member demoing their own work
- [ ] `retro.md`, one thing to keep, one to change
- [ ] `saleh-contribution.md` · `mohammed-contribution.md` · `tasbeeh-contribution.md` · `shahad-contribution.md` · `fatema-contribution.md`