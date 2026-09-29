# 04 — Tech Architecture & Cost Model

> Companion to the Design Document §14 (Technical architecture). Everything here is chosen against one hard constraint from the client: **make it as minimal cost as possible.**

---

## 1. Architectural principles

| # | Principle | Consequence |
|---|---|---|
| **1** | **Zero-cost by default** | Every service sits inside a free tier. Nothing is provisioned "just in case". |
| **2** | **On-device first, cloud second** | Extraction, embedding and (where possible) generation happen on the phone — no network, no cost, no privacy exposure. |
| **3** | **Offline-first** | The core loop (browse → review cards → quiz) works with no connectivity. Sync is a background concern, not a gate. |
| **4** | **Server-enforced security** | Roles live in Auth custom claims and security rules. The client is never trusted to decide access. |
| **5** | **Protocol-first / swappable providers** | `AIProvider`, `PaymentGateway`, `MaterialExtractor` are protocols. Swapping Gemini for another model, or Tap for StoreKit, is a one-file change. |
| **6** | **Testable by construction** | Every service is injected through `AppContainer`, so any screen runs on mock data with no backend. |
| **7** | **Nothing regenerated twice** | AI output is cached by the SHA-256 hash of the source text. Identical input never costs a second call. |

---

## 2. System architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│  iOS 26+  ·  SwiftUI  ·  Swift 6  ·  Xcode 27                            │
│                                                                          │
│  Presentation      Views + @Observable ViewModels (MVVM)                 │
│  Domain            UseCases · Repository protocols · Domain models       │
│  Data              Repository impls ──┬── Firebase SDK (Firestore/RTDB)  │
│                                       ├── SwiftData (offline cache, RAG) │
│                                       ├── Keychain (tokens)              │
│                                       └── Cloud Functions (callable)     │
│  Platform          Vision · NaturalLanguage · PDFKit · FoundationModels  │
│                    PencilKit · UserNotifications · BackgroundTasks       │
│  DesignSystem      ColorTokens · TypeScale · Spacing · Components        │
└───────────────┬──────────────────────────────────────────────────────────┘
                │
    ┌───────────┴────────────────────────────────────────────┐
    │              AI ROUTER  (policy-driven)                 │
    │  ┌──────────────┬──────────────────┬────────────────┐   │
    │  │ T0 on-device │ T1 Firebase AI   │ T2 CF proxy    │   │
    │  │ Foundation   │ Logic (Gemini)   │ (heavy jobs)   │   │
    │  │ Models   $0  │ free tier    $0  │ free allowance │   │
    │  └──────────────┴──────────────────┴────────────────┘   │
    └───────────┬─────────────────────────────────────────────┘
                │
┌───────────────┴──────────────────────────────────────────────────────────┐
│  FIREBASE  (Spark plan — no-cost tier)                                   │
│  Auth (50K MAU) · Firestore (50K reads / 20K writes per day, 1 GiB)      │
│  Storage (5 GB, 1 GB/day egress — bucket in us-central1)                 │
│  FCM (unlimited) · Remote Config · App Check · Analytics · Crashlytics   │
└───────────────┬──────────────────────────────────────────────────────────┘
                │
┌───────────────┴──────────────────────────────────────────────────────────┐
│  EXTERNAL                                                                │
│  Tap Payments (sandbox) — card + BenefitPay + Apple Pay, priced in BHD   │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Stack decisions (with justification)

