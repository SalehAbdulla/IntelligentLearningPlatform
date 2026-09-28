# 09 — Risks, Decisions & Open Questions

---

## 1. Risk register

Scored on likelihood (L) and impact (I), 1–5. **Score = L × I.** Anything ≥12 is reviewed every Monday.

| ID | Risk | L | I | Score | Mitigation | Owner |
|---|---|---|---|---|---|---|
| **R1** | The Figma prototype is not finished, linked or correctly named by 12 Nov | 3 | 5 | **15** | P0-first sequencing · Thursday freeze week before · wiring is a *scheduled* task, not an afterthought · the cut-line protocol | M2, M4 |
| **R2** | Scope creep — 141 frames is a lot for 5 people in 6 weeks | 4 | 4 | **16** | Hard tiering (P0 = 89) · explicit cut-line protocol ([roadmap §14](01-ROADMAP-PHASES-TODOLIST.md)) · freeze dates | M2 |
| **R3** | On-device Apple Intelligence is unavailable in the Simulator, so the AI demo fails live | 4 | 4 | **16** | Tier-1 fallback works in the Simulator · `80_Coach_OnDeviceUnavailable_Fallback` designed · **demo on a real device** · recorded backup | M2, M3 |
| **R4** | Firebase free-tier quota exhaustion mid-demo | 2 | 4 | 8 | Content-hash cache · on-device-first routing · per-user daily budget · emulator for all dev work · seed demo data before the demo | M1 |
| **R5** | Cloud Functions require the Blaze plan, creating billing risk | 3 | 4 | 12 | Keep the function surface tiny (webhook + nightly aggregation only) · **budget alert + spend cap before first deploy** | M1, M3 |
| **R6** | Tap Payments **live** onboarding needs a commercial registration and bank account we don't have | 5 | 3 | 15 | **Sandbox only** — this is a stated, deliberate scope boundary; test cards are sufficient to demonstrate the flow | M3 |
| **R7** | Apple Guideline 3.1.1 conflicts with using a non-Apple gateway for digital goods | 4 | 2 | 8 | `PaymentGateway` protocol with a `StoreKitGateway` implementation · the conflict is *documented as an ethics finding* (turns a risk into a mark) | M3 |
| **R8** | AI-generated quiz answers are wrong — an academic-integrity problem | 3 | 4 | 12 | Grounded generation only · provenance on every answer · confidence bands · tutor review queue · "verify against your source" disclaimer · **no auto-grading of assessed work** | M2 |
| **R9** | A team member becomes unavailable during the critical path | 3 | 4 | 12 | Cross-training matrix ([doc 07 §4](07-CLINE-SKILLS-AND-TOOLING.md)) · pair on critical-path frames · everything in git | M1 |
| **R10** | Figma and SwiftUI drift apart visually | 3 | 3 | 9 | Single token source · `tools/check-tokens.sh` fails the build on divergence | M3 |
| **R11** | A framework or SDK API changes (Foundation Models is new) | 3 | 3 | 9 | Pin SPM versions · feature-detect availability at runtime · the router already has a fallback path | M3 |
| **R12** | Cline produces large, unreviewable diffs that break the build | 3 | 3 | 9 | One feature per PR · PR template requires feature ID + screens + rubric row + test evidence · CI build gate | M3 |
| **R13** | Academic-integrity concern about AI-assisted development | 3 | 3 | 9 | **Disclose it explicitly** in the document: name the tools, state what the team designed versus what was generated, and keep the design decisions, feature ownership and testing human | M1 |
| **R14** | Privacy concerns in usability testing with real students | 2 | 3 | 6 | Written consent · anonymise all data in the report · no personal study content collected | M4 |
| **R15** | Deadline pressure from other modules in the same weeks | 4 | 4 | **16** | 24-hour submission buffers · freeze dates are absolute · the cut-line protocol removes optional work first | all |

