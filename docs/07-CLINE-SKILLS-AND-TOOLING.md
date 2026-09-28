# 07 — Cline Skills & Tooling

> "Add the skills needed" has **two meanings** in this project, and both are needed for full marks. This document covers both.

---

## 1. The two senses of "skills"

| Sense | What it means | Where it is captured |
|---|---|---|
| **A · Agent skills** | Capability packs installed into Cline so it can build SwiftUI + Firebase correctly | §2 and §3 below |
| **B · Human skills** | The competencies the 5 team members must each demonstrate to present any part of the app (brief requirement) | §4 below |

---

## 2. Sense A — Agent skills to install

These are real, published skills discovered through the open skills ecosystem (`npx skills find`). Install counts are shown because they are the ecosystem's quality signal.

### 2.1 Firebase (official — `firebase/agent-skills`)

| Skill | Installs | Why we need it |
|---|---|---|
| `firebase-basics` | **160.9K** | Correct project setup, SDK initialisation, environment handling |
| `firebase-auth-basics` | **159.8K** | Email/password + Apple sign-in, **and the custom-claims pattern our whole role model depends on** |
| `firebase-firestore` | **120.4K** | Data modelling, offline persistence, pagination, indexes, transactions |
| `firebase-ai-logic-basics` | **121.3K** | Tier-1 AI: Gemini via Firebase AI Logic, structured output, streaming |
| `firebase-security-rules-auditor` | **123.7K** | Adversarially audits `firestore.rules` for holes — our LO3 security evidence |
| `xcode-project-setup` | **116.5K** | Correct Xcode 27 + SPM wiring for the Firebase SDK |
| `firebase-crashlytics` | **117.2K** | Crash reporting = evidence of professional practice |

*Also available in the same collection if needed:* `firebase-hosting-basics` (155.8K), `firebase-app-hosting-basics` (155.3K), `firebase-data-connect` (154.4K).

### 2.2 SwiftUI and Swift

| Skill | Source | Installs | Why we need it |
|---|---|---|---|
| `swiftui-expert-skill` | `avdlee/swiftui-agent-skill` | 33.1K | Modern SwiftUI patterns, `@Observable`, navigation, performance |
| `swiftui-pro` | `twostraws/swiftui-agent-skill` | 30.2K | Correctness and API-usage review by a well-known Swift author |
| `write-swift` | `emilkowalski/skills` | 62K | Idiomatic, readable Swift — matters for the LO3 documentation marks |
| `ios-design` | `uizze.sh` | 114.7K | Apple-native design quality, directly relevant to LO1 |

### 2.3 Testing

| Skill | Source | Installs | Why we need it |
|---|---|---|---|
| `swift-testing-pro` | `twostraws/swift-testing-agent-skill` | 9K | Swift Testing framework, parameterised tests |
| `swift-testing-expert` | `avdlee/swift-testing-agent-skill` | 5K | Deeper testing strategy, async testing |
| `ios-accessibility` | `dpearson2699/swift-ios-skills` | 4.6K | Accessibility auditing — produces our SDG 10 evidence |

### 2.4 Figma (Track B — the graded prototype)

| Skill | Source | Installs | Why we need it |
|---|---|---|---|
| `figma-use` | `figma/mcp-server-guide` | 7.6K | Official Figma guidance; lets the agent drive Figma via MCP |
| `implement-design` | `figma/mcp-server-guide` | 6K | Translating a Figma design into production code accurately — the Track B → Track C bridge |

### 2.5 Design and UX (optional, high value for LO1)

| Skill | Source | Installs | Why |
|---|---|---|---|
| `design-mobile-apps` | `designed-by-ai/skills` | 478.7K | Mobile-specific design craft |
| `ui-ux-pro-max` | `nextlevelbuilder/ui-ux-pro-max-skill` | 374.5K | Broad UI/UX review heuristics |

---

## 3. Installing them (corrected — verified against the real CLI)

Two facts learned by actually running the installer on this machine:

1. **Global install is not supported.** `-g` fails with *"PromptScript does not support global skill installation."* Skills must be installed **into the project**.
2. That is **better for us anyway**: the skills land in the repository (`/.agents/skills/` plus a `skills-lock.json` lockfile) and are symlinked into `.claude/skills/`. Committing them means **all five team members get an identical, pinned agent setup** — no "works on my machine" divergence.

### Run the installer

```bash
bash tools/install-skills.sh     # idempotent; safe to re-run
npx skills check                 # verify what is installed
npx skills update                # pull newer versions
```

### What actually gets installed (14 skills)

