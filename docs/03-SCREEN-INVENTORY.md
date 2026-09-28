# 03 — Screen Inventory & Figma Naming

> Rubric area **c · Mockups — 8 marks** (largest single block) and the entire **Project Prototype — 20 marks**.

**Rubric requirements this document serves:**

- *"Include multiple screens if the feature requires them."*
- *"Contain written descriptions for each screen explaining its purpose and layout."*
- *"Identify and label all UI elements, such as buttons, inputs, and labels, and explain their function."*
- *"The mockups should include all necessary screens, show clear navigation or screen flow."*
- *"All main features of the app are designed and linked based on your feature list."*
- *"Error & feedback states — user feedback, success, and error screens or messages should be included."*
- *"all frames/screens must be clearly named by developer, such as Login_Ahmed_2022XXXXX"* ← **mandatory naming rule**

---

## 1. Figma frame naming rule (non-negotiable)

The brief gives an explicit example format. We follow it **exactly**, extended with a sortable prefix:

```
NN_ScreenName_FirstName_StudentID
```

| Part | Rule | Example |
|---|---|---|
| `NN` | Two-digit sortable index, unique across the file | `03` |
| `ScreenName` | PascalCase, noun-first, from this document's inventory | `Login` |
| `FirstName` | Developer's first name, exactly as on the roster | `Saleh` |
| `StudentID` | Full student ID, no spaces | `202300540` |

**Handle → frame suffix (the roster, from [doc 02 §2](02-FEATURE-LIST-OWNERSHIP.md))**

| Handle in this doc | Member | Frame suffix to append |
|---|---|---|
| `{M1}` | Saleh Abdulla | `Saleh_202300540` |
| `{M2}` | Mohammed Almadhoon | `Mohammed_202401702` |
| `{M3}` | Tasbeeh Saeed | `Tasbeeh_202300549` |
| `{M4}` | Shahad Ashoor | `Shahad_202305767` |

**Worked examples using the real roster**

```
03_Login_Saleh_202300540
28_MaterialUpload_Processing_OCR_Saleh_202300540
37_Summary_Result_Mohammed_202401702
47_Flashcard_Review_Back_Rate_Mohammed_202401702
65_StudyPlan_Calendar_Week_Tasbeeh_202300549
93_GroupSpace_SharedQuiz_Live_Shahad_202305767
115_Admin_AIConfig_Settings_Shahad_202305767
```

Group headings later in this document use the `{M1}` handle for brevity — expand it using the table above before creating the frame in Figma. **Every one of the 141 frames must carry a real name and student ID**, because the brief states: *"all frames/screens must be clearly named by developer, such as Login_Ahmed_2022XXXXX."*


**Figma file structure** — one **Page** per owner, so the file stays navigable and the marker can see authorship instantly:

| Figma Page | Owner | Contents |
|---|---|---|
| `0 · Cover & Legend` | M1 | Cover with app name, logo, team table, legend, navigation index |
| `1 · Design System` | M1 | Colour, type, spacing, components, icons, states |
| `2 · Flow Overview` | M3 | Full navigation map + per-feature flow diagrams |
| `3 · M1 — Auth, Library & States` | M1 | Groups A, B, C, M |
| `4 · M2 — AI Content & Tutor` | M2 | Groups D, E, F, J |
| `5 · M3 — Plan, Progress & Payments` | M3 | Groups G, L |
| `6 · M2+M3 — AI Companion` | M2, M3 | Group H (advanced feature) |
| `7 · M4 — Collaboration & Admin` | M4 | Groups I, K |
| `8 · States & Prototype Wiring` | all | Error / empty / loading / success tokens, RTL proof, connection map |

---

## 2. Priority tiers and the realistic cut-line

141 frames across 15 features is the full inventory. At ~6 working weeks for 5 people, **89 P0 frames is the committed submission target** — about 18 per person, ~3 per week. The 51 P1 state screens are then swept as a team in the final week (they are mostly single-purpose state screens and component boards, so they are cheap).

| Tier | Frames | Meaning | Commitment |
|---|---|---|---|
| **P0 — MVP** | **89** | The happy path of every one of the 15 features, plus the states that prove the loop works. **If this is not done, features are unlinked and marks are lost.** | Non-negotiable |
| **P1 — Complete** | **51** | Error / empty / loading / success states, permission screens, kit boards, accessibility proof | Full-marks target |
| **P2 — Stretch** | **1** | Deep secondary variants (voice quiz mode) | Only if time allows |
| | **141** | **Total inventory** | |

**The realistic cut-line:** commit to **P0 (89 frames)** first — that is ~18 frames per person and it guarantees every feature is designed and linked, which is exactly what the prototype rubric tests. Then sweep **P1** as a team in the final week (they are mostly one-screen states and component boards, so they are cheap). P0+P1 = **140 of 141** frames.

> **Rule:** it is far better to submit 89 fully-linked, correctly-named frames than 141 half-linked ones. The prototype rubric rewards *"interactive links between screens"* and *"a clearly structured prototype"* — not raw frame count.


---

## 3. Screen inventory

**Notation:** in the *Frame* column, `{M1}` expands to `FirstName_StudentID` for member M1 (e.g. `Ahmed_202212345`) — see §1. `F` = feature ID from [doc 02](02-FEATURE-LIST-OWNERSHIP.md). Tier: **P0** MVP · **P1** complete · **P2** stretch.

