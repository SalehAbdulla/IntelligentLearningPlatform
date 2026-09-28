# 01 — Roadmap, Phases & Todolist

> **StudyForge** · the guide and roadmap for building the whole project.
> Deadline 1: **Thu 22 Oct 2026, 23:55** — Design Document · Deadline 2: **Thu 12 Nov 2026, 23:55** — Prototype.

---

## 1. The calendar

Today is **Mon 28 Sep 2026**. That gives **3.5 weeks** to the Design Document and **6.5 weeks** to the Prototype. Weeks run Monday → Sunday.

| Week | Dates | Primary focus | Gate at end of week |
|---|---|---|---|
| **W0** | Mon 28 Sep – Sun 4 Oct | Setup, identity, research start, tutor interview booked | Identity frozen |
| **W1** | Mon 5 Oct – Sun 11 Oct | Research, feature list, ownership, flows | **Feature list signed off** |
| **W2** | Mon 12 Oct – Sun 18 Oct | Low-fi mockups (bulk), design system, hi-fi starts | 60% of P0 frames drawn |
| **W3** | Mon 19 Oct – Sun 25 Oct | Document assembly → **SUBMIT 22 Oct** | 🚩 **Design Document submitted** |
| **W4** | Mon 26 Oct – Sun 1 Nov | Hi-fi prototype continues, app foundation merged | All P0 frames hi-fi |
| **W5** | Mon 2 Nov – Sun 8 Nov | Wiring, states, usability test, payments, polish | **Prototype feature-complete** |
| **W6** | Mon 9 Nov – Sun 15 Nov | QA, `.fig` export → **SUBMIT 12 Nov** | 🚩 **Prototype submitted** |
| **W7+** | Mon 16 Nov onward | Demo & viva preparation | Demo rehearsed |

**Weekly rhythm (non-negotiable):** Monday 20-minute stand-up → midweek async check-in → Sunday 45-minute review against the gate. Every meeting minuted in `research/meeting-notes/`.

---

## 2. Phase overview

| Phase | Name | Window | Owner | Exit gate |
|---|---|---|---|---|
| **0** | Setup & Project Identity | W0 (28 Sep – 4 Oct) | M1 | Name, logo, palette, team roster, tooling frozen |
| **1** | Research & Discovery | W0–W1 (30 Sep – 8 Oct) | M4 | Evidence dossier + tutor interview complete |
| **2** | Feature Definition & Ownership | W1 (5 – 9 Oct) | M3 | Master feature table signed off by all 5 |
| **3** | IA, Flows & Low-Fidelity Mockups | W1–W2 (7 – 16 Oct) | M2 | 89 P0 frames drawn; every flow diagrammed |
| **4** | Design Document Assembly → **GATE 1** | W2–W3 (14 – 21 Oct) | M1 | 🚩 PDF submitted 22 Oct with 24 h buffer |
| **5** | Design System & High-Fidelity Prototype | W2–W5 (12 Oct – 8 Nov) | M2 | All P0+P1 frames hi-fi and linked |
| **6** | iOS App Foundation (SwiftUI) | W2–W4 (12 Oct – 1 Nov) | M3 | App runs, auth + navigation + empty shells of all 15 features |
| **7** | Firebase Backend, Security & AI Pipeline | W3–W5 (19 Oct – 8 Nov) | M1 | Rules deployed, AI router live on all three tiers |
| **8** | Payments, Accessibility, Offline & Polish | W5 (2 – 8 Nov) | M5 | Sandbox payment succeeds; RTL + AX3 verified |
| **9** | Prototype QA, Usability Test → **GATE 2** | W5–W6 (2 – 11 Nov) | M4 | 🚩 `.fig` + URL submitted 12 Nov |
| **10** | Demo Readiness & Viva Preparation | W6+ (9 – 15 Nov+) | all | Every member can present any feature |

**Critical path:** Phase 3 (mockups) → Phase 5 (hi-fi) → Phase 9 (wiring/QA) → Gate 2. Phases 6–8 (the working app) are **parallel and non-blocking** — they must never delay the Figma track.

---

## 3. Phase 0 — Setup & Project Identity · W0 · owner **M1**

**Goal:** remove every unknown that could block work later. When this phase ends, no one should have to ask "what's the app called?" or "what's the bundle ID?".

