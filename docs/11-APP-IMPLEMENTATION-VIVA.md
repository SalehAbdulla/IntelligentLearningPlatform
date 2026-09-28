# 11 — iOS App Implementation & Demonstration

> **60% of the course · MUST PASS · assessed as a group through (a) the completed iOS application and (b) an in-person VIVA / demonstration.**
>
> **Failure here fails the course**, regardless of the other 40%. Every rule in this document exists because of that sentence.

---

## 1. What is being assessed

| Assessed through | What the marker is looking for |
|---|---|
| **The completed iOS application** | Does it actually work? Are all the designed features present and functional? Does it handle real data, real failure and real devices? |
| **The in-person VIVA / demonstration** | Can the team operate it live, and can **every member** explain and defend any part of it? |

**Two consequences that drive this whole document:**

1. **A beautiful design with a broken app scores nothing here.** The Figma prototype (10%) and the design document (10%) are separate and do not compensate.
2. **Individual comprehension is a group risk.** One member who cannot explain their feature damages a *group* mark on a *must-pass* component.

---

## 2. What "complete" means — the MVP definition

"Complete" is defined here so it can be verified rather than argued about. Features are tiered by demo risk.

### Tier A — demo-solid, non-negotiable (10 features)

These must work **flawlessly, twice in a row, on a real device, with real data.** They are the features the demo cannot proceed without.

| Feature | Why it is Tier A |
|---|---|
| **F01** Auth & role onboarding | Nothing else is reachable without it; also demonstrates the 4-role model |
| **F02** Material upload & library | It is the entry point of the brief's own "upload → generate" story |
| **F03** AI summary | The brief's headline capability |
| **F04** Flashcards + spaced repetition | Proves "active learning", not just summarisation |
| **F05** Quiz generation + analytics | Proves assessment and feeds the weakness radar |
| **F06** Study plan | The brief's "revision planning" |
| **F07** Progress tracking | Closes the loop and makes the dashboard demonstrable |
| **F08** Shared study folders | The brief's "sharing between students" |
| **F10** Resource bookmarking | Cheap to build, visibly useful, proves offline caching |
| **F14** Notifications | Shows real iOS platform integration (FCM + local) |

### Tier B — must function (5 features)

These must work end-to-end with realistic seeded data. Visual polish is optional; *function* is not.

| Feature | Requirement |
|---|---|
| **F09** Group revision spaces | Live group quiz must run across **two devices** at least once, recorded |
| **F11** Tutor content studio | Course creation, material publish, and the AI review queue must operate |
| **F12** Admin content management | Moderation queue and user role change must operate (can be on a seeded dataset) |
| **F13** Subscription & payments | Tap **sandbox** payment must succeed and entitlement must unlock a feature |
| **F15** AI Study Companion *(advanced)* | A grounded answer with a visible citation. Must degrade gracefully if on-device AI is unavailable |

### Tier C — stretch (only if sprints finish early)

Voice-quiz mode · full offline write-queue conflict resolution · full dark-mode coverage · PDF annotation with PencilKit · animated onboarding.

> **Cut-line rule:** Tier C is cut first, then Tier B polish. **Tier A is never cut.** If Tier A is at risk, Figma and design-document work stops — see [doc 01 §14](01-ROADMAP-PHASES-TODOLIST.md).

### 2.1 Definition of "demo-solid" (applies to every Tier A feature)

- [ ] The happy path completes on a **physical device**, twice in a row, with no crash and no dead end
- [ ] **Loading, empty, and error** states are visible and correct
- [ ] It works against the seeded demo account and realistic demo content
- [ ] The owner can explain every screen and every data write in it
- [ ] It survives **aeroplane mode** without hanging or crashing (graceful degradation)

---

## 3. Must-pass risk control

Because a single failed demo step is disproportionately expensive, we engineer around it.

