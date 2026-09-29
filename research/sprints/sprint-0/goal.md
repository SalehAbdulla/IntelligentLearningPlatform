# Sprint S0 — Foundation & Requirements

| Field | Value |
|---|---|
| **Sprint** | **S0** |
| **Dates** | Mon 28 Sep – Sun 4 Oct 2026 |
| **Sprint lead** | M1 — Saleh Abdulla |
| **Theme** | Foundation, identity, research start, feature definition, tutor interview |

## Sprint goal — one sentence

> **One sentence:** *"Everything is decided and unblocked — the app builds and runs on a device, Firebase is live, the team and 15 features are signed off, and the tutor interview is booked with the advanced feature proposed for approval."*

## Demoable outcome (the sprint review must show this working)

1. The Xcode 27 app **builds and launches** on a physical device, showing the design-system component gallery.
2. **Firebase project is live** on Spark, with Auth enabled and a `users/{uid}` document written by signing up.
3. `firestore.rules` deployed in a **deny-by-default** state, with one passing emulator test.
4. The **feature table is signed off** by all four members, and the Figma file exists with 9 named pages.

## Fixed constraints inside this sprint

- [ ] None. This is the only sprint without an external deadline.

## Per-member tasks

| Member | Task ID | What they own this sprint | Evidence they will produce |
|---|---|---|---|
| **M1** Saleh | S0-M1 | Firebase project (`studyforge-it8108`, Spark, bucket `us-central1`); Auth enabled; `firestore.rules` skeleton; requirements for F01, F02, F14 | `firebase/` config · rules file · `rules-tests.mjs` passing · 3 feature specs |
| **M2** Mohammed | S0-M2 | **AI feasibility spike**: `FoundationModels` availability on a real Apple-Intelligence device vs the Simulator; first grounded prompt; specs for F03, F04, F05, F11 | `research/spikes/foundation-models.md` · throwaway demo · prompt drafts |
| **M3** Tasbeeh | S0-M3 | Xcode 27 project scaffold (iOS 26 target, Swift 6); `AppContainer` DI; `DesignSystem.swift` token gallery; navigation shell; specs for F06, F07, F13 | Building app · `DesignSystem.swift` · specs |
| **M4** Shahad | S0-M4 | Figma file + **9 pages** + variables + component library skeleton; specs for F08, F09, F10, F12 | Figma file · component board · specs |

## Risks this sprint

| Risk | Likelihood | Response |
|---|---|---|
| On-device Apple Intelligence unavailable on the demo device | Medium | M2's spike answers this in week 1; tier-1 fallback already designed ([doc 04 §4](../../../docs/04-TECH-ARCHITECTURE-COST.md)) |
| Figma component library becomes a time sink | Medium | Time-box to half a day; it must only cover the components the P0 frames need |
| Firebase setup blocked on account/billing | Low | Spark only; no billing required. **No Cloud Functions this sprint** |
| Sprint boundaries not yet confirmed with the tutor | Medium | Confirm at the interview (Q9) and adjust |

## Definition of done

- [ ] The demoable outcome demos live, from the real app
- [ ] Every member demonstrated something they personally built or fixed
- [ ] Every member's contribution log is written and evidence-linked
- [ ] Slipped scope recorded and re-planned
- [ ] `main` builds clean, zero warnings
- [ ] Sprint artefacts committed to this folder

---

## Sprint artefacts checklist

- [x] `goal.md` (this file)
- [ ] `board.png` — task board snapshot at sprint end
- [ ] `review/` — screenshots or recording of each member demoing their own work
- [ ] `retro.md` — one thing to keep, one to change
- [ ] `saleh-contribution.md` · `mohammed-contribution.md` · `tasbeeh-contribution.md` · `shahad-contribution.md`

---

## S0 progress log

**Updated:** after the backend increment.

### ✅ Complete

| Task | Owner | Evidence |
|---|---|---|
| Xcode 27 project scaffold + design tokens + gallery | M3 | `ios/StudyForge/`, `xcodebuild` BUILD SUCCEEDED |
| Backend configuration: rules, indexes, emulator config | M1 | `backend/` — **58 rules tests, 0 failures** |
| Repo restructured into `ios/` + `backend/` | M1 | PR #7, decision D20/D21 |

### ⛔ Blocked on the human (cannot be automated)

| Task | Why it needs a person | Time |
|---|---|---|
| Create Firebase project `studyforge-it8108` | Requires a Google account and the console UI | ~5 min |
| Storage bucket region **`us-central1`** | ⚠️ A Bahrain-region bucket leaves the no-cost quota and starts billing | ~1 min |
| Enable Auth (Email/Password + Apple), Firestore, Storage, FCM, Crashlytics | Console-only | ~5 min |
| Download `GoogleService-Info.plist` → `ios/StudyForge/StudyForge/` | Console-only; already gitignored | ~1 min |

### ⬜ Next (I can do these)

| Task | Owner | Note |
|---|---|---|
| Firebase SPM packages wired into the Xcode project | M1 | Needs `GoogleService-Info.plist` to actually initialise |
| `AuthService` protocol + Firebase impl + mock | M1 | Starts F01 — the first real feature |
| **AI feasibility spike** (`AIProvider`, on-device availability, fallback) | M2 | **Highest technical risk in the project** — protects the demo money-shot |
| Figma file: 9 pages + variables + component library | M4 | Needs the design decisions in docs/06, already frozen |

### Sprint exit gate (unchanged)

> App builds on device · Firebase live · feature table signed off · tokens frozen

Three of those four are now true. **"Firebase live" is the only one left, and it is the human step above.**