- [ ] `P0-01` Create repo structure (`docs/`, `deliverables/`, `ios/`, `firebase/`, `research/`)
- [ ] `P0-02` Add `.gitignore` excluding `GoogleService-Info.plist`, `*.xcuserdata`, secrets, `.env` — **verify no key is ever committed**
- [x] `P0-03` Verify toolchain: Xcode 27.0 · iOS 26.5 + 27.0 simulators · Swift 6.4 · Figma.app · Node 24.15 ✅
- [ ] `P0-04` Create Firebase project `studyforge-it8108` on the **Spark (no-cost)** plan
- [ ] `P0-05` Register iOS app, bundle ID `com.studyforge.app`, download `GoogleService-Info.plist`
- [ ] `P0-06` Enable: Auth (Email/Password + Sign in with Apple), Firestore, Storage (**bucket region `us-central1`** — required to stay inside the free tier), FCM, Analytics, Crashlytics, App Check
- [ ] `P0-07` Install Firebase CLI (`npm i -g firebase-tools`), log in, run `firebase init`
- [ ] `P0-08` **Freeze the app name:** StudyForge (and confirm no trademark clash)
- [ ] `P0-09` Design 3 logo concepts → team vote → export `@1x/@2x/@3x` PNG + SVG + 1024×1024 app icon
- [ ] `P0-10` Freeze palette, type scale and spacing grid → [doc 06](06-DESIGN-SYSTEM.md)
- [ ] `P0-11` **Fill the real team names + student IDs** into [doc 02 §2](02-FEATURE-LIST-OWNERSHIP.md) ⚠️ *blocks Figma frame naming*
- [ ] `P0-12` Create the Figma file with the **10 pages** from [doc 03 §1](03-SCREEN-INVENTORY.md)
- [ ] `P0-13` Publish Figma **styles** (colour, text, effect) + skeleton component library
- [ ] `P0-14` Book the **tutor interview** (target: early W1) and circulate the question list
- [ ] `P0-15` Install the Cline agent skills in [doc 07](07-CLINE-SKILLS-AND-TOOLING.md)
- [ ] `P0-16` Create the shared drive: `deliverables/`, `research/meeting-notes/`, `research/interviews/`
- [ ] `P0-17` Register a **Tap Payments sandbox** account and request test keys (`pk_test_…`)
- [ ] `P0-18` Confirm all 5 members have Xcode installed and can build the empty project

**Exit gate:** identity frozen · roster filled · Firebase project live · Figma file ready · interview booked.

---

## 4. Phase 1 — Research & Discovery · W0–W1 · owner **M4**

**Goal:** produce the evidence base that earns the whole **Background Research (4 marks)** block. Vague claims score nothing; cited statistics and real interview quotes score full marks.

- [ ] `P1-01` Desk research: **8+ credible sources** on retrieval practice, spaced repetition and the testing effect (peer-reviewed preferred), each with a Harvard reference
- [ ] `P1-02` Desk research: digital-learning adoption in Bahrain / the GCC (cite **Resolution No. 43** on digital payments as a local-context source)
- [ ] `P1-03` Competitor teardown: Quizlet · Anki · Google NotebookLM · Notion · ChatGPT · Studocu — with **screenshots** and the gap table from [doc 00 §8](00-MASTER-PLAN.md)
- [ ] `P1-04` SDG mapping evidence for SDG 4 / 9 / 10 with a source per claim
- [ ] `P1-05` **Interview 5 real students** (semi-structured, 10 min each); capture verbatim quotes and photos of their current "study chaos"
- [ ] `P1-06` **Run the tutor interview** — ask the questions below, record the answers verbatim, note what changed
- [ ] `P1-07` Obtain **written approval for the F15 advanced feature** and record it in [doc 02 §5](02-FEATURE-LIST-OWNERSHIP.md)
- [ ] `P1-08` Write the problem statement: who is affected, why it matters, scale
- [ ] `P1-09` Write app purpose, goals and intended impact + **measurable** success metrics
- [ ] `P1-10` Compile everything into `research/dossier.md` with a Harvard reference list

**Tutor interview question bank** (the rubric requires *"questions asked AND summary of responses"*):

1. Which part of the brief do you consider the highest-risk for our team — AI accuracy, scope, or the payments integration?
2. What would make you say this project earned full Innovation marks?
3. Do you approve our proposed advanced feature (F15: RAG-based AI Study Companion with adaptive study paths)? Is that "advanced" enough, or should we stretch further?
4. How much emphasis should the design document place on engineering architecture versus visual design?
5. For the Figma prototype, do you expect every error/empty state, or only the main flows?
6. Is there a preferred balance between feature breadth (15 features) and depth (fewer, richer features)?
7. Any specific references or frameworks you'd like to see applied (e.g. Nielsen's heuristics, WCAG 2.2)?
8. What causes groups to lose marks in your experience?
9. Is a working SwiftUI app alongside the Figma prototype viewed positively, neutrally, or as scope creep?
10. Any constraints we should respect regarding student data collection in our user testing?

