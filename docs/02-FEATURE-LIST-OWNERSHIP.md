# 02 — Feature List & Ownership

> Rubric area **b · Features List — 4 marks**. Requirement text, verbatim:
> *"Submit a structured feature list. Include feature name, user role, main task, flow, developer, and tester. Use at least three user roles. Each student must develop at least two features. Include one approved advanced feature assigned to one or two developers."*

**How this document satisfies it, point by point:**

| Requirement | Where satisfied |
|---|---|
| Structured feature list | §4 master table (`ID · Feature · Role · Main task · Flow · Developer · Tester`) |
| Feature name | §4, column *Feature* |
| User role | §4, column *Role* — 4 distinct roles used |
| Main task | §4, column *Main task* (user-perspective outcome) |
| Flow | §4, column *Flow* (compact) + expanded sub-task steps in §6 |
| Developer | §4, column *Developer* |
| Tester | §4, column *Tester* |
| ≥3 user roles | 4 roles: Student, Tutor, Study Group Member, Admin |
| Each student ≥2 features | §3 workload-balance table: every member owns exactly 3 |
| One advanced feature, 1–2 developers | §5 — **F15 AI Study Companion**, developers M2 + M3 |

---

## 1. Ownership convention

Feature IDs are **stable** and referenced across every other document (`F03` → screens `D01–D07` → Firestore collections → test cases → rubric evidence). Never renumber; supersede instead.

| Prefix | Meaning |
|---|---|
| `F01…F14` | Standard feature |
| `F15` | Approved **advanced** feature (co-owned) |
| `M1…M5` | Team member handle (see §2) |
| `P0 / P1 / P2` | Priority tier — P0 = MVP must ship, P1 = should ship, P2 = stretch |

---

## 2. Team roster

> ⚠️ **Group size:** the brief mandates *"each group should consist of 5 members only."* **Four members are confirmed; M5 is an open slot.** Until the 5th member is confirmed with the tutor, M5's features stay unassigned and the contingency plan at the end of this section applies. Everything else in this document is final.

| Handle | Name | Student ID | Role in team | Features owned | Frame suffix | Count |
|---|---|---|---|---|---|---|
| **M1** | **Saleh Abdulla** | `202300540` | Data & Auth lead | F01, F02, F14 | `Saleh_202300540` | 3 |
| **M2** | **Mohammed Almadhoon** | `202401702` | AI/ML lead | F03, F04, F05, **F15 (co)** | `Mohammed_202401702` | 3 + shared |
| **M3** | **Tasbeeh Saeed** | `202300549` | Architecture & Scheduling lead | F06, F07, **F15 (co)** | `Tasbeeh_202300549` | 2 + shared |
| **M4** | **Shahad Ashoor** | `202305767` | UI/UX & Collaboration lead | F08, F09, F10 | `Shahad_202305767` | 3 |
| **M5** | **`{{TBC — 5th member}}`** | `{{2022xxxxx}}` | Payments, Tutor & Admin lead | F11, F12, F13 | `{{TBC}}` | 3 |

**How the assignment was made:** the heaviest workstreams (F01/F02 data foundation and the F15 advanced feature) went to the members with the strongest technical fit, and the two members sharing the advanced feature (M2 + M3) each carry the *lowest* standard-feature count so the advanced work never becomes a bottleneck. M4 carries the fewest screens but the most interaction-heavy page (18 collaborative frames with realtime states).

### 2.1 Contingency — if the 5th member is not confirmed

The brief requires 5 members, so **raising this with the tutor is the first action of the project** (see [doc 09 Q1](09-RISKS-OPEN-QUESTIONS.md)). If a 5th member cannot be found:

| If M5 is absent | F11 Tutor Content Studio → | F12 Admin Content Management → | F13 Subscription & Payments → |
|---|---|---|---|
| **Redistribution** | **M2** (AI content review fits their AI workstream) | **M1** (fits the Auth/roles foundation) | **M3** (fits the architecture/Cloud Functions work) |

That yields four members with 4 features each, plus the shared F15. **But it does not satisfy the brief's group-size rule** — obtain written tutor approval before relying on it. Tester duties that were assigned to M5 reassign as follows: F04 → M1, F09 → M2, F10 → M3, F14 → M1.


---

## 3. Workload-balance proof (rubric: *"the workload should be fairly distributed"*)