The *Purpose & key labelled elements* column is written to be **copy-pasted directly into the Design Document**, because the rubric requires a written description plus labelled, explained UI elements for every screen. Writing them once here saves the team weeks.

### Group A — Onboarding & Auth · owner **M1 — Saleh** · F01

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| A01 | `01_Splash_Logo_{M1}` | F01 | P0 | Branded launch. Centred **logo**, **app name**, **tagline**, indeterminate **loading indicator**. Auto-advances after auth check. |
| A02 | `02_Onboarding_ValueProp_{M1}` | F01 | P0 | Slide 1 of 3. Headline "Upload anything.", **illustration**, **page dots**, **Skip** (text button), **Next** (primary). |
| A03 | `03_Onboarding_HowItWorks_{M1}` | F01 | P0 | Slide 2 of 3. 4-step **pipeline diagram** (upload → generate → plan → practise) with numbered labels. |
| A04 | `04_Onboarding_AIPrivacy_{M1}` | F01 | P0 | Slide 3 of 3. Explains where AI runs (on-device vs cloud), **privacy icon**, **Get Started** primary CTA. Trust-building screen. |
| A05 | `05_SignUp_Email_{M1}` | F01 | P0 | **Email field**, **password field** with inline validation + **strength meter**, **Create account** primary, **Continue with Apple**, **ToS/Privacy** links. |
| A06 | `06_SignUp_OTP_Verify_{M1}` | F01 | P0 | **6-box OTP input** with auto-advance, **resend timer** label, **Verify** primary. Error variant shows invalid-code message. |
| A07 | `07_Login_{M1}` | F01 | P0 | **Email/password fields**, **Forgot password?** link, **Face ID** biometric button, **Log in** primary, **inline error banner** for wrong credentials. |
| A08 | `08_ForgotPassword_Request_{M1}` | F01 | P0 | **Email input**, **Send reset link** primary, **success confirmation** state ("Check your inbox"). |
| A09 | `09_ForgotPassword_Reset_{M1}` | F01 | P1 | **New password** + **confirm password**, live **rule checklist** (8 chars, number, symbol), **Reset** primary. |
| A10 | `10_RoleSelect_{M1}` | F01 | P0 | **Three tappable role cards** (Student / Tutor / Admin), each with icon, title and "what you'll get" micro-copy. Sets Firestore `role`. |

### Group B — Profile & Settings · owner **M1 — Saleh** · F01, F14

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| B01 | `11_ProfileSetup_Academic_{M1}` | F01 | P0 | **University picker**, **major field**, **year segmented control**, **enrolled-courses chips** with add button, **Continue**. |
| B02 | `12_ProfileSetup_LearningStyle_{M1}` | F03 | P0 | **Four selectable cards** (Visual / Verbal / Read-Write / Kinesthetic). Each shows a *sample output preview* so the choice is meaningful, not abstract. **Continue**. |
| B03 | `13_ProfileSetup_StudyGoals_{M1}` | F06 | P0 | **Weekly-hours slider**, **target-grade selector**, **exam-date date pickers**, **Finish setup**. |
| B04 | `14_ProfileSetup_Complete_{M1}` | F01 | P1 | Success celebration, **choice summary list**, **Go to dashboard** primary. |
| B05 | `15_Home_Dashboard_Student_{M1}` | F07 | P0 | **Greeting header**, **streak flame + count**, **Today's plan** card, **due-cards badge**, **quick-action tiles** (Upload, Summarise, Quiz, Plan), **bottom tab bar**. |
| B06 | `16_Profile_View_{M1}` | F01 | P1 | **Avatar**, **name/ID**, **stat row** (mastery %, streak, hours), **badge strip**, **shortcut list**. |
| B07 | `17_Profile_Edit_{M1}` | F01 | P1 | Editable name / avatar / academic fields, **Save** and **Cancel** in nav bar, **unsaved-change warning**. |
| B08 | `18_Settings_Main_{M1}` | F14 | P1 | Grouped list rows: Account · Notifications · Accessibility · Language · AI & Data · Subscription · **Sign out** (destructive). |
| B09 | `19_Settings_Notifications_{M1}` | F14 | P1 | **Per-type toggles** (study reminders, quiz due, group activity), **quiet-hours time pickers**, **Save**. |
| B10 | `20_Settings_Accessibility_{M1}` | — | P1 | **Text-size stepper**, **dyslexia-friendly font toggle**, **reduce motion toggle**, **high-contrast toggle**, live preview card. |
| B11 | `21_Settings_Language_RTL_{M1}` | — | P1 | **EN / AR segmented switch** with **instant RTL preview** panel. Evidence for SDG 10. |
| B12 | `22_Settings_AIDataPrivacy_{M1}` | F15 | P1 | **On-device vs cloud toggle**, **data-retention explainer**, **Delete my AI data** destructive button, **confirmation dialog**. |
| B13 | `23_Settings_Subscription_{M1}` | F13 | P1 | **Current plan card**, **renewal date**, **Upgrade** / **Manage** / **Cancel** actions, billing-history link. |