**Exit gate:** dossier written · interview recorded · advanced feature approved in writing.

---

## 5. Phase 2 — Feature Definition & Ownership · W1 · owner **M3**

**Goal:** lock the feature list before any pixel is drawn. Renumbering features after mockups exist is the single most expensive mistake available to us.

- [ ] `P2-01` Gap analysis vs the brief's 10 named features → arrive at 15 (see [doc 02 §4](02-FEATURE-LIST-OWNERSHIP.md))
- [ ] `P2-02` Complete the master table columns: name · role · main task · flow · developer · tester
- [ ] `P2-03` Assign developers so **every member owns ≥2 features** and effort is visibly balanced
- [ ] `P2-04` Assign testers using the rotation rule (nobody tests their own work)
- [ ] `P2-05` Freeze the F15 advanced-feature spec and the `RetrievalService` / `CoachPlanningService` contracts
- [ ] `P2-06` **All 5 members review and sign off** the feature table (record sign-off date)
- [ ] `P2-07` Map each feature → its screen IDs and its Firestore collections (traceability matrix)
- [ ] `P2-08` Write 2–3 acceptance criteria per feature (these become the test cases in Phase 9)

**Exit gate:** feature table signed off by all 5 · traceability matrix complete.

---

## 6. Phase 3 — IA, Flows & Low-Fidelity Mockups · W1–W2 · owner **M2**

**Goal:** the **8-mark Mockups block**. This is the largest single rubric area, so it gets the most schedule time and the most people.

- [ ] `P3-01` Build the **information architecture tree** (tab bars, modal flows, depth limits) per [doc 03 §5](03-SCREEN-INVENTORY.md)
- [ ] `P3-02` Draw **one flow diagram per feature** (15 diagrams) — start/end, decisions, error branches
- [ ] `P3-03` Draw the **global navigation map** on one page
- [ ] `P3-04` Each member draws their **P0 frames in low fidelity** (boxes, labels, no styling) — 89 frames total
- [ ] `P3-05` For **every** screen write the three rubric-required items: description · purpose/layout · labelled UI elements *with their function*
- [ ] `P3-06` Peer-review pass: each member checks another member's frames against the doc 03 inventory (coverage gaps are the #1 mark-loser)
- [ ] `P3-07` Cover the **required state set**: loading · empty · error · success · offline · permission-denied
- [ ] `P3-08` Ensure **app name + logo appear** in mockups (project identity rubric requirement)
- [ ] `P3-09` Assemble frames into the document order (grouped by feature, with flow diagrams preceding each group)
- [ ] `P3-10` Write the low-fi figure captions (`Figure 12 — F04 flashcard review, front state`)
- [ ] `P3-11` Completeness audit against [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) — every rubric bullet ticked
- [ ] `P3-12` Freeze low-fi: no new screens after this point without a change-log entry

**Exit gate:** 89 P0 frames drawn and described · 15 flow diagrams · completeness audit passed.

---

## 7. Phase 4 — Design Document Assembly → 🚩 **GATE 1** · W2–W3 · owner **M1**

**Goal:** one PDF, structurally identical to the 19-section plan in [doc 00 §11](00-MASTER-PLAN.md), submitted with a **24-hour buffer**.

- [ ] `P4-01` Build the Word/Pages master file with the heading style ladder **first** (formatting must be systemic, not per-section)
- [ ] `P4-02` Create the cover page: app name, logo, tagline, team table with IDs, module, tutors, date
- [ ] `P4-03` Auto-generate table of contents, figure list and table list (never type these by hand)
- [ ] `P4-04` Drop in sections 1–6 (research, interview, competitive analysis, purpose, personas)
- [ ] `P4-05` Drop in section 7–8 (feature list table + advanced feature spec)
- [ ] `P4-06` Drop in sections 9–11 (flows, low-fi mockups, navigation map)
- [ ] `P4-07` Drop in sections 12–16 (design system, innovation, architecture, accessibility, ethics)
- [ ] `P4-08` Drop in sections 17–19 (testing, references, appendix)
- [ ] `P4-09` Formatting pass: header on every page, page numbers, caption numbering, Harvard references, no orphan headings
- [ ] `P4-10` **Cross-check every rubric bullet** in [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) → tick the evidence column
- [ ] `P4-11` Two members read the whole document cold and flag anything unclear or unjustified
- [ ] `P4-12` Export to PDF; verify fonts embedded, images ≥150 dpi, file size sane, links live
- [ ] `P4-13` **Submit by Wed 21 Oct, 23:55** (a day early — buffer against the portal failing)
- [ ] `P4-14` Tag the submission in git: `git tag design-doc-v1` and archive the source files