| # | Skill | Source | Status |
|---|---|---|---|
| 1 | `firebase-basics` | `firebase/agent-skills` | ✅ installed |
| 2 | `firebase-auth-basics` | `firebase/agent-skills` | ✅ installed |
| 3 | `firebase-firestore` | `firebase/agent-skills` | ✅ installed |
| 4 | `firebase-ai-logic-basics` | `firebase/agent-skills` | ✅ installed |
| 5 | `firebase-security-rules-auditor` | `firebase/agent-skills` | ✅ installed |
| 6 | `firebase-crashlytics` | `firebase/agent-skills` | ✅ installed |
| 7 | `xcode-project-setup` | `firebase/agent-skills` | ✅ installed |
| 8 | `swiftui-expert-skill` | `avdlee/swiftui-agent-skill` | ✅ installed |
| 9 | `swiftui-pro` | `twostraws/swiftui-agent-skill` | ✅ installed |
| 10 | `write-swift` | `emilkowalski/skills` | ✅ installed |
| 11 | `swift-testing-pro` | `twostraws/swift-testing-agent-skill` | ✅ installed |
| 12 | `swift-testing-expert` | `avdlee/swift-testing-agent-skill` | ✅ installed |
| 13 | `ios-accessibility` | `dpearson2699/swift-ios-skills` | ✅ installed |
| 14 | `figma-use` + `figma-use-figjam`, `figma-use-motion`, `figma-use-slides` | `figma/mcp-server-guide` | ✅ installed (4 skills) |

### Two that did **not** work, and the substitute

| Attempted | Result | Substitute |
|---|---|---|
| `figma/mcp-server-guide@implement-design` | ❌ no such skill in that package — installing the package without `@skill` pulled all of its real skills instead (`figma-use`, `figma-use-figjam`, `figma-use-motion`, `figma-use-slides`) | Install the whole package: `npx skills add figma/mcp-server-guide -y` |
| `uizze.sh@ios-design` | ❌ `Failed to clone repository: 'uizze.sh@ios-design' does not exist` — it is a registry listing with no installable source | Use **`swiftui-pro`** + **`swiftui-expert-skill`** (already installed) for iOS design quality, and the Design System in [doc 06](06-DESIGN-SYSTEM.md) as the house style |

### What gets committed to git

| Path | Committed? | Why |
|---|---|---|
| `skills-lock.json` | ✅ **yes** | Pins each skill to a verified hash — the source of truth for reproduction |
| `tools/install-skills.sh` | ✅ **yes** | One command to restore the exact setup on any machine |
| `.agents/skills/**` (~3.3 MB, 254 files) | ❌ no (gitignored) | Installed artefact, not source — same reasoning as `node_modules` |
| `.claude/skills/**` (symlinks) | ❌ no (gitignored) | Generated symlinks into `.agents/` |

**Onboarding a teammate:** clone the repo, then run `bash tools/install-skills.sh`. That is the whole setup. Committing the lockfile rather than the skill bodies keeps the repository readable for the marker while guaranteeing reproducibility.

**Optional, if we want Cline to touch the Figma file directly:** wire up the Figma MCP server, after which `figma-use` becomes an active tool rather than reference material. Worth doing if the team wants Cline to generate the Figma component library programmatically — a genuine time-saver across ~141 frames.



---

## 4. Sense B — Human skills matrix

The brief requires that **every member can present and explain any part of the app**. This matrix states what each member must be able to *do* by the end, not merely what they own. "Primary" means they go deep; "everyone" is the shared non-negotiable floor.