**The two risks that will actually decide the grade: R1/R2 (prototype completeness) and R3 (the live AI demo).** Everything else is manageable.

---

## 2. Decision log

Recorded as lightweight ADRs so the Design Document can show *why* choices were made — the rubric rewards justified decisions and LO3 rewards documentation conventions.

| # | Decision | Rationale | Alternatives rejected |
|---|---|---|---|
| D1 | App name **StudyForge** | "Forge" is the brief's own metaphor (raw material → study tools); unique, one word, memorable | MindFold, Zamil, Mishkat, Revisely — held as fallbacks |
| D2 | **Figma prototype is the critical path**; the working app is a parallel, non-graded track | The brief grades a Figma artefact, not an app | Build the app first and mock up later |
| D3 | **3-tier AI router, on-device first** | The only way to hit "$0", offline and privacy simultaneously | Cloud-only (costs money, breaks offline); on-device-only (breaks in the Simulator, no multimodal) |
| D4 | **SwiftData** for the offline cache *and* RAG vectors | First-party and free; avoids paying for a vector database | Pinecone / Weaviate (cost); Firestore vectors (cost + privacy) |
| D5 | **Tap Payments sandbox only**; StoreKit behind the same protocol | Live onboarding needs a CR and a bank account we don't have; App Store 3.1.1 forbids the external gateway for digital goods in a shipping app | Going live (impossible + non-compliant); mocking payment entirely (loses the client requirement) |
| D6 | **Firestore** over Realtime Database | Realtime listeners are free, offline persistence is built in, security rules are more expressive | RTDB (weaker queries/rules); custom backend (cost + effort) |
| D7 | **Minimal Cloud Functions** (webhook + nightly aggregation only) | Keeps us inside the free allowance and limits billing exposure | All AI behind functions (cost + latency + bigger bill risk) |
| D8 | **Storage bucket in `us-central1`** | The no-cost Storage quota applies only to `us-central1` / `us-west1` / `us-east1`. ~200 ms extra latency is the price of $0 | A Bahrain-region bucket (would incur charges) |
| D9 | **4 roles with capability layering** — *Study Group Member* is a capability, not a role | Models reality (one human, one account, many contexts) and satisfies "≥3 roles" with a stronger pattern | Four account types (confusing re-signup UX) |
| D10 | **15 features, 3 per developer** | Comfortably exceeds the "≥2 each" minimum and maps onto the brief's 10 named features plus 5 additions | 10 features (minimum effort, thin document) |
| D11 | **Figma variables ↔ SwiftUI token parity** | Prevents visual drift between the graded prototype and the app | Designing twice and hoping they match |
| D12 | **141 frames inventoried, 89 P0 committed** | Depth without unbounded scope, plus a hard honest cut-line | Fewer screens (weaker mockup coverage); promising all 141 (unrealistic) |
| D13 | **Low-fi and hi-fi in the same Figma file** | Low-fi → hi-fi becomes an upgrade, never a redraw; halves the work and guarantees they match | Separate lo-fi tool (Draw.io) then redesign in Figma |
| D14 | **Prompt templates stored in Firestore** | Tune AI output without an app release — and a live demo asset | Hard-coded prompts (need a rebuild to improve quality) |
| D15 | **Two graded tracks only** (doc + prototype), everything else optional | Protects the critical path; the cut-line protocol removes the app work first | Treating the app as a deliverable (risks both grades) |
| D16 | **Proceed with 4 members** — remove M5, redistribute F11/F12/F13 | The tutor confirmed 4 is acceptable for this group, overriding the brief's default of 5. Redistribution was done by **adjacency** so each moved feature sits next to a member's existing domain: F11→M2 (AI content review), F12→M4 (permissions/moderation), F13→M3 (Cloud Functions/server-side) | Holding an unfilled 5th slot (blocks the entire feature list, developer and tester columns); distributing randomly (creates avoidable learning curves and uneven loads) |

---

## 3. Open questions — awaiting answers

