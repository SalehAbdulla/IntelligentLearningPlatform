# 08, Rubric Coverage Matrix (the full-marks checklist)

> **This is the single most important document in the repo.** Every rubric bullet from the brief is reproduced verbatim below with the specific evidence that satisfies it, the owner, and a status. If a row has no evidence, that is a **lost mark**, and it is fixable today.

Status legend: ⬜ not started · 🟨 in progress · ✅ done

---

## 1. How to use this

1. **Before every gate**, read this file top to bottom.
2. For any ⬜ row, create a task and assign it during the next stand-up.
3. The `Evidence` column must point at something a marker can *open*: a page of the PDF, a Figma frame ID, a file in the repo.

---

## 2. Design Document, Background Research (4 of 20)

Rubric area a, *"Group Assessment – 4%"*.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| a1 | *"A clear explanation of the real world or context, including who is affected and why the issue matters."* | Design Doc §2 → problem statement, affected population, scale, Gulf/Bahrain context. Dashboard at `research/dossier.md` §1. | M1 | ⬜ |
| a2 | *"A clear description of the app's purpose, goals, and intended impact as a solution to the problem."* | Design Doc §5 → purpose, goals, **measurable** success metrics, intended impact. | M1 | ⬜ |
| a3 | *"Supporting research or references, such as online research, trends, or statistics."* | Design Doc §2 + §18 → **8+ cited sources** (retrieval practice, spaced repetition, testing effect, GCC digital-learning adoption, Bahrain Resolution No. 43), Harvard style. `research/dossier.md`. | M4 | ⬜ |
| a4 | *"Group interview summary with your tutor… Include questions asked and summary of responses."* | Design Doc §3 → **Table 3.2**, the 10 questions each mapped to the rubric bullet it serves and the member who asks it, plus **Table 3.3**, the tutor's answers verbatim with a "what changed as a result" column. The interview guidelines also make the **transcript** and the **summary** graded parts: transcript, capture sheet and the **written F15 approval** in [`research/interviews/`](../research/interviews/README.md). The 10 questions and the 3 buffers are banked in [roadmap Phase 1 §4](01-ROADMAP-PHASES-TODOLIST.md). **⚠️ easy to lose** | M2 | ⬜ |
| a5 | *"Explain what gives your app a competitive edge compared to similar apps in the market."* | Design Doc §4 → competitor teardown table (Quizlet · Anki · NotebookLM · Notion · ChatGPT · Studocu) + the "one closed loop" claim + 3 differentiators. [`00-MASTER-PLAN.md` §8](00-MASTER-PLAN.md). | M4 | ⬜ |

**Also required by the brief for this area (not a separate bullet but stated):** the interview must be *"focused on collecting information from your tutor within class time"*, record the date, location and attendees. ⬜

---

## 3. Design Document, Features List (4 of 20)