**Exit gate:** 🚩 PDF submitted 21 Oct · every rubric bullet has traceable evidence.

---

## 8. Phase 5 — Design System & High-Fidelity Figma Prototype · W2–W5 · owner **M2**

**Goal:** the entire **Project Prototype (20 marks)**. Starts in W2 in parallel with low-fi, using the *same* frames — upgrade, never redraw.

- [ ] `P5-01` Build the **Figma component library**: buttons (5 variants), inputs, cards, chips, list rows, tab bar, nav bar, progress ring, flashcard, quiz option, stat tile, sheet/dialog, empty-state block, toast, skeleton
- [ ] `P5-02` Bind components to **variables** (colour, spacing, radius, type) so a theme change propagates instantly
- [ ] `P5-03` Apply the app icon + name header to all frames (identity requirement)
- [ ] `P5-04` Upgrade Group A + B to high fidelity (M1)
- [ ] `P5-05` Upgrade Group C (M1) and Groups D + E + F (M2)
- [ ] `P5-06` Upgrade Group G (M3) and Group H, the advanced feature (M2 + M3)
- [ ] `P5-07` Upgrade Group I (M4) and Groups J + K + L (M5)
- [ ] `P5-08` Upgrade Group M, the cross-cutting states (M1) — **these are the states the rubric explicitly asks for**
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

## 9. Phase 6 — iOS App Foundation (SwiftUI) · W2–W4 · owner **M3**

**Goal:** a real, buildable app. This is **Track C** — it never blocks Track A or B, but it must run for the demo.

- [ ] `P6-01` Create the Xcode 27 project: `StudyForge`, SwiftUI lifecycle, iOS 26.0 deployment target, Swift 6 language mode
- [ ] `P6-02` Add packages via SPM: `firebase-ios-sdk`, `FirebaseAILogic`, Tap Payments iOS SDK, `swift-collections`
- [ ] `P6-03` Repo layout inside the app: `App/`, `Features/<FeatureName>/`, `Core/`, `DesignSystem/`, `Resources/`
- [ ] `P6-04` Write `DesignSystem.swift` — colour tokens, type scale, spacing, radii, component modifiers
- [ ] `P6-05` Establish architecture: **MVVM + Repository + `@Observable`** view models, `async/await`, no singletons except injected services
- [ ] `P6-06` Build a lightweight DI container (`AppContainer`) so every service is protocol-backed and mockable
- [ ] `P6-07` Implement `RootView` + `RoleRouter` (role-driven tab bars: 5 tabs student, 4 tutor, 4 admin)
- [ ] `P6-08` Implement a reusable `LoadState` enum (`idle / loading / loaded / empty / failed`) and drive every screen from it
- [ ] `P6-09` Create **empty shells** for all 15 features so navigation is demonstrable from day one
- [ ] `P6-10` Set up `Configuration.xcconfig` for environments (dev / staging / prod) with no secrets in source
- [ ] `P6-11` Add `MockData` seeds so the whole app is browsable before Firebase is wired
- [ ] `P6-12` Enable strict concurrency checking; get to **zero warnings** before Phase 7

**Exit gate:** app builds and runs on the iOS 26.5 simulator · all 15 features navigable · zero warnings.

---

## 10. Phase 7 — Firebase Backend, Security & AI Pipeline · W3–W5 · owner **M1**

**Goal:** the data layer, the security model and the 3-tier AI router. This is what makes the design document's architecture section *true* rather than aspirational.