Each question materially affects the plan. **Every one has a safe default**, so no work is blocked while waiting.

| # | Question | Why it matters | Default if unanswered |
|---|---|---|---|
| ~~Q1~~ | ✅ **RESOLVED** — 4 members confirmed by the tutor: **Saleh Abdulla** `202300540` · **Mohammed Almadhoon** `202401702` · **Tasbeeh Saeed** `202300549` · **Shahad Ashoor** `202305767`. M5's F11/F12/F13 redistributed to M2/M4/M3; all 141 frames now name a real developer. | Frame names, developer and tester columns all use real names. | — |
| **Q2** | **Confirm the payment gateway: "Tap Payments" (`tap.company`, Bahrain-licensed) — or the Taiwanese TapPay (Cherri Tech)?** | Different companies, different SDKs and flows. The brief says "Bahrain-based", which points to Tap Payments. | Build against **Tap Payments** behind a `PaymentGateway` protocol, so swapping later is one file |
| **Q3** | **Do we have a commercial registration / merchant account, or is sandbox-only correct?** | Live mode requires KYC; sandbox requires nothing and costs nothing. | **Sandbox only**, documented as a deliberate scope boundary |
| **Q4** | Is the app name **StudyForge** acceptable, or is there a preferred name? | The identity must be consistent across all three phases, so it should be locked in Phase 0. | StudyForge, with the logo concept in [doc 00 §5](00-MASTER-PLAN.md) |
| **Q5** | **Should I install the Cline agent skills now?** ([doc 07 §3](07-CLINE-SKILLS-AND-TOOLING.md)) | They materially improve the quality of generated SwiftUI and Firebase code. | Not installed — waiting for your go-ahead |
| **Q6** | Is iPad support required, or iPhone-only? | Changes layout work (2-column layouts, max-width rules) across ~141 frames. | **iPhone-first**, with layouts that survive a wider canvas |
| **Q7** | How far should Arabic/RTL go — full localisation or a proof-of-concept? | Full RTL roughly doubles copy work and adds layout risk on every screen. | **Full RTL on the 12 hero screens** plus a documented plan for the rest |
| **Q8** | Should the working SwiftUI app be built at all, or should we focus 100% on the graded Figma prototype? | The app is not graded, but it de-risks the demo and backs the Innovation claim. | **Build it** — it costs nothing extra because Cline writes it in parallel |

---

## 4. Assumptions

Stated explicitly, because an unstated assumption is where a plan breaks.

1. **Group size is 4 — approved by the tutor.** The brief's default is 5; the tutor confirmed 4 is acceptable for this group, so M5 was removed and their workstream redistributed ([doc 02 §2.1](02-FEATURE-LIST-OWNERSHIP.md)).
2. **All 4 members have a Mac capable of running Xcode 27** — or can pair with someone who does.
3. **The tutor will approve the F15 advanced feature.** If not, **F09 (live group revision arena)** is the substitution — it was deliberately designed to be strong enough to promote.
4. **Firebase Spark remains no-cost for the project's lifetime** — verified against the published limits in [doc 04 §5](04-TECH-ARCHITECTURE-COST.md).
5. **No App Store submission is required**, so Guideline 3.1.1 becomes a documented ethics discussion rather than a blocker.
6. **The on-device Apple Intelligence tier requires a real device for the demo.** A tier-1 fallback exists and the fallback screen is designed.
7. **The brief's "Xcode 26.6 or 27" requirement is satisfied** — local verification shows Xcode 27.0 with iOS 26.5 and 27.0 runtimes.
8. **Figma seats:** at least 5 collaborators, or a shared team project so every member can author their own page. A personal account with a single shared file is acceptable.
9. **Usability testing uses 5 consenting classmates**, not external participants.
10. **AI-generated content is a study aid, never assessed coursework** — the academic-integrity position in [doc 05 §8](05-DATA-MODEL-SECURITY.md).
11. **The 10th of November onward is reserved for QA only** — no new design work after the freeze.
12. **The tutor accepts a working SwiftUI app as supporting evidence** rather than scope creep (Q9 in the interview bank covers this).

