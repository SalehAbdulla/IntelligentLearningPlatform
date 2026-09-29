# 05 — Data Model & Security

> Firestore + Cloud Storage schema, role model and security rules for **StudyForge**. Feeds Phase 7 of the [roadmap](01-ROADMAP-PHASES-TODOLIST.md) and the Design Document's architecture section.

---

## 1. Data modelling rules

| # | Rule | Reason |
|---|---|---|
| 1 | **Denormalise for reads.** Store course name, deck title and author display name on the child document. | Firestore has no joins; a client-side join costs N extra reads — the classic cost trap. |
| 2 | **Subcollections for high-cardinality children.** `decks/{id}/cards/{id}`, `quizzes/{id}/questions/{id}`. | Keeps parent documents small and avoids the 1 MiB document limit. |
| 3 | **Every document carries `createdAt`, `updatedAt`, `byUid`.** | Auditability (LO3) and conflict resolution during offline sync. |
| 4 | **Soft delete** via `deletedAt`, purged by a scheduled function. | Undo, and referential safety during sync. |
| 5 | **Every list query is index-backed and paginated at 20.** | Read-cost control. |
| 6 | **All AI artefacts store provenance** (`sourceChunkIds`, `pageNumbers`, `confidence`). | This is the accuracy story from [doc 00 §2](00-MASTER-PLAN.md). |
| 7 | **Client writes are minimal; aggregations run server-side.** | Write-cost control. |
| 8 | **Counters use distributed shards** for concurrently-written values (e.g. live-quiz answers). | Firestore's ~1 write/sec per-document limit. |
| 9 | **Vectors live on-device in SwiftData, not in Firestore.** | A 512-float vector per chunk would destroy both the free tier and the privacy story. |
| 10 | **Never store secrets or card data.** Only Tap charge references. | Avoids PCI-DSS scope entirely. |

---

## 2. Collections map

### 2.1 Identity, roles and platform

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `users/{uid}` | Profile, role, academic details, learning style, plan | self · tutor (cohort) · admin | self (limited fields) · admin |
| `users/{uid}/private/prefs` | Notification prefs, AI privacy settings, quiet hours | self only | self only |
| `deviceTokens/{uid}/tokens/{token}` | FCM tokens | self · CF | self · CF |
| `auditLog/{id}` | Append-only admin action trail | admin only | **CF only** (rules deny client writes) |
| `aiConfig/{doc}` | Engine routing policy, prompt templates, quotas | admin · CF (app reads via Remote Config) | admin only |

### 2.2 Academic structure

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `courses/{courseId}` | Course metadata, tutor, term | enrolled students · tutor · admin | tutor · admin |
| `enrollments/{uid_courseId}` | Student ↔ course membership and role | self · tutor · admin | tutor · admin |
| `materials/{materialId}` | Upload metadata, extraction stats, tags, visibility | owner · folder members · enrolled students (if published) · admin | owner · tutor (published) |
| `materials/{id}/chunks/{chunkId}` | Text chunks with page + offset (vectors stay on-device) | same as parent | owner · CF |

### 2.3 AI artefacts

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `summaries/{id}` | Generated summary + provenance + confidence | owner · folder members · tutor | owner · CF |
| `decks/{deckId}` | Flashcard deck metadata + SR stats | owner · folder members · tutor | owner |
| `decks/{deckId}/cards/{cardId}` | Front/back, tags, SR state (`ease`, `interval`, `dueAt`, `reps`) | owner · folder members | owner |
| `quizzes/{quizId}` | Generated quiz metadata + settings | owner · folder members · tutor | owner |
| `quizzes/{id}/questions/{qId}` | Question, options, answer, explanation, provenance | owner · folder members | owner |
| `quizAttempts/{id}` | Attempt score + per-question responses | self · tutor (cohort) · admin | self · CF |
| `topicMastery/{uid}/topics/{topicId}` | Per-topic mastery — feeds the weakness radar | self · tutor (aggregate) · admin | **CF only** |
| `aiCache/{textHash}` | Cached generations keyed by SHA-256 of source text | CF only | **CF only** |
| `aiUsage/{uid}/days/{yyyy-mm-dd}` | Per-user daily AI generation counter | self (for quota UX) · admin | **CF only** |
| `coachThreads/{threadId}` | Advanced-feature conversation thread | owner | owner |
| `coachThreads/{id}/messages/{msgId}` | Messages + citations + confidence | owner | owner · CF |
| `aiFeedback/{id}` | Response ratings (feed prompt improvement) | owner · admin | owner |