| Layer | Technology | Why this one | Cost |
|---|---|---|---|
| Frontend | **SwiftUI + Swift 6**, iOS 26.0+ | Brief mandates iOS + Xcode 26.6/27. Declarative UI matches the UI/UX rubric. | $0 |
| State | **MVVM + `@Observable` + async/await** | Testable, concurrency-safe, no third-party dependency | $0 |
| Local data | **SwiftData** (cache + RAG vectors) · Keychain (tokens) | Offline-first; entirely first-party | $0 |
| Auth | **Firebase Authentication** | Email/password, Sign in with Apple, OTP, **custom claims** for roles | $0 (50K MAU) |
| Database | **Cloud Firestore** | Realtime listeners (free) power the live group quiz; built-in offline persistence | $0 within 50K reads / 20K writes per day |
| Files | **Cloud Storage for Firebase** | Material PDFs and images | $0 within 5 GB — **bucket must be `us-central1` / `us-west1` / `us-east1` to qualify for the no-cost quota** |
| Push | **Firebase Cloud Messaging** | Free at any volume | $0 |
| Observability | **Crashlytics + Google Analytics** | Evidence of professional practice (LO3) | $0 |
| Config | **Remote Config + Firestore prompt templates** | Prompt tuning without an app release | $0 |
| Abuse protection | **App Check (App Attest)** | Stops repackaged clients burning the AI free tier or reading Firestore | $0 |
| Serverless | **Cloud Functions (Blaze)** | Only for payment webhooks, nightly aggregation, heavy AI jobs | $0 within free allowance; **budget alert + spend cap mandatory** |
| AI · tier 0 | **Apple Foundation Models** (`FoundationModels`) | Free, private, offline. Strong at summarise / extract / classify. **Not available in the Simulator** — needs an Apple Intelligence device | $0 |
| AI · tier 1 | **Firebase AI Logic** (Gemini Developer API free tier) | Works in the Simulator; handles multimodal input (scanned pages). Rate-limited by RPM / RPD / TPM | $0 within quota |
| AI · tier 2 | **Gemini via Cloud Function proxy** | Heavy or queued jobs; keeps API keys server-side | $0 within free allowance |
| Embeddings | **NaturalLanguage `NLEmbedding`** (on-device) | Zero-cost RAG with no vector database to pay for | $0 |
| OCR | **Vision framework** (on-device) | Instant, private, free — and it keeps large scans off the network | $0 |
| Voice | **Speech + AVSpeechSynthesizer** | Free voice-quiz mode | $0 |
| Payments | **Tap Payments iOS SDK** (`tap.company`) | Bahrain-licensed; supports Benefit, BenefitPay, cards and Apple Pay; sandbox needs no CR | $0 in sandbox |
| Charts | **Swift Charts** | First-party, accessible, no dependency | $0 |
| PDF | **PDFKit** + system share sheet | First-party viewer + annotation | $0 |
| Testing | **Swift Testing** + XCTest + **Firebase Emulator Suite** | Modern and first-party; the emulator avoids burning production quotas | $0 |
| CI | **GitHub Actions** (free tier) | Build + unit tests on every push | $0 |

**Estimated total project cost: $0.** The only path to a bill is exceeding a free-tier quota, which is why §5's guardrails exist.

---

## 4. The 3-tier AI router (the core technical innovation)

### Router input

| Signal | Source | Used for |
|---|---|---|
| Task type | Caller | Capability requirement |
| `SystemLanguageModel.availability` | Foundation Models framework | Is on-device even possible? |
| Device capability | `os` + Apple Intelligence check | Tier eligibility |
| Network reachability | `NWPathMonitor` | Offline → tier 0 only |
| Remaining daily budget | `aiUsage/{uid}/{date}` | Prevents quota exhaustion |
| Content size | Token estimate | Context-window fit |
| Requires multimodal | Input contains images/scans | Tier 0 is text-only → tier 1 |

### Routing policy (default, admin-configurable at `115_Admin_AIConfig_Settings`)

| Task | Preferred | Fallback | Rationale |
|---|---|---|---|
| Text summarisation | **T0 on-device** | T1 → T2 | Model is excellent at summarisation; free + private + offline |
| Flashcard generation | **T0 on-device** (guided generation into `@Generable` structs) | T1 | Structured output is well supported |
| Quiz generation | **T0 on-device** | T1 | Same |
| OCR of scanned pages | **Vision on-device** | T1 multimodal | Never send a scan to the cloud unless OCR fails |
| Coach Q&A (RAG) | **T0 if available** | T1 → T2 | Longer context + stronger reasoning may need tier 1 |
| Study-path planning | **T0 on-device** | Deterministic scheduler | Falls back to a pure-algorithmic planner if no model — still works |
| Long documents (> context window) | **T2 Cloud Function** | T1 (chunked) | Server-side chunk-and-merge |
| Community moderation | **T2 Cloud Function** | — | Must be server-side and auditable |