### Group C — Courses & Material Library · owner **M1 — Saleh** · F02

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| C01 | `24_Courses_List_{M1}` | F02 | P0 | Enrolled **course cards** with colour tag, material count, next-deadline chip, **+ Add course** button. |
| C02 | `25_Course_Detail_{M1}` | F02 | P0 | Course header, **tab bar** (Materials / Decks / Quizzes / Plans / Members), material list, **Upload** FAB. |
| C03 | `26_MaterialUpload_SourcePicker_{M1}` | F02 | P0 | **Source grid**: Files · Photos · Camera scan · Paste link · Paste text. **Recent files** strip. **Cancel**. |
| C04 | `27_MaterialUpload_Compress_Progress_{M1}` | F02 | P1 | Client-side **downscale + compress** progress bar with size before/after label. Cost-saving step, made visible. |
| C05 | `28_MaterialUpload_Processing_OCR_{M1}` | F02 | P0 | On-device **OCR / text-extraction** progress with page count ("Extracting page 4 of 22"), **background-safe** notice. |
| C06 | `29_MaterialUpload_Success_{M1}` | F02 | P0 | **Success check**, extracted character count, **Generate now** primary (summary/cards/quiz), **View in library**. |
| C07 | `30_MaterialUpload_Error_UnsupportedFormat_{M1}` | F02 | P1 | **Error state**: unsupported format / file too large / no text found in scan. **Retry** + **Choose another file** + *why* explanation. |
| C08 | `31_Library_Materials_List_{M1}` | F02 | P0 | All materials with **cover thumbnails**, **type icon**, **tag chips**, **offline-available cloud icon**, **sort control**. |
| C09 | `32_Library_Search_Filter_{M1}` | F02 | P1 | **Search field** with recent queries, **filter sheet** (course, type, date, tags, has-AI-artefact), **active-filter chips**. |
| C10 | `33_Material_Detail_Viewer_{M1}` | F02 | P0 | **PDF/image viewer** with page scrubber, **highlight tool**, **bookmark**, **Generate** toolbar, **provenance jump target** for AI citations. |
| C11 | `34_Material_GenerateActionSheet_{M1}` | F02 | P0 | **Action sheet**: Summarise · Make flashcards · Make quiz · Add to study plan. Each shows estimated AI cost/time. |

### Group D — AI Summaries & Notes · owner **M2 — Mohammed** · F03

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| D01 | `35_Summary_Configure_{M2}` | F03 | P0 | **Length selector** (Short / Standard / Exam-ready), **style selector** (Bullets / Narrative / Cornell notes), **language toggle** (EN/AR), **focus-topics input**, **Generate** primary. |
| D02 | `36_Summary_Generating_{M2}` | F03 | P0 | Streaming **generation skeleton** with progress dots, **cancel** button, and an honest **engine badge** ("On-device · private") explaining which AI tier is running. |
| D03 | `37_Summary_Result_{M2}` | F03 | P0 | **TL;DR card**, **Key points list**, **Glossary terms** with definitions, **confidence band** per block, **provenance chips** (`p.12`), toolbar: Edit · Save · Share · Make cards. |
| D04 | `38_Summary_Provenance_Citation_{M2}` | F03/15 | P0 | Tapping a provenance chip opens a **bottom sheet** with the source snippet highlighted, page number and a **Open in material** button. This is the accuracy story made tangible. |
| D05 | `39_Summary_Edit_Rename_{M2}` | F03 | P1 | Editable rich-text body, **title field**, **Save** / **Discard**, **"AI-drafted" watermark** toggle retaining provenance. |
| D06 | `40_Summary_SaveToFolder_{M2}` | F03/08 | P1 | **Folder picker** with search, **Create new folder** inline, **permission indicator** if the folder is shared. |
| D07 | `41_Summary_Error_QuotaExceeded_{M2}` | F03/15 | P0 | **Graceful quota failure**: "Your free AI generations reset in 3 h 12 m." Options: switch to on-device engine · upgrade plan · try later. **Never a raw error.** |

### Group E — Flashcards & Spaced Repetition · owner **M2 — Mohammed** · F04

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| E01 | `42_Decks_List_{M2}` | F04 | P0 | Deck cards with **card count**, **due-today badge**, **mastery ring**, **last-reviewed label**; **+ New deck** button. |
| E02 | `43_Flashcards_Generate_Config_{M2}` | F04 | P0 | **Card-count stepper** (10/20/30/50), **difficulty segmented control**, **card-type selector** (Q&A · Cloze deletion · Image-occlusion · Reversible), **source-range picker** ("pages 1–40"), **Generate**. |
| E03 | `44_Flashcards_Generating_{M2}` | F04 | P0 | Streaming card-by-card progress ("12 of 30 cards"), **engine badge**, **cancel**. |
| E04 | `45_Deck_Detail_{M2}` | F04 | P0 | Deck header, **due / new / learning / mastered** counters, card list with per-card mastery dot, **Study now** primary, **Edit deck** menu. |
| E05 | `46_Flashcard_Review_Front_{M2}` | F04 | P0 | **Large question card**, **progress bar** (7/20), **reveal (tap anywhere) hint**, **bookmark card** icon, **close (with progress saved)** button. |
| E06 | `47_Flashcard_Review_Back_Rate_{M2}` | F04 | P0 | **Answer face** + explanation, **four rating buttons** (Again · Hard · Good · Easy) each showing the **next interval** (`<1m`, `2d`, `5d`, `11d`), **provenance chip**. |
| E07 | `48_Flashcard_Session_Summary_{M2}` | F04 | P0 | **Session stats** (cards reviewed, accuracy, time), **next due date**, **streak increment** animation, **Done** / **Keep going**. |
| E08 | `49_Flashcard_Manual_Create_Edit_{M2}` | F04 | P1 | **Front/back text editors**, **image attach**, **tags picker**, **deck selector**, **Save**. |
| E09 | `50_Flashcards_Offline_EmptyState_{M2}` | F04 | P1 | **Empty state**: "No cards due today." Also shows **offline mode banner** and *last synced* timestamp. |