---

## 5. Likely viva questions and prepared answers

The brief states every member must be able to present and explain *any* part of the app. These are the questions a marker is most likely to ask. **Rehearse the answers out loud.**

| Question | Key points in the answer |
|---|---|
| "Why Firebase and not a custom backend?" | No server to run or pay for · Auth with custom claims solves roles **server-side** · Firestore's realtime listeners power the live group quiz for free · offline persistence is built in, which is core to our SDG 9 story · the whole system sits inside a documented no-cost tier |
| "Why build a working app when the brief asks for a Figma prototype?" | The prototype is the graded artefact and it is complete and interactive. The app exists to **prove the design is feasible**, de-risk the live demo, and supply real evidence for the Innovation claim. It is deliberately a parallel, non-blocking track. |
| "How do you know the AI output is accurate?" | We never ask a free-recall question. Generation is **grounded** in the extracted text of the user's own material, every claim carries a **provenance citation** and a **confidence band**, low-confidence items are visibly flagged, and tutors can review AI content before students see it. |
| "What happens with no internet?" | The core loop works offline: extraction and generation run on-device, and Firestore persistence plus a SwiftData cache mean browsing, card review and cached quizzes all function. Edits queue and sync, and a designed offline banner shows what will sync. |
| "Isn't on-device AI weaker than a cloud model?" | For heavy reasoning, yes — which is exactly why we have a **router** rather than one model. Tier 0 handles summarisation and card generation well at zero cost; the router escalates to a cloud model when a task needs more reasoning or multimodal input, and degrades with a clear explanation rather than failing. |
| "How is this different from Quizlet or NotebookLM?" | Neither closes the loop. NotebookLM grounds well but has no mobile revision loop, no flashcards, no quizzes, no scheduling. Quizlet has cards and quizzes but is cloud-only, English-first, and not grounded in your own uploads. StudyForge makes upload → generate → schedule → practise → measure → adapt **one loop**. |
| "Where does the money come from if it's free to run?" | Tiers: Free (15 cloud generations/day, unlimited on-device), Plus BHD 1.900, Pro BHD 4.900. The on-device-first router means the free tier is genuinely viable rather than crippled — which is also our SDG 10 argument. |
| "Why not use Apple In-App Purchase instead of Tap?" | Legally, on the App Store we must — Guideline 3.1.1. That's why both implementations sit behind one `PaymentGateway` protocol. For this prototype we use Tap in sandbox because the client specifies a Bahrain gateway, and we document the conflict and the migration path instead of pretending it doesn't exist. |
| "How do you handle the ethics of AI in education?" | No auto-grading of assessed work · tutors review AI content before students see it · summaries carry an AI-drafted watermark · student material is never used for training · on-device-first for privacy · and the limitations are disclosed during onboarding. |
| "How did you test the security?" | Emulator-based rules tests including **negative** tests: a student cannot read another student's material, a non-tutor cannot write the review queue, and a client cannot modify its own subscription. Roles live in Auth custom claims, so authorisation is server-enforced. |
| "Which part is your own work versus AI-generated?" | The research, design, feature decomposition, screen inventory, testing and every decision are ours and are traceable in git with per-member authorship. Cline was used as a *coding tool*, exactly like an IDE assistant, and that is disclosed. |
| "What would you do differently with more time?" | Semantic search across all materials rather than the active one · offline on-device speech-to-text so recorded lectures become material · FSRS instead of SM-2, tuned on our own review data · tutor-authored rubrics so generated quizzes map to marking criteria. |

---

## 6. What is needed to proceed

**Answer Q2–Q5 in §3** and the plan is fully unblocked. Everything else has a safe default, so work can start immediately — beginning with [roadmap Phase 0](01-ROADMAP-PHASES-TODOLIST.md).



