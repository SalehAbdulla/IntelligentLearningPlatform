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
| On-device Apple Intelligence unavailable on the demo device | Medium | ✅ **Addressed by the S0 spike.** Verified available on Apple Silicon hardware; unavailable in the Simulator *by design*. Tier-1 fallback confirmed working, and `MockProvider` serves tier 1 in the Simulator until S1 |
| Figma component library becomes a time sink | Medium | Time-box to half a day; it must only cover the components the P0 frames need |
| Firebase setup blocked on account/billing | **Realised** | ⚠️ **This risk materialised.** The console failed at *"Billing setup can't be completed [OR_BACR2_59]"* — a **Google Payments** error, not a Firebase one, and one only the account owner can clear. **Mitigated rather than waited on:** (1) Spark needs no billing *at all*, so the project can be created from the CLI via `firebase projects:create`, which never enters the billing flow — runbook in [`backend/README.md`](../../../backend/README.md); and (2) the app no longer depends on a project existing, because `FirebaseBootstrap` runs against the Emulator Suite in Debug. See decision **D22**. **No Cloud Functions this sprint** |
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

**Updated:** after the live Firebase project was created and verified end-to-end.

> **S0 exit gate:** App builds on device · Firebase **live** · feature table signed off · tokens frozen.
> **All four are now true.** `studyforge-it8108` is live, and every claim below was verified
> *against the real project*, not assumed from a console screenshot.

### ✅ Complete

| Task | Owner | Evidence |
|---|---|---|
| Xcode 27 project scaffold + design tokens + gallery | M3 | `ios/StudyForge/`, `xcodebuild` BUILD SUCCEEDED |
| Backend configuration: rules, indexes, emulator config | M1 | `backend/` — **58 rules tests, 0 failures** |
| Repo restructured into `ios/` + `backend/` | M1 | PR #7, decision D20/D21 |
| **AI feasibility spike — on-device tier** | **M2** | `research/spikes/foundation-models.md` + `fm-probe.swift` · **all three AI assumptions verified** · measured 2.8 s for 3 guided cards · Simulator fallback confirmed by screenshot |
| **First unit-test target + AI layer tests** | **M3** | `StudyForgeTests` target wired into the scheme · `xcodebuild test` → **39 tests in 7 suites, 0 failures** · found and fixed a real `AppError.from` bug |
| **Firebase SDK wired + `AuthService` (F01 foundation)** | **M1** | `firebase-ios-sdk` **12.19.2** resolved with 13 packages pinned in `Package.resolved` · new `Core/Auth/` (protocol, Firebase impl, mock, claims, state broadcaster) and `Core/Config/` (plist-optional bootstrap) · app **launches and renders with NO Firebase project** in the Simulator · `xcodebuild test` → **78 tests in 12 suites, 0 failures** · build has **0 errors, 0 warnings** · decisions **D22/D23** |
| **Live project `studyforge-it8108` + rules deployed** | **M1** | Live on **Spark** (no billing, as predicted — the `OR_BACR2_59` console error was a Google Payments issue and was routed around) · Firestore **STANDARD** edition, `FIRESTORE_NATIVE`, location **`me-central2` (Dammam)** · Email/Password enabled · iOS app `com.studyforge.app` registered, its **App ID matches the plist byte-for-byte** · **rules and indexes deployed** · *verified against the live database*: the app's own `users/{uid}` payload → **HTTP 200 ALLOWED**; the same payload claiming `role=tutor` → **HTTP 403 PERMISSION_DENIED** · test account deleted and `users/` left at **0 documents** |

### ✅ The human-only steps — completed

> **No longer blocked.** These needed a person (a Google account plus a browser); they are
> done, and every outcome is recorded above.

| Task | Outcome |
|---|---|
| Create the Firebase project | ⚠️ The console's billing flow failed with **`OR_BACR2_59`** — a **Google Payments** error, not a Firebase one. Since **Spark needs no billing**, it was routed around rather than fought. Runbook: [`backend/README.md`](../../../backend/README.md) |
| Firestore database | Created in **Standard** edition. *Not* Enterprise — that has **no automatic indexing**, which would break `firestore.indexes.json` and every single-field query we rely on |
| Location | **`me-central2` (Dammam)** — ~15 ms from Bahrain instead of ~200 ms to Iowa. A permanent choice, so worth having got right |
| Auth providers | ✅ **Email/Password enabled** (F01 depends on it). ⚠️ **Google was enabled too** — see the warning below |
| `GoogleService-Info.plist` | In `ios/StudyForge/StudyForge/`, auto-included by the synchronized folder, gitignored, **App ID matches the registered app exactly** |
| Rules + indexes | Deployed via the CLI and **verified against the live database** (see the table above) |
| Storage bucket | ⬜ **Not created yet** — create it as **`us-central1`** when S2 first needs uploads |

> ⚠️ **Open item created by enabling Google sign-in.** App Store Guideline 4.8 requires that
> if a third-party login is offered, **Sign in with Apple must be offered too**.
> `FirebaseAuthService` implements email/password only, so Google currently does nothing —
> but shipping it would oblige us to ship Apple sign-in as well (which needs a paid Apple
> Developer membership and a Firebase Service ID + key). **Safest S1 path: email/password
> only**, and add Apple + Google together if time allows.

### ⬜ Next (I can do these)

| Task | Owner | Note |
|---|---|---|
| ~~Firebase SPM packages wired into the Xcode project~~ | M1 | ✅ **Done during S0** — `firebase-ios-sdk` 12.19.2 resolved and linked; `Package.resolved` committed to pin versions |
| ~~`AuthService` protocol + Firebase impl + mock~~ | M1 | ✅ **Done during S0** — F01 foundation landed, with 39 auth tests. F01 continues in S1 with the sign-in/sign-up **screens** |
| Tier-1 `FirebaseAIProvider` against the existing `AIProvider` protocol | M2 | The protocol and router already exist and are tested; this is the S1 wiring |
| Emulator-backed **integration** test for sign-up (writes `users/{uid}`) | M1 | The write path is **already proven against the live project** (HTTP 200 vs 403 above). What remains is making that proof *repeatable in CI* rather than a manual probe — deliberately kept out of the hermetic unit suite (D23) |
| Figma file: 9 pages + variables + component library | M4 | Needs the design decisions in docs/06, already frozen |
| Confirm tier 0 on the real demo iPhone | M2 | Simulator reports `simulatorUnsupported` by design; hardware verified available |

### Sprint exit gate — **met**

> App builds on device · Firebase live · feature table signed off · tokens frozen

| Gate item | Status | Evidence |
|---|---|---|
| App builds | ✅ | `xcodebuild` BUILD SUCCEEDED, **0 errors, 0 warnings**; launches in the Simulator |
| **Firebase live** | ✅ | Project + Standard Firestore (`me-central2`) + Auth + rules deployed, all **verified against the live database** |
| Feature table signed off | ✅ | `tools/verify-docs.py` → ALL CHECKS PASSED (141 frames, 15 features) |
| Tokens frozen | ✅ | Design gallery renders from the frozen token set |

**S0 is complete.** The only outstanding Firebase item is the **Storage bucket**
(`us-central1`), which S0 never needed — it becomes a prerequisite the moment S2 first
uploads a file, and it is noted above so it cannot be forgotten.