### Group F — Quizzes · owner **M2 — Mohammed** · F05

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| F01 | `51_Quizzes_List_{M2}` | F05 | P0 | Quiz history cards with **score**, **date**, **source material**, **topics missed chips**, **Retake** button. |
| F02 | `52_Quiz_Generate_Config_{M2}` | F05 | P0 | **Question-type selector** (MCQ · True/False · Short answer · Mixed), **question-count stepper**, **difficulty**, **timer toggle + minutes**, **focus-topics input**, **Generate**. |
| F03 | `53_Quiz_Generating_{M2}` | F05 | P1 | Question-by-question generation progress with **cancel**, plus **"grounded in your material"** reassurance line. |
| F04 | `54_Quiz_Take_MCQ_{M2}` | F05 | P0 | **Question counter** (3 of 10), **timer ring**, **question stem**, **four answer options**, **Skip** and **Next**, **progress bar**, **flag-question icon**. |
| F05 | `55_Quiz_Feedback_Correct_{M2}` | F05 | P0 | **Correct state**: green option fill, checkmark, **"Why" explanation panel**, **provenance chip**, **Next question** primary. |
| F06 | `56_Quiz_Feedback_Incorrect_{M2}` | F05 | P0 | **Incorrect state**: red fill on chosen option, green on the correct one, **explanation**, **provenance chip**, **Add this to my revision plan** secondary action. |
| F07 | `57_Quiz_Submit_Confirm_{M2}` | F05 | P0 | **Confirmation dialog**: unanswered-question warning, **Submit** / **Review unanswered**; timed variant warns about time remaining. |
| F08 | `58_Quiz_Results_Scorecard_{M2}` | F05 | P0 | **Big score ring** (8/10 · 80%), **time taken**, **topic performance bars**, **weak-topic callout**, **Review answers** / **Retake weak topics** primaries. |
| F09 | `59_Quiz_Review_Answers_Explanations_{M2}` | F05 | P0 | Scrollable per-question review: your answer, correct answer, explanation, **provenance chip**, **topic tag**. Feeds `topicMastery`. |

### Group G — Study Plan & Progress · owner **M3 — Tasbeeh** · F06, F07

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| G01 | `60_StudyPlan_Wizard_Subjects_{M3}` | F06 | P0 | **Subject multi-select chips** with per-subject priority slider, **Continue**, **step indicator** (1 of 4). |
| G02 | `61_StudyPlan_Wizard_Availability_{M3}` | F06 | P0 | **Weekly availability grid** (days × time blocks, tap-to-toggle), **blocked-days picker**, **Continue**. |
| G03 | `62_StudyPlan_Wizard_Deadlines_{M3}` | F06 | P0 | **Exam/assignment date list** with add button, per-item **weighting field**, **Continue**. |
| G04 | `63_StudyPlan_Wizard_Intensity_{M3}` | F06 | P0 | **Intensity segmented control** (Light / Balanced / Intensive), **session-length stepper**, **reminder-time picker**, **Generate my plan**. |
| G05 | `64_StudyPlan_Generating_{M3}` | F06 | P1 | Plan-generation progress with an explanation of *what* the scheduler is optimising (spacing, deadline weighting, review load). |
| G06 | `65_StudyPlan_Calendar_Week_{M3}` | F06 | P0 | **Week grid** of colour-coded session blocks per subject, **today highlight**, **drag handle** on blocks, **+ Add session**. |
| G07 | `66_StudyPlan_Calendar_Month_{M3}` | F06 | P1 | **Month view** with session-density dots, **deadline markers**, **tap day → day detail**. |
| G08 | `67_StudyPlan_Session_Detail_{M3}` | F06 | P0 | **Session detail sheet**: subject, topic, duration, linked material, **Start now** primary, **Reschedule** / **Skip** / **Mark done**. |
| G09 | `68_StudyPlan_MissedSession_Reschedule_{M3}` | F06 | P0 | **AI re-plan prompt**: "You missed 2 sessions — rebalance the week?" Shows the **before/after diff**, **Accept new plan** primary. This is the adaptive-planner innovation made visible. |
| G10 | `69_Progress_Dashboard_{M3}` | F07 | P0 | **Stat ring row** (mastery %, streak, hours this week), **weekly activity bar chart**, **subjects-in-progress list**, **goal progress bar**. |
| G11 | `70_Progress_WeaknessRadar_{M3}` | F07 | P0 | **Radar chart** of topic mastery, **weakest-topics cards** with **Make quiz** / **Add to plan** actions. Directly closes the measure → adapt loop. |
| G12 | `71_Progress_Achievements_{M3}` | F07 | P1 | **Badge grid** (earned in colour, locked dimmed with unlock hint), **streak calendar heatmap**, **next milestone card**. |
| G13 | `72_Progress_ExportReport_{M3}` | F07 | P1 | **Export sheet**: date range picker, include-toggles, **Share as PDF** primary, **success toast**. |

