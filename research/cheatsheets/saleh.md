# Feature Cheat Sheet, Saleh Abdulla (M1)

> One page to keep open in the VIVA. Fill it in from now to the feature freeze.
> Why: the marker may ask you to explain any part of the app; this answers "where does that live and why?" in under ten seconds.

| Field | Value |
|---|---|
| **Member** | Saleh Abdulla (M1) |
| **Student ID** | `202300540` |
| **Features I develop** | **F01** Authentication & Role-Based Onboarding · **F02** Material Upload & Course Library · **F14** Notifications & Reminders |
| **Features I test** | F03 (Summary) · F07 (Progress) · F09 (Group Spaces) · F15 (AI Companion) |
| **Sprints I contributed in** | S0 [x] · S1 [x] · S2 [x] · S3 [ ] · S4 [ ] · S5 [ ] |
| **Also mine** | the project level: planning docs, `tools/`, the Design Document, the Figma file |

## My features

### F01, Authentication & Role-Based Onboarding
- **What it does, in three sentences:**
  1. A student signs up with email and password, verifies their address, and lands on the home screen for their role.
  2. The role is **not chosen in the app** — it is read from a Firebase Auth **custom claim**, so a user cannot promote themselves.
  3. Every screen that depends on a signed-in profile is gated behind that check, so the app never renders a half-configured account.
- **Key source files:**
  - `Features/Auth/` — `SplashView`, `AuthFlowView`, `SignUpView`(+VM), `LoginView`(+VM), `EmailVerificationView`(+VM), `ForgotPasswordView`(+VM)
  - `Core/Auth/` — `AuthService` (protocol), `FirebaseAuthService`, `MockAuthService`, `AuthStateStream`, **`CustomClaims`**, `PasswordStrength`, `UserSession`
- **Firestore collections / claims touched:** `users/{uid}` (profile, role, plan, academic details) · `users/{uid}/private/prefs` (owner-only) · Auth custom claims **`role`**, **`plan`**, **`groupIds`**
- **The hard part and how I solved it:** the brief wants a role-select screen, but the security model cannot allow it. `role` is **server-owned** — `firestore.rules` accepts only `role == 'student'` on create and pins it with `keeps('role')` on update, and the app reads roles from **custom claims**. So the role step is a **recorded deviation** (`docs/03` §A, `docs/09` Q13) rather than a dead control.
- **A trade-off I made:** I chose **email/password only** over adding a third-party login, because offering one would trigger App Store Guideline 4.8 (Sign in with Apple required), and that needs a paid Apple Developer account this project does not have (`docs/09` R22). The consequence is documented, not hidden.
- **A known limitation, and what I'd do about it:** four screens are drawn but deliberately **not built**, each recorded in `docs/03` §A with its reason: the **Face ID** button (needs a Keychain decision), the **6-box OTP** (Firebase email/password has no OTP — verification is by **link**), the **in-app password reset** (Firebase completes it on its hosted page; in-app needs a deep link and an associated domain), and **A10 role select** (above). With a paid account, all four become buildable.
- **Loading / empty / error / offline behaviour:** wrong credentials show an inline error banner, not a crash; an unverified address is routed back to the verification screen with a resend timer; offline sign-in fails with the app's standard network error.
- **Who tested it, and what they found:** **M5 (Fatema) primary, M3 (Tasbeeh) secondary** — I do not test my own feature.

### F02, Material Upload & Course Library
- **What it does, in three sentences:**
  1. A student imports a lecture PDF, a photo or a scan, and the app extracts its text **on the device**.
  2. The material is filed into a course library where it can be searched, tagged, bookmarked and opened offline.
  3. The extracted text is what every AI feature downstream reads — summaries, flashcards, quizzes and the companion never see the raw file.
- **Key source files:** `Features/Library/` — `ImportMaterialView`(+VM), `MaterialLibraryView`(+VM) · `Core/Materials/` — `Material`, `MaterialStore` (protocol), `FileMaterialStore`, `InMemoryMaterialStore`, **`TextExtractor`**, `PageMarker`
- **Collections / Storage paths touched:** `materials/{materialId}` · `materials/{id}/chunks/{chunkId}` (text + page + offset; **vectors stay on-device**) · Storage paths `users/{uid}/materials/…` are defined but **deliberately unused** — see the trade-off.
- **The hard part and how I solved it:** extraction. The first tier is the on-device **Vision** framework, which is free, private and instant; only if that fails does a multimodal cloud tier see the page. That ordering is what keeps large scans off the network.
- **A trade-off I made:** I chose **on-device materials behind a store seam** over uploading files to Cloud Storage, because Firebase gates the default Storage bucket behind the **Blaze** plan (`docs/09` **D24**). Uploading a PDF to a server is pointless when the AI that reads it runs on the phone — so only *derived* data syncs, and swapping in real Storage is a one-file change behind `MaterialStore`.
- **Known limitation:** the library starts from a **seeded catalogue** rather than the student's real enrolment, and a duplicate upload is not yet detected by content hash — both are open items in `docs/TODOLIST.md` §1.
- **Loading / empty / error / offline behaviour:** an import shows a compression state then an OCR progress state; an unsupported file type gets its own error screen (`30_MaterialUpload_Error_Unsupported`); the library reads from the local store, so it works offline.
- **Who tested it:** **M3 (Tasbeeh) primary, M2 (Mohammed) secondary.**

