# Appendix A, Low-fidelity mockup screen descriptions

> Design Document section 10. Companion to the wireframes on **Figma page `5 · Low-Fi Wireframes`**.

**Statement of low-fidelity vs high-fidelity, as the brief requires it:**

> *Low-fidelity wireframes (structure, hierarchy and labels only, greyscale, no imagery) are presented here in accordance with the brief's Mockups requirement. The high-fidelity, fully interactive version is delivered separately as the Figma Project Prototype.*

---

## A.1 How the mockups are organised

| | |
|---|---|
| **Frames** | **106** wireframes, one per screen, covering all **15** features (F01–F15) |
| **Page** | Figma page `5 · Low-Fi Wireframes`, 4 wireframes per row, ordered by screen number |
| **Naming** | `NN_ScreenName_FirstName_StudentID`, exactly as the brief requires. Every frame carries a real student ID, so authorship is visible at a glance |
| **Each wireframe** | A greyscale drawing of the screen, with **numbered callout badges** on the key UI elements |
| **Beside each wireframe** | A **legend panel** listing every numbered element, its **type** (button, input field, section heading, content card, tab bar item, label) and **what it does** |
| **Flow** | Page `2 · Flow Overview` holds the global navigation map plus **15 per-feature flow diagrams**, each ending in the error/edge case the flow must survive |
| **Style** | Structure and hierarchy only: no colour, no imagery, no shadow. A **filled block** is a primary action, a **light block** is a container/card/input, a **numbered badge** is a described element |

**Why the wireframes are drawn in Figma rather than on paper:** the low-fidelity set is generated from the same frame geometry as the high-fidelity prototype, so the two can never drift apart. A change to a screen changes both, by construction.

The exhaustive element-by-element legend for every one of the 106 screens is printed beside its wireframe on Figma page 5. This appendix is the **written** half: the purpose and layout of each screen, with its key elements named.

---

## A.2 Group A, Onboarding & Auth · owner M1, Saleh · feature F01

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 01 | `01_Splash_Logo_Saleh_202300540` | Branded launch; checks auth state silently so a returning user never sees onboarding again. | Centred **logo mark**, **wordmark**, **tagline**, indeterminate **loading indicator**. Auto-advances; not user-driven. |
| 02 | `02_Onboarding_ValueProp_Saleh_202300540` | Onboarding slide 1 of 3: state the value in one line. | **Illustration** block, **headline**, **page dots**, **Skip** text button, **Next** primary. |
| 03 | `03_Onboarding_HowItWorks_Saleh_202300540` | Slide 2 of 3: explain the pipeline before asking for anything. | Four numbered **step cards** (upload → generate → plan → practise) with **numbered labels**, **page dots**, **Next**. |
| 04 | `04_Onboarding_AIPrivacy_Saleh_202300540` | Slide 3 of 3: where AI runs, and why it is private. Trust is the conversion step. | **Privacy icon**, **on-device vs cloud explainer**, **Get started** primary CTA. |
| 05 | `05_SignUp_Email_Saleh_202300540` | Create the account. | **Email field**, **password field** with **strength meter**, **Create account** primary, **Continue with Apple** (documented as deliberately not built), **ToS/Privacy** links. |
| 06 | `06_SignUp_OTP_Verify_Saleh_202300540` | Prove the address is real. | **Envelope icon**, **6-digit code entry**, **"I've verified — continue"** primary, **Resend link** with a live countdown. |
| 07 | `07_Login_Saleh_202300540` | Returning-user sign-in, including the failure path. | **Email field**, **password field**, **Log in** primary, inline **error example** ("Incorrect email or password"), **Forgot password** link, **Face ID** affordance. |
| 08 | `08_ForgotPassword_Request_Saleh_202300540` | Start a password reset. | **Email field**, **Send reset link** primary. |
| 09 | `09_ForgotPassword_Confirm_Saleh_202300540` | Confirm the link was sent, and set the expectation. | **Check mark**, **"Check your inbox"**, **60-minute expiry** note, **Back to log in**. |
| 10 | `10_RoleSelect_Saleh_202300540` | Choose the role that routes the whole app. Four roles are supported. | Three **role cards** (Student, Tutor, Admin) each with a one-line description and an icon, **Continue as student** primary. |

---

