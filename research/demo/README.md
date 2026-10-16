# Demo evidence

> **Why this folder exists.** The iOS App Implementation & Demonstration component is **60% and
> MUST PASS**, and [doc 11 §3](../../docs/11-APP-IMPLEMENTATION-VIVA.md) sets four controls so a
> single failed step cannot cost the whole mark. Two of those four controls produce evidence, and
> **that evidence has nowhere to live until this folder exists**:
>
> - **Control 3 — the golden-path regression**, run **3× a week from S3**, *"logged with pass/fail"*
> - **Control 4 — the recorded backup**, *"re-recorded after any change to those screens"*
>
> A control that is not logged is a claim, not a control. This folder is where the log goes.

## What lives here, and what does not

[doc 11](../../docs/11-APP-IMPLEMENTATION-VIVA.md) is the **strategy**: the tiering, the must-pass
rationale, the environment checklist, the fallback ladder. **This folder is the executable half** —
the sheets you read on the day, and the logs that prove the controls were actually run.

| File | What it is |
|---|---|
| [`run-sheet.md`](run-sheet.md) | The timed 5-minute script as a **run sheet**: what to tap, who presents, and **the one line to say when each step fails** |
| [`regression-log.md`](regression-log.md) | The **3×/week golden-path regression log** — control 3's evidence |
| [`backup-capture.md`](backup-capture.md) | The recording inventory: what exists, from which commit, and **what invalidates it** — control 4's evidence |
| [`failure-rehearsal.md`](failure-rehearsal.md) | The **injected-failure** rehearsal plan that risk **R19** asks for |

## The three numbers that decide this component

| | |
|---|---|
| **60%** | the component's weight |
| **MUST PASS** | an aggregate of 60% *and* this component. Failing it fails the course |
| **5 minutes** | the live demo, rehearsed **to the second** |

## Why the fallbacks are written down

[doc 11 §4](../../docs/11-APP-IMPLEMENTATION-VIVA.md) says *"every step has a rehearsed fallback. If
it fails, the presenter says one line and moves on"* — and then, until now, the one-liners existed
nowhere. Under pressure nobody composes a calm sentence; they apologise, and the demo dies in front
of the marker. **A fallback that is not written down is not a fallback**, so every step in
[`run-sheet.md`](run-sheet.md) carries its line, and the line is short enough to be remembered.

## The rule for this folder

**Log the failure, not just the pass.** A regression log with fourteen consecutive passes and no
failures is not evidence of a reliable app; it is evidence of a log that was not filled in honestly.
When a run fails, record what failed and what was done about it — that record is what makes the
passes believable.

## Before the demo

- [ ] `regression-log.md` has entries at **3×/week from S3**, not one entry the night before
- [ ] Every recording in `backup-capture.md` was made **after** the last change to the screens it shows
- [ ] The fallback line for every step has been **said out loud** at least once in rehearsal
- [ ] At least one rehearsal included an **injected failure** ([`failure-rehearsal.md`](failure-rehearsal.md))
- [ ] The environment checklist in [doc 11 §6](../../docs/11-APP-IMPLEMENTATION-VIVA.md) is walked, not skimmed
