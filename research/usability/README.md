# Usability test pack

> **Why this folder exists.** The Design Document **§17.3** commits the team to a usability test:
> five participants who are *not* squad members complete the golden path, the facilitator records
> task success, time on task and confusion, and a **System Usability Scale** score is collected.
> Two submission checks read that commitment — `dd-usability` (*"usability test with 5 users"*) and
> `p9-0304` (*"P9-03/04 usability test and SUS score"*) — and **one test clears both**.
>
> This pack is everything needed to run the test. Nothing here is a result; **results go in
> [`results.md`](results.md) only after the session has actually happened.**

## Why it is worth doing properly, not just ticking

The Sprints and Design Document components both reward *evidence of testing with real users*. A test
that was genuinely run produces findings that change the product, and §17.3 has a slot for exactly
that: *"the changes made in response"*. **A test with no findings is a test that was not run
honestly** — the expected outcome of five people using a prototype for the first time is several
points of confusion, and recording them is what earns the marks, not hiding them.

## Files

| File | What it is | Who fills it |
|---|---|---|
| [`protocol.md`](protocol.md) | The method, the facilitator script, the task scenarios and the timings | Prepared now, followed on the day |
| [`consent-form.md`](consent-form.md) | Participant information and written consent, aligned with §16.2 and the Bahrain PDPL 2018 | Signed by each participant |
| [`sus-questionnaire.md`](sus-questionnaire.md) | The ten standard SUS items and the scoring rule | Completed by each participant |
| [`participant-log.md`](participant-log.md) | The anonymised participant table (P1–P5) | Facilitator, on the day |
| [`results.md`](results.md) | Task success, time on task, confusion, the SUS score and the changes made | Facilitator, after the session |

## The short version of the method

| | |
|---|---|
| **Participants** | **5**, students, **none a squad member** (§17.3) |
| **Session length** | **25 minutes** each, including consent and the questionnaire |
| **Method** | Semi-structured, moderated, **think-aloud** |
| **Build** | The prototype on a physical device or Simulator, from `main` |
| **Tasks** | The six-step golden path, given one at a time |
| **Measures** | Task success (per task), time on task, **confusions observed**, SUS score |
| **Data** | Anonymised to P1–P5. **No personal study content is collected** (§16.2) |

## Before the session

- [ ] Five participants recruited and their slots booked — **recruit early, this is the item that fails if people are busy**
- [ ] Consent form printed or shared, one per participant
- [ ] SUS questionnaire printed or shared, one per participant
- [ ] Build installed on the test device from `main`, verified by walking the golden path yourself first
- [ ] A test PDF available on the device (about 5–20 pages, real study material)
- [ ] Timer, and somewhere to record notes per participant
- [ ] Facilitator briefed on the **do-not-help rule** in [`protocol.md`](protocol.md)

## After the session

- [ ] Complete [`participant-log.md`](participant-log.md) from the notes, within 24 hours
- [ ] Compute the SUS score with the rule in [`sus-questionnaire.md`](sus-questionnaire.md)
- [ ] Complete [`results.md`](results.md), **including the confusions found**
- [ ] Paste the participant table, the SUS score and the changes into **Design Document §17.3**
- [ ] Re-run `bash tools/check-submission.sh` and confirm `dd-usability` and `p9-0304` clear

> **The honesty rule.** Record what actually happened. If a participant failed a task, that is a
> finding, not an embarrassment — §17.3 asks for the changes made in response, and a change can only
> come from a real finding. Never round a SUS score, and never record a participant who did not
> take part.