> **S0 note — tier 1 is temporarily the mock.** The Firebase SDK is not wired in yet,
> so `AIRouter.standard` registers `MockProvider` at tier 1. This is what lets every AI
> screen be built and demoed in the Simulator, where tier 0 cannot run.
> `FirebaseAIProvider` replaces it in S1 with no change to the protocol or to any caller.
> See the [S0 spike report](../research/spikes/foundation-models.md).

### Why this is defensible engineering, not decoration

1. **It makes the product free.** Tier 0 costs nothing and covers the majority of calls, so the free tier of tier 1 is never exhausted by normal use.
2. **It makes the product work offline.** A student on a bus with no data can still generate flashcards.
3. **It is honest about failure.** `80_Coach_OnDeviceUnavailable_Fallback` tells the user what happened and offers a next step, instead of a spinner that never resolves.
4. **It is a real product concern** — every commercial AI app wrestles with exactly this cost/quality/privacy trade-off.

---

## 5. Cost model — how we stay at $0

### Confirmed no-cost allowances (Firebase Spark plan)

| Service | No-cost allowance | Our expected use | Headroom |
|---|---|---|---|
| Firestore reads | **50,000 / day** | ~5,000 / day (listeners + cache-first reads) | ~10× |
| Firestore writes | **20,000 / day** | ~2,000 / day | ~10× |
| Firestore deletes | **20,000 / day** | <200 / day | ~100× |
| Firestore stored data | **1 GiB** | ~50 MB | ~20× |
| Firestore egress | **10 GiB / month** | ~1 GiB | ~10× |
| Cloud Storage stored | **5 GB** | ~300 MB (client-side compressed) | ~16× |
| Storage download | **1 GB / day** | ~50 MB / day | ~20× |
| Storage upload ops | **20,000 / day** | <100 / day | ~200× |
| Auth MAU | **50,000** | 40 demo users | — |
| Cloud Messaging | **Unlimited** | — | — |
| Remote Config | **No-cost** | — | — |
| Firebase AI Logic (Gemini Developer API free tier) | Rate-limited per model (RPM / RPD / TPM); requires an API key created in AI Studio and enabled for the Firebase project | <100 generation calls / day after caching + tier-0 routing | — |

> ⚠️ **Two non-obvious constraints worth stating in the document, because they demonstrate real engineering diligence:**
> 1. **Cloud Storage's no-cost quota applies only to buckets in `us-central1`, `us-west1` or `us-east1`.** Choosing a Bahrain-region bucket would look locally optimal but would drop us straight onto a billing plan. We choose `us-central1` and accept ~200 ms extra latency to stay free.
> 2. **Cloud Functions requires the Blaze (pay-as-you-go) plan** for new projects, though the free monthly invocation allowance is generous. Because Blaze is tied to a *billing account*, a **budget alert and spend cap are mandatory** — otherwise a runaway loop has unbounded cost.

### Cost guardrails (all implemented, all cheap)

| # | Guardrail | Mechanism | Protects against |
|---|---|---|---|
| 1 | **Content-hash response cache** | SHA-256 of extracted text → cached AI output in `aiCache/{hash}` | Paying to regenerate identical summaries for the same material |
| 2 | **On-device-first routing** | The AI router (§4) | Burning the tier-1 free quota |
| 3 | **Per-user daily AI budget** | `aiUsage/{uid}/{date}` counter, admin-configurable | One user exhausting the shared project quota |
| 4 | **Client-side compression before upload** | Downscale to ≤2048 px, JPEG q0.7, PDF linearisation | Blowing the 5 GB storage and 1 GB/day egress caps |
| 5 | **Cache-first reads** | Firestore offline persistence + SwiftData cache; every list paginated at 20 items | Read amplification — the classic Firestore cost trap |
| 6 | **Batched writes and aggregation** | A nightly Cloud Function rolls up daily metrics; clients never recompute dashboards | Write amplification |
| 7 | **Realtime listeners only where realtime is required** | Live quiz, chat and moderation only; everything else uses one-shot `get()` | Idle listener read charges |
| 8 | **Budget alert + spend cap** | Hard ceiling set in the Google Cloud console | Any unbounded bill |
| 9 | **Emulator-first development** | Firebase Emulator Suite for all local work | Burning quota while debugging |
| 10 | **Asset hygiene** | No duplicate uploads (hash match → offer replace); list thumbnails instead of full PDFs | Storage growth |