Rubric area b.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| b1 | *"Submit a structured feature list."* | Design Doc §7 → the master table. [`02-FEATURE-LIST-OWNERSHIP.md` §4](02-FEATURE-LIST-OWNERSHIP.md). | M3 | ⬜ |
| b2 | *"Name of Feature"* | Master table column *Feature*, F01–F17. | M3 | ⬜ |
| b3 | *"Main Task: What is the feature trying to accomplish from the user's perspective?"* | Master table column *Main task*, all 15 written from the user's perspective. | M3 | ⬜ |
| b4 | *"User: Who is the intended user for this feature"* | Master table column *Role*, 4 distinct roles used across the set. | M3 | ⬜ |
| b5 | *"Sub-Tasks/Steps: Describe a brief flow or individual steps"* | Design Doc §7 → the expanded sub-task table. [`02 §6`](02-FEATURE-LIST-OWNERSHIP.md). | M3 | ⬜ |
| b6 | *"Developer: The team member responsible"* | Master table column *Developer*. | M3 | ⬜ |
| b7 | *"Tester: Another team member responsible for testing"* | Master table column *Tester* **and** the rotation matrix [`02 §7`](02-FEATURE-LIST-OWNERSHIP.md) proving tester ≠ developer. | M4 | ⬜ |
| b8 | *"Use a clear, structured table or bullet-point format"* | The tables are used as-is in the PDF. | M3 | ⬜ |
| b9 | *"Use at least three user roles."* | **Four**: Student · Tutor/Teacher · Study Group Member · Admin. [`00 §7`](00-MASTER-PLAN.md). | M1 | ⬜ |
| b10 | *"Every student must be responsible for at least two features as a developer."* | Workload-balance table [`02 §3`](02-FEATURE-LIST-OWNERSHIP.md): every member owns **2–4** (M2 and M3 also co-own the advanced feature), the minimum is 2, and M5's two are both net-new. | M1 | ⬜ |
| b11 | *"the workload should be fairly distributed between team members."* | `02 §3` balance table + the explicit rationale for why frame count is not the fairness metric. | M1 | ⬜ |
| b12 | *"include at least one advanced feature agreed upon with the tutor, such as LLM integration, maps, group chats, or real-time multiplayer."* | **F15 AI Study Companion** (RAG + adaptive coach). Spec at [`02 §5`](02-FEATURE-LIST-OWNERSHIP.md). **⚠️ requires written tutor approval** | M2 | ⬜ |
| b13 | *"The advanced feature should be assigned to one or a maximum of two developers."* | F15 → **M2 + M3**, with the ownership split and interface contracts documented. | M2 | ⬜ |

> **Note:** we exceed the minimum deliberately in two places, 4 roles instead of 3, and 3 features per developer instead of 2. This is stated as a choice in the document so it reads as intentional ambition rather than padding.

---

## 4. Design Document, Mockups (8 of 20, **the largest single block**)

Rubric area c. This is where the most marks are available, so it gets the most schedule time.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| c1 | *"Clearly show and reflect the structure and flow of each feature."* | One flow diagram + a grouped frame set per feature. [`03-SCREEN-INVENTORY.md`](03-SCREEN-INVENTORY.md) groups A–M. | all | ⬜ |
| c2 | *"Include multiple screens if the feature requires them."* | **130 low-fidelity wireframes** across the **17** features, **3–16 per feature**, so every feature exceeds a single screen. (The hi-fi prototype is a separate count: **123** frames built of a **154**-frame inventory.) | all | ⬜ |
| c3 | *"Contain written descriptions for each screen explaining its purpose and layout."* | The *Purpose & key labelled elements* column in [doc 03](03-SCREEN-INVENTORY.md), written to be pasted directly into the PDF. | all | ⬜ |
| c4 | *"Identify and label all UI elements, such as buttons, inputs, and labels, and explain their function."* | Every screen's description **names** each element (in bold) **and** states what it does, e.g. *"**Generate** primary button, runs the grounded generation with the chosen settings"*. | all | ⬜ |
| c5 | *"You may use any software or method… paper sketches scanned, Draw.io, Figma, or Canva."* | **Figma (low-fidelity mode)**, same file as the prototype, so the low-fi and hi-fi stay in sync by construction. Framed as a deliberate efficiency choice. | M2 | ⬜ |
| c6 | *"should include all necessary screens, show clear navigation or screen flow, label UI elements clearly, and include written screen descriptions"* | Coverage audit against doc 03 · navigation map (doc 03 §5) · labelled elements · descriptions. | M4 | ⬜ |
| c7 | *"coverage of assigned features"* | All **17** features covered; the [frame-count-by-owner table](03-SCREEN-INVENTORY.md) §4 proves each member covered their own features, including **M5's groups N and O**. | M4 + **M5** | ⬜ |
| c8 | *"clarity of screen flow"* | 17 feature flow diagrams + the global navigation map + the modal/push distinction documented. | M3 | ⬜ |
| c9 | *"usability of layout"* | Design system ([doc 06](06-DESIGN-SYSTEM.md)) applied consistently: 4 pt grid, 16 pt margins, ≥44 pt targets, one primary action per screen. | M1 | ⬜ |
| c10 | *"meaningful UI labelling"* | Consistent terminology ("deck", "material", "session", "Coach") across every screen, both documents and the app. | M4 | ⬜ |
| c11 | *"overall neatness/professionalism"* | Aligned frames, consistent gaps, no overlapping elements, ordered frame numbering, consistent titles. | M1 | ⬜ |

