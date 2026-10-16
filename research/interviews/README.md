# Tutor interview pack (graded evidence)

> **Start here:** [`docs/15-PROJECT-BRIEFING.md`](../../docs/15-PROJECT-BRIEFING.md) is the plain-language
> summary of the whole project, the 15 features, and these questions in one file. Print it for the interview.

The Design Document rubric (Background Research, bullet a4) requires *"Group interview summary
with your tutor to validate and refine your understanding, focused on collecting information
from your tutor within class time. Include questions asked and summary of responses."*

The interview guidelines add two more graded parts: a **transcript** of the interview and a
**summary** of it. Both live here, and both are pasted into `DESIGN-DOCUMENT.md` section 3.

## 1. What this folder must contain

| File | What it is | Status |
|---|---|---|
| `tutor-interview-transcript.md` | Verbatim transcript of the questions asked and the supervisor's answers | ✅ **recorded** — **5 questions**, verbatim, in this folder. Date and attendees are still to confirm (see that file's *Metadata still to confirm* table) |
| `tutor-interview-notes.docx` | The team's original capture document, written up during the interview | ✅ present — this is the **source** the transcript was taken from |
| `tutor-interview-capture-sheet.md` | The scribe's live capture, one row per question | ⬜ to record — the `.docx` serves as the live capture, but the one-row-per-question sheet the guidelines describe has not been made yet |
| `f15-advanced-feature-approval.md` | The tutor's **written** approval of the advanced feature (rubric: *"one approved advanced feature"*) | ✅ **APPROVED 15 Oct 2026, 2:14 pm** by Ghassan AlShajjar (Tutor, EDICT Programming) — requested by email at 1:11 pm the same day and answered within the hour. **The approval carries three conditions**, all now met: each developer's part named, F15 kept separate from the core AI features, and the F02/F05 dependencies noted. See [Design Document §3.4](../../deliverables/design-document/DESIGN-DOCUMENT.md) |
| `recording.*` | The audio or video recording, if permission was given | ⬜ pending |

## 2. Before the interview

1. Confirm the session and the slot. The interview runs in the **second session** of the week, in
   the section the group is allocated to, and the slot is **15 minutes**.
2. Confirm **at least four members** will be present. Fewer than four and the interview does not go
   ahead, and the group must use office hours instead.
3. Decide **three members who will ask** (the guidelines require two or three).
4. Nominate **one scribe**, in case the recording is unclear.
5. Print the question table from `DESIGN-DOCUMENT.md` section 3.2, with the timing plan on it.
6. Ask permission to record **before** the first question, and note the answer in the transcript.

## 3. During the interview

- Ask in the order in `DESIGN-DOCUMENT.md` section 3.2. The highest-mark questions come first, so a
  shortened slot still protects them.
- Write the answer **verbatim** where possible, then summarise in your own words afterwards.
- For every answer, capture one thing: **what we will change as a result**. The rubric rewards
  refinement, not just transcription.
- Get the F15 advanced-feature approval in writing before you leave the room, or by email the same day.

## 4. What each question is really asking (and the words to use)

Read the questions as they are written. They are already in plain words. If the tutor asks a
follow-up, this is what each one means and the simple way to say it.

| # | In one line | If the tutor asks you to explain |
|---|---|---|
| 1 | Can we keep our advanced feature, and may we have that in writing? | F15 is the AI helper. It reads only the student's own files. It is worth the most marks because the brief requires one advanced feature to be approved by the tutor. |
| 2 | How many screens must we draw, and which states? | "States" means the same screen in different situations: normal, nothing to show yet, still loading, something went wrong, and no internet. |
| 3 | Is our plan for accurate AI good enough? | We do four things: the AI uses only the student's file, it shows where the answer came from, it says how sure it is, and a tutor can check it first. |
| 4 | 15 features, or fewer and bigger? | Each of us must build at least 2 features. We have 15 across 4 people, so 3 or 4 each. |
| 5 | Are finished screens a problem in Phase 1? | Phase 1 says low-fidelity, which means rough sketches. We drew finished screens instead. We want to know if that is acceptable. |
| 6 | Is the paid subscription a good idea or off-topic? | The brief never mentions money. F13 is our payment feature. We want to know if extra ideas earn marks or look like we drifted off the brief. |
| 7 | What do we need to prove an innovation? | Innovation is a small mark block (2 of 20) but it needs proof. We are asking whether a screen or some code is required, or whether writing it clearly is enough. |
| 8 | Is Study Group Member a real role in our design? | The brief lists it as a role. In our app it is not a second account. A student joins a group and gains the group features. |
| 9 | How do we hand in the transcript and summary? | Both are graded. We are asking about the format and where they go. |
| 10 | What are the rules for testing with real people? | SUS is a standard 10-question survey that gives a usability score out of 100. We are asking about permission and privacy first. |

### Words to avoid, and what to say instead