### Group H — ADVANCED FEATURE · AI Study Companion (RAG + Adaptive Coach) · owners **M2 — Mohammed + M3 — Tasbeeh** · F15

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| H01 | `73_Coach_Home_{M2}` | F15 | P0 | **Prompt-suggestion cards** ("Explain Chapter 4 simply", "Quiz me on lecture 3"), **library-scope chip** showing which materials are searchable, **ask bar**. |
| H02 | `74_Coach_Chat_Conversation_{M2}` | F15 | P0 | **Message bubbles**, **citation chips** under AI answers, **streaming cursor**, **thumbs up/down**, **copy** and **save as note** actions. |
| H03 | `75_Coach_ExplainLevel_Toggle_{M2}` | F15 | P0 | **Segmented control**: Explain like I'm 12 · Standard · Exam-level · In Arabic. Re-renders the same answer at a different depth. |
| H04 | `76_Coach_Citation_SourceSheet_{M2}` | F15 | P0 | **Source sheet**: material title, page number, **highlighted snippet**, **relevance score**, **Open in viewer** button. The anti-hallucination guarantee, visible. |
| H05 | `77_Coach_StudyPath_Recommended_{M3}` | F15 | P0 | **Step-by-step study path** (ordered cards: read → cards → quiz → review) generated from weakness data, each with estimated time and **Add all to plan** primary. |
| H06 | `78_Coach_QuizMe_Voice_{M3}` | F15 | P2 | **Voice-mode quiz**: mic button with waveform, **live transcript**, **spoken feedback**. Accessibility + learning-style evidence. |
| H07 | `79_Coach_RateResponse_{M2}` | F15 | P1 | **Feedback sheet**: helpfulness stars, **what went wrong** chips (wrong / too long / off-topic), optional comment, **Submit**. Feeds prompt-improvement loop. |
| H08 | `80_Coach_OnDeviceUnavailable_Fallback_{M2}` | F15 | P0 | **Graceful-degradation screen**: explains that on-device Apple Intelligence is unavailable on this device/simulator, offers **Use cloud engine** (with privacy note) or **Continue offline**. Prevents a dead end. |

### Group I — Collaboration: Folders, Group Spaces, Bookmarks · owner **M4 — Shahad** · F08, F09, F10

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| I01 | `81_Folder_Shared_List_{M4}` | F08 | P0 | **Shared-folder cards** with member avatar stack, item count, **role pill** (Owner/Editor/Viewer), last-activity label; **+ New folder**. |
| I02 | `82_Folder_Detail_{M4}` | F08 | P0 | Folder header with **member avatars**, **tab bar** (Items / Activity / Members), item grid, **Add item** FAB, **share** toolbar icon. |
| I03 | `83_Folder_Create_Edit_{M4}` | F08 | P0 | **Folder-name field**, **colour/icon picker**, **linked-course selector**, **initial visibility segmented control**, **Create**. |
| I04 | `84_Folder_Invite_Members_{M4}` | F08 | P0 | **Search field** for classmates, **contact list** with multi-select checkboxes, **per-invitee permission picker**, **Send invites**. |
| I05 | `85_Folder_InviteCode_Share_{M4}` | F08 | P1 | **6-character invite code** (large, tappable to copy), **share link**, **QR code**, **expiry picker**, system **share sheet** trigger. |
| I06 | `86_Folder_MemberPermissions_{M4}` | F08 | P0 | **Member rows** with avatar, name, and **permission segmented control** (View / Comment / Edit / Remove). Owner row is locked with explanation. |
| I07 | `87_Folder_EmptyState_{M4}` | F08 | P1 | **Empty state**: "No folders yet." Illustration + **Create your first folder** + **Join with a code**. |
| I08 | `88_GroupSpace_List_{M4}` | F09 | P0 | **Group cards** with cover gradient, member count, **next session countdown**, **live-now badge**, unread-chat dot. |
| I09 | `89_GroupSpace_JoinByCode_{M4}` | F09 | P0 | **Code entry** (6 boxes), **Join** primary, **error state** for invalid/expired code with retry guidance. |
| I10 | `90_GroupSpace_Detail_Board_{M4}` | F09 | P0 | **Shared board**: pinned resources, upcoming session card, member list, **Chat** and **Start group quiz** primaries, live-presence dots. |
| I11 | `91_GroupSpace_Chat_{M4}` | F09 | P1 | **Message list** with sender avatars, **shared-resource attachment cards**, **reaction row**, **input bar** with attach + send. |
| I12 | `92_GroupSpace_SharedQuiz_Lobby_{M4}` | F09 | P1 | **Lobby**: participant avatars filling in, **ready checkmarks**, **topic + question-count settings** (host only), **Start quiz** (host), **waiting** spinner (members). |
| I13 | `93_GroupSpace_SharedQuiz_Live_{M4}` | F09 | P1 | **Live quiz**: question stem, answer options, **per-player progress strip**, **live leaderboard rail**, **timer ring**, answering state vs answered state. |
| I14 | `94_GroupSpace_Quiz_Results_Leaderboard_{M4}` | F09 | P1 | **Final leaderboard** with rank medals, per-player score, **topic accuracy bars**, **Challenge rematch** / **Review answers** primaries. |
| I15 | `95_Bookmarks_Collections_{M4}` | F10 | P0 | **Collection cards** with cover mosaic, item count, **offline-available badge**; **+ New collection**. |
| I16 | `96_Bookmark_Collection_Detail_{M4}` | F10 | P0 | Bookmarked items with **source-type icon**, **saved date**, **swipe actions** (remove / move / open), **select-and-share**. |
| I17 | `97_Bookmark_Save_Sheet_{M4}` | F10 | P0 | **Save sheet** from any screen: **collection picker** with checkmarks, **Create new** inline, **also save offline** toggle, **Save** primary. |
| I18 | `98_Bookmarks_EmptyState_{M4}` | F10 | P1 | **Empty state** explaining what bookmarks do + **Browse library** CTA. Also demonstrates the **offline-first** story. |

