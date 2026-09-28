# 08 — Rubric Coverage Matrix (the full-marks checklist)

> **This is the single most important document in the repo.** Every rubric bullet from the brief is reproduced verbatim below with the specific evidence that satisfies it, the owner, and a status. If a row has no evidence, that is a **lost mark** — and it is fixable today.

Status legend: ⬜ not started · 🟨 in progress · ✅ done

---

## 1. How to use this

1. **Before every gate**, read this file top to bottom.
2. For any ⬜ row, create a task and assign it during the next stand-up.
3. The `Evidence` column must point at something a marker can *open*: a page of the PDF, a Figma frame ID, a file in the repo.

---

## 2. Design Document — Background Research (4 of 20)

Rubric area a, *"Group Assessment – 4%"*.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| a1 | *"A clear explanation of the real world or context, including who is affected and why the issue matters."* | Design Doc §2 → problem statement, affected population, scale, Gulf/Bahrain context. Dashboard at `research/dossier.md` §1. | M1 | ⬜ |
| a2 | *"A clear description of the app's purpose, goals, and intended impact as a solution to the problem."* | Design Doc §5 → purpose, goals, **measurable** success metrics, intended impact. | M1 | ⬜ |
| a3 | *"Supporting research or references, such as online research, trends, or statistics."* | Design Doc §2 + §18 → **8+ cited sources** (retrieval practice, spaced repetition, testing effect, GCC digital-learning adoption, Bahrain Resolution No. 43), Harvard style. `research/dossier.md`. | M4 | ⬜ |
| a4 | *"Group interview summary with your tutor… Include questions asked and summary of responses."* | Design Doc §3 → the 10 questions from [roadmap Phase 1 §4](01-ROADMAP-PHASES-TODOLIST.md) with the tutor's answers verbatim, plus a "what changed as a result" subsection. **⚠️ easy to lose** | M2 | ⬜ |
| a5 | *"Explain what gives your app a competitive edge compared to similar apps in the market."* | Design Doc §4 → competitor teardown table (Quizlet · Anki · NotebookLM · Notion · ChatGPT · Studocu) + the "one closed loop" claim + 3 differentiators. [`00-MASTER-PLAN.md` §8](00-MASTER-PLAN.md). | M4 | ⬜ |

**Also required by the brief for this area (not a separate bullet but stated):** the interview must be *"focused on collecting information from your tutor within class time"* — record the date, location and attendees. ⬜

---

## 3. Design Document — Features List (4 of 20)

Rubric area b.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| b1 | *"Submit a structured feature list."* | Design Doc §7 → the master table. [`02-FEATURE-LIST-OWNERSHIP.md` §4](02-FEATURE-LIST-OWNERSHIP.md). | M3 | ⬜ |
| b2 | *"Name of Feature"* | Master table column *Feature*, F01–F15. | M3 | ⬜ |
| b3 | *"Main Task: What is the feature trying to accomplish from the user's perspective?"* | Master table column *Main task* — all 15 written from the user's perspective. | M3 | ⬜ |
| b4 | *"User: Who is the intended user for this feature"* | Master table column *Role* — 4 distinct roles used across the set. | M3 | ⬜ |
| b5 | *"Sub-Tasks/Steps: Describe a brief flow or individual steps"* | Design Doc §7 → the expanded sub-task table. [`02 §6`](02-FEATURE-LIST-OWNERSHIP.md). | M3 | ⬜ |
| b6 | *"Developer: The team member responsible"* | Master table column *Developer*. | M3 | ⬜ |
| b7 | *"Tester: Another team member responsible for testing"* | Master table column *Tester* **and** the rotation matrix [`02 §7`](02-FEATURE-LIST-OWNERSHIP.md) proving tester ≠ developer. | M4 | ⬜ |
| b8 | *"Use a clear, structured table or bullet-point format"* | The tables are used as-is in the PDF. | M3 | ⬜ |
| b9 | *"Use at least three user roles."* | **Four**: Student · Tutor/Teacher · Study Group Member · Admin. [`00 §7`](00-MASTER-PLAN.md). | M1 | ⬜ |
| b10 | *"Every student must be responsible for at least two features as a developer."* | Workload-balance table [`02 §3`](02-FEATURE-LIST-OWNERSHIP.md) — every member owns **3** (M3 owns 2 + the advanced feature). | M1 | ⬜ |
| b11 | *"the workload should be fairly distributed between team members."* | `02 §3` balance table + the explicit rationale for why frame count is not the fairness metric. | M1 | ⬜ |
| b12 | *"include at least one advanced feature agreed upon with the tutor, such as LLM integration, maps, group chats, or real-time multiplayer."* | **F15 AI Study Companion** (RAG + adaptive coach). Spec at [`02 §5`](02-FEATURE-LIST-OWNERSHIP.md). **⚠️ requires written tutor approval** | M2 | ⬜ |
| b13 | *"The advanced feature should be assigned to one or a maximum of two developers."* | F15 → **M2 + M3**, with the ownership split and interface contracts documented. | M2 | ⬜ |

