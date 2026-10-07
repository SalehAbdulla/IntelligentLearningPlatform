# backend/ — Firebase configuration and server-side functions

> **This is the backend half of the repository.** The other half is [`ios/`](../ios/), the app itself.
> Everything here is declared, deployed and enforced by Firebase — there is no server of ours to run.

**Why this directory is called `backend/` and not `firebase/`:** it names the *tier* rather than the
*vendor*, so the repo has two clearly labelled halves without implying a codebase we don't own.
Worth being explicit about, because the split is deliberately **asymmetric**:

| | `ios/` | `backend/` |
|---|---|---|
| What it is | The product — **60% must-pass** deliverable | ~95% declarative config + **2 Cloud Functions** |
| Language | Swift 6, SwiftUI | Firestore rules syntax · TypeScript (functions only) |
| Move to the app? | — | No. The AI router, repositories, offline cache and data model all live in `ios/`, because generation is on-device-first |

So if a marker asks *"where is your server code?"* — the honest answer is
*"there isn't one by design; the tier-0 AI runs on the device and Firebase enforces authorisation
declaratively."* See [docs/00 §3](../docs/00-MASTER-PLAN.md) and [docs/04 §4](../docs/04-TECH-ARCHITECTURE-COST.md).

---

## Status — Sprint S0 ✅

The configuration is written and the rules are **verified against the emulator**:
**58 tests, 0 failures** (40 Firestore + 18 Storage), including the negative tests.

| Path | What it is | Verified |
|---|---|---|
| `firebase.json` | CLI config: rules/indexes paths, emulator ports, small function surface | ✅ |
| `.firebaserc` | Project alias → `studyforge-it8108` | ✅ |
| `firestore.rules` | **Role-based, deny-by-default** rules for all 40 collections | ✅ 40 tests |
| `firestore.indexes.json` | 10 composite indexes — no cold-query crashes | ✅ |
| `storage.rules` | Owner-only paths plus shared-folder grants resolved from Firestore | ✅ 18 tests |
| `rules-tests/` | Emulator suites, **negative tests first** | ✅ |
| `functions/src/index.ts` | `createCharge` + `tapWebhook` (Tap Company, **implemented**) and `rollupDailyMetrics` (skeleton) | ✅ payments · ⚠️ rollup S4 |
| `functions/.env.example` | Required secrets, documented; the real `.env` is gitignored | ✅ |

Full schema, role model and rule rationale: [docs/05-DATA-MODEL-SECURITY.md](../docs/05-DATA-MODEL-SECURITY.md).

### ⚠️ Two honest limitations

1. **The Tap payment functions are implemented but not deployed.** `createCharge` and
   `tapWebhook` are ported from a working Tap Company integration (Bearer `sk_` key,
   `POST /v2/charges`, and `X-Tap-Signature` HMAC-SHA256 over the raw body). They compile
   clean (`tsc`) but cannot deploy without the Blaze plan plus a budget alert and spend cap
   (docs/04 §5) and Tap secret keys from a merchant account (docs/09 Q2/Q3).
   `rollupDailyMetrics` remains a skeleton (Sprint S4). Nothing here pretends otherwise.
2. **The Storage emulator prints a Java warning** on newer JDKs
   (`sun.misc.Unsafe::arrayBaseOffset` from protobuf). It is a deprecation notice from
   the emulator's own dependency, not a failure — all 18 Storage tests pass. If a future
   JDK finally removes the API, pin JDK 21 for emulator work.

## Commands (run from this directory)

```bash
cd backend
npm install                       # firebase-tools + @firebase/rules-unit-testing

# ── run the rules tests (this is the gate before any deploy) ──
npm test                          # both suites
npm run test:firestore            # 40 tests
npm run test:storage              # 18 tests (needs Firestore too — see below)

# ── local development ──
npm run emulators                 # auth + firestore + storage, with the emulator UI

# ── deploy (never deploy rules without the tests passing first) ──
npm run deploy:rules            # Firestore rules — the ones that matter
npm run deploy:indexes
# npm run deploy:rules:storage  # requires Blaze; Storage is bypassed — see D24 below
```