Counted the way the rubric counts it:

| Handle | Member | Features as **developer** | Tests (count) | Screens authored | Figma pages | Weighted effort |
|---|---|---|---|---|---|---|
| **M1** | Saleh Abdulla | 3 | 4 | 48 | 4 (A, B, C, M) | ~3.2 |
| **M2** | Mohammed Almadhoon | 3 + F15 (co) | 2 | 25 | 3 (D, E, F) | ~3.0 |
| **M3** | Tasbeeh Saeed | 2 + F15 (co) | 3 | 21 | 2 (G, H) | ~2.8 |
| **M4** | Shahad Ashoor | 3 | 3 | 18 | 1 (I) | ~2.9 |
| **M5** | `{{TBC — 5th member}}` | 3 | 3 | 29 | 3 (J, K, L) | ~3.0 |

**Balance rationale (state this in the document — markers reward the reasoning):** M2 and M3 carry the lowest screen counts *precisely because* they co-own the advanced feature F15, the highest-risk and highest-effort workstream. M4 carries the fewest frames but the most Figma-complex page (18 collaborative frames with realtime and permission states). M1 carries the highest frame count because the Auth, Library and Settings groups are the most interconnected — but Groups B (13 settings frames) and M (14 state/kit frames) are low-complexity form and component frames, so raw frame count overstates the effort.

**Optional rebalance if the team wants a tighter frame split:** move **Group M (14 cross-cutting state frames)** from M1 to M4, giving M1 = 34 and M4 = 32. This is a clean swap because Group M contains no feature logic — only shared states — and it would also balance the Figma page count. Record the decision in [doc 09 §2](09-RISKS-OPEN-QUESTIONS.md) if taken.

**Testing rotation principle:** nobody tests a feature they developed, and every member tests at least two features owned by someone else. See the matrix in §7.


---

## 4. Master feature list (rubric deliverable table)

**Legend:** *Flow* is written as `trigger → step → … → outcome`.

| ID | Feature | Role | Main task | Flow | Dev | Tester |
|---|---|---|---|---|---|---|
| **F01** | Authentication & Role-Based Onboarding | All | Get a verified user onto the correct role-specific home screen | Launch → Splash → Onboarding (3) → Sign up email → OTP verify → Role select → Profile wizard → Role home | M1 | M4 |
| **F02** | Material Upload & Course Library | Student, Tutor | Turn a PDF / photo / scan / link into a searchable, tagged, offline-available library item | Pick source → on-device compress + OCR → upload to Storage → write metadata → item appears in Library → open viewer | M1 | M3 |
| **F03** | AI Summary & Notes Generation | Student | Produce an accurate, cited summary of a chosen material | Open material → Generate sheet → choose length / style / language → grounded generation → TL;DR + key points + glossary → provenance chips → save to folder | M2 | M1 |
| **F04** | Flashcard Generation & Spaced Repetition | Student | Convert material into reviewable cards and have them scheduled automatically | Generate config (count / difficulty / card type) → review + edit cards → start session → flip → rate Again/Hard/Good/Easy → SM-2 writes next due date → session summary | M2 | M5 |
| **F05** | Quiz Generation & Attempt Analytics | Student, Tutor | Test recall and expose weak topics | Configure (MCQ / true-false / short answer, count, timer) → generate → answer with immediate feedback → submit → scorecard → review explanations → attempts feed `topicMastery` | M2 | M4 |
| **F06** | Study Plan Scheduling & Adaptive Re-planning | Student | Get a realistic, exam-aware revision calendar that fixes itself | Wizard (subjects → availability → deadlines → intensity) → AI plan → week/month calendar → session reminders → missed session → offer AI re-plan → accept | M3 | M2 |
| **F07** | Progress Tracking & Analytics | Student, Tutor | See mastery, streaks and weak areas over time | Activity events recorded → nightly aggregation → dashboard (streak, mastery %, time) → subject breakdown → weakness radar → achievements → export PDF | M3 | M1 |
| **F08** | Shared Study Folders | Study Group Member | Share resources with a study group, with real permissions | Create folder → invite by code / link / picker → assign view / comment / edit → members add materials and AI artefacts → folder activity feed | M4 | M3 |
| **F09** | Group Revision Spaces | Study Group Member | Revise together, synchronously, in real time | Join by code → shared board + pinned resources → group chat → launch live group quiz → real-time progress + leaderboard → results summary | M4 | M2 |
| **F10** | Resource Bookmarking & Collections | Student | Save anything for later and actually revisit it | Bookmark from any screen (long-press or toolbar) → choose / create collection → offline cache → collection view → resume navigation via deep link | M4 | M5 |
| **F11** | Tutor Content Studio | Tutor | Publish and manage course material for a cohort | Create course → build roster → publish material → AI content review queue → approve / edit / reject → cohort progress view → send announcement → export gradebook | M5 | M1 |
| **F12** | Admin Content Management & Moderation | Admin | Keep content correct, safe and compliant | Admin home KPIs → user list → user detail (role change / suspend) → moderation queue → flagged reports → taxonomy manage → AI config → audit log | M5 | M3 |
| **F13** | Subscription & Payments | Student | Buy and manage a premium tier securely | Paywall → plan select → compare → order summary (BHD) → Tap card / BenefitPay → processing → server-side verification → entitlement written → receipt → manage / cancel | M5 | M4 |
| **F14** | Notifications & Reminders | All | Bring the user back at exactly the right moment | Server event or local schedule → relevance / quiet-hours filter → FCM push or local notification → tap → deep link → inbox → preferences | M1 | M5 |
| **F15** | **ADVANCED** · AI Study Companion (RAG + Adaptive Coach) | Student | Ask anything grounded in *your own* materials and receive a personalised study path | Ask → on-device embedding search over own library → grounded answer with citation chips → adjust explanation level → get recommended study path → rate the response | **M2 + M3** | M1 + M5 |

