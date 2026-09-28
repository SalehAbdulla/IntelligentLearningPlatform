## What does this PR do?

<!-- One or two sentences. The "why", not the "what" — the diff shows the what. -->

## Plain-English explanation (required)

<!-- 3 sentences explaining what this code does and why.
     If you cannot write these, you do not understand the change yet — read the code first.
     This is a gate, not a formality (see docs/10-SPRINT-PLAN.md §9). -->

1.
2.
3.

## Traceability

| Field | Value |
|---|---|
| **Feature ID** | `F__` |
| **Sprint** | S__ |
| **Screens touched** | `NN_ScreenName_{Mx}` — or "none (logic only)" |
| **Rubric row affected** | e.g. Design Doc §4 / Prototype p2 / doc 08 `app1` |
| **Branch** | `feat/F__-...` |

## Changes

<!-- Group by file so the reviewer can follow the per-file commits. -->

| File | What changed |
|---|---|
| | |

## How was this tested?

- [ ] Unit tests added / updated — `xcodebuild test` output or screenshot
- [ ] Ran on a **physical device** (model + iOS version): __________
- [ ] Tested on the **Simulator** (device + OS): __________
- [ ] States verified: loading ☐ empty ☐ error ☐ offline ☐
- [ ] Independent test log by the named tester (see doc 02 §7)

## AI-assistance disclosure

Using AI is permitted (tutor-confirmed). Disclosing it is still required.

- [ ] AI tools were used on this change → which, and for what:
- [ ] I have **read every line** and can explain it
- [ ] I corrected the following after review:
- [ ] Part of this change was hand-written: <!-- describe -->

## VIVA readiness

- [ ] I can open any file in this PR and explain it without preparation
- [ ] I can name the trade-off made here (chose ___ over ___ because ___)
- [ ] I can describe what happens when it fails
- [ ] Known limitation (if any):

## Reviewer checklist

- [ ] Builds clean with **zero warnings**
- [ ] No secrets committed (`Google.plist`, keys, `.env`)
- [ ] No `allow read, write: if true` introduced in security rules
- [ ] Loading / empty / error / offline states all handled
- [ ] No hard-coded user-facing strings (English + Arabic both supported)
- [ ] No AI call on the main thread
- [ ] Commit messages are meaningful and one file per commit