### Scenarios that would cost money, and the trigger point

| Scenario | Would breach | Our mitigation |
|---|---|---|
| 50+ concurrent users all listening to the same group space | Firestore reads | Throttle live listeners; aggregate the leaderboard into one document |
| A user looping on a 500-page upload | Storage egress + AI calls | Upload size cap (50 MB) + daily AI budget |
| Real production use after the course ends | Everything | Documented as out of scope; on Spark, the project simply stops serving beyond quota rather than billing |

---

## 6. Payments architecture (Tap Payments)

### Confirmed facts

- **Tap Payments (`tap.company`)** is licensed in Bahrain and across GCC markets, with local support and a Bahrain-specific product page — this is the gateway meant by "TapPay, Bahrain-based".
- Supported locally: **Benefit**, **BenefitPay**, cards (Visa / Mastercard / Amex), **Apple Pay**, plus regional methods (KNET, Mada, STC Pay) — important because a Bahrain student expects Benefit or BenefitPay, not only an international card form.
- An **iOS SDK** exists (Card SDK + Checkout SDK) and installs via Swift Package Manager.
- **Sandbox** provides test keys and test cards. Going live requires merchant onboarding (commercial registration + bank account), which is **out of scope for a university prototype** — this is the single biggest reason we stay in sandbox.
- Bahrain's **Resolution No. 43** requires businesses to hold a commercial bank account and adopt electronic payments — useful local-context evidence for the Background Research section.

### Flow we implement

```
User taps "Upgrade"
   → iOS builds the order (plan, term, BHD amount incl. 10% VAT)
   → iOS calls Cloud Function  createCharge(orderId, amount, currency: "BHD")
   → Function calls Tap  POST /v2/charges  using the SECRET key   ← the key never leaves the server
   → Tap returns a payment / redirect URL
   → iOS presents the Tap card sheet (TapCardView) or an SFSafariViewController redirect
   → User completes payment (card / BenefitPay / Apple Pay / 3-D Secure)
   → Tap → webhook → Cloud Function verifySignature() → validate amount + currency
   → Function writes subscriptions/{uid} = { plan, status, tapChargeId, periodEnd }
   → Function mirrors the plan into the Auth custom claim `plan`
   → Client observes its own subscription doc and unlocks features
```

**Security rules of engagement** — state these explicitly in the document; this is LO3 material:

1. **The secret key lives only in the Cloud Function environment**, never in the app bundle.
2. **Card data never touches our servers.** The Tap SDK tokenises inside the card view; we only ever receive a charge reference. This keeps us out of PCI-DSS scope for card storage.
3. **The client is never trusted.** An in-app "success" callback changes nothing — the **webhook is the single source of truth** for entitlement.
4. **Idempotency keys** prevent duplicate charges on retry.
5. **Server-side amount validation** prevents a client-tampered price.

### The professional-ethics issue we surface deliberately

**Apple App Store Review Guideline 3.1.1** requires that digital content and subscriptions consumed *inside* an iOS app be sold through **Apple In-App Purchase**. A shipping app that sells "StudyForge Plus" via Tap Payments would be rejected at review.

We resolve this architecturally rather than ignoring it:

```swift
protocol PaymentGateway {
    func startCheckout(order: Order) async throws -> PaymentResult
    func restoreEntitlements() async throws -> [Entitlement]
}

struct TapPaymentsGateway: PaymentGateway { /* required by the client brief; used in test / dev builds */ }
struct StoreKitGateway:    PaymentGateway { /* App Store-compliant path for a production release */ }
```

