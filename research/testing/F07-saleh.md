# Test log — F07 Progress Tracking

| Field | Value |
|---|---|
| **Tester** | **M1, Saleh Abdulla** (`202300540`) |
| **Developer** | M3, Tasbeeh Saeed (`202305409`) — *not me* |
| **Date** | 15 October 2026 |
| **Build** | `xcodebuild … -scheme StudyForge -destination 'platform=iOS Simulator,name=iPhone 17' test` |
| **Feature** | F07 Progress Tracking · screens G10–G13, B05 |

## What was run

```bash
xcodebuild -project ios/StudyForge/StudyForge.xcodeproj -scheme StudyForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:StudyForgeTests/ProgressCalculatorTests \
  -only-testing:StudyForgeTests/ProgressDashboardViewModelTests \
  -only-testing:StudyForgeTests/ProgressSnapshotTests
```

## Observed result

```
✔ Suite "Progress calculator" passed
✔ Suite "Progress dashboard (F07)" passed
✔ Suite "Progress snapshot" passed
✔ Test run with 41 tests in 6 suites passed
** TEST SUCCEEDED **
```

## Cases covered

| Behaviour | Covered by | Result |
|---|---|---|
| The week always has **seven** days, even with no activity | `ProgressCalculatorTests` | ✅ pass |
| Only the **current** week's minutes are totalled | `ProgressCalculatorTests` | ✅ pass |
| An unbroken run of days counts from today backwards | `ProgressCalculatorTests` | ✅ pass |
| **Studying yesterday but not today keeps the streak the student earned** | `ProgressCalculatorTests` | ✅ pass |
| A streak older than yesterday is broken | `ProgressCalculatorTests` | ✅ pass |
| No activity means no streak (not a crash, not a zero-length streak) | `ProgressCalculatorTests` | ✅ pass |
| With one feature used, that feature's mastery **is** the headline | `ProgressSnapshotTests` | ✅ pass |
| With both features used, the headline blends them | `ProgressSnapshotTests` | ✅ pass |
| Cards past the mastered interval count as mastered | `ProgressSnapshotTests` | ✅ pass |
| Topic mastery groups answered questions and **sorts weakest first** | `ProgressSnapshotTests` | ✅ pass |
| An empty input produces an empty snapshot | `ProgressSnapshotTests` | ✅ pass |
| A topic answered correctly every time is not flagged weak | `ProgressSnapshotTests` | ✅ pass |

**The streak boundary is the interesting part**, and it is covered both ways: *yesterday-but-not-today* keeps the streak (a student is not punished for not having studied yet today), while a gap older than yesterday breaks it. That pair is exactly where a streak bug would hide, so I checked both.

## Manual / on-device pass — **outstanding**

- [ ] Open the progress dashboard with **seeded demo data** and confirm the numbers match the data
- [ ] Confirm the **weakness radar** and the topic bars agree with each other
- [ ] Check the empty state for a brand-new account (no activity yet)
- [ ] Confirm the dashboard is readable at **AX5** Dynamic Type
- [ ] VoiceOver pass over G10–G13

## Defects found

**None.** The date-boundary cases above are the ones I expected to be fragile and they pass; the manual pass is what remains.

## Verdict

**Pass on logic; manual pass outstanding.**
