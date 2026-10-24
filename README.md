# StudyForge, Intelligent Learning Platform

**Turn any material into mastery.**

> **Contributing to this project? Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first.** It is
> the full guide: setup, the git rules, your file lane, code conventions, testing, the
> evidence that is actually marked, troubleshooting, and VIVA readiness.

| | |
|---|---|
| **Module** | IT8108, Project Design Document & Prototype |
| **Semester** | Semester A, 2026–2027 |
| **Client Brief** | **Project Brief 2, Intelligent Learning Platform** |
| **SDGs** | SDG 4 (Quality Education) · SDG 9 (Industry, Innovation & Infrastructure) · SDG 10 (Reduced Inequalities) |
| **Tutors** | Haetham Alhaddad (Coordinator) · Ghassan AlShajjar |
| **Platform** | iOS 26.0+ · Xcode 26.6 / 27 (local verified: **Xcode 27.0** ✅) |
| **Backend** | Firebase (Spark / no-cost tier) |
| **Frontend** | SwiftUI + Swift 6 |
| **Payments** | Tap Payments (tap.company), Bahrain-licensed gateway |
| **Deadlines** | Design Document **22 Oct 2026, 23:55** · Prototype **12 Nov 2026, 23:55** |

---

## Assessment model (this drives every priority in the plan)

| # | Component | Weight | Type | Must pass? | Status |
|---|---|---|---|---|---|
| 1 | **Individual App** | 10% | Individual | - | ✅ already completed |
| 2 | **Design Document** | 10% | Group | - | ⬜ due **22 Oct 2026** |
| 3 | **Prototype (Figma)** | 10% | Group | - | ⬜ due **12 Nov 2026** |
| 4 | **Sprints** | **10%** | **Individual** | - | ⬜ continuous during implementation |
| 5 | **iOS App Implementation & Demonstration** | **60%** | Group | ⛔ **MUST PASS** | ⬜ continuous + in-person VIVA |

**Two pass conditions, both must be met:**

1. An **aggregate mark ≥ 60%**; **and**
2. The **iOS App Implementation & Demonstration (60%) is passed**.

> ⚠️ **The working iOS app is the most important deliverable, 60% and a hard gate on passing the course.** An earlier draft of this plan wrongly treated the app as optional, because the *Project Design Document brief* describes only two phases (design document + Figma prototype). That brief covers 20% of the course, it is not the whole assessment. **The app is the critical path, not Figma.**

| Priority | Component | Why it ranks here |
|---|---|---|
| **1** | **iOS App + VIVA (60%, must pass)** | Failing this fails the course regardless of everything else. Must be complete, working on a real device, and explainable by every member |
| **2** | **Sprints (10%, individual)** | The only component a teammate cannot carry for you. Needs continuous, per-person, timestamped evidence |
| **3** | **Design Document (10%)** | Fixed deadline (22 Oct), front-loaded then closed |
| **4** | **Prototype (10%)** | Still must cover every feature and be interactive, but is **not** worth over-investing at this weight |

**Effort allocation target:** ~50% app & VIVA · ~20% sprints & contribution evidence · ~15% design document · ~15% Figma prototype.


---

## Team

**5 members — the brief's own default.** (Between 28 Sep and 14 Oct the group ran with four, which the tutor approved; on 14 Oct 2026 Fatema Ghareeb joined and filled the fifth seat, so the group now matches the brief exactly.)

| Handle | Name | Student ID | Team role | Features owned | Frame suffix |
|---|---|---|---|---|---|
| **M1** | **Saleh Abdulla** | `202300540` | Data, Auth & Admin lead | F01, F02, F14 | `Saleh_202300540` |
| **M2** | **Mohammed Almadhoon** | `202401702` | AI/ML & Tutor lead | F03, F04, F05, **F11**, **F15 (co)** | `Mohammed_202401702` |
| **M3** | **Tasbeeh Saeed** | `202305409` | Architecture & Payments lead | F06, F07, **F13**, **F15 (co)** | `Tasbeeh_202305409` |
| **M4** | **Shahad Ashoor** | `202305767` | UI/UX, Collaboration & Admin lead | F08, F09, F10, **F12** | `Shahad_202305767` |
| **M5** | **Fatema Ghareeb** | `202304804` | Collaboration & Recall lead | **F16**, **F17** | `Fatema_202304804` |

All placeholder names have been replaced. The workstream of the **then-empty** fifth seat (F11/F12/F13) was redistributed by adjacency and **stays** redistributed; M5 owns the two features added with her, F16 and F17. See [doc 02 §2.1](docs/02-FEATURE-LIST-OWNERSHIP.md).

> **M3's student ID was corrected on 23 Oct 2026** — `202300549` → **`202305409`**, two digits had been transposed. Every **identity** reference, every **frame suffix** and the tooling now carry the corrected ID. The old address survives in exactly one place and for one reason: her twelve commits that were already merged are authored under it, so `.mailmap` keeps it as an **alias** to stop `git shortlog` orphaning them — **do not delete that line**. Dated evidence written before the correction (sprint logs, testing sheets, the F15 approval request) keeps the ID it was written with; that is the record, not an oversight.