### 2.4 Collaboration

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `groups/{groupId}` | Study group metadata, owner, hashed invite code | members | owner · admin |
| `groups/{id}/members/{uid}` | Member list + role | members | owner |
| `groups/{id}/messages/{msgId}` | Group chat | members | members |
| `liveSessions/{id}` | Live group-quiz state, current question index | members | host · CF |
| `liveSessions/{id}/answers/{uid_qIndex}` | Per-player answers (idempotent key) | host · self | self |
| `folders/{folderId}` | Shared study folder | owner · members | owner · editors |
| `folders/{id}/items/{itemId}` | References to materials / decks / summaries in the folder | owner · members | owner · editors |
| `folders/{id}/members/{uid}` | Per-member permission (`view` / `comment` / `edit`) | owner · members | owner |
| `folderInvites/{code}` | Hashed invite code → folder, expiry, max uses | **CF only** | **CF only** |

### 2.5 Bookmarks and content management

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `collections/{id}` | User bookmark collections | owner | owner |
| `bookmarks/{id}` | Saved reference (type + target id + snapshot title) | owner | owner |
| `reviewQueue/{id}` | Tutor AI-content review items (approve / edit / reject) | tutor · admin | tutor |
| `announcements/{id}` | Tutor announcements to a cohort | enrolled students · tutor | tutor |
| `reports/{id}` | User-submitted content reports | reporter · admin | reporter · admin |
| `tags/{id}` | Canonical taxonomy (subject / topic tags) | everyone (public list) | admin |

### 2.6 Commerce (Cloud-Function-write-only)

| Collection | Purpose | Read | Write |
|---|---|---|---|
| `subscriptions/{uid}` | Current plan, status, `periodEnd`, Tap references | self · admin | **CF only** |
| `payments/{paymentId}` | Charge reference, amount, method, status, idempotency key | self (own) · admin | **CF only** |
| `promoCodes/{code}` | Discount validation | **CF only** | admin |

---

## 3. Representative document schemas

```jsonc
// users/{uid}
{
  "displayName": "Sara Ali",
  "email": "sara@university.edu.bh",
  "studentId": "202211987",
  "role": "student",              // student | tutor | admin
  "plan": "free",                 // free | plus | pro  (mirrored to a custom claim)
  "university": "University of Bahrain",
  "major": "Computer Science",
  "year": 3,
  "learningStyle": "visual",      // visual | verbal | readwrite | kinesthetic
  "accessibility": { "dyslexiaFont": false, "textScale": 1.0, "reduceMotion": false },
  "weeklyStudyGoalHours": 12,
  "createdAt": "<timestamp>", "updatedAt": "<timestamp>", "byUid": "<uid>"
}
```

```jsonc
// materials/{materialId}
{
  "ownerUid": "<uid>",
  "courseId": "cs201",
  "title": "Lecture 4 — Normalisation",
  "sourceType": "pdf",            // pdf | image | scan | link | text
  "storagePath": "users/<uid>/materials/<id>.pdf",
  "pageCount": 22,
  "extractedChars": 41230,
  "textHash": "sha256:9f2c…",     // powers the AI response cache
  "tags": ["databases", "normalisation"],
  "visibility": "private",        // private | folder | course
  "ocrQuality": 0.94,             // 0…1 — flags scans that need review
  "deletedAt": null,
  "createdAt": "<timestamp>", "updatedAt": "<timestamp>", "byUid": "<uid>"
}
```

```jsonc
// decks/{deckId}/cards/{cardId}
{
  "front": "What is 3NF?",
  "back": "A relation where every non-key attribute depends only on the primary key — no transitive dependencies.",
  "cardType": "qa",               // qa | cloze | imageOcclusion | reversible
  "tags": ["databases"],
  "provenance": { "materialId": "<id>", "chunkIds": ["c12","c13"], "pageNumbers": [18] },
  "confidence": "high",           // high | medium | low
  "aiDrafted": true,
  "sr": { "ease": 2.5, "interval": 0, "dueAt": "<timestamp>", "reps": 0, "lapses": 0 }
}
```

```jsonc
// subscriptions/{uid}   — written ONLY by the Tap webhook handler
{
  "plan": "plus",
  "status": "active",             // active | past_due | canceled | expired
  "periodStart": "<timestamp>",
  "periodEnd": "<timestamp>",
  "tapChargeId": "chg_…",
  "tapCustomerId": "cus_…",
  "lastPaymentId": "pay_…",
  "updatedAt": "<timestamp>"
}
```

