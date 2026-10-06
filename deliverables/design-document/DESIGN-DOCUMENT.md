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
| **Team (4 members)** | Saleh Abdulla (202300540) · Mohammed Almadhoon (202401702) · Tasbeeh Saeed (202300549) · Shahad Ashoor (202305767) |
| **Tutors** | Haetham Alhaddad (Coordinator) · Ghassan AlShajjar |
| **Platform** | iOS 26.0+ · SwiftUI · Swift 6 · Xcode 27 · Firebase (Spark, no-cost tier) |
| **SDGs** | SDG 4 (Quality Education) · SDG 9 (Industry, Innovation & Infrastructure) · SDG 10 (Reduced Inequalities) |
| **Design Document due** | 22 October 2026, 23:55 |
| **Prototype (Figma) due** | 12 November 2026, 23:55 |
| **Document version** | 1.0 (Gate 1 draft) |

> The app name and logo appear in the header of every page and on the Figma cover, per the identity requirement.

## Table of contents

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

## 1. Executive summary

University students accumulate large volumes of unstructured study material (lecture slides, PDFs, photographs of whiteboards) but have no systematic way to convert it into the active-recall practice that research shows produces durable learning. The default behaviour, rereading and highlighting, is among the least effective techniques available, yet it remains the most common.

**StudyForge** turns any study material into summaries, flashcards, quizzes and a spaced-repetition plan, and closes the loop between them: **upload, generate, schedule, practise, measure, adapt**. It is an iPhone-first, bilingual (English and Arabic) application built on Apple's on-device intelligence where possible, so the core loop works offline and at no cloud cost, and every AI artefact carries a visible source citation.

The design is documented end to end in this document: 4 user roles, 15 features, 98 designed screens, a bilingual design system, a 3-tier AI router, and a security model that keeps authorisation server-side. The system is built against a hard client constraint, **minimal cost**, and runs entirely inside free tiers.

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

### 2.3 Why now

On-device language models shipped to consumer phones in the last platform cycle, which means grounded, private generation can run without a server bill. That changes the economics: a student app can summarise and generate cards on the device, at zero marginal cost, and only escalate to the cloud when a task genuinely needs more reasoning or multimodal input. StudyForge is designed around exactly that shift. Locally, Bahrain's push toward digital payments and infrastructure (Resolution No. 43) and the region's rapid adoption of mobile learning make this a well-timed context rather than a speculative one.

> **Note for the final export:** the market-context figures in this section should be refreshed against the cited reports immediately before submission, and any figure that cannot be verified should be removed rather than approximated. The learning-science findings above are stable and peer-reviewed.

## 3. Tutor interview: questions asked and summary of responses

> ⚠️ **Status: the interview is booked but has not yet taken place.** The questions below are finalised. The response summary (§3.2) and "what changed" (§3.3) must be completed immediately after the interview, and the rubric requires both halves, so **this section must not be submitted without the responses.** It is structured so that filling it in takes minutes.

### 3.1 Interview record

| Field | Value |
|---|---|
| Date | *to be recorded* |
| Location | *Bahrain Polytechnic, within class time (as the brief requires)* |
| Interviewer(s) | Mohammed Almadhoon (M2), Shahad Ashoor (M4) |
| Attendee | Haetham Alhaddad (module coordinator) |
| Format | Semi-structured, ~20 minutes |
| Notes and recording | `research/interviews/` |

### 3.2 Questions asked

