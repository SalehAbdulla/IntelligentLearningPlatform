# 10 — Sprint Plan & Individual Contribution

> **The Sprint component: 10% of the course, assessed individually.**
> Verbatim: *"Sprints (10%) – Individual assessment of each student's contribution and progress during the implementation of the group project."*

---

## 1. What is actually being assessed

Read the sentence closely — three words carry the whole design of this document:

| Word | Implication | Consequence for us |
|---|---|---|
| **Individual** | Not a group mark. Four separate marks | A strong teammate does **not** raise your score. Your own evidence is all that counts |
| **Contribution** | Work you personally did, produced, reviewed or verified | Must be attributable, per person, with timestamps |
| **Progress** | Continuous movement, not one end-of-project burst | Evidence must appear **across** the project, not in a single dump |

**Therefore:** every member must generate a visible, dated trail of their own work through every sprint — and it must be work they can *defend* in the VIVA.

---

## 2. The uncomfortable truth this component creates

Cline writes the code. **Sprints assess what *you* did.** If the honest answer is "I prompted an AI," then a 10% component evaporates and — far worse — the 60% must-pass VIVA becomes very hard, because a marker can ask *"show me the code for your feature and explain this line."*

So this plan defines contribution as the work that is genuinely the team's:

| Counts as your contribution | Does **not** count |
|---|---|
| Writing the specification, flow and acceptance criteria for your feature | Typing a prompt and accepting the output unread |
| **Reviewing and correcting** AI-generated code, with your corrections documented | Commits that only reformat or rename files |
| Hand-writing the parts that matter (scheduling maths, SM-2 intervals, security rules, state machines) | A single large commit at the sprint deadline |
| Being the named **tester** for a feature and producing a real test log | "Attended the meeting" with no artefact |
| Debugging an integration failure to root cause | Work you cannot explain on demand |
| Authoring Figma frames named with your own student ID | Duplicated work a teammate already did |
| Writing documentation, references and test evidence | Anything you could not demo live |

> **The comprehension contract (§9) exists to make this real rather than cosmetic.** It is not busywork — it is the mechanism that turns "Cline wrote it" into "I own it, I can explain it, and I can change it."

---

## 3. Sprint cadence

> ⚠️ **Assumption to confirm:** the sprint boundaries and the final app/VIVA date are **not** stated in the Design Document brief. The cadence below assumes **five 2-week sprints** starting 28 Sep. **Confirm both with the tutor in the first interview** ([doc 01 §4](01-ROADMAP-PHASES-TODOLIST.md)) and adjust this table.

| Sprint | Dates | Theme | Demoable outcome at sprint review |
|---|---|---|---|
| **S0** | 28 Sep – 4 Oct | Foundation & requirements | App builds and runs; Firebase project live; feature table signed off; design system tokens frozen |
| **S1** | 5 Oct – 18 Oct | **Core loop MVP** | Sign up → upload a real PDF → get a real summary → generate cards → review them, on device |
| **S2** | 19 Oct – 1 Nov | **Assessment engine** | Generate + take a real quiz; study plan generated; progress dashboard populated from real data |
| **S3** | 2 Nov – 15 Nov | **Collaboration & monetisation** | Two accounts share a folder; live group quiz runs across two devices; Tap sandbox payment succeeds |
| **S4** | 16 Nov – 29 Nov | **Intelligence & polish** | F15 AI Coach answering grounded questions with citations; offline mode; RTL; accessibility pass |
| **S5** | 30 Nov – 13 Dec | **Hardening & VIVA** | Feature freeze; full regression; rehearsed demo; every member presents a feature they did *not* build |

**Design Document deadline (22 Oct)** falls inside S2. **Prototype deadline (12 Nov)** falls inside S3. Both are handled as fixed constraints inside those sprints — see [doc 01](01-ROADMAP-PHASES-TODOLIST.md).

**Rule:** a sprint is only "done" if the demoable outcome actually demos. Slipped scope moves to the next sprint and is recorded — never quietly dropped.

---

## 4. Per-sprint, per-member allocation

Each cell names the work that member personally owns that sprint, plus the evidence it produces. **This table is the spine of the sprint assessment** — it is what each member is judged on.

### S0 · Foundation & requirements (28 Sep – 4 Oct)

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | Firebase project + Auth + Firestore/Storage rules skeleton; requirements for F01, F02, F14 | `firebase/` config, rules file, feature specs |
| **M2** Mohammed | AI feasibility spike: `FoundationModels` on a real device vs the Simulator, prompt prototype; specs for F03, F04, F05, F11 | Spike report, throwaway demo, prompt drafts |
| **M3** Tasbeeh | Xcode 27 project scaffold, `AppContainer` DI, `DesignSystem.swift` tokens, navigation shell; specs for F06, F07, F13 | Building app, token file, specs |
| **M4** Shahad | Figma file + 9 pages + component library + variables; specs for F08, F09, F10, F12 | Figma skeleton, component board |