## A.3 Group B, Profile & Settings · owner M1, Saleh · features F01, F07, F14

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 11 | `11_ProfileSetup_Academic_Saleh_202300540` | Wizard step 1 of 4: who the student is, academically. | **Step indicator**, **institution picker**, **college picker**, **course chips** (CS201, CS202, MATH201, BIS301), **Continue**. |
| 12 | `12_ProfileSetup_LearningStyle_Saleh_202300540` | Wizard step 2 of 4: capture the learning style that later tunes AI output depth. | Four **style cards** (Visual, Verbal, Read-Write, Kinesthetic), each with a technique hint such as "Diagrams + mind-mapped cards", **Continue**. |
| 13 | `13_ProfileSetup_StudyGoals_Saleh_202300540` | Wizard step 3 of 4: weekly commitment and target grade. | **Goal chips**, **target-grade selector** (A–D), **Add exam date**, **Finish setup** primary. |
| 14 | `14_ProfileSetup_Complete_Saleh_202300540` | Wizard step 4 of 4: confirm what was captured, then hand off. | **Check mark**, summary rows for **Study style**, **Weekly goal**, **Target grade**, **Go to dashboard** primary. |
| 15 | `15_Home_Dashboard_Student_Saleh_202300540` | The student's landing screen: today's plan plus the fastest route into the four core actions. | **Greeting**, **streak pill** (🔥 12), **Today's plan** session cards, **18 cards due** / **2 quizzes** tiles, four **quick action buttons** (Upload, Summarise, Quiz, Plan), 5-item **tab bar** (Home, Library, Study, Progress, Profile). |
| 16 | `16_Profile_View_Saleh_202300540` | The student's own profile and settings entry point. | **Avatar**, three **stat tiles** (Mastery 64%, Streak 12, 6.5 h this week), settings rows **Profile details · Notifications · Accessibility · Language · Subscription**, **tab bar**. |
| 17 | `17_Profile_Edit_Saleh_202300540` | Edit the profile, with dirty-state protection so edits are not lost silently. | **Avatar**, **name field**, **institution field**, **programme field**, **unsaved-changes banner**, **Cancel** and **Save**. |
| 18 | `18_Settings_Main_Saleh_202300540` | The settings hub: every cross-cutting preference in one place. | Rows for **Account**, **Notifications**, **Accessibility**, **Language**, **AI & Data**, **Subscription**, and a destructive **Sign out**. |

---

## A.4 Group C, Courses & Library · owner M1, Saleh · feature F02

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 24 | `24_Courses_List_Saleh_202300540` | The student's enrolled courses, each showing how much material it holds and what is due. | **+ Add** button, **course cards** with material and deck counts and a **due label**, a **next-quiz card**, **tab bar**. |
| 25 | `25_Course_Detail_Saleh_202300540` | Everything inside one course, so material, decks, quizzes and plans are one tap apart. | **Back**, **course title**, **course code + tutor**, **tab chips** (Materials, Decks, Quizzes, Plans, Members), **material rows** with type and size, **+ FAB**. |
| 26 | `26_MaterialUpload_SourcePicker_Saleh_202300540` | Choose where the material comes from, before anything is processed. | Title, **explainer line**, **Paste text** card, **PDF from Files** card, **Continue**, **Cancel**. |
| 27 | `27_MaterialUpload_Compress_Progress_Saleh_202300540` | Show the value of downscaling: a measurable before/after saving. | **Before** 8.4 MB and **After** 1.2 MB comparison with an **indeterminate progress** indicator. |
| 28 | `28_MaterialUpload_Processing_OCR_Saleh_202300540` | OCR and text extraction with page markers, which is slow and must not feel broken. | **Progress** indicator plus **"Safe to background"** reassurance ("StudyForge keeps working and notifies you when done"). |
| 29 | `29_MaterialUpload_Success_Saleh_202300540` | Confirm the material landed and offer the next action immediately. | **Check mark**, **Generate now** primary, **View in library** secondary, **"What can I generate?"** explainer, and the provenance line "every item cites its source page". |
| 30 | `30_MaterialUpload_Error_UnsupportedFormat_Saleh_202300540` | The upload is rejected, with a way forward rather than a dead end. | **Error mark**, **reason**, **Choose another file** and **Retry**. |
| 31 | `31_Library_Materials_List_Saleh_202300540` | The library: every material, searchable and filterable. | **Search materials field**, **sort chip** (Newest), **material rows** with type chip and topic, **tab bar** with Library active. |
| 33 | `33_Material_Detail_Viewer_Saleh_202300540` | Read the material in place before generating from it. | **Document viewer** with page markers, **generate affordance**. |
| 34 | `34_Material_GenerateActionSheet_Saleh_202300540` | Pick what to generate from this material. | **Action sheet** offering **Summary**, **Flashcards** and **Quiz**, so generation always starts from a named source. |