1. Which part of the brief do you consider the highest-risk for our team: AI accuracy, scope, or the payments integration?
2. What would make you say this project earned full Innovation marks?
3. Do you approve our proposed advanced feature (F15: a RAG-based AI Study Companion with adaptive study paths)? Is that "advanced" enough, or should we stretch further?
4. How much emphasis should the design document place on engineering architecture versus visual design?
5. For the Figma prototype, do you expect every error and empty state, or only the main flows?
6. Is there a preferred balance between feature breadth (15 features) and depth (fewer, richer features)?
7. Are there specific references or frameworks you would like to see applied (for example Nielsen's heuristics, or WCAG 2.2)?
8. What causes groups to lose marks in your experience?
9. Is a working SwiftUI app alongside the Figma prototype viewed positively, neutrally, or as scope creep?
10. Are there constraints we should respect regarding student data collection in our user testing?

### 3.3 Summary of responses and impact on the design

| # | Summary of response | What changed in the design as a result |
|---|---|---|
| 1 | *pending* | *pending* |
| 2 | *pending* | *pending* |
| 3 | *pending* | *pending* |
| 4 | *pending* | *pending* |
| 5 | *pending* | *pending* |
| 6 | *pending* | *pending* |
| 7 | *pending* | *pending* |
| 8 | *pending* | *pending* |
| 9 | *pending* | *pending* |
| 10 | *pending* | *pending* |

### 3.4 Written approval of the advanced feature (F15)

Requested in question 3. Status: **pending**. On receipt, store the written approval in `research/interviews/` and record the date and the approver here.

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

*Figure 4.1, competitor teardown, screenshots to be captured and captioned at export.*

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

*Figure 5.1, the core learning loop (upload, generate, schedule, practise, measure, adapt), also shown in §11.*

## 6. User roles and personas

The brief requires at least three user roles. StudyForge defines **four**, and each is genuinely distinct in permissions, home screen and primary job, rather than a label on the same account.

| # | Role | Job to be done | Exclusive capabilities | Home screen | Demo account |
|---|---|---|---|---|---|
| 1 | **Student** | "Get me through my exams with less wasted time." | Own library, generate AI artefacts, personal study plan, bookmarks, personal progress | `Home_Dashboard_Student` | `student@studyforge.demo` |
| 2 | **Tutor / Teacher** | "Give my cohort good material and see who is struggling." | Create courses, publish official material, review and edit AI-generated content before students see it, cohort analytics, gradebook export, announcements | `Home_Dashboard_Tutor` | `tutor@studyforge.demo` |
| 3 | **Study Group Member** (owner and member sub-roles) | "Revise together without losing my own notes." | Shared-folder CRUD, invite by code or link, per-member permissions (view, comment, edit), group revision spaces, live group quizzes, group leaderboard | `Home_Dashboard_Group` | `group@studyforge.demo` |
| 4 | **Admin** | "Keep the platform correct, safe and compliant." | User and role management, moderation queue, flagged-content reports, taxonomy management, AI prompt-template and quota configuration, audit log, broadcast notifications | `Home_Dashboard_Admin` | `admin@studyforge.demo` |

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

**Legend.** *Flow* is written as `trigger → step → … → outcome`. Developers and testers use the roster handles: **M1** Saleh Abdulla (202300540) · **M2** Mohammed Almadhoon (202401702) · **M3** Tasbeeh Saeed (202300549) · **M4** Shahad Ashoor (202305767). **Nobody tests a feature they developed.**

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
| F13 | Subscription & Payments | Student | Buy and manage a premium tier securely | Paywall → plan select → compare → order summary (BHD) → Tap card or BenefitPay → processing → server-side verification → entitlement → receipt → manage | M3 | M2 |
| F14 | Notifications & Reminders | All | Bring the user back at exactly the right moment | Server event or local schedule → relevance and quiet-hours filter → FCM push or local notification → tap → deep link → inbox → preferences | M1 | M3 |
| F15 | **ADVANCED** · AI Study Companion (RAG and Adaptive Coach) | Student | Ask anything grounded in your own materials and receive a personalised study path | Ask → on-device embedding search over own library → grounded answer with citation chips → adjust explanation level → recommended study path → rate response | **M2 + M3** | M1 |

**Workload balance:** every member owns at least three features (M1: 3, M2: 4 plus shared F15, M3: 3 plus shared F15, M4: 4), comfortably above the rubric minimum of two per student. **Advanced feature:** F15, co-owned by M2 and M3, whose feature areas are deliberately disjoint so neither can block the other.

**Sub-tasks and edge cases.** Each of the 15 features is expanded into an ordered sub-task list with explicit edge cases and error handling, and the Firestore collections it touches. These expansions are what the prototype's error and feedback states are built from. The full expansion is maintained in `docs/02-FEATURE-LIST-OWNERSHIP.md` §6 and is reproduced feature by feature alongside the mockups in §10.

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

### 8.3 Contracts and error handling

`RetrievalService` and `CoachPlanningService` are protocols, so the retrieval implementation and the planner can each be swapped or unit-tested in isolation. Edge cases handled explicitly: no relevant chunk found (say so), on-device model unavailable (fallback screen), very long answers (chunked streaming), a cited material deleted (the citation degrades gracefully), and a low-confidence response (flagged for the student).

*Figure 8.1, the RAG pipeline (index, retrieve, ground, answer, adapt).*

## 9. Feature flows

Each feature is broken into an ordered set of steps (the brief's "sub-tasks or individual steps"). These are the steps the prototype wires and the acceptance tests exercise. The 15 flow diagrams are drawn in Figma page `2 · Flow Overview` and reproduced as figures at export.

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
| F13 Payments | 1 Paywall, 2 select plan, 3 order summary in BHD with VAT, 4 choose method, 5 Tap card or BenefitPay, 6 processing, 7 server-side verification via webhook, 8 entitlement written, 9 receipt, 10 manage or cancel |
| F14 Notifications | 1 Server event or local schedule fires, 2 relevance and quiet-hours filter, 3 deliver FCM or local notification, 4 tap deep-links to the screen, 5 inbox history, 6 preferences respected |
| F15 Companion | 1 Ask a question, 2 embed the query on-device, 3 retrieve top-k chunks, 4 build a grounded prompt, 5 router picks a tier, 6 streamed answer with citations, 7 tap citation to source, 8 adjust explanation level, 9 request a study path, 10 capture feedback |

Every step above has at least one designed error or empty state, since the brief requires error and feedback states. Representative examples: F05, the timer expiring auto-submits; F04, rating a card then closing early saves partially; F08, an expired invite code shows a recovery action; F13, a declined card and a 3-D Secure timeout both resolve to a clear next step.

## 10. Low-fidelity mockups

### 10.1 Organisation and naming

The prototype is built in a single Figma file with one **page per owner**, so authorship is visible at a glance. Every frame is named to the brief's rule, `NN_ScreenName_FirstName_StudentID`, for example `03_Login_Saleh_202300540` and `115_Admin_AIConfig_Shahad_202305767`. The current file holds **98 frames** across the feature groups below; the full per-screen inventory with descriptions lives in `docs/03-SCREEN-INVENTORY.md` and is attached at export as Appendix A.

| Group | Area | Owner | Frames |
|---|---|---|---|
| A | Onboarding & Auth | M1 | 01–10, 24 |
| B | Profile & Settings | M1 | 11–18 |
| C | Courses & Library | M1 | 24–34 |
| D | AI Summaries | M2 | 35–41 |
| E | Flashcards | M2 | 42–48 |
| F | Quizzes | M2 | 51–59 |
| G | Study Plan & Progress | M3 | 60–70 |
| H | AI Study Companion (F15) | M2 + M3 | 73–78 |
| I | Collaboration | M4 | 81–97 |
| J | Tutor Content Studio | M2 | 99–105 |
| K | Admin Content Management | M4 | 109–115 |
| L | Subscription & Payments | M3 | 118–126 |
| M | System, States & Feedback | M1 | 128–141 |

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
| States (all) | M01–M14 | Loading, empty, offline, error, quota, success, permission denied |

### 10.3 Error and feedback states

The brief requires success, error and feedback states. A dedicated state set exists for every screen: loading skeleton, empty, offline, server error with retry, quota exceeded, invalid input (inline), permission denied, payment declined, and success confirmations with undo where destructive. These are designed once as components (`Figure 10.1`) and applied consistently.

## 11. Navigation map

StudyForge uses a persistent **5-tab spine**, with role-specific tab contents. No screen is more than two levels deep before a modal or sheet takes over, and every error state offers a next action, so there are no dead ends.

| Tab | Student | Tutor | Admin |
|---|---|---|---|
| Home | Today's plan, streak, quick actions | Cohort KPIs, courses, review badge | Platform KPIs, alerts, quick-nav |
| Library | Materials, folders, bookmarks, search | Courses, published material | Users, moderation, reports |
| Coach | AI Study Companion (F15) | Content Studio entry | AI configuration |
| Practise | Flashcards, quizzes, revision | Cohort analytics | Audit log |
| Plan | Study plan, progress, settings | Gradebook export | Taxonomy, settings |

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

*Figure 11.1, the global navigation map. Figure 11.2, the core learning loop.*

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

## 13. Innovation

Ten concrete, feasible, user-focused innovations, each stated as **Problem, Idea, Feasibility, Evidence**, because markers reward relevance, feasibility and added value, and vague "AI-powered" claims score zero. Items 1 to 3 are the headline claims.

| # | Innovation | Problem | Idea | Feasibility | Evidence |
|---|---|---|---|---|---|
| 1 | **Hybrid 3-tier AI router** | Cloud AI is costly, slow and leaks data; on-device AI is limited | Route each task to on-device, cloud free tier or a server function by a cost, latency and quality policy | `FoundationModels` (iOS 26+) behind an `AIProvider` protocol with swappable conformers | §14, screens `115`, `80` |
| 2 | **Provenance-tagged generation** | AI can hallucinate quiz answers, an academic-integrity risk | Every summary line, card and answer carries a source citation and confidence band; one tap jumps to the page | The extraction pipeline retains page and character offsets | §2, F03/F05, `figure 13.1` |
| 3 | **Learning-style-adaptive output** | One format does not suit every learner | One material, four output shapes (Visual, Verbal, Read-Write, Kinesthetic) plus accessibility profiles | Prompt templates stored in Firestore, changeable with no app update | `12_ProfileSetup_LearningStyle` |
| 4 | **Weakness radar to auto-replanned plan** | Competitors stop at "here is your score" | Quiz failures rewrite the revision calendar | Quiz attempts write `topicMastery`; the planner reads it | F05, F06, G-15 |
| 5 | **AI cost governor** | A free tier is only viable if the cost is bounded | Per-user daily budget, content-hash response caching, honest quota UX | SHA-256 of extracted text as the cache key | F03, `aiUsage` |
| 6 | **Graceful AI degradation** | On-device AI is unavailable on some devices and simulators | Explain why and offer the cloud path, instead of a dead end | `SystemLanguageModel.availability` | `80_Coach_OnDeviceUnavailable_Fallback` |
| 7 | **True RTL Arabic and dyslexia-friendly type** | Most apps ship translated overlays that break layout | Real RTL layout plus accessibility typography and a Dynamic Type proof | SwiftUI `layoutDirection`, custom type scale | `138`/`139` proof screens |
| 8 | **Offline-first core loop** | Students commute without data | Browse, review cards and take a cached quiz with the radio off | SwiftData plus Firebase offline persistence and a write queue | F04, offline states |
| 9 | **Live group revision arena** | The brief says only "possible collaboration" | Synchronous competitive revision with a real-time leaderboard | Firestore realtime listeners, no extra service or cost | F09, I-10 to I-17 |
| 10 | **Payment abstraction with an ethics note** | Apple Guideline 3.1.1 conflicts with a third-party gateway | One `PaymentGateway` protocol implemented by both Tap and StoreKit, with the conflict documented | Two thin adapters behind one protocol | §16, F13 |

*Figure 13.1, a provenance citation chip and confidence band on a generated quiz answer.*

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

The router picks a tier per call from signals: task type, `SystemLanguageModel.availability`, device capability, network reachability, remaining daily budget, content size, and whether multimodal input is required. Routing policy is admin-configurable at screen `115`. If on-device is unavailable, the app degrades to the cloud path with a clear explanation rather than failing.

**Why this is engineering, not decoration:** it makes the product free (T0 covers most calls), it makes it work offline, and it is honest about failure. Every commercial AI app faces this same cost, quality and privacy trade-off.

### 14.4 Cost model

Every service sits inside a free tier. Firestore (50K reads, 20K writes per day), Storage (5 GB), Auth (50K monthly active), FCM (unlimited), plus a tiny Cloud Function surface (a payment webhook and a nightly aggregation). Content-hash caching and on-device-first routing keep expected usage roughly an order of magnitude under every limit. **Estimated total project cost: $0**, with budget alerts and a spend cap as the guardrail.

### 14.5 Security model

Authorisation is **server-enforced**. Roles and entitlement live in Firebase Auth **custom claims** (`role`, `plan`, `groupIds`) and are mirrored in Firestore at `users/{uid}`. Firestore and Storage rules are **deny-by-default** and role-based: a student cannot read another student's material, a non-tutor cannot write the review queue, and a client cannot modify its own subscription. `users/{uid}` updates are gated by an explicit **field allowlist**, so a field added in a later sprint is not client-writable until it is named. Money-touching collections (`subscriptions`, `payments`, `promoCodes`) are Cloud-Function-write-only; the client never writes them. Vectors and extraction text stay on the device; only derived artefacts sync. The rule sets are covered by emulator tests including negative cases.

*Figure 14.1, the system architecture. Figure 14.2, the AI router decision tree.*

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

## 16. Professional ethics and compliance

### 16.1 Apple Guideline 3.1.1 and payments

Digital goods on the App Store must use Apple In-App Purchase. The client specifies a Bahrain gateway (Tap Payments). Rather than ignore the conflict, StudyForge abstracts payments behind a `PaymentGateway` protocol with two implementations, a Tap adapter and a `StoreKitGateway`. The prototype demonstrates the Tap sandbox flow; the production path is StoreKit. This turns a compliance problem into a documented architectural decision (LO3).

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

### 17.2 Acceptance criteria, worked example (F04 Flashcards)

1. Generating from a material with at least 200 words produces 10 to 20 cards, each with a source citation.
2. Rating a card writes the next due date, and a "Good" rating increases the interval while "Again" resets it.
3. A review session completed offline persists and syncs without duplication on reconnect.

Every feature has 2 to 3 criteria of this form, which become its test cases.

### 17.3 Usability test plan

Five participants (students who are not squad members) complete the golden path: sign up, upload a PDF, generate a summary, generate flashcards, complete a review session, take a short quiz. The facilitator records task success, time on task and any confusion, then collects a **System Usability Scale** score. Consent is written and all data is anonymised (see §16.2). Results and the changes made are recorded here after the test.

> **Status: planned, not yet run.** The usability test is scheduled for Sprint S3, alongside the hi-fidelity prototype, so that the tested build is close to the final one. This subsection will carry the participant table, the SUS score, and the list of changes made in response.

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

> **Verification note.** The learning-science references above are stable, peer-reviewed sources and are cited for their established findings. Any local market or regulatory figure used in §2 must be re-checked against its primary source immediately before submission; Bahrain's Resolution No. 43 on digital payments is cited as local context and its exact reference should be confirmed against the official gazette.

## 19. Appendix

### Appendix A, screen inventory (labelled descriptions)

The complete per-screen inventory, with a purpose, labelled UI elements and element functions for every frame, is reproduced from `docs/03-SCREEN-INVENTORY.md` (98 frames across groups A to M). It is attached to the exported PDF as the largest appendix; the worked example in §10.2 is the template it follows.

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

### Appendix C, traceability matrix

Each feature maps to its screens, the Firestore collections it touches, and the rubric area it provides evidence for. The full matrix is maintained in `docs/02-FEATURE-LIST-OWNERSHIP.md` §8. It is what lets a marker check that every feature in the list is present in the mockups and the prototype.

### Appendix D, prototype artefact

- Figma file (view link): `https://www.figma.com/design/uzTHnydXGeZSmImS5k2cLv`
- Prototype export: `deliverables/prototype/StudyForge.fig` (produced at Gate 2, 12 Nov 2026)
- Both the link text document and the `.fig` file are submitted, as the brief requires both.

### Appendix E, AI tool use disclosure

The team used an AI coding assistant (Cline, with a documented set of agent skills) to help write code and documentation. Every specification, design decision, feature decomposition, screen inventory, test and review was produced by the team, and each contribution is traceable in git with per-member authorship. Generated output was read, reviewed and corrected before it was committed, and those corrections are recorded in `research/reviews/`. This disclosure is deliberate, see §16.3.

