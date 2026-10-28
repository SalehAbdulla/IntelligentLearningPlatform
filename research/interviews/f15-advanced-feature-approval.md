# F15 advanced feature — written approval

> **The rubric requirement this file satisfies:** the brief requires *"one approved advanced feature
> assigned to one or two developers"*. Until 15 Oct 2026 this was the only rubric item the tutor
> interview had not settled, because none of the five questions asked for it. It is now **approved
> in writing**, and the approval carries **three conditions** which are tracked below.

| Field | Value |
|---|---|
| **Approved by** | **Ghassan AlShajjar**, Tutor, EDICT Programming (`Ghassan.AlShajjar@polytechnic.bh`) |
| **Approved on** | **Thursday 15 October 2026, 2:14 pm** |
| **Method** | Email — sufficient; the supervisor confirmed a written reply is enough |
| **Requested by** | M1, Saleh Abdulla (`202300540`) |
| **Requested at** | Thursday 15 October 2026, 1:11 pm |
| **Feature** | **F15, AI Study Companion** — retrieval-augmented generation + adaptive coach |
| **Developers** | **M2 Mohammed Almadhoon** (`202401702`) + **M3 Tasbeeh Saeed** (`202305409`) — exactly two, the maximum the brief allows |
| **Verdict** | ✅ **Approved** — *"The idea is approved"* |

---

## The approval, verbatim

> **From:** Ghassan AlShajjar `<Ghassan.AlShajjar@polytechnic.bh>`
> **Date:** Thursday, 15 October 2026 at 2:14 PM
> **To:** Saleh Ahmed Saleh Ahmed Mahdi Abdulla `<202300540@Student.polytechnic.bh>`
> **Subject:** Re: IT8108 Request: Approval of our advanced feature
>
> Dear Saleh,
>
> The idea is approved, although in the feature list, show which part each of the students are
> responsible for, it should also be separate from the core AI features, and do keep note of the
> dependencies on file upload and quizzes that may introduce.
>
> For any additional feedback, I will also provide it during the evaluation as well.
>
> Kind regards
>
> Ghassan AlShajjar
> Tutor | EDICT Programming
> Office 26.104

## The request that was approved

> **From:** Saleh Abdulla
> **Date:** Thursday, 15 October 2026 at 1:11 PM
> **Subject:** IT8108 Request: Approval of our advanced feature
>
> Dear Mr. Ghassan,
>
> Following our interview on 13 October - section 1 - Intelligent Learning Platform.
>
> May we have your written approval of our advanced feature? It is F15, the AI Study Companion,
>
> It answers only from a student's own uploaded files, shows the source of each answer, and builds
> an adaptive revision path from their quiz results.
>
> It will be built by Mohammed Almadhoon (202401702) and Tasbeeh Saeed (202305409), which is the
> maximum the brief allows. A one-line reply is enough.
>
> If you feel it is not advanced enough, we will promote F09 (the live group revision arena)
> instead. We would be grateful by 21 October, as the document is due on the 22nd.

---

## The three conditions, and where each is met

The approval is **conditional**. A condition that is not acted on is an unmet requirement, so each
one is tracked to the place in the Design Document that satisfies it.

| # | Condition, in the tutor's words | Where it is met |
|---|---|---|
| **1** | *"in the feature list, show which part each of the students are responsible for"* | **§7**, the advanced-feature block now names each developer's scope, and **§8.4** gives the full split with deliverables |
| **2** | *"it should also be separate from the core AI features"* | **§7** — F15 is lifted **out of** the core feature table into its own block, so it cannot read as an eighteenth row among F03/F04/F05/F11 |
| **3** | *"do keep note of the dependencies on file upload and quizzes that may introduce"* | **§8.5** — the dependency table names **F02** (upload, which produces the corpus) and **F05** (quizzes, which write the mastery the planner reads), with what breaks in F15 if either changes |

**Why conditions 1 and 2 matter beyond compliance.** The tutor is guarding against two specific
failure modes: an advanced feature whose ownership is vague (so nobody is accountable for the
hardest part), and an advanced feature that is really just a fifth AI feature wearing a label. Both
are common, and both are cheap to detect from the feature list alone.

## The substitution that was **not** needed

**F09 (the live group revision arena)** was held in reserve as the substitute if F15 was judged not
advanced enough. **It was not needed** — F15 was approved on its own merits, so F09 remains an
ordinary Tier B feature and the substitution is closed. Recorded here so the reserve decision does
not reappear later as an open question.

## Note on who approved it

The **interview** on 13 October was conducted with **Haetham Alhaddad** (module coordinator), as
recorded in §3.1. This **approval** came from **Ghassan AlShajjar** (Tutor, EDICT Programming), who
is the tutor for this project. They are two different people, and the distinction is kept because the
brief's requirement is for the *tutor's* agreement, which is what this file evidences.
