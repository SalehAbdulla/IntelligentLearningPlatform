# Feature Cheat Sheet, Fatema Ghareeb (M5)

> One page to keep open in the VIVA. Fill it in from now to the feature freeze.
> **Filled in from the day I joined, 14 Oct 2026**, so the evidence is dated rather than assembled at the end.

| Field | Value |
|---|---|
| **Member** | Fatema Ghareeb (M5) |
| **Student ID** | `202304804` |
| **Features I develop** | **F16** Admin-Moderated Group Chat · **F17** Active Recall Space |
| **Features I test** | **F01**, **F05**, **F13** |
| **Sprints I contributed in** | S0 ✗ · S1 [x] (joined mid-sprint) · S2 [ ] · S3 [ ] · S4 [ ] · S5 [ ] |

---

## My features

### F16, Admin-Moderated Group Chat

- **What it does, in three sentences** (no jargon, if you can't say it plainly you don't own it):
  1. Every group's chat carries a **permanent moderator** — an admin who is always a member of that space.
  2. The moderator cannot be removed or demoted by the group owner, and is visibly badged in the member list and the chat.
  3. The moderator can hide, delete, pin or flag any message, with a captured reason, and every action is written to an append-only audit log.
- **Key source files:**
  - `Core/Groups/Moderation/GroupModeration.swift` (the model + the "cannot be removed" policy)
  - `Features/Groups/GroupChatView.swift` · `GroupChatViewModel.swift` (the chat surface, extended)
  - `Features/Groups/Moderation/` (the moderation screens)
- **Firestore collections and Storage paths touched:** `groups/{id}/messages` (gains `hiddenAt`, `hiddenBy`, `hiddenReason`, `pinnedBy`) · `groups/{id}/moderation/{actionId}` · `groups/{id}/members/{uid}` (moderator role) · `auditLog/{id}`
- **The hard part and how I solved it:** modelling "the admin is always there" so that it is **enforced, not merely displayed** — the rules refuse a write that removes or demotes the moderator, so the guarantee lives in the security layer rather than in the UI.
- **A trade-off I made:** I chose a **separate moderation store** over adding moderator fields to `StudyGroup`, because it keeps my lane disjoint from M4's F09 files.
- **A known limitation, and what I'd do about it:** real-time delivery of a moderation action needs a live backend; today the local-first store means a second device sees the change on next load.
- **Loading / empty / error / offline behaviour:** moderation actions taken offline **queue** and resolve on reconnect; a hidden message becomes a tombstone rather than disappearing.
- **Who tested it, and what they found:** M4 (Shahad), primary tester.

### F17, Active Recall Space (Anki-style)

- **What it does, in three sentences:**
  1. One **Recall Space** gathers everything due across **every** deck, instead of making you open decks one at a time.
  2. It adds Anki's mechanics the per-deck review lacks: **learning steps** (1m → 10m), **daily new/review limits**, and the new / learning / young / mature card states.
  3. It shows **retention, a review heatmap and a streak**, and every interval still comes from the existing SM-2 engine.
- **Key source files:**
  - `Core/Recall/RecallQueue.swift` (the cross-deck due-today queue)
  - `Core/Recall/RecallSettings.swift` (learning steps, daily limits, the four card states)
  - `Core/Recall/RecallSettingsStore.swift` · `FileRecallSettingsStore.swift` · `InMemoryRecallSettingsStore.swift` (where the learner's options live — the store seam)
  - `Features/Recall/RecallSpaceViewModel.swift` (O01's presentation logic: one queue across every deck)
  - `Core/Scheduling/SpacedRepetition.swift` (**not mine — I call it, I never duplicate it**)
- **Firestore collections touched:** `decks/{id}/cards` (the `sr` state gains `learningStep`) · `recallSettings/{uid}`
- **The hard part and how I solved it:** ordering a queue that mixes **new, learning and review** cards correctly, so a card in a learning step comes back inside the same session while a mature card waits days.
- **A trade-off I made:** I chose to **call** `SpacedRepetition.nextState` rather than re-implement Anki's SM-2 variant, because one scheduler is testable and two would drift.
- **A known limitation, and what I'd do about it:** Anki's full statistics (forecast, hourly breakdown) are trimmed to retention, maturity, heatmap and streak.
- **Loading / empty / error / offline behaviour:** "nothing due" shows the next due time; the daily limit hit explains itself; the whole space works offline from the local store.
- **Who tested it, and what they found:** M2 (Mohammed), primary tester.

---

## Code walkthrough, rehearsed

- **Entry point** → where the screen is registered and how you navigate to it: the Recall Space is reached from the Decks list; the moderation screens are reached from the group chat.
- **The view** → structure, what it renders from, what it delegates: `GroupChatView` renders the moderator banner and the message list, and delegates every moderation action to `GroupChatViewModel`.
- **The view model** → state, `LoadState` handling, async calls: `RecallSpaceViewModel` reads every deck and the learner's options together, builds the queue once and rebuilds it on a scope or settings change (no second store read); the session screens sit on top of it.
- **The repository** → the store seam: `ModerationStore` / `RecallSettingsStore`, with File and InMemory implementations, exactly like every other store in this codebase.
- **The data contract** → which collections, which rules govern them: `groups/{id}/moderation` is append-only; `recallSettings/{uid}` is owner-only.
- **What happens when it fails** → the specific error path I'd demo: an owner trying to remove the moderator gets a refusal **with the reason shown**, not a silent no-op.

---

## Where things live, the 10-second drill

| Feature | Screen ID | View file | ViewModel | Repository | Collections |
|---|---|---|---|---|---|
| F16 | N01–N06 | `Features/Groups/GroupChatView.swift` | `GroupChatViewModel` | `ModerationStore` | `groups/{id}/moderation` |
| F17 | O01–O07 | `Features/Recall/` (O01 `RecallSpaceView` is the next slice) | `RecallSpaceViewModel` ✓ — the session view model comes with O02 | `RecallSettingsStore` → `FileRecallSettingsStore` · `InMemoryRecallSettingsStore` | `recallSettings/{uid}` |

**Drill:** pick a random row, navigate to the file, and name its collection within ten seconds. Do this weekly.

---

## Hard questions I should expect

| Question | My prepared answer |
|---|---|
| "Why did you build it this way?" | The moderator guarantee is enforced in the security rules, not the UI, because a UI-only rule can be bypassed by a direct write. |
| "What happens with no internet?" | The Recall Space works entirely from the local store; moderation actions queue and resolve on reconnect. |
| "What if the AI returns nonsense?" | F16 and F17 generate no AI content — they are safety and scheduling features. |
| "What does this specific function do?" | `SpacedRepetition.nextState(_:rating:now:)` — it is pure, so the same state and rating always give the same interval. |
| "What doesn't work?" *(always have a real answer)* | Real-time multi-device moderation needs a live backend; today a second device sees the change on next load. |
| "What would you change with more time?" | Anki's full statistics, and a realtime presence feed for the moderator badge. |

---

## VIVA evidence I can point to

- [ ] Merged PR(s): links
- [ ] Hand-written commits: `git log --author="Fatema" --grep="hand:"`
- [ ] Test log(s) for F01, F05, F13
- [ ] Sprint review recording(s) where I demoed my own work
- [ ] Figma frames named with my student ID (142–154)