### Group J — Tutor / Teacher Content Studio · owner **M2 — Mohammed** · F11

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| J01 | `99_Home_Dashboard_Tutor__{M2}` | F11 | P0 | **Cohort KPI row** (students, active this week, avg mastery, at-risk count), **courses list**, **pending AI-review badge**, **Create course** primary. |
| J02 | `100_Tutor_Course_List__{M2}` | F11 | P1 | Course cards with **code**, **enrolment count**, **term dates**, **published-material count**, **archive** swipe action. |
| J03 | `101_Tutor_Course_Create_Edit__{M2}` | F11 | P0 | **Course name/code fields**, **term date pickers**, **cover colour picker**, **enrolment mode** (open / code / approval), **Save**. |
| J04 | `102_Tutor_Course_Roster__{M2}` | F11 | P0 | **Student table** (name, ID, mastery %, last active), **search + filter**, **invite students**, **export CSV**; row taps to progress detail. |
| J05 | `103_Tutor_Material_Publish__{M2}` | F11 | P0 | **Upload staged as a draft with visibility controls**, **publish date/time picker**, **target cohort selector**, **notify students toggle**, **Publish** primary. |
| J06 | `104_Tutor_AI_Content_ReviewQueue__{M2}` | F11 | P0 | **Review queue list** of AI-generated items awaiting approval, **pending/source/material** columns, **bulk approve** and **filter by confidence**. |
| J07 | `105_Tutor_AI_Content_EditApprove__{M2}` | F11 | P0 | Split view: **AI-drafted item on the left editable**, **source snippet on the right**, **confidence badge**, **Approve** / **Edit & approve** / **Reject with reason**. This is the human-in-the-loop ethics control. |
| J08 | `106_Tutor_StudentProgress_Detail__{M2}` | F11 | P1 | Per-student **mastery radar**, **session history**, **risk flags**, **Send encouragement** action (privacy-respecting: aggregate-first). |
| J09 | `107_Tutor_Announcement_Compose__{M2}` | F11 | P1 | **Message editor** with templates, **audience selector** (course / group / individual), **schedule send**, **Send now**. |
| J10 | `108_Tutor_Gradebook_Export__{M2}` | F11 | P1 | **Gradebook table** (quiz scores, card mastery, plan adherence), **column config**, **date range**, **Export CSV / PDF** primaries. |

### Group K — Admin Content Management · owner **M4 — Shahad** · F12

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| K01 | `109_Home_Dashboard_Admin__{M4}` | F12 | P0 | **Platform KPI cards** (users, DAU, AI calls today vs free-tier cap, storage used vs quota), **alert banners** (quota approaching, reports open), **quick-nav grid**. |
| K02 | `110_Admin_Users_List__{M4}` | F12 | P0 | **User table** with search, **role filter chips**, **status badge** (active/suspended), **last login**, **row overflow menu**. |
| K03 | `111_Admin_User_Detail__{M4}` | F12 | P1 | User profile, **role changer** with confirmation dialog, **suspend / reactivate**, **activity log**, **support actions**. |
| K04 | `112_Admin_Moderation_Queue__{M4}` | F12 | P0 | **Queue of reported items** with **preview**, **reason chips**, **reporter**, **age**; **Approve / Remove / Escalate** actions. |
| K05 | `113_Admin_FlaggedReports__{M4}` | F12 | P1 | **Report detail**: reported content, report history, **prior-action list**, **decision panel with mandatory reason**, **audit note**. |
| K06 | `114_Admin_Taxonomy_Manage__{M4}` | F12 | P1 | **Subject / tag CRUD** list with drag-reorder, **merge duplicates** tool, **usage count** per tag. |
| K07 | `115_Admin_AIConfig_Settings__{M4}` | F12 | P0 | **Engine routing policy** (on-device-first / cloud-first / offline-only), **prompt-template editor per artefact type**, **per-user daily quota stepper**, **cost-estimate readout**. This screen *is* the cost-governor innovation made operational. |
| K08 | `116_Admin_AuditLog__{M4}` | F12 | P1 | **Filterable audit trail** (actor, action, target, timestamp), **export**, **redacted-fields indicator** for privacy compliance. |
| K09 | `117_Admin_Broadcast_Notification__{M4}` | F12 | P1 | **Broadcast composer**: audience segment builder, title/body fields, **preview as push notification**, **schedule**, **Send with confirmation**. |

