# Run sheet — the 5-minute demo

> The executable form of [doc 11 §4](../../docs/11-APP-IMPLEMENTATION-VIVA.md). The timings and the
> step order are that script's; **the "if it fails" column is new, and it is the point of this file.**
>
> Print this. Hold it. Do not read the script from the doc on the day.

| Field | Value |
|---|---|
| **Build** | commit `________`, installed with `bash tools/run-device.sh` |
| **Device** | |
| **Rehearsal count** | ____ / 3 |
| **Backup recording** | `________` (see [`backup-capture.md`](backup-capture.md)) |

## The two rules

1. **If a step fails, say your line and move on.** Do not retry in front of the marker, do not
   apologise, do not explain the cause. The line buys the next step.
2. **The money shot is 0:25–2:55.** If you are running late, protect the core loop and cut from the
   tail, never from the middle.

---

## The run

### 0:00–0:25 · Problem & promise — **M1**

One slide: the study-chaos problem, then the one-loop claim.

> **If the projector fails:** *"I'll talk you through this one and show it on the device."*

### 0:25–0:40 · Sign in as a student — **M1**

Login → student dashboard with real seeded data.

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

### 1:55–2:25 · Cards → review — **M2**

Generate 20 cards → review session → rate *Good* → the next-due interval changes.

> **If generation fails:** *"These are the cards from the same material"* — use the pre-generated
> deck. **The rating step still runs**, and it is the step that matters: it shows SM-2 responding.

### 2:25–2:55 · Quiz → weakness radar → replan — **M3**

Take a quiz → scorecard → weakness radar → **accept the AI re-plan** → the calendar changes.

> **If the re-plan fails:** *"The plan is here — this is what it changed."* Show the before/after
> calendar from the recorded run. **The radar still shows**, because it is computed locally.

### 2:55–3:25 · Collaboration — **M4**

Second device joins the group space → live quiz → real-time leaderboard.

> **If the second device fails:** *"Both accounts are here on one device"* — switch account and show
> the leaderboard. **Say plainly that the live quiz is single-device in this build** if it is; the
> recorded limitation is in the docs, and an honest gap scores better than a pretence.

### 3:25–3:55 · AI Coach, the advanced feature — **M2 + M3**

Ask a question grounded in the uploaded material → answer with citation → tap the citation → source.

> **If the on-device model is unavailable:** *"The model isn't available on this device, so here's
> the fallback it shows — and here's the recorded answer with its citation."* **This fallback screen
> is a feature, not a failure**, and saying so turns a failure into a demonstration of the tiering.

### 3:55–4:20 · Payments, sandbox — **M3**

Paywall → plan → order summary in BHD → Tap card → success → a feature unlocks.

> **If the gateway fails:** *"Payments run in sandbox — here's the recorded authorisation."* Then
> walk the order summary and the rules that protect the collection, which is the engineering point.

### 4:20–4:40 · Tutor & admin view — **M4**

Tutor review queue approving AI content; admin KPI dashboard.

> **If the queue is empty:** *"This is the queue after the morning's approvals"* — the pre-seeded
> state is on the device. An empty queue is still a valid screen; **do not** manufacture items live.

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
| 3 | The money shot (0:25–2:55) was protected | ☐ |
| 4 | The total landed within 5:00 | ☐ |
| 5 | Any step that failed is **written into [`regression-log.md`](regression-log.md)** | ☐ |