---

## A.5 Group D, AI Summaries · owner M2, Mohammed · feature F03

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 35 | `35_Summary_Configure_Mohammed_202401702` | Choose the shape of the summary before spending a generation. | **Length segmented control** (Short, Standard, Exam-ready), **style control** (Bullets, Narrative, Cornell), **language control** (English, العربية), **focus-topics field**, **Generate summary** primary. |
| 36 | `36_Summary_Generating_Mohammed_202401702` | Generation in progress, with the privacy claim visible while the user waits. | **"On-device · private"** chip and **Cancel**. |
| 37 | `37_Summary_Result_Mohammed_202401702` | The generated summary, with provenance attached to every claim. | **TL;DR** panel, **key-point rows** (root/parent/child, binary tree, traversal, height vs depth), **term definition card**, **confidence readout**, **citation chip** (p.12 cite), and the actions **Edit**, **Save**, **Share**, **Cards**. |
| 38 | `38_Summary_Provenance_Citation_Mohammed_202401702` | Prove a claim against the source page. This is the anti-hallucination guarantee made visible. | **Citation chip**, **source header** (material title and page), **highlighted snippet**, **relevance score**, **Open in viewer**. |
| 41 | `41_Summary_Error_QuotaExceeded_Mohammed_202401702` | A real limit, met honestly, with three ways out. | **Error mark**, **quota explanation**, **Switch to on-device engine** (unlimited, private), **Upgrade plan** with BHD price, **Try again later**. |

---

## A.6 Group E, Flashcards & Spaced Repetition · owner M2, Mohammed · feature F04

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 42 | `42_Decks_List_Mohammed_202401702` | The deck library, sorted by what is actually due today. | **+ New deck**, **deck cards** with card count, mastery %, **due count** and last-reviewed label, **tab bar** with Study active. |
| 43 | `43_Flashcards_Generate_Config_Mohammed_202401702` | Configure card generation so the output matches the revision need. | **Card-count chips** (10/20/30/50), **difficulty control**, **card-type control** (Q&A, Cloze, Image, Reverse), **page-range chip**, **Generate 20 cards** primary. |
| 44 | `44_Flashcards_Generating_Mohammed_202401702` | Generation in progress, showing real cards as they arrive. | **"On-device · private"** chip, **live card preview** (Q/A pair), **Cancel**. |
| 45 | `45_Deck_Detail_Mohammed_202401702` | The state of one deck, by spaced-repetition bucket. | **Due / New / Learning / Mastered** counters, **Study now** primary, **card list** rows. |
| 46 | `46_Flashcard_Review_Front_Mohammed_202401702` | The question side of a card. Deliberately one thing on screen. | **Question stem** only; the whole screen is the flip target (**Smart Animate** on tap). |
| 47 | `47_Flashcard_Review_Back_Rate_Mohammed_202401702` | The answer side plus the grading that drives the SM-2 schedule. | **Answer**, **explanation**, **citation chip** (p.14 cite), and four **grade buttons** with their next-due interval: **Again <1m · Hard 2d · Good 5d · Easy 11d**. |
| 48 | `48_Flashcard_Session_Summary_Mohammed_202401702` | Close the loop: what happened, and what the streak did. | **Check mark**, **Reviewed 20**, **Accuracy 85%**, **Time 6m**, **streak-extended** callout, **Keep going** and **Done**. |

---