> **Note:** we exceed the minimum deliberately in two places — 4 roles instead of 3, and 3 features per developer instead of 2. This is stated as a choice in the document so it reads as intentional ambition rather than padding.

---

## 4. Design Document — Mockups (8 of 20 — **the largest single block**)

Rubric area c. This is where the most marks are available, so it gets the most schedule time.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| c1 | *"Clearly show and reflect the structure and flow of each feature."* | One flow diagram + a grouped frame set per feature. [`03-SCREEN-INVENTORY.md`](03-SCREEN-INVENTORY.md) groups A–M. | all | ⬜ |
| c2 | *"Include multiple screens if the feature requires them."* | 7–18 screens per feature group; 141 total. Every feature exceeds one screen. | all | ⬜ |
| c3 | *"Contain written descriptions for each screen explaining its purpose and layout."* | The *Purpose & key labelled elements* column in [doc 03](03-SCREEN-INVENTORY.md) — written to be pasted directly into the PDF. | all | ⬜ |
| c4 | *"Identify and label all UI elements, such as buttons, inputs, and labels, and explain their function."* | Every screen's description **names** each element (in bold) **and** states what it does — e.g. *"**Generate** primary button — runs the grounded generation with the chosen settings"*. | all | ⬜ |
| c5 | *"You may use any software or method… paper sketches scanned, Draw.io, Figma, or Canva."* | **Figma (low-fidelity mode)** — same file as the prototype, so the low-fi and hi-fi stay in sync by construction. Framed as a deliberate efficiency choice. | M2 | ⬜ |
| c6 | *"should include all necessary screens, show clear navigation or screen flow, label UI elements clearly, and include written screen descriptions"* | Coverage audit against doc 03 · navigation map (doc 03 §5) · labelled elements · descriptions. | M4 | ⬜ |
| c7 | *"coverage of assigned features"* | All 15 features covered; the [frame-count-by-owner table](03-SCREEN-INVENTORY.md) proves each member covered their own features. | M4 | ⬜ |
| c8 | *"clarity of screen flow"* | 15 feature flow diagrams + the global navigation map + the modal/push distinction documented. | M3 | ⬜ |
| c9 | *"usability of layout"* | Design system ([doc 06](06-DESIGN-SYSTEM.md)) applied consistently: 4 pt grid, 16 pt margins, ≥44 pt targets, one primary action per screen. | M1 | ⬜ |
| c10 | *"meaningful UI labelling"* | Consistent terminology ("deck", "material", "session", "Coach") across every screen, both documents and the app. | M4 | ⬜ |
| c11 | *"overall neatness/professionalism"* | Aligned frames, consistent gaps, no overlapping elements, ordered frame numbering, consistent titles. | M1 | ⬜ |