```jsonc
// aiUsage/{uid}/days/{yyyy-mm-dd}
{
  "generations": 7,
  "byTask": { "summary": 2, "flashcards": 3, "quiz": 1, "coach": 1 },
  "tier0": 5, "tier1": 2, "tier2": 0,     // lets the admin dashboard prove the cost strategy works
  "updatedAt": "<timestamp>"
}
```

---

## 4. Cloud Storage layout

```
{default bucket — region us-central1}
users/{uid}/materials/{materialId}.pdf          # owner only
users/{uid}/materials/{materialId}_thumb.jpg    # lists never load the full PDF
users/{uid}/avatars/{uid}.jpg                   # world-readable to signed-in users
courses/{courseId}/published/{materialId}.pdf   # enrolled students, read-only
folders/{folderId}/shared/{itemId}              # folder members, read-only
reports/{reportId}/evidence.jpg                 # admin only
```

**Rules of thumb:** always store a ≤200 px thumbnail alongside the original · cap uploads at 50 MB · always compress images client-side before upload · never store generated AI text in Storage (it belongs in Firestore).

---

## 5. Role model and custom claims

Three roles and one plan value are mirrored into the Firebase Auth token as **custom claims**, set by a Cloud Function whenever `users/{uid}` changes:

```jsonc
{
  "role": "student",          // student | tutor | admin
  "plan": "plus",             // free | plus | pro
  "groupIds": ["g_1042"],     // keeps live-session rules cheap
  "faculty": false            // tutor flag for cohort-scoped reads
}
```

**Why claims rather than reading `users/{uid}` in every rule:** rules can read the token for **free**, but reading another document inside a rule costs a billed read and slows the query. This is simultaneously a cost optimisation and a performance one — worth stating explicitly in the document.

**Capability layering (from [doc 00 §7](00-MASTER-PLAN.md)):** *Study Group Member* is **not** a role. It is the presence of `groupIds` plus a `folders/{id}/members/{uid}` document carrying `permission: view | comment | edit`.

---

## 6. Security rules (pattern reference)