## A.7 Group F, Quiz Generation & Analytics · owner M2, Mohammed · feature F05

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 51 | `51_Quizzes_List_Mohammed_202401702` | Quiz history, read as a diagnostic rather than a scoreboard. | **+ New quiz**, **quiz cards** with score, date and **missed-topic chips**, **Retake**. |
| 52 | `52_Quiz_Generate_Config_Mohammed_202401702` | Configure the attempt. | **Question-type control** (MCQ, True/False, Short, Mixed), **question-count stepper**, **difficulty control**, **timer toggle with minutes**, **focus-topics input**, **Generate quiz** primary. |
| 53 | `53_Quiz_Generating_Mohammed_202401702` | Generation in progress, with the grounding claim visible. | **"Grounded in your material"** row ("Every question cites a source page"), **Cancel**. |
| 54 | `54_Quiz_Take_MCQ_Mohammed_202401702` | Answer a question under time pressure. | **Question counter** (3 of 10), **timer ring** (04:32), **question stem**, four **answer options**, **Skip** and **Next**, **flag-question** control. |
| 55 | `55_Quiz_Feedback_Correct_Mohammed_202401702` | Immediate positive feedback with the reasoning, not just a tick. | **Correct option** highlighted, **✓ Correct** badge, **explanation panel**, **citation chip** (p.12 cite), **Next question** primary. |
| 56 | `56_Quiz_Feedback_Incorrect_Mohammed_202401702` | Immediate corrective feedback that teaches the difference. | **Correct option** marked ✓ and the **chosen option** marked ✕, **explanation**, **citation chip** (p.14 cite), **Next question**, and **+ Add to revision plan**. |
| 57 | `57_Quiz_Submit_Confirm_Mohammed_202401702` | Guard against submitting with questions unanswered. | **Confirmation dialog**, **unanswered count** ("2 unanswered"), **explanatory body**, **Submit now** and **Review unanswered**. |
| 58 | `58_Quiz_Results_Scorecard_Mohammed_202401702` | The result, converted into a diagnosis. | **Score ring** (8/10 · 80%), **time taken**, **topic performance bars**, **weak-topic callout**, **Review** and **Retake weak**. |
| 59 | `59_Quiz_Review_Answers_Explanations_Mohammed_202401702` | Per-question review, which is what actually writes `topicMastery`. | Scrollable **per-question cards**: your answer, the correct answer, the explanation, a **citation chip** and a **topic tag**. |

---

## A.8 Group G, Study Plan & Progress · owner M3, Tasbeeh · features F06, F07

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 60 | `60_StudyPlan_Wizard_Subjects_Tasbeeh_202300549` | Wizard 1 of 4: which subjects, at what priority. | **Subject multi-select chips** with a **per-subject priority slider**, **step indicator** (1 of 4), **Continue**. |
| 61 | `61_StudyPlan_Wizard_Availability_Tasbeeh_202300549` | Wizard 2 of 4: when the student is actually free. | **Weekly availability grid** (days × time blocks, tap-to-toggle), **blocked-days picker**, **Continue**. |
| 62 | `62_StudyPlan_Wizard_Deadlines_Tasbeeh_202300549` | Wizard 3 of 4: the fixed points the planner must respect. | **Deadline list** (Chem Quiz 3, Trees Assignment, Linear Exam) each with a date and a **weighting**, **+ Add deadline**, **Continue**. |
| 63 | `63_StudyPlan_Wizard_Intensity_Tasbeeh_202300549` | Wizard 4 of 4: how hard, how long, and when to be reminded. | **Intensity segmented control** (Light, Balanced, Intensive), **session-length stepper** (45 min), **reminder-time picker** (18:30), **Generate my plan**. |
| 64 | `64_StudyPlan_Generating_Tasbeeh_202300549` | Explain what the scheduler is optimising, so the result is trusted. | **"What we optimise"** panel naming spaced-repetition intervals, deadline weighting and review-load balance, **Cancel**. |
| 65 | `65_StudyPlan_Calendar_Week_Tasbeeh_202300549` | The generated week, as colour-coded blocks. | **Month ›** switcher, **day headers** (Mon–Sun), **session blocks** per subject (DS, Chem, Maths, Quiz), **+ Add session**, **tab bar**. |
| 68 | `68_StudyPlan_Session_Detail_Tasbeeh_202300549` | Act on one session without leaving the calendar. | **Session title**, **time and duration**, **linked material**, and the actions **Start now**, **Reschedule**, **Skip**, **Mark done**. |
| 69 | `69_Progress_Dashboard_Tasbeeh_202300549` | Answer "am I on track?" in one screen. | **Stat ring row** (Mastery 64%, Streak 12, 6.5 h this week), **weekly activity chart**, **subjects-in-progress list**, **tab bar**. |
| 70 | `70_Progress_WeaknessRadar_Tasbeeh_202300549` | Close the measure → adapt loop by naming the weak topics and offering the fix. | **Radar chart** of topic mastery, **weakest-topic cards** with a percentage and the actions **Quiz** and **+Plan**, **tab bar**. |

---

