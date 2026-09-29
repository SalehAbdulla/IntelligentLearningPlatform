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

## Status

**Empty except this README.** Created in Sprint S1 (S0 is the app foundation).
Sprint allocation: [docs/10 §4](../docs/10-SPRINT-PLAN.md).

## Planned contents

| Path | What it is | Owner |
|---|---|---|
| `firebase.json` | Firebase CLI project config (hosting targets, emulator ports) | M1 |
| `.firebaserc` | Project alias → `studyforge-it8108` | M1 |
| `firestore.rules` | **Role-based, deny-by-default** security rules | M1 |
| `firestore.indexes.json` | Composite indexes — reproducible build, no cold-query crashes | M1 |
| `storage.rules` | Owner-only paths plus explicit shared-folder grants | M1 |
| `rules-tests/` | Emulator tests, including **negative** tests | M4 |
| `functions/src/` | **Only two functions:** the Tap Payments webhook, and nightly aggregation | M3 |
| `functions/.env.example` | Documents required secrets — the real `.env` is gitignored | M3 |

Full schema, role model and rule patterns: [docs/05-DATA-MODEL-SECURITY.md](../docs/05-DATA-MODEL-SECURITY.md).

## Commands (run from this directory)

```bash
cd backend

# First-time setup
npm i -g firebase-tools
firebase login
firebase init                    # Firestore, Storage, Functions, Emulators

# Local development — use the emulator for ALL work, it protects production quota
firebase emulators:start --only auth,firestore,storage,functions

# Run the rules tests before any deploy
npm --prefix rules-tests test

# Deploy (never deploy rules without the emulator tests passing first)
firebase deploy --only firestore:rules,storage:rules
```

---

> ⚠️ **Before the FIRST Cloud Functions deploy:** set a **budget alert and a spend cap** in the
> Google Cloud console. Cloud Functions requires the Blaze plan, which is tied to a billing
> account — this is the only path to an unbudgeted bill.
> See [docs/04 §5](../docs/04-TECH-ARCHITECTURE-COST.md).

> ⚠️ **Storage bucket region:** create the default bucket in **`us-central1`** (or `us-west1` /
> `us-east1`). The Firebase no-cost Storage quota applies *only* to those regions — a
> Bahrain-region bucket drops straight onto a billing plan. We accept ~200 ms extra latency
> in exchange for staying at $0.

