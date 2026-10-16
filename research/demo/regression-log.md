# Golden-path regression log

> **Control 3 of the four in [doc 11 §3](../../docs/11-APP-IMPLEMENTATION-VIVA.md).** The doc requires
> the golden path be *"executed at least **3× per week from S3**, logged with pass/fail"*. This is
> the log. **A control that is not logged is a claim, not a control.**

| Field | Value |
|---|---|
| **Cadence** | **3× per week from Sprint 3** (Mon 2 Nov – Sun 15 Nov 2026), then daily from the feature freeze |
| **Who runs it** | Rotating — **not** the person whose change is being tested |
| **Where** | A **physical device**, from `develop`, installed with `bash tools/run-device.sh` |
| **What is logged** | Pass or fail **per step**, the commit, and any failure with what was done about it |

## The steps

The eight Tier A steps from the demo script, in order. A run passes only if **every** step passes or
its fallback is known to work.

| # | Step | Feature |
|---|---|---|
| **1** | Sign in as a student | F01 |
| **2** | Upload a PDF → appears in the library | F02 |
| **3** | Generate a summary → tap a provenance chip | F03 |
| **4** | Generate cards → review → rate *Good* → interval changes | F04 |
| **5** | Take a quiz → scorecard | F05 |
| **6** | Weakness radar → accept an AI re-plan | F06 |
| **7** | Progress dashboard populates | F07 |
| **8** | Group space → live quiz → leaderboard | F09 |

## The log

`✅` pass · `❌` fail · `⚠️` passed with a fallback · `—` not run

| Date | Commit | Run by | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |
| | | | | | | | | | | | |

## Failures

**Every `❌` or `⚠️` gets a row here.** This table is the useful half of the log.

| Date | Step | What happened | Cause | Fixed by | Re-run result |
|---|---|---|---|---|---|
| | | | | | |

## Why the failure table matters more than the pass table

A log of fourteen clean passes is not evidence that the app is reliable. It is evidence that the log
was filled in from memory, or filled in at all. **The failures are what make the passes credible**,
and they are also the most useful thing here: a step that failed twice and now passes is a step the
team has actually engineered around, which is exactly what control 3 exists to produce.

**Record the near-misses too.** A step that passed on the second attempt, or needed the device
restarted, is a step that will fail in front of the marker. It belongs in the table with `⚠️`.

## What counts as a fail

Be strict, because the marker will be:

| | |
|---|---|
| **Fail** | The step did not complete, or needed help from the person running it |
| **Pass with fallback** | The step did not complete, and the **documented fallback line** in [`run-sheet.md`](run-sheet.md) carried it |
| **Pass** | The step completed on the first attempt, with no intervention |

A step that only works when someone knows which button to press is **not** a pass. The demo is run
by a presenter under pressure, and a step that needs knowledge rather than a label will fail live.

## Escalation

| Trigger | Action |
|---|---|
| Any Tier A step fails **twice** | Raise it with the owner that day; it is now risk **R20** territory |
| Any Tier A step fails **3× a week** | Bring the freeze forward for that feature's remaining scope |
| A step fails and **has no working fallback** | Write the fallback **before** the next run — this is the highest-priority gap the log can find |