**Low-fi vs hi-fi — state this explicitly in the document so the marker sees we understood the distinction:**

> *"Low-fidelity wireframes (structure, hierarchy and labels only — greyscale, no imagery) are presented in this document in accordance with the brief's Mockups requirement. The high-fidelity, fully interactive version is delivered separately as the Figma Project Prototype."*

---

## 5. Design Document — Innovation (2 of 20)

Rubric area d.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| d1 | *"Demonstrate creative and thoughtful design ideas beyond the basic requirements."* | The 10 innovation items in [`00-MASTER-PLAN.md` §9](00-MASTER-PLAN.md), each written as *Problem → Idea → Feasibility → Evidence*. | M2 | ⬜ |
| d2 | *"Show evidence of original thinking, user-focused improvements, or meaningful enhancement of the selected brief."* | Provenance-tagged generation · learning-style-adaptive output · weakness radar → auto-replanned plan · offline-first core loop · RTL/dyslexia support. | M2 | ⬜ |
| d3 | *"Marks are awarded for relevance, feasibility, and added value."* | Each item names the **screen ID or code artefact** that implements it — feasibility is demonstrated, not claimed. Cost model shows the "$0" claim is real. | M2 | ⬜ |

---

## 6. Design Document — Organisation and Presentation (2 of 20)

Rubric area e.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| e1 | *"should be clearly structured and easy to follow"* | The 19-section structure in [`00-MASTER-PLAN.md` §11](00-MASTER-PLAN.md) maps 1:1 onto the rubric order, so a marker never has to search. | M1 | ⬜ |
| e2 | *"Use consistent formatting throughout the document."* | One heading ladder, one body font, one accent, numbered captions, consistent table styling. | M1 | ⬜ |
| e3 | *"Present the document professionally with good readability."* | Auto-generated TOC/figure list/table list · page numbers · **app name + logo in the header of every page** · no orphan headings · figures ≥150 dpi. | M1 | ⬜ |
| e4 | *"organization, consistency, readability, and overall presentation quality"* | Two members read the whole document cold before submission and flag anything unclear. | M4 | ⬜ |

---

## 7. Project Identity requirements (stated outside the rubric — applies to all three phases)

| Requirement (verbatim) | Evidence | Owner | Status |
|---|---|---|---|
| *"A unique app name that is memorable and reflects your solution."* | **StudyForge** — "forge" is the brief's own metaphor (raw material → study tools). [`00 §5`](00-MASTER-PLAN.md). | M1 | 🟨 |
| *"A basic logo/icon concept that can be refined in later phases."* | Hexagon anvil mark in ember→gold on indigo; exported `@1x/@2x/@3x` + 1024 app icon. | M1 | ⬜ |
| *"Consistent use of this identity across all project materials, including app name on document covers and headers, logo/icon in mockups and prototype screens, and the same visual identity throughout all three assessment phases."* | Cover page + **every page header** · logo pinned in the Figma cover and on `01_Splash_Logo` / `15_Home_Dashboard_Student` · same palette in doc, mockups and prototype · **verify with a side-by-side check before each gate** | M1 | ⬜ |

---

