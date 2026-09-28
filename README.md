# StudyForge — Intelligent Learning Platform

**Turn any material into mastery.**

| | |
|---|---|
| **Module** | IT8108 — Project Design Document & Prototype |
| **Semester** | Semester A, 2026–2027 |
| **Client Brief** | **Project Brief 2 — Intelligent Learning Platform** |
| **SDGs** | SDG 4 (Quality Education) · SDG 9 (Industry, Innovation & Infrastructure) · SDG 10 (Reduced Inequalities) |
| **Tutors** | Haetham Alhaddad (Coordinator) · Ghassan AlShajjar |
| **Platform** | iOS 26.0+ · Xcode 26.6 / 27 (local verified: **Xcode 27.0** ✅) |
| **Backend** | Firebase (Spark / no-cost tier) |
| **Frontend** | SwiftUI + Swift 6 |
| **Payments** | Tap Payments (tap.company) — Bahrain-licensed gateway |
| **Deadlines** | Design Document **22 Oct 2026, 23:55** · Prototype **12 Nov 2026, 23:55** |

---

## The two graded deliverables (do not confuse them)

| # | Deliverable | Format | Marks | Weight | LOs |
|---|---|---|---|---|---|
| 1 | **Design Document** | Single PDF — Background Research (4) · Features List (4) · Mockups (8) · Innovation (2) · Organisation (2) | /20 | 10% | LO1, LO3 |
| 2 | **Project Prototype** | High-fidelity **interactive Figma** — `.fig` file **AND** shared URL in a text doc | /20 | 10% | LO1, LO2, LO3 |

> ⚠️ **The working SwiftUI app is NOT itself a graded deliverable.** The brief specifies the prototype as a *Figma* artefact. We build the real app anyway because it (a) de-risks the live demonstration, (b) proves the design is technically feasible, and (c) is a strong Innovation talking point. **Figma is the non-negotiable critical path.**

---

## Team

| Handle | Name | Student ID | Team role | Features owned | Frame suffix |
|---|---|---|---|---|---|
| **M1** | **Saleh Abdulla** | `202300540` | Data & Auth lead | F01, F02, F14 | `Saleh_202300540` |
| **M2** | **Mohammed Almadhoon** | `202401702` | AI/ML lead | F03, F04, F05, **F15 (co)** | `Mohammed_202401702` |
| **M3** | **Tasbeeh Saeed** | `202300549` | Architecture & Scheduling lead | F06, F07, **F15 (co)** | `Tasbeeh_202300549` |
| **M4** | **Shahad Ashoor** | `202305767` | UI/UX & Collaboration lead | F08, F09, F10 | `Shahad_202305767` |
| **M5** | `{{TBC — 5th member}}` | `{{2022xxxxx}}` | Payments, Tutor & Admin lead | F11, F12, F13 | `{{TBC}}` |

> ⚠️ **The brief requires exactly 5 members.** Four are confirmed; **M5 is an open slot** that must be resolved with the tutor. Contingency and redistribution plan: [doc 02 §2.1](docs/02-FEATURE-LIST-OWNERSHIP.md).

---

## Documentation index

| Doc | Contents |
|---|---|
| [00 — Master Plan](docs/00-MASTER-PLAN.md) | Decoded spec, product identity, personas, competitive edge, strategy |
| [01 — Roadmap, Phases & Todolist](docs/01-ROADMAP-PHASES-TODOLIST.md) | 11 phases with dated gates + tickable task list — **the guide & roadmap** |
| [02 — Feature List & Ownership](docs/02-FEATURE-LIST-OWNERSHIP.md) | 15 features, 5 developers × 3, developer/tester matrix, advanced feature |
| [03 — Screen Inventory](docs/03-SCREEN-INVENTORY.md) | 141 screens (89 P0 committed), Figma frame naming rule, MVP cut-line |
| [04 — Tech Architecture & Cost](docs/04-TECH-ARCHITECTURE-COST.md) | SwiftUI + Firebase + Tap Payments + 3-tier AI, $0 cost model |
| [05 — Data Model & Security](docs/05-DATA-MODEL-SECURITY.md) | Firestore/Storage schema, roles, security-rules strategy |
| [06 — Design System](docs/06-DESIGN-SYSTEM.md) | Colour, type, spacing, components, UI/UX principle mapping |
| [07 — Cline Skills & Tooling](docs/07-CLINE-SKILLS-AND-TOOLING.md) | Agent skills to install, team skill matrix, Cline operating model |
| [08 — Rubric Coverage Matrix](docs/08-RUBRIC-COVERAGE-MATRIX.md) | Bullet-by-bullet evidence map for **full marks** |
| [09 — Risks & Open Questions](docs/09-RISKS-OPEN-QUESTIONS.md) | Risk register, decision log, questions awaiting answers |

---

## Repository layout (target)

```
IntelligentLearningPlatform/
├── README.md
├── docs/                        # this planning set
├── deliverables/
│   ├── design-document/         # Phase 1 PDF source + assets
│   │   └── mockups/             # low-fidelity screens
│   └── prototype/               # Phase 2 Figma hand-off
│       ├── StudyForge.fig
│       └── figma-link.txt
├── ios/StudyForge/              # Xcode 27 project (SwiftUI, Swift 6)
├── firebase/                    # firestore.rules, storage.rules, indexes, functions/
└── research/                    # interview notes, references, competitor teardown
```

---

## Current status

**Phase 0 — Setup & Project Identity** · see [roadmap](docs/01-ROADMAP-PHASES-TODOLIST.md)

Legend: ⬜ not started · 🟨 in progress · ✅ done

- ✅ Brief decoded, rubric extracted, easy-to-miss requirements identified
- ✅ Local toolchain verified (Xcode 27.0 · iOS 26.5 & 27.0 simulators · Swift 6.4 · Figma.app · Node 24.15)
- ✅ Tech stack + $0 cost model researched and confirmed
- ✅ App name, tagline, logo direction, palette proposed
- ⬜ App identity frozen
- ⬜ Team names/IDs inserted (placeholders `M1–M5` currently in use)
- ⬜ Cline agent skills installed