**Status update, 8 Oct 2026 (verified against the live file):** every row above is now
backed by something a marker can open.

| Row | Status | Evidence now in place |
|---|---|---|
| c1 | ✅ | 17 per-feature flow diagrams on Figma page `2 · Flow Overview`, each ending in its error/edge case, plus a grouped frame set per feature |
| c2 | ✅ | **130 low-fi wireframes**; every feature has **3–18** screens (`SCREEN-DESCRIPTIONS.md` §A.17) |
| c3 | ✅ | `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md` §A.2–§A.16: purpose **and** layout for all **130** wireframes |
| c4 | ✅ | Numbered callout badges on every wireframe, mapped to a legend panel that gives each element's **type** and **function** |
| c5 | ✅ | Figma page `5 · Low-Fi Wireframes`, greyscale, generated from the same geometry as the prototype |
| c6 | ✅ | Coverage audit §A.17, navigation map + 17 flow diagrams, labelled elements, descriptions |
| c7 | ✅ | [doc 03 §4](03-SCREEN-INVENTORY.md) gives frames per owner across **five** members: **M1 48 · M2 41 · M3 25 · M4 27 · M5 13 = 154** |
| c8 | ✅ | 17 flow diagrams + the navigation map; modal vs pushed distinction documented in doc 03 §5 |
| c9 | ✅ | One shared 4 pt grid, ≥44 pt targets, one primary action per screen |
| c10 | ✅ | Terminology is consistent across mockups, prototype and app ("deck", "material", "session", "Coach") |
| c11 | ✅ | Greyscale only, consistent gaps, ordered numbering, no overlapping elements |

**Low-fi vs hi-fi, state this explicitly in the document so the marker sees we understood the distinction:**

> *"Low-fidelity wireframes (structure, hierarchy and labels only, greyscale, no imagery) are presented in this document in accordance with the brief's Mockups requirement. The high-fidelity, fully interactive version is delivered separately as the Figma Project Prototype."*

---

## 5. Design Document, Innovation (2 of 20)

Rubric area d.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| d1 | *"Demonstrate creative and thoughtful design ideas beyond the basic requirements."* | The 10 innovation items in [`00-MASTER-PLAN.md` §9](00-MASTER-PLAN.md), each written as *Problem → Idea → Feasibility → Evidence*. | M2 | ⬜ |
| d2 | *"Show evidence of original thinking, user-focused improvements, or meaningful enhancement of the selected brief."* | Provenance-tagged generation · learning-style-adaptive output · weakness radar → auto-replanned plan · offline-first core loop · RTL/dyslexia support. | M2 | ⬜ |
| d3 | *"Marks are awarded for relevance, feasibility, and added value."* | Each item names the **screen ID or code artefact** that implements it, feasibility is demonstrated, not claimed. Cost model shows the "$0" claim is real. | M2 | ⬜ |

---

## 6. Design Document, Organisation and Presentation (2 of 20)

Rubric area e.

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| e1 | *"should be clearly structured and easy to follow"* | The 19-section structure in [`00-MASTER-PLAN.md` §11](00-MASTER-PLAN.md) maps 1:1 onto the rubric order, so a marker never has to search. | M1 | ⬜ |
| e2 | *"Use consistent formatting throughout the document."* | One heading ladder, one body font, one accent, numbered captions, consistent table styling. | M1 | ⬜ |
| e3 | *"Present the document professionally with good readability."* | Auto-generated TOC/figure list/table list · page numbers · **app name + logo in the header of every page** · no orphan headings · figures ≥150 dpi. | M1 | ⬜ |
| e4 | *"organization, consistency, readability, and overall presentation quality"* | Two members read the whole document cold before submission and flag anything unclear. | M4 | ⬜ |

---

## 7. Project Identity requirements (stated outside the rubric, applies to all three phases)