### Group L — Subscription & Payments (Tap Payments) · owner **M3 — Tasbeeh** · F13

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| L01 | `118_Paywall_Plans__{M3}` | F13 | P0 | **Three plan cards** (Free / Plus / Pro) with **BHD pricing**, **monthly-annual toggle with save %**, **recommended ribbon**, **Continue** primary, **restore purchases** link. |
| L02 | `119_Paywall_FeatureCompare__{M3}` | F13 | P1 | **Comparison table** of AI generations, materials, group spaces, offline export per tier, **sticky plan headers**, **Choose plan** buttons. |
| L03 | `120_Checkout_OrderSummary_BHD__{M3}` | F13 | P0 | **Order summary**: plan, term, **subtotal / VAT 10% / total in BHD**, **promo-code field**, **terms checkbox**, **Proceed to payment**. |
| L04 | `121_Payment_Method_Select__{M3}` | F13 | P0 | **Payment method cards**: Card · BenefitPay · Apple Pay · KNET, with **supported-network icons** (Visa/Mastercard), **secure-payment trust row**. |
| L05 | `122_Payment_Card_Entry__{M3}` | F13 | P0 | **Tap Card SDK** secure fields (number/expiry/CVV) — **no card data ever touches our servers**; **save card** toggle, **Pay BHD 4.900** primary, **PCI-DSS note**. |
| L06 | `123_Payment_BenefitPay_Redirect__{M3}` | F13 | P1 | **Web-redirect handoff** state with a clear explanation ("You'll return to StudyForge automatically"), **cancel** action, **progress indicator**. |
| L07 | `124_Payment_Processing__{M3}` | F13 | P0 | **Processing overlay** with **never-double-charge** copy and a **Do not close** instruction. |
| L08 | `125_Payment_Success_Receipt__{M3}` | F13 | P0 | **Success check**, **receipt card** (amount, method, last 4 digits, Tap reference), **unlocked-features list**, **Done**. |
| L09 | `126_Payment_Failed_Retry__{M3}` | F13 | P0 | **Failure state** with **decline reason** (insufficient funds / 3-D Secure timeout / network), **Retry** and **Try another method** primaries. |
| L10 | `127_Subscription_Manage_Cancel__{M3}` | F13 | P1 | **Current plan panel**, renewal date, **payment-method list** with default toggle, **Cancel subscription** destructive + **retention dialog**. |

### Group M — System, Notifications & Cross-cutting States · owner **M1 — Saleh** · F14

| ID | Frame | F | Tier | Purpose & key labelled elements |
|---|---|---|---|---|
| M01 | `128_Notifications_Inbox_{M1}` | F14 | P0 | **Notification list** grouped by day, **type icons**, **unread dots**, **swipe to mark read**, **grouped section headers**. |
| M02 | `129_Notification_Permission_Request_{M1}` | F14 | P0 | **Primer screen *before* the system prompt** explaining value ("so your plan keeps you on track"), **Enable** / **Not now**. Improves opt-in rate. |
| M03 | `130_Push_StudyReminder_{M1}` | F14 | P1 | **Push notification preview**: "Chemistry — 25 min. Your flashcards are ready." with **deep-link** open target. |
| M04 | `131_Push_QuizDue_{M1}` | F14 | P1 | **Push preview**: weekly quiz ready with one-tap **Start** action button. |
| M05 | `132_Global_Search_{M1}` | — | P0 | **Unified search** across materials, summaries, decks, quizzes, folders, bookmarks; **scope chips**, **recent searches**, **result-type tabs**. |
| M06 | `133_Error_NoInternet_OfflineBanner_{M1}` | F14 | P0 | **Offline banner** + queue indicator ("3 changes will sync"), cached-content badge. Explicitly required by the rubric's *error & feedback states*. |
| M07 | `134_Error_Server_Retry_{M1}` | — | P0 | **Server error state** with plain-language explanation, **Retry** primary, **reference id** for support. |
| M08 | `135_EmptyState_Kit_{M1}` | — | P1 | **Component board**: no-materials, no-folders, no-cards-due, no-results, no-notifications — illustration + explanation + single CTA each. |
| M09 | `136_Toast_Success_Kit_{M1}` | — | P1 | **Component board**: saved, copied, invited, synced, generated — with undo variants where destructive. |
| M10 | `137_Loading_Skeleton_Kit_{M1}` | — | P1 | **Shimmer skeleton components** for list, card, chart and reader layouts. |
| M11 | `138_Accessibility_LargeText_Example_{M1}` | — | P1 | Same screen at **AX3 text size**, proving Dynamic Type layout integrity. Direct SDG 10 evidence. |
| M12 | `139_RTL_Arabic_Example_{M1}` | — | P1 | Same screen mirrored in **Arabic RTL**, proving true bidirectional layout rather than a translated overlay. |
| M13 | `140_Home_Dashboard_Group_{M1}` | F09 | P1 | **Group-member home variant**: upcoming group sessions, group activity feed, shared-folder shortcuts, group leaderboard position. |
| M14 | `141_Logout_Confirm_{M1}` | F01 | P1 | **Confirmation dialog** with "keep offline copies?" option, preventing accidental data-loss surprises. |

---

## 4. Frame count by owner (prototype workload proof)