### S1 · Core loop MVP (5 Oct – 18 Oct)

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | **F01** auth end-to-end (sign-up, OTP, role routing) + **F02** upload → compress → Vision OCR → Storage | Two features merged, test logs from M4/M3 |
| **M2** Mohammed | **F03** summary generation (tier 0 + tier 1) + **F04** flashcard generation with `@Generable` | Two features merged, prompt-eval notes |
| **M3** Tasbeeh | **F06** plan-wizard skeleton + **F07** activity-event writes; app-wide `LoadState` handling | Two skeletons, loading/empty/error states |
| **M4** Shahad | Figma P0 frames for groups A, C, D, E; **F10** bookmarking | Frames named per the rule, one merged feature |

### S2 · Assessment engine (19 Oct – 1 Nov) — *Design Document due 22 Oct*

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | **F12** admin shell + **F14** notifications; security-rules hardening + **emulator negative tests** | Merged features, passing rules tests |
| **M2** Mohammed | **F05** quiz generation + attempts + `topicMastery` writes; **F11** tutor review queue | Two features merged, test logs |
| **M3** Tasbeeh | **F06** adaptive re-planning + **F07** dashboard + weakness radar | Merged features, re-plan recording |
| **M4** Shahad | **F08** shared folders; Figma P0 for groups F, G, I; usability-test plan; Design Document assembly support | Merged feature, frames, test plan, doc sections |

### S3 · Collaboration & monetisation (2 Nov – 15 Nov) — *Prototype due 12 Nov*

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | Realtime listeners for live sessions; rules for folders/groups; review-queue and moderation wiring | Merged PRs, rules tests |
| **M2** Mohammed | **F09** group-quiz generation; **F15** RAG index (chunking + `NLEmbedding` + retrieval) | Merged PRs, retrieval-accuracy log |
| **M3** Tasbeeh | **F13** Tap payments: SDK, order build, Cloud Function `createCharge`, webhook verification, entitlements | Sandbox payment recording, function logs |
| **M4** Shahad | **F09** live-quiz UI + leaderboard; **F12** moderation queue; **Figma wiring + `.fig` export + submission** | Merged PRs, submitted prototype |

### S4 · Intelligence & polish (16 Nov – 29 Nov)

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | **F14** local reminders + deep links; offline sync queue + conflict handling | Merged PRs, aeroplane-mode recording |
| **M2** Mohammed | **F15** coach UI, citation sheet, explain-level toggle, prompt templates in Firestore; AI quality review | Merged PRs, before/after prompt eval |
| **M3** Tasbeeh | AI cost governor, `aiCache`, admin AI-config screen; Instruments performance pass | Merged PRs, Instruments captures |
| **M4** Shahad | RTL Arabic, accessibility (VoiceOver / AX5 / contrast), dark mode, taxonomy management | Accessibility report, RTL capture |

### S5 · Hardening & VIVA (30 Nov – 13 Dec)

| Member | Owns | Evidence produced |
|---|---|---|
| **M1** Saleh | Security audit + rules re-test; regression of F01/F02/F12/F14; demo-data sealing | Audit report, test log |
| **M2** Mohammed | AI accuracy review across all generated artefacts; regression of F03/F04/F05/F11/F15 | Accuracy report, test log |
| **M3** Tasbeeh | Performance and stability pass; crash-free verification via Crashlytics; regression of F06/F07/F13 | Stability report, test log |
| **M4** Shahad | VIVA deck, demo script, **recorded walkthrough of every feature**, rehearsal coordination | Deck, script, recordings |

> **Every member must appear in every sprint.** A blank cell is a lost individual mark — and it is visible to the marker.


---

## 5. Contribution evidence rules

The marker needs to attribute work to **you**. These are the only forms of evidence that count.

| # | Evidence type | Where it lives | Why it is credible |
|---|---|---|---|
| 1 | **Authored commits and PRs** on features you own | `git log --author`, GitHub PR list | Timestamped, attributable, code-level |
| 2 | **Sprint review demo** of your own work | Recorded review in `research/sprints/sprint-N/` | Shows you can operate what you claim to have built |
| 3 | **Review notes on AI-generated code** — what was wrong, what you changed and why | `research/reviews/` + the commit that fixes it | Proves genuine engineering judgement, not acceptance |
| 4 | **Test logs** for the features you test (per [doc 02 §7](02-FEATURE-LIST-OWNERSHIP.md)) | `research/testing/` | Independent verification by a named person |
| 5 | **Design and decision documents** you authored | `docs/` history, decision log | Design work is contribution |
| 6 | **Issue-board items you closed**, with linked PRs | GitHub Issues | Shows planned → done traceability |
| 7 | **Figma frames named with your own student ID** | The Figma file | The brief's own naming rule makes authorship provable |
| 8 | **Hand-written code** on the parts that matter (SM-2, scheduler, rules, state machines) | Commits you authored directly, not via Cline | The strongest possible evidence |

**Deliberately excluded:** prompting alone · reformatting-only commits · a single end-of-sprint commit dump · meeting attendance without an artefact · work you cannot demo or explain.

### 5.1 Commit discipline that makes attribution possible