The Design Document states the conflict, explains both routes, and justifies the choice for a university prototype (TestFlight / internal distribution, no App Store submission, sandbox only). This converts a compliance problem into evidence of **professional judgement under LO3**.

### Pricing model (BHD)

| Plan | Monthly | Annual (2 months free) | AI generations / day | Materials | Group spaces |
|---|---|---|---|---|---|
| **Free** | BHD 0.000 | — | 15 (on-device unlimited) | 20 | 1 |
| **Plus** | BHD 1.900 | BHD 19.000 | 100 | 200 | 5 |
| **Pro** | BHD 4.900 | BHD 49.000 | Unlimited (fair use) | Unlimited | Unlimited |

All prices are shown VAT-inclusive with the breakdown rendered on `120_Checkout_OrderSummary_BHD`.

---

## 7. Security architecture (summary — detail in [doc 05](05-DATA-MODEL-SECURITY.md))

| Layer | Control | Where enforced |
|---|---|---|
| Identity | Firebase Auth (email/password, Sign in with Apple, OTP) | Firebase |
| Authorisation | Role + plan + groupIds as **Auth custom claims** | Auth token |
| Data access | `firestore.rules` — row-level, role-aware, denies by default | **Server** |
| File access | `storage.rules` — owner + explicit folder grants only | **Server** |
| API abuse | **App Check** (App Attest) on every client request | Firebase |
| Secrets | Secret keys only in Cloud Function environment; `GoogleService-Info.plist` in `.gitignore` | Build + deploy |
| Payments | Webhook signature verification; server-side amount check; idempotency | Cloud Function |
| Privacy | On-device-first AI; explicit retention controls at `22_Settings_AIDataPrivacy`; delete-my-data path | App + Firestore |
| Academic integrity | Tutor review queue (`105`), AI-draft watermarking on summaries, no auto-grading claims | Product design |
| Auditability | Append-only `auditLog` for every admin action | Firestore rules deny update/delete |

---

## 8. Implementation conventions (the Cline working agreement)

Track C is built by Cline, so the conventions are explicit and enforceable.

### Repository layout

```
ios/StudyForge/
├── StudyForge.xcodeproj
└── StudyForge/
    ├── App/                    StudyForgeApp.swift · AppContainer.swift · RootView.swift · RoleRouter.swift
    ├── Core/
    │   ├── AI/                 AIProvider.swift · AITier.swift · AIGenerationModels.swift
    │   │                       OnDeviceProvider.swift · MockProvider.swift · FirebaseAIProvider.swift
    │   │                       AIRouter.swift · AICostGovernor.swift · PromptTemplates.swift
    │   ├── AI/Retrieval/       Chunker.swift · EmbeddingIndex.swift · Retriever.swift
    │   ├── Auth/               AuthService.swift · CustomClaims.swift · RoleGuard.swift
    │   ├── Payments/           PaymentGateway.swift · TapPaymentsGateway.swift · StoreKitGateway.swift
    │   ├── Persistence/        SwiftDataModels.swift · LocalCache.swift · SyncQueue.swift
    │   ├── Extraction/         MaterialExtractor.swift · VisionOCR.swift · Compressor.swift
    │   ├── Notifications/      PushService.swift · DeepLinkRouter.swift
    │   ├── Scheduling/         SpacedRepetition.swift · StudyPlanner.swift
    │   └── Observability/      Logger.swift · AnalyticsEvents.swift
    ├── Features/
    │   └── <FeatureName>/      <Feature>View.swift · <Feature>ViewModel.swift · <Feature>Repository.swift
    ├── DesignSystem/           ColorTokens.swift · TypeScale.swift · Spacing.swift · Components/
    └── Resources/              Assets.xcassets · Localizable.strings (en, ar) · SampleMaterials/
```

### Coding rules

