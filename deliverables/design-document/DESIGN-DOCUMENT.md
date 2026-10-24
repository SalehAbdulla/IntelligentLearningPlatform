<!--
StudyForge, Design Document (source of truth for the submitted PDF)
IT8108 Project Design Document & Prototype, Project Brief 2, Intelligent Learning Platform
Export to PDF at Gate 1 (before 21 Oct 2026). House rule: no em dashes anywhere.
Every section maps to a rubric area, see docs/08-RUBRIC-COVERAGE-MATRIX.md.
-->

# StudyForge

## Turn any material into mastery.

**IT8108, Project Design Document & Prototype · Project Brief 2, Intelligent Learning Platform · Semester A 2026-2027**

| | |
|---|---|
| **App name** | StudyForge |
| **Tagline** | Turn any material into mastery. |
| **Client brief** | Project Brief 2, Intelligent Learning Platform |
| **Module** | IT8108, Bahrain Polytechnic, Year 3 |
| **Team (5 members)** | Saleh Abdulla (202300540) · Mohammed Almadhoon (202401702) · Tasbeeh Saeed (202305409) · Shahad Ashoor (202305767) · Fatema Ghareeb (202304804) |
| **Tutors** | Haetham Alhaddad (Coordinator) · Ghassan AlShajjar |
| **Platform** | iOS 26.0+ · SwiftUI · Swift 6 · Xcode 27 · Firebase (Spark, no-cost tier) |
| **SDGs** | SDG 4 (Quality Education) · SDG 9 (Industry, Innovation & Infrastructure) · SDG 10 (Reduced Inequalities) |
| **Design Document due** | 22 October 2026, 23:55 |
| **Prototype (Figma) due** | 12 November 2026, 23:55 |
| **Document version** | 1.2 (Gate 1 draft: figure and table lists, all figures except the two that need the app or a competitor's product captured) |

> The app name and logo appear in the header of every page and on the Figma cover, per the identity requirement.

## Table of contents

List of figures · List of tables

1. Executive summary
2. Background research: the problem, who is affected, and why it matters
3. Tutor interview: questions asked and summary of responses
4. Competitive analysis
5. App purpose, goals, intended impact and success metrics
6. User roles and personas
7. Feature list
8. Advanced feature specification (F15, AI Study Companion)
9. Feature flows
10. Low-fidelity mockups
11. Navigation map
12. Design system
13. Innovation
14. Technical architecture
15. Accessibility and inclusiveness
16. Professional ethics and compliance
17. Testing and validation
18. References
19. Appendix

---

## List of figures

Every figure is numbered by the section it belongs to. The `figures/` and
`mockups/figures/` paths are relative to this document, and each PNG was exported at 2× from
the Figma file (see §10.1). Statuses are honest: a figure marked ⬜ does not exist yet. The
gate script `tools/check-submission.sh` checks that both lists exist, that the artwork resolves
and that the PDF is present, but it does not read these status cells, so an open ⬜ here is a
commitment to the marker rather than a gate the script enforces.

| Figure | Caption | File | Status |
|---|---|---|---|
| Cover | StudyForge cover, as built in Figma | [figures/00_Cover_StudyForge.png](figures/00_Cover_StudyForge.png) | ✅ |
| 4.1 | Competitor teardown, screenshots of each product | ⬜ to capture | ⬜ pending |
| 5.1 | The core learning loop: upload, generate, schedule, practise, measure, adapt | [mockups/figures/LOOP_CoreLearningLoop_StudyForge.png](mockups/figures/LOOP_CoreLearningLoop_StudyForge.png) | ✅ exported |
| 8.1 | The RAG pipeline: index, retrieve, ground, answer, adapt | [mockups/figures/PIPE_RAGPipeline_StudyForge.png](mockups/figures/PIPE_RAGPipeline_StudyForge.png) | ✅ exported |
| 9.1 to 9.17 | The 17 per-feature flow diagrams (F01 to F17), one per feature | [mockups/figures/](mockups/figures/) `FLOW_F01` to `FLOW_F17` | ✅ all 17 exported |
| 10.1 | The cross-cutting state set (loading, empty, error, offline, success) | [figures/03_States_StudyForge.png](figures/03_States_StudyForge.png) | ✅ exported |
| 10.2 to 10.131 | The 130 low-fidelity wireframes in screen order, each with its numbered callouts and legend panel | [mockups/figures/](mockups/figures/) `LF_01` to `LF_179` | ✅ exported |
| 11.1 | The global navigation map | [mockups/figures/02_NavigationMap_StudyForge.png](mockups/figures/02_NavigationMap_StudyForge.png) | ✅ exported |
| 11.2 | The core learning loop, restated in the navigation context (same artwork as Figure 5.1) | [mockups/figures/LOOP_CoreLearningLoop_StudyForge.png](mockups/figures/LOOP_CoreLearningLoop_StudyForge.png) | ✅ exported |
| 12.1 | The design system sheet: colour variables, type ramp, spacing, radius, elevation | [figures/01_DesignSystem_Saleh_202300540.png](figures/01_DesignSystem_Saleh_202300540.png) | ✅ exported |
| 12.2 | The glass and depth reference: blur, hairline border, dual shadow, inner light edge | [figures/02_GlassAndDepth_Saleh_202300540.png](figures/02_GlassAndDepth_Saleh_202300540.png) | ✅ exported |
| 13.1 | The provenance citation chip and its confidence band, on prototype screens 38 and 59 | [figures/13_Provenance_Citation_StudyForge.png](figures/13_Provenance_Citation_StudyForge.png) | ✅ exported |
| 14.1 | The system architecture: app, backend, AI tiers | [mockups/figures/ARCH_SystemArchitecture_StudyForge.png](mockups/figures/ARCH_SystemArchitecture_StudyForge.png) | ✅ exported |
| 14.2 | The AI router decision tree | [mockups/figures/ARCH_AIRouterDecisionTree_StudyForge.png](mockups/figures/ARCH_AIRouterDecisionTree_StudyForge.png) | ✅ exported |

Figure resolution: every exported wireframe is 1720 × 1920 px and every flow diagram is at
least 2160 px on its long edge, so each clears 150 dpi at any printed width up to 11.4 inches
(the requirement in the export checklist). The four system diagrams drawn on 8 Oct 2026
(Figures 5.1, 8.1, 14.1 and 14.2) were exported at the same 2× scale, 2160 px wide. The
per-screen figure index is §10.4.

## List of tables

| Table | Caption |
|---|---|
| 2.1 | The SDG alignment, one contribution per goal |
| 3.1 | The interview record (date, location, attendees) |
| 3.2 | The ten interview questions, the rubric bullet each one serves, and who asks it |
| 3.3 | The tutor answers and what changed in the design as a result |
| 4.1 | The competitor teardown, with the gap StudyForge exploits |
| 5.1 | Goals mapped to a measurable success metric and a target |
| 6.1 | The four user roles, their exclusive capabilities and their home screen |
| 7.1 | The master feature list (feature name, main task, user, sub-tasks or steps, developer, tester) |
| 7.2 | The advanced feature's identity, kept separate from the core feature table |
| 7.3 | Which developer is responsible for which part of F15 |
| 8.1 | The retrieval-augmented generation pipeline, step by step |
| 8.2 | The F15 ownership split with deliverables |
| 8.3 | The two protocols forming the interface between F15's halves |
| 8.4 | The features F15 depends on, and what breaks in F15 if each changes |
| 9.1 | Every feature expanded into its ordered sub-tasks and steps |
| 10.1 | The 123 screens grouped by feature area, with the owning member |
| 10.2 | The labelled-element standard, worked example (student home) |
| 10.3 | The screens that implement each feature, with a one-line purpose each |
| 10.4 | The figure index for the 130 wireframes |
| 11.1 | The five-tab spine and what each tab holds per role |
| 12.1 | The light-mode colour tokens with their measured contrast ratios |
| 13.1 | The ten innovations, each with its problem, idea, feasibility and evidence |
| 14.1 | The three AI tiers and when each is used |
| 15.1 | The accessibility requirements, the target and how each is verified |
| 17.1 | The four test levels, the method and the evidence each produces |
| 19.1 | The light-mode colour tokens in full (appendix) |
| 19.2 | The dark-mode colour tokens on #0B1220 (appendix) |

The title-page metadata block above is part of the front matter and is deliberately not
numbered.

---

## 1. Executive summary

University students accumulate large volumes of unstructured study material (lecture slides, PDFs, photographs of whiteboards) but have no systematic way to convert it into the active-recall practice that research shows produces durable learning. The default behaviour, rereading and highlighting, is among the least effective techniques available, yet it remains the most common.

**StudyForge** turns any study material into summaries, flashcards, quizzes and a spaced-repetition plan, and closes the loop between them: **upload, generate, schedule, practise, measure, adapt**. It is an iPhone-first, bilingual (English and Arabic) application built on Apple's on-device intelligence where possible, so the core loop works offline and at no cloud cost, and every AI artefact carries a visible source citation.

The design is documented end to end in this document: 4 user roles, 17 features, 123 designed screens, a bilingual design system, a 3-tier AI router, and a security model that keeps authorisation server-side. The system is built against a hard client constraint, **minimal cost**, and runs entirely inside free tiers. (The **154-frame** inventory in [doc 03](../../docs/03-SCREEN-INVENTORY.md) is the full plan, and the **123 built screens** are those drawn in Figma — all 17 features, including groups N and O for F16 and F17.)

## 2. Background research: the problem, who is affected, and why it matters

### 2.1 The problem

Students are asked to retain more, from more sources, in less time. The material arrives as slides, PDFs and photographs, but it arrives **unstructured**, and the tools students reach for by default do not work well.

- **Rereading and highlighting are low-yield.** A landmark review of ten study techniques rated rereading and highlighting as low utility, while practice testing and distributed practice were rated high utility (Dunlosky et al., 2013).
- **Retrieval practice beats restudy.** Being tested on material, rather than rereading it, produces markedly better long-term retention, the "testing effect" (Roediger and Karpicke, 2006; Karpicke and Blunt, 2011).
- **Spacing beats cramming.** Distributing study over time produces more durable memory than massed practice (Cepeda et al., 2006), a principle formalised in scheduling algorithms such as SM-2 (Wozniak and Gorzelanczyk, 1994).
- **Forgetting is predictable.** Retention decays over time in a regular pattern (Ebbinghaus, 1885), so scheduling review at the right moment is a solvable problem rather than a matter of discipline.

The gap is not that students lack willpower. It is that converting a lecture PDF into spaced, tested practice is **manual, tedious work**, so almost nobody does it. The brief states the opportunity directly: *"This project asks students to design an AI-supported mobile learning platform that helps students organize materials and turn them into useful study resources such as summaries, notes, quizzes, and flashcards."*

### 2.2 Who is affected, and why it matters

The primary users are undergraduates, and the design is deliberately shaped by the Gulf context:

- Many students study in a **second language** (English-medium instruction), so clarity and translation matter.
- Many study **alongside part-time work**, so time is scarce and a realistic plan matters more than a perfect one.
- Many pay for **mobile data by the gigabyte**, so an architecture that generates on-device, rather than uploading everything to a server, is both cheaper and more private.
- Commercial AI study tools are largely **Western-market, subscription-gated, English-only and cloud-only**, which excludes precisely the students who would benefit most.

This is where the module's **SDG 10 (Reduced Inequalities)** alignment becomes concrete rather than decorative: a genuinely useful free tier, full Arabic with true right-to-left layout, dyslexia-friendly typography, and offline operation are inclusivity decisions, not features bolted on.

| SDG | How StudyForge contributes |
|---|---|
| **SDG 4, Quality Education** | Turns passive material into active-recall resources, with measurable mastery over time. |
| **SDG 9, Industry, Innovation & Infrastructure** | On-device AI plus offline-first architecture means quality tools that work on low-quality or intermittent connectivity. |
| **SDG 10, Reduced Inequalities** | Bilingual English and Arabic with full RTL, dyslexia-friendly typography, a free tier that is genuinely useful rather than crippled, offline mode, and accessibility-first design. |

*Table 2.1, the SDG alignment, one contribution per goal.*

### 2.3 Why now

On-device language models shipped to consumer phones in the last platform cycle, which means grounded, private generation can run without a server bill. That changes the economics: a student app can summarise and generate cards on the device, at zero marginal cost, and only escalate to the cloud when a task genuinely needs more reasoning or multimodal input. StudyForge is designed around exactly that shift. Locally, Bahrain's move toward digital payments is a matter of regulation rather than fashion: **Ministerial Resolution No. (43) of 2024** (Official Gazette No. 3753, 13 June 2024) requires commercial establishments to hold a dedicated business bank account and to process their payments through licensed financial institutions, and directs them to adopt electronic payment systems — the same licensed rails F13 builds on. Regionally, the GCC e-learning market reached **USD 7.7 billion in 2025 and is forecast to grow at 13.46% a year to 2034** (IMARC Group, *GCC E-Learning Market, 2026–2034*, published May 2026). Together, those make this a well-timed context rather than a speculative one.

> **Note for the final export — carried out on 23 Oct 2026.** Every market-context figure in this section was re-checked against its cited source, and each is recorded with its source and retrieval date in [`research/dossier.md`](../../research/dossier.md) §2.1. **V1–V5 are all verified; nothing was removed and nothing is approximated.** Two of them carry an explicit caveat rather than a silent one — the penetration figure is **mobile lines**, not smartphones (V2), and the market-size figure is **GCC-wide**, not Bahrain-specific (V3). The learning-science findings above are stable and peer-reviewed.

**Evidence base for this section.** Every claim above is traced to its source, each design consequence is recorded, and the market figures that are still unverified are listed, in [`research/dossier.md`](../../research/dossier.md) sections 1, 2 and 6. Section 4 of that file is the stage-by-stage competitor coverage behind the "one closed loop" claim.

## 3. Tutor interview: questions asked and summary of responses

> ✅ **Status: the interview HAS taken place — Tuesday 13 October 2026, 2:40 pm, all five members present.** **Five questions** were put to the supervisor, and they are transcribed **verbatim** in [`research/interviews/tutor-interview-transcript.md`](../../research/interviews/tutor-interview-transcript.md), with the team's original capture beside it as `tutor-interview-notes.docx`. The rubric requires **both** halves — the questions asked *and* the summary of responses — and the interview guidelines make the transcript and the summary graded parts in their own right. §3.2 holds the questions, §3.3 holds the summary of responses **and what changed in the design as a result**.
>
> ✅ **The written F15 approval has been obtained** (§3.4) — approved by Ghassan AlShajjar on 15 Oct 2026, and it closed the last rubric item the interview had left open. The five interview questions did not request it, so it was requested separately by email, which the tutor confirmed was sufficient.

### 3.1 Interview record

| Field | Value |
|---|---|
| Date | **Tuesday 13 October 2026, 2:40 pm** |
| Location | Bahrain Polytechnic, in the group's allocated section, second session of the week (as the interview guidelines require) |
| Slot | 15 minutes, allocated by the tutor |
| Interviewer(s) | **Three members asked**, as the guidelines require (the notes do not record which three) |
| Supervisor | Haetham Alhaddad (module coordinator) |
| Group attendance | **All five members attended** — F01–F17's owners: Saleh, Mohammed, Tasbeeh, Shahad and Fatema |
| Scribe | Not recorded in the team's notes |
| Format | Semi-structured. **Five questions were asked**; the ten-question bank in §3.2 was the prepared set |
| Notes | ✅ **`research/interviews/tutor-interview-transcript.md`** — the five questions and the supervisor's answers, **verbatim**; the team's original capture is beside it as `tutor-interview-notes.docx` |
| Consent | Not recorded in the team's notes |

*Table 3.1, the interview record (date, location, attendees).*

> **What is recorded and what is not.** The **five questions and the supervisor's answers are
> verbatim and complete** in `research/interviews/tutor-interview-transcript.md`, and the interview
> record above is complete for the fields the guidelines require — **date, location, attendees**.
> Two non-required fields (the scribe, and the recording-consent answer) were not written down in
> the team's notes and are marked as such rather than filled in afterwards.

### 3.2 Questions asked

> **The five questions actually asked** were: (1) API keys and security, (2) AI accuracy and
> material verification, (3) group chat and study communities, (4) paid subscriptions and
> monetisation, and (5) mockup coverage and UI states. They are transcribed verbatim, with the
> supervisor's answers, in
> [`research/interviews/tutor-interview-transcript.md`](../../research/interviews/tutor-interview-transcript.md),
> and their impact is recorded in §3.3 below.
>
> The **ten-question bank** that follows was the *prepared* set, ordered by rubric weight and each
> mapped to the rubric bullet it serves. It is retained because it shows the interview was planned
> against the rubric rather than improvised, and because it is the bank for the **follow-up** — which
> has now been sent and answered: the F15 approval was obtained by email on 15 Oct 2026 (§3.4).

Ten questions, in plain words, so they can be read out exactly as they stand. The order is deliberate: the questions that move the most marks, and the one that needs a written answer, come first, so a shortened slot still protects them. Three members ask, as the guidelines require, and the rubric bullet each question serves is named, so nothing asked is wasted. Full wording, timings and the buffer questions are in `research/interviews/README.md`.

| # | Question | Rubric bullet it serves | Asked by |
|---|---|---|---|
| 1 | "Our advanced feature is F15. It is an AI helper that answers only from the student's own uploaded files, and then builds a study plan. Two of us will build it. The brief says the advanced feature must be agreed with you and built by one or two students. Is F15 advanced enough, and is it fine that two of us share it? Can we have your approval in writing today? If F15 is not advanced enough, would F09, the live group quiz room, be acceptable instead?" | Features List: *"Include one approved advanced feature assigned to one or two developers."* | M2 |
| 2 | "Mockups are worth 8 of the 20 marks. We have 106 screens, and every screen has a written description and labelled buttons and fields. To get full marks, do we show every screen, or only the main screens of each feature? Do the error, empty, loading and no-internet screens each need their own labelled screen?" | Mockups: *"Include all required screens and clear navigation flow"* and *"Label key UI elements clearly."* | M4 |
| 3 | "The brief asks how uploaded files become accurate study material. Our plan is: the AI answers only from the student's own file, it shows which part of the file each answer came from, it tells the student how sure it is, and a tutor can check AI content before students see it. We never let AI mark real coursework. Is that what you expect, or do you also want us to measure and report how accurate the AI is?" | Background Research: the real-world problem and why it matters. Innovation: *"relevance, feasibility, and added value."* | M2 |
| 4 | "We have 17 features across 4 user roles, so each of us builds 2 to 4 features, and the minimum is 2. Is 17 the right number, or would you prefer fewer features with more detail in each one?" | Features List: *"Each student must develop at least two features"* and the workload-balance clause. Mockups: coverage. | M4 |
| 5 | "Phase 1 asks for low-fidelity mockups, but the brief says we may use Figma. Our document shows finished, high-fidelity Figma screens. Could showing finished screens cost us mockup marks, or is it fine as long as we cover every screen and label everything?" | Mockups: *"Submit low-fidelity mockups for assigned features."* | M4 |
| 6 | "Brief 2 does not mention payment at all. We added a paid subscription (F13) using Tap, and we wrote down that the App Store would require Apple's own payment system instead. Is that a good extra idea, or is it outside the brief and better left as a note for future work?" | Innovation: *"meaningful enhancement of the selected brief"* and *"relevance."* | M2 |
| 7 | "Innovation is marked on whether the idea is relevant, realistic and adds value. Our main ideas are: the AI runs on the phone first and only uses the cloud when needed, every AI answer shows its source, the app finds weak topics and rebuilds the study plan, and full Arabic right to left with easy-to-read fonts for dyslexia. For full marks, does each idea need a screen or a piece of code to prove it, or is a written explanation enough?" | Innovation: *"Demonstrate original, user-focused improvements"* and *"feasibility."* | M1 |
| 8 | "The brief lists Study Group Member as a role. In our design it is not a separate account: a student joins a group and then gets the group features. Does that still count as 4 roles for the rubric?" | Features List: *"Use at least three user roles."* | M2 |
| 9 | "The transcript and the summary are graded parts of the document. Do you want the transcript word for word and complete? Should it go inside the main document or in an appendix? May we quote your answers directly?" | Background Research: *"Include questions asked and summary of responses."* Document Organization: structure and consistency. | M4 |
| 10 | "We plan to test the app with 5 classmates and give them a standard usability questionnaire, the SUS. What permission and privacy rules do you need from us, and should we avoid asking them to upload their real study files?" | Background Research: supporting research. Mockups: usability of layout. | M1 |

*Table 3.2, the ten interview questions, the rubric bullet each one serves, and who asks it.*

**Buffer questions**, asked only if time remains after question 10. They resolve assumptions the document currently states rather than asks:

1. "Is a working SwiftUI app alongside the Figma prototype viewed positively as feasibility evidence, neutrally, or as scope creep?"
2. "Sprint boundaries and the final demonstration date are not published in the brief. May we set five two-week sprints aligned to the 22 October and 12 November gates, and is the final demonstration live on a device?"
3. "How much of the Tap against Apple In-App Purchase conflict should the document carry: one paragraph, or a full migration path?"

**Timing plan for the 15 minutes.** Consent and framing 0:00 to 0:45 · Q1 0:45 to 2:30 · Q2 2:30 to 4:15 · Q3 4:15 to 5:45 · Q4 5:45 to 7:00 · Q5 7:00 to 8:15 · Q6 8:15 to 9:30 · Q7 9:30 to 10:30 · Q8 10:30 to 11:30 · Q9 11:30 to 12:30 · Q10 12:30 to 13:30 · buffers and closing 13:30 to 15:00. Q1 is asked first and is not sacrificed, because the rubric needs that approval in writing.

### 3.3 Summary of responses and impact on the design

| # | Question topic | Summary of response | What changed in the design as a result |
|---|---|---|---|
| 1 | API keys and security | API keys must **never** be given to users; only developers hold them. Because the app runs locally on development devices rather than in production, enterprise-grade server hardening is not expected at this stage. **Best practice:** keep keys in **environment variables** on the development device, so they are never stored in plain text and never published to GitHub. | **Confirms the existing architecture rather than changing it**, and turns an assumption into evidenced practice. The AI already runs **on-device first** (`D3`), so no key ships inside the app; `tools/commit.sh` already refuses key-shaped values and `.env` files; and `GoogleService-Info.plist` stays in `.gitignore`. The supervisor's "best practice" is therefore the practice the repository already **enforces**, which is the stronger claim to make in the document. |
| 2 | AI accuracy and material verification | An **AI disclaimer is mandatory** for any application featuring AI. Source linking is good, but students may blindly trust a link without verifying it. A tutor approval flow is strong but does not scale to a large student base. There is **no single standard fix** — weigh each option's drawbacks, pick the one with the fewest limitations, and consider pre-verifying a curated set of materials. | The design **already carries all three**, which the answer endorses: a disclaimer, **provenance on every generated artefact**, and the **tutor review queue** (F11). One concrete addition follows from the answer: the **low-confidence band routes generated items to the tutor queue first** (`AIConfidence.isReviewRecommended`), which is the "pick the option with the fewest limitations" instruction applied rather than quoted. The "curate reliable materials yourself" point is met by the tutor-published course catalogue in F11. |
| 3 | Group chat and study communities | **Group chat is in scope and expected** when multiple users interact and have profiles. Real-time chat is straightforward with a backend such as Firebase. Subject-scoped versus user-created groups is a design choice; **prioritise UX above everything**, even at extra cost. | **Directly validates F16.** Group chat had been treated as an optional collaboration extra; the supervisor makes it **expected**, which is why **F16 (admin-moderated group chat)** was promoted into the feature list on 14 Oct with its own frame group, security rules and tests. The "prioritise UX" instruction is visible in one design decision inside F16: a moderated message becomes a **tombstone that keeps the reason**, not a silent deletion. |
| 4 | Paid subscriptions and monetisation (F13) | Monetisation is a good addition **provided the paid tier offers clear, tangible benefits** over free — higher AI limits, extra group sessions — rather than simply covering developer costs. Live transactions and real profitability are **not** expected; a **simulated/demo card** in the presentation is fully acceptable. Documenting App Store and Google Play policies demonstrates industry awareness. | **Removes the open risk on F13** and confirms `D5` (Tap sandbox only, StoreKit behind the same protocol). One concrete change: the paywall must **name tangible benefits** — AI-usage limits, extra group sessions — instead of a generic "premium" tier, and the App Store 3.1.1 discussion stays in the document as future production work. The demo flow is explicitly a **simulated card**, which is what the payment screens already show. |
| 5 | Mockup coverage and UI states | **Every screen assigned to a feature must be shown**, and members should **take ownership of the mockups for their own features**. Mockups are expected to be **low-fidelity** — layout, structure and interface, without fine detail such as exact colours, final copy or granular data. Loading and error states may be shown, but exact error strings are **not** required at this stage. | **Confirms the per-member frame ownership rule** already in force (`NN_ScreenName_FirstName_StudentID`), and **removes a needless worry**: the team built **high-fidelity** screens where low-fidelity was required — more than asked, not off-brief. The low-fidelity wireframes on Figma page 5 satisfy the stated requirement exactly, so both are kept: the wireframes as the required low-fidelity set, the finished screens as the visual target. Exact error copy is **not** required, so the state screens stay schematic. |

*Table 3.3, the supervisor's answers and what changed in the design as a result.*

**Two items the interview did not settle**, recorded so they are not mistaken for answered:

- ~~**The F15 advanced-feature approval was not requested**~~ — ✅ **RESOLVED 15 Oct 2026.** The five questions did not ask for it, so it was requested separately by email and **approved in writing the same day** by Ghassan AlShajjar. See §3.4 and [`research/interviews/f15-advanced-feature-approval.md`](../../research/interviews/f15-advanced-feature-approval.md). Kept here, struck through rather than deleted, so the record shows the interview genuinely did not settle it and the gap was closed afterwards
- **The usability test and its consent rules were not asked about** (prepared question 10). The plan is unchanged: five consenting classmates, a standard SUS questionnaire, and no real study files uploaded — but it is an assumption the document still states rather than an answer it can cite.

### 3.4 Written approval of the advanced feature (F15)

> ✅ **Approved in writing on Thursday 15 October 2026 at 2:14 pm** by **Ghassan AlShajjar**
> (Tutor, EDICT Programming), in reply to an email sent at 1:11 pm the same day. The full request
> and reply, verbatim, are filed as
> [`research/interviews/f15-advanced-feature-approval.md`](../../research/interviews/f15-advanced-feature-approval.md).
> This closes the last rubric item the interview did not settle.

| Field | Value |
|---|---|
| **Approved by** | Ghassan AlShajjar, Tutor, EDICT Programming |
| **Date** | **Thursday 15 October 2026, 2:14 pm** |
| **Method** | Email — the supervisor confirmed a written reply is sufficient |
| **Feature** | **F15, AI Study Companion** (RAG + adaptive coach) |
| **Developers** | **M2** Mohammed Almadhoon + **M3** Tasbeeh Saeed — exactly two, the brief's maximum |

**The approval is conditional**, and the tutor named three conditions. Each is a requirement rather
than a suggestion, so each is tracked to the place that satisfies it:

| # | The tutor's words | Where it is met |
|---|---|---|
| 1 | *"in the feature list, show which part each of the students are responsible for"* | **§7** names each developer's scope in the advanced-feature block; **§8.4** gives the full split with deliverables |
| 2 | *"it should also be separate from the core AI features"* | **§7** lifts F15 **out of** the core feature table into its own block, so it cannot read as an eighteenth row among F03, F04, F05 and F11 |
| 3 | *"do keep note of the dependencies on file upload and quizzes that may introduce"* | **§8.5** names the **F02** and **F05** dependencies and what breaks in F15 if either changes |

**What conditions 1 and 2 are guarding against**, and why they are worth taking seriously: an
advanced feature with vague ownership (nobody accountable for the hardest part), and an advanced
feature that is really a fifth AI feature wearing a label. Both are common, and both are visible
from the feature list alone.

**The substitution was not needed.** **F09 (the live group revision arena)** was held in reserve in
case F15 was judged not advanced enough. It was approved on its own merits, so F09 remains an
ordinary Tier B feature and the reserve decision is closed.

## 4. Competitive analysis

### 4.1 Teardown

| Competitor | Strength | Gap StudyForge exploits |
|---|---|---|
| **Quizlet** | Huge card library, polished UX | Cloud-only, freemium with aggressive paywalls, English-first, weak on *your own* uploaded material |
| **Anki** | Best-in-class spaced repetition | Hostile onboarding, no AI generation, no collaboration, desktop-centric |
| **Notion / Obsidian** | Powerful organisation | The student must build the system themselves; no generation, no scheduling intelligence |
| **Google NotebookLM** | Excellent grounded summarisation | Desktop and web-first, no mobile revision loop, no flashcards, quizzes or spaced repetition, no group spaces |
| **ChatGPT / Gemini apps** | Broad general capability | Not grounded in *your* course material, no structure, no provenance, no revision scheduling |
| **Studocu / Course Hero** | Shared notes at scale | Paywalled, legal grey areas, no personal generation |

*Table 4.1, the competitor teardown, with the gap StudyForge exploits.*

The stage-by-stage coverage behind the "one closed loop" claim, with the reasoning per competitor and the limits of that claim, is compiled in `research/dossier.md` section 3.

*Figure 4.1, competitor teardown screenshots of Quizlet, Anki, NotebookLM, Notion, ChatGPT and Studocu. Status: ⬜ not yet captured, listed as an open figure in the List of figures.*

### 4.2 The competitive edge: one closed loop

> Incumbents solve *one stage* of the study workflow. StudyForge is the only design where **upload, generate, schedule, practise, measure, adapt** is a single closed loop, and where the user's own course material is the grounding source for every AI artefact.

Three supporting differentiators:

1. **Grounded by default, with visible provenance.** Every summary line and every quiz answer traces back to the page it came from, so a generated quiz answer is never a hallucination with no source.
2. **Works without a network.** On-device extraction and on-device generation mean the core loop runs on a bus with no data.
3. **Bilingual English and Arabic with true RTL**, designed for the GCC market that every listed competitor treats as an afterthought.

## 5. App purpose, goals, intended impact and success metrics

### 5.1 Purpose

StudyForge exists to remove the manual work between "I have study material" and "I am practising it". Its purpose is to make high-yield study behaviour (retrieval practice and spaced repetition) the *default*, by generating the resources and scheduling the review automatically.

### 5.2 Goals

1. Turn any material (PDF, photo, scan, link, text) into accurate, cited study resources.
2. Schedule those resources so the student reviews them at the right time.
3. Adapt to the individual, through learning-style-formatted output and a plan that re-plans itself around missed sessions and weak topics.
4. Support collaboration (shared folders, live group revision) without exposing a private student's own notes.
5. Stay free and private: zero infrastructure cost, on-device-first processing, and no student material used for model training.

### 5.3 Intended impact and measurable success metrics

| Goal | Measurable success metric | Target |
|---|---|---|
| Time to value | Time from sign-up to a first completed summary | under 10 minutes on a first run |
| Core loop adoption | A new student generates at least 20 flashcards from one material and completes one review session | within the first session |
| Learning outcome | Increase in topic mastery between two quiz attempts on the same topic | mastery rises after spaced review |
| AI trust | Proportion of AI artefacts carrying a source citation and confidence band | 100 percent |
| Accessibility | Screens passing WCAG 2.2 AA on text contrast, and usable at Dynamic Type AX5 | all designed screens |
| Cost | Monthly infrastructure cost | $0 inside free tiers |
| Offline capability | Core loop (browse, review cards, take a cached quiz) works with the radio off | fully functional offline |
| Reliability | Golden-path demo (upload to review) completes twice in a row | 2 of 2 |

*Table 5.1, goals mapped to a measurable success metric and a target.*

*Figure 5.1, the core learning loop (upload, generate, schedule, practise, measure, adapt), repeated as Figure 11.2: [mockups/figures/LOOP_CoreLearningLoop_StudyForge.png](mockups/figures/LOOP_CoreLearningLoop_StudyForge.png). The loop closes, because what is measured and adapted shapes the next upload.*

## 6. User roles and personas

The brief requires at least three user roles. StudyForge defines **four**, and each is genuinely distinct in permissions, home screen and primary job, rather than a label on the same account.

| # | Role | Job to be done | Exclusive capabilities | Home screen | Demo account |
|---|---|---|---|---|---|
| 1 | **Student** | "Get me through my exams with less wasted time." | Own library, generate AI artefacts, personal study plan, bookmarks, personal progress | `Home_Dashboard_Student` | `student@studyforge.demo` |
| 2 | **Tutor / Teacher** | "Give my cohort good material and see who is struggling." | Create courses, publish official material, review and edit AI-generated content before students see it, cohort analytics, gradebook export, announcements | `Home_Dashboard_Tutor` | `tutor@studyforge.demo` |
| 3 | **Study Group Member** (owner and member sub-roles) | "Revise together without losing my own notes." | Shared-folder CRUD, invite by code or link, per-member permissions (view, comment, edit), group revision spaces, live group quizzes, group leaderboard | `Home_Dashboard_Group` | `group@studyforge.demo` |
| 4 | **Admin** | "Keep the platform correct, safe and compliant." | User and role management, moderation queue, flagged-content reports, taxonomy management, AI prompt-template and quota configuration, audit log, broadcast notifications | `Home_Dashboard_Admin` | `admin@studyforge.demo` |

*Table 6.1, the four user roles, their exclusive capabilities and their home screen.*

> **Design note.** *Study Group Member* is modelled as a capability set layered on top of Student, not a separate account type. One person, one account, multiple contexts. This is the correct real-world model, it avoids a confusing re-sign-up, and it still yields four rubric-compliant roles. Roles are stored in Firestore at `users/{uid}.role` and mirrored into **Firebase Auth custom claims** (`role`, `plan`, `groupIds`), so security rules enforce access server-side, the client never decides who can read what.

### 6.1 Personas

**Persona 1 · Sara, 20, Year 2 Computer Science student (Student).**
Goal: pass her exams with less wasted time and stop forgetting material between lectures. Frustrations: she rereads lecture slides the night before, cannot tell which topics she is actually weak on, and has no realistic plan. Quote: *"I have all the slides. I just do not know what to do with them."* Success for Sara: uploads a PDF and has a summary and 20 cards inside ten minutes.

**Persona 2 · Mr. Yusuf, 41, module lecturer (Tutor).**
Goal: publish official material to his cohort and see who is struggling before the exam, not after. Frustrations: he has no visibility of individual progress until marks come in, and he is wary of AI-generated content reaching students unchecked. Quote: *"Show me who is behind while I can still help."* Success for Yusuf: a review queue where he approves or corrects AI content, and a cohort view that flags at-risk students.

**Persona 3 · Noor, 21, study-group organiser (Study Group Member).**
Goal: revise with her friends in real time without losing her own notes. Frustrations: revision happens in a chaotic group chat, files are duplicated across phones, and shared material is not permission-controlled. Quote: *"We share files on WhatsApp and nobody knows which version is current."* Success for Noor: one shared folder with real permissions, plus a live group quiz everyone can join.

**Persona 4 · Ms. Huda, 35, platform administrator (Admin).**
Goal: keep content correct, safe and compliant, and answer any question about who changed what. Frustrations: moderation is manual, there is no audit trail, and she cannot see platform health at a glance. Quote: *"If something goes wrong, I need to be able to prove what happened."* Success for Huda: a dashboard with platform KPIs, a moderation queue, and an append-only audit log.

## 7. Feature list

The brief requires a structured feature list with name, user role, main task, flow, developer and tester, using at least three roles, with each student developing at least two features and one approved advanced feature co-owned by one or two developers. The table below satisfies every clause.

**Legend.** *Flow* is written as `trigger → step → … → outcome`. Developers and testers use the roster handles: **M1** Saleh Abdulla (202300540) · **M2** Mohammed Almadhoon (202401702) · **M3** Tasbeeh Saeed (202305409) · **M4** Shahad Ashoor (202305767). **Nobody tests a feature they developed.**

| ID | Feature | Role | Main task | Flow | Developer | Tester |
|---|---|---|---|---|---|---|
| F01 | Authentication & Role-Based Onboarding | All | Get a verified user onto the correct role-specific home screen | Launch → splash → onboarding (3) → sign up → verify email → profile wizard → role home | M1 | M4 |
| F02 | Material Upload & Course Library | Student, Tutor | Turn a PDF, photo, scan or link into a searchable, tagged, offline-available library item | Pick source → on-device compress and OCR → upload → write metadata → appears in Library → open viewer | M1 | M3 |
| F03 | AI Summary & Notes Generation | Student | Produce an accurate, cited summary of a chosen material | Open material → Generate sheet → length/style/language → grounded generation → TL;DR, key points, glossary → provenance chips → save | M2 | M1 |
| F04 | Flashcard Generation & Spaced Repetition | Student | Convert material into reviewable cards and have them scheduled automatically | Configure → review and edit cards → review session → flip → rate Again/Hard/Good/Easy → SM-2 writes next due → summary | M2 | M4 |
| F05 | Quiz Generation & Attempt Analytics | Student, Tutor | Test recall and expose weak topics | Configure → generate → answer with feedback → submit → scorecard → explanations → attempts feed `topicMastery` | M2 | M4 |
| F06 | Study Plan Scheduling & Adaptive Re-planning | Student | Get a realistic, exam-aware revision calendar that fixes itself | Wizard (subjects, availability, deadlines, intensity) → AI plan → calendar → reminders → missed session → offer re-plan → accept | M3 | M2 |
| F07 | Progress Tracking & Analytics | Student, Tutor | See mastery, streaks and weak areas over time | Activity events recorded → nightly aggregation → dashboard (streak, mastery, time) → subject breakdown → weakness radar → export | M3 | M1 |
| F08 | Shared Study Folders | Study Group Member | Share resources with a study group, with real permissions | Create folder → invite by code/link/picker → assign view, comment or edit → members add material → activity feed | M4 | M3 |
| F09 | Group Revision Spaces | Study Group Member | Revise together, synchronously, in real time | Join by code → shared board and pinned resources → group chat → launch live quiz → live progress and leaderboard → results | M4 | M1 |
| F10 | Resource Bookmarking & Collections | Student | Save anything for later and actually revisit it | Bookmark from any screen → choose or create collection → offline cache → collection view → resume via deep link | M4 | M3 |
| F11 | Tutor Content Studio | Tutor | Publish and manage course material for a cohort | Create course → roster → publish material → AI review queue → approve, edit or reject → cohort progress → announcement → gradebook export | M2 | M4 |
| F12 | Admin Content Management & Moderation | Admin | Keep content correct, safe and compliant | Admin KPIs → user list → user detail (role change or suspend) → moderation queue → flagged reports → taxonomy → AI config → audit log | M4 | M2 |
| F13 | Subscription & Payments | Student | Buy and manage a premium tier securely | Paywall → plan select → compare → order summary (BHD) → Tap card or BenefitPay → processing → server-side verification → entitlement → receipt → manage | M3 | M5 |
| F14 | Notifications & Reminders | All | Bring the user back at exactly the right moment | Server event or local schedule → relevance and quiet-hours filter → FCM push or local notification → tap → deep link → inbox → preferences | M1 | M3 |
### 7.1 The advanced feature, kept separate from the core features

The brief requires the feature list to *"include one approved advanced feature"*, and the tutor's
written approval added a condition: **F15 must be separate from the core AI features.** It is
therefore lifted **out** of the table above rather than sitting as an eighteenth row among F03, F04,
F05 and F11.

**Why the separation is not cosmetic.** F03, F04, F05 and F11 are each a *single* AI generation task
against one material, with the model given the material and asked for an artefact. F15 is a
**retrieval-augmented system**: it indexes a corpus, retrieves against a query, constrains generation
to what it retrieved, and reasons over the student's own measured mastery to plan what to study next.
Reading it as a fifth AI feature would understate it, and the tutor asked for it to be presented so
that it cannot be read that way.

| Field | Value |
|---|---|
| **ID** | **F15 · AI Study Companion** (retrieval-augmented generation + adaptive coach) |
| **Role** | Student |
| **Main task** | Ask anything grounded in your own materials, and receive a personalised study path |
| **Flow** | Ask → on-device embedding search over own library → grounded answer with citation chips → adjust explanation level → recommended study path → rate response |
| **Screens** | `73`–`80` (8 frames, group H) |
| **Developer(s)** | **M2 + M3** — exactly two, the brief's maximum |
| **Tester** | **M1** — independent; neither developer tests it |
| **Tutor approval** | ✅ **Approved in writing, 15 Oct 2026** (§3.4) |

*Table 7.2, the advanced feature's identity, kept out of the master feature table so it cannot read as an eighteenth core feature.*

**Who does what.** The approval also required each developer's part to be named, so the split is
stated here as well as in §8.4:

| Developer | Owns | Delivers |
|---|---|---|
| **M2** Mohammed Almadhoon | **Retrieval and generation layer** — the half that decides *what the model is allowed to see* | Chunking with page and offset, the on-device `NLEmbedding` index, cosine-similarity retrieval, the prompt contract, citation enforcement, and the `AIProvider` routing seam. Screens `73`, `74`, `75`, `76`, `79`, `80` |
| **M3** Tasbeeh Saeed | **Planner and router integration** — the half that decides *what the student should do next* | The adaptive study path over `topicMastery`, the tier-selection policy, the cost governor integration, and graceful degradation when on-device intelligence is unavailable. Screens `77`, `78` |

*Table 7.3, which developer is responsible for which part of F15, as the tutor's approval required.*

**The split is deliberately disjoint**, so neither developer can block the other: the two halves meet
at one protocol boundary, and each is independently testable and independently demoable. Full scope,
deliverables and the interface contract are in **§8.4**; the dependencies this introduces are in
**§8.5**.

| F16 | Admin-Moderated Group Chat | Admin, Study Group Member | Talk to a study group inside a chat an admin moderates and is always present in | Open group chat → admin presence banner → post and read messages → moderator pins an announcement → hide, delete or flag any message with a reason → tombstone shown → action written to the audit log | M5 | M4 |
| F17 | Active Recall Space (Anki-style spaced repetition) | Student | Review everything due across every deck in one place, the way Anki does | Recall Space home → due-today counts by card state → filter by deck or tag → session → flip → rate Again/Hard/Good/Easy with the next interval shown → learning steps graduate the card → summary → retention, heatmap and streak | M5 | M2 |

**Workload balance:** every member owns at least two features (M1: 3, M2: 4 plus shared F15, M3: 3 plus shared F15, M4: 4, M5: 2), meeting the rubric minimum of two per student. M5's two are both **net-new** — a new module, its own security rules and tests each — and she also carries a three-feature testing rotation, so effort is balanced even though feature count is not; the 13 F16/F17 frames were drawn by M1 and M3 and are credited to them, not to her. The full frames-and-testers view is in [doc 02 §3](../../docs/02-FEATURE-LIST-OWNERSHIP.md). **Advanced feature:** F15, co-owned by M2 and M3, whose feature areas are deliberately disjoint so neither can block the other.

**Sub-tasks and edge cases.** Each of the 17 features is expanded into an ordered sub-task list with explicit edge cases and error handling, and the Firestore collections it touches. These expansions are what the prototype's error and feedback states are built from. The full expansion is maintained in `docs/02-FEATURE-LIST-OWNERSHIP.md` §6 and is reproduced feature by feature alongside the mockups in §10.

*Table 7.1, the master feature list (required columns: feature name, main task, user, sub-tasks/steps, developer, tester).*

## 8. Advanced feature specification (F15, AI Study Companion)

The brief permits one approved advanced feature co-owned by one or two developers. StudyForge's advanced feature is a **retrieval-augmented (RAG) study companion** that answers questions grounded strictly in the student's own material and produces an adaptive study path. It is co-owned by **M2** (retrieval and grounding) and **M3** (the planner and the AI-router integration).

### 8.1 Why it is genuinely advanced

It combines four capabilities that most student projects do not attempt together:

1. **On-device semantic search** over a private corpus (the student's own library), with vectors held only on the device.
2. **Grounding with visible provenance**, every answer carries citation chips back to the source page, and the assistant says "no relevant source found" rather than guessing.
3. **A per-query router** that decides whether to answer on-device, in the cloud, or to degrade, based on availability, network, budget and task type.
4. **A planner that learns from measured mastery**, quiz attempts write `topicMastery`, and the companion reads it to propose what to study next.

### 8.2 How it works

| Step | Mechanism |
|---|---|
| Indexing | When material is added, its extracted text is chunked with page and character offsets and embedded. Vectors live on-device in SwiftData, never in the cloud. |
| Retrieval | A query is embedded and the top-k chunks are retrieved by cosine similarity. |
| Grounding | The prompt is built only from those chunks and their ids. The model is constrained to the provided text and is never asked a free-recall question. |
| Answering | The response streams with citation chips. Tapping a chip opens a source sheet at the cited page. |
| Adaptation | Quiz attempts write `topicMastery`; the companion reads it to propose a study path and to adjust the explanation level. |
| Degradation | If on-device intelligence is unavailable, the app explains why and offers the cloud path (`80_Coach_OnDeviceUnavailable_Fallback`) instead of failing silently. |

*Table 8.1, the retrieval-augmented generation pipeline, step by step.*

### 8.3 Contracts and error handling

`RetrievalService` and `CoachPlanningService` are protocols, so the retrieval implementation and the planner can each be swapped or unit-tested in isolation. Edge cases handled explicitly: no relevant chunk found (say so), on-device model unavailable (fallback screen), very long answers (chunked streaming), a cited material deleted (the citation degrades gracefully), and a low-confidence response (flagged for the student).

*Figure 8.1, the RAG pipeline (index, retrieve, ground, answer, adapt): [mockups/figures/PIPE_RAGPipeline_StudyForge.png](mockups/figures/PIPE_RAGPipeline_StudyForge.png). The six steps are the rows of Table 8.1, drawn with the constraint that keeps them honest: vectors stay on the device, the prompt is built only from retrieved chunks, and a response is cited.*

### 8.4 Ownership split, and the contract between the two halves

The tutor's approval required each developer's part to be named. It is stated in §7.1 and expanded
here, because the split is the reason a two-developer advanced feature is safe rather than risky.

| Developer | Scope | Deliverables | Screens |
|---|---|---|---|
| **M2** Mohammed Almadhoon | **Retrieval and generation** — *what the model is allowed to see* | Text chunking carrying page and character offsets; the on-device `NLEmbedding` index held in SwiftData; cosine-similarity top-k retrieval; the prompt contract that admits only retrieved chunk ids; citation enforcement, where a claim with no supporting chunk is **dropped rather than emitted**; the `AIProvider` routing seam | `73`, `74`, `75`, `76`, `79`, `80` |
| **M3** Tasbeeh Saeed | **Planner and router integration** — *what the student should do next* | The adaptive study path built over `topicMastery`; the tier-selection policy across on-device, cloud and server; `AICostGovernor` integration and the daily allowance; graceful degradation when on-device intelligence is unavailable | `77`, `78` |

*Table 8.2, the F15 ownership split with deliverables, expanded from Table 7.3.*

**The contract between them is one protocol boundary**, and that is what keeps the two halves
non-blocking:

| Protocol | Written by | Consumed by | Why the boundary is here |
|---|---|---|---|
| `RetrievalService` | M2 | M3 | M3's planner must be able to ask *"what does the student's own material say about this topic?"* without knowing how retrieval works |
| `CoachPlanningService` | M3 | M2 | M2's answer screen must be able to ask *"what should this student do next?"* without knowing how the plan is built |

*Table 8.3, the two protocols that form the interface between F15's two halves.*

Both are protocols, so **each half is unit-testable against a stub of the other**, and neither
developer is blocked while the other is mid-change. This is the same seam discipline the rest of the
codebase uses (`AIProvider`, `MaterialStore`, `SubscriptionStore`), applied where the risk of a
two-person feature is highest.

### 8.5 Dependencies this feature introduces

The approval required these to be noted, and the reason is that **F15 cannot work without two
features it does not own.** If either changes, F15 breaks in a way that is not obvious from F15's own
code.

| Depends on | What F15 takes from it | If it changes, what breaks in F15 |
|---|---|---|
| **F02 · Material Upload & Course Library** (M1) | The **corpus**. Extraction produces the text; chunking and embedding run over it, and a citation points at a **page and offset within the extracted text**. F15 retrieves nothing if there is no library | A change to extraction or to the stored text shape invalidates **every existing vector**, so the index must be rebuilt — and a citation that referenced an offset no longer opens the right page. **F15 has no corpus of its own**; it is entirely a function of F02's output |
| **F05 · Quiz Generation & Attempt Analytics** (M2) | The **mastery signal**. Quiz attempts write `topicMastery`, and the adaptive planner reads it to order the path and to pick what to revise first | The planner degrades to a **generic path** — read → cards → quiz → review — in a fixed order with no personalisation. **F15 still functions, but stops being adaptive**, which is the half of the feature that makes it advanced. Note the awkwardness and own it: **F05's developer is also F15's M2**, so a change to the mastery shape is a change one person makes in two places |
| **F03, F04** (M2) | Not a hard dependency, but the **shared generation pipeline**. F15 routes through the same `AIProvider` seam and the same tier policy | A change to the router's tier policy or the `AIProvider` protocol affects F03, F04, F05 and F15 together. This is a strength (one policy, one place) and a coupling (one mistake, four features) |

*Table 8.4, the features F15 depends on, and what breaks in F15 if each one changes.*

**Why this note is worth having in the document rather than in someone's head.** Both dependencies
point **inward**, at features owned by other people: F02 is M1's, and F05 is M2's. That means the
critical path for the advanced feature runs through work that is *not* the advanced feature's own.
Recording it here is what makes that visible to a reader — and to us, when planning the freeze.

**The honest statement to make in the VIVA:** F15 is the most technically ambitious feature in the
project and it **sits on top of two features it does not own**. That is a normal and acceptable
dependency for a retrieval system, but it is a dependency, and saying so is better than presenting
F15 as self-contained.


## 9. Feature flows

Each feature is broken into an ordered set of steps (the brief's "sub-tasks or individual steps"). These are the steps the prototype wires and the acceptance tests exercise. The 17 flow diagrams are drawn in Figma page `2 · Flow Overview` and reproduced as figures at export.

| Feature | Sub-tasks / steps |
|---|---|
| F01 Authentication | 1 Launch and splash, 2 three onboarding slides, 3 sign up with email, 4 verify email, 5 open the verification link, 6 complete the 3-step profile wizard, 7 land on the role home |
| F02 Upload & Library | 1 Tap Upload, 2 choose source, 3 downscale and compress, 4 OCR and text extraction with page markers, 5 upload to Storage, 6 write metadata, 7 item appears in Library |
| F03 AI Summary | 1 Open material, 2 Generate then Summary, 3 set length, style and language, 4 router picks a tier, 5 stream generation, 6 attach provenance chips, 7 save to a folder |
| F04 Flashcards & SR | 1 Choose source and card config, 2 generate cards, 3 review and edit, 4 save to deck, 5 start review session, 6 flip and rate Again/Hard/Good/Easy, 7 SM-2 computes next due date, 8 session summary |
| F05 Quiz & Analytics | 1 Configure quiz, 2 generate questions, 3 answer with immediate feedback, 4 submit (confirm unanswered), 5 scorecard, 6 review explanations, 7 attempt writes `topicMastery` |
| F06 Study Plan | 1 Wizard: subjects, 2 availability, 3 deadlines, 4 intensity, 5 generate plan, 6 week and month calendar, 7 session reminders, 8 miss a session, 9 accept an AI re-plan |
| F07 Progress | 1 Activity events written by other features, 2 nightly aggregation, 3 dashboard (streak, mastery, hours), 4 subject breakdown, 5 weakness radar, 6 achievements, 7 export PDF |
| F08 Shared Folders | 1 Create folder, 2 invite by code, link or picker, 3 set per-member permission, 4 members add material and artefacts, 5 folder activity feed, 6 owner revokes access |
| F09 Group Spaces | 1 Join group by code, 2 shared board loads, 3 group chat, 4 host launches live quiz, 5 members answer in real time, 6 live leaderboard, 7 results and topic accuracy |
| F10 Bookmarks | 1 Bookmark from any screen, 2 choose or create a collection, 3 optional save offline, 4 item appears in the collection, 5 open later via deep link |
| F11 Tutor Studio | 1 Create course, 2 build roster, 3 publish material, 4 AI content lands in the review queue, 5 approve, edit or reject with a reason, 6 cohort progress, 7 announcement, 8 gradebook export |
| F12 Admin | 1 Admin home KPIs, 2 search users, 3 change role or suspend with a reason, 4 moderation queue, 5 resolve flagged reports, 6 manage taxonomy, 7 configure AI routing and quotas, 8 review the audit log |
| F13 Payments | 1 Paywall, 2 select plan, 3 order summary in BHD with VAT, 4 choose method, 5 simulated card or BenefitPay (no live provider is contacted), 6 processing, 7 simulated success or failure result, 8 demo entitlement written, 9 demo receipt, 10 manage or cancel |
| F14 Notifications | 1 Server event or local schedule fires, 2 relevance and quiet-hours filter, 3 deliver FCM or local notification, 4 tap deep-links to the screen, 5 inbox history, 6 preferences respected |
| F15 Companion | 1 Ask a question, 2 embed the query on-device, 3 retrieve top-k chunks, 4 build a grounded prompt, 5 router picks a tier, 6 streamed answer with citations, 7 tap citation to source, 8 adjust explanation level, 9 request a study path, 10 capture feedback |
| F16 Moderated chat | 1 Open the group chat, 2 admin presence banner and shield badge render, 3 post and read messages, 4 moderator pins an announcement, 5 long-press a message, 6 choose hide/delete/pin/flag, 7 capture a reason, 8 tombstone replaces the body, 9 the action is written to the append-only audit log |
| F17 Recall Space | 1 Open the Recall Space, 2 build the due-today queue across every deck, 3 show counts by card state, 4 optionally filter by deck or tag, 5 start the session, 6 reveal, 7 rate with the next interval shown, 8 learning steps graduate the card, 9 session summary, 10 retention, heatmap and streak update |

*Table 9.1, every feature expanded into its ordered sub-tasks and steps.*

Every step above has at least one designed error or empty state, since the brief requires error and feedback states. Representative examples: F05, the timer expiring auto-submits; F04, rating a card then closing early saves partially; F08, an expired invite code shows a recovery action; F13, a declined card and a 3-D Secure timeout both resolve to a clear next step.

**Figures 9.1 to 9.17, one flow diagram per feature.** Each diagram is drawn on Figma page `2 · Flow Overview`, named `FLOW_Fnn_…` with its owner, and exported at 2× into `deliverables/design-document/mockups/figures/`. Every diagram ends with the error or edge case the flow must survive, which is how the brief's error and feedback requirement is evidenced per feature. `FLOW_F13` is titled *Subscription & Payments (Demo)* and ends by stating that the prototype involves **no real charges, no payment-provider handoff and no payment webhook** — the same limitation the wireframes and §16.1 carry.

| Figure | Feature | Diagram file |
|---|---|---|
| 9.1 | F01 Authentication and role onboarding | [FLOW_F01_Authentication_Role_Onboarding_Saleh.png](mockups/figures/FLOW_F01_Authentication_Role_Onboarding_Saleh.png) |
| 9.2 | F02 Material upload and library | [FLOW_F02_Material_Upload_Library_Saleh.png](mockups/figures/FLOW_F02_Material_Upload_Library_Saleh.png) |
| 9.3 | F03 AI summary and notes | [FLOW_F03_AI_Summary_Notes_Mohammed.png](mockups/figures/FLOW_F03_AI_Summary_Notes_Mohammed.png) |
| 9.4 | F04 Flashcards and spaced repetition | [FLOW_F04_Flashcards_Spaced_Repetition_Mohammed.png](mockups/figures/FLOW_F04_Flashcards_Spaced_Repetition_Mohammed.png) |
| 9.5 | F05 Quiz generation and analytics | [FLOW_F05_Quiz_Generation_Analytics_Mohammed.png](mockups/figures/FLOW_F05_Quiz_Generation_Analytics_Mohammed.png) |
| 9.6 | F06 Study plan and adaptive re-planning | [FLOW_F06_Study_Plan_Adaptive_Re_planning_Tasbeeh.png](mockups/figures/FLOW_F06_Study_Plan_Adaptive_Re_planning_Tasbeeh.png) |
| 9.7 | F07 Progress tracking | [FLOW_F07_Progress_Tracking_Tasbeeh.png](mockups/figures/FLOW_F07_Progress_Tracking_Tasbeeh.png) |
| 9.8 | F08 Shared study folders | [FLOW_F08_Shared_Study_Folders_Shahad.png](mockups/figures/FLOW_F08_Shared_Study_Folders_Shahad.png) |
| 9.9 | F09 Group revision spaces | [FLOW_F09_Group_Revision_Spaces_Shahad.png](mockups/figures/FLOW_F09_Group_Revision_Spaces_Shahad.png) |
| 9.10 | F10 Resource bookmarking | [FLOW_F10_Resource_Bookmarking_Shahad.png](mockups/figures/FLOW_F10_Resource_Bookmarking_Shahad.png) |
| 9.11 | F11 Tutor content studio | [FLOW_F11_Tutor_Content_Studio_Mohammed.png](mockups/figures/FLOW_F11_Tutor_Content_Studio_Mohammed.png) |
| 9.12 | F12 Admin content management | [FLOW_F12_Admin_Content_Management_Shahad.png](mockups/figures/FLOW_F12_Admin_Content_Management_Shahad.png) |
| 9.13 | F13 Subscription and payments | [FLOW_F13_Subscription_Payments_Tap_Tasbeeh.png](mockups/figures/FLOW_F13_Subscription_Payments_Tap_Tasbeeh.png) |
| 9.14 | F14 Notifications and reminders | [FLOW_F14_Notifications_Reminders_Saleh.png](mockups/figures/FLOW_F14_Notifications_Reminders_Saleh.png) |
| 9.15 | F15 AI study companion (advanced) | [FLOW_F15_AI_Study_Companion_advanced_Mohammed_Tasbeeh.png](mockups/figures/FLOW_F15_AI_Study_Companion_advanced_Mohammed_Tasbeeh.png) |
| 9.16 | F16 Admin-moderated group chat | [FLOW_F16_Moderated_Group_Chat_Saleh.png](mockups/figures/FLOW_F16_Moderated_Group_Chat_Saleh.png) |
| 9.17 | F17 Active recall space | [FLOW_F17_Active_Recall_Space_Tasbeeh.png](mockups/figures/FLOW_F17_Active_Recall_Space_Tasbeeh.png) |

## 10. Low-fidelity mockups

### 10.1 Organisation and naming

The prototype is built in a single Figma file with one **page per owner**, so authorship is visible at a glance. Every frame is named to the brief's rule, `NN_ScreenName_FirstName_StudentID`, for example `03_Onboarding_HowItWorks_Saleh_202300540` and `142_GroupChat_Moderator_Presence_Banner_Saleh_202300540`. The file holds **123 frames** across the feature groups below, plus **130 low-fidelity wireframes** on page `5 · Low-Fi Wireframes` and **17 per-feature flow diagrams** on page `2 · Flow Overview` (all 17 exported). The full per-screen inventory with descriptions lives in `docs/03-SCREEN-INVENTORY.md` and is attached at export as Appendix A. Every wireframe and every flow diagram is exported at 2× into `deliverables/design-document/mockups/figures/` (154 PNGs, plus the page headers and the navigation map) and is numbered in the List of figures and in §10.4.

| Group | Area | Owner | Frames | Count |
|---|---|---|---|---|
| A | Onboarding & Auth | M1 | 01–10 | 10 |
| B | Profile & Settings | M1 | 11–18 | 8 |
| C | Courses & Library | M1 | 24–31, 33–34 | 10 |
| D | AI Summaries | M2 | 35–38, 41 | 5 |
| E | Flashcards | M2 | 42–48 | 7 |
| F | Quizzes | M2 | 51–59 | 9 |
| G | Study Plan & Progress | M3 | 60–65, 68–70 | 9 |
| H | AI Study Companion (F15) | M2 + M3 | 73–78 | 6 |
| I | Collaboration | M4 | 81–86, 88–97 | 16 |
| J | Tutor Content Studio | M2 | 99, 101–105 | 6 |
| K | Admin Content Management | M4 | 109–112, 115 | 5 |
| L | Subscription & Payments | M3 | 155–157, 172–179 | 11 |
| M | System, States & Feedback | M1 | 128, 129, 132–134, 138, 139, 141 | 8 |
| N | Admin-Moderated Group Chat (F16) | M5 | 142–147 | 6 |
| O | Active Recall Space (F17) | M5 | 148–154 | 7 |
| | **Total** | | | **123** |

*Table 10.1, the 123 screens grouped by feature area, with the owning member.*

**Group L, superseded 24 October 2026.** The seven first-cut F13 screens (`118`, `120`–`122`, `124`–`126`) were replaced by eleven subscription-state screens (`155`–`157`, `172`–`179`) as the feature was reworked around an explicitly **simulated** payment flow: study-to-unlock and trial activation, the Exam Boost one-time purchase, the Pro monthly checkout, the processing-then-failure state, and subscription management through to cancellation. The wireframes for the retired seven (`LF_118`, `LF_120`–`LF_122`, `LF_124`–`LF_126`) are **kept on page 5 as the design record of that first pass**, and the eleven current screens each have a wireframe of their own.


**Groups N and O — built 15 October 2026.** The two features added with the fifth member are drawn and named to the brief's rule, taking page `3 · Screens` from **106 to 119 frames**, and then to **123** once group L was reworked. The frames carry the members who drew them (`Saleh_202300540` for F16, `Tasbeeh_202305409` for F17) while the **features** remain M5's:

| Group | Area | Owner | Frames | Count |
|---|---|---|---|---|
| N | Admin-Moderated Group Chat (F16) | M5 | 142–147 | 6 |
| O | Active Recall Space (F17) | M5 | 148–154 | 7 |

**The low-fidelity gap is closed (24 October 2026).** Page `5 · Low-Fi Wireframes` now carries **130 wireframes**, so every built screen has a low-fidelity counterpart. The original 106 are joined by the **13 F16/F17 wireframes** (`LF_142`–`LF_147`, `LF_148`–`LF_154`) that the 15 October audit recorded as missing, and by the **11 F13 subscription-state wireframes** (`LF_155`–`LF_157`, `LF_172`–`LF_179`) drawn from the current prototype screens. The supervisor's answer at §3.3 (question 5) was explicit that **low-fidelity is what the mockup component expects**, which is why the 24 new screens were given low-fidelity counterparts rather than left as finished screens only. The two N and O rows above are therefore no longer a stated gap. Because the brief names every frame **by developer**, the whole F16/F17 Figma set — the 13 screens, their 13 dark variants and the 13 wireframes — carries `Saleh_202300540` for F16 and `Tasbeeh_202305409` for F17, the two members who drew it; M5 owns both features and her contribution is recorded where it lies, in the two Swift modules and her three-feature testing rotation.

Frames per developer: **M1 Saleh 42 · M2 Mohammed 31 · M3 Tasbeeh 29 · M4 Shahad 21 · M5 Fatema 0** — **123** in total. The split follows the brief's *named-by-developer* rule, so it counts who drew each frame rather than who owns the feature: M5 owns F16 and F17 and her contribution is their two Swift modules and her three-feature testing rotation, while the 13 F16/F17 frames were drawn by M1 (F16) and M3 (F17). The per-screen purpose-and-layout descriptions, the coverage audit against all 17 features and the state-coverage audit are in `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md`.

### 10.2 The description standard (worked example)

Every screen is described in the same three-part form, so a marker can check that UI elements are labelled **and** their function is explained. Worked example, `15_Home_Dashboard_Student` (F07, student home):

**Purpose.** The student's landing screen: today's plan, the streak, and the fastest route into the four core actions.

**Labelled UI elements and their function.**

| Element | Type | Function |
|---|---|---|
| Greeting header | Static label | Personal welcome and current term context |
| Streak flame and count | Data display | Reinforces the retrieval-habit loop; taps to the streak detail |
| Today's plan card | Container (hero) | Shows the next 3 scheduled sessions; taps into the plan |
| Due-cards badge | Data display | Number of flashcards due today; taps to review |
| Upload tile | Action tile | Opens the upload flow (F02) |
| Summarise tile | Action tile | Opens the generate sheet (F03) |
| Quiz tile | Action tile | Opens quiz config (F05) |
| Plan tile | Action tile | Opens the study-plan view (F06) |
| Bottom tab bar | Navigation | Home, Library, Coach, Practise, Plan |

*Table 10.2, the labelled-element standard, worked example (student home).*

**States.** Default, loading (skeleton), empty (new user with no material), offline banner, error with retry.

Every other screen follows this template. The per-feature tables below list the screens that exist with a one-line purpose each; the labelled-element tables for all of them are the content of Appendix A.

| Feature | Screens | One-line purpose each |
|---|---|---|
| F01 Auth | 01–10 | Splash, 3 onboarding, sign up, verify, profile wizard steps |
| F02 Upload & Library | C01–C11 | Upload source picker, OCR progress, library list, filters, viewer |
| F03 Summary | D01–D07 | Generate sheet, streaming, result, key points, glossary, citations, save |
| F04 Flashcards | E01–E09 | Config, generation, card editor, deck list, front, back, rating, summary |
| F05 Quiz | F01–F09 | Config, question, correct, incorrect, scorecard, explanations, revision |
| F06 Plan | G01–G11 | Wizard steps, generated plan, week and month calendar, session detail |
| F07 Progress | G12–G20 | Dashboard, subject breakdown, weakness radar, achievements, export |
| F08 Shared Folders | I01–I09 | Folder list, create, invite, permissions, member view, activity feed |
| F09 Group Spaces | I10–I17 | Group join, board, chat, live quiz host and player, results, leaderboard |
| F10 Bookmarks | C12–C16 | Bookmark action, collection picker, create, collection view, resume |
| F11 Tutor Studio | J01–J07 | Dashboard, course list, course editor, material publish, review queue |
| F12 Admin | K01–K07 | Dashboard, users, user detail, moderation, reports, taxonomy, AI config |
| F13 Payments | L01–L09 | Paywall, plan compare, order summary, method, processing, receipt |
| F14 Notifications | B06–B09, M | Preferences, inbox, notification detail, permission states |
| F15 Companion | H01–H06 | Coach chat, citation sheet, explanation level, study path, feedback |
| F16 Moderated chat | N01–N06 | Moderator presence banner, message action sheet, tombstone, reason sheet, slow-mode notice, audit row |
| F17 Recall Space | O01–O07 | Due-today queue, session front and back, daily limits, stats, deck filter, empty state |
| States (all) | M01–M14 | Loading, empty, offline, error, quota, success, permission denied |

*Table 10.3, the screens that implement each feature, with a one-line purpose each.*

### 10.3 Error and feedback states

The brief requires success, error and feedback states. A dedicated state set exists for every screen: loading skeleton, empty, offline, server error with retry, quota exceeded, invalid input (inline), permission denied, payment declined, and success confirmations with undo where destructive. These are designed once as components (`Figure 10.1`) and applied consistently.

*Figure 10.1, the cross-cutting state set as built, exported from Figma page `4 · States & Prototype Wiring`: [figures/03_States_StudyForge.png](figures/03_States_StudyForge.png).*

### 10.4 Figure index, the 130 wireframes

Figures 10.2 to 10.131 are the 130 wireframes, numbered in screen order. Each figure is the
Figma frame for that screen, exported at 2×, and contains the greyscale wireframe with its
numbered callout badges beside the legend panel that names every element and its function.
The written half of Appendix A is `mockups/SCREEN-DESCRIPTIONS.md`.

| Figure | Screen | Wireframe file |
|---|---|---|
| 10.2 | `01` | [LF_01_Splash_Logo_Saleh_202300540.png](mockups/figures/LF_01_Splash_Logo_Saleh_202300540.png) |
| 10.3 | `02` | [LF_02_Onboarding_ValueProp_Saleh_202300540.png](mockups/figures/LF_02_Onboarding_ValueProp_Saleh_202300540.png) |
| 10.4 | `03` | [LF_03_Onboarding_HowItWorks_Saleh_202300540.png](mockups/figures/LF_03_Onboarding_HowItWorks_Saleh_202300540.png) |
| 10.5 | `04` | [LF_04_Onboarding_AIPrivacy_Saleh_202300540.png](mockups/figures/LF_04_Onboarding_AIPrivacy_Saleh_202300540.png) |
| 10.6 | `05` | [LF_05_SignUp_Email_Saleh_202300540.png](mockups/figures/LF_05_SignUp_Email_Saleh_202300540.png) |
| 10.7 | `06` | [LF_06_SignUp_OTP_Verify_Saleh_202300540.png](mockups/figures/LF_06_SignUp_OTP_Verify_Saleh_202300540.png) |
| 10.8 | `07` | [LF_07_Login_Saleh_202300540.png](mockups/figures/LF_07_Login_Saleh_202300540.png) |
| 10.9 | `08` | [LF_08_ForgotPassword_Request_Saleh_202300540.png](mockups/figures/LF_08_ForgotPassword_Request_Saleh_202300540.png) |
| 10.10 | `09` | [LF_09_ForgotPassword_Confirm_Saleh_202300540.png](mockups/figures/LF_09_ForgotPassword_Confirm_Saleh_202300540.png) |
| 10.11 | `10` | [LF_10_RoleSelect_Saleh_202300540.png](mockups/figures/LF_10_RoleSelect_Saleh_202300540.png) |
| 10.12 | `11` | [LF_11_ProfileSetup_Academic_Saleh_202300540.png](mockups/figures/LF_11_ProfileSetup_Academic_Saleh_202300540.png) |
| 10.13 | `12` | [LF_12_ProfileSetup_LearningStyle_Saleh_202300540.png](mockups/figures/LF_12_ProfileSetup_LearningStyle_Saleh_202300540.png) |
| 10.14 | `13` | [LF_13_ProfileSetup_StudyGoals_Saleh_202300540.png](mockups/figures/LF_13_ProfileSetup_StudyGoals_Saleh_202300540.png) |
| 10.15 | `14` | [LF_14_ProfileSetup_Complete_Saleh_202300540.png](mockups/figures/LF_14_ProfileSetup_Complete_Saleh_202300540.png) |
| 10.16 | `15` | [LF_15_Home_Dashboard_Student_Saleh_202300540.png](mockups/figures/LF_15_Home_Dashboard_Student_Saleh_202300540.png) |
| 10.17 | `16` | [LF_16_Profile_View_Saleh_202300540.png](mockups/figures/LF_16_Profile_View_Saleh_202300540.png) |
| 10.18 | `17` | [LF_17_Profile_Edit_Saleh_202300540.png](mockups/figures/LF_17_Profile_Edit_Saleh_202300540.png) |
| 10.19 | `18` | [LF_18_Settings_Main_Saleh_202300540.png](mockups/figures/LF_18_Settings_Main_Saleh_202300540.png) |
| 10.20 | `24` | [LF_24_Courses_List_Saleh_202300540.png](mockups/figures/LF_24_Courses_List_Saleh_202300540.png) |
| 10.21 | `25` | [LF_25_Course_Detail_Saleh_202300540.png](mockups/figures/LF_25_Course_Detail_Saleh_202300540.png) |
| 10.22 | `26` | [LF_26_MaterialUpload_SourcePicker_Saleh_202300540.png](mockups/figures/LF_26_MaterialUpload_SourcePicker_Saleh_202300540.png) |
| 10.23 | `27` | [LF_27_MaterialUpload_Compress_Progress_Saleh_202300540.png](mockups/figures/LF_27_MaterialUpload_Compress_Progress_Saleh_202300540.png) |
| 10.24 | `28` | [LF_28_MaterialUpload_Processing_OCR_Saleh_202300540.png](mockups/figures/LF_28_MaterialUpload_Processing_OCR_Saleh_202300540.png) |
| 10.25 | `29` | [LF_29_MaterialUpload_Success_Saleh_202300540.png](mockups/figures/LF_29_MaterialUpload_Success_Saleh_202300540.png) |
| 10.26 | `30` | [LF_30_MaterialUpload_Error_UnsupportedFormat_Saleh_202300540.png](mockups/figures/LF_30_MaterialUpload_Error_UnsupportedFormat_Saleh_202300540.png) |
| 10.27 | `31` | [LF_31_Library_Materials_List_Saleh_202300540.png](mockups/figures/LF_31_Library_Materials_List_Saleh_202300540.png) |
| 10.28 | `33` | [LF_33_Material_Detail_Viewer_Saleh_202300540.png](mockups/figures/LF_33_Material_Detail_Viewer_Saleh_202300540.png) |
| 10.29 | `34` | [LF_34_Material_GenerateActionSheet_Saleh_202300540.png](mockups/figures/LF_34_Material_GenerateActionSheet_Saleh_202300540.png) |
| 10.30 | `35` | [LF_35_Summary_Configure_Mohammed_202401702.png](mockups/figures/LF_35_Summary_Configure_Mohammed_202401702.png) |
| 10.31 | `36` | [LF_36_Summary_Generating_Mohammed_202401702.png](mockups/figures/LF_36_Summary_Generating_Mohammed_202401702.png) |
| 10.32 | `37` | [LF_37_Summary_Result_Mohammed_202401702.png](mockups/figures/LF_37_Summary_Result_Mohammed_202401702.png) |
| 10.33 | `38` | [LF_38_Summary_Provenance_Citation_Mohammed_202401702.png](mockups/figures/LF_38_Summary_Provenance_Citation_Mohammed_202401702.png) |
| 10.34 | `41` | [LF_41_Summary_Error_QuotaExceeded_Mohammed_202401702.png](mockups/figures/LF_41_Summary_Error_QuotaExceeded_Mohammed_202401702.png) |
| 10.35 | `42` | [LF_42_Decks_List_Mohammed_202401702.png](mockups/figures/LF_42_Decks_List_Mohammed_202401702.png) |
| 10.36 | `43` | [LF_43_Flashcards_Generate_Config_Mohammed_202401702.png](mockups/figures/LF_43_Flashcards_Generate_Config_Mohammed_202401702.png) |
| 10.37 | `44` | [LF_44_Flashcards_Generating_Mohammed_202401702.png](mockups/figures/LF_44_Flashcards_Generating_Mohammed_202401702.png) |
| 10.38 | `45` | [LF_45_Deck_Detail_Mohammed_202401702.png](mockups/figures/LF_45_Deck_Detail_Mohammed_202401702.png) |
| 10.39 | `46` | [LF_46_Flashcard_Review_Front_Mohammed_202401702.png](mockups/figures/LF_46_Flashcard_Review_Front_Mohammed_202401702.png) |
| 10.40 | `47` | [LF_47_Flashcard_Review_Back_Rate_Mohammed_202401702.png](mockups/figures/LF_47_Flashcard_Review_Back_Rate_Mohammed_202401702.png) |
| 10.41 | `48` | [LF_48_Flashcard_Session_Summary_Mohammed_202401702.png](mockups/figures/LF_48_Flashcard_Session_Summary_Mohammed_202401702.png) |
| 10.42 | `51` | [LF_51_Quizzes_List_Mohammed_202401702.png](mockups/figures/LF_51_Quizzes_List_Mohammed_202401702.png) |
| 10.43 | `52` | [LF_52_Quiz_Generate_Config_Mohammed_202401702.png](mockups/figures/LF_52_Quiz_Generate_Config_Mohammed_202401702.png) |
| 10.44 | `53` | [LF_53_Quiz_Generating_Mohammed_202401702.png](mockups/figures/LF_53_Quiz_Generating_Mohammed_202401702.png) |
| 10.45 | `54` | [LF_54_Quiz_Take_MCQ_Mohammed_202401702.png](mockups/figures/LF_54_Quiz_Take_MCQ_Mohammed_202401702.png) |
| 10.46 | `55` | [LF_55_Quiz_Feedback_Correct_Mohammed_202401702.png](mockups/figures/LF_55_Quiz_Feedback_Correct_Mohammed_202401702.png) |
| 10.47 | `56` | [LF_56_Quiz_Feedback_Incorrect_Mohammed_202401702.png](mockups/figures/LF_56_Quiz_Feedback_Incorrect_Mohammed_202401702.png) |
| 10.48 | `57` | [LF_57_Quiz_Submit_Confirm_Mohammed_202401702.png](mockups/figures/LF_57_Quiz_Submit_Confirm_Mohammed_202401702.png) |
| 10.49 | `58` | [LF_58_Quiz_Results_Scorecard_Mohammed_202401702.png](mockups/figures/LF_58_Quiz_Results_Scorecard_Mohammed_202401702.png) |
| 10.50 | `59` | [LF_59_Quiz_Review_Answers_Explanations_Mohammed_202401702.png](mockups/figures/LF_59_Quiz_Review_Answers_Explanations_Mohammed_202401702.png) |
| 10.51 | `60` | [LF_60_StudyPlan_Wizard_Subjects_Tasbeeh_202305409.png](mockups/figures/LF_60_StudyPlan_Wizard_Subjects_Tasbeeh_202305409.png) |
| 10.52 | `61` | [LF_61_StudyPlan_Wizard_Availability_Tasbeeh_202305409.png](mockups/figures/LF_61_StudyPlan_Wizard_Availability_Tasbeeh_202305409.png) |
| 10.53 | `62` | [LF_62_StudyPlan_Wizard_Deadlines_Tasbeeh_202305409.png](mockups/figures/LF_62_StudyPlan_Wizard_Deadlines_Tasbeeh_202305409.png) |
| 10.54 | `63` | [LF_63_StudyPlan_Wizard_Intensity_Tasbeeh_202305409.png](mockups/figures/LF_63_StudyPlan_Wizard_Intensity_Tasbeeh_202305409.png) |
| 10.55 | `64` | [LF_64_StudyPlan_Generating_Tasbeeh_202305409.png](mockups/figures/LF_64_StudyPlan_Generating_Tasbeeh_202305409.png) |
| 10.56 | `65` | [LF_65_StudyPlan_Calendar_Week_Tasbeeh_202305409.png](mockups/figures/LF_65_StudyPlan_Calendar_Week_Tasbeeh_202305409.png) |
| 10.57 | `68` | [LF_68_StudyPlan_Session_Detail_Tasbeeh_202305409.png](mockups/figures/LF_68_StudyPlan_Session_Detail_Tasbeeh_202305409.png) |
| 10.58 | `69` | [LF_69_Progress_Dashboard_Tasbeeh_202305409.png](mockups/figures/LF_69_Progress_Dashboard_Tasbeeh_202305409.png) |
| 10.59 | `70` | [LF_70_Progress_WeaknessRadar_Tasbeeh_202305409.png](mockups/figures/LF_70_Progress_WeaknessRadar_Tasbeeh_202305409.png) |
| 10.60 | `73` | [LF_73_Coach_Home_Mohammed_202401702.png](mockups/figures/LF_73_Coach_Home_Mohammed_202401702.png) |
| 10.61 | `74` | [LF_74_Coach_Chat_Conversation_Mohammed_202401702.png](mockups/figures/LF_74_Coach_Chat_Conversation_Mohammed_202401702.png) |
| 10.62 | `75` | [LF_75_Coach_ExplainLevel_Toggle_Mohammed_202401702.png](mockups/figures/LF_75_Coach_ExplainLevel_Toggle_Mohammed_202401702.png) |
| 10.63 | `76` | [LF_76_Coach_Citation_SourceSheet_Mohammed_202401702.png](mockups/figures/LF_76_Coach_Citation_SourceSheet_Mohammed_202401702.png) |
| 10.64 | `77` | [LF_77_Coach_StudyPath_Recommended_Tasbeeh_202305409.png](mockups/figures/LF_77_Coach_StudyPath_Recommended_Tasbeeh_202305409.png) |
| 10.65 | `78` | [LF_78_Coach_QuizMe_Voice_Tasbeeh_202305409.png](mockups/figures/LF_78_Coach_QuizMe_Voice_Tasbeeh_202305409.png) |
| 10.66 | `81` | [LF_81_Folder_Shared_List_Shahad_202305767.png](mockups/figures/LF_81_Folder_Shared_List_Shahad_202305767.png) |
| 10.67 | `82` | [LF_82_Folder_Detail_Shahad_202305767.png](mockups/figures/LF_82_Folder_Detail_Shahad_202305767.png) |
| 10.68 | `83` | [LF_83_Folder_Create_Edit_Shahad_202305767.png](mockups/figures/LF_83_Folder_Create_Edit_Shahad_202305767.png) |
| 10.69 | `84` | [LF_84_Folder_Invite_Members_Shahad_202305767.png](mockups/figures/LF_84_Folder_Invite_Members_Shahad_202305767.png) |
| 10.70 | `85` | [LF_85_Folder_InviteCode_Share_Shahad_202305767.png](mockups/figures/LF_85_Folder_InviteCode_Share_Shahad_202305767.png) |
| 10.71 | `86` | [LF_86_Folder_MemberPermissions_Shahad_202305767.png](mockups/figures/LF_86_Folder_MemberPermissions_Shahad_202305767.png) |
| 10.72 | `88` | [LF_88_GroupSpace_List_Shahad_202305767.png](mockups/figures/LF_88_GroupSpace_List_Shahad_202305767.png) |
| 10.73 | `89` | [LF_89_GroupSpace_JoinByCode_Shahad_202305767.png](mockups/figures/LF_89_GroupSpace_JoinByCode_Shahad_202305767.png) |
| 10.74 | `90` | [LF_90_GroupSpace_Detail_Board_Shahad_202305767.png](mockups/figures/LF_90_GroupSpace_Detail_Board_Shahad_202305767.png) |
| 10.75 | `91` | [LF_91_GroupSpace_Chat_Shahad_202305767.png](mockups/figures/LF_91_GroupSpace_Chat_Shahad_202305767.png) |
| 10.76 | `92` | [LF_92_GroupSpace_SharedQuiz_Lobby_Shahad_202305767.png](mockups/figures/LF_92_GroupSpace_SharedQuiz_Lobby_Shahad_202305767.png) |
| 10.77 | `93` | [LF_93_GroupSpace_SharedQuiz_Live_Shahad_202305767.png](mockups/figures/LF_93_GroupSpace_SharedQuiz_Live_Shahad_202305767.png) |
| 10.78 | `94` | [LF_94_GroupSpace_Quiz_Results_Leaderboard_Shahad_202305767.png](mockups/figures/LF_94_GroupSpace_Quiz_Results_Leaderboard_Shahad_202305767.png) |
| 10.79 | `95` | [LF_95_Bookmarks_Collections_Shahad_202305767.png](mockups/figures/LF_95_Bookmarks_Collections_Shahad_202305767.png) |
| 10.80 | `96` | [LF_96_Bookmark_Collection_Detail_Shahad_202305767.png](mockups/figures/LF_96_Bookmark_Collection_Detail_Shahad_202305767.png) |
| 10.81 | `97` | [LF_97_Bookmark_Save_Sheet_Shahad_202305767.png](mockups/figures/LF_97_Bookmark_Save_Sheet_Shahad_202305767.png) |
| 10.82 | `99` | [LF_99_Home_Dashboard_Tutor_Mohammed_202401702.png](mockups/figures/LF_99_Home_Dashboard_Tutor_Mohammed_202401702.png) |
| 10.83 | `101` | [LF_101_Tutor_Course_Create_Edit_Mohammed_202401702.png](mockups/figures/LF_101_Tutor_Course_Create_Edit_Mohammed_202401702.png) |
| 10.84 | `102` | [LF_102_Tutor_Course_Roster_Mohammed_202401702.png](mockups/figures/LF_102_Tutor_Course_Roster_Mohammed_202401702.png) |
| 10.85 | `103` | [LF_103_Tutor_Material_Publish_Mohammed_202401702.png](mockups/figures/LF_103_Tutor_Material_Publish_Mohammed_202401702.png) |
| 10.86 | `104` | [LF_104_Tutor_AI_Content_ReviewQueue_Mohammed_202401702.png](mockups/figures/LF_104_Tutor_AI_Content_ReviewQueue_Mohammed_202401702.png) |
| 10.87 | `105` | [LF_105_Tutor_AI_Content_EditApprove_Mohammed_202401702.png](mockups/figures/LF_105_Tutor_AI_Content_EditApprove_Mohammed_202401702.png) |
| 10.88 | `109` | [LF_109_Home_Dashboard_Admin_Shahad_202305767.png](mockups/figures/LF_109_Home_Dashboard_Admin_Shahad_202305767.png) |
| 10.89 | `110` | [LF_110_Admin_Users_List_Shahad_202305767.png](mockups/figures/LF_110_Admin_Users_List_Shahad_202305767.png) |
| 10.90 | `111` | [LF_111_Admin_User_Detail_Shahad_202305767.png](mockups/figures/LF_111_Admin_User_Detail_Shahad_202305767.png) |
| 10.91 | `112` | [LF_112_Admin_Moderation_Queue_Shahad_202305767.png](mockups/figures/LF_112_Admin_Moderation_Queue_Shahad_202305767.png) |
| 10.92 | `115` | [LF_115_Admin_AIConfig_Settings_Shahad_202305767.png](mockups/figures/LF_115_Admin_AIConfig_Settings_Shahad_202305767.png) |
| 10.93 | `118` | [LF_118_Paywall_Plans_Tasbeeh_202305409.png](mockups/figures/LF_118_Paywall_Plans_Tasbeeh_202305409.png) |
| 10.94 | `120` | [LF_120_Checkout_OrderSummary_BHD_Tasbeeh_202305409.png](mockups/figures/LF_120_Checkout_OrderSummary_BHD_Tasbeeh_202305409.png) |
| 10.95 | `121` | [LF_121_Payment_Method_Select_Tasbeeh_202305409.png](mockups/figures/LF_121_Payment_Method_Select_Tasbeeh_202305409.png) |
| 10.96 | `122` | [LF_122_Payment_Card_Entry_Tasbeeh_202305409.png](mockups/figures/LF_122_Payment_Card_Entry_Tasbeeh_202305409.png) |
| 10.97 | `124` | [LF_124_Payment_Processing_Tasbeeh_202305409.png](mockups/figures/LF_124_Payment_Processing_Tasbeeh_202305409.png) |
| 10.98 | `125` | [LF_125_Payment_Success_Receipt_Tasbeeh_202305409.png](mockups/figures/LF_125_Payment_Success_Receipt_Tasbeeh_202305409.png) |
| 10.99 | `126` | [LF_126_Payment_Failed_Retry_Tasbeeh_202305409.png](mockups/figures/LF_126_Payment_Failed_Retry_Tasbeeh_202305409.png) |
| 10.100 | `128` | [LF_128_Notifications_Inbox_Saleh_202300540.png](mockups/figures/LF_128_Notifications_Inbox_Saleh_202300540.png) |
| 10.101 | `129` | [LF_129_Notification_Permission_Request_Saleh_202300540.png](mockups/figures/LF_129_Notification_Permission_Request_Saleh_202300540.png) |
| 10.102 | `132` | [LF_132_Global_Search_Saleh_202300540.png](mockups/figures/LF_132_Global_Search_Saleh_202300540.png) |
| 10.103 | `133` | [LF_133_Error_NoInternet_OfflineBanner_Saleh_202300540.png](mockups/figures/LF_133_Error_NoInternet_OfflineBanner_Saleh_202300540.png) |
| 10.104 | `134` | [LF_134_Error_Server_Retry_Saleh_202300540.png](mockups/figures/LF_134_Error_Server_Retry_Saleh_202300540.png) |
| 10.105 | `138` | [LF_138_Accessibility_LargeText_Example_Saleh_202300540.png](mockups/figures/LF_138_Accessibility_LargeText_Example_Saleh_202300540.png) |
| 10.106 | `139` | [LF_139_RTL_Arabic_Example_Saleh_202300540.png](mockups/figures/LF_139_RTL_Arabic_Example_Saleh_202300540.png) |
| 10.107 | `141` | [LF_141_Logout_Confirm_Saleh_202300540.png](mockups/figures/LF_141_Logout_Confirm_Saleh_202300540.png) |
| 10.108 | `142` | [LF_142_GroupChat_Moderator_Presence_Banner_Saleh_202300540.png](mockups/figures/LF_142_GroupChat_Moderator_Presence_Banner_Saleh_202300540.png) |
| 10.109 | `143` | [LF_143_GroupChat_Message_Moderation_Menu_Saleh_202300540.png](mockups/figures/LF_143_GroupChat_Message_Moderation_Menu_Saleh_202300540.png) |
| 10.110 | `144` | [LF_144_GroupChat_Hidden_Message_Placeholder_Saleh_202300540.png](mockups/figures/LF_144_GroupChat_Hidden_Message_Placeholder_Saleh_202300540.png) |
| 10.111 | `145` | [LF_145_GroupChat_Moderation_Reason_Sheet_Saleh_202300540.png](mockups/figures/LF_145_GroupChat_Moderation_Reason_Sheet_Saleh_202300540.png) |
| 10.112 | `146` | [LF_146_GroupChat_SlowMode_Muted_Notice_Saleh_202300540.png](mockups/figures/LF_146_GroupChat_SlowMode_Muted_Notice_Saleh_202300540.png) |
| 10.113 | `147` | [LF_147_GroupChat_Moderation_Audit_Entry_Saleh_202300540.png](mockups/figures/LF_147_GroupChat_Moderation_Audit_Entry_Saleh_202300540.png) |
| 10.114 | `148` | [LF_148_RecallSpace_Home_DueToday_Tasbeeh_202305409.png](mockups/figures/LF_148_RecallSpace_Home_DueToday_Tasbeeh_202305409.png) |
| 10.115 | `149` | [LF_149_RecallSpace_Session_Front_Tasbeeh_202305409.png](mockups/figures/LF_149_RecallSpace_Session_Front_Tasbeeh_202305409.png) |
| 10.116 | `150` | [LF_150_RecallSpace_Session_Back_Rate_Tasbeeh_202305409.png](mockups/figures/LF_150_RecallSpace_Session_Back_Rate_Tasbeeh_202305409.png) |
| 10.117 | `151` | [LF_151_RecallSpace_Daily_Limits_Tasbeeh_202305409.png](mockups/figures/LF_151_RecallSpace_Daily_Limits_Tasbeeh_202305409.png) |
| 10.118 | `152` | [LF_152_RecallSpace_Stats_Tasbeeh_202305409.png](mockups/figures/LF_152_RecallSpace_Stats_Tasbeeh_202305409.png) |
| 10.119 | `153` | [LF_153_RecallSpace_Filter_By_Deck_Tasbeeh_202305409.png](mockups/figures/LF_153_RecallSpace_Filter_By_Deck_Tasbeeh_202305409.png) |
| 10.120 | `154` | [LF_154_RecallSpace_EmptyState_Tasbeeh_202305409.png](mockups/figures/LF_154_RecallSpace_EmptyState_Tasbeeh_202305409.png) |
| 10.121 | `155` | [LF_155_StudyToUnlock_Milestones_Tasbeeh_202305409.png](mockups/figures/LF_155_StudyToUnlock_Milestones_Tasbeeh_202305409.png) |
| 10.122 | `156` | [LF_156_StudyToUnlock_Completed_Tasbeeh_202305409.png](mockups/figures/LF_156_StudyToUnlock_Completed_Tasbeeh_202305409.png) |
| 10.123 | `157` | [LF_157_Trial_Activated_Tasbeeh_202305409.png](mockups/figures/LF_157_Trial_Activated_Tasbeeh_202305409.png) |
| 10.124 | `172` | [LF_172_Checkout_ExamBoost_Tasbeeh_202305409.png](mockups/figures/LF_172_Checkout_ExamBoost_Tasbeeh_202305409.png) |
| 10.125 | `173` | [LF_173_Payment_Processing_Failed_Tasbeeh_202305409.png](mockups/figures/LF_173_Payment_Processing_Failed_Tasbeeh_202305409.png) |
| 10.126 | `174` | [LF_174_Subscription_Manage_Monthly_Tasbeeh_202305409.png](mockups/figures/LF_174_Subscription_Manage_Monthly_Tasbeeh_202305409.png) |
| 10.127 | `175` | [LF_175_Subscription_Manage_ExamBoost_Tasbeeh_202305409.png](mockups/figures/LF_175_Subscription_Manage_ExamBoost_Tasbeeh_202305409.png) |
| 10.128 | `176` | [LF_176_Subscription_Manage_Trial_Tasbeeh_202305409.png](mockups/figures/LF_176_Subscription_Manage_Trial_Tasbeeh_202305409.png) |
| 10.129 | `177` | [LF_177_Subscription_Cancel_Confirm_Tasbeeh_202305409.png](mockups/figures/LF_177_Subscription_Cancel_Confirm_Tasbeeh_202305409.png) |
| 10.130 | `178` | [LF_178_Subscription_Cancelled_Tasbeeh_202305409.png](mockups/figures/LF_178_Subscription_Cancelled_Tasbeeh_202305409.png) |
| 10.131 | `179` | [LF_179_Checkout_Pro_Tasbeeh_202305409.png](mockups/figures/LF_179_Checkout_Pro_Tasbeeh_202305409.png) |

*Table 10.4, the figure index for the 130 wireframes, in screen order.*

Two further exports are page furniture rather than figures and carry no number: `LF_00_PageHeader_StudyForge.png` (the header on the wireframe page) and `F00_FlowDiagrams_Header_StudyForge.png` (the header on the flow diagrams page).

## 11. Navigation map

StudyForge uses a persistent **5-tab spine**, with role-specific tab contents. No screen is more than two levels deep before a modal or sheet takes over, and every error state offers a next action, so there are no dead ends.

| Tab | Student | Tutor | Admin |
|---|---|---|---|
| Home | Today's plan, streak, quick actions | Cohort KPIs, courses, review badge | Platform KPIs, alerts, quick-nav |
| Library | Materials, folders, bookmarks, search | Courses, published material | Users, moderation, reports |
| Coach | AI Study Companion (F15) | Content Studio entry | AI configuration |
| Practise | Flashcards, quizzes, revision | Cohort analytics | Audit log |
| Plan | Study plan, progress, settings | Gradebook export | Taxonomy, settings |

*Table 11.1, the five-tab spine and what each tab holds per role.*

The global flow, shown in full on Figma page `2 · Flow Overview`:

```
Launch → Splash → Onboarding → Sign up / Log in → Email verification
      → Profile wizard (3 steps) → Role home
Role home → Upload → Extract → Generate (Summary | Cards | Quiz | Notes)
          → Schedule (SM-2 + plan) → Practise (cards | quiz)
          → Measure (progress, radar) → Adapt (re-plan, weak-topic focus)
Each feature is independently reachable from its tab; every modal is dismissible;
every list has an empty state with a primary action.
```

*Figure 11.1, the global navigation map, exported from Figma page `2 · Flow Overview`: [mockups/figures/02_NavigationMap_StudyForge.png](mockups/figures/02_NavigationMap_StudyForge.png). Figure 11.2, the core learning loop, restated here: [mockups/figures/LOOP_CoreLearningLoop_StudyForge.png](mockups/figures/LOOP_CoreLearningLoop_StudyForge.png), the same artwork as Figure 5.1.*

## 12. Design system

The design system exists in exactly two places, Figma variables and SwiftUI tokens, generated from one token list, so the prototype and the app cannot drift. This parity is itself an Innovation talking point.

### 12.1 Colour

The palette is built on the **Apple system-blue family** rather than a bespoke gradient, so the app reads as iOS-native. It clears WCAG 2.2 AA at the points where it is used as text.

| Token (light) | Hex | Usage | Contrast on surface |
|---|---|---|---|
| `primary` | `#0062CC` | Primary buttons, active tabs, links | 5.8:1, AA |
| `primaryContainer` | `#E1F0FF` | Selected chips, highlights | fill only |
| `onPrimaryContainer` | `#00427A` | Text on `primaryContainer` | 8.8:1, AAA |
| `accent` (Ember) | `#F97316` | Streak flame, AI actions | fill only (2.8:1 as text) |
| `accentText` | `#C2410C` | Ember **text** | 5.2:1, AA |
| `secondary` (Teal) | `#14B8A6` | Collaboration surfaces | fill only |
| `secondaryText` | `#0F766E` | Teal **text** | 5.5:1, AA |
| `success` / `successText` | `#10B981` / `#047857` | Correct-answer fill / success text | fill / 5.5:1 AA |
| `warning` / `warningText` | `#F59E0B` / `#B45309` | Quota fill / amber **text** | fill / 5.0:1 AA |
| `error` | `#DC2626` | Destructive, incorrect answers | 4.8:1, AA |
| `textPrimary` / `textSecondary` / `textTertiary` | `#0F172A` / `#475569` / `#94A3B8` | Body / supporting / disabled only | 17.9:1 / 7.6:1 / 2.6:1 (not for text) |

*Table 12.1, the light-mode colour tokens with their measured contrast ratios.*

**The rule most teams get wrong:** the saturated hues (`accent`, `secondary`, `warning`) are *fill* colours, not text colours. Where the hue itself carries text, the paired `*Text` token is used instead, a change made specifically to fix a measured AA failure on five dashboard statistics. Full light and dark values, with contrast ratios, are in Appendix B. Eight subject colours (blue, teal, rose, amber, mint, cyan, lime, slate) tag courses and calendar blocks, deliberately excluding violet and pink.

### 12.2 Typography

SF Pro (the system font), so Dynamic Type and Arabic glyph shaping come free, with no custom Latin font, a deliberate accessibility decision. The ladder runs from `displayL` (34 pt bold) to `caption` (12 pt), with `body` at 17 pt. Minimum body size is 17 pt; nothing user-facing drops below 11 pt; everything scales to AX5; the dyslexia-friendly option increases line height by 40 percent and letter spacing by 5 percent; Arabic increases line height by 15 percent and never uses negative tracking.

### 12.3 Spacing, radius, elevation, motion

- **Spacing:** a strict 4 pt grid (`space1` 4 through `space12` 48); 16 pt screen margin; content max width 640 pt on a wider canvas.
- **Radius:** `radiusS` 8 (chips), `radiusM` 12 (buttons, fields), `radiusL` 16 (cards), `radiusXL` 24 (modals), full for pills and rings.
- **Elevation:** subtle iOS-style shadows (`e0` to `e3`); in dark mode shadows are replaced by a 1 pt outline plus a lifted surface.
- **Motion:** five tokens from 100 ms to 420 ms, all respecting Reduce Motion; the flashcard flip is a 3D Y-axis rotation, the app's signature moment.

### 12.4 Components

Actions, input controls, containment, data display and learning-specific components (flashcard, quiz option row, due-count badge, mastery dot, provenance citation chip, confidence band, streak flame, subject tag, calendar block, AI engine badge, timer ring). Each defines default, pressed, disabled and loading states. Icons are SF Symbols exclusively.

*Figure 12.1, the design system sheet as built in Figma (colour variables, type ramp, spacing, radius, elevation): [figures/01_DesignSystem_Saleh_202300540.png](figures/01_DesignSystem_Saleh_202300540.png).*

*Figure 12.2, the glass and depth reference (background blur, hairline border, dual shadow, inner light edge): [figures/02_GlassAndDepth_Saleh_202300540.png](figures/02_GlassAndDepth_Saleh_202300540.png).*

## 13. Innovation

Ten concrete, feasible, user-focused innovations, each stated as **Problem, Idea, Feasibility, Evidence**, because markers reward relevance, feasibility and added value, and vague "AI-powered" claims score zero. Items 1 to 3 are the headline claims.

| # | Innovation | Problem | Idea | Feasibility | Evidence |
|---|---|---|---|---|---|
| 1 | **Hybrid 3-tier AI router** | Cloud AI is costly, slow and leaks data; on-device AI is limited | Route each task to on-device, cloud free tier or a server function by a cost, latency and quality policy | `FoundationModels` (iOS 26+) behind an `AIProvider` protocol with swappable conformers | §14, screens `115`, `80` |
| 2 | **Provenance-tagged generation** | AI can hallucinate quiz answers, an academic-integrity risk | Every summary line, card and answer carries a source citation and confidence band; one tap jumps to the page | The extraction pipeline retains page and character offsets | §2, F03/F05, Figure 13.1 |
| 3 | **Learning-style-adaptive output** | One format does not suit every learner | One material, four output shapes (Visual, Verbal, Read-Write, Kinesthetic) plus accessibility profiles | Prompt templates stored in Firestore, changeable with no app update | `12_ProfileSetup_LearningStyle` |
| 4 | **Weakness radar to auto-replanned plan** | Competitors stop at "here is your score" | Quiz failures rewrite the revision calendar | Quiz attempts write `topicMastery`; the planner reads it | F05, F06, G-15 |
| 5 | **AI cost governor** | A free tier is only viable if the cost is bounded | Per-user daily budget, content-hash response caching, honest quota UX | SHA-256 of extracted text as the cache key | F03, `aiUsage` |
| 6 | **Graceful AI degradation** | On-device AI is unavailable on some devices and simulators | Explain why and offer the cloud path, instead of a dead end | `SystemLanguageModel.availability` | `80_Coach_OnDeviceUnavailable_Fallback` |
| 7 | **True RTL Arabic and dyslexia-friendly type** | Most apps ship translated overlays that break layout | Real RTL layout plus accessibility typography and a Dynamic Type proof | SwiftUI `layoutDirection`, custom type scale | `138`/`139` proof screens |
| 8 | **Offline-first core loop** | Students commute without data | Browse, review cards and take a cached quiz with the radio off | SwiftData plus Firebase offline persistence and a write queue | F04, offline states |
| 9 | **Live group revision arena** | The brief says only "possible collaboration" | Synchronous competitive revision with a real-time leaderboard | Firestore realtime listeners, no extra service or cost | F09, I-10 to I-17 |
| 10 | **Payment abstraction with an ethics note** | Apple Guideline 3.1.1 conflicts with a third-party gateway | One `PaymentGateway` protocol implemented by both Tap and StoreKit, with the conflict documented | Two thin adapters behind one protocol | §16, F13 |

*Table 13.1, the ten innovations, each with its problem, idea, feasibility and evidence.*

*Figure 13.1, the provenance citation chip and its confidence band, captured from the two prototype screens that carry it: `38_Summary_Provenance_Citation` (the chip beside `Relevance 0.92`, the confidence band) and `59_Quiz_Review_Answers_Explanations` (the same chip on a generated quiz answer). The component is implemented in the app under F03 and F05; these captures are from the Figma prototype because the app's summary screen cannot be driven from the command line — there is no tap automation in this environment — and that limitation is stated here rather than glossed over.*

## 14. Technical architecture

### 14.1 Principles

Zero-cost by default · on-device first, cloud second · offline-first · server-enforced security · protocol-first swappable providers · testable by construction · nothing regenerated twice.

### 14.2 System layers

```
iOS 26+ · SwiftUI · Swift 6 · Xcode 27
  Presentation   Views + @Observable ViewModels (MVVM)
  Domain         UseCases, Repository protocols, domain models
  Data           Firebase SDK (Firestore/RTDB) · SwiftData (offline cache, RAG vectors)
                 Keychain (tokens) · Cloud Functions (callable)
  Platform       Vision · NaturalLanguage · PDFKit · FoundationModels
                 PencilKit · UserNotifications · BackgroundTasks
  DesignSystem   ColorTokens · TypeScale · Spacing · Components
```

### 14.3 The 3-tier AI router

| Tier | Engine | Cost | Use |
|---|---|---|---|
| T0 | On-device Apple Foundation Models | $0 | Summarisation, flashcards, quizzes, planning, most coaching |
| T1 | Firebase AI Logic (Gemini free tier) | $0 | Multimodal OCR fallback, longer context, stronger reasoning |
| T2 | Cloud Function proxy | free allowance | Long documents (chunk and merge), server-side moderation |

*Table 14.1, the three AI tiers and when each is used.*

The router picks a tier per call from signals: task type, `SystemLanguageModel.availability`, device capability, network reachability, remaining daily budget, content size, and whether multimodal input is required. Routing policy is admin-configurable at screen `115`. If on-device is unavailable, the app degrades to the cloud path with a clear explanation rather than failing.

**Why this is engineering, not decoration:** it makes the product free (T0 covers most calls), it makes it work offline, and it is honest about failure. Every commercial AI app faces this same cost, quality and privacy trade-off.

*Figure 14.1, the system architecture (app, backend, AI tiers): [mockups/figures/ARCH_SystemArchitecture_StudyForge.png](mockups/figures/ARCH_SystemArchitecture_StudyForge.png), the five layers of §14.2 with the three tiers of Table 14.1. Figure 14.2, the AI router decision tree: [mockups/figures/ARCH_AIRouterDecisionTree_StudyForge.png](mockups/figures/ARCH_AIRouterDecisionTree_StudyForge.png), the same policy §14.3 describes in prose, drawn as the sequence of questions the router asks on every call.*

### 14.4 Cost model

Every service sits inside a free tier. Firestore (50K reads, 20K writes per day), Storage (5 GB), Auth (50K monthly active), FCM (unlimited), plus a tiny Cloud Function surface (a payment webhook and a nightly aggregation). Content-hash caching and on-device-first routing keep expected usage roughly an order of magnitude under every limit. **Estimated total project cost: $0**, with budget alerts and a spend cap as the guardrail.

### 14.5 Security model

Authorisation is **server-enforced**. Roles and entitlement live in Firebase Auth **custom claims** (`role`, `plan`, `groupIds`) and are mirrored in Firestore at `users/{uid}`. Firestore and Storage rules are **deny-by-default** and role-based: a student cannot read another student's material, a non-tutor cannot write the review queue, and a client cannot modify its own subscription. `users/{uid}` updates are gated by an explicit **field allowlist**, so a field added in a later sprint is not client-writable until it is named. Money-touching collections (`subscriptions`, `payments`, `promoCodes`) are Cloud-Function-write-only; the client never writes them. Vectors and extraction text stay on the device; only derived artefacts sync. The rule sets are covered by emulator tests including negative cases.

## 15. Accessibility and inclusiveness

Accessibility is where SDG 10 becomes real, and where LO1 (UI and UX best practice) is assessed, so it is designed in, not retrofitted.

| Requirement | Target | How it is verified |
|---|---|---|
| Text contrast | WCAG 2.2 AA (4.5:1 body, 3:1 large) | The colour table in §12 and Appendix B states every ratio; saturated fill hues have dedicated text-safe variants |
| Dynamic Type | Full support to AX5 | A dedicated proof screen plus a simulator pass at AX5 |
| VoiceOver | Every control labelled; images labelled or hidden | Accessibility labels on all interactive elements; decorative images marked hidden |
| Hit targets | Minimum 44 x 44 pt everywhere | Layout constant enforced in components |
| Motion | Respect "Reduce Motion" | Cross-fade replaces motion; no spring bounce |
| Colour independence | Never colour alone to convey meaning | Icons and text carry the meaning alongside colour (WCAG 1.4.1) |
| Language | Full English and Arabic with true RTL | `layoutDirection` support plus RTL proof screens; no hard-coded strings |
| Reading load | Plain language, 8th-grade reading level on errors | Copy review pass; plain-language error strings |
| Dyslexia-friendly option | Increased line height and letter spacing | A setting that changes typography without changing the size ladder |

*Table 15.1, the accessibility requirements, the target and how each is verified.*

## 16. Professional ethics and compliance

### 16.1 Apple Guideline 3.1.1 and payments

Digital goods on the App Store must use Apple In-App Purchase. The client specifies a Bahrain gateway (Tap Payments). Rather than ignore the conflict, StudyForge abstracts payments behind a `PaymentGateway` protocol with two implementations, a Tap adapter and a `StoreKitGateway`. The prototype **simulates** the gateway end to end: no live provider is contacted, no card data leaves the device, and every payment screen says so in plain words (`FLOW_F13`, and the demo notices on the wireframes). The production path is StoreKit. This turns a compliance problem into a documented architectural decision (LO3).

### 16.2 Privacy and data protection

- **On-device first.** Extraction, embedding and generation happen on the device where possible, so the user's material does not leave the phone unless it must.
- **Minimal collection.** Profiles hold only what the product needs; no personal study content is used to train models.
- **Retention.** Soft-delete via `deletedAt`, purged by a scheduled function; a user can delete their account and its derived data.
- **Security.** Deny-by-default rules, custom-claim roles, and money collections that only a Cloud Function can write.
- **Testing with real students.** User testing collects written consent, anonymises all data, and gathers no personal study content (aligned with the Bahrain Personal Data Protection Law, 2018).

### 16.3 Academic integrity and AI

- **No free-recall generation.** The model is grounded in the extracted text of the user's own material and is never asked a general-knowledge question, so it cannot invent a quiz answer.
- **Provenance on everything.** Every summary line, card and answer carries a citation and a confidence band.
- **Human in the loop.** Tutors review AI content before a cohort sees it; low-confidence items are flagged rather than published silently.
- **No auto-grading of assessed work.** AI assists revision, it does not mark submissions.
- **Disclosure.** Users are told where AI is used, that summaries are AI-drafted, and that on-device processing is private. (For the taught prototype, the team's own use of AI coding tools is disclosed in the appendix.)

### 16.4 Honesty about limitations

Where a feature is designed but not yet built (for example the role-select screen, which cannot exist because roles are server-owned), the deviation is recorded in the design rather than hidden. A clearly explained gap is worth more than a pretence.

## 17. Testing and validation

Testing is planned at four levels, and the brief's tester column is honoured by rotation: **nobody tests a feature they developed**, so every feature is read by at least two other team members before it counts as done.

### 17.1 Test levels

| Level | What is tested | Method | Evidence |
|---|---|---|---|
| Unit | Scheduling maths (SM-2), scoring, chunking, the router policy, money formatting | Swift Testing, run in CI on every push | Test report |
| Security | Firestore and Storage rules, including negative cases (a student cannot read another's material) | Emulator suite plus a live probe | `backend/rules-tests/` |
| Integration | Each feature's happy path and its error states on a real device or simulator | Scripted manual test logs, tester not the developer | Test logs in `research/testing/` |
| Usability | The golden path with 5 real students | Semi-structured test, System Usability Scale score | Usability report, §17.3 |

*Table 17.1, the four test levels, the method and the evidence each produces.*

### 17.2 Acceptance criteria, worked example (F04 Flashcards)

1. Generating from a material with at least 200 words produces 10 to 20 cards, each with a source citation.
2. Rating a card writes the next due date, and a "Good" rating increases the interval while "Again" resets it.
3. A review session completed offline persists and syncs without duplication on reconnect.

Every feature has 2 to 3 criteria of this form, which become its test cases.

### 17.3 Usability test plan

Five participants (students who are not squad members) complete the golden path: sign up, upload a PDF, generate a summary, generate flashcards, complete a review session, take a short quiz. The facilitator records task success, time on task and any confusion, then collects a **System Usability Scale** score. Consent is written and all data is anonymised (see §16.2). Results and the changes made are recorded here after the test.

> **Status: prepared, not yet run.** The usability test is scheduled for Sprint S3, alongside the hi-fidelity prototype, so that the tested build is close to the final one. **The full test pack is prepared and ready to run** in [`research/usability/`](../../research/usability/README.md): the [protocol](../../research/usability/protocol.md) with the facilitator script, the six golden-path tasks and the do-not-help rule; the [consent form](../../research/usability/consent-form.md); the [System Usability Scale questionnaire](../../research/usability/sus-questionnaire.md) with its scoring rule; the [participant log](../../research/usability/participant-log.md); and the [results template](../../research/usability/results.md).
>
> This subsection will carry the participant table, the usability score and the list of changes made in response, once the session has been run. **No score is recorded here yet, because none has been observed** — a figure entered before the session would be invented, and the honesty of this section is worth more than its completeness.

## 18. References

Cited in Harvard style.

- Bjork, R.A. and Bjork, E.L. (2011) 'Making things hard on yourself, but in a good way: creating desirable difficulties to enhance learning', in Gernsbacher, M.A., Pew, R.W., Hough, L.M. and Pomerantz, J.R. (eds.) *Psychology and the real world: essays illustrating fundamental contributions to society*. New York: Worth Publishers, pp. 56-64.
- Cepeda, N.J., Pashler, H., Vul, E., Wixted, J.T. and Rohrer, D. (2006) 'Distributed practice in verbal recall tasks: a review and quantitative synthesis', *Psychological Bulletin*, 132(3), pp. 354-380.
- Dunlosky, J., Rawson, K.A., Marsh, E.J., Nathan, M.J. and Willingham, D.T. (2013) 'Improving students' learning with effective learning techniques: promising directions from cognitive and educational psychology', *Psychological Science in the Public Interest*, 14(1), pp. 4-58.
- Ebbinghaus, H. (1885) *Über das Gedächtnis: Untersuchungen zur experimentellen Psychologie*. Leipzig: Duncker und Humblot.
- Fleming, N.D. and Mills, C. (1992) 'Not another inventory, rather a catalyst for reflection', *To Improve the Academy*, 11(1), pp. 137-155.
- Karpicke, J.D. and Blunt, J.R. (2011) 'Retrieval practice produces more learning than elaborative studying with concept mapping', *Science*, 331(6018), pp. 772-775.
- Kingdom of Bahrain (2018) *Law No. 30 of 2018 with respect to Personal Data Protection*. Manama: Government of the Kingdom of Bahrain.
- Mayer, R.E. (2009) *Multimedia learning*. 2nd edn. New York: Cambridge University Press.
- Nielsen, J. (1994) *Usability engineering*. San Francisco: Morgan Kaufmann.
- Roediger, H.L. and Karpicke, J.D. (2006) 'Test-enhanced learning: taking memory tests improves long-term retention', *Psychological Science*, 17(3), pp. 249-255.
- Sweller, J. (1988) 'Cognitive load during problem solving: effects on learning', *Cognitive Science*, 12(2), pp. 257-285.
- W3C (2023) *Web Content Accessibility Guidelines (WCAG) 2.2*. Available at: https://www.w3.org/TR/WCAG22/ (Accessed: 1 October 2026).
- Wozniak, P.A. and Gorzelanczyk, E.J. (1994) 'Optimization of repetition schedules in SuperMemo', *Acta Neurobiologiae Experimentalis*, 54(1), pp. 59-62.

> **Verification note.** The learning-science references above are stable, peer-reviewed sources and are cited for their established findings. **The local market and regulatory figures in §2 have been re-checked (23 Oct 2026):** Bahrain's Resolution No. 43 is **Ministerial Resolution No. (43) of 2024**, Minister of Industry and Commerce, published in the **Official Gazette No. 3753 of Thursday 13 June 2024**, and the payment rails F13 names are regulated under the **Central Bank of Bahrain Rulebook, Volume 5 (Specialised Licensees) — Payment Service Provider module** (version 5 February 2026). Every figure and its source is listed in [`research/dossier.md`](../../research/dossier.md) §2.1, with the retrieval date.

**Where these references come from.** The compiled evidence base sits beside this document as
[`research/dossier.md`](../../research/dossier.md): it carries the source behind every claim
in §2 and §4, the SDG mapping with a source per row, the change log from evidence to design,
and the list of market figures that are still unverified. Nothing in this section is
upgraded on the way in from the dossier.

## 19. Appendix

### Appendix A, screen inventory (labelled descriptions)

The complete per-screen inventory, with a purpose, labelled UI elements and element functions for every frame, is reproduced from `docs/03-SCREEN-INVENTORY.md` and from `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md`, which carries the purpose-and-layout description for every screen alongside the numbered element legend printed on Figma page 5 — **130 wireframes across groups A to O**. It is attached to the exported PDF as the largest appendix; the worked example in §10.2 is the template it follows.

### Appendix B, full colour token tables

**Light mode.**

| Token | Hex | Contrast on surface | WCAG |
|---|---|---|---|
| primary | #0062CC | 5.8:1 | AA |
| onPrimaryContainer | #00427A | 8.8:1 (on primaryContainer) | AAA |
| accent (Ember) | #F97316 | 2.8:1 | fill only |
| accentText | #C2410C | 5.2:1 | AA |
| secondary (Teal) | #14B8A6 | 2.3:1 | fill only |
| secondaryText | #0F766E | 5.5:1 | AA |
| success | #10B981 | 2.5:1 | fill only |
| successText | #047857 | 5.5:1 | AA |
| warning | #F59E0B | 2.2:1 | fill only |
| warningText | #B45309 | 5.0:1 | AA |
| error | #DC2626 | 4.8:1 | AA |
| textPrimary | #0F172A | 17.9:1 | AAA |
| textSecondary | #475569 | 7.6:1 | AAA |
| textTertiary | #94A3B8 | 2.6:1 | not for text |

*Table 19.1, the light-mode colour tokens in full (appendix).*

**Dark mode.**

| Token | Hex | Contrast on #0B1220 | WCAG |
|---|---|---|---|
| primary | #0A84FF | 5.1:1 | AA |
| secondaryText | #5EEAD4 | 12.7:1 | AAA |
| accentText | #FDBA74 | 11.1:1 | AAA |
| warningText | #FCD34D | 13.0:1 | AAA |
| successText | #6EE7B7 | 8.6:1 | AA |
| textPrimary | #F1F5F9 | 16.9:1 | AAA |
| textSecondary | #CBD5E1 | 11.2:1 | AAA |

*Table 19.2, the dark-mode colour tokens on #0B1220 (appendix).*

### Appendix C, traceability matrix

Each feature maps to its screens, the Firestore collections it touches, and the rubric area it provides evidence for. The full matrix is maintained in `docs/02-FEATURE-LIST-OWNERSHIP.md` §8. It is what lets a marker check that every feature in the list is present in the mockups and the prototype.

### Appendix D, prototype artefact

- Figma file (view link): `https://www.figma.com/design/uzTHnydXGeZSmImS5k2cLv`
- Prototype export: `deliverables/prototype/StudyForge.fig` (1.8 MB, re-exported from the Figma desktop app on 24 October 2026; `meta.json` records `exported_at 2026-10-23T23:01:26Z`, so it matches the shared link)
- Both the link text document and the `.fig` file are submitted, as the brief requires both.

### Appendix E, AI tool use disclosure

The team used an AI coding assistant (Cline, with a documented set of agent skills) to help write code and documentation. Every specification, design decision, feature decomposition, screen inventory, test and review was produced by the team, and each contribution is traceable in git with per-member authorship. Generated output was read, reviewed and corrected before it was committed, and those corrections are recorded in `research/reviews/`. This disclosure is deliberate, see §16.3.

