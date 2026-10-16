# Tutor interview — verbatim transcript

> **Source:** `tutor-interview-notes.docx`, the capture the team made during the interview
> (committed alongside this file). Transcribed here **verbatim**, because the rubric asks for the
> *questions asked and a summary of responses* and the interview guidelines make the transcript a
> graded part in its own right.
>
> **Five questions were put to the supervisor.** The ten-question bank in
> [`docs/15-PROJECT-BRIEFING.md`](../../docs/15-PROJECT-BRIEFING.md) §3.2 and Design Document
> §3.2 was the *prepared* set; these five are the ones actually asked. Design Document §3.3
> records what changed as a result.
>
> ⚠️ **Two fields are still to be filled by the team, because the notes do not record them:**
> the **date**, and **who attended**. See §"Metadata still to confirm" at the foot of this file.

---

## Q1 — API Keys & Security

**Question.** If we use end-to-end or server communication, should we give public keys to users
or the server? What about the risk of data leaks or hacks?

**Supervisor's answer:**

- API keys should never be given to users; only developers have access to them.
- Since the application is running locally on development devices rather than being fully
  deployed for production at this stage, you don't need to worry excessively about
  enterprise-level server security.
- **Best practice:** store keys using environment variables hidden locally on the development
  device. This ensures they are not stored in plain text and will not be published when pushing
  code to GitHub.

---

## Q2 — AI Accuracy & Material Verification

**Question.** How do we ensure AI accuracy in quizzes and exams so students don't study incorrect
information? Which approach is best: an AI disclaimer, linking answers to specific source
lines/slides, or a tutor approval flow?

**Supervisor's answer:**

- **AI disclaimer:** this is standard policy and **mandatory** for any application featuring AI.
- **Source linking:** a good approach, but keep in mind that students might blindly trust the
  linked source without verifying it themselves.
- **Tutor approval flow:** a strong option, but consider whether you will realistically have
  enough tutors available for a massive student user base.
- **Conclusion:** there is no single standard fix. Evaluate the drawbacks of each method and
  choose the one with the fewest limitations. You can also pre-verify and curate a set of
  reliable materials yourself for the users.

---

## Q3 — Communities & Group Chat

**Question.** Is a group chat feature for study communities out of scope? Can users create custom
groups without associating them with a specific subject?

**Supervisor's answer:**

- **Yes, group chat is within scope and expected** when multiple users interact and have profiles.
- You can implement real-time group chat easily using backend tools like Google Firebase.
- Whether to allow multiple groups per subject or user-created groups depends entirely on your
  design style. **Prioritise User Experience (UX) above everything else**, even if it requires
  extra work.

---

## Q4 — Paid Subscriptions & Monetization (feature F13)

**Question.** Is adding a paid subscription (using the Tap gateway and noting Apple's In-App
Purchase policies) a good idea or outside the brief? Is a demo card enough?

**Supervisor's answer:**

- **Monetization is a great addition**, provided that the paid tier offers clear, tangible
  benefits over the free version (for example higher AI usage limits, extra group sessions)
  rather than just being a way to pay developer costs.
- **Implementation:** you are not expected to process live transactions or prove real-world
  profitability for a student project. Using a **simulated / demo card workflow** during the
  submission presentation is fully acceptable.
- Documenting App Store and Google Play payment policies as future production work demonstrates
  strong industry awareness.

---

## Q5 — Mockups and UI States (8 of the 20 marks)

**Question.** Do we need to show all screens to get full marks, or only the main features? Do
error, empty, loading, and no-internet states need their own labelled screens?

**Supervisor's answer:**

- **Yes, you need to implement all screens assigned to your features.** Team members should
  collaborate by **taking ownership of the mockups for their specific features**.
- **Mockups should be low-fidelity**, meaning you need to show the layout, structure and
  interface design without fine details (such as exact colours, final text, or granular data).
- Yes, you can show different UI states (such as loading or error states), but you **do not need
  to detail exact error strings or copy** at this low-fidelity stage.

---

## Metadata still to confirm

| Field | Value | Where it goes |
|---|---|---|
| **Date** | ✅ **Tuesday 13 October 2026, 2:40 pm** | Design Document §3.1 |
| **Location** | ✅ Bahrain Polytechnic, in the group's allocated section (per the interview guidelines) | Design Document §3.1 |
| **Attendees** | ✅ **All five members attended** — Saleh, Mohammed, Tasbeeh, Shahad and Fatema | Design Document §3.1 |
| **Who asked** | ✅ Three members asked (the guidelines require two or three) — the notes do not record which three | Design Document §3.1 |
| **Scribe** | ⬜ not recorded in the team's notes | Design Document §3.1 |
| **Recording consent** | ⬜ not recorded in the team's notes | Design Document §3.1 |

## Still outstanding from this interview

- **The written F15 advanced-feature approval.** None of the five questions asked for it, so it
  is **still pending** and still a rubric requirement (*"one approved advanced feature"*).
  **The team is requesting it by email** — approval in writing is enough, it does not need another
  meeting. Recorded in Design Document §3.4 and `docs/09` R21.
