# 01, Roadmap, Phases & Todolist

> **StudyForge** · the guide and roadmap for building the whole project.
> **Fixed deadlines:** Design Document **Thu 22 Oct 2026, 23:55** · Prototype (`.fig` + link) **Thu 12 Nov 2026, 23:55**.
> **Must pass:** the iOS App Implementation & Demonstration (**60%**), see [doc 11](11-APP-IMPLEMENTATION-VIVA.md).

---

## 1. The calendar

Today is **Mon 28 Sep 2026**. Work is organised as **five two-week sprints plus S0**. The Design Document deadline falls inside S2; the Prototype deadline falls inside S3, both are fixed constraints *inside* a sprint, never reasons to pause app work.

| Sprint | Dates | Theme | Fixed constraint inside | Sprint exit gate (must demo) |
|---|---|---|---|---|
| **S0** | Mon 28 Sep – Sun 4 Oct | Foundation & requirements | - | App builds on device · Firebase live · feature table signed off · tokens frozen |
| **S1** | Mon 5 Oct – Sun 18 Oct | **Core loop MVP** | - | Upload a real PDF → summary → 20 cards → review them, on a real device |
| **S2** | Mon 19 Oct – Sun 1 Nov | **Assessment engine** | 🚩 **Design Document 22 Oct** | Generate + take a quiz · plan generated · dashboard populated from real data |
| **S3** | Mon 2 Nov – Sun 15 Nov | **Collaboration & monetisation** | 🚩 **Prototype 12 Nov** | Two accounts share a folder · live group quiz on 2 devices · Tap sandbox payment succeeds |
| **S4** | Mon 16 Nov – Sun 29 Nov | **Intelligence & polish** | - | Coach answers with citations · offline mode · RTL · accessibility pass |
| **S5** | Mon 30 Nov – Sun 13 Dec | **Hardening & VIVA** | ⛔ **Feature freeze 30 Nov** | Golden path passes 3× · demo rehearsed · every member presents an unowned feature |

> ⚠️ **Sprint boundaries and the final demo/VIVA date are not specified in the Design Document brief.** These are **assumptions to confirm with the tutor in the first interview** ([§4](01-ROADMAP-PHASES-TODOLIST.md)). Adjust this table if the course defines its own sprints.

**Weekly rhythm (non-negotiable):** Monday sprint planning → daily async stand-up → Thursday mid-sprint check → Sunday review & demo (every member demos their **own** work) → retrospective. Minutes in `research/meeting-notes/`; sprint artefacts in `research/sprints/sprint-<N>/`.

---

## 2. Sprint and phase overview

| Sprint | Dates | Primary workstreams | Leads |
|---|---|---|---|
| **S0** | 28 Sep – 4 Oct | Setup & identity · research & discovery · feature definition | M1, M4, M3 |
| **S1** | 5 – 18 Oct | Low-fi mockups · design system · **app core loop (F01–F04)** | M2 (Figma), M1 + M2 (app) |
| **S2** | 19 Oct – 1 Nov | Design Document → **SUBMIT 22 Oct** · **assessment engine (F05–F08, F12, F14)** · **M5 ramp-up (F16, F17)** | M1 (doc), M2, M3, M4, **M5** |
| **S3** | 2 – 15 Nov | Hi-fi prototype → **SUBMIT 12 Nov** · **collaboration & payments (F09, F13, F11)** · **F16/F17 hardening** | M4 (Figma), M3 (payments), M2, **M5** |
| **S4** | 16 – 29 Nov | **Advanced feature F15** · offline · RTL · accessibility · dark mode · **F16/F17 polish** | M2 + M3, M4, **M5** |
| **S5** | 30 Nov – 13 Dec | Hardening · regression · **VIVA preparation** | all |

> **M5, Fatema Ghareeb, joined on 14 Oct 2026** and filled the brief's fifth seat. She is **not in S0 or S1** because she was not in the group yet, and her sprint evidence starts in S2 — which is why S2 is explicitly a **ramp-up**: her two features, **F16** and **F17**, were scaffolded and handed to her with a disjoint file lane, a `.mailmap` identity and TODO markers before the sprint began. Adding her mid-sprint rather than at the freeze is deliberate, because a contribution log cannot be created retroactively.

**Critical path, corrected:**

```
MUST PASS (60%)   App core loop → assessment engine → collaboration → polish → real-device demo → VIVA
PARALLEL (10% ea) Design Document (22 Oct)   ·   Figma Prototype (12 Nov)
CONTINUOUS (10%)  Individual sprint contribution evidence
```

**The app is the critical path.** Figma and document work run *alongside* it and must never block it. If app work slips, **Figma scope is cut first**, see the cut-line protocol in §14.

**Cross-reference:** the per-sprint, per-member task allocation lives in [doc 10 §4](10-SPRINT-PLAN.md) and the demo/VIVA rules in [doc 11](11-APP-IMPLEMENTATION-VIVA.md). The phase details below remain valid as *workstream* definitions; their timing is now governed by the sprint table above.

---

## 3. Phase details (workstream definitions)

> Sections 3–13 below define **what** each phase must produce. The **when** comes from the sprint table in §1. Read them as workstream specifications, not as a strictly sequential waterfall.


---

## 3. Phase 0, Setup & Project Identity · W0 · owner **M1**

**Goal:** remove every unknown that could block work later. When this phase ends, no one should have to ask "what's the app called?" or "what's the bundle ID?".