| Group | Theme | Owner | Feature(s) | Frames | P0 | P1 | P2 |
|---|---|---|---|---|---|---|---|
| A | Onboarding & Auth | M1 | F01 | 10 | 9 | 1 | 0 |
| B | Profile & Settings | M1 | F01, F14 | 13 | 4 | 9 | 0 |
| C | Courses & Material Library | M1 | F02 | 11 | 8 | 3 | 0 |
| D | AI Summaries & Notes | M2 | F03 | 7 | 5 | 2 | 0 |
| E | Flashcards & Spaced Repetition | M2 | F04 | 9 | 7 | 2 | 0 |
| F | Quizzes | M2 | F05 | 9 | 8 | 1 | 0 |
| G | Study Plan & Progress | M3 | F06, F07 | 13 | 9 | 4 | 0 |
| H | **AI Study Companion (ADVANCED)** | M2 + M3 | F15 | 8 | 6 | 1 | 1 |
| I | Collaboration | M4 | F08, F09, F10 | 18 | 11 | 7 | 0 |
| J | Tutor Content Studio | M2 | F11 | 10 | 6 | 4 | 0 |
| K | Admin Content Management | M4 | F12 | 9 | 4 | 5 | 0 |
| L | Subscription & Payments | M3 | F13 | 10 | 7 | 3 | 0 |
| M | System, Notifications & States | M1 | F14 | 14 | 5 | 9 | 0 |
| | | | **Total** | **141** | **89** | **51** | **1** |

Per-owner totals (**141** frames across **4** members): **M1 — Saleh = 48** · **M2 — Mohammed = 41** · **M3 — Tasbeeh = 25** · **M4 — Shahad = 27**.

Breakdown: M2's 41 = D(7) + E(9) + F(9) + J(10) + 6 of the 8 advanced-feature frames; M3's 25 = G(13) + L(10) + 2 of the 8 advanced-feature frames (the advanced feature is shared, so its frames split 6/2 to M2/M3).

M5's former groups were distributed as: **J → M2** (fits the AI content-review workstream), **K → M4** (fits the permissions/moderation UI work), **L → M3** (fits the Cloud Functions and architecture work).
Frame count is *not* the fairness metric — see the weighting rationale in [doc 02 §3](02-FEATURE-LIST-OWNERSHIP.md). M2's and M4's frames are the most interaction-heavy (realtime, permissions, admin tables). M1's higher count includes Groups B and M, which are low-complexity settings and shared-state/kit frames.

---

## 5. Navigation architecture (the "clear screen flow" requirement)

**Root:** `RootView` switches on auth state → `OnboardingFlow` or `RoleRouter(role:)`.

**Student tab bar (5 tabs)** — the persistent spine of the prototype:

| Tab | Icon | Root screen | Contains |
|---|---|---|---|
| **Home** | house | `15_Home_Dashboard_Student` | today's plan, streak, quick actions, notifications entry |
| **Library** | books | `31_Library_Materials_List` | courses, materials, search, upload FAB, folders, bookmarks |
| **Coach** | sparkles | `73_Coach_Home` | advanced AI companion (F15), study path |
| **Practise** | brain | `42_Decks_List` | decks, quizzes, due cards, review sessions |
| **Plan** | calendar | `65_StudyPlan_Calendar_Week` | calendar, sessions, progress, achievements |

**Tutor tab bar (4 tabs):** Dashboard · Courses · Review Queue · Profile
**Admin tab bar (4 tabs):** Overview · Users · Moderation · Settings
**Group variant:** adds a **Groups** entry in the Library tab plus `140_Home_Dashboard_Group`.

**Modal flows** (presented, not pushed — important for correct prototype wiring):
`MaterialUploadFlow` · `Material_GenerateActionSheet` · `Flashcard_Review_Session` · `Quiz_Take` flow · `StudyPlan_Wizard` · `Checkout` flow · `Bookmark_Save_Sheet` · `Folder_Invite_Members`.

---

## 6. Prototype wiring checklist (rubric: *"interactive links between screens"*)

Before submission, every one of these must be a real Figma connection — not a static frame:

- ⬜ Every primary button (`Next`, `Continue`, `Generate`, `Save`, `Join`, `Pay`, `Submit`) has a destination
- ⬜ Every back / close / cancel affordance returns to the correct origin screen
- ⬜ Every tab-bar icon switches tabs and preserves tab state
- ⬜ Every list row opens its detail screen
- ⬜ Every modal sheet has both a success path and a dismissal path
- ⬜ At least one **loading → success** transition per AI feature
- ⬜ At least one **error → retry → recovery** loop (use `41_Summary_Error_QuotaExceeded` and `134_Error_Server_Retry`)
- ⬜ The full **onboarding → home** chain works end to end
- ⬜ The full **upload → summary → save to folder → shared folder** chain works end to end
- ⬜ The full **generate quiz → attempt → results → weakness radar → re-plan** chain works end to end
- ⬜ The full **paywall → checkout → success → unlocked** chain works end to end
- ⬜ **Overflow behaviour** set to *Scroll* on every long screen and *Device* on every screen
- ⬜ **Smart Animate** applied to at least 5 high-impact transitions (flashcard flip, tab switch, sheet present)
- ⬜ Prototype **starting frame** set to `01_Splash_Logo_{M1}`
- ⬜ Every frame name matches the `NN_ScreenName_FirstName_StudentID` rule exactly