### F14, Notifications & Reminders
- **What it does, in three sentences:**
  1. The app nudges a student at the right moment — a deck is due, a study session is scheduled, a quiz is ready.
  2. It asks permission **after explaining the value**, rather than firing the system prompt cold, which is why opt-in is higher.
  3. It respects **quiet hours** and per-type preferences, so a reminder never arrives at 2 a.m.
- **Key source files:** `Features/Notifications/` — `NotificationPermissionView`(+VM), `NotificationPreferencesView`(+VM), `NotificationsInboxView`(+VM), `SettingsView` · `Core/Notifications/` — `StudyNotification`, `NotificationStore` (+File/InMemory), **`NotificationReminderPlanner`**, `NotificationScheduler`, `NotificationAuthorizer`, `NotificationPreferences`
- **Collections touched:** `notifications/{id}` · `deviceTokens/{uid}/tokens/{token}` · `users/{uid}/private/prefs` (quiet hours live here, self-only)
- **The hard part and how I solved it:** deciding *when* to fire. The **planner** computes a due reminder from the spaced-repetition state and then applies the quiet-hours filter, so scheduling is a pure function I can reason about rather than date maths tangled through a view.
- **A trade-off I made:** I chose **local notifications** for reminders over server push, because a reminder the device can compute itself costs nothing and works offline; FCM is kept for what only a server knows — a tutor broadcast.
- **Known limitation:** the "Send a test reminder" action is still an open item, and quiet-hours suppression still needs its test (both tracked in `docs/TODOLIST.md` §1).
- **Loading / empty / error / offline behaviour:** the inbox has an empty state; a denied permission shows a recovery path back into Settings rather than a silent no-op; scheduled reminders survive being offline because they are local.
- **Who tested it:** **M3 (Tasbeeh) primary, M2 (Mohammed) secondary.**

## Hard questions I should expect

| Question | My prepared answer |
|---|---|
| "Why did you build it this way?" | Role comes from a **custom claim**, not a screen, because a client-writable role is a privilege-escalation hole — `firestore.rules` will not accept `role` from a client at all. |
| "What happens with no internet?" | The **library** and the **notification planner** work offline: materials live on the device and reminders are computed locally. Only sign-in and cloud-tier AI need the network. |
| "What if the AI returns nonsense?" | F01/F02/F14 generate no AI content. Where it matters is extraction, and the first tier is on-device Vision over the student's own file, with provenance attached downstream. |
| "What does this specific function do?" | `CustomClaims` maps the Auth token's claims onto the app's `AppRole` and plan, so **one** place decides what a user is instead of a dozen view-level checks. |
| "What doesn't work?" *(always have a real answer)* | Face ID, the OTP screen, in-app password reset and the role-select screen are **drawn but not built**, each with a written reason in `docs/03` §A. Duplicate-upload detection by content hash is not implemented. |
| "What would you change with more time?" | Buy the paid Apple Developer account: it unlocks Face ID, the associated domain for a deep-linked reset, and Sign in with Apple — four recorded deviations at once. |

## Where things live, the 10-second drill

| Feature | Screens | View | ViewModel | Store | Collections |
|---|---|---|---|---|---|
| F01 | A01–A10, B01–B04 | `Features/Auth/` | `SignUpViewModel`, `LoginViewModel` | `AuthService` | `users/{uid}` |
| F02 | C01–C11 | `Features/Library/` | `ImportMaterialViewModel`, `MaterialLibraryViewModel` | `MaterialStore` | `materials`, `materials/{id}/chunks` |
| F14 | M01–M04, B08, B09 | `Features/Notifications/` | `NotificationsInboxViewModel`, `NotificationPreferencesViewModel` | `NotificationStore` | `notifications`, `deviceTokens`, `users/{uid}/private/prefs` |

**Drill:** pick a random row, navigate to the file, and name its collection within ten seconds.

## VIVA evidence I can point to

- [x] Merged PRs — `git log --author="Saleh Abdulla" --merges`, 90+ on this repository
- [x] Hand-written commits — `git log --author="Saleh Abdulla" --grep="hand:"`
- [ ] Test logs for F03, F07, F09, F15 → `research/testing/F0*-saleh.md`
- [ ] Sprint review recording(s) where I demoed my own work
- [x] Figma frames named `Saleh_202300540` — **36 frames**, groups A, B, C and M
- [x] Contribution logs — `research/sprints/sprint-1/saleh-contribution.md`, `research/sprints/sprint-2/saleh-contribution.md`
