# Run sheet — the 5-minute demo

> The executable form of [doc 11 §4](../../docs/11-APP-IMPLEMENTATION-VIVA.md). The timings and the
> step order are that script's; **the "if it fails" column is new, and it is the point of this file.**
>
> Print this. Hold it. Do not read the script from the doc on the day.
>
> **Revised 16 Oct 2026:** M5 joined the group on 14 Oct, and the script she inherited had **no step
> for her** while requiring that every member demos their own work. **F17's Recall Space now owns
> 2:20–2:45** (M5), and she joins the tutor/admin step for **F16**. The money shot moved from
> 0:25–2:55 to **0:25–3:10**. Rehearse against these figures.

| Field | Value |
|---|---|
| **Build** | commit `________`, installed with `bash tools/run-device.sh` |
| **Launch state** | `xcrun simctl launch <device> com.studyforge.app -seedDemo` — **verified 28 Oct 2026:** opens **signed in as the demo student with a finished profile**, so step 1 lands on the dashboard instead of the profile wizard. `-seedDemo` also seeds the library with `Material.samples`. **DEBUG only**, like every other hatch: a shipping build must never fabricate a session |
| **AI tier 1** | `GEMINI_API_KEY` set in the scheme — **free, and required for the money shot** (see below) |
| **Device** | |
| **Rehearsal count** | ____ / 3 |
| **Backup recording** | `________` (see [`backup-capture.md`](backup-capture.md)) |

### Before you start — the AI key (5 minutes, and it is free)

**Why it matters.** With no key, `GeminiCloudProvider.isConfigured` is false, tier 1 reports
`.unavailable(.notImplemented)`, and every AI screen shows its **"not available"** state. That state is
*designed* rather than broken — the app does not crash and tier 0 still works — but it is not the
demo. The difference is whether the money shot is the real thing.

**Where it comes from, and it costs nothing.** Google AI Studio → **Get API key**
(`aistudio.google.com/apikey`). One click with a Google account: **no credit card, no billing setup.**
[docs/04 §1](../../docs/04-TECH-ARCHITECTURE-COST.md) is built on exactly this — *"Zero-cost by
default: every service sits inside a free tier"* — and the project's estimated total cost is **$0**.

**How to set it.** Scheme → Run → Arguments → **Environment Variables**: `GEMINI_API_KEY = <key>`.
Preferred over `Info.plist` because an Xcode scheme's user data is gitignored, so the key sits in no
repository and in no diff. Two more nets: `tools/commit.sh` refuses any commit containing a
key-shaped string, and GitGuardian runs on every push.

**Two facts about the free tier, stated here rather than discovered on the day:**

1. **Free-tier content is used to improve Google's products** — the paid tier's is not. Fine for a
   demo with sample material; **do not run a real student's notes through it**, and do not let the
   privacy screen imply otherwise.
2. **Rate limits are per project**, and the daily quota resets at **midnight Pacific**. The app's own
   `AICostGovernor` caps per-user daily generations long before that binds, so a demo cannot reach it.

**And a correction worth knowing, because a marker may ask:** [docs/04 §5](../../docs/04-TECH-ARCHITECTURE-COST.md)
describes the *planned* tier 1 as **Firebase AI Logic**, whose key must be "enabled for the Firebase
project". The implementation went another way — the Firebase AI Logic SDK needs a `*.xcodeproj` edit,
and the lane guard forbids that file to **every** member including the owner — so tier 1 calls the
**Gemini Developer API directly over `URLSession`** (`Core/AI/GeminiCloudProvider.swift`). **Same key,
same free tier, and no Firebase wiring needed.**

## The two rules

1. **If a step fails, say your line and move on.** Do not retry in front of the marker, do not
   apologise, do not explain the cause. The line buys the next step.
2. **The money shot is 0:25–3:10.** If you are running late, protect the core loop and cut from the
   tail, never from the middle.

---

## The run

### 0:00–0:25 · Problem & promise — **M1**

One slide: the study-chaos problem, then the one-loop claim.

> **If the projector fails:** *"I'll talk you through this one and show it on the device."*

### 0:25–0:40 · Sign in as a student — **M1**

Login → student dashboard with real seeded data.

> **Measured 28 Oct 2026, in the Simulator, launched with `-seedDemo`:** the dashboard opens signed in as **Sara Ali**, with the streak badge and the four quick actions (Upload · Summarise · Quizzes · Study plan), and **`Study plan` reads "No plan yet"** while **`Flashcards · Due` reads 0**. That is the app's *designed* empty state rather than a broken screen — and for this script it may be the better opening, because step 2 is the upload that fills it. **If the demo needs the dashboard pre-populated instead, that is a seed across the plan, progress and deck stores — three types outside M1's lane**, so it is a decision rather than a defect, recorded in [docs/TODOLIST.md §7](../../docs/TODOLIST.md).

> **If sign-in fails:** *"The account is already signed in — here's the dashboard."* (Rehearsed: the
> app is left **already signed in** as the student before the demo starts, so this step is a
> fallback by default.)

### 0:40–1:15 · Upload → extract — **M1**

Real PDF from Files → appears in the library.

> **If the picker fails:** *"Here's one I imported earlier"* — and open the pre-loaded material. A
> demo course with materials **already processed** is on the device for exactly this.

### 1:15–1:55 · Generate a summary — **M2**

Length/style pickers → generation → **tap a provenance chip** → source page shown.