- [x] `P0-01` Create repo structure (`docs/`, `deliverables/`, `ios/`, `backend/`, `research/`) — **verified 28 Oct 2026:** all five exist and are tracked.
- [x] `P0-02` Add `.gitignore` excluding `GoogleService-Info.plist`, `*.xcuserdata`, secrets, `.env`, **verify no key is ever committed** — **verified 28 Oct 2026:** 9 matching rules in `.gitignore`, and the "no key" half is **enforced rather than promised** — `tools/commit.sh` scans every staged file for keys and refuses the commit, with a written allowlist for values that are public by design.
- [x] `P0-03` Verify toolchain: Xcode 27.0 · iOS 26.5 + 27.0 simulators · Swift 6.4 · Figma.app · Node 24.15 ✅
- [x] `P0-04` Create Firebase project `studyforge-it8108` on the **Spark (no-cost)** plan — **verified 28 Oct 2026:** `backend/.firebaserc` names `studyforge-it8108`, and [doc 09](09-RISKS-OPEN-QUESTIONS.md) R21 records `billingEnabled: false` **verified against the API**, so it is on the no-cost plan as specified.
- [x] `P0-05` Register iOS app, bundle ID `com.studyforge.app`, download `GoogleService-Info.plist` — **verified 28 Oct 2026:** `PRODUCT_BUNDLE_IDENTIFIER = com.studyforge.app` in the Xcode project. *Limit:* the plist is correctly gitignored, so its presence cannot be evidenced from the repository — and should not be.
- [ ] `P0-06` Enable: Auth (Email/Password + Sign in with Apple), Firestore, Storage (**bucket region `us-central1`**, required to stay inside the free tier), FCM, Analytics, Crashlytics, App Check — **reconciled 28 Oct 2026: three of the seven have code evidence, four have none.** Auth (**34 files**), Firestore (**31**) and Storage (**26**) are demonstrably in use; **FCM, Analytics, Crashlytics and App Check return 0 files**. Console enablement is not repository-verifiable, and notifications are **local, not push** (`NotificationViewModel`), so an unused FCM is consistent rather than broken. **Cannot be ticked as written** — if the console state matters, it needs a screenshot in `deliverables/`, not a code claim.
- [x] `P0-07` Install Firebase CLI (`npm i -g firebase-tools`), log in, run `firebase init` — **verified 28 Oct 2026:** `backend/firebase.json` configures the Firestore rules and indexes, the Storage rules, the `studyforge` functions codebase and the emulator suite, so `init` ran and the result is committed.
- [x] `P0-08` **Freeze the app name:** StudyForge (and confirm no trademark clash) — **verified 28 Oct 2026:** StudyForge is the name in the app, the design document, the Figma cover and the README, and [doc 09](09-RISKS-OPEN-QUESTIONS.md) **D1** records the choice against the alternatives considered.
- [ ] `P0-09` Design 3 logo concepts → team vote → export `@1x/@2x/@3x` PNG + SVG + 1024×1024 app icon — **reconciled 28 Oct 2026: the shipped icon exists, the export set does not.** `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` is in the app and ships. But a search of `deliverables/` finds **no `@1x/@2x/@3x` PNG set, no SVG and no logo-concept artefacts**, and no record of a three-concept team vote. **Say which it is** — if the concepts live only in Figma, record that here; if they do not exist, the box is honest as an open item.
- [x] `P0-10` Freeze palette, type scale and spacing grid → [doc 06](06-DESIGN-SYSTEM.md) — **verified 28 Oct 2026:** doc 06 holds all three, and **`bash tools/check-tokens.sh` gates the claim** — 21 colour tokens agree between doc 06 and `ColorTokens.swift` on every run, and the check is wired into the submission gate.
- [x] `P0-11` **Fill the real team names + student IDs** into [doc 02 §2](02-FEATURE-LIST-OWNERSHIP.md) ⚠️ *blocks Figma frame naming* — **verified 28 Oct 2026:** all five members are listed with real names, student IDs and frame-name suffixes, and `tools/verify-docs.py` **fails** if a roster entry goes missing.
- [ ] `P0-12` Create the Figma file with the **10 pages** from [doc 03 §1](03-SCREEN-INVENTORY.md) — **reconciled 28 Oct 2026: the file has seven pages and this line asks for ten.** `deliverables/prototype/figma-link.txt` documents *"the seven pages, each directly reachable"* and records that an earlier nine-page description **was wrong and has been corrected to match the file**. The file and the plan disagree, and **the plan is the stale half** — decide which is right, then correct the other. Do not tick this as though ten pages existed.
- [x] `P0-13` Publish Figma **styles** (colour, text, effect) + skeleton component library — **verified 28 Oct 2026:** `figma-link.txt` records page 1's design system — **38 colour variables** (Light + Dark modes), spacing and radius variables, **11 text styles**, **4 glass effect styles** and a Glass & Depth component set.
- [x] `P0-14` Book the **tutor interview** (target: early W1) and circulate the question list — **verified 28 Oct 2026:** held **Tuesday 13 October 2026** with all five members present, and [`research/interviews/tutor-interview-transcript.md`](../research/interviews/tutor-interview-transcript.md) holds the five questions with their responses.
- [x] `P0-15` Install the Cline agent skills in [doc 07](07-CLINE-SKILLS-AND-TOOLING.md) — **verified 28 Oct 2026:** `skills-lock.json` is tracked and pins the installed skills; doc 07 is the record.
- [x] `P0-16` Create the shared drive: `deliverables/`, `research/meeting-notes/`, `research/interviews/` — **verified 28 Oct 2026:** all three exist and are tracked, along with `research/{demo,testing,reviews,usability,sprints}/`.
- [ ] `P0-17` Register a **Tap Payments sandbox** account and request test keys (`pk_test_…`) — **reconciled 28 Oct 2026: the integration is built; the account is not evidenceable from here.** `backend/functions/src/index.ts` declares three Firebase secrets — `TAP_SECRET_KEY`, `TAP_WEBHOOK_SECRET`, `TAP_MERCHANT_ID` — and calls `https://api.tap.company/v2/charges`, so the sandbox path is real code rather than a mock. **The keys are correctly absent from the repository** (a committed secret would be the worse failure), so *"was a sandbox account registered"* is an account fact, not a repository one. Sandbox-only is the deliberate, documented boundary — [doc 09](09-RISKS-OPEN-QUESTIONS.md) **R6**, **D5**, **Q3**.
- [ ] `P0-18` Confirm all 5 members have Xcode installed and can build the empty project — **reconciled 28 Oct 2026: false for four of the five members, and deliberately superseded.** [`docs/18-WINDOWS-CONTRIBUTING.md`](18-WINDOWS-CONTRIBUTING.md) opens with *"Four of the five members work on **Windows**"* and *"Xcode is macOS-only. There is no workaround, no Windows port, and no emulator that runs an [iOS simulator]"*. The project's answer was **CI as the shared build machine** (`.github/workflows/ios.yml`: a macOS build plus the full test suite on every push and PR), so the box's *intent* — everyone can build and verify — is met even though its letter is not.