| Skill area | Needed for | Primary | Everyone's minimum |
|---|---|---|---|
| **SwiftUI** (views, `@Observable`, navigation, animation) | The app + hi-fi prototype fidelity | M3 | Can read and explain any screen |
| **Swift 6 concurrency** (`async/await`, actors, strict checking) | AI streaming, uploads, sync | M3 | Can explain why AI calls stay off the main thread |
| **Firebase Auth + custom claims** | The entire role model | M1 | Can explain how role checks reach the security rules |
| **Firestore data modelling** | Every feature | M1 | Can explain the collections behind their own features |
| **Security rules** | LO3 evidence | M1 | Can explain deny-by-default |
| **AI: Foundation Models + guided generation** | F03–F05, F15 | M2 | Can explain `@Generable` and why guided generation beats free-text prompts |
| **AI: Firebase AI Logic / Gemini** | Tier-1 fallback, multimodal | M2 | Can explain the router's fallback order |
| **Prompt engineering** | Quality of every AI artefact | M2 | Can explain grounding and why confidence bands matter |
| **Vision OCR + NaturalLanguage embeddings** | F02, F15 retrieval | M2 | Can explain why extraction is on-device |
| **Spaced repetition (SM-2)** | F04 | M3 | Can explain the four rating buttons and what each changes |
| **Scheduling algorithms** | F06 | M3 | Can explain deadline weighting and the re-plan trigger |
| **Figma: auto-layout, variables, components** | All ~141 frames | M4 | Can build a screen from the component library |
| **Figma prototyping: links, Smart Animate, overflow** | Gate 2 | M4 | Can wire a flow end to end |
| **UI/UX principles (Nielsen, WCAG 2.2, Fitts's law)** | LO1 + the document | M4 | Can justify a design decision with a named principle |
| **Visual design (grid, type scale, colour, contrast maths)** | The whole look | M1 | Can state why white-on-ember fails AA |
| **Payments (Tap Payments, StoreKit, PCI basics)** | F13 | M5 | Can explain why the webhook is the source of truth |
| **Cloud Functions** | Webhooks, aggregation | M5 | Can explain what runs server-side and why |
| **Testing (Swift Testing, emulator, rules tests)** | Gate 2 QA | M4 | Can write and run a negative security-rules test |
| **Privacy & professional ethics** | LO3 + the document | M5 | Can explain the Apple 3.1.1 conflict |
| **Technical writing + Harvard referencing** | Both deliverables | M2 | Can write a rubric-aligned section |
| **Git + PR workflow** | LO3 authorship evidence | M3 | Can open a clean PR with test evidence |
| **Presentation** | The viva | all | Can present a feature they did **not** build |

**Deliberate overlap:** every member's *minimum* includes at least one thing owned by someone else. That is how the "present any part of the app" requirement is actually achieved rather than assumed.

---

## 5. Tooling setup checklist

| Tool | Status | Notes |
|---|---|---|
| macOS 27 | ✅ verified | Local machine |
| Xcode 27.0 | ✅ verified | Meets the brief's "Xcode 26.6 or 27" requirement |
| iOS 26.5 + 27.0 simulator runtimes | ✅ verified | `iPhone 17`, `iPhone 18 Pro`, `iPhone Air`, `iPhone 17e`, iPads |
| Swift 6.4 | ✅ verified | Strict concurrency available |
| Figma desktop app | ✅ verified | Installed |
| Node 24.15 / npm 11.12 | ✅ verified | For the Firebase CLI and `npx skills` |
| Firebase CLI (`firebase-tools`) | ⬜ install | `npm i -g firebase-tools` → `firebase login` |
| Firebase project (Spark plan) | ⬜ create | `studyforge-it8108`, storage bucket in `us-central1` |
| Firebase Emulator Suite | ⬜ install | Ships with the CLI |
| Tap Payments sandbox account | ⬜ sign up | Request `pk_test_…` keys |
| Google Cloud budget alert + spend cap | ⬜ **mandatory** | Before any Cloud Functions deploy |
| SF Symbols app | ⬜ install | Icon consistency |
| Accessibility Inspector | ✅ built into Xcode | Phase 8 gate |
| Instruments | ✅ built into Xcode | Phase 8 gate |
| draw.io / Excalidraw | ⬜ | The 15 feature flow diagrams |
| Figma "Contrast" plugin | ⬜ | Verify the §1.1 table in the actual file |
| Task tracker (GitHub Projects / Notion) | ⬜ | Mirrors the [roadmap](01-ROADMAP-PHASES-TODOLIST.md) |
| Git + GitHub repo | ✅ repo exists | Enable branch protection on `main` |

---

## 6. How to drive Cline well (prompt playbook)

Track C is built by Cline, so the prompts matter as much as the architecture. These rules consistently produce usable results:

| Rule | Example |
|---|---|
| **Give the feature ID and the screen IDs** | "Implement **F04** per screens `42`–`50` in [doc 03](03-SCREEN-INVENTORY.md)." |
| **Name the convention document** | "Follow [doc 04 §8](04-TECH-ARCHITECTURE-COST.md) — MVVM, `@Observable`, `AppContainer`, no singletons." |
| **Ask for the protocol first** | "Define the `SpacedRepetitionScheduling` protocol and its mock before the implementation." |
| **Demand all states** | "Every screen must render `LoadState<…>`: loading, empty, failed, loaded." |
| **Insist on the data contract** | "Write the Firestore document shape and its security rule together, then the Swift model." |
| **One feature per PR** | Keeps diffs reviewable and gives clean authorship evidence for LO3. |
| **Always ask for tests** | "Add Swift Testing cases for the SM-2 interval calculation, including a lapse case." |
| **Ask it to check itself** | "Re-read the requirements, list every state, error path and accessibility label you have not implemented, then implement them." |
| **Never let it touch secrets** | `GoogleService-Info.plist` stays in `.gitignore`; keys go in `.xcconfig` files and Cloud Function environment variables. |

**Guardrails to restate in every long session:** no secrets committed · no `allow read, write: if true` anywhere in rules · no AI call on the main thread · no hard-coded user-facing strings (EN + AR) · never silently drop a state the design requires — flag it instead.

---

## 7. Quick reference: which skill for which phase

| Phase | Skills to lean on |
|---|---|
| 0 · Setup & Identity | `firebase-basics`, `xcode-project-setup` |
| 3 · Mockups & flows | `design-mobile-apps`, `ios-design`, `figma-use` |
| 5 · Hi-fi prototype | `figma-use`, `implement-design`, `ui-ux-pro-max` |
| 6 · App foundation | `swiftui-expert-skill`, `swiftui-pro`, `write-swift` |
| 7 · Backend & AI | `firebase-auth-basics`, `firebase-firestore`, `firebase-ai-logic-basics`, `firebase-security-rules-auditor` |
| 8 · Payments & accessibility | `ios-accessibility`, `firebase-crashlytics` |
| 9 · QA | `swift-testing-pro`, `swift-testing-expert`, `ios-accessibility` |