| # | Control | Detail |
|---|---|---|
| 1 | **Feature freeze** | S5 start (**30 Nov**). After this, only bug fixes — no new features, no refactors |
| 2 | **Daily build health check** | Every morning: `main` builds clean, tests pass, app launches. A red build is the day's top priority |
| 3 | **Golden path test** | One scripted end-to-end run of the Tier A demo flow, executed at least **3× per week from S3**, logged with pass/fail |
| 4 | **Recorded backup** | A full screen capture of the working golden path, re-recorded after any change to those screens. Used if live hardware or network fails |
| 5 | **Real-device strategy** | Demoing on a **physical iPhone with Apple Intelligence enabled** (the on-device AI tier does not run in the Simulator). A second device is charged and ready |
| 6 | **Seeded demo data, sealed** | Demo accounts and content created in S2 and frozen; never rely on generating content live for the first time |
| 7 | **Network fallback** | Phone hotspot ready. The demo path is designed to survive no-network via on-device generation and cached content |
| 8 | **No first-time surprises** | Nothing goes in the demo that has not been run at least 3 times before, by the person presenting it |
| 9 | **External dependency containment** | Only F13 depends on a third party (Tap). If the gateway is unreachable, play the recorded sandbox run and explain the flow |
| 10 | **Rehearsal until boring** | Two full timed rehearsals in S5, with a deliberate failure injected in one |

> **The governing principle:** the demo is a *performance of something already proven*, not an experiment. Every risky discovery happens in a sprint, never on the day.

---

## 4. The demo script (5 minutes, timed)

Rehearsed to the second. The **money shot** is the core loop at 0:25–2:55 — that is where the brief's four pillars become visible in one continuous flow.

| Time | Step | On screen | Presenter |
|---|---|---|---|
| 0:00–0:25 | **Problem & promise** | One slide: the study-chaos problem, then the one-loop claim | M1 |
| 0:25–0:40 | **Sign in as a student** | Login → student dashboard with real seeded data | M1 |
| 0:40–1:15 | **Upload → extract** | Real PDF from Files → compress → on-device OCR → appears in library | M1 |
| 1:15–1:55 | **Generate a summary** | Length/style pickers → streaming generation → **tap a provenance chip** → source page shown | M2 |
| 1:55–2:25 | **Cards → review** | Generate 20 cards → review session → rate *Good* → next-due interval changes | M2 |
| 2:25–2:55 | **Quiz → weakness radar → replan** | Take a quiz → scorecard → weakness radar → **accept AI re-plan** and watch the calendar change | M3 |
| 2:55–3:25 | **Collaboration** | Second device joins the group space → live quiz → real-time leaderboard | M4 |
| 3:25–3:55 | **AI Coach (advanced feature)** | Ask a question grounded in the uploaded material → answer with citation → tap citation → source sheet | M2 + M3 |
| 3:55–4:20 | **Payments (sandbox)** | Paywall → plan → order summary in BHD → Tap card → success → a feature unlocks | M3 |
| 4:20–4:40 | **Tutor & admin view** | Tutor review queue approving AI content; admin KPI dashboard | M4 |
| 4:40–5:00 | **Architecture & cost** | One slide: 3-tier AI router, $0 cost model, 4 roles, security rules | M1 |

**Every step has a rehearsed fallback.** If it fails, the presenter says one line and moves on. Rehearsing the *failure* path matters as much as the happy path.

---

## 5. VIVA strategy

The brief requires: *"each student should be able to present and explain any part of the app."* The must-pass framing makes this existential.

### 5.1 The preparation method

| # | Method | When | Why it works |
|---|---|---|---|
| 1 | **Rotated feature presentation** — each member presents a feature they did **not** build | S3, S4, S5 reviews | Forces whole-app understanding instead of silo knowledge |
| 2 | **The "explain it" drill** — open a teammate's file and explain it from the code, unprompted | Weekly, 15 min | The closest thing to what a marker will actually do |
| 3 | **Cheat sheet per member** — purpose · key files · data touched · hard parts · limitations | From S2 | In the VIVA you can navigate to anything in seconds |
| 4 | **Code walkthrough rehearsal** — each member walks their own feature file-by-file with the team | S5 | Catches "I know what it does but not where it lives" |
| 5 | **Adversarial Q&A bank** — the team invents the hardest questions it can and asks each other | S5 | Turns surprises into prepared answers |
| 6 | **Two timed full rehearsals** | S5 | Removes nerves and overruns |

### 5.2 Question types to prepare for

**Product level** — *"Why did you build it this way?"* → answered by the decisions in [doc 09 §2](09-RISKS-OPEN-QUESTIONS.md).

**Architecture level** — *"Why Firebase? Why on-device AI? How does the router decide?"* → [doc 04](04-TECH-ARCHITECTURE-COST.md).

**Code level** — *"Open your feature's view model. What does this function do? What happens if it fails?"* → **this is the question the comprehension contract exists to survive.** Every member must be able to do this for their own features.

**Failure level** — *"What happens with no internet? If the AI returns nonsense? If the payment webhook never arrives?"* → pre-answered in [doc 09 §5](09-RISKS-OPEN-QUESTIONS.md).