- [ ] `P7-01` Write `firestore.rules` with **role-based, server-enforced** access (see [doc 05](05-DATA-MODEL-SECURITY.md)) — never trust the client
- [ ] `P7-02` Write `storage.rules`; lock material files to the owner plus explicit folder grants
- [ ] `P7-03` Deploy rules via the Firebase CLI and test them with the **emulator suite** before touching production
- [ ] `P7-04` Define all Firestore composite indexes and commit `firestore.indexes.json`
- [ ] `P7-05` Wire **Firebase Auth**: email/password, Sign in with Apple, OTP, and custom claims (`role`, `plan`, `groupIds`)
- [ ] `P7-06` Implement the **extraction pipeline**: client-side downscale → Vision OCR → chunking with page + offset metadata → Storage upload → Firestore metadata
- [ ] `P7-07` Implement the `AIProvider` protocol and `OnDeviceProvider` using `FoundationModels` (`LanguageModelSession`, `@Generable` structs for cards and quiz questions)
- [ ] `P7-08` Implement `FirebaseAIProvider` using Firebase AI Logic with **structured JSON output** and streaming
- [ ] `P7-09` Implement the **router**: choose a tier per task by capability, availability and remaining budget; fall back gracefully
- [ ] `P7-10` Implement the **AI cost governor**: per-user daily counter, SHA-256 content-hash cache in Firestore, friendly quota state
- [ ] `P7-11` Store prompt templates in Firestore so they can change **without an app release**
- [ ] `P7-12` Implement the **RAG index**: `NLEmbedding` vectors in SwiftData, cosine-similarity top-k retrieval
- [ ] `P7-13` Implement **provenance**: persist chunk IDs against every generated artefact, render citation chips
- [ ] `P7-14` Implement **SM-2 scheduling** for flashcards with efficient due-date queries
- [ ] `P7-15` Implement **offline-first sync**: Firestore persistence, write queue, SwiftData cache, offline banner
- [ ] `P7-16` Implement **FCM**: token registration, topic subscriptions, deep-link routing, local scheduled reminders
- [ ] `P7-17` Enable **App Check** so AI keys and Firestore can't be abused by a repackaged build
- [ ] `P7-18` Implement **audit-log** writes for every admin action
- [ ] `P7-19` Seed demo accounts (student / tutor / group / admin) plus a realistic demo course with materials
- [ ] `P7-20` Set a **budget alert and spend cap** in Google Cloud; confirm the project is on Blaze with alerts on, or stays on Spark

**Exit gate:** rules tested in the emulator · AI router live on all three tiers · offline mode demonstrated in aeroplane mode.

---

## 11. Phase 8 — Payments, Accessibility, Offline & Polish · W5 · owner **M5**

**Goal:** the differentiators. These are the items that separate a competent submission from a memorable one — and they are all cheap to do *if* they are planned rather than bolted on.

- [ ] `P8-01` Implement `PaymentGateway` protocol; `TapPaymentsGateway` (card + BenefitPay + Apple Pay) and `StoreKitGateway` stubs
- [ ] `P8-02` Wire the **Tap sandbox**: public key `pk_test_…`, card-entry sheet, redirect handling, return URL scheme
- [ ] `P8-03` Implement the Cloud Function that verifies the Tap charge **server-side** and writes the entitlement — never trust a client "success" callback
- [ ] `P8-04` Handle every payment failure path: declined, 3-D Secure timeout, network drop, duplicate charge guard (idempotency key)
- [ ] `P8-05` Implement VAT-inclusive **BHD** pricing display (10% Bahrain VAT) — show the breakdown
- [ ] `P8-06` Write the compliance note: Apple Guideline 3.1.1 vs external gateway, and the StoreKit migration plan
- [ ] `P8-07` Full **RTL Arabic** pass: mirrored layouts, `layoutDirection`, Arabic number formatting, RTL-safe icons
- [ ] `P8-08` **Accessibility audit**: VoiceOver labels on every control, Dynamic Type to AX5, ≥44 pt touch targets, contrast ≥4.5:1, reduce-motion support
- [ ] `P8-09` **Offline drill**: aeroplane mode — browse, review cards, take a cached quiz; verify the sync queue drains correctly
- [ ] `P8-10` **Empty / loading / error state sweep** across all screens (the rubric explicitly rewards these)
- [ ] `P8-11` Add **haptics** and micro-animations to key interactions (card flip, streak, correct answer)
- [ ] `P8-12` Run **Instruments**: verify no retain cycles, AI calls off the main thread, smooth 120 Hz scrolling
- [ ] `P8-13` Cold-start budget: under 2 s to interactive on the simulator

**Exit gate:** sandbox payment succeeds end-to-end · VoiceOver walkthrough passes · aeroplane-mode drill passes.

---

## 12. Phase 9 — Prototype QA, Usability Test → 🚩 **GATE 2** · W5–W6 · owner **M4**

**Goal:** convert a finished prototype into a *verified* one. The brief says *"It is encouraged that your prototype is tested thoroughly by team members and real users"* — doing it and **documenting it** is worth real marks.

