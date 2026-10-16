# Usability test protocol

| Field | Value |
|---|---|
| **Method** | Moderated, semi-structured, **think-aloud** |
| **Participants** | 5 students, **none a squad member** |
| **Session** | 25 minutes per participant |
| **Facilitator** | **M1, Saleh Abdulla** |
| **Observer** | One team member, silent, taking time and confusion notes |
| **Build under test** | `main`, the prototype build, walked through by the facilitator beforehand |
| **Device** | A physical device if available, otherwise the iOS Simulator on the facilitator's Mac |
| **Evidence produced** | Participant table, SUS score, confusion list, changes made (Design Document §17.3) |

## Why a semi-structured moderated test

The golden path is fixed, so success and time on task are comparable across the five participants.
The *questions asked after each task* are open, so a participant can report a problem the team did
not anticipate. Fixing the tasks and leaving the discussion open is what makes a five-person test
produce findings rather than just a number.

**Five participants is the number §17.3 commits to**, and it is the right size for finding the
severe problems: Nielsen's (1994) result, cited in the Design Document's reference list, is that a
small number of participants surfaces the majority of usability problems. It is **not** a sample
from which to claim statistical significance, and the write-up must not imply that it is.

## The do-not-help rule

This is the rule that makes the test worth anything, and it is the hardest one to keep.

**When a participant is stuck, the facilitator does not tell them what to tap.** The facilitator
may:

- repeat the task in the same words
- ask *"what are you looking for?"* or *"what do you expect to happen?"*
- say *"keep going, there's no wrong way to do this"*

The facilitator may **not**:

- name a screen, button or gesture
- point at the screen
- take the device and do it

If a participant is still stuck after **about 90 seconds**, the facilitator marks the task as
**failed**, moves on, and notes what blocked them. **A rescued participant produces no finding.**
The failure is the data.

## Session script

Read the bracketed lines aloud, as written, so all five participants hear the same thing.

### 1. Welcome and consent (4 minutes)

> *"Thanks for helping. I'm testing the app, not you — if something is confusing, that's the app's
> problem and exactly what I need to know. There are no wrong answers and nothing you do can break
> it. I'd like you to think aloud as you go: say what you're looking for and what you expect to
> happen. I'll stay quiet while you work. First, please read this and sign if you're happy."*

Give [`consent-form.md`](consent-form.md). **Answer any question about it before continuing.** If
the participant does not consent, thank them and end the session — do not run a partial test.

### 2. Warm-up (2 minutes)

Ask, and record the answers — they matter for interpreting the result:

- What do you study, and what year are you in?
- How do you revise at the moment — paper, notes app, anything else?
- Have you used a flashcard or spaced-repetition app before?

### 3. The tasks (14 minutes)

Give **one task at a time**, in this order. Read the wording exactly. Start the timer when the
participant begins and stop it when they say they are done or the task is marked failed.

| # | Task, read aloud | Success looks like | Fail if |
|---|---|---|---|
| **T1** | *"Create an account for yourself."* | Reaches a signed-in state | 90s pass without a signed-in state |
| **T2** | *"Add the PDF that's already on the device to your library."* | The material appears in the library | Cannot find the import path, or import errors |
| **T3** | *"Get a summary of that material."* | A summary is shown, with citations | Summary missing, or no way to reach it |
| **T4** | *"Turn that material into flashcards."* | Cards are generated | Generation unreachable or produces nothing |
| **T5** | *"Study the cards for a couple of minutes, the way you would before an exam."* | Completes at least 3 ratings | Cannot rate a card, or the session does not advance |
| **T6** | *"Now test yourself with a quiz on the same material."* | A quiz is taken and a result shown | Quiz unreachable, or no result shown |

After each task, ask **the same two questions** and record the answers verbatim where possible:

1. *"How did that feel — anything awkward?"*
2. *"Was there anything you expected to be there and wasn't?"*

### 4. The SUS questionnaire (3 minutes)

Hand over [`sus-questionnaire.md`](sus-questionnaire.md).

> *"Ten short statements about the app. Please tick the box that matches how you feel about each
> one — there's no right answer, and if you can't answer one just leave it."*

**Do not explain any item, and do not comment on an answer.** If a participant asks what an item
means, say *"whatever it means to you"* — that is the point of the scale.

### 5. Debrief (2 minutes)

- *"If you could change one thing about it, what would it be?"*
- *"Would you use this to revise? Why, or why not?"*
- *"Is there anything you'd want to tell the person who built it?"*

Thank them, and confirm how their data will be used.

## What the facilitator records

| Recorded | For | Where it goes |
|---|---|---|
| Task success, **per task, per participant** | Task success rate | [`participant-log.md`](participant-log.md) |
| **Time on task**, per task, in seconds | Where the app is slow *for a human* | [`participant-log.md`](participant-log.md) |
| **Confusions**, quoted where possible | The findings that drive changes | [`participant-log.md`](participant-log.md) |
| SUS responses, 1–5, per item | The SUS score | [`sus-questionnaire.md`](sus-questionnaire.md) → [`results.md`](results.md) |

**Record the confusion in the participant's own words.** *"I couldn't find where to upload"* is a
finding; *"task 2 was hard"* is not.

## Threats to validity, to state in §17.3

Naming these is what separates an honest write-up from an inflated one:

- **Five participants is a small sample.** It surfaces severe problems; it does not measure
  preference or performance across a population.
- **The facilitator is a developer of the app.** Mitigated by the do-not-help rule and a fixed
  script, but not eliminated.
- **Novelty and politeness effects.** Participants who know the team tend to be kinder and to try
  harder than a real user would. Recruiting participants who do not know the squad reduces this.
- **A single device and a single build.** Findings are about this build on this hardware.
- **The prototype runs partly on simulated data.** A confusion about a simulated state may not
  occur in the finished product, and must be reported as such.
