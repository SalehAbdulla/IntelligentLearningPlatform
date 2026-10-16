# Test log — F15 AI Study Companion *(the advanced feature)*

| Field | Value |
|---|---|
| **Tester** | **M1, Saleh Abdulla** (`202300540`) |
| **Developers** | M2, Mohammed Almadhoon (`202401702`) + M3, Tasbeeh Saeed (`202300549`) — *neither is me* |
| **Date** | 15 October 2026 |
| **Build** | `xcodebuild … -scheme StudyForge -destination 'platform=iOS Simulator,name=iPhone 17' test` |
| **Feature** | F15 AI Study Companion · screens H01–H08 · **the feature the rubric requires written tutor approval for** |

## What was run

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:StudyForgeTests/TextChunkingTests \
  -only-testing:StudyForgeTests/RetrievalTests \
  -only-testing:StudyForgeTests/GroundedAnsweringTests \
  -only-testing:StudyForgeTests/StudyPathPlannerTests
```

## Observed result

```
✔ Suite "Text chunking (F15)" passed
✔ Suite "Retrieval (F15)" passed
✔ Suite "Grounded answering (F15)" passed
✔ Suite "Study path planner (F15)" passed
✔ Test run with 42 tests in 8 suites passed     ← this run also carried the F09 view-model suites
** TEST SUCCEEDED **
```

## Cases covered

| Behaviour | Covered by | Result |
|---|---|---|
| Text is split into chunks that carry **page and offset**, so a citation can point somewhere real | `TextChunkingTests` | ✅ pass |
| Chunking a document with no text produces no chunks rather than a phantom one | `TextChunkingTests` | ✅ pass |
| Retrieval returns the **top-k by cosine similarity**, nearest first | `RetrievalTests` | ✅ pass |
| A query with **no relevant chunk** retrieves nothing — it does not return the least-bad chunk | `RetrievalTests` | ✅ pass |
| A grounded answer carries **citation chips** back to the chunks it used | `GroundedAnsweringTests` | ✅ pass |
| An answer with no supporting chunk is **dropped rather than emitted** | `GroundedAnsweringTests` | ✅ pass |
| The study path is ordered **read → cards → quiz → review** with durations | `StudyPathPlannerTests` | ✅ pass |
| The planner reads `topicMastery` and puts the **weakest topic first** | `StudyPathPlannerTests` | ✅ pass |

**The two cases I care about most** are the negatives: *a query with no relevant chunk retrieves nothing*, and *an unsupported claim is dropped rather than emitted*. Those are the two ways a "grounded" AI feature quietly stops being grounded, and both are asserted.

## What this run does **not** prove — and it is the honest limit of this log

These suites test **our retrieval, chunking, citation and planning logic**. They do **not** test the quality of a real language model's output, because:

- the suites run against **`MockProvider`**, not a live model — deliberate, so the suite is repeatable and needs no network (`docs/09` D23)
- **the on-device tier does not run in the Simulator**, so the real Apple Foundation Models path cannot be exercised here at all
- no live Firebase AI Logic key is configured in this build

So this log is evidence that **the machinery around the model is correct**. It is **not** evidence that the model's answers are accurate. That claim belongs to the VIVA demo on a real device, and I am not going to let a green suite imply otherwise.

## Manual / on-device pass — **outstanding, and this one matters**

- [ ] On a **real Apple Intelligence device**, ask a question about an uploaded PDF and confirm the answer is drawn from that file
- [ ] Tap a citation chip and confirm it opens the right page
- [ ] Ask a question the material **cannot** answer, and confirm the app **says so instead of guessing** ← the single most important manual test in this log
- [ ] Trigger the **on-device-unavailable fallback** (`80_Coach_OnDeviceUnavailable_Fallback`) and confirm it explains itself
- [ ] Confirm the generated study path matches the student's actual weak topics
- [ ] VoiceOver pass over H01–H08

## Defects found

**None in the automated run.** Two honest notes rather than defects:

1. The simulated-player limitation in F09 applies to nothing here, but the **mock-provider** limitation above does, and it is a real limit on what this log can claim.
2. `AITier.swift` still carries an open `TODO(M2 · F15)` for the planned tier engine, and `PromptTemplates.swift` one for a Firestore-backed template store. Both are tracked by their owners in `docs/TODOLIST.md` §1.

## Verdict

**Pass on logic; model quality unverified.** This is the advanced feature, so the manual pass above is the one I would insist on completing before the VIVA — particularly the *"ask something the material cannot answer"* case.