```
feat(F04): SM-2 interval calculation and lapse handling      <- who did it is in --author
fix(F13): verify Tap webhook signature before writing entitlement
test(F12): add negative security-rules test for subscription write
docs(F06): plan wizard flow diagram and acceptance criteria
```
One feature per PR. Conventional Commits so the history is readable as a contribution record. **Never** push another member's work under your own name.

---

## 6. Contribution log template

Each member keeps their own log per sprint. This is the artefact you hand over if contribution is ever questioned.

**File:** `research/sprints/sprint-<N>/<yourname>-contribution.md`

| Date | Task / feature ID | What I personally did | Evidence (commit / PR / file) | Hours | Blocker |
|---|---|---|---|---|---|
| 07 Oct | F02 | Wrote the chunking spec; reviewed Cline's OCR pipeline and fixed the page-offset bug | PR #14, commit `a1b2c3d` | 4 | none |
| 09 Oct | F02 | Tested 6 scan types; found 2 OCR failures, raised bugs | `research/testing/F02-log.md` | 2 | needs a clearer scan sample |
| 12 Oct | — | Sprint review: demoed upload → OCR → library | `research/sprints/sprint-1/review.mp4` | 1 | — |

**Rules:** log within 24 h · one row per work session · always link evidence · never back-fill a whole sprint at once (it reads as fabricated and defeats the point).

---

## 7. Sprint ceremonies

| Ceremony | When | Duration | Output |
|---|---|---|---|
| **Sprint planning** | Monday, sprint start | 45 min | Sprint goal + task board with per-member assignments |
| **Async stand-up** | Every weekday | 5 min | 3 lines in the team channel: done · doing · blocked |
| **Mid-sprint check** | Thursday | 20 min | Unblock, re-scope, protect the sprint goal |
| **Sprint review & demo** | Final Sunday | 60 min | **Every member demos their own work.** Recorded |
| **Retrospective** | After the review | 30 min | One thing to keep, one to change |

**Evidence committed to `research/sprints/sprint-<N>/`:** `goal.md` · `board.png` · `review.mp4` (or screenshots) · `retro.md` · each member's contribution log.

---

## 8. Definition of done for a sprint

A sprint counts as complete only when **all** of these hold:

- [ ] The sprint's **demoable outcome actually demos**, live, from the real app
- [ ] Every member demonstrated something they personally built or fixed
- [ ] Every member's contribution log is written and evidence-linked
- [ ] Slipped scope is explicitly recorded and re-planned (not silently dropped)
- [ ] The app builds clean on `main` with **zero warnings** and tests passing
- [ ] Sprint artefacts committed to `research/sprints/sprint-<N>/`


---

## 9. The comprehension contract

This is the most important rule in the project, because it protects both the individual 10% and the must-pass 60%.

**The risk it addresses:** if Cline writes the code and nobody reads it, then come the VIVA a marker can ask *"open your feature's view model and explain what this function does"* — and the answer "the AI wrote it" fails a must-pass component. The comprehension contract prevents that by making understanding a *gate on merging*, not an afterthought.

| # | Rule | Enforced by |
|---|---|---|
| 1 | **No PR is merged for a feature you cannot explain.** Every PR description must contain a 3-sentence plain-English summary of what the code does and why. | PR template |
| 2 | **Hand-modify your own feature at least once per sprint** without Cline — change a label, fix a bug, adjust a layout, add a validation rule. | Commit labelled `hand:` |
| 3 | **Weekly "explain it" drill (15 min):** one member opens *another* member's feature and explains it from the code, unprompted. | Rotation, logged |
| 4 | **Record a 2-minute walkthrough of your own feature each sprint**, narrating what it does and how it works. | `research/sprints/sprint-N/` |
| 5 | **Maintain a one-page "my feature" cheat sheet:** purpose · key files · data touched · the hard parts · known limitations. | `research/cheatsheets/<name>.md` |
| 6 | **Be able to name the trade-offs** in your feature — what you chose, what you rejected, and why. | Cheat sheet + rehearsal |

**Why rule 5 matters most:** in the VIVA, a marker asking "explain any part of the app" is really testing whether you know *where things live and why*. A cheat sheet per member turns that from a risk into an advantage.

---

## 10. Risks specific to the sprint component

| Risk | Mitigation |
|---|---|
| One member does most of the work; others have thin evidence | The §4 allocation table guarantees every member owns features in every sprint. The Monday stand-up asks each person for their own tasks |
| Contribution is real but undocumented | Contribution logs are due within 24 h and are part of the sprint's definition of done |
| End-of-sprint commit dumps look fabricated | Work in small commits daily; the review requires a live demo of your own work |
| A member can't explain their feature at review | Rules 1–4 of the comprehension contract catch this from sprint 1, not at the VIVA |
| Sprint dates assumed wrongly | Confirm both cadence and the demo date with the tutor in the first interview |
| Cline does the work, so no one has real contribution | Rules 2 and 3 force genuine engineering activity, and the §2 table defines what legitimately counts |