## A.9 Group H, AI Study Companion (advanced feature F15) · owners M2, Mohammed + M3, Tasbeeh

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 73 | `73_Coach_Home_Mohammed_202401702` | The entry point to the advanced feature, with the searchable scope stated up front. | **Library-scope chip** ("Searching: 4 materials · 82 pages"), four **prompt-suggestion cards**, **ask bar**, **send** button. |
| 74 | `74_Coach_Chat_Conversation_Mohammed_202401702` | The conversation, with every answer traceable. | **Message bubbles**, **"grounded"** badge, **citation chips** (p.12 cite) under the answer, the **reaction row** (👍 👎 ⧉ copy), **explanation-level segmented control**, **follow-up ask bar**. |
| 75 | `75_Coach_ExplainLevel_Toggle_Mohammed_202401702` | Re-render the same answer at a different depth, including Arabic. | **Segmented control** (Like I'm 12 · Standard · Exam · العربية), and the **same content re-explained** at two levels side by side. |
| 76 | `76_Coach_Citation_SourceSheet_Mohammed_202401702` | Show exactly which passage supports the answer. | **Source header** (material · page), **highlighted snippet**, **relevance and confidence** readout, **Open in viewer**. |
| 77 | `77_Coach_StudyPath_Recommended_Tasbeeh_202300549` | Turn weakness data into an ordered plan. | **Ordered step cards** (Read → Flashcards → Quiz → Review) each with an estimated time, and **Add all to plan**. |
| 78 | `78_Coach_QuizMe_Voice_Tasbeeh_202300549` | An accessibility and learning-style alternative to typing. | **Microphone** button with a **waveform**, **live transcript** of the question read aloud, **Stop**. |

---

## A.10 Group I, Collaboration: folders, group spaces, bookmarks · owner M4, Shahad · features F08, F09, F10

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 81 | `81_Folder_Shared_List_Shahad_202305767` | Every shared folder the student belongs to, with their level of access visible. | **+ New folder**, **folder cards** with a **member avatar stack**, item and member counts, and a **role pill** (Owner / Editor / Viewer). |
| 82 | `82_Folder_Detail_Shahad_202305767` | One shared folder: what is in it, who is in it, and what changed. | **Back**, **folder title**, **share** control, **member avatars**, **+ invite**, **tab bar** (Items, Activity, Members), **item rows** with type chips (PDF, AI summary, Flashcards, Quiz), **activity line**, **+ FAB**. |
| 83 | `83_Folder_Create_Edit_Shahad_202305767` | Create or rename a folder and set who can see it. | **Folder-name field**, **linked-course selector**, **visibility segmented control** (Private, Shared, Public), **Create folder**. |
| 84 | `84_Folder_Invite_Members_Shahad_202305767` | Invite classmates, with the permission chosen at the point of invite. | **Search field**, **contact rows** with avatar, name and student ID, **multi-select checkmarks**, **per-invitee permission picker**, **Send invites**. |
| 85 | `85_Folder_InviteCode_Share_Shahad_202305767` | A second, code-based route in, for people not in the contact list. | **6-character invite code** (tap to copy), **QR code**, **Share link**, **expiry picker** (24 h / 7 days / Never). |
| 86 | `86_Folder_MemberPermissions_Shahad_202305767` | Change a member's access after the fact. | **Member rows** with avatar and name, each with a **permission segmented control** (View, Comment, Edit); the **owner row is locked** with an explanation. |
| 88 | `88_GroupSpace_List_Shahad_202305767` | Every study group the student belongs to, surfacing what is live right now. | **+ New group**, **group cards** with a cover gradient, member count, a **live-now badge** or a **next-session countdown**, and an unread-chat dot. |
| 89 | `89_GroupSpace_JoinByCode_Shahad_202305767` | Join a group from a shared code, including the failure path. | **Code entry** with validation state, a **resolved-group preview**, **Join group** primary, and an explicit **invalid/expired** row with **Retry**. |
| 90 | `90_GroupSpace_Detail_Board_Shahad_202305767` | The shared board for one group: resources, the next session, and the two actions that matter. | **Group title**, **member avatars**, **+ invite**, **tab bar** (Board, Chat, Members), **pinned resource rows**, **next-session card**, and the primaries **Chat** and **Start group quiz**. |
| 91 | `91_GroupSpace_Chat_Shahad_202305767` | Talk about the material without leaving the group. | **Message list** with sender initials, **shared-resource attachment** rows, **reaction row**, **day divider**, **input bar** with attach and send. |
| 92 | `92_GroupSpace_SharedQuiz_Lobby_Shahad_202305767` | Gather everyone before a live quiz, so nobody starts alone. | **Participant rows** with **Ready / Not ready** state, **Host** badge, **waiting indicator**, **topic and count settings** (host only), **Start quiz** (host). |
| 93 | `93_GroupSpace_SharedQuiz_Live_Shahad_202305767` | The live quiz: same question for everyone, at the same time. | **Question counter** (Q3 of 10 · live), **timer**, **question stem**, four **answer options**, **per-player progress strip**, **live leaderboard line**. |
| 94 | `94_GroupSpace_Quiz_Results_Leaderboard_Shahad_202305767` | Rank the group, then hand out the next action. | **Final leaderboard** with rank, player name and points, **group weakest-topic callout**, **Review answers** and **Challenge rematch**. |
| 95 | `95_Bookmarks_Collections_Shahad_202305767` | Collections of saved material, with offline availability visible. | **+ New**, **collection cards** with item count and an **offline-available** badge. |
| 96 | `96_Bookmark_Collection_Detail_Shahad_202305767` | The contents of one collection, with the saved date as context. | **Saved item rows** with a **source-type icon** and **saved date**, row actions (remove, move, open), **Select & share**. |
| 97 | `97_Bookmark_Save_Sheet_Shahad_202305767` | The one shared save path from every screen that can bookmark. | **Collection picker** with checkmarks, **+ Create new collection** inline, **Also save offline** toggle, **Save** primary. |

---

## A.11 Group J, Tutor Content Studio · owner M2, Mohammed · feature F11

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 99 | `99_Home_Dashboard_Tutor_Mohammed_202401702` | The tutor's cockpit: how the cohort is doing and what needs attention first. | **+ Create course**, **cohort KPI row** (124 students, 86 active, 68% average mastery, 7 at risk), **pending AI-review banner**, **course rows** with enrolment counts. |
| 101 | `101_Tutor_Course_Create_Edit_Mohammed_202401702` | Create or edit a course, including who may join. | **Course-name field**, **course-code field**, **term date pickers**, **enrolment-mode control** (Open, Code, Approval), **Save course**. |
| 102 | `102_Tutor_Course_Roster_Mohammed_202401702` | Read the roster as a progress table, not a class list. | **Search students field**, **Export** action, **student rows** with mastery % and last-active label. |
| 103 | `103_Tutor_Material_Publish_Mohammed_202401702` | Stage material as a draft, then publish it deliberately. | **Draft file row** with **"Draft · not visible to students"** state, **publish date/time picker**, **target-cohort selector** (All, Group A, Group B), **Notify students** toggle, **Publish** primary. |
| 104 | `104_Tutor_AI_Content_ReviewQueue_Mohammed_202401702` | Human review of AI-generated content before students ever see it. | **Pending counter** (12), **filter chips** (Low conf., All), **queue rows** with artefact type, page range and **confidence score**, **Bulk approve** action. |
| 105 | `105_Tutor_AI_Content_EditApprove_Mohammed_202401702` | Approve, correct or reject one item, with the source always visible. | **Confidence readout** (0.81), **editable AI draft**, **source panel** with the cited excerpt, and the decisions **Approve**, **Edit & approve**, **Reject with reason**. |

---

## A.12 Group K, Admin Content Management · owner M4, Shahad · feature F12

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 109 | `109_Home_Dashboard_Admin_Shahad_202305767` | The platform at a glance, with quota and moderation risk surfaced above the fold. | **KPI row** (1,284 users, 312 DAU, 4.2k/15k AI calls today, 3/5 GB storage), **quota warning banner**, **moderation queue banner**, and the navigation rows **Users & roles**, **Moderation queue**, **Taxonomy**, **AI configuration**, **Audit log**. |
| 110 | `110_Admin_Users_List_Shahad_202305767` | Find a user, then act on them. | **Search users field**, **role filter chips** (All, Students, Tutors, Admins), **user rows** with role, a **status badge** (active / suspended) and a last-seen label. |
| 111 | `111_Admin_User_Detail_Shahad_202305767` | Change a user's role or suspend them, with the consequence stated. | **User header**, **role changer** with the **"Changing a role requires confirmation"** warning, **activity log** entries, **Suspend account** destructive action. |
| 112 | `112_Admin_Moderation_Queue_Shahad_202305767` | Triage reported content. | **Reported-item rows** with a **reason chip** (Spam, Copyright, Harassment) and age, **Review** action, **open-reports counter**. |
| 115 | `115_Admin_AIConfig_Settings_Shahad_202305767` | The cost-governor innovation, made operational. | **Engine-routing control** (On-device first, Cloud first, Offline only), **per-user daily quota stepper** (15 generations), **cost-estimate readout** (≈ BHD 0.000 today, with the on-device/cloud split), **prompt-template editor**, **Save configuration**. |

---

## A.13 Group L, Subscription & Payments (Tap Payments) · owner M3, Tasbeeh · feature F13

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 118 | `118_Paywall_Plans_Tasbeeh_202300549` | Present the plans in BHD, without dark patterns or hidden pricing. | **Three plan cards** (Free BHD 0, Plus BHD 1.900, Pro BHD 4.900) each listing what it includes, a **recommended ribbon**, **Choose** primary per card, and the **Current** state on the free plan. |
| 120 | `120_Checkout_OrderSummary_BHD_Tasbeeh_202300549` | Show the full cost before any payment detail is requested. | **Plan and term header**, **Subtotal BHD 1.727**, **VAT (10%) BHD 0.173**, **Total BHD 1.900**, **promo-code field**, **terms checkbox**, **Proceed to payment** primary. |
| 121 | `121_Payment_Method_Select_Tasbeeh_202300549` | Let the student pay the way they actually can, in Bahrain. | **Method cards** for **Card** (Visa · Mastercard), **BenefitPay** (redirect to app), **Apple Pay** (Face ID) and **KNET** (Kuwait), a **secure-payment trust row** (🔒 PCI-DSS compliant), **Continue**. |
| 122 | `122_Payment_Card_Entry_Tasbeeh_202300549` | Enter card details in fields we never see. | **Tap Card SDK fields** for number, expiry and CVV, **Save card for next time** toggle, the **"Card data never touches our servers"** note ("Handled by Tap Payments (PCI-DSS)"), **Pay BHD 1.900** primary. |
| 124 | `124_Payment_Processing_Tasbeeh_202300549` | Hold the user still during the charge, and promise not to double-charge. | **Progress overlay**, **"You will never be charged twice"** copy, **idempotency-key** note. |
| 125 | `125_Payment_Success_Receipt_Tasbeeh_202300549` | Confirm the purchase and receipt it properly. | **Success check**, **Receipt card** (Amount BHD 1.900, Method Visa ·· 4242, Reference TAP-8841-2210), **unlocked-features list**, **Done**. |
| 126 | `126_Payment_Failed_Retry_Tasbeeh_202300549` | A declined payment must not read as a dead end. | **Error mark**, **"Nothing has been charged"** reassurance, **retry guidance**, and the two actions **Retry** and **Try another method**. |

---

## A.14 Group M, System, Notifications & Cross-cutting States · owner M1, Saleh · feature F14

| # | Screen | Purpose | Layout and key labelled elements |
|---|---|---|---|
| 128 | `128_Notifications_Inbox_Saleh_202300540` | All notifications in one place, so a missed push is never lost. | **Notification list grouped by day**, **type icons**, **unread dots**, **mark-read** affordance. |
| 129 | `129_Notification_Permission_Request_Saleh_202300540` | The primer shown *before* the system prompt, which is what actually improves opt-in. | **Value explanation** ("so your plan keeps you on track"), **Enable** primary, **Not now** secondary. |
| 132 | `132_Global_Search_Saleh_202300540` | One search across every artefact type. | **Query field**, **scope chips**, **result rows** each labelled with its type (Material, Summary, Deck, Quiz, Folder). |
| 133 | `133_Error_NoInternet_OfflineBanner_Saleh_202300540` | Keep the app honest and usable when the network goes. | **Offline banner** with a **queue indicator** ("3 changes will sync"), **cached** / **Available offline** badges, **"Not downloaded — tap to save"** rows, and the sync explanation. |
| 134 | `134_Error_Server_Retry_Saleh_202300540` | A server failure with a recovery action and a reference to quote. | **Error mark**, **Retry** primary, **reference code** (SF-2026-4471). |
| 138 | `138_Accessibility_LargeText_Example_Saleh_202300540` | Prove the layout survives large text rather than just claiming it does. | The progress dashboard re-rendered at **AX3**, with the annotation "Layout stays intact — nothing clips". |
| 139 | `139_RTL_Arabic_Example_Saleh_202300540` | Prove the app is genuinely localised, including right-to-left mirroring. | The sign-in screen in **Arabic**, fully mirrored, including the localised inline error. |
| 141 | `141_Logout_Confirm_Saleh_202300540` | Ask before a destructive sign-out, and state what is lost. | **Confirmation dialog**, **Keep offline copies** option, **"You can still review downloaded cards offline"** explanation, **Sign out** destructive and **Cancel**. |

---

## A.15 Coverage audit

Every one of the 15 features has at least three screens, and the counts below sum to the 106 frames in the file.

| Group | Area | Owner | Screens | Frames |
|---|---|---|---|---|
| A | Onboarding & Auth | M1 Saleh | 01–10 | 10 |
| B | Profile & Settings | M1 Saleh | 11–18 | 8 |
| C | Courses & Library | M1 Saleh | 24–34 | 10 |
| D | AI Summaries | M2 Mohammed | 35–41 | 5 |
| E | Flashcards & Spaced Repetition | M2 Mohammed | 42–48 | 7 |
| F | Quiz Generation & Analytics | M2 Mohammed | 51–59 | 9 |
| G | Study Plan & Progress | M3 Tasbeeh | 60–70 | 9 |
| H | AI Study Companion (F15, advanced) | M2 + M3 | 73–78 | 6 |
| I | Collaboration: folders, groups, bookmarks | M4 Shahad | 81–97 | 16 |
| J | Tutor Content Studio | M2 Mohammed | 99–105 | 6 |
| K | Admin Content Management | M4 Shahad | 109–115 | 5 |
| L | Subscription & Payments | M3 Tasbeeh | 118–126 | 7 |
| M | System, Notifications & States | M1 Saleh | 128–141 | 8 |
| | **Total** | | | **106** |

**Frames per developer**, matching the ownership in `docs/02-FEATURE-LIST-OWNERSHIP.md`:

| Member | Student ID | Frames | Feature areas |
|---|---|---|---|
| M1 Saleh Abdulla | `202300540` | 36 | F01, F02, F07 home, F14, cross-cutting states |
| M2 Mohammed Almadhoon | `202401702` | 31 | F03, F04, F05, F11, F15 (co) |
| M3 Tasbeeh Saeed | `202300549` | 18 | F06, F07, F13, F15 (co) |
| M4 Shahad Ashoor | `202305767` | 21 | F08, F09, F10, F12 |

**State coverage required by the brief** (loading · empty · error · success · offline · permission):

| State | Screens |
|---|---|
| Loading / in progress | `27`, `28`, `36`, `44`, `53`, `64`, `124` |
| Empty | `42` (no cards due), `82` (folder with no items), `95` (no collections) |
| Error | `30` (unsupported format), `41` (AI quota exceeded), `126` (payment declined), `134` (server retry) |
| Success | `29` (upload), `37` (summary), `48` (session), `58` (quiz), `125` (receipt) |
| Offline | `133` (offline banner and sync queue) |
| Permission | `129` (notification primer) |
| Corrective feedback | `55` (correct), `56` (incorrect), with the explanation and citation for each |
| Confirmation before loss | `57` (submit with unanswered), `141` (sign out) |
| Accessibility proof | `138` (large text AX3), `139` (Arabic RTL) |

---

## A.16 Where the exportable figures come from

**Status: exported, 8 October 2026.** The 106 wireframes and the 15 flow diagrams are the figures for Design Document section 10 and section 9, and they have been exported from the live Figma file through the Figma MCP server, not by hand:

1. **106 wireframe frames** at 2× PNG into `figures/`, named exactly as the Figma frames are (`LF_01_Splash_Logo_Saleh_202300540.png` and so on, one per screen). Each export is the frame plus its legend panel, so the numbered callouts and the element legend stay with the drawing. 1720 × 1920 px each.
2. **15 flow diagram frames** at 2× PNG into the same directory, named `FLOW_Fnn_…png`, one per feature.
3. **Supplementary exports** that are page furniture rather than figures: `LF_00_PageHeader_StudyForge.png` and `F00_FlowDiagrams_Header_StudyForge.png`.
4. **The navigation map, the states panel, the design system sheet, the glass reference and the cover** are exported into `../figures/`, because they belong to sections 10, 11 and 12 rather than to the mockups appendix.

Figure numbering: the 15 flows are Figures 9.1 to 9.15, the states panel is Figure 10.1, the 106 wireframes are Figures 10.2 to 10.107 in screen order (indexed in `DESIGN-DOCUMENT.md` §10.4), the navigation map is Figure 11.1, and the design system and glass sheets are Figures 12.1 and 12.2. The complete list, with statuses, is the document's "List of figures".

The exports are counted and checked by `bash tools/check-submission.sh`, and the measurements behind them are recorded in `../../prototype/figma-audit.md`.

The high-fidelity, interactive version is the same file's page `3 · Screens (all features)`; it is delivered as the Project Prototype, not as document figures, so the document stays a **low-fidelity** mockups section as the brief intends. Page `6 · Dark Mode Variants (P9-12)` holds the 106 dark variants, which are also prototype evidence rather than document figures.