---

## 5. Advanced feature declaration (rubric: *"one approved advanced feature assigned to one or two developers"*)

### F15 · AI Study Companion — Retrieval-Augmented Generation + Adaptive Coach

| Field | Value |
|---|---|
| **Feature ID** | F15 |
| **Developers** | **M2 and M3** — exactly two, as the rubric permits |
| **Screens** | `73`–`80` (8 frames, group H) |
| **Supporting screens for testing** | `41` (quota error), `76` (citation sheet), `133` (offline banner) |
| **Tutor approval** | ⬜ **REQUIRED — record here once obtained** (`Approved by: ____ on ____, in class / by email`) |

**Why this qualifies as an *advanced* feature** (the brief's own examples are *"LLM integration, maps, group chats, or real-time multiplayer"*) — F15 is not one technique, it is a **system of four techniques**:

1. **Retrieval-Augmented Generation over the user's own corpus.** Materials are chunked during extraction; each chunk is embedded on-device using `NLEmbedding` (NaturalLanguage framework) and stored as vectors alongside the chunk in SwiftData. A question is embedded, top-k chunks are retrieved by cosine similarity, and only those chunks are placed in the model's context window.
2. **Grounded generation with enforced citation.** The prompt contract requires every factual claim to reference a retrieved chunk ID. Claims with no supporting chunk are dropped rather than emitted, and the UI renders citation chips (`76_Coach_Citation_SourceSheet`). This is the concrete answer to the brief's accuracy question.
3. **Adaptive study path generation.** The coach reads `topicMastery` (written by F05 quiz attempts and F04 card ratings) and produces an ordered path — read → cards → quiz → review — each step with an estimated duration. This is **multi-source reasoning over the user's own behavioural data**, not a chat wrapper.
4. **Multi-tier execution with graceful degradation.** Runs on-device when Apple Intelligence is available (free, private, offline); falls back to Firebase AI Logic otherwise; shows `80_Coach_OnDeviceUnavailable_Fallback` rather than failing.

**Ownership split (deliberate, to keep two developers non-blocking):**

| Owner | Scope | Deliverables |
|---|---|---|
| **M2** | Retrieval + generation layer | Chunking, `NLEmbedding` index, cosine-similarity retrieval, prompt contract, citation enforcement, `AIProvider` routing, screens `73`, `74`, `75`, `76`, `79`, `80` |
| **M3** | Adaptation + planning layer | `topicMastery` contract with F05/F07, study-path generator, effort estimation, integration with the F06 planner, screens `77`, `78` |

**Interface contract between them** (freeze before implementation):
```swift
protocol RetrievalService {
    func index(materialID: String, chunks: [TextChunk]) async throws
    func retrieve(query: String, scope: [String], topK: Int) async throws -> [RetrievedChunk]
}

protocol CoachPlanningService {
    func studyPath(for userID: String, weakTopics: [TopicScore]) async throws -> [StudyStep]
}
```

**Fallback if F15 slips:** the app remains fully functional — the Coach tab degrades to a "coming soon" state and F15 is documented as a Phase-2 roadmap item. **This must never block the prototype**, which is why M2 and M3 own only 2–3 standard features each.

---

## 6. Expanded sub-task steps

The rubric asks for *"Sub-Tasks/Steps: Describe a brief flow or individual steps required to complete the feature."* Copy these straight into the Design Document.

| ID | Sub-tasks / steps | Edge cases & error handling | Data touched |
|---|---|---|---|
| **F01** | 1 Tap "Create account" · 2 Enter email + password (inline validation) · 3 Receive + enter 6-digit OTP · 4 Choose role · 5 Complete 3-step profile wizard · 6 Land on role home | Email already registered · invalid/expired OTP · weak password · user abandons mid-wizard (resume later) · no network | `users/{uid}`, Auth custom claims |
| **F02** | 1 Tap Upload · 2 Choose source · 3 Downscale/compress · 4 Run OCR/text extraction with page markers · 5 Upload file to Storage · 6 Write metadata doc · 7 Item appears in Library | Unsupported format · file too large · scan with no detectable text · OCR partially fails · upload interrupted (resume) · duplicate file (hash match → offer replace) | `materials/{id}`, `courses/{id}`, Storage `users/{uid}/materials/` |
| **F03** | 1 Open material · 2 Choose Generate → Summary · 3 Set length/style/language · 4 Router picks AI tier · 5 Stream generation · 6 Attach provenance chips · 7 Save to folder | Quota exhausted · on-device model unavailable · generation too long (timeout) · user cancels mid-stream · material has <200 words | `summaries/{id}`, `aiCache/{hash}`, `aiUsage/{uid}/{date}` |
| **F04** | 1 Choose source + card config · 2 Generate cards · 3 Review/edit before saving · 4 Save to deck · 5 Start review session · 6 Flip + rate Again/Hard/Good/Easy · 7 SM-2 computes next due date · 8 Session summary | Zero cards generated · duplicate cards vs existing deck · user rates then closes early (partial save) · offline creation (queue for sync) | `decks/{id}`, `cards/{id}`, `cardReviews/{id}` |
| **F05** | 1 Configure quiz (type/count/timer) · 2 Generate questions · 3 Answer with immediate feedback · 4 Submit (confirm unanswered) · 5 View scorecard · 6 Review explanations · 7 Attempt writes `topicMastery` | Timer expires mid-quiz (auto-submit) · user backgrounds the app · ambiguous source text → low-confidence questions flagged · offline attempt (queue) | `quizzes/{id}`, `attempts/{id}`, `topicMastery/{uid}/{topic}` |
| **F06** | 1 Wizard: subjects · 2 availability · 3 deadlines · 4 intensity · 5 Generate plan · 6 View week/month calendar · 7 Receive session reminders · 8 Miss a session → offer AI re-plan · 9 Accept revised plan | No availability selected · deadline in the past · plan exceeds available hours (warn) · conflicting sessions · timezone change | `studyPlans/{id}`, `sessions/{id}`, `deadlines/{id}` |
| **F07** | 1 Activity events written by other features · 2 Aggregation job rolls up daily metrics · 3 Dashboard shows streak/mastery/hours · 4 Subject breakdown · 5 Weakness radar from `topicMastery` · 6 Achievements evaluated · 7 Export PDF report | No activity yet (empty state) · timezone day-boundary for streaks · stale aggregates (show last-updated) | `activityEvents/{id}`, `progress/{uid}`, `achievements/{id}` |
| **F08** | 1 Create folder · 2 Invite by code / link / member picker · 3 Set per-member permission · 4 Members add materials and AI artefacts · 5 Folder activity feed · 6 Owner revokes access | Invalid/expired invite code · inviting an existing member · permission downgrade on items already shared · owner leaves the folder (transfer ownership) | `folders/{id}`, `folderMembers/{id}`, `folderItems/{id}` |

| ID | Sub-tasks / steps | Edge cases & error handling | Data touched |
|---|---|---|---|
| **F09** | 1 Join group by code · 2 Shared board loads with pinned resources · 3 Group chat · 4 Host launches live quiz · 5 Members answer in real time · 6 Leaderboard updates live · 7 Final results + topic accuracy | Host disconnects mid-quiz · member joins late · duplicate answers (idempotency) · network drop during live quiz (reconnect + resync) | `groups/{id}`, `groupMessages/{id}`, `liveSessions/{id}`, `liveAnswers/{id}` |
| **F10** | 1 Long-press / tap bookmark on any artefact · 2 Choose or create a collection · 3 Optional "save offline" · 4 Item appears in collection · 5 Open later via deep link | Duplicate bookmark · collection deleted while referenced · offline bookmark (queues, resolves on reconnect) | `bookmarks/{id}`, `collections/{id}` |
| **F11** | 1 Create course · 2 Build roster (invite / code / import) · 3 Publish material with visibility + schedule · 4 AI content lands in review queue · 5 Approve / edit / reject with reason · 6 View cohort progress · 7 Send announcement · 8 Export gradebook | Student not enrolled · re-publishing an edited material (versioning) · bulk approve with low-confidence items (warn) · export with no data | `courses/{id}`, `enrollments/{id}`, `reviewQueue/{id}`, `announcements/{id}` |
| **F12** | 1 Admin home KPIs · 2 Search users · 3 Change role / suspend (with reason) · 4 Work the moderation queue · 5 Resolve flagged reports · 6 Manage taxonomy · 7 Configure AI routing + quotas · 8 Review audit log | Self-suspension blocked · demoting the last admin blocked · removing content that is referenced elsewhere (cascade warning) · audit log must be append-only | `users/{uid}`, `reports/{id}`, `tags/{id}`, `aiConfig/{doc}`, `auditLog/{id}` |
| **F13** | 1 Open paywall · 2 Select plan · 3 Order summary in BHD with VAT · 4 Choose method · 5 Tap Card SDK / BenefitPay redirect · 6 Processing state · 7 Server-side verification via webhook · 8 Entitlement written · 9 Receipt + unlocked features · 10 Manage / cancel | Card declined · 3-D Secure timeout · user closes app mid-payment (reconcile on next launch) · duplicate charge (idempotency key) · webhook arrives before redirect returns · refund path | `subscriptions/{uid}`, `payments/{id}`, custom claim `plan` |
| **F14** | 1 Server event or local schedule fires · 2 Relevance + quiet-hours filter · 3 FCM push or local notification delivered · 4 Tap deep-links to the exact screen · 5 Inbox lists history · 6 Preferences respected | Permission denied (in-app explanation + settings deep link) · duplicate notifications (dedupe key) · quiet hours · device offline (deliver on reconnect) | `notifications/{id}`, `deviceTokens/{id}`, `notificationPrefs/{uid}` |
| **F15** | 1 User asks a question in Coach · 2 Query embedded on-device · 3 Top-k chunks retrieved by cosine similarity · 4 Grounded prompt built with chunk IDs · 5 Router picks tier (on-device → cloud → fallback) · 6 Streamed answer with citation chips · 7 Tap citation → source sheet · 8 Adjust explanation level · 9 Request study path (reads `topicMastery`) · 10 Feedback captured | No relevant chunk found (say so — do **not** guess) · on-device model unavailable (show fallback screen) · very long answer (chunked streaming) · citation target material deleted · low-confidence response flagged | `chunks/{id}` (with vectors), `coachThreads/{id}`, `coachMessages/{id}`, `aiFeedback/{id}` |

**Design note to state in the document:** every feature above lists explicit edge cases. This is deliberate — the brief requires the prototype to include *"error and feedback states"*, and edge cases identified at design time are the cheapest possible way to satisfy that requirement.

---

## 7. Testing rotation matrix (rubric: *"Tester: another team member responsible for testing the feature"*)

| Feature | Developer | Primary tester | Secondary tester (cross-check) |
|---|---|---|---|
| F01 Authentication & Onboarding | M1 | **M4** | M2 |
| F02 Material Upload & Library | M1 | **M3** | M4 |
| F03 AI Summary & Notes | M2 | **M1** | M5 |
| F04 Flashcards & Spaced Repetition | M2 | **M5** | M3 |
| F05 Quiz Generation & Analytics | M2 | **M4** | M1 |
| F06 Study Plan & Adaptive Re-planning | M3 | **M2** | M5 |
| F07 Progress Tracking | M3 | **M1** | M2 |
| F08 Shared Study Folders | M4 | **M3** | M2 |
| F09 Group Revision Spaces | M4 | **M2** | M5 |
| F10 Resource Bookmarking | M4 | **M5** | M1 |
| F11 Tutor Content Studio | M5 | **M1** | M3 |
| F12 Admin Content Management | M5 | **M3** | M4 |
| F13 Subscription & Payments | M5 | **M4** | M1 |
| F14 Notifications & Reminders | M1 | **M5** | M3 |
| F15 AI Study Companion *(advanced)* | M2 + M3 | **M1** | M5 |

**Coverage check:** **M1 (Saleh) tests 4** · **M2 (Mohammed) tests 2** · **M3 (Tasbeeh) tests 3** · **M4 (Shahad) tests 3** · **M5 (TBC) tests 3** = 15 features covered. **Nobody tests a feature they developed**, and every member tests at least two features owned by someone else.

**Handle → name legend for the matrix above:** M1 = Saleh Abdulla · M2 = Mohammed Almadhoon · M3 = Tasbeeh Saeed · M4 = Shahad Ashoor · M5 = `{{TBC — 5th member}}`.

**If M5 is not confirmed,** reassign their testing duties: F04 → M1, F09 → M2, F10 → M3, F14 → M1 (giving M1 = 6, M2 = 3, M3 = 4, M4 = 3, still nobody testing their own work).


---

## 8. Traceability matrix (feature → screen → data → rubric)

This is the table that goes in the Design Document appendix. It lets a marker follow any requirement all the way from the brief to a screen and a collection.

| Feature | Screens | Firestore collections | Design Doc section | Rubric areas served |
|---|---|---|---|---|
| **F01** Auth & Role Onboarding | A01–A10, B01–B04, M14 | `users`, `users/{uid}/private` | §7, §10 | b (roles) · c (mockups) |
| **F02** Material Upload & Library | C01–C11 | `materials`, `materials/{id}/chunks`, Storage | §7, §9, §10 | a (accuracy) · b · c |
| **F03** AI Summary & Notes | D01–D07 | `summaries`, `aiCache`, `aiUsage` | §7, §13, §14 | a · b · c · d |
| **F04** Flashcards & Spaced Repetition | E01–E09 | `decks`, `decks/{id}/cards` | §7, §13 | a (revisit) · b · c |
| **F05** Quiz Generation & Analytics | F01–F09 | `quizzes`, `quizzes/{id}/questions`, `quizAttempts`, `topicMastery` | §7, §13 | a · b · c |
| **F06** Study Plan & Adaptive Re-planning | G01–G09 | `studyPlans`, `sessions`, `deadlines` | §7, §13 | a (planning) · b · d |
| **F07** Progress Tracking | G10–G13, B05 | `activityEvents`, `progress`, `achievements` | §7, §13 | a · b · d |
| **F08** Shared Study Folders | I01–I07 | `folders`, `folders/{id}/items`, `folders/{id}/members` | §7, §14 | a (collaboration) · b · c |
| **F09** Group Revision Spaces | I08–I14, M13 | `groups`, `groups/{id}/messages`, `liveSessions` | §7, §13, §14 | b · c · d |
| **F10** Resource Bookmarking | I15–I18, M05 | `collections`, `bookmarks` | §7 | a (organise) · b |
| **F11** Tutor Content Studio | J01–J10 | `courses`, `enrollments`, `reviewQueue`, `announcements` | §7, §16 | b (tutor role) · c |
| **F12** Admin Content Management | K01–K09 | `users`, `reports`, `tags`, `aiConfig`, `auditLog` | §7, §16 | b (admin role) · c |
| **F13** Subscription & Payments | L01–L10, B13 | `subscriptions`, `payments`, `promoCodes` | §16 | b · c · d (ethics) |
| **F14** Notifications & Reminders | M01–M04, B08, B09 | `notifications`, `deviceTokens`, `notificationPrefs` | §7 | a (revisit) · b |
| **F15** **AI Study Companion** *(advanced)* | H01–H08 | `chunks`, `coachThreads`, `coachMessages`, `aiFeedback` | §8, §13 | a (accuracy) · b (advanced) · d |

**Reading it as a checklist:** every feature maps to at least one screen, at least one collection, one document section and at least two rubric areas. A feature that maps to only one of those is under-specified.