**Why `test:storage` also starts Firestore:** `storage.rules` calls `firestore.get()`
to resolve shared-folder permission, so folder permission lives in exactly **one**
place instead of being duplicated into the auth token. That is a deliberate design
choice, and the Storage tests prove the cross-service lookup actually enforces.

**Why `--test-concurrency=1` is not optional:** both suites share one emulator, and
Node runs test *files* concurrently by default. Run together, the Firestore suite's
`clearFirestore()` wipes the folder membership the Storage suite has just seeded — so
the Storage tests that *expect success* fail with `storage/unauthorized`, while the
ones that *expect denial* still pass. That asymmetry makes the bug easy to misread as
a rules problem when it is a test-harness one. Serialising the files fixes it:

```
node --test --test-concurrency=1 rules-tests/*.test.mjs     # 58/58 pass
node --test rules-tests/*.test.mjs                          # 56/58 — cross-talk
```

**Recommended before every deploy:**
```bash
npm test && npm run deploy:rules
```

---

## Creating the Firebase project — and how to proceed if the console blocks you

### The CLI path (preferred)

The console's project-creation flow can fail with **`OR_BACR2_59`** ("Billing setup can't
be completed"). **Spark needs no billing account**, so that error means the flow routed
you toward a Blaze upgrade you never asked for — it does not mean a card is required.

Creating the project from the CLI sidesteps that flow entirely:

```bash
cd backend
npx firebase login
npx firebase projects:create studyforge-it8108 -n "StudyForge"
npx firebase apps:create IOS StudyForge -b com.studyforge.app    # prints an App ID
npx firebase apps:sdkconfig IOS <APP_ID> -o ../ios/StudyForge/StudyForge/GoogleService-Info.plist
```

`apps:sdkconfig` writes `GoogleService-Info.plist` **without the console**, so the entire
setup can be completed from a terminal.

If `OR_BACR2_59` persists, the likeliest cause is that the Google account is a
**university/Workspace account**, where creating a billing profile is blocked at the
organisation level. The usual support response is a dead end ("you are not an
administrator on any Billing Account" — true, but circular, since you have never had
one). Use a **personal Gmail** instead.

### You do not have to wait for this

The iOS app runs with **no Firebase project at all**. In Debug, when
`GoogleService-Info.plist` is absent, `Core/Config/FirebaseBootstrap.swift` synthesises
options against the demo project and points Auth + Firestore at the local emulators — so
every Firebase-backed screen is developable and testable today.

```bash
cd backend && npm run emulators     # terminal 1: auth :9099, firestore :8080, storage :9199
# terminal 2: run the app from Xcode — it will use the emulators automatically
```

Release builds still require the plist: `FirebaseBootstrap` calls `fatalError` rather than
allow a production build to run against a fake project. See **D22** in
[docs/09](../docs/09-RISKS-OPEN-QUESTIONS.md).

> On a **physical device** the emulators are not reachable at `127.0.0.1`. Set
> `STUDYFORGE_EMULATOR_HOST` to the Mac's LAN IP in the scheme's environment variables.

---

> ⚠️ **Before the FIRST Cloud Functions deploy:** set a **budget alert and a spend cap** in the
> Google Cloud console. Cloud Functions requires the Blaze plan, which is tied to a billing
> account — this is the only path to an unbudgeted bill.
> See [docs/04 §5](../docs/04-TECH-ARCHITECTURE-COST.md).

> ⚠️ **Storage bucket region:** create the default bucket in **`us-central1`** (or `us-west1` /
> `us-east1`). The Firebase no-cost Storage quota applies *only* to those regions — a
> Bahrain-region bucket drops straight onto a billing plan. We accept ~200 ms extra latency
> in exchange for staying at $0.