Full rules live in `backend/firestore.rules`. These are the patterns that matter, and they are worth reproducing in the Design Document because they evidence **server-enforced, deny-by-default security**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- helpers ----------
    function signedIn()   { return request.auth != null; }
    function uid()        { return request.auth.uid; }
    function role()       { return request.auth.token.role; }
    function isAdmin()    { return signedIn() && role() == 'admin'; }
    function isTutor()    { return signedIn() && (role() == 'tutor' || isAdmin()); }
    function isSelf(u)    { return signedIn() && uid() == u; }
    function untouched(f) { return request.resource.data[f] == resource.data[f]; }

    // 1. DENY BY DEFAULT — there is no catch-all `allow read, write: if true` anywhere.

    // 2. OWNERSHIP + ROLE on the user record; no self-promotion, no self-upgrade.
    match /users/{userId} {
      allow read:   if isSelf(userId) || isTutor() || isAdmin();
      allow create: if isSelf(userId)
                    && request.resource.data.role == 'student'
                    && request.resource.data.plan == 'free';
      allow update: if isAdmin()
                    || (isSelf(userId) && untouched('role') && untouched('plan'));
      allow delete: if isAdmin();

      match /private/{doc} { allow read, write: if isSelf(userId); }
    }

    // 3. SHARED-FOLDER ACCESS resolves through MEMBERSHIP, not ownership alone.
    match /folders/{folderId} {
      function member()   { return get(/databases/$(database)/documents/folders/$(folderId)/members/$(uid())).data; }
      function canRead()  { return isAdmin() || exists(/databases/$(database)/documents/folders/$(folderId)/members/$(uid())); }
      function canWrite() { return canRead() && member().permission == 'edit'; }

      allow read:  if canRead();
      allow write: if canWrite() || isAdmin();

      match /items/{itemId} { allow read: if canRead(); allow write: if canWrite(); }
      match /members/{memberUid} {
        allow read:  if canRead();
        allow write: if isAdmin() || resource.data.permission == 'edit';
      }
    }

    // 4. IMMUTABLE AUDIT LOG — append-only; not even admins may rewrite history.
    match /auditLog/{entryId} {
      allow read:   if isAdmin();
      allow create: if false;            // the Admin SDK (Cloud Functions) bypasses rules
      allow update, delete: if false;
    }

    // 5. SERVER-OWNED COLLECTIONS — clients read their own, never write.
    match /subscriptions/{userId}              { allow read: if isSelf(userId) || isAdmin(); allow write: if false; }
    match /payments/{paymentId}                { allow read: if isAdmin() || resource.data.uid == uid(); allow write: if false; }
    match /aiCache/{hash}                      { allow read, write: if false; }
    match /aiUsage/{userId}/days/{day}         { allow read: if isSelf(userId) || isAdmin(); allow write: if false; }
    match /topicMastery/{userId}/topics/{tid}  { allow read: if isSelf(userId) || isTutor(); allow write: if false; }
    match /progress/{userId}                   { allow read: if isSelf(userId) || isTutor(); allow write: if false; }

    // 6. AI ARTEFACTS inherit their parent material's visibility.
    match /summaries/{id} {
      allow read:   if isAdmin() || resource.data.ownerUid == uid();
      allow create: if signedIn() && request.resource.data.ownerUid == uid();
      allow update, delete: if isAdmin() || resource.data.ownerUid == uid();
    }

    // 7. TUTOR REVIEW QUEUE — only tutors/admins, and every rejection needs a reason.
    match /reviewQueue/{id} {
      allow read:  if isTutor();
      allow write: if isTutor()
                   && (!('decision' in request.resource.data)
                       || request.resource.data.reason is string);
    }
  }
}
```

**Storage rules follow the same philosophy:** `users/{uid}/**` is owner-only · `courses/{courseId}/published/**` is readable by enrolled students · `reports/**` is admin-only · everything else is denied.

**Emulator tests are mandatory.** `backend/firestore.rules.test.js` must contain **negative** tests: a student reading another student's material, a non-tutor writing the review queue, and a client trying to update its own `subscriptions` document. *Proving the rules deny the wrong people is stronger evidence for LO3 than proving they allow the right ones.*

---

## 7. Required composite indexes

| Collection | Fields | Supports |
|---|---|---|
| `materials` | `ownerUid` asc, `createdAt` desc | Library list |
| `materials` | `ownerUid` asc, `courseId` asc, `deletedAt` asc, `createdAt` desc | Course-scoped list |
| `decks` | `ownerUid` asc, `updatedAt` desc | Deck list |
| `cards` (collection group) | `ownerUid` asc, `sr.dueAt` asc | "Due today" query |
| `quizAttempts` | `uid` asc, `createdAt` desc | Quiz history |
| `folders` | `memberUids` array-contains, `updatedAt` desc | Shared-folder list |
| `groups` | `memberUids` array-contains, `updatedAt` desc | Group list |
| `bookmarks` | `ownerUid` asc, `collectionId` asc, `createdAt` desc | Collection detail |
| `reviewQueue` | `courseId` asc, `status` asc, `createdAt` asc | Tutor queue |
| `notifications` | `uid` asc, `createdAt` desc | Inbox |

Every index is declared in `backend/firestore.indexes.json` so the build is reproducible — a missing index is a runtime crash on a cold query, not a compile error.

---

## 8. Privacy, retention and compliance

| Concern | StudyForge position | Mechanism |
|---|---|---|
| Where does study material go? | Nowhere, unless the user explicitly asks for a cloud AI call | On-device extraction + tier-0 generation by default |
| Is uploaded material used for model training? | **No.** | Stated in the privacy copy; no data sharing with providers beyond the inference request |
| Right to deletion | Full self-service | `22_Settings_AIDataPrivacy` → "Delete my AI data" purges `summaries`, `decks`, `quizzes`, `chunks`, `coachThreads` and derived cache entries |
| Retention | Indefinite while the account is active; 30-day purge after account deletion | Scheduled Cloud Function |
| Minors | Out of scope — stated as an explicit limitation | Product decision, documented |
| Card data | Never stored, never seen by us | Tap SDK tokenises client-side; we hold only a charge reference |
| Academic integrity | Disclosed, not hidden | Tutor review queue (`105`), "AI-drafted" watermark on summaries, an explicit academic-integrity note in onboarding, and **no auto-grading of assessed work** |
| Accessibility | Committed and testable | VoiceOver labels, Dynamic Type to AX5, contrast ≥4.5:1, RTL, dyslexia-friendly font option |
| Auditability | Admin actions are provably logged | Append-only `auditLog`; rules deny update and delete |

**Why this section exists in the design document:** LO3 explicitly assesses *"professional ethics"*. Naming the hard problems — AI accuracy, student data, minors, academic integrity, card data — and showing a concrete control for each is exactly what that learning outcome is looking for.




