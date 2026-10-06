# 00, Master Plan

> **StudyForge** · IT8108 Project Brief 2 (Intelligent Learning Platform) · Semester A 2026–2027
> Companion docs: [Feature List](02-FEATURE-LIST-OWNERSHIP.md) · [Screen Inventory](03-SCREEN-INVENTORY.md) · [Tech Architecture](04-TECH-ARCHITECTURE-COST.md) · [Roadmap](01-ROADMAP-PHASES-TODOLIST.md) · [Rubric Matrix](08-RUBRIC-COVERAGE-MATRIX.md)

---

## 1. Why this document exists

The brief is deliberately under-specified: *"The client briefs provided are not exhaustive… You are expected to conduct additional research, explore real-world references, and demonstrate innovation."*

That is both the risk and the opportunity. This plan converts the under-specified brief into a **closed, traceable specification** where every mark in both rubrics has a named owner and a piece of evidence. Nothing here is guesswork, the rubric is quoted verbatim in [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) and mapped line by line.

---

## 2. The brief, decoded

**Client brief (verbatim):** *"This project asks students to design an AI-supported mobile learning platform that helps students organize materials and turn them into useful study resources such as summaries, notes, quizzes, and flashcards. The solution should promote active learning, personalization, revision planning, and possible collaboration or sharing between students."*

The brief contains **four explicit success pillars**. Every feature must serve at least one. This is our design filter:

| Pillar | Brief wording | StudyForge mechanism |
|---|---|---|
| **P1 · Organise** | "helps students organize materials" | Course-scoped Material Library, intelligent tagging, shared folders, bookmarking |
| **P2 · Transform** | "turn them into useful study resources such as summaries, notes, quizzes, and flashcards" | 3-tier AI pipeline: upload → extract → summary / flashcards / quiz / notes |
| **P3 · Active Learning & Personalisation** | "promote active learning, personalization, revision planning" | Spaced repetition (SM-2), adaptive study plan, weakness radar, learning-style formatting |
| **P4 · Collaboration** | "possible collaboration or sharing between students" | Shared study folders, group revision spaces, live group quiz arena |

**Brief challenges, answered explicitly**, these *are* exam questions and must appear verbatim in the design document:

- **"How can uploaded materials become accurate study resources?"** → Accuracy is an *architecture* decision, not a prompt decision. Every AI artefact stores **provenance**: the source page/chunk it came from, a confidence band, and a one-tap "show me where this came from" citation. Extraction runs on-device (Vision OCR) first, with a cloud multimodal fallback for scanned images. Generation is *grounded*, the model is constrained to the extracted text and is never asked a free-recall question.
- **"How can generated resources support different learning styles?"** → A **Learning Style Profile** (Visual / Verbal / Read-Write / Kinesthetic, plus accessibility toggles) changes the *output format*, not merely the content: Visual gets diagrams + mind-map-tagged cards, Verbal gets narration scripts and spoken quizzes, Read-Write gets structured notes and cloze deletions, Kinesthetic gets applied-scenario quizzes and drag-to-order activities.
- **"How can students organize and revisit resources throughout the term?"** → A course-scoped library with folders, tags, bookmarks, global search, a **revision timeline** driven by SM-2 due-dates, and offline availability so resources survive a commute with no data.

---

## 3. Grading strategy, corrected priorities

### 3.1 The real assessment model

| # | Component | Weight | Type | Must pass? |
|---|---|---|---|---|
| 1 | Individual App | 10% | Individual | - |
| 2 | Design Document | 10% | Group | - |
| 3 | Prototype (Figma) | 10% | Group | - |
| 4 | **Sprints** | **10%** | **Individual** | - |
| 5 | **iOS App Implementation & Demonstration** | **60%** | Group | ⛔ **MUST PASS** |

**Pass conditions, both required:** aggregate **≥ 60%**, **and** the **60% iOS App Implementation & Demonstration passed**.