> **If generation fails:** *"Generation needs the model; here's the summary from this morning's run"*
> — open the saved summary. Then **still tap the citation chip**, because the citation is the part
> being demonstrated, not the streaming.

### 1:55–2:20 · Cards → review — **M2**

Generate 20 cards → review session → rate *Good* → the next-due interval changes.

> **If generation fails:** *"These are the cards from the same material"* — use the pre-generated
> deck. **The rating step still runs**, and it is the step that matters: it shows SM-2 responding.

### 2:20–2:45 · Recall Space — **M5**

Cross-deck due-today queue gathers cards from **more than one deck** → learning steps → the daily limit holds.

> **If the queue is empty:** *"These are the cards that were due this morning"* — the pre-seeded recall state is on the device. **The daily limit still shows**, because it is a settings rule rather than a data state, so the point survives an empty queue.

### 2:45–3:10 · Quiz → weakness radar → replan — **M3**

Take a quiz → scorecard → weakness radar → **accept the AI re-plan** → the calendar changes.

> **If the re-plan fails:** *"The plan is here — this is what it changed."* Show the before/after
> calendar from the recorded run. **The radar still shows**, because it is computed locally.

### 3:10–3:35 · Collaboration — **M4**

Second device joins the group space → live quiz → real-time leaderboard.

> **If the second device fails:** *"Both accounts are here on one device"* — switch account and show
> the leaderboard. **Say plainly that the live quiz is single-device in this build** if it is; the
> recorded limitation is in the docs, and an honest gap scores better than a pretence.

### 3:35–4:00 · AI Coach, the advanced feature — **M2 + M3**

Ask a question grounded in the uploaded material → answer with citation → tap the citation → source.

> **If the on-device model is unavailable:** *"The model isn't available on this device, so here's
> the fallback it shows — and here's the recorded answer with its citation."* **This fallback screen
> is a feature, not a failure**, and saying so turns a failure into a demonstration of the tiering.

### 4:00–4:20 · Payments, sandbox — **M3**

Paywall → plan → order summary in BHD → Tap card → success → a feature unlocks.

> **If the gateway fails:** *"Payments run in sandbox — here's the recorded authorisation."* Then
> walk the order summary and the rules that protect the collection, which is the engineering point.

### 4:20–4:40 · Tutor & admin view — **M4 + M5**

Tutor review queue approving AI content; admin KPI dashboard; **and M5 shows F16's permanent-moderator rule** — a moderator who cannot be removed by another member.

> **If the queue is empty:** *"This is the queue after the morning's approvals"* — the pre-seeded
> state is on the device. An empty queue is still a valid screen; **do not** manufacture items live.
>
> **If the moderator rule is hard to show live:** *"Here's the rule and the test that covers it"* —
> open the rule and the passing test. A security-shaped rule is often better demonstrated by its
> guard than by clicking through it, and saying so is honest rather than evasive.

### 4:40–5:00 · Architecture & cost — **M1**

One slide: the 3-tier AI router, the $0 cost model, the 4 roles, the security rules.

> **If time is short:** this slide is the one to **cut short, never skip** — the router and the cost
> model are the two claims the marker is most likely to probe.

---

## After the run

| # | Check | ✅ |
|---|---|---|
| 1 | Every step ran, or its fallback line was said | ☐ |
| 2 | Nobody apologised or retried in front of the marker | ☐ |
| 3 | The money shot (0:25–3:10) was protected | ☐ |
| 4 | The total landed within 5:00 | ☐ |
| 5 | Any step that failed is **written into [`regression-log.md`](regression-log.md)** | ☐ |

---

## Owner's tasks before the VIVA — the things only M1 can do

**Recorded 28 Oct 2026, for the next session.** Everything here is either a human action or a review
nobody else can give. Nothing in the *engineering* is blocked.

| # | Task | Why it matters | Time |
|---|---|---|---|
| 1 | **Set `GEMINI_API_KEY`** — see the pre-flight section above. Free, from Google AI Studio, no card | Without it tier 1 reports `.unavailable` and every AI screen shows **"not available"**. The demo still runs, but the money shot is not the real thing | 5 min |
| 2 | **Re-export `deliverables/prototype/StudyForge.fig`** (Figma → File → Save local copy) | The committed export is **8 components behind**: its canvas is dated **15:00**, and the component work landed from **15:19** | 2 min |
| 3 | **Chase one review** on **#148** (the guard fix — M3 is blocked on it for her contribution log), then **#149** and **#150** | `develop` requires one approving review and M1 cannot review his own PRs. It is the only thing between here and a closed queue | 10 min |
| 4 | **Book the §17.3 usability test — 5 participants + a SUS score** | **Two of the three** items the submission gate still reports as open (`dd-usability`, `p9-0304`), and the only one that needs other people. It cannot be compressed, so it sets the real deadline | 1–2 days |
| 5 | **P5-16 — the 3-minute walkthrough recording** | The last Phase 5 item needing nothing but a screen recorder; the prototype is fully wired (320 reactions, 37 Smart Animate) | 30 min |
| 6 | **Portal submit, then tick `p9-1819`** | The last gate item. The `prototype-v1` tag already exists | 30 min |
| 7 | **Decide the demo seed** — the dashboard's empty state (recommended, and the better opening) or pre-populated plan/progress/decks | Recorded in the "Measured 28 Oct 2026" note above as a **decision**, not a defect | 5 min |

**Not on this list, because it is not M1's:** R25 (M3's — four lines, two files, one test) and
everything in `docs/TODO-M2`/`M4`/`M5`.
