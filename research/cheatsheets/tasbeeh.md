# Feature Cheat Sheet, Tasbeeh Saeed (M3)

> One page to keep open in the VIVA. Fill it in from now to the feature freeze.

| Field | Value |
|---|---|
| **Member** | Tasbeeh Saeed (M3) |
| **Student ID** | `202300549` |
| **Features I develop** | F06, F07, F13, F15 (co) |
| **Features I test** | F02, F08, F10, F14 |
| **Sprints I contributed in** | S0 [ ] · S1 [ ] · S2 [ ] · S3 [ ] · S4 [ ] · S5 [ ] |

## My features

### F06, Study Plan Scheduling & Adaptive Re-planning
- **What it does, in three sentences:** 1. 2. 3.
- **Key source files:** `Features/StudyPlan/`, `Core/Planning/`
- **The hard part and how I solved it:** (the scheduler / re-plan logic, hand-written)
- **A trade-off I made:** I chose ______ over ______ because ______.
- **Known limitation:**
- **Loading / empty / error / offline behaviour:**
- **Who tested it (should be M2):**

### F07, Progress Tracking & Analytics
- **Key source files:** `Features/Progress/`, `Core/Progress/`
- **The hard part:**
- **A trade-off I made:**
- **Known limitation:**
- **Who tested it (should be M1):**

### F13, Subscription & Payments
- **What it does, in three sentences:** 1. 2. 3.
- **Key source files:** `Features/Subscription/`, `Core/Payments/`
- **The hard part:** the `PaymentGateway` abstraction, Tap sandbox flow, server-side verification, idempotency
- **A trade-off I made:** (Apple 3.1.1 vs the client's Bahrain gateway, documented, not hidden)
- **Known limitation:**
- **Who tested it (should be M2):**

### F15, AI Study Companion (co-owned with M2)
- **Key source files:** `Features/Coach/`, the router integration
- **The hard part (my half):** the planner, the AI-router tier selection
- **A trade-off I made:**
- **Known limitation:**
- **Who tested it (should be M1):**

## Hard questions I should expect

| Question | My prepared answer |
|---|---|
| "Why not Apple In-App Purchase?" | Guideline 3.1.1 vs the client's Tap gateway; one `PaymentGateway` protocol, both implementations, the conflict documented |
| "How is the plan re-planned?" | |
| "Where does the AI cost go?" | |
| "What doesn't work?" | |
| "What would you change with more time?" | |

## VIVA evidence I can point to

- [ ] Merged PR(s): links
- [ ] Hand-written commits: `git log --author="Tasbeeh Saeed" --grep="hand:"`
- [ ] Test logs for F02, F08, F10, F14
- [ ] Emulator rules-test result
- [ ] Sprint review recording(s) where I demoed my own work
