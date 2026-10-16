# Test log — F09 Group Revision Spaces

| Field | Value |
|---|---|
| **Tester** | **M1, Saleh Abdulla** (`202300540`) |
| **Developer** | M4, Shahad Ashoor (`202305767`) — *not me* |
| **Date** | 15 October 2026 |
| **Build** | `xcodebuild … -scheme StudyForge -destination 'platform=iOS Simulator,name=iPhone 17' test` |
| **Feature** | F09 Group Revision Spaces · screens I08–I14, M13 |

## What was run

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:StudyForgeTests/GroupStoreTests \
  -only-testing:StudyForgeTests/GroupListViewModelTests \
  -only-testing:StudyForgeTests/GroupDetailViewModelTests \
  -only-testing:StudyForgeTests/GroupChatViewModelTests \
  -only-testing:StudyForgeTests/LiveQuizViewModelTests
```

## Observed result

```
✔ Suite "Group store" passed
✔ Suite "Group list and join (F09)" passed
✔ Suite "Group board (F09)" passed
✔ Suite "Group chat (F09)" passed
✔ Suite "Live group quiz (F09)" passed
✔ Test run with 42 tests in 8 suites passed     ← this run also carried the F15 suites
** TEST SUCCEEDED **
```

## Cases covered

| Behaviour | Covered by | Result |
|---|---|---|
| The in-memory store returns groups **most recently updated first** | `GroupStoreTests` | ✅ pass |
| A group round-trips through the store unchanged | `GroupStoreTests` | ✅ pass |
| Joining with an unknown invite code produces the **code-not-found** error | `GroupListViewModelTests` | ✅ pass |
| Joining a group you are already in is refused, not silently duplicated | `GroupListViewModelTests` | ✅ pass |
| The board renders pinned resources and members | `GroupDetailViewModelTests` | ✅ pass |
| A chat message is **stored and then re-read**, so the screen shows what persisted | `GroupChatViewModelTests` | ✅ pass |
| A blank draft cannot be sent | `GroupChatViewModelTests` | ✅ pass |
| The live quiz orders the leaderboard score-first, and ties are stable | `LiveQuizViewModelTests` | ✅ pass |
| Per-topic accuracy on the results screen matches the answers given | `LiveQuizViewModelTests` | ✅ pass |

## What this run does **not** prove, and I want that on the record

The **live group quiz is single-device and simulated.** `LiveQuizSession` documents this itself: the student's own answering and scoring are real, but the other players' answers are **deterministically simulated**, because `liveSessions/{id}/answers/…` needs a realtime backend that is not wired up. So:

- the **leaderboard arithmetic** is genuinely tested
- **two devices actually seeing each other** is **not** tested, and cannot be until the backend lands

I am stating that rather than letting a green suite imply multiplayer works.

## Manual / on-device pass — **outstanding**

- [ ] Create a group, read the invite code, and **join from a second account**
- [ ] Send a message and confirm it appears for both accounts
- [ ] Pin a resource to the board and confirm it renders
- [ ] Run the live quiz on two simulators and compare the leaderboards
- [ ] Check the **disconnected-player** state (`LiveQuizSession`'s open reconnect item)

## Defects found

**None in the automated run.** The known limitation above is a **documented design constraint**, not a defect I found — `LiveQuizSession.swift` already carries a `TODO(M4 · F09)` for the reconnect/resync path, so it is tracked by its owner.

## Verdict

**Pass on logic; single-device only.** Multi-device behaviour is explicitly untested and is the one thing I would want to verify before the VIVA.