### 3.2 Correction: an earlier assumption in this plan was wrong

Earlier drafts treated the working app as optional and made Figma the critical path. That was based on the *Project Design Document brief*, which describes only two phases, design document and Figma prototype. **That brief covers 20% of the course; it is not the whole assessment.**

The corrected position: the working iOS application plus the in-person VIVA is **60% of the course and a hard gate on passing**. Every priority in this plan flows from that.

### 3.3 The four workstreams, ranked

| Rank | Workstream | Weight | Effort share | Strategy |
|---|---|---|---|---|
| **1** | **Working iOS app + VIVA** | **60% · must pass** | ~50% | Build a genuinely complete, working app that runs on a real device. Every member must be able to explain and modify any feature. This is not a mockup exercise, it is the course. |
| **2** | **Sprints (individual)** | 10% | ~20% | Continuous, per-person, timestamped evidence of contribution and progress. The only component a teammate cannot carry for you. |
| **3** | **Design Document** | 10% | ~15% | Front-load to the 22 Oct deadline, then close it. Four of five rubric areas need only discipline, not design skill. |
| **4** | **Figma Prototype** | 10% | ~15% | Must cover every feature and be genuinely interactive, but do **not** gold-plate 141 frames for 10%. |

### 3.4 Critical path

```
CRITICAL PATH (must pass)   App implementation → integration → real-device demo → in-person VIVA
PARALLEL, HARD DEADLINES    Design Document (22 Oct)  ·  Figma Prototype (12 Nov)
CONTINUOUS, INDIVIDUAL      Sprint contribution evidence
```

The design system remains a shared asset: Figma variables and `DesignSystem.swift` come from one token list ([doc 06](06-DESIGN-SYSTEM.md)), so the prototype and the app cannot drift. That is still an Innovation talking point, but it is now a *convenience*, not the critical path.

### 3.5 Effort re-allocation, what changes

