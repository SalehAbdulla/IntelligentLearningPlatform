# §17.3 usability test — one-page run order

> **Print this. Follow it on the day.** It is the whole session on one page; the detail and the
> rationale are in [`protocol.md`](protocol.md). Five participants × 25 minutes, **none a squad member**.

## The two rules that make it worth anything

1. **Do not help.** Never name a screen, button or gesture; never point at the screen; never take the
   device. You may only **repeat the task**, ask *"what are you looking for?"*, or say *"keep going,
   there's no wrong way to do this."*
2. **The 90-second rule.** Still stuck after ~90 s → **mark the task failed**, note what blocked them,
   move on. **The failure is the data**; a rescued participant produces none.

## Before the first participant — do once, the same day

- [ ] Build installed and **walked through end to end today** (`bash tools/run-ios.sh`, or a device).
- [ ] A **5–20 page PDF** already on the device for task T2.
- [ ] Print **one pack per participant** (consent + SUS + log sheet) from
      `StudyForge-Usability-Packet.docx`.
- [ ] [`responses.md`](responses.md) open on the laptop; a timer ready (the phone is fine).

## Per participant — 25 minutes, the same script every time

| Min | Step | Say / do |
|---|---|---|
| 0–4 | **Welcome + consent** | Read the welcome line from the protocol. Give the consent sheet, answer any question, then continue only if signed — otherwise thank them and end. |
| 4–6 | **Warm-up** | Study + year · how they revise now · prior flashcard-app use. Record the answers. |
| 6–20 | **Tasks T1–T6** | One at a time, **exact wording** (protocol table). Start the timer; stop on "done" or at 90 s. After **each**: *"How did that feel?"* and *"Anything you expected and wasn't?"* |
| 20–23 | **SUS** | Hand over the questionnaire: *"tick what matches, no right answer."* **Do not explain any item.** |
| 23–25 | **Debrief** | One thing you'd change · would you use it, and why · anything for the builder. Thank them. |

## Immediately after each participant

- [ ] Log **task success + time on task (seconds) + confusions in their own words** in
      [`participant-log.md`](participant-log.md).
- [ ] Type the **ten SUS answers (1–5)** into [`responses.md`](responses.md).

## After all five

- [ ] `python3 tools/usability-score.py research/usability/responses.md` → paste its paragraph into
      [`results.md`](results.md) **and** Design Document **§17.3**.
- [ ] Write the **changes made in response** — that is the slot §17.3 grades, and a test with none
      reads as a test that was not run honestly.
- [ ] State the **validity threats** (five is a small sample; the facilitator is a developer; novelty
      and politeness; one build). Do **not** imply statistical significance.

## If five 25-minute slots do not fit the time left

Run **15-minute** sessions (consent 3 · tasks 9 · SUS + debrief 3) or use **two facilitators in two
rooms**. The SUS is unaffected by session length, so the score stays comparable.

**Do not change:** the do-not-help rule, the 90-second rule, the exact wording of the six tasks, or
"no participant is a squad member."