## 8. Project Prototype (20 marks) — requirement-by-requirement

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| p1 | *"All main features of the app are designed and linked based on your feature list."* | All 15 features from [doc 02 §4](02-FEATURE-LIST-OWNERSHIP.md) have frames in [doc 03](03-SCREEN-INVENTORY.md) and are reachable by clicking. Traceability matrix in the appendix. | M2 | ⬜ |
| p2 | *"Interactive links between screens simulate taps, button presses, and navigation."* | Every item on the [doc 03 §6 wiring checklist](03-SCREEN-INVENTORY.md) verified by a click-through of the whole prototype. 4 end-to-end chains explicitly tested. | M4 | ⬜ |
| p3 | *"A clearly structured prototype reflects real-world app behavior and layout."* | Role-based tab bars · modal vs push distinction · iOS-native nav bars and sheets · realistic content (no lorem ipsum) · realistic Arabic + English data. | M3 | ⬜ |
| p4 | *"Visual consistency is maintained in terms of color themes, fonts, and UI elements."* | Figma **variables** bound to every component ([doc 06](06-DESIGN-SYSTEM.md)) so consistency is mechanically enforced, not eyeballed. Verified on the light *and* dark variants. | M1 | ⬜ |
| p5 | *"Screen organization is consistent in the prototype, and all frames/screens must be clearly named by developer, such as Login_Ahmed_2022XXXXX."* | Naming rule `NN_ScreenName_FirstName_StudentID` applied to all 141 frames + one Figma page per owner + a naming audit pass. **⚠️ stated rubric line** | M4 | ⬜ |
| p6 | *"Submit the interactive prototype file using a Figma file (.fig) alongside the shared link."* | `deliverables/prototype/StudyForge.fig` **and** `deliverables/prototype/figma-link.txt` (URL + "Anyone with the link can view" verified in a private window). **⚠️ both required** | M4 | ⬜ |
| p7 | *"It is encouraged that your prototype is tested thoroughly by team members and real users to gather feedback."* | Usability test with **5 real users**, 4 scripted tasks, think-aloud, SUS score, findings + applied fixes documented in Design Doc §17. | M4 | ⬜ |

### 8.1 Visual design principles (listed verbatim in the brief)

| Principle | Evidence | Status |
|---|---|---|
| **Balance** | One hero element per screen; symmetric 2×2 stat tiles; optical centring. [`06 §4.1`](06-DESIGN-SYSTEM.md). | ⬜ |
| **Contrast** | One primary action per screen; semantic fills paired with `onAccent` text to hold AA. | ⬜ |
| **Alignment** | Single 16 pt margin, single 4 pt grid, shared left edge across all screens. | ⬜ |
| **Simplicity** | ≤5 tabs, ≤7 items per settings group, ≤2 nav levels before a modal. | ⬜ |
| **Proximity** | Related controls grouped in cards; 24 pt between unrelated groups. | ⬜ |
| **Repetition** | One component library, one icon family (SF Symbols), one radius and motion ladder. | ⬜ |
| **White Space** | 16/24/40/48 pt rhythm; dense content, uncluttered chrome. | ⬜ |

### 8.2 Interaction and UX design practices (listed verbatim in the brief)

| Practice | Evidence | Status |
|---|---|---|
| **Clear Navigation** | 5-tab spine with role variants; no dead ends; location always visible. | ⬜ |
| **Interactive Elements** | ≥44×44 pt targets; pressed states; confirmation on destructive actions. | ⬜ |
| **Error & Feedback States** | Dedicated state screens `133`–`137` plus `30`, `41`, `50`, `56`, `87`, `98`, `126`. | ⬜ |
| **Mobile Optimization** | Thumb-zone CTAs; sheets not dropdowns; native keyboard types; no hover dependency. | ⬜ |
| **Consistency** | One terminology set across every screen; identical system for tutor/admin. | ⬜ |

### 8.3 Prototype quality extras (beyond the minimum, cheap to do)

| Extra | Why |
|---|---|
| **Dark mode variants** of the 10 hero screens | Demonstrates a real design system rather than a one-off skin |
| **RTL Arabic frame** (`139`) | Direct SDG 10 evidence that almost nobody else will have |
| **AX3 large-text frame** (`138`) | Accessibility proof |
| **Smart Animate** on ≥5 transitions | Makes the prototype feel like a product, not a slideshow |
| **Prototype starting frame + cover/legend page** | Shows the marker exactly where to begin |
| **3-minute recorded walkthrough** | Insurance against a marker not clicking through, and usable in the viva |

---