| Rule | Detail |
|---|---|
| Architecture | MVVM. Views are dumb; all logic lives in `@Observable` view models. |
| Concurrency | Swift 6 strict concurrency. `@MainActor` on view models. No `DispatchQueue` anywhere. |
| Dependency injection | Everything through `AppContainer`. No singletons, no `FirebaseFirestore.firestore()` calls inside views. |
| Protocols | Every service that touches the network or the model has a protocol + a mock. |
| Errors | A single `AppError` enum with user-facing messages. Never surface a raw NSError or a server string to the user. |
| State | Every screen renders from `LoadState<T>`. Loading, empty, failed and loaded states are all first-class. |
| Localisation | No hard-coded user-facing strings. All through `Localizable.strings` (English + Arabic). |
| Accessibility | Every interactive element gets an accessibility label; layouts must survive AX5. |
| Secrets | Never committed. `GoogleService-Info.plist` and `.xcconfig` files holding keys stay in `.gitignore`. |
| Naming | Feature-first, no abbreviations except `SR` (spaced repetition) and `AI`. |

### Git conventions

**Full workflow: [doc 12 — Git Workflow](12-GIT-WORKFLOW.md).** Summary — the tutor requires a branch-based workflow with meaningful, well-scoped commits.

| Item | Convention |
|---|---|
| **Branch model** | `main` (stable, protected) ← `develop` (integration, protected) ← `feat/Fxx-slug` · `fix/slug` · `docs/slug` · `chore/slug` |
| **Never** | Commit directly to `main` or `develop` — always via branch + PR |
| **Branch naming** | `feat/F04-sm2-scheduling` — feature branches **must** carry the feature ID |
| **Commit granularity** | **One file per commit** wherever the change is separable |
| **Commit message** | Conventional Commits — `feat(F04): implement SM-2 interval calculation` |
| **Push cadence** | At least once a day while working (continuous progress evidence) |
| **PR** | Base `develop` · uses `.github/PULL_REQUEST_TEMPLATE.md` · reviewed by the feature's named **tester** |
| **Merge** | Preserve the per-file commits — do **not** squash a feature branch into one commit |
| **Helper tools** | `tools/commit.sh` (enforces rules 1, 2, 3, 6) · `tools/new-branch.sh` |
| **Tags** | `design-doc-v1` (21 Oct), `prototype-v1` (11 Nov), `demo-v1` |
| **Protected** | `main` and `develop` — PR required, no force-push, no deletion |

**Why this is more than tidiness:** git history is the primary evidence for the **Sprints (10%, individual)** component, and it is what makes a feature traceable in the **60% must-pass VIVA**. A marker can run `git log --grep="F04"` or `--author="Saleh"` and see the work — that is worth more than any written claim.

### Build & run commands

```bash
# Build for the simulator (verified available devices: iPhone 17, iPhone 18 Pro,
# iPhone Air, iPhone 17e · runtimes iOS 26.5 and iOS 27.0)
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj \
           -scheme StudyForge \
           -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
           build

# Unit tests
xcodebuild test -project ios/StudyForge/StudyForge.xcodeproj \
                -scheme StudyForge \
                -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# List destinations when a device is missing
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge -showdestinations

# Backend — the Firebase CLI runs from the backend/ directory
cd backend

# Firebase emulators (use this for ALL local work — protects production quota)
firebase emulators:start --only auth,firestore,storage,functions

# Deploy rules only (never deploy rules without emulator tests passing)
firebase deploy --only firestore:rules,storage:rules
```

> ⚠️ **Do not deploy Cloud Functions without first setting a budget alert and a spend cap in the Google Cloud console.** This is a Phase 7 gate item.

> 📱 **Demo device note:** the **on-device Apple Intelligence tier does not run in the Simulator** — it requires a physical device with Apple Intelligence enabled. For the live demo, run on a real iPhone; in the Simulator, the AI router falls back to tier 1 (Firebase AI Logic) and the app shows `80_Coach_OnDeviceUnavailable_Fallback` when tier 1 is also unavailable. Plan the demo around this.


---

## 9. Verification status of this architecture