**Exit gate:** identity frozen · roster filled · Firebase project live · Figma file ready · interview booked.

---

## 4. Phase 1, Research & Discovery · W0–W1 · owner **M4**

**Goal:** produce the evidence base that earns the whole **Background Research (4 marks)** block. Vague claims score nothing; cited statistics and real interview quotes score full marks.

- [ ] `P1-01` Desk research: **8+ credible sources** on retrieval practice, spaced repetition and the testing effect (peer-reviewed preferred), each with a Harvard reference
- [ ] `P1-02` Desk research: digital-learning adoption in Bahrain / the GCC (cite **Resolution No. 43** on digital payments as a local-context source)
- [ ] `P1-03` Competitor teardown: Quizlet · Anki · Google NotebookLM · Notion · ChatGPT · Studocu, with **screenshots** and the gap table from [doc 00 §8](00-MASTER-PLAN.md)
- [ ] `P1-04` SDG mapping evidence for SDG 4 / 9 / 10 with a source per claim
- [ ] `P1-05` **Interview 5 real students** (semi-structured, 10 min each); capture verbatim quotes and photos of their current "study chaos"
- [ ] `P1-06` **Run the tutor interview**, ask the questions below, record the answers verbatim, note what changed
- [ ] `P1-07` Obtain **written approval for the F15 advanced feature** and record it in [doc 02 §5](02-FEATURE-LIST-OWNERSHIP.md)
- [ ] `P1-08` Write the problem statement: who is affected, why it matters, scale
- [ ] `P1-09` Write app purpose, goals and intended impact + **measurable** success metrics
- [x] `P1-10` Compile everything into `research/dossier.md` with a Harvard reference list — done 8 Oct 2026 (problem evidence, 13 cited sources, SDG mapping, competitor teardown, change log, road-map coverage; the still-unverified market figures are listed as open rather than asserted)

**Tutor interview question bank** (the rubric requires *"questions asked AND summary of responses"*, and the interview guidelines add a **transcript** and a **summary** as graded parts). Ten core questions, ordered by rubric weight, each mapped to the rubric bullet it serves, plus three buffer questions. The full wording, the asker per question and the 15-minute timing plan live in `deliverables/design-document/DESIGN-DOCUMENT.md` section 3.2, and the transcript template and capture sheet live in [`research/interviews/README.md`](../research/interviews/README.md).