- [ ] `P9-01` QA every feature against its acceptance criteria from `P2-08`, with the assigned **tester ≠ developer**
- [ ] `P9-02` Maintain a bug board (Notion/GitHub Issues); triage P0 → fix, P1 → fix, P2 → log as known limitation
- [ ] `P9-03` **Usability test with 5 real users** (the brief's own recommendation): 4 scripted tasks, think-aloud protocol, note errors/time/critical incidents
- [ ] `P9-04` Score with **SUS** (System Usability Scale) and report the number in the document
- [ ] `P9-05` Turn findings into a fix list; apply fixes; re-test the top 3 issues
- [ ] `P9-06` **Frame-naming audit** — every frame matches `NN_ScreenName_FirstName_StudentID` exactly
- [ ] `P9-07` **Link audit** — present the prototype and click *every* hotspot; zero dead ends
- [ ] `P9-08` Overflow + device-frame audit across all frames
- [ ] `P9-09` Content audit — no lorem ipsum, no "Screen 1", realistic names and grades throughout
- [ ] `P9-10` Consistency audit — colours, type scale, spacing, radii, icon style all match the design system
- [ ] `P9-11` Accessibility audit on the prototype — contrast, touch targets, text sizes
- [ ] `P9-12` Verify **dark mode** and **RTL Arabic** frames render correctly
- [ ] `P9-13` Freeze the prototype; any further change requires a changelog entry
- [ ] `P9-14` **Export the `.fig` file**
- [ ] `P9-15` Set Figma share permissions to *Anyone with the link can view* and verify in a private browser window
- [ ] `P9-16` Create `deliverables/prototype/figma-link.txt` containing the shared URL + access notes
- [ ] `P9-17` Assemble the package: **`.fig` file AND the link text document** (the rubric requires both)
- [ ] `P9-18` **Submit by Wed 11 Nov, 23:55** — one day early
- [ ] `P9-19` `git tag prototype-v1` and archive everything

**Exit gate:** 🚩 `.fig` + link submitted 11 Nov · usability test documented with SUS score.

---

## 13. Phase 10 — Demo Readiness & Viva Preparation · W6+ · owner **all**

**Goal:** the brief requires that *"each student should be able to present and explain any part of the app"*. Practise this deliberately.

- [ ] `P10-01` Write the 5-minute demo script: problem → solution → live flow → architecture → innovation
- [ ] `P10-02` Seed demo data and 4 demo accounts; verify on a **real device** (not just the simulator)
- [ ] `P10-03` Each member presents **a feature they did not build** — rotate until everyone can
- [ ] `P10-04` Rehearse twice, timed; cut anything that runs long
- [ ] `P10-05` Record a **backup screen capture** in case live demo fails (network, projector, device)
- [ ] `P10-06` Prepare answers to the obvious questions — see the list in [doc 09 §5](09-RISKS-OPEN-QUESTIONS.md)
- [ ] `P10-07` Charge every device; test AirPlay/projector; bring cables and a phone hotspot
- [ ] `P10-08` Run a 15-minute retrospective and archive lessons learned

---

## 14. If we fall behind — the cut-line protocol

Ranked order of sacrifice. Cut from the **bottom** only, and record the decision.

| Priority | Item | Never cut? |
|---|---|---|
| 1 | 89 P0 frames drawn, described and **linked** | ✅ Never |
| 2 | The Design Document's five rubric areas | ✅ Never |
| 3 | Frame naming compliance | ✅ Never |
| 4 | Error / empty / offline / success state screens | Strongly prefer not |
| 5 | P1 frames | Cut only in the final 48 h |
| 6 | Working app: payments sandbox | Convert to a documented "designed + partially implemented" |
| 7 | Working app: live group quiz | Convert to a recorded demo |
| 8 | Working app: voice quiz mode | Drop; document as roadmap |
| 9 | F15 advanced feature implementation | Keep the **design**; reduce the implementation |

> **The one rule:** the Figma prototype and the design document are the only graded artefacts. If time runs short, **Track A and Track B win every argument**.

---

## 15. Cadence checklists

**Every Monday (20 min stand-up):** previous gate status · this week's frames per person · blockers · anything slipping into the cut-line table.

**Every Sunday (45 min review):** run the week's gate check · update the tickboxes in this document · update [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) status · commit and push everything.

**Before every gate:** re-read [doc 08](08-RUBRIC-COVERAGE-MATRIX.md) top to bottom. If a row has no evidence, that is a lost mark, and it is fixable today.





