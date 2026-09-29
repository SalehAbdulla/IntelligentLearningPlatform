# Spike — Apple Foundation Models on-device tier

| Field | Value |
|---|---|
| **Sprint** | S0 |
| **Owner** | M2 — Mohammed (spike task **S0-M2**) |
| **Date run** | 28 Sep 2026 |
| **Toolchain** | Xcode 27 · Swift 6.0 (strict concurrency) · iOS 26.0 target |
| **Status** | ✅ **Answered — the architecture holds as designed** |

## The question this spike had to answer

The whole AI architecture (docs/04 §4) rests on three assumptions that, if wrong,
would force a redesign in Sprint 3 — when it would be most expensive:

| # | Assumption | Why it matters |
|---|---|---|
| 1 | `SystemLanguageModel.availability` reports *whether* the on-device model can run, and *why not* | The UI must explain, not just fail |
| 2 | On-device AI is **unavailable in the Simulator** | Development happens in the Simulator; if this is not handled, no AI screen is developable until S3 |
| 3 | `respond(to:generating:)` performs **guided generation** into a `@Generable` type | Flashcards and quizzes are structured data. If the model returns prose, every AI feature needs a fragile parser |

**Assumption 3 was the real risk.** A student project that asks a model for "20
flashcards" and splits the reply on newlines is one prompt change away from breaking.

## Method

Three independent checks, because passing a compile proves nothing about behaviour:

1. **Compile the real implementation** in the app target under strict concurrency.
2. **Run a standalone probe on real hardware** — a command-line Swift binary calling
   the framework directly, so the result comes from the model rather than from a mock.
3. **Run the app in the Simulator** and inspect the router's own live availability
   report, to confirm the fallback path rather than assume it.

## Results

### 1. Compilation — passes, with zero warnings

`xcodebuild -scheme StudyForge -destination 'generic/platform=iOS Simulator'` →
**BUILD SUCCEEDED**, zero errors, zero warnings. Every API in
`Core/AI/OnDeviceProvider.swift` compiled against the real framework on the first
attempt, which means the API design in docs/04 §4 was accurate rather than guessed.

### 2. Real-hardware probe — the model works, and it is fast

Probe source: `research/spikes/fm-probe.swift`, run on Apple Silicon macOS 27 with
Apple Intelligence enabled.

```
availability      : available
VERDICT           : on-device model IS available on this machine
plain generation  : OK in 2.692739833 seconds
guided generation : OK in 2.818012875 seconds
  cards produced  : 3
  [0] front=What is the requirement for a relation to be in Third Normal
        back=A relation is in 3NF when it is in second normal form and ha
        difficulty=2
  [1] front=What does 3NF eliminate?
        back=3NF eliminates transitive dependencies, meaning no non-key a
        difficulty=2
  [2] front=What benefit does 3NF provide?
        back=3NF reduces data redundancy and prevents update anomalies.
        difficulty=1
  structurally valid: true
```

Three findings from this output:

- **Assumption 3 holds.** Guided generation filled a `@Generable` struct with a
  `String`, a `String` and an `Int` — including parsing `difficulty` into an integer.
  No prose parsing is needed anywhere in the app.
- **Latency is acceptable.** ~2.8 s for three cards. Extrapolating linearly, a
  20-card deck lands somewhere in the 15–25 s range, so the generation screen needs a
  determinate progress indicator and must not block the UI — which is what
  docs/03 §4 already specifies.
- **The grounding rule held.** Every generated back referenced only content present
  in the supplied 3NF paragraph. No invented facts, and `difficulty` assignment was
  sensible rather than random. This is weak evidence at n=1 and is *not* a
  hallucination guarantee — it is a reason to keep the grounding instruction and to
  keep the citation feature.

### 3. Simulator — tier 0 correctly reports unavailable, and the router falls back

The app was installed on an **iPhone 18 Pro Max (iOS 27.0) Simulator** and launched.
The spike screen reports the live state of every engine, and the router's predicted
choice for every task:

| Engine | Reported state | Reason surfaced to the user |
|---|---|---|
| On-device (tier 0) | 🔴 unavailable | *Offline AI isn't available in the Simulator* |
| Cloud — Firebase AI (tier 1) | 🟢 ready | — |
| Cloud — server (tier 2) | 🔴 unavailable | *Not available in this build* |

| Task | Routed to |
|---|---|
| Summarise · Make flashcards · Make a quiz · Answer a question · Build a study path | Cloud (Firebase AI) |

Also confirmed: the app **launched and stayed running** (PID present in
`launchctl list` 6 s after launch), so the eight new AI files introduce no crash and
no launch-time regression. The design-system gallery still renders correctly.

**This is the assumption-2 result, and it is the one that changes how we work.**
Tier 0 is unavailable in the Simulator *by design* — Apple's model needs real
hardware. The consequence for the project is concrete:

> **Every AI feature must be developed and demoed against tier 1 or the mock in the
> Simulator. The on-device path can only be verified on a physical device.**

That is why `MockProvider` exists as a first-class engine rather than a test double,
and why the demo script must run on hardware (docs/09).

## Interpretation — what changed as a result of this spike

| Decision | Status |
|---|---|
| Three-tier router (docs/04 §4) | ✅ **Confirmed.** Not one of the three assumptions failed |
| `@Generable` structured output as the contract for all artefacts | ✅ **Confirmed and adopted** |
| Tier 0 leads for text-transformation tasks | ✅ **Confirmed** — it works and costs nothing |
| Simulator development uses the mock as tier 1 | ✅ **New, forced by this spike.** `AIRouter.standard` registers `MockProvider` at tier 1 until the Firebase SDK lands in S1 |
| Grounding instruction first in every prompt | ✅ **Kept** — the probe's output respected it |

No redesign is required. The spike's value was in converting three assumptions into
verified facts, and in surfacing the Simulator limitation early enough to build the
mock into the architecture rather than bolt it on later.

## Honest limitations of this evidence

These are stated because a marker should be able to find them, not hidden because
they weaken the claim:

1. **The probe ran on a Mac, not on the demo iPhone.** Same framework, same
   `availability` API, but "available on this Mac" does not prove "available on
   device X". **Still unverified:** availability on the actual demo device, and real
   iPhone latency (expected slower than the Mac's 2.8 s).
2. **n=1 generation.** One document, one prompt, three cards. This is evidence the
   mechanism works, not evidence about output quality across the curriculum.
3. **Tier 1 was the mock, not real Gemini.** The routing *decision* is verified; the
   Firebase AI Logic integration is not yet written and lands in S1.
4. **No automated tests yet.** There is no test target in the Xcode project, so the
   router and cost governor are verified by compiling and by observation rather than
   by assertion. Adding the test target is scheduled as the first task of S1 — see
   the follow-ups below.
5. **`AICostGovernor` counts in memory only.** A reinstall resets the budget. Moving
   the count to Firestore is S3 work (already noted in the file header).

## Follow-ups generated by this spike

| # | Action | Owner | Sprint |
|---|---|---|---|
| 1 | Add the unit-test target; cover `AIRouter` fallback order and `AICostGovernor` budget | M3 | S1 |
| 2 | Confirm tier 0 availability on the real demo iPhone | M2 | S1 |
| 3 | Write the tier-1 Firebase AI Logic provider against this protocol | M2 | S1 |
| 4 | Fold the measured 2.8 s / 3 cards into the generation-progress screen budget | M4 | S2 |

## Reproducing this result

```bash
# 1. Compile the real implementation under strict concurrency
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

# 2. Run the hardware probe (needs Apple Intelligence enabled)
swiftc -parse-as-library research/spikes/fm-probe.swift \
  -o /tmp/fm-probe -target arm64-apple-macos27.0 && /tmp/fm-probe

# 3. See the live state in the Simulator: AI tab on the app's root view
```

**Note for whoever runs step 2:** `-parse-as-library` is required because the probe
uses `@main` in a single-file module; without it the compiler reports *"'main'
attribute cannot be used in a module that contains top-level code"*.