| Requirement (verbatim) | Evidence | Owner | Status |
|---|---|---|---|
| *"A unique app name that is memorable and reflects your solution."* | **StudyForge**, "forge" is the brief's own metaphor (raw material → study tools). [`00 §5`](00-MASTER-PLAN.md). | M1 | 🟨 |
| *"A basic logo/icon concept that can be refined in later phases."* | Hexagon anvil mark in ember→gold on deep blue; exported `@1x/@2x/@3x` + 1024 app icon. | M1 | ⬜ |
| *"Consistent use of this identity across all project materials, including app name on document covers and headers, logo/icon in mockups and prototype screens, and the same visual identity throughout all three assessment phases."* | Cover page + **every page header** · logo pinned in the Figma cover and on `01_Splash_Logo` / `15_Home_Dashboard_Student` · same palette in doc, mockups and prototype · **verify with a side-by-side check before each gate** | M1 | ⬜ |

---

## 8. Project Prototype (20 marks), requirement-by-requirement

| # | Rubric bullet (verbatim) | Evidence | Owner | Status |
|---|---|---|---|---|
| p1 | *"All main features of the app are designed and linked based on your feature list."* | All 17 features from [doc 02 §4](02-FEATURE-LIST-OWNERSHIP.md) have frames in [doc 03](03-SCREEN-INVENTORY.md) and are reachable by clicking. Traceability matrix in the appendix. | M2 | ⬜ |
| p2 | *"Interactive links between screens simulate taps, button presses, and navigation."* | Every item on the [doc 03 §6 wiring checklist](03-SCREEN-INVENTORY.md) verified by a click-through of the whole prototype. 4 end-to-end chains explicitly tested. | M4 | ⬜ |
| p3 | *"A clearly structured prototype reflects real-world app behavior and layout."* | Role-based tab bars · modal vs push distinction · iOS-native nav bars and sheets · realistic content (no lorem ipsum) · realistic Arabic + English data. | M3 | ⬜ |
| p4 | *"Visual consistency is maintained in terms of color themes, fonts, and UI elements."* | Figma **variables** bound to every component ([doc 06](06-DESIGN-SYSTEM.md)) so consistency is mechanically enforced, not eyeballed. Verified on the light *and* dark variants. | M1 | ⬜ |
| p5 | *"Screen organization is consistent in the prototype, and all frames/screens must be clearly named by developer, such as Login_Ahmed_2022XXXXX."* | Naming rule `NN_ScreenName_FirstName_StudentID` applied to all 154 frames + one Figma page per owner + a naming audit pass. **⚠️ stated rubric line** | M4 | ⬜ |
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

## 9. iOS App Implementation & Demonstration (60%, ⛔ MUST PASS)

> Verbatim: *"iOS App Implementation & Demonstration (60%) – Group project implementation assessed through the completed iOS application and an in-person VIVA/demonstration."*
> *"To pass the course, an aggregate mark of 60% must be achieved, and the iOS App Implementation & Demonstration is a Must Pass component."*

**This is the highest-value section in this document.** Full detail: [doc 11](11-APP-IMPLEMENTATION-VIVA.md).