| Area | Previous plan | Corrected plan |
|---|---|---|
| Working app | Optional extra | **Primary deliverable.** Every one of the 15 features must actually function, with loading, empty, error and offline states |
| Figma prototype | 141 frames, 89 "committed" | **Reduced.** Target the 89 P0 frames; a **linked-coverage set of ~55 frames** (all 15 features' happy paths, fully wired) is the acceptable floor at this weight |
| VIVA preparation | A final phase | **Starts in Sprint 1.** Comprehension is built as features are built, not crammed at the end |
| Sprints | Not addressed at all | **New workstream** with its own doc, cadence and evidence rules ([doc 10](10-SPRINT-PLAN.md)) |
| Advanced feature F15 | Headline innovation | **Stays, but strictly de-risked.** Core features must be demo-solid *before* F15 is polished, a broken core with a clever advanced feature fails the must-pass gate |

> **The single most dangerous failure mode in this project:** spending six weeks on Figma and documentation (20%) while the app (60%, must pass) is unfinished. The cut-line protocol in [doc 01 §14](01-ROADMAP-PHASES-TODOLIST.md) now sacrifices Figma work **first** if time runs short, the opposite of the earlier plan.


## 4. Easy-to-lose marks (found by reading the brief closely)

These are the items most groups miss. Each one is a task in [the roadmap](01-ROADMAP-PHASES-TODOLIST.md).

1. **The tutor interview summary is a required sub-item of Background Research (4/20).** The rubric asks for *"Group interview summary with your tutor… Include questions asked and summary of responses."* Missing it caps this section at ~3 of 4.
2. **The advanced feature needs tutor *approval*:** *"at least one advanced feature agreed upon with the tutor."* Get written confirmation before 22 Oct.
3. **Every student must develop ≥2 features *and* the workload must be visibly fair.** Show it in the table, not just claim it.
4. **The prototype must be BOTH the `.fig` file AND the shared URL, in a text document.** Submitting only a link loses marks.
5. **Frame naming is a stated rubric line:** *"all frames/screens must be clearly named by developer, such as Login_Ahmed_2022XXXXX."* Non-compliance is a visible, avoidable deduction.
6. **Project identity must be consistent across all three phases:** app name on the document cover *and headers*, logo/icon *in mockups and prototype screens*.
7. **Mockups need three things per screen:** a written description, labelled UI elements, *and* an explanation of each element's function. Many groups only draw the screen.
8. **Error & feedback states are explicitly required in the prototype:** *"User feedback, success, and error screens or messages should be included."* Most groups skip these, they are free marks.
9. **Mockups are LOW-fidelity in the Design Document** (paper/Draw.io/Figma/Canva) but **HIGH-fidelity in the Prototype.** Don't invert them.
10. **The app name must be memorable and unique, with a logo/icon concept**, *"consistent use of this identity across all project materials."* It is worth real time in Phase 0, not five minutes at the end.

---

## 5. Product identity

| Element | Decision |
|---|---|
| **Name** | **StudyForge** |
| **Tagline** | *Turn any material into mastery.* |
| **Why this name** | "Forge" is the exact brief metaphor: raw material (PDFs, scans, slides) is *forged* into study tools (summaries, cards, quizzes). It is unique in the education app space, memorable, one word, and reads identically in English and Arabic transliteration (*ستادي فورج*). |
| **Logo concept** | A hexagon "anvil" mark built from three overlapping rounded rectangles representing a **summary**, a **flashcard** and a **quiz**. Filled with an ember→gold gradient (`#F97316 → #FACC15`) on a deep blue field. Reads clearly at 20 px on the home screen. |
| **Alternate names** (if StudyForge is taken) | **MindFold** (ties to shared folders) · **Zamil** (زميل, "classmate", local flavour) · **Mishkat** (مشكاة, "niche of light") |
| **Tone of voice** | Calm, encouraging, never gamified-guilt-tripping. "Let's turn this into 20 flashcards" not "You're falling behind!" |
| **Visual identity** | Apple system blue primary `#0062CC`, Ember accent `#F97316`, teal success `#14B8A6`, on a glassmorphic light canvas. No purple anywhere in the palette, because violet-to-pink ramps read as generic AI output. SF Pro (system) with Dynamic Type. Full light + dark mode. See [Design System](06-DESIGN-SYSTEM.md). |

---

## 6. Problem, target users and SDG alignment

**The problem (to be evidenced with published research in the document):** university students accumulate large volumes of unstructured material (lecture slides, PDFs, photographed whiteboards, recordings) but have no *systematic* way to convert it into active-recall practice. The default behaviour, re-reading and highlighting, is a well-documented low-yield study strategy, while retrieval practice and spaced repetition are high-yield. Existing AI study tools are Western-market, subscription-gated, English-only, cloud-only and privacy-opaque.

**Who is affected:** undergraduates in the Gulf region especially, many study in a second language (English-medium instruction), study alongside part-time work, and pay for data by the gigabyte.

| SDG | How StudyForge contributes |
|---|---|
| **SDG 4, Quality Education** | Turns passive material into active-recall resources; measurable mastery improvement |
| **SDG 9, Industry, Innovation & Infrastructure** | On-device AI + offline-first architecture means quality tools that work on low-quality infrastructure |
| **SDG 10, Reduced Inequalities** | Bilingual EN/AR with full RTL, dyslexia-friendly typography, free tier that is genuinely useful (not crippled), offline mode, and accessibility-first design |

---

## 7. User roles (4 roles, the rubric requires "at least three")

Each role is genuinely distinct in **permissions, home screen and primary job-to-be-done**, not just a label.

| # | Role | Job to be done | Exclusive capabilities | Home screen | Seeded demo account |
|---|---|---|---|---|---|
| 1 | **Student** | "Get me through my exams with less wasted time." | Own library, generate AI artefacts, personal study plan, bookmarks, personal progress | `Home_Dashboard_Student` | `student@studyforge.demo` |
| 2 | **Tutor / Teacher** | "Give my cohort good material and see who is struggling." | Create courses, publish official material, review/edit AI-generated content before students see it, cohort analytics, gradebook export, announcements | `Home_Dashboard_Tutor` | `tutor@studyforge.demo` |
| 3 | **Study Group Member** (owner + member sub-roles) | "Revise together without losing my own notes." | Shared-folder CRUD, invite by code/link, per-member permissions (view / comment / edit), group revision spaces, live group quizzes, group leaderboard | `Home_Dashboard_Group` | `group@studyforge.demo` |
| 4 | **Admin** | "Keep the platform correct, safe and compliant." | User & role management, moderation queue, flagged-content reports, taxonomy management, AI prompt-template & quota configuration, audit log, broadcast notifications | `Home_Dashboard_Admin` | `admin@studyforge.demo` |

> **Design note:** *Study Group Member* is modelled as a **capability set layered on top of Student** rather than a separate account type. One human, one account, multiple contexts, this is the correct real-world model and it is explicitly justified in the document as a UX decision. It yields 4 rubric-compliant roles without forcing a confusing re-signup.

**Authorisation model:** role is stored in Firestore `users/{uid}.role` and mirrored into **Firebase Auth custom claims** (`role`, `plan`, `groupIds`) so Firestore/Storage security rules enforce it *server-side*. The client never decides who can read what. See [Data Model & Security](05-DATA-MODEL-SECURITY.md).

---

## 8. Competitive edge (rubric: Background Research)

Teardown of the incumbents, to be included in the document with screenshots:

| Competitor | Strength | Gap StudyForge exploits |
|---|---|---|
| **Quizlet** | Huge card library, polish | Cloud-only, freemium with aggressive paywalls, English-first, weak on *your own* uploaded material |
| **Anki** | Best-in-class spaced repetition | Hostile onboarding, no AI generation, no collaboration, desktop-centric |
| **Notion / Obsidian** | Powerful organisation | You must build the system yourself; no generation, no scheduling intelligence |
| **Google NotebookLM** | Excellent grounded summarisation | Desktop/web-first, no mobile revision loop, no flashcards/quizzes/SR, no group spaces |
| **ChatGPT / Gemini apps** | Broad capability | Not grounded in *your* course material, no structure, no provenance, no revision scheduling |
| **Studocu / Course Hero** | Shared notes | Paywalled, legal grey areas, no personal generation |

**StudyForge's competitive edge, the "one loop" claim:**

> Incumbents solve *one stage* of the study workflow. StudyForge is the only design where **upload → generate → schedule → practise → measure → adapt** is a single closed loop, and where the user's own course material is the grounding source for every AI artefact.

Three supporting differentiators:

1. **Grounded-by-default AI with visible provenance**, every summary line and quiz answer traces back to the page it came from. No hallucinated quiz answers.
2. **Works without a network**, on-device extraction and on-device generation mean the core loop runs on a bus with no data.
3. **Bilingual EN/AR with true RTL**, designed for the GCC market that every listed competitor treats as an afterthought.

---

## 9. Innovation plan (rubric: Innovation, 2 marks)

Ten concrete, feasible, user-focused innovations. Items **1–3 are the headline claims**; the rest add depth. Each is designed so it cannot be dismissed as a gimmick, it solves a named problem.

| # | Innovation | Why it goes beyond the brief | Made feasible by |
|---|---|---|---|
| **1** | **Hybrid 3-tier AI router**, on-device Apple Foundation Models → Firebase AI Logic free tier → Cloud Function fallback, selected per task by a cost / latency / quality policy | The brief says "AI-supported". Deciding *where* each AI call runs, and degrading gracefully when offline or when the device lacks Apple Intelligence, is an engineering innovation, not a feature | `FoundationModels` (iOS 26+) + an `AIProvider` protocol with swappable conformers |
| **2** | **Provenance-tagged generation**, every summary line, card and quiz answer carries a source citation chip and confidence band; one tap jumps to the source page | Directly attacks the brief's own question: *"How can uploaded materials become accurate study resources?"* Nobody else in the (student-project or commercial) space makes groundedness visible | The extraction pipeline retains page + character offsets |
| **3** | **Learning-style-adaptive output**, one material, four output shapes (Visual / Verbal / Read-Write / Kinesthetic), plus accessibility profiles | Answers *"support different learning styles"* with genuine output transformation, not marketing copy | Prompt templates stored in Firestore, changeable with no app update |
| **4** | **Weakness radar → auto-replanned study plan** | Closes the loop: quiz failures rewrite the calendar. Competitors stop at "here is your score" | Quiz attempts write `topicMastery`; the planner reads it |
| **5** | **AI cost governor**, per-user daily AI budget, content-hash response caching, honest "resets in 3 h" quota UX | Makes a free-tier-only product *viable*. A real engineering constraint that most student projects ignore entirely | SHA-256 of extracted text as the cache key |
| **6** | **Graceful AI degradation**, when on-device Apple Intelligence is unavailable (Simulator, older iPhone) the app explains why and offers the cloud path | Honest, accessible failure design instead of a dead end | `SystemLanguageModel.availability` + the `80_Coach_OnDeviceUnavailable_Fallback` screen |
| **7** | **True RTL Arabic + dyslexia-friendly typography + Dynamic Type proof** | SDG 10 credibility. Almost never done properly, usually translated overlays that break layout | SwiftUI `layoutDirection`, custom font scale, `138`/`139` proof screens |
| **8** | **Offline-first core loop** | Commute-friendly; SDG 9 credibility; a genuinely different architecture, not a caching afterthought | SwiftData + Firebase offline persistence + write queue |
| **9** | **Live group revision arena** with real-time leaderboard | The brief says only *"possible collaboration"*. Synchronous competitive revision is a real leap | Firestore realtime listeners (no extra service, no extra cost) |
| **10** | **Payment abstraction with a professional-ethics note**, one `PaymentGateway` protocol implemented by both Tap Payments *and* StoreKit, documenting Apple Guideline 3.1.1 | Demonstrates **LO3 professional ethics** by surfacing a genuine compliance conflict and resolving it architecturally, instead of ignoring it | Two thin adapters behind one protocol |

**How to write these up:** for each, state *Problem → Idea → Why it's feasible → Evidence (screen or code)*. Markers reward *"relevance, feasibility, and added value"*, vague "AI-powered" claims score zero, so every item above names a screen ID or a code artefact.

---

## 10. Definition of done (per feature)

A feature is **Done** only when **all eight** are true. This is the standard Cline (and every team member) builds to.

| # | Criterion | Evidence |
|---|---|---|
| 1 | All its P0 + P1 screens exist in Figma and are named to the rule | Frame links in the Design Document |
| 2 | Every screen is wired in the prototype (no dead ends) | Prototype walkthrough recording |
| 3 | A written screen description + labelled UI elements exists for every screen | This repo, [doc 03](03-SCREEN-INVENTORY.md) |
| 4 | Happy path implemented in the working SwiftUI app | Demo on device/simulator |
| 5 | Loading, empty, error and offline states implemented | Screen recordings |
| 6 | Firestore/Storage security rules cover the feature's collections | `backend/firestore.rules` diff |
| 7 | Tested by the assigned **tester** (not the developer) with results recorded | Test log in [doc 05] / QA sheet |
| 8 | Zero AI features exceed the free-tier budget in normal use | Admin AI config dashboard |

---

## 11. Required structure of the submitted Design Document (PDF)

Ordered to map 1:1 onto the rubric, so a marker can find every mark without hunting. Estimated page counts assume A4, 11pt, consistent heading styles.

| § | Section | Pages | Rubric area (marks) | Owner |
|---|---|---|---|---|
| - | **Cover page**, app name, logo, tagline, team table with IDs, module, tutors, date | 1 | Identity requirement + Organisation (2) | M1 |
| - | **Table of contents**, figure list, table list | 1 | Organisation (2) | M1 |
| 1 | **Executive summary** | 1 | Background Research (4) | M1 |
| 2 | **Background research**, problem, who is affected, evidence & references, SDG alignment | 3 | Background Research (4) | M1 + M4 |
| 3 | **Tutor interview**, questions asked, summary of responses, what changed as a result | 1.5 | Background Research (4) ← *easy to lose* | M2 |
| 4 | **Competitive analysis**, teardown table + screenshots + competitive edge | 1.5 | Background Research (4) | M4 |
| 5 | **App purpose, goals, intended impact + success metrics** | 1 | Background Research (4) | M1 |
| 6 | **User roles & personas**, 4 roles, 4 personas with goals/frustrations | 2 | Features List (4) | M4 |
| 7 | **Feature list**, the master table (name, role, task, flow, developer, tester) | 2 | **Features List (4)** | M3 |
| 8 | **Advanced feature specification**, F15 in depth | 1.5 | Features List (4) | M2 + M3 |
| 9 | **Feature flows**, one flow diagram per feature | 3 | Mockups (8) | all |
| 10 | **Low-fidelity mockups**, grouped by feature, each with description + labelled UI elements + element functions | 16–20 | **Mockups (8)** | all |
| 11 | **Navigation map**, global screen flow | 1 | Mockups (8) | M3 |
| 12 | **Design system**, colour, type, spacing, components, states | 2 | Mockups (8) + Innovation (2) | M1 |
| 13 | **Innovation**, the 10 items in *Problem → Idea → Feasibility → Evidence* form | 2.5 | **Innovation (2)** | M2 |
| 14 | **Technical architecture**, stack, AI router, cost model, security, payments | 2.5 | Innovation (2) | M3 |
| 15 | **Accessibility & inclusiveness statement** | 1 | Innovation (2) + SDG 10 | M4 |
| 16 | **Professional ethics & compliance**, Apple 3.1.1, GDPR-style privacy, data retention, academic-integrity policy for AI, human-in-the-loop review | 1.5 | Innovation (2) + **LO3** | M3 |
| 17 | **Testing & validation**, usability test with 5 users, results, changes made | 1.5 | Organisation (2) | M4 |
| 18 | **References**, Harvard style | 1 | Background Research (4) | M2 |
| 19 | **Appendix**, Figma link, prototype `.fig` note, feature-to-screen traceability matrix | 1.5 | Organisation (2) | M3 |

**Formatting contract** (rubric: *"consistent formatting throughout"*):
one heading style ladder used everywhere · one body font · one accent colour · numbered captions (`Figure 7, ...`, `Table 3, ...`) · page numbers in the footer · **app name + logo in the header of every page** · Harvard referencing throughout · no orphan headings · all figures at ≥150 dpi.

---

## 12. Where to start (next 72 hours)

1. Fill in the real team names and student IDs in [doc 02 §2](02-FEATURE-LIST-OWNERSHIP.md), **everything downstream depends on this**, and Figma frame names embed them.
2. Freeze the app identity (name + logo) and add it to the Figma cover and every document header.
3. Book the tutor interview and take the question list from [doc 09](09-RISKS-OPEN-QUESTIONS.md), get the F15 advanced-feature approval in writing on the same day.
4. Start the literature and market research collection in `research/`.
5. Install the Cline agent skills listed in [doc 07](07-CLINE-SKILLS-AND-TOOLING.md).

The dated sequence for everything else lives in **[doc 01, Roadmap, Phases & Todolist](01-ROADMAP-PHASES-TODOLIST.md)**.