1. **Advanced feature approval (asked first).** Our advanced feature is F15, an AI helper that answers only from the student's own uploaded files and then builds a study plan. Two of us will build it. Is it advanced enough, is it fine that two of us share it, and can we have that in writing today? Is F09, the live group quiz room, acceptable instead if not?
2. **Mockup coverage (8 of the 20 marks).** Every screen, or only the main screens of each feature? Do the error, empty, loading and no-internet screens each need their own labelled screen?
3. **How accurate the AI must be.** Is our plan enough (answers only from the student's file, shows where each answer came from, says how sure it is, a tutor checks AI content first, and no AI marking of real coursework), or must we also measure and report the accuracy?
4. **Number of features.** 17 features across 4 roles means 2 to 4 each, against a minimum of 2. Is 17 right, or fewer features with more detail?
5. **Finished screens in Phase 1.** Phase 1 asks for low-fidelity mockups but allows Figma, and our document shows finished high-fidelity screens. Could that cost us mockup marks?
6. **Payment, which the brief never mentions.** Is the F13 paid subscription a good extra idea, or outside the brief and better left as a note for future work?
7. **What proves an innovation.** Does each innovation need a screen or a piece of code, or is a written explanation enough?
8. **User roles.** Study Group Member is not a separate account in our design, a student joins a group and then gets the group features. Does that still count as 4 roles?
9. **Transcript and summary format.** Word for word and complete? Inside the main document or in an appendix? May we quote the answers directly?
10. **Usability testing.** We plan 5 classmates and a standard questionnaire (SUS). What permission and privacy rules do you need, and should we avoid asking them to upload their real study files?

**Buffers, if time remains:** whether a working iPhone app next to the Figma prototype is seen as a plus or as too much, the sprint dates and whether the final demo is live on a real device, and how much of the Tap against Apple payment conflict the document should explain.

**Exit gate:** dossier written · interview recorded · advanced feature approved in writing.

---

## 5. Phase 2, Feature Definition & Ownership · W1 · owner **M3**

**Goal:** lock the feature list before any pixel is drawn. Renumbering features after mockups exist is the single most expensive mistake available to us.

- [ ] `P2-01` Gap analysis vs the brief's 10 named features → arrive at 15 (see [doc 02 §4](02-FEATURE-LIST-OWNERSHIP.md))
- [ ] `P2-02` Complete the master table columns: name · role · main task · flow · developer · tester
- [ ] `P2-03` Assign developers so **every member owns ≥2 features** and effort is visibly balanced
- [ ] `P2-04` Assign testers using the rotation rule (nobody tests their own work)
- [ ] `P2-05` Freeze the F15 advanced-feature spec and the `RetrievalService` / `CoachPlanningService` contracts
- [ ] `P2-06` **All 5 members review and sign off** the feature table (record sign-off date)
- [ ] `P2-07` Map each feature → its screen IDs and its Firestore collections (traceability matrix)
- [ ] `P2-08` Write 2–3 acceptance criteria per feature (these become the test cases in Phase 9)

**Exit gate:** feature table signed off by all 4 · traceability matrix complete.

---

## 6. Phase 3, IA, Flows & Low-Fidelity Mockups · W1–W2 · owner **M2**

**Goal:** the **8-mark Mockups block**. This is the largest single rubric area, so it gets the most schedule time and the most people.

- [ ] `P3-01` Build the **information architecture tree** (tab bars, modal flows, depth limits) per [doc 03 §5](03-SCREEN-INVENTORY.md)
- [ ] `P3-02` Draw **one flow diagram per feature** (15 diagrams), start/end, decisions, error branches
- [ ] `P3-03` Draw the **global navigation map** on one page
- [ ] `P3-04` Each member draws their **P0 frames in low fidelity** (boxes, labels, no styling), 89 frames total
- [ ] `P3-05` For **every** screen write the three rubric-required items: description · purpose/layout · labelled UI elements *with their function*
- [ ] `P3-06` Peer-review pass: each member checks another member's frames against the doc 03 inventory (coverage gaps are the #1 mark-loser)
- [ ] `P3-07` Cover the **required state set**: loading · empty · error · success · offline · permission-denied
- [ ] `P3-08` Ensure **app name + logo appear** in mockups (project identity rubric requirement)
- [ ] `P3-09` Assemble frames into the document order (grouped by feature, with flow diagrams preceding each group)
- [ ] `P3-10` Write the low-fi figure captions (`Figure 12, F04 flashcard review, front state`)
- [ ] `P3-11` Completeness audit against [doc 08](08-RUBRIC-COVERAGE-MATRIX.md), every rubric bullet ticked
- [ ] `P3-12` Freeze low-fi: no new screens after this point without a change-log entry

**Exit gate:** 89 P0 frames drawn and described · 15 flow diagrams · completeness audit passed.

---

## 7. Phase 4, Design Document Assembly → 🚩 **GATE 1** · W2–W3 · owner **M1**

**Goal:** one PDF, structurally identical to the 19-section plan in [doc 00 §11](00-MASTER-PLAN.md), submitted with a **24-hour buffer**.

- [x] `P4-01` Build the Word/Pages master file with the heading style ladder **first** (formatting must be systemic, not per-section) — **verified 28 Oct 2026:** the master is [`deliverables/design-document/DESIGN-DOCUMENT.md`](../deliverables/design-document/DESIGN-DOCUMENT.md) and the Word export is generated from it by `bash tools/build-docx.sh` **into the university's own template**, so the heading ladder is the template's styles rather than per-section formatting. *Limit:* the ladder is inherited from the template, not authored in the Markdown.
- [x] `P4-02` Create the cover page: app name, logo, tagline, team table with IDs, module, tutors, date — **verified 28 Oct 2026:** the cover carries **app name, tagline, client brief, module, all five members with student IDs, both tutors** (Haetham Alhaddad · Ghassan AlShajjar), the platform, the three SDGs, both due dates and the document version.
- [x] `P4-03` Auto-generate table of contents, figure list and table list (never type these by hand) — **verified 28 Oct 2026:** `## Table of contents` (line 30), `## List of figures` (57) and `## List of tables` (89) are present, and `tools/build-figure-index.py` regenerates the lists from the figures at build time.
- [x] `P4-04` Drop in sections 1–6 (research, interview, competitive analysis, purpose, personas) — **verified 28 Oct 2026:** §§1–6 present.
- [x] `P4-05` Drop in section 7–8 (feature list table + advanced feature spec) — **verified 28 Oct 2026:** §§7–8 present.
- [x] `P4-06` Drop in sections 9–11 (flows, low-fi mockups, navigation map) — **verified 28 Oct 2026:** §§9–11 present.
- [x] `P4-07` Drop in sections 12–16 (design system, innovation, architecture, accessibility, ethics) — **verified 28 Oct 2026:** §§12–16 present.
- [x] `P4-08` Drop in sections 17–19 (testing, references, appendix) — **verified 28 Oct 2026:** §§17–19 present. **All nineteen numbered sections exist** (`## 1.` … `## 19.`), so every drop-in landed.
- [x] `P4-09` Formatting pass: header on every page, page numbers, caption numbering, Harvard references, no orphan headings — **verified 28 Oct 2026:** the header and `Page X of Y` footer are applied to **every** page by `tools/pdf-headers.js` (verified with `pdftotext` on pages 2 and 100 of the export), **27** `Table` captions are numbered, every figure is enumerated in the List of figures, and §18 is the Harvard reference list. *Limit:* **"no orphan headings" is a visual property and is not machine-checked** — nothing here claims otherwise.
- [x] `P4-10` **Cross-check every rubric bullet** in [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) → tick the evidence column — **verified 28 Oct 2026:** doc 08 *is* that cross-check, and it was **reconciled the same day** — 19 of its 23 Gate 1 / Gate 2 boxes now carry a dated verdict **and the artefact each was checked against**; the 4 that stay open are named there with their gaps.
- [ ] `P4-11` Two members read the whole document cold and flag anything unclear or unjustified — **reconciled 28 Oct 2026: one second reader, and only for the mockups.** The content audit records M1 as a genuine second reader for **70 of the 106** wireframes (he drew the other 36) and **names the 36 that still need somebody else**. **No record exists of a member reading the whole document cold.** The box is half-met; the 36 named frames are the concrete remainder.
- [x] `P4-12` Export to PDF; verify fonts embedded, images ≥150 dpi, file size sane, links live — **verified 28 Oct 2026:** the PDF is built (**26,269,669 bytes**, ≈25.1 MB), fonts are embedded by the browser at build time, the smallest exported figure is **1704 px** wide (clearing 150 dpi), and **36 external links** are live. The gate's `dd-figures` check re-verifies all of it on every run.
- [ ] `P4-13` **Submit by Wed 21 Oct, 23:55** (a day early, buffer against the portal failing) — **reconciled 28 Oct 2026: the deadline passed and the portal submission is still open.** The document deadline was **22 Oct 2026, 23:55**; the bundle is assembled, tracked and byte-compared by the gate, and both `design-doc-v1` and `prototype-v1` are tagged — **but the submission itself has not been recorded** (the gate's `p9-1819`). This is one of only three items keeping the submission gate red, and the only one that is not a document problem.
- [x] `P4-14` Tag the submission in git: `git tag design-doc-v1` and archive the source files — **verified 28 Oct 2026:** **both tags exist** — `design-doc-v1` and `prototype-v1` — and the sources are archived under `deliverables/`.

**Exit gate:** 🚩 PDF submitted 21 Oct · every rubric bullet has traceable evidence.

---

## 8. Phase 5, Design System & High-Fidelity Figma Prototype · W2–W5 · owner **M2**

**Goal:** the entire **Project Prototype (20 marks)**. Starts in W2 in parallel with low-fi, using the *same* frames, upgrade, never redraw.

- [ ] `P5-01` Build the **Figma component library**: buttons (5 variants), inputs, cards, chips, list rows, tab bar, nav bar, progress ring, flashcard, quiz option, stat tile, sheet/dialog, empty-state block, toast, skeleton
- [ ] `P5-02` Bind components to **variables** (colour, spacing, radius, type) so a theme change propagates instantly
- [ ] `P5-03` Apply the app icon + name header to all frames (identity requirement)
- [ ] `P5-04` Upgrade Group A + B to high fidelity (M1)
- [ ] `P5-05` Upgrade Group C (M1) and Groups D + E + F (M2)
- [ ] `P5-06` Upgrade Group G (M3) and Group H, the advanced feature (M2 + M3)
- [ ] `P5-07` Upgrade Groups I + K (M4), Group J (M2) and Group L (M3)
- [ ] `P5-08` Upgrade Group M, the cross-cutting states (M1), **these are the states the rubric explicitly asks for**
- [ ] `P5-09` Build **light and dark** variants of at least the 10 hero screens
- [ ] `P5-10` Build the **RTL Arabic** and **AX3 large-text** proof frames (`139`, `138`)
- [ ] `P5-11` Rename **every** frame to the `NN_ScreenName_FirstName_StudentID` rule, then audit with a script pass
- [ ] `P5-12` Set overflow behaviour: *Scroll* on long screens, *Device* on all
- [ ] `P5-13` Wire every link per the [doc 03 §6](03-SCREEN-INVENTORY.md) checklist (worth more marks than visual polish)
- [ ] `P5-14` Apply **Smart Animate** to ≥5 high-impact transitions
- [ ] `P5-15` Add a `0 · Cover & Legend` page: app name, logo, team, legend, prototype start instructions
- [ ] `P5-16` Record a 3-minute walkthrough of the main flows for the appendix

**Exit gate:** all P0 + P1 frames high-fidelity and linked · naming rule verified · recorded walkthrough.

---

## 9. Phase 6, iOS App Foundation (SwiftUI) · W2–W4 · owner **M3**

**Goal:** a real, buildable app. This is **Track C**, it never blocks Track A or B, but it must run for the demo.

- [ ] `P6-01` Create the Xcode 27 project: `StudyForge`, SwiftUI lifecycle, iOS 26.0 deployment target, Swift 6 language mode
- [ ] `P6-02` Add packages via SPM: `firebase-ios-sdk`, `FirebaseAILogic`, Tap Payments iOS SDK, `swift-collections`
- [ ] `P6-03` Repo layout inside the app: `App/`, `Features/<FeatureName>/`, `Core/`, `DesignSystem/`, `Resources/`
- [ ] `P6-04` Write `DesignSystem.swift`, colour tokens, type scale, spacing, radii, component modifiers
- [ ] `P6-05` Establish architecture: **MVVM + Repository + `@Observable`** view models, `async/await`, no singletons except injected services
- [ ] `P6-06` Build a lightweight DI container (`AppContainer`) so every service is protocol-backed and mockable
- [ ] `P6-07` Implement `RootView` + `RoleRouter` (role-driven tab bars: 5 tabs student, 4 tutor, 4 admin)
- [ ] `P6-08` Implement a reusable `LoadState` enum (`idle / loading / loaded / empty / failed`) and drive every screen from it
- [ ] `P6-09` Create **empty shells** for all 17 features so navigation is demonstrable from day one
- [ ] `P6-10` Set up `Configuration.xcconfig` for environments (dev / staging / prod) with no secrets in source
- [ ] `P6-11` Add `MockData` seeds so the whole app is browsable before Firebase is wired
- [ ] `P6-12` Enable strict concurrency checking; get to **zero warnings** before Phase 7

**Exit gate:** app builds and runs on the iOS 26.5 simulator · all 17 features navigable · zero warnings.

---

## 10. Phase 7, Firebase Backend, Security & AI Pipeline · W3–W5 · owner **M1**

**Goal:** the data layer, the security model and the 3-tier AI router. This is what makes the design document's architecture section *true* rather than aspirational.

- [x] `P7-01` Write `firestore.rules` with **role-based, server-enforced** access (see [doc 05](05-DATA-MODEL-SECURITY.md)), never trust the client — **verified 28 Oct 2026:** `backend/firestore.rules` is **538 lines** of role-based rules with helpers (`signedIn`, `uid`, `role()`, `isAdmin()`, `isTutor()`, `isSelf()`), the role read from the **custom claim** rather than client input, over a deny-by-default baseline.
- [x] `P7-02` Write `storage.rules`; lock material files to the owner plus explicit folder grants — **verified 28 Oct 2026:** `backend/storage.rules` (**89 lines**) scopes materials to the owner (`isSelf`), adds explicit **folder grants** (`isFolderMember`, `canEditFolder`), and caps content type (PDF/image) and size.
- [ ] `P7-03` Deploy rules via the Firebase CLI and test them with the **emulator suite** before touching production — **reconciled 28 Oct 2026: the tests exist and the live probe is committed, but no run is recorded and the deploy is not evidenced.** `backend/rules-tests/` holds `firestore.rules.test.mjs` (**24.5 KB** of negative tests), `storage.rules.test.mjs` (**9.2 KB**) and `live-rules-probe.py` — a probe that checks the **deployed** rules as a real client, because the emulator is a re-implementation. **Nothing records a passing run**, and [doc 13](13-PER-MEMBER-TASKS.md) assigns *"run the emulator rules tests and record the result"* to M3. The exit gate's *"rules tested in the emulator"* is therefore **claimed, not evidenced**.
- [x] `P7-04` Define all Firestore composite indexes and commit `firestore.indexes.json` — **verified 28 Oct 2026:** `backend/firestore.indexes.json` (**89 lines**) is committed and wired into `firebase.json`.
- [ ] `P7-05` Wire **Firebase Auth**: email/password, Sign in with Apple, email-verification + password-reset links, and custom claims (`role`, `plan`, `groupIds`) — **reconciled 28 Oct 2026: Auth is wired and `role`/`plan` are server-owned; `groupIds` is not.** `Core/Auth/` holds `AuthService`, `FirebaseAuthService`, `AuthStateStream`, `CustomClaims`, `UserSession` and `PasswordStrength`, and `CustomClaims` models all three claims. Server-side, `onUserCreate` sets `DEFAULT_CLAIMS = { role: 'student', plan: 'free' }`, so the role **cannot be client-chosen** — which is the point of the box. **But `groupIds` appears nowhere in `backend/functions/src/`**, so that claim is granted **out of band**. Half the box is met; the groupIds half is a manual step.
- [ ] `P7-06` Implement the **extraction pipeline**: client-side downscale → Vision OCR → chunking with page + offset metadata → Storage upload → Firestore metadata — **reconciled 28 Oct 2026: the shipped extractor is PDFKit, not Vision OCR — and the code says so itself.** `Core/Materials/TextExtractor.swift` imports **PDFKit**, and its own header records the gap: *"…already designed (C03's source grid) and will need **Vision rather than PDFKit**; a caller that names PDFKit would have to change when they arrive."* So **scanned or photographed material is not supported** by the current pipeline — and the file names that limitation rather than hiding it.
- [x] `P7-07` Implement the `AIProvider` protocol and `OnDeviceProvider` using `FoundationModels` (`LanguageModelSession`, `@Generable` structs for cards and quiz questions) — **verified 28 Oct 2026:** `Core/AI/AIProvider.swift` defines the protocol, `OnDeviceProvider.swift` conforms to it through **FoundationModels** (`LanguageModelSession`), and `AIGenerationModels.swift` carries the `@Generable` shapes.
- [ ] `P7-08` Implement `FirebaseAIProvider` using Firebase AI Logic with **structured JSON output** and streaming — **reconciled 28 Oct 2026: there is no cloud provider, and the tier is served by a mock.** Only **two** types conform to `AIProvider` — `OnDeviceProvider` and **`MockProvider`** — and `AIRouter` resolves the cloud tier as `MockProvider(tier: .firebaseAI, latency: .milliseconds(400))`: **a simulated 400 ms latency standing in for Gemini.** The Xcode project links **only `FirebaseAuth`, `FirebaseFirestore` and `FirebaseFunctions`** — no Firebase AI Logic — and **no Cloud Function proxies AI** (`onUserCreate`, `createCharge`, `tapWebhook`, `rollupDailyMetrics`). **The code is honest about it:** `AITier.swift:114` carries an open `TODO(M2 · F15)` and states *"Until it exists, `.notImplemented` is the honest state."* **The stale claim is in the internal architecture doc, not in the graded document — and that distinction matters.** [doc 04](04-TECH-ARCHITECTURE-COST.md) says *"`FirebaseAIProvider` replaces it in S1"* and its file tree lists the file as though it existed: **that is now false**, and it is a doc-versus-code contradiction of exactly the kind §9 exists to catch. **The Design Document is defensible as written** — §14.3 is a *design* table (*"Tier | Engine | Cost | Use"*), and innovation #1's Evidence column cites *"`FoundationModels` behind an `AIProvider` protocol with swappable conformers"*, i.e. **the protocol and the on-device tier, not a working cloud tier**. **The honest fix is one line, not a rewrite:** caveat T1 as *planned* in §14.3, or correct doc 04 and its file tree. **A marker asking "show me the cloud tier" still finds a mock**, because the prototype is what has to answer that — and this is M2's lane and M2's open marker.
- [x] `P7-09` Implement the **router**: choose a tier per task by capability, availability and remaining budget; fall back gracefully — **verified 28 Oct 2026:** `AIRouter.swift`, `AIRoutingPolicy.swift` and `AITier.swift` choose a tier by capability, availability and remaining budget, and fall back with a **named reason** (`.policyOfflineOnly`, `.notImplemented`) instead of failing silently.
- [x] `P7-10` Implement the **AI cost governor**: per-user daily counter, SHA-256 content-hash cache in Firestore, friendly quota state — **verified 28 Oct 2026:** `AICostGovernor.swift` holds the per-user daily counter and exposes `hasBudget` / `remaining` / `resetsAt`, and `Core/ContentHash.swift` provides the SHA-256 hash that lets a repeat skip both the router and the quota.
- [ ] `P7-11` Store prompt templates in Firestore so they can change **without an app release** — **reconciled 28 Oct 2026: still hardcoded, TODO open.** `Core/AI/PromptTemplates.swift` says in its own header *"In S3 these strings move to Firestore so prompt quality can improve without an [app release]"* and carries an open `TODO(M2 · F15)`. A prompt change still needs a release, which is the box's entire purpose.
- [x] `P7-12` Implement the **RAG index**: `NLEmbedding` vectors in SwiftData, cosine-similarity top-k retrieval — **verified 28 Oct 2026:** `Core/Coach/` holds `Embedding.swift`, `LocalRetrievalService.swift`, `RetrievalService.swift` and `TextChunk.swift` — `NLEmbedding` vectors with cosine-similarity top-k retrieval.
- [x] `P7-13` Implement **provenance**: persist chunk IDs against every generated artefact, render citation chips — **verified 28 Oct 2026:** `TextChunk.swift` and `Citation.swift` carry the chunk IDs, `PageMarker.swift` ties them to page + offset, and the citation chips render (Design Document §13's Figure 13.1 is captured from the two screens that carry them).
- [x] `P7-14` Implement **SM-2 scheduling** for flashcards with efficient due-date queries — **verified 28 Oct 2026:** `Core/Scheduling/SpacedRepetition.swift` implements SM-2, and the deck list orders by what is actually due.
- [ ] `P7-15` Implement **offline-first sync**: Firestore persistence, write queue, SwiftData cache, offline banner — **reconciled 28 Oct 2026: the banner is real, the persistence is not.** `DesignSystem/Components/SFOfflineBanner.swift` exists and is used. But `Core/Config/FirebaseBootstrap.swift:149` sets **`MemoryCacheSettings()`** — the Firestore cache is **memory-only**, so it does not survive a relaunch — and a search finds **no write queue** (`writeQueue` / `PendingWrite` / `SyncQueue`: **0 hits**). The app's offline story is **file-backed stores** (`FileDeckStore`, `FileGroupStore`, `FileChatModerationStore`, …) rather than the Firestore persistence plus write queue this box specifies.
- [ ] `P7-16` Implement **FCM**: token registration, topic subscriptions, deep-link routing, local scheduled reminders — **reconciled 28 Oct 2026: FCM is not implemented at all.** `FirebaseMessaging`, `Messaging` and `registerForRemoteNotifications` return **0 files** across `ios/` and `backend/functions/src`, and the SDK list has no Messaging product. **Local scheduled reminders do exist** (`NotificationViewModel`), so F14 works — but token registration, topic subscriptions and deep-link routing do not.
- [ ] `P7-17` Enable **App Check** so AI keys and Firestore can't be abused by a repackaged build — **reconciled 28 Oct 2026: not implemented.** `AppCheck` and `FirebaseAppCheck` return **0 files**, and no App Check product is linked. The box's stated purpose is unaddressed — and it interacts with `P7-08`, because **there is no cloud AI key to protect yet**.
- [ ] `P7-18` Implement **audit-log** writes for every admin action — **reconciled 28 Oct 2026: the screen's copy exists, the writes do not.** `L10n.swift` carries the admin audit-log keys (`admin.auditLog.title`, `.searchPlaceholder`, `.actors`, `.actions`), but there is **no audit-log store or write path** in the app or in the functions. The K08 surface has strings and no data.
- [ ] `P7-19` Seed demo accounts (student / tutor / group / admin) plus a realistic demo course with materials — **reconciled 28 Oct 2026: the four accounts exist, the seeded course does not.** `Features/Auth/DemoAccounts.swift` defines `DemoAccounts.all` with a **role and a plan per account** and a single shared password, and `DeveloperAccountSwitcherTests` **fails** unless every subscription tier is covered by some account — the coverage guard working as intended. **The "realistic demo course with materials" is not seeded**, and `docs/TODOLIST.md` §7 still carries *"Seed demo data and four verified accounts"* as open.
- [ ] `P7-20` Set a **budget alert and spend cap** in Google Cloud; confirm the project is on Blaze with alerts on, or stays on Spark — **reconciled 28 Oct 2026: the project stayed on Spark, so there is nothing to cap — but the decision is not recorded as one.** [doc 09](09-RISKS-OPEN-QUESTIONS.md) **R21** records `billingEnabled: false` verified against the API, and R5/R6 keep the server surface deliberately tiny. So **no budget alert or spend cap was set**, and `docs/TODOLIST.md` §3 still lists *"Blaze plan, budget alert, spend cap"* among the open deploy prerequisites. **The box itself allows "or stays on Spark"** — in which case this should be **ticked with that decision written down**, rather than left looking like an omission.

**Exit gate:** rules tested in the emulator · AI router live on all three tiers · offline mode demonstrated in aeroplane mode.

---

## 11. Phase 8, Payments, Accessibility, Offline & Polish · W5 · owner **M3**

**Goal:** the differentiators. These are the items that separate a competent submission from a memorable one, and they are all cheap to do *if* they are planned rather than bolted on.

- [ ] `P8-01` Implement `PaymentGateway` protocol; `TapPaymentsGateway` (card + BenefitPay + Apple Pay) and `StoreKitGateway` stubs
- [ ] `P8-02` Wire the **Tap sandbox**: public key `pk_test_…`, card-entry sheet, redirect handling, return URL scheme
- [ ] `P8-03` Implement the Cloud Function that verifies the Tap charge **server-side** and writes the entitlement, never trust a client "success" callback
- [ ] `P8-04` Handle every payment failure path: declined, 3-D Secure timeout, network drop, duplicate charge guard (idempotency key)
- [ ] `P8-05` Implement VAT-inclusive **BHD** pricing display (10% Bahrain VAT), show the breakdown
- [ ] `P8-06` Write the compliance note: Apple Guideline 3.1.1 vs external gateway, and the StoreKit migration plan
- [ ] `P8-07` Full **RTL Arabic** pass: mirrored layouts, `layoutDirection`, Arabic number formatting, RTL-safe icons
- [ ] `P8-08` **Accessibility audit**: VoiceOver labels on every control, Dynamic Type to AX5, ≥44 pt touch targets, contrast ≥4.5:1, reduce-motion support
- [ ] `P8-09` **Offline drill**: aeroplane mode, browse, review cards, take a cached quiz; verify the sync queue drains correctly
- [ ] `P8-10` **Empty / loading / error state sweep** across all screens (the rubric explicitly rewards these)
- [ ] `P8-11` Add **haptics** and micro-animations to key interactions (card flip, streak, correct answer)
- [ ] `P8-12` Run **Instruments**: verify no retain cycles, AI calls off the main thread, smooth 120 Hz scrolling
- [ ] `P8-13` Cold-start budget: under 2 s to interactive on the simulator

**Exit gate:** sandbox payment succeeds end-to-end · VoiceOver walkthrough passes · aeroplane-mode drill passes.

---

## 12. Phase 9, Prototype QA, Usability Test → 🚩 **GATE 2** · W5–W6 · owner **M4**

**Goal:** convert a finished prototype into a *verified* one. The brief says *"It is encouraged that your prototype is tested thoroughly by team members and real users"*, doing it and **documenting it** is worth real marks.

- [ ] `P9-01` QA every feature against its acceptance criteria from `P2-08`, with the assigned **tester ≠ developer**
- [ ] `P9-02` Maintain a bug board (Notion/GitHub Issues); triage P0 → fix, P1 → fix, P2 → log as known limitation
- [ ] `P9-03` **Usability test with 5 real users** (the brief's own recommendation): 4 scripted tasks, think-aloud protocol, note errors/time/critical incidents
- [ ] `P9-04` Score with **SUS** (System Usability Scale) and report the number in the document
- [ ] `P9-05` Turn findings into a fix list; apply fixes; re-test the top 3 issues
- [ ] `P9-06` **Frame-naming audit**, every frame matches `NN_ScreenName_FirstName_StudentID` exactly
- [ ] `P9-07` **Link audit**, present the prototype and click *every* hotspot; zero dead ends
- [ ] `P9-08` Overflow + device-frame audit across all frames
- [ ] `P9-09` Content audit, no lorem ipsum, no "Screen 1", realistic names and grades throughout
- [ ] `P9-10` Consistency audit, colours, type scale, spacing, radii, icon style all match the design system
- [ ] `P9-11` Accessibility audit on the prototype, contrast, touch targets, text sizes
- [ ] `P9-12` Verify **dark mode** and **RTL Arabic** frames render correctly
- [ ] `P9-13` Freeze the prototype; any further change requires a changelog entry
- [ ] `P9-14` **Export the `.fig` file** — ✅ **done:** 8 Oct 2026, **re-exported 24 Oct 2026** (1,830,424 bytes, `exported_at 2026-10-23T23:01:26Z`), so the file on disk matches the shared link
- [ ] `P9-15` Set Figma share permissions to *Anyone with the link can view* and verify in a private browser window
- [ ] `P9-16` Create `deliverables/prototype/figma-link.txt` containing the shared URL + access notes
- [ ] `P9-17` Assemble the package: **`.fig` file AND the link text document** (the rubric requires both)
- [ ] `P9-18` **Submit by Wed 11 Nov, 23:55**, one day early
- [ ] `P9-19` `git tag prototype-v1` and archive everything

**Exit gate:** 🚩 `.fig` + link submitted 11 Nov · usability test documented with SUS score.

---

## 13. Phase 10, Demo Readiness & Viva Preparation · W6+ · owner **all**

**Goal:** the brief requires that *"each student should be able to present and explain any part of the app"*. Practise this deliberately.

- [ ] `P10-01` Write the 5-minute demo script: problem → solution → live flow → architecture → innovation
- [ ] `P10-02` Seed demo data and 4 demo accounts; verify on a **real device** (not just the simulator)
- [ ] `P10-03` Each member presents **a feature they did not build**, rotate until everyone can
- [ ] `P10-04` Rehearse twice, timed; cut anything that runs long
- [ ] `P10-05` Record a **backup screen capture** in case live demo fails (network, projector, device)
- [ ] `P10-06` Prepare answers to the obvious questions, see the list in [doc 09 §5](09-RISKS-OPEN-QUESTIONS.md)
- [ ] `P10-07` Charge every device; test AirPlay/projector; bring cables and a phone hotspot
- [ ] `P10-08` Run a 15-minute retrospective and archive lessons learned

---

## 14. If we fall behind, the cut-line protocol (corrected)

Ranked order of sacrifice. Cut from the **bottom**, record the decision, and never quietly drop anything.

| Priority | Item | Component weight | Cut from here |
|---|---|---|---|
| 1 | **Tier A app features demo-solid on a real device** | **60% · must pass** | ⛔ **Never** |
| 2 | **Golden path rehearsed + backup recording** | 60% · must pass | ⛔ **Never** |
| 3 | **Individual sprint contribution evidence** | 10% · individual | ⛔ **Never** |
| 4 | **Design Document's five rubric areas** | 10% · fixed deadline | ⛔ **Never** |
| 5 | All 17 features linked in Figma + naming compliance | 10% | ⛔ Never |
| 6 | P1 state frames (51 of 141) | 10% | **First** |
| 7 | Tier B feature polish (function stays, shine goes) | 60% | **Second** |
| 8 | Figma visual polish, dark-mode variants, hero screens | 10% | **Third** |
| 9 | Tier C stretch (voice quiz, PencilKit annotation) | - | **Fourth** |
| 10 | Documentation beyond what the rubric asks for | - | **Fifth** |

> **The one rule:** the app (**60%, must pass**) outranks everything. If a day has to be sacrificed, it is sacrificed from Figma, **never** from the app, the demo rehearsal, or the sprint evidence.
>
> This is the **exact opposite** of the earlier draft of this plan, which made Figma the critical path. The correction is deliberate and worth stating to the marker if asked: with the app at 60% and gating the course, optimising for the 10% Figma artefact would have been the wrong call.

---

## 15. Cadence checklists

**Every Monday (20 min stand-up):** previous gate status · this week's frames per person · blockers · anything slipping into the cut-line table.

**Every Sunday (45 min review):** run the week's gate check · update the tickboxes in this document · update [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) status · commit and push everything.

**Before every gate:** re-read [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) top to bottom. If a row has no evidence, that is a lost mark, and it is fixable today.