**Honesty level** — *"What doesn't work?"* → **always have a real answer.** Naming a genuine limitation with its cause and its plan reads as engineering maturity. Claiming perfection and then failing a follow-up does not.

### 5.3 The traceability one-pager

Every member carries one page mapping **feature → screens → source files → Firestore collections → who built it → who tested it**. It mirrors [doc 02 §8](02-FEATURE-LIST-OWNERSHIP.md) and answers "where does that live?" instantly. Practise with it: the marker may pick any feature, and you should find it in under ten seconds.


---

## 6. Demonstration environment checklist

- [ ] Primary demo device: physical iPhone, **Apple Intelligence enabled**, ≥80% battery
- [ ] Secondary device for the live group quiz (two accounts, both signed in)
- [ ] Both devices on the same network; phone hotspot as fallback
- [ ] Four demo accounts verified: student · tutor · group · admin
- [ ] Demo course with 3–4 real materials pre-uploaded **and pre-processed**
- [ ] Demo group space with 2 members
- [ ] Tap **sandbox test card** details written down (never rely on memory)
- [ ] Airplane-mode toggle rehearsed for the offline demonstration
- [ ] Backup screen recording on the presenting device **and** on a USB stick
- [ ] Chargers, cables, projector dongle
- [ ] Slides exported to PDF as well as native format
- [ ] Notifications enabled and quiet-hours disabled, so the reminder demo fires
- [ ] Screen-recording permission granted (Control Centre) before starting

---

## 7. If the app is not finished — the honest fallback ladder

Descend only as far as necessary, and **say so clearly in the VIVA**. A clearly explained gap scores far better than a pretence.

| Level | State | How to present it |
|---|---|---|
| 1 | Everything works | Present normally |
| 2 | One Tier B feature incomplete | Demo it as designed, state plainly that it is partially implemented, and say what remains |
| 3 | A Tier B feature is broken | Skip it in the live flow, show the recorded working version, explain the defect and its cause |
| 4 | Part of the core loop is broken | Demo what works, use the recording for the rest, then walk the architecture and code to show the work is real |
| 5 | The app does not run | **Never allow this.** The Tier A freeze, daily build check and recorded backup exist to prevent it |

> **The controlling insight:** markers assess *understanding and engineering process* as much as a flawless binary. An honest, well-reasoned explanation of a limitation is worth more than a rehearsed illusion — but an app that does not run on a must-pass component is unrecoverable, which is why controls 1–4 in §3 are non-negotiable.

---

## 8. The must-pass ritual (do this every week)

| Cadence | Action | Owner |
|---|---|---|
| **Daily** | Build health check: `main` builds, tests pass, app launches | rotating |
| **Weekly** | Golden path run, logged pass/fail, backup recording refreshed if those screens changed | M4 |
| **Weekly** | "Explain it" drill: one member explains another's feature from the code | rotating |
| **Bi-weekly** | Sprint review: every member demos their own work live | all |
| **From S3, 3×/week** | Full Tier A golden-path regression against demo accounts | all |
| **S5** | Feature freeze · two timed rehearsals · adversarial Q&A · traceability one-pagers finalised | all |

**The single sentence to remember:** *the demo is a performance of something already proven, not an experiment.*

---

## 9. How this component maps to the other documents

| Need | Document |
|---|---|
| Build order and sprint allocation | [doc 10 — Sprint Plan](10-SPRINT-PLAN.md) |
| Feature scope and who owns/tests what | [doc 02 — Feature List & Ownership](02-FEATURE-LIST-OWNERSHIP.md) |
| Screens each feature must have | [doc 03 — Screen Inventory](03-SCREEN-INVENTORY.md) |
| Architecture, AI router, cost | [doc 04 — Tech Architecture](04-TECH-ARCHITECTURE-COST.md) |
| Data, roles, security rules | [doc 05 — Data Model & Security](05-DATA-MODEL-SECURITY.md) |
| Visual/interaction standard | [doc 06 — Design System](06-DESIGN-SYSTEM.md) |
| Coding conventions and Cline working agreement | [doc 04 §8](04-TECH-ARCHITECTURE-COST.md) |
| Likely VIVA questions with prepared answers | [doc 09 §5](09-RISKS-OPEN-QUESTIONS.md) |
| Evidence checklist for every assessed component | [doc 08 — Rubric Coverage](08-RUBRIC-COVERAGE-MATRIX.md) |