| # | Requirement | Evidence | Owner | Status |
|---|---|---|---|---|
| app1 | All 17 features present and functional in the app | Tier A demo-solid; Tier B functional ([doc 11 §2](11-APP-IMPLEMENTATION-VIVA.md)) | all | ⬜ |
| app2 | Runs on a **physical device** | Demo device with Apple Intelligence enabled | M1 | ⬜ |
| app3 | Loading, empty, error and offline states implemented | Screen recordings of each state | all | ⬜ |
| app4 | Real Firebase backend with server-enforced rules | Emulator rules tests passing, including negative tests | M1 | ⬜ |
| app5 | AI pipeline works, with graceful degradation | Generation demo + the fallback screen behaviour | M2 | ⬜ |
| app6 | Payments work in Tap sandbox; entitlement unlocks | Recorded sandbox payment + function logs | M3 | ⬜ |
| app7 | Feature freeze respected from 30 Nov; no new features after | Commit history | M3 | ⬜ |
| demo1 | Golden path rehearsed and timed to 5 minutes | [doc 11 §4](11-APP-IMPLEMENTATION-VIVA.md) script · **executable run sheet with a fallback line per step**: [`research/demo/run-sheet.md`](../research/demo/run-sheet.md). **M5 presents 2:20–2:45 (F17)** and joins the tutor/admin step (F16) | M4 + **M5** | ⬜ |
| demo2 | Backup screen recording on device **and** USB | Recording file | M4 | ⬜ |
| demo3 | Four demo accounts + demo content seeded and frozen | Verified accounts and data | M1 | ⬜ |
| demo4 | Environment checklist executed before the demo | [doc 11 §6](11-APP-IMPLEMENTATION-VIVA.md) ticked | M4 | ⬜ |
| viva1 | Every member can present a feature they did **not** build | Rotated presentations in S3–S5 reviews | all | ⬜ |
| viva2 | Every member can explain **their own** feature from the code | Code walkthrough rehearsal | all | ⬜ |
| viva3 | Traceability one-pager per member | `research/cheatsheets/<name>.md` | all | ⬜ |
| viva4 | An honest answer prepared for *"what doesn't work?"* | [doc 11 §7](11-APP-IMPLEMENTATION-VIVA.md) | all | ⬜ |

---

## 10. Sprints (10%, individual)

> Verbatim: *"Sprints (10%) – Individual assessment of each student's contribution and progress during the implementation of the group project."*

Full detail: [doc 10](10-SPRINT-PLAN.md). **Four separate marks, one per member.** Nobody's score is raised by a strong teammate.

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

> **The trap to avoid:** with Cline writing code, a member can easily finish a project with real contribution but **no attributable evidence**. Requirements s2, s4 and s7 exist specifically to prevent that, and they must be maintained continuously, because a back-filled log is obvious and reads as fabricated.

---

## 11. Pre-submission audit, run this twice

### Gate 1 · Design Document (before 21 Oct)