---

## Documentation index

| Doc | Contents |
|---|---|
| [**CONTRIBUTING.md**](CONTRIBUTING.md) | **Start here to contribute.** Setup, git rules, your file lane, conventions, testing, evidence, troubleshooting, VIVA |
| [00, Master Plan](docs/00-MASTER-PLAN.md) | Decoded spec, assessment-driven priorities, product identity, roles, innovation |
| [01, Roadmap, Phases & Todolist](docs/01-ROADMAP-PHASES-TODOLIST.md) | Sprint-structured roadmap with dated gates + tickable task list, **the guide & roadmap** |
| [02, Feature List & Ownership](docs/02-FEATURE-LIST-OWNERSHIP.md) | 17 features, 5 developers, developer/tester matrix, advanced feature |
| [03, Screen Inventory](docs/03-SCREEN-INVENTORY.md) | 154 screens, Figma frame naming rule, prototype cut-line |
| [04, Tech Architecture & Cost](docs/04-TECH-ARCHITECTURE-COST.md) | SwiftUI + Firebase + Tap Payments + 3-tier AI, $0 cost model |
| [05, Data Model & Security](docs/05-DATA-MODEL-SECURITY.md) | Firestore/Storage schema, roles, security-rules strategy |
| [06, Design System](docs/06-DESIGN-SYSTEM.md) | Colour, type, spacing, components, UI/UX principle mapping |
| [07, Cline Skills & Tooling](docs/07-CLINE-SKILLS-AND-TOOLING.md) | Agent skills, team skill matrix, Cline operating model |
| [08, Rubric Coverage Matrix](docs/08-RUBRIC-COVERAGE-MATRIX.md) | Bullet-by-bullet evidence map for **every assessed component** |
| [09, Risks & Open Questions](docs/09-RISKS-OPEN-QUESTIONS.md) | Risk register, decision log, questions awaiting answers |
| [10, Sprint Plan](docs/10-SPRINT-PLAN.md) | The **individual 10%**: sprint cadence, per-member tasks, contribution evidence |
| [11, App Implementation & VIVA](docs/11-APP-IMPLEMENTATION-VIVA.md) | The **60% must-pass**: MVP scope, demo script, VIVA prep, must-pass risk control |
| [12, Git Workflow](docs/12-GIT-WORKFLOW.md) | **Branches, per-file commits, PRs**, the tutor's stated requirement, plus `tools/commit.sh` |
| [13, Per-Member Tasks](docs/13-PER-MEMBER-TASKS.md) | Tickable task list per member, plus turnkey first-commit starter briefs |
| [14, Per-member AI-agent handover](docs/14-COLLEAGUE-AI-AGENT-PROMPTS.md) | The disjoint file-lane map + `tools/check-lane.sh`, so four agents can work at once without conflicts |
| [15, Project Briefing](docs/15-PROJECT-BRIEFING.md) | **Plain-language summary in three parts:** what the project is about, the 17 features, and the interview questions. Start here for interview prep or VIVA revision |
| [16, Team Kickoff](docs/16-TEAM-KICKOFF.md) | **One page, read it first this week:** what changed, your lane, the five commands, the two rules that cost marks, the deadlines |
| [18, Windows Contributing](docs/18-WINDOWS-CONTRIBUTING.md) | **For the four members on Windows:** CI is your build machine, what you can and cannot verify locally, and the six rules that make agent-written code trustworthy |
| [TODO M2](docs/TODO-M2-mohammed.md) · [TODO M3](docs/TODO-M3-tasbeeh.md) · [TODO M4](docs/TODO-M4-shahad.md) · [TODO M5](docs/TODO-M5-fatema.md) | **The handover file to give each member's AI agent** — identity, lane, features, TODOs, git protocol, definition of done |

---

## Repository layout (target)

```
IntelligentLearningPlatform/
│
├── ios/StudyForge/              ⭐ THE APP, 60% must-pass deliverable
│   │                                Xcode 27 · SwiftUI · Swift 6 · MVVM
│   ├── StudyForge.xcodeproj/
│   └── StudyForge/
│       ├── App/                 entry · RootView · AppContainer (DI)
│       ├── Core/                Auth · State · (AI · Persistence · Payments in S1+)
│       ├── DesignSystem/        colour · type · spacing tokens
│       ├── Features/            one folder per feature ID
│       └── Resources/
│
├── backend/                     THE BACKEND, Firebase (config + 3 functions)
│   ├── firestore.rules              role-based, deny-by-default (40 tests ✅)
│   ├── storage.rules                owner + shared-folder grants (18 tests ✅)
│   ├── firestore.indexes.json       10 composite indexes
│   ├── rules-tests/                 emulator suites, negative tests first
│   └── functions/                   createCharge · tapWebhook · rollupDailyMetrics
│
├── docs/                        planning set (00–15) + a TODO handover per member, start at README
│
├── deliverables/
│   ├── design-document/         10%, PDF source + low-fidelity mockups
│   └── prototype/               10%, StudyForge.fig + figma-link.txt
│
├── research/                    assessment evidence
│   ├── dossier.md               evidence base for Background Research
│   ├── interviews/              graded: transcript, capture, written F15 approval
│   ├── sprints/sprint-<N>/      10% INDIVIDUAL, goal · board · review · retro
│   ├── cheatsheets/             one per member, VIVA quick reference
│   ├── testing/                 test logs per feature (tester ≠ developer)   ← to create
│   ├── reviews/                 review notes on AI-generated code            ← to create
│   ├── meeting-notes/           stand-up and review minutes                  ← to create
│   └── demo/                    golden-path recordings + backup capture      ← to create
│
└── tools/                       commit · new-branch · check-lane · check-submission
                                 verify-docs · check-strings · todos · build-pdf
                                 run-ios · run-device · install-skills · figma-cli
```

