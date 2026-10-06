# StudyForge, Intelligent Learning Platform

**Turn any material into mastery.**

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

**4 members, group size approved by the tutor.** (The brief's default is 5; the tutor has confirmed 4 is acceptable for this group.)

| Handle | Name | Student ID | Team role | Features owned | Frame suffix |
|---|---|---|---|---|---|
| **M1** | **Saleh Abdulla** | `202300540` | Data, Auth & Admin lead | F01, F02, F14 | `Saleh_202300540` |
| **M2** | **Mohammed Almadhoon** | `202401702` | AI/ML & Tutor lead | F03, F04, F05, **F11**, **F15 (co)** | `Mohammed_202401702` |
| **M3** | **Tasbeeh Saeed** | `202300549` | Architecture & Payments lead | F06, F07, **F13**, **F15 (co)** | `Tasbeeh_202300549` |
| **M4** | **Shahad Ashoor** | `202305767` | UI/UX, Collaboration & Admin lead | F08, F09, F10, **F12** | `Shahad_202305767` |

All placeholder names have been replaced. The former M5 workstream (F11/F12/F13) was redistributed by adjacency, see [doc 02 §2.1](docs/02-FEATURE-LIST-OWNERSHIP.md).


---

## Documentation index

| Doc | Contents |
|---|---|
| [00, Master Plan](docs/00-MASTER-PLAN.md) | Decoded spec, assessment-driven priorities, product identity, roles, innovation |
| [01, Roadmap, Phases & Todolist](docs/01-ROADMAP-PHASES-TODOLIST.md) | Sprint-structured roadmap with dated gates + tickable task list, **the guide & roadmap** |
| [02, Feature List & Ownership](docs/02-FEATURE-LIST-OWNERSHIP.md) | 15 features, 4 developers, developer/tester matrix, advanced feature |
| [03, Screen Inventory](docs/03-SCREEN-INVENTORY.md) | 141 screens, Figma frame naming rule, prototype cut-line |
| [04, Tech Architecture & Cost](docs/04-TECH-ARCHITECTURE-COST.md) | SwiftUI + Firebase + Tap Payments + 3-tier AI, $0 cost model |
| [05, Data Model & Security](docs/05-DATA-MODEL-SECURITY.md) | Firestore/Storage schema, roles, security-rules strategy |
| [06, Design System](docs/06-DESIGN-SYSTEM.md) | Colour, type, spacing, components, UI/UX principle mapping |
| [07, Cline Skills & Tooling](docs/07-CLINE-SKILLS-AND-TOOLING.md) | Agent skills, team skill matrix, Cline operating model |
| [08, Rubric Coverage Matrix](docs/08-RUBRIC-COVERAGE-MATRIX.md) | Bullet-by-bullet evidence map for **every assessed component** |
| [09, Risks & Open Questions](docs/09-RISKS-OPEN-QUESTIONS.md) | Risk register, decision log, questions awaiting answers |
| [10, Sprint Plan](docs/10-SPRINT-PLAN.md) | The **individual 10%**: sprint cadence, per-member tasks, contribution evidence |
| [11, App Implementation & VIVA](docs/11-APP-IMPLEMENTATION-VIVA.md) | The **60% must-pass**: MVP scope, demo script, VIVA prep, must-pass risk control |
| [12, Git Workflow](docs/12-GIT-WORKFLOW.md) | **Branches, per-file commits, PRs**, the tutor's stated requirement, plus `tools/commit.sh` |

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
├── docs/                        planning set (00–12), start at README
│
├── deliverables/
│   ├── design-document/         10%, PDF source + low-fidelity mockups
│   └── prototype/               10%, StudyForge.fig + figma-link.txt
│
├── research/                    assessment evidence
│   ├── dossier.md               evidence base for Background Research
│   ├── sprints/sprint-<N>/      10% INDIVIDUAL, goal · board · review · retro
│   ├── testing/                 test logs per feature (tester ≠ developer)
│   ├── reviews/                 review notes on AI-generated code
│   ├── cheatsheets/             one per member, VIVA quick reference
│   └── demo/                    golden-path recordings + backup capture
│
└── tools/                       install-skills · commit.sh · new-branch.sh · verify-docs
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
| iOS App Implementation & Demonstration | **60% (must pass)** | 🟨 in progress: F01 to F15 implemented; builds and passes 697 unit tests |
| Sprints (individual) | 10% | 🟨 in progress: continuous commit evidence on `feat/*` branches |
| Design Document | 10% | 🟨 in progress: draft assembled in `deliverables/design-document/` |
| Prototype (Figma) | 10% | 🟨 in progress: 98 frames built, see `deliverables/prototype/figma-link.txt` |

Legend: ⬜ not started · 🟨 in progress · ✅ done

**Verified locally** (Xcode 27.0, iPhone 17 simulator, iOS 27.0, UDID `08D34825-D798-4328-929A-18616BEA64CB`):

- `xcodebuild ... build` → `** BUILD SUCCEEDED **`
- `xcodebuild ... test` → `Test run with 697 tests in 111 suites passed`

- ✅ Brief decoded, rubric extracted, easy-to-miss requirements identified
- ✅ Local toolchain verified (Xcode 27.0 · iOS 26.5 & 27.0 simulators · Swift 6.4 · Figma.app · Node 24.15)
- ✅ Tech stack + $0 cost model researched and confirmed
- ✅ App name, tagline, logo direction, palette proposed
- ⬜ App identity frozen
- ✅ Team names/IDs inserted, 4 members, group size approved by the tutor
- ⬜ Cline agent skills installed