- [ ] Every ⬜ row in §2–§7 above is now ✅, or consciously accepted as a lost mark — **reconciled 28 Oct 2026: stays open, and it is the one box that must.** The rows still ⬜ are the ones whose evidence is a *person* — the sprint artefacts, the usability session, the portal submission — not an artefact that can be checked from the repository.
- [x] Tutor interview **questions AND responses** are in the document — **verified 28 Oct 2026:** [`research/interviews/tutor-interview-transcript.md`](../research/interviews/tutor-interview-transcript.md) holds **five** questions with their responses, and Design Document **§3.3** carries Table 3.3 recording what each answer changed in the design.
- [x] Written tutor approval for the F15 advanced feature is recorded — **verified 28 Oct 2026:** [`research/interviews/f15-advanced-feature-approval.md`](../research/interviews/f15-advanced-feature-approval.md) records **Ghassan AlShajjar** (Tutor, EDICT Programming) approving **in writing on 15 Oct 2026**, with the three conditions and where each one is met; Design Document **§3.4** cites it.
- [x] Every one of the 17 features has all seven required columns populated — **verified 28 Oct 2026:** the [doc 02](02-FEATURE-LIST-OWNERSHIP.md) §4 table carries **7 columns** and **17 feature rows** (F01–F17), each populated.
- [x] Workload balance is stated, not just implied — **verified 28 Oct 2026:** [doc 02 §3](02-FEATURE-LIST-OWNERSHIP.md) carries the weighting column and states the position outright — *"feature count alone is not the fairness metric"* — balancing feature count, frame count, risk ownership (F15, F13), interaction complexity and how much of the work is net-new.
- [x] All 89 P0 screens exist in low fidelity, described and labelled — **verified 28 Oct 2026:** [doc 03](03-SCREEN-INVENTORY.md) puts the P0 floor at **89** screens, and [`SCREEN-DESCRIPTIONS.md`](../deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md) describes **130** wireframes across all 17 features, each with numbered callout badges and a legend panel naming every element and its type.
- [x] 17 feature flow diagrams + 1 global navigation map — **verified 28 Oct 2026:** **17** `FLOW_F*.png` files plus `02_NavigationMap_StudyForge.png` in `deliverables/design-document/mockups/figures/`, and the gate's `new-flows` check fails below 17.
- [x] 10 innovation items each state relevance, feasibility and evidence — **verified 28 Oct 2026:** Design Document **§13** presents exactly **ten** items in Table 13.1, each with its **Problem, Idea, Feasibility and Evidence** columns populated.
- [x] Cover page + header on every page carry the app name and logo — **closed 24 Oct 2026:** `tools/build-pdf.sh` now adds the header (app name + app-icon logo) and `Page X of Y` to every page through `tools/pdf-headers.js`; verified with `pdftotext` on pages 2 and 100 of the export
- [x] TOC, figure list and table list auto-generated — **verified 28 Oct 2026:** `## Table of contents` (line 30), `## List of figures` (line 57) and `## List of tables` (line 89) are all present in the Markdown, and `tools/build-figure-index.py` plus `tools/build-pdf.sh` regenerate the lists from the figures at build time.
- [ ] Harvard references with in-text citations — **reconciled 28 Oct 2026: the list is right, the citations are not.** Design Document **§18** carries **12** properly Harvard-formatted entries (author-date, italicised titles, `pp.` ranges, the Bahrain data-protection statute, and WCAG 2.2 with an access date). **But the document cites them only three times in text** — two parenthetical `(Author, Year)` and one narrative `Author (Year)` — across ~197 pages. This is the cheapest real gap in Gate 1: the references exist and the claims resting on them are in the document; what is missing is the pointer at each claim.
- [x] Spot-check 5 screens: is every UI element labelled *and* is its function explained? — **spot-checked 28 Oct 2026 on screens 35, 36, 37, 38 and 41** (§A.5, Group D, M2's F03). Every one holds: each row carries a **Purpose** stating the screen's function in a sentence, and a **Layout and key labelled elements** column naming every element in bold. *Limit:* checked against `SCREEN-DESCRIPTIONS.md` rather than against the rendered frames.
- [x] PDF exported, fonts embedded, images ≥150 dpi, links live — **verified 28 Oct 2026 by the gate:** `dd-figures` passes (*"Figures at 150 dpi, figure list, table list, PDF"*, smallest exported figure **1704 px** wide), fonts are embedded by the browser at build time, and the export carries **36 live external links**.

### Gate 2 · Prototype (before 11 Nov)

- [x] All 17 features designed and **reachable by clicking** — **verified 28 Oct 2026, with the limit stated:** [`figma-link.txt`](../deliverables/prototype/figma-link.txt) §9 records **110 of the 119** screens reachable by clicking alone; the remaining **9** (24, 30, 41, 77, 78, 88, 126, 133, 134) are state, error and secondary screens, each a **named flow start point** so it is directly reachable in the player, and *"no screen is a dead end"*. **Not re-measured since the F13 rework (24 Oct):** page 3 now holds **123** screens, so that figure predates the eleven new F13 screens.
- [x] Every hotspot clicked at least once (no dead ends) — **verified 28 Oct 2026:** the gate's `p9-07` **hotspot and link audit** passes, and the reachability audit closes with *"No screen is a dead end."*
- [x] 4 end-to-end chains work — **verified 28 Oct 2026:** `figma-link.txt` documents all four with their screen sequences — **Chain 1** onboarding→home (01→02→03→04→05→06→07), **Chain 2** upload→generated artefact, **Chain 3** quiz→adaptive re-plan, **Chain 4** paywall→entitlement (121→122→124→125).
- [x] Every frame named `NN_ScreenName_FirstName_StudentID`, audited — **verified 28 Oct 2026:** the gate's `p9-06` frame-naming audit passes.
- [x] Overflow set on every frame · starting frame set — **verified 28 Oct 2026:** the gate's `p9-08` overflow audit passes.
- [x] Error, empty, loading, offline and success states all present — **verified 28 Oct 2026 in the exported frames:** error (`LF_30_MaterialUpload_Error_UnsupportedFormat`, `LF_41_Summary_Error_QuotaExceeded`, `LF_134_Error_Server_Retry`), empty (`LF_154_RecallSpace_EmptyState`), offline (`LF_133_Error_NoInternet_OfflineBanner`), loading (the "Generating" screens 36 and 44) and success (`48_Flashcard_Session_Summary`), plus Group M's 14 cross-cutting state frames ([doc 09](09-RISKS-OPEN-QUESTIONS.md) D28).
- [x] Dark mode + RTL + AX3 frames present — **verified 28 Oct 2026:** the gate's `p9-11` (frames `138_Accessibility_LargeText_Example` and `139_RTL_Arabic_Example`) and `p9-12` (**106** dark-mode variants, one per screen) both pass.
- [ ] Usability test with 5 users completed; SUS score calculated — **reconciled 28 Oct 2026: the pack is ready, the session has not run.** `research/usability/` holds the protocol, facilitator script, consent form, the SUS questionnaire **with its exact scoring rule**, the participant log and the results template; `results.md` and `responses.md` are empty. **No score is recorded, deliberately** — a figure entered before the session would be invented. This is the same item as the gate's `dd-usability`/`p9-0304`, and one of only three keeping the submission gate red.
- [x] Figma share set to viewable-by-link and verified in a private window — **verified 28 Oct 2026:** the gate's `p9-share` passes, and the record of **17 Oct 2026** shows the check that matters was made with the **token-free** URL (`https://www.figma.com/design/uzTHnydXGeZSmImS5k2cLv` — no `?t=`, no `node-id`), because a token-bearing link can open a file whose link sharing is off and proves nothing.
- [x] `.fig` exported **and** the link text document written — **verified 28 Oct 2026:** the gate's `p9-14` (1,830,424 bytes, `meta.json` recording `exported_at 2026-10-23T23:01:26Z`) and `p9-17` (`deliverables/prototype/figma-link.txt`) both pass.
- [ ] Submission package assembled and submitted 24 h early — **reconciled 28 Oct 2026: assembled, not submitted, and no longer early.** `deliverables/submission/` is assembled and tracked, `deliverables/StudyForge-Submission.zip` is byte-compared against its sources by the gate's `bundle-fresh` check, and `prototype-v1` is tagged and pushed. **The portal submission itself is still open** (the gate's `p9-1819`), and the design-document deadline (**22 Oct 2026, 23:55**) has passed, so the "24 h early" half cannot be recovered — only recorded honestly.
- [x] `git tag prototype-v1` — **created and pushed 24 Oct 2026** at `7cd1bb6`, the branch head when the tag was placed (an earlier tag at `41bc978` was force-updated, so the tag and the branch agreed at that point)