## 9. iOS App Implementation & Demonstration (60% — ⛔ MUST PASS)

> Verbatim: *"iOS App Implementation & Demonstration (60%) – Group project implementation assessed through the completed iOS application and an in-person VIVA/demonstration."*
> *"To pass the course, an aggregate mark of 60% must be achieved, and the iOS App Implementation & Demonstration is a Must Pass component."*

**This is the highest-value section in this document.** Full detail: [doc 11](11-APP-IMPLEMENTATION-VIVA.md).

| # | Requirement | Evidence | Owner | Status |
|---|---|---|---|---|
| app1 | All 15 features present and functional in the app | Tier A demo-solid; Tier B functional ([doc 11 §2](11-APP-IMPLEMENTATION-VIVA.md)) | all | ⬜ |
| app2 | Runs on a **physical device** | Demo device with Apple Intelligence enabled | M1 | ⬜ |
| app3 | Loading, empty, error and offline states implemented | Screen recordings of each state | all | ⬜ |
| app4 | Real Firebase backend with server-enforced rules | Emulator rules tests passing, including negative tests | M1 | ⬜ |
| app5 | AI pipeline works, with graceful degradation | Generation demo + the fallback screen behaviour | M2 | ⬜ |
| app6 | Payments work in Tap sandbox; entitlement unlocks | Recorded sandbox payment + function logs | M3 | ⬜ |
| app7 | Feature freeze respected from 30 Nov; no new features after | Commit history | M3 | ⬜ |
| demo1 | Golden path rehearsed and timed to 5 minutes | [doc 11 §4](11-APP-IMPLEMENTATION-VIVA.md) script | M4 | ⬜ |
| demo2 | Backup screen recording on device **and** USB | Recording file | M4 | ⬜ |
| demo3 | Four demo accounts + demo content seeded and frozen | Verified accounts and data | M1 | ⬜ |
| demo4 | Environment checklist executed before the demo | [doc 11 §6](11-APP-IMPLEMENTATION-VIVA.md) ticked | M4 | ⬜ |
| viva1 | Every member can present a feature they did **not** build | Rotated presentations in S3–S5 reviews | all | ⬜ |
| viva2 | Every member can explain **their own** feature from the code | Code walkthrough rehearsal | all | ⬜ |
| viva3 | Traceability one-pager per member | `research/cheatsheets/<name>.md` | all | ⬜ |
| viva4 | An honest answer prepared for *"what doesn't work?"* | [doc 11 §7](11-APP-IMPLEMENTATION-VIVA.md) | all | ⬜ |

---

## 10. Sprints (10% — individual)

> Verbatim: *"Sprints (10%) – Individual assessment of each student's contribution and progress during the implementation of the group project."*

Full detail: [doc 10](10-SPRINT-PLAN.md). **Four separate marks — one per member.** Nobody's score is raised by a strong teammate.

| # | Requirement | Evidence | Location |
|---|---|---|---|
| s1 | Contribution in **every** sprint, by **every** member | The [doc 10 §4](10-SPRINT-PLAN.md) allocation fulfilled | `research/sprints/` |
| s2 | Contribution log written within 24 h, evidence-linked | Per-member logs | `research/sprints/sprint-N/<name>-contribution.md` |
| s3 | Authored commits and PRs on owned features | `git log --author`, PR list | GitHub |
| s4 | Sprint review demo of **your own** work | Recorded reviews / screenshots | `research/sprints/` |
| s5 | Test logs for the features you are the named tester of | Test logs per [doc 02 §7](02-FEATURE-LIST-OWNERSHIP.md) | `research/testing/` |
| s6 | Review notes on AI-generated code, with your corrections | Review notes + the fixing commit | `research/reviews/` |
| s7 | Comprehension contract honoured (rules 1–6) | `hand:` commits · walkthrough recordings · cheat sheets | [doc 10 §9](10-SPRINT-PLAN.md) |
| s8 | Progress visible **across** the project, not one end-of-sprint burst | Commit timeline | GitHub |
| s9 | Sprint retro recorded with one keep / one change | Retro notes | `research/sprints/sprint-N/retro.md` |

