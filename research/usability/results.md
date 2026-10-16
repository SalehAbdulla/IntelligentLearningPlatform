# Usability test results

> ## ⚠️ This file is a template. It contains **no results**, because the test has not been run.
>
> Everything below marked `____` is a placeholder. **Fill it in only from a session that actually
> happened**, using the notes in [`participant-log.md`](participant-log.md). Do not estimate, and do
> not carry a number over from anywhere else.
>
> When this file is complete, its contents go into **Design Document §17.3**, replacing the
> *"Status: planned, not yet run"* note.

| Field | Value |
|---|---|
| **Session date** | ____ |
| **Build tested** | commit `____`, from `main` |
| **Device** | ____ |
| **Facilitator** | M1, Saleh Abdulla |
| **Participants** | ____ of 5 completed |
| **Protocol followed** | [`protocol.md`](protocol.md) |

---

## 1. Participants

| # | Year of study | Prior flashcard-app use? | Tasks passed (of 6) | Total time on task (s) | SUS score |
|---|---|---|---|---|---|
| P1 | | | | | |
| P2 | | | | | |
| P3 | | | | | |
| P4 | | | | | |
| P5 | | | | | |
| **Mean** | — | — | ____ / 6 | ____ s | **____** |

**Recruited how:** ____ *(state it honestly — if participants knew the team, the write-up must say so)*

---

## 2. Task success

| Task | Participants who completed it | Success rate | Median time (s) | Slowest (s) |
|---|---|---|---|---|
| **T1** Create an account | ____ / 5 | ____% | | |
| **T2** Add a PDF to the library | ____ / 5 | ____% | | |
| **T3** Get a summary | ____ / 5 | ____% | | |
| **T4** Generate flashcards | ____ / 5 | ____% | | |
| **T5** Study the cards | ____ / 5 | ____% | | |
| **T6** Take a quiz | ____ / 5 | ____% | | |
| **Overall** | ____ / 30 | ____% | — | — |

**Median, not mean, for time.** One participant who wanders off for two minutes would drag a mean
somewhere unrepresentative; the median reports the typical experience.

---

## 3. The SUS score

**The headline figure for §17.3:**

> *"The five participants returned a **SUS score of ____** (SD ____), which falls in the ____
> band on the Bangor, Kortum and Miller (2009) adjective scale."*

### Per-participant scoring

Apply the rule in [`sus-questionnaire.md`](sus-questionnaire.md) **per participant first**, then
average the final scores. Show the working, so the number can be checked.

| | P1 | P2 | P3 | P4 | P5 |
|---|---|---|---|---|---|
| Odd items (1,3,5,7,9) each −1, summed | | | | | |
| Even items (2,4,6,8,10) each 5 −, summed | | | | | |
| Total (0–40) | | | | | |
| **× 2.5 → SUS score** | | | | | |

**Mean SUS score:** **____**  ·  **Standard deviation:** ____  ·  **Band:** ____

> **Reminder.** SUS is **not a percentage**. Write *"a SUS score of 78.5"*, never *"78.5%"*. And 68
> is the published average — say whether the result is above or below it, because the number alone
> is not an interpretation.

---

## 4. What was found

### Confusions, by severity

| # | Participants | Task | What happened | Severity |
|---|---|---|---|---|
| C1 | | | | |
| C2 | | | | |
| C3 | | | | |

### What worked

Record this too. A report that lists only problems is not a fair account of the session, and §17.3
is about the design as a whole.

- ____

---

## 5. Changes made in response

**This is the section §17.3 asks for by name.** Every high-severity finding must have a response —
either a fix, or a reasoned decision not to fix it with the reason recorded.

| Finding | Change made | Commit / PR | Status |
|---|---|---|---|
| C1 | | | |
| C2 | | | |
| C3 | | | |

**Not fixed, and why:**

| Finding | Why not fixed |
|---|---|
| | |

> A finding left unfixed with a stated reason is good engineering. A finding left off the list is a
> gap in the report.

---

## 6. Limitations

State these in §17.3 alongside the result. They are what make the claim defensible rather than
overstated.

- **Five participants.** Enough to surface severe problems (Nielsen, 1994); **not** enough to claim
  statistical significance or to generalise to a population.
- **The facilitator is a developer of the app.** Mitigated by the do-not-help rule and the fixed
  script, but the facilitator's presence is a known influence.
- **Politeness and novelty effects.** Participants who know the team tend to be more generous than
  real users.
- **One build on one device.**
- **Simulated data.** Where a participant was confused by a state that is simulated in the
  prototype, that is recorded as such.

---

## 7. The paragraph for Design Document §17.3

Assembled from the above. Fill it in and paste it into the document, replacing the *"Status: planned,
not yet run"* note.

> **Status: run on ____ 2026.** Five participants who are not squad members completed the golden path
> on build `____` running on ____. Consent was written and all data is anonymised to P1–P5
> ([consent form](consent-form.md)); no personal study material was collected. The protocol, the
> task scenarios and the questionnaire are in [`research/usability/`](../usability/README.md).
>
> Task success was **____ of 30** (____%). The five participants returned a **SUS score of ____**
> (SD ____), in the ____ band on the Bangor, Kortum and Miller (2009) adjective scale, against a
> published average of 68. ____ confusions were found, of which ____ were high severity; the changes
> made in response are listed above, and ____ findings were left unfixed with the reasons recorded.
>
> The test's limits are stated: five participants surfaces severe problems but does not support a
> statistical claim, the facilitator is a developer of the app, and one build on one device was
> tested.
