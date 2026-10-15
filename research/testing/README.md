# Test logs

> **Why this folder exists.** The Sprints component (10%) is assessed **per person**, and one of the
> things it rewards is *being the named tester for a feature and producing a real test log* — see
> [doc 10 §2](../../docs/10-SPRINT-PLAN.md) and [doc 13](../..//docs/13-PER-MEMBER-TASKS.md).
> The rule that makes it worth anything: **nobody tests a feature they developed.** Every log here
> is written by the person named as the **primary tester** in
> [doc 02 §7](../../docs/02-FEATURE-LIST-OWNERSHIP.md), not by the developer.

## Naming

```
F<xx>-<firstname>.md          e.g. F03-saleh.md, F15-saleh.md
```

One file per **feature tested**, not per session. The name is distinct per person so two testers
never collide.

## What a log must contain

| Section | Why |
|---|---|
| **What was run** | The exact command, so the result can be reproduced rather than believed |
| **Observed result** | The **real** output. Never a summary you wrote before running it |
| **Cases covered** | Which behaviours were exercised, and which were not |
| **Manual / on-device pass** | What a unit test cannot prove: layout, states, offline, VoiceOver |
| **Defects found** | The honest answer. **Finding a real defect beats a clean pass** — but never invent one |
| **Verdict** | Pass, pass-with-notes, or fail, and what it blocks |

## The honesty rule

A log that says *"all tests passed"* and nothing else is worth very little, because it records no
judgement. A log that says *"the store round-trips correctly, but I could not verify the Firestore
implementation because no live project is configured — here is what I did verify instead"* is worth
a great deal. **State what you did not test.**

## Files

| Log | Feature | Tester | Developer |
|---|---|---|---|
| [`F03-saleh.md`](F03-saleh.md) | AI Summary & Notes | **M1 Saleh** | M2 Mohammed |
| [`F07-saleh.md`](F07-saleh.md) | Progress Tracking | **M1 Saleh** | M3 Tasbeeh |
| [`F09-saleh.md`](F09-saleh.md) | Group Revision Spaces | **M1 Saleh** | M4 Shahad |
| [`F15-saleh.md`](F15-saleh.md) | AI Study Companion *(advanced)* | **M1 Saleh** | M2 + M3 |