---

## 12. Self-marking projection

### 12.1 Course level, what actually determines the outcome

| Component | Weight | Target | Must pass | Current |
|---|---|---|---|---|
| Individual App | 10% | complete | - | ✅ done |
| Design Document | 10% | 9.0 | - | |
| Prototype (Figma) | 10% | 7.0 | - | |
| Sprints *(individual, score yourself honestly)* | 10% | 8.0 | - | |
| **iOS App Implementation & Demonstration** | **60%** | **48+ (80%)** | ⛔ **Yes** | |
| **Aggregate** | **100%** | **≥ 72** | - | |

**Why these targets:** an aggregate of ~72 gives comfortable headroom over the 60% pass bar, and the app target is set at **80%** deliberately, it is both the largest component *and* the gate, so it deserves the highest target rather than an "average" one.

### 12.2 Design Document sub-areas

| Rubric area | Max | Target | Current | Gap |
|---|---|---|---|---|
| Design Doc · Background Research | 4 | 4 | | |
| Design Doc · Features List | 4 | 4 | | |
| Design Doc · Mockups | 8 | 7.5 | | |
| Design Doc · Innovation | 2 | 2 | | |
| Design Doc · Organisation & Presentation | 2 | 2 | | |
| **Design Document total** | **20** | **19.5** | | |

> **Reality check on the mockup target:** 8/8 is realistic **only if** every screen has a written description with labelled, explained UI elements, that is where most groups lose 2–3 of those 8 marks. The descriptions in [doc 03](03-SCREEN-INVENTORY.md) exist precisely to make that achievable without last-minute writing.