### Why two halves, and why they aren't symmetrical

`ios/` and `backend/` are the two deployable halves. Everything else, `docs/`, `research/`,
`deliverables/`, `tools/`, is project-level and deliberately outside both.

The split is **asymmetric on purpose**: the app is the product (60% must-pass, thousands of lines),
while `backend/` is ~95% declarative Firebase config plus **three small Cloud Functions**. The AI
router, repositories, offline cache and data model all live **inside `ios/`**, because generation is
on-device-first. So there is no server of ours to run, Firebase enforces authorisation
declaratively. See [docs/00 §3](docs/00-MASTER-PLAN.md) and [backend/README.md](backend/README.md).


---

## Current status

**Implementation underway.** The **app (60%, must pass)** is the critical path; everything else runs alongside it.

| Component | Weight | Status |
|---|---|---|
| Individual App | 10% | ✅ complete |
| iOS App Implementation & Demonstration | **60% (must pass)** | 🟨 in progress: **F01 to F17** implemented; builds and passes **808 unit tests** |
| Sprints (individual) | 10% | ⚠️ **at risk, but no longer for access:** all five members hold write access (verified 16 Oct 2026), so **the blocker is gone** — yet **only M1 has authored commits**. Teammate evidence cannot be created at the end; it has to exist throughout the sprint, and the commit timestamps are what a marker reads |
| Design Document | 10% | 🟨 in progress: draft assembled in `deliverables/design-document/`; **tutor interview done and transcribed** (13 Oct); **PDF rebuilt 24 Oct 2026** — 196 pages, 159 figures, a running header and `Page X of Y` on every page; **submission bundle assembled** in `deliverables/submission/`. `bash tools/check-submission.sh` clears **26 of its 29 items** and **the 3 open are human-only** — the **§17.3 usability test** (counted twice; the pack is ready in `research/usability/`) and **P9-18/19, the portal submission itself** (`prototype-v1` is tagged and pushed). Run the gate for the live list |
| Prototype (Figma) | 10% | 🟨 in progress: **123 screens built** of a **154-frame inventory**, and **interactive** — **320 prototype connections** and **110 of 119 reachable, zero dead ends**, both as measured in the **15 Oct 2026** audit, with the screens added since not yet re-measured (see `deliverables/prototype/figma-link.txt` §9); **130 low-fidelity wireframes**, **all 17 flow diagrams** and **130 dark-mode variants**. F16/F17's 13 frames (groups N and O) were drawn and wired on 15 Oct 2026, and their low-fidelity wireframes followed on 24 Oct 2026 together with 11 more for the reworked F13 subscription states. See `deliverables/prototype/figma-link.txt` |

Legend: ⬜ not started · 🟨 in progress · ✅ done

**Verified locally** (Xcode 27.0, iPhone 17 simulator, iOS 27.0, UDID `08D34825-D798-4328-929A-18616BEA64CB`):

- `xcodebuild ... build` → `** BUILD SUCCEEDED **`
- `xcodebuild ... test` → `Test run with 808 tests in 128 suites passed`

- ✅ Brief decoded, rubric extracted, easy-to-miss requirements identified
- ✅ Local toolchain verified (Xcode 27.0 · iOS 26.5 & 27.0 simulators · Swift 6.4 · Figma.app · Node 24.15)
- ✅ Tech stack + $0 cost model researched and confirmed
- ✅ App name, tagline, logo direction, palette proposed
- ✅ App identity frozen (StudyForge · logo · palette — carried in every document header and the Figma cover)
- ✅ Team names/IDs inserted, 5 members, the brief's own default group size
- ✅ Cline agent skills installed (`.agents/skills/`, `skills-lock.json`)
- ✅ **Tutor interview conducted** — Tuesday 13 October 2026, 2:40 pm, all five members present; five questions and the supervisor's answers transcribed in [`research/interviews/`](research/interviews/README.md)
- ✅ **Written F15 advanced-feature approval** — the rubric requirement; the request and the tutor's reply are transcribed in [`research/interviews/f15-advanced-feature-approval.md`](research/interviews/f15-advanced-feature-approval.md)
- ⬜ Usability test with 5 users and a SUS score (Design Document §17.3)