| Do not say | Say this |
|---|---|
| RAG, retrieval-augmented generation | "the AI answers only from the student's own uploaded files" |
| grounded generation | "the AI is not allowed to make things up, it uses the student's file" |
| provenance, citation chip | "the answer shows which part of the file it came from" |
| confidence band | "the app says how sure the AI is" |
| low-fidelity / high-fidelity | "rough sketch" / "finished screen" |
| SUS | "a standard 10-question usability survey, scored out of 100" |
| capability set, role layering | "a student joins a group and then gets the group features" |
| monetisation, entitlement | "the paid subscription" |
| buffer question | "an extra question, if there is time left" |
| scribe | "the person writing the answers down" |

## 5. Transcript template

Copy this into `tutor-interview-transcript.md` and fill it in live.

```markdown
# Tutor interview transcript

- Date:
- Section and session:
- Location:
- Duration: 15 minutes (allocated)
- Present (group): M1, M2, M3, M4
- Asked the questions: M1, M2, M4
- Scribe: M3
- Tutor:
- Recording consent: granted / refused
- Recording file:

## Transcript

| Time | Speaker | Verbatim |
|---|---|---|
| 00:00 | M2 | We would like to record this interview so the answers are accurate. Do we have your permission? |
| 00:00 | Tutor |  |
| 00:00 | M2 | Q1. Our advanced feature is F15, an AI helper that answers only from the student's own uploaded files and then builds a study plan. Two of us will build it. Is it advanced enough, is it fine that two of us share it, and can we have your approval in writing today? |
| 00:00 | Tutor |  |
| 00:00 | M4 | Q2. Mockups are worth 8 of the 20 marks. Do we show every screen, or only the main screens of each feature, and do the error, empty, loading and no-internet screens each need their own labelled screen? |
| 00:00 | Tutor |  |
| 00:00 | M2 | Q3. The brief asks how uploaded files become accurate study material. Our plan is that the AI answers only from the student's own file, shows which part of the file the answer came from, says how sure it is, and a tutor checks AI content before students see it. Is that enough, or must we measure the accuracy too? |
| 00:00 | Tutor |  |
| 00:00 | M4 | Q4. We have 15 features across 4 user roles, so each of us builds 3 or 4, and the minimum is 2. Is 15 the right number, or fewer features with more detail in each one? |
| 00:00 | Tutor |  |
| 00:00 | M4 | Q5. Phase 1 asks for low-fidelity mockups but allows Figma, and our document shows finished high-fidelity screens. Could that cost us mockup marks? |
| 00:00 | Tutor |  |
| 00:00 | M2 | Q6. Brief 2 does not mention payment at all. We added a paid subscription, F13, using Tap, and noted that the App Store would require Apple's own payment system. Is that a good extra idea, or better left as a note for future work? |
| 00:00 | Tutor |  |
| 00:00 | M1 | Q7. Innovation is marked on whether the idea is relevant, realistic and adds value. Does each of our ideas need a screen or a piece of code to prove it, or is a written explanation enough? |
| 00:00 | Tutor |  |
| 00:00 | M2 | Q8. The brief lists Study Group Member as a role. In our design it is not a separate account, a student joins a group and then gets the group features. Does that still count as 4 roles? |
| 00:00 | Tutor |  |
| 00:00 | M4 | Q9. Do you want the transcript word for word and complete, should it go inside the main document or in an appendix, and may we quote your answers directly? |
| 00:00 | Tutor |  |
| 00:00 | M1 | Q10. We plan to test the app with 5 classmates and give them a standard questionnaire, the SUS. What permission and privacy rules do you need from us? |
| 00:00 | Tutor |  |
| 00:00 | M2 | Thank you. To confirm, we have your approval in writing for F15. |

## Actions agreed

| Action | Owner | Date |
|---|---|---|
|  |  |  |

## Confirmed by the group

- [ ] Transcript is complete and speaker-labelled
- [x] `f15-advanced-feature-approval.md` is filed and dated — **approved 15 Oct 2026, 2:14 pm**
- [ ] `DESIGN-DOCUMENT.md` section 3.3 is filled in, one row per question
- [ ] `DESIGN-DOCUMENT.md` section 3.1 date, location and attendees are no longer `to be recorded`
- [ ] PDF rebuilt (`bash tools/build-pdf.sh`) after the interview content lands
```

## 6. After the interview

1. Transcribe the recording the same day, while it is fresh.
2. Fill `DESIGN-DOCUMENT.md` section 3.3, one row per question, with the response **and** what
   changed in the design.
3. ~~File the written F15 approval, and update section 3.4.~~ ✅ **DONE 15 Oct 2026** — the approval was requested by email at 1:11 pm and **granted at 2:14 pm the same day**. Filed as [`f15-advanced-feature-approval.md`](f15-advanced-feature-approval.md), recorded in §3.4, and its **three conditions** are met in §7.1, §8.4 and §8.5.
4. Rebuild the PDF, because the export predates the interview.