> **The trap to avoid:** with Cline writing code, a member can easily finish a project with real contribution but **no attributable evidence**. Requirements s2, s4 and s7 exist specifically to prevent that — and they must be maintained continuously, because a back-filled log is obvious and reads as fabricated.

---

## 11. Pre-submission audit — run this twice

### Gate 1 · Design Document (before 21 Oct)

- [ ] Every ⬜ row in §2–§7 above is now ✅, or consciously accepted as a lost mark
- [ ] Tutor interview **questions AND responses** are in the document
- [ ] Written tutor approval for the F15 advanced feature is recorded
- [ ] Every one of the 15 features has all seven required columns populated
- [ ] Workload balance is stated, not just implied
- [ ] All 89 P0 screens exist in low fidelity, described and labelled
- [ ] 15 feature flow diagrams + 1 global navigation map
- [ ] 10 innovation items each state relevance, feasibility and evidence
- [ ] Cover page + header on every page carry the app name and logo
- [ ] TOC, figure list and table list auto-generated
- [ ] Harvard references with in-text citations
- [ ] Spot-check 5 screens: is every UI element labelled *and* is its function explained?
- [ ] PDF exported, fonts embedded, images ≥150 dpi, links live

### Gate 2 · Prototype (before 11 Nov)

- [ ] All 15 features designed and **reachable by clicking**
- [ ] Every hotspot clicked at least once (no dead ends)
- [ ] 4 end-to-end chains work: onboarding→home · upload→summary→folder · quiz→results→re-plan · paywall→receipt
- [ ] Every frame named `NN_ScreenName_FirstName_StudentID` — audited
- [ ] Overflow set on every frame · starting frame set
- [ ] Error, empty, loading, offline and success states all present
- [ ] Dark mode + RTL + AX3 frames present
- [ ] Usability test with 5 users completed; SUS score calculated
- [ ] Figma share set to viewable-by-link and verified in a private window
- [ ] `.fig` exported **and** the link text document written
- [ ] Submission package assembled and submitted 24 h early
- [ ] `git tag prototype-v1`

---

## 12. Self-marking projection

### 12.1 Course level — what actually determines the outcome

| Component | Weight | Target | Must pass | Current |
|---|---|---|---|---|
| Individual App | 10% | complete | — | ✅ done |
| Design Document | 10% | 9.0 | — | |
| Prototype (Figma) | 10% | 7.0 | — | |
| Sprints *(individual — score yourself honestly)* | 10% | 8.0 | — | |
| **iOS App Implementation & Demonstration** | **60%** | **48+ (80%)** | ⛔ **Yes** | |
| **Aggregate** | **100%** | **≥ 72** | — | |

**Why these targets:** an aggregate of ~72 gives comfortable headroom over the 60% pass bar, and the app target is set at **80%** deliberately — it is both the largest component *and* the gate, so it deserves the highest target rather than an "average" one.

### 12.2 Design Document sub-areas

| Rubric area | Max | Target | Current | Gap |
|---|---|---|---|---|
| Design Doc · Background Research | 4 | 4 | | |
| Design Doc · Features List | 4 | 4 | | |
| Design Doc · Mockups | 8 | 7.5 | | |
| Design Doc · Innovation | 2 | 2 | | |
| Design Doc · Organisation & Presentation | 2 | 2 | | |
| **Design Document total** | **20** | **19.5** | | |

> **Reality check on the mockup target:** 8/8 is realistic **only if** every screen has a written description with labelled, explained UI elements — that is where most groups lose 2–3 of those 8 marks. The descriptions in [doc 03](03-SCREEN-INVENTORY.md) exist precisely to make that achievable without last-minute writing.