| Claim in this document | Verified how | Status |
|---|---|---|
| Xcode 27.0 satisfies the brief's "Xcode 26.6 or 27" requirement | `xcodebuild -version` → Xcode 27.0 (27A266a) | ✅ verified |
| iOS 26.0+ deployment target is testable locally | `xcrun simctl list runtimes` → iOS 26.5 and iOS 27.0 present | ✅ verified |
| Swift 6.4 with strict concurrency | `swift --version` → Apple Swift 6.4 | ✅ verified |
| Simulator devices for the demo | `simctl list devices` → iPhone 17, iPhone 18 Pro, iPhone Air, iPhone 17e, iPad Pro/Air/mini | ✅ verified |
| Figma is available for Track B | `Figma.app` present in `/Applications` | ✅ verified |
| Firebase CLI + emulator workflow is executable | Node 24.15 / npm 11.12 present; `firebase-tools` not yet installed | 🟨 Phase 0 task |
| Firestore / Storage / Auth free-tier numbers | Read from Firebase's published pricing and quota documentation (Sept 2026) | ✅ verified |
| Storage no-cost quota is region-restricted | Firebase pricing docs: `us-central1`, `us-west1`, `us-east1` only | ✅ verified |
| Cloud Functions requires Blaze | Firebase pricing docs; free invocation allowance still applies | ✅ verified |
| Firebase AI Logic has a no-cost tier with per-model RPM/RPD/TPM limits | Firebase AI Logic quota docs; requires an API key from AI Studio | ✅ verified |
| On-device Apple Intelligence needs a real device (not the Simulator) | Apple Foundation Models docs **+ confirmed empirically in the S0 spike**: the app reports `simulatorUnsupported` on an iPhone 18 Pro Max Simulator while the same framework returns `available` on Apple Silicon hardware | ✅ **verified empirically — [spike report](../research/spikes/foundation-models.md)** |
| `FoundationModels` provides guided generation (`@Generable`), tools and streaming on iOS 26+ | **Proven, not assumed:** the S0 probe filled a `@Generable` struct (2 × `String` + parsed `Int`) from real model output in 2.82 s, and the app compiles against the real API with zero warnings | ✅ **verified empirically — [spike report](../research/spikes/foundation-models.md)** |
| A tier-1 fallback keeps every AI feature usable when tier 0 is unavailable | Router behaviour observed live in the Simulator: tier 0 `simulatorUnsupported` → all five tasks routed to tier 1 | ✅ verified empirically |
| Tap Payments is Bahrain-licensed with an iOS SDK, Benefit/BenefitPay/Apple Pay support and a sandbox mode | Tap Payments Bahrain product page + developer documentation | ✅ verified |
| Apple Guideline 3.1.1 conflicts with an external gateway for in-app digital goods | App Store Review Guidelines | ✅ verified |

**Everything else in this document is design intent, not a verified fact — and is labelled as such.** That distinction matters: it is what separates an architecture section a marker trusts from one they don't.

---

## 10. Summary of the cost position

| Category | Cost |
|---|---|
| Apple developer tooling (Xcode, simulators, Swift) | $0 |
| Firebase (Auth, Firestore, Storage, FCM, Remote Config, App Check, Analytics, Crashlytics) | $0 within the documented no-cost limits |
| AI — tier 0 on-device (Apple Foundation Models) | $0, unlimited |
| AI — tier 1 (Firebase AI Logic / Gemini free tier) | $0 within the free quota; protected by cache + budget + routing |
| AI — tier 2 (Cloud Functions proxy) | $0 within the free invocation allowance; **spend cap mandatory** |
| Embeddings + OCR (NaturalLanguage, Vision) | $0, on-device |
| Payments (Tap Payments sandbox) | $0 |
| Design (Figma free tier) | $0 |
| CI (GitHub Actions free tier) | $0 |
| **Total** | **$0**, with a hard spend cap as the only defence against an accidental bill |

> **This is the answer to the client's "make it as minimal cost as possible" requirement**, and it is defensible line by line rather than asserted. The cost model is itself a rubric asset — it belongs in the Innovation section.





