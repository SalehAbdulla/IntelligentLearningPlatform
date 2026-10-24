# 15, Project Briefing

> **Plain-language summary of the whole project**, in three parts: what the project is about,
> the 17 features, and the questions to ask the tutor in the group interview.
> Written to be read out loud, not to impress. Use it for interview prep and VIVA revision.
> Sources: [00 Master Plan](00-MASTER-PLAN.md) · [02 Feature List](02-FEATURE-LIST-OWNERSHIP.md) ·
> [08 Rubric Matrix](08-RUBRIC-COVERAGE-MATRIX.md) · [research/interviews](../research/interviews/README.md).

| | |
|---|---|
| **App name** | **StudyForge** |
| **Tagline** | Turn any material into mastery |
| **Module** | IT8108, Project Design Document & Prototype |
| **Client brief** | Project Brief 2, Intelligent Learning Platform |
| **Team** | 5 members, the brief's own default group size |
| **Platform** | iPhone app (SwiftUI) plus a Figma prototype |
| **SDGs** | SDG 4 Quality Education · SDG 9 Industry, Innovation and Infrastructure · SDG 10 Reduced Inequalities |

---

## 1. What the project is about

### 1.1 In one sentence

StudyForge is a phone app that takes the study material a student already has, such as a lecture
PDF, photo or scan, and turns it into summaries, flashcards, quizzes and a revision plan, with AI
doing the heavy lifting.

### 1.2 Where it came from

The module gave the group a list of client briefs to choose from. We chose **Brief 2, Intelligent
Learning Platform**, which asks for:

> "an AI-supported mobile learning platform that helps students organize materials and turn them
> into useful study resources such as summaries, notes, quizzes, and flashcards. The solution
> should promote active learning, personalization, revision planning, and possible collaboration
> or sharing between students."

That paragraph contains four jobs. We call them the four pillars, and every feature must serve at
least one of them.

| Pillar | What the brief asked for | What StudyForge does |
|---|---|---|
| **Organise** | "helps students organize materials" | A course library with folders, tags, bookmarks, search and offline access |
| **Transform** | "turn them into useful study resources such as summaries, notes, quizzes, and flashcards" | AI reads the uploaded file and produces a summary, flashcards, a quiz and notes |
| **Active learning and personalisation** | "promote active learning, personalization, revision planning" | Spaced repetition, an adaptive study plan, and a weakness radar |
| **Collaboration** | "possible collaboration or sharing between students" | Shared study folders, group revision spaces, and live group quizzes |

### 1.3 The three questions the brief asks us to answer

The brief does not specify everything, and it asks three questions directly. Our design document
must answer each one, so here are the answers in short form.

1. **"How can uploaded materials become accurate study resources?"** Accuracy is built into the
   design, not left to luck. The AI only uses the text we extracted from the student's own file, it
   shows which part of the file each answer came from, it says how sure it is, and a tutor can check
   AI content before students see it. We never let AI mark real coursework.
2. **"How can generated resources support different learning styles?"** The student picks a
   learning style and accessibility settings, and the app changes the *format* of what it produces.
   Visual learners get diagrams and mind maps, verbal learners get narration and spoken quizzes,
   read-write learners get structured notes, and hands-on learners get scenario quizzes.
3. **"How can students organize and revisit resources throughout the term?"** A library with
   folders, tags and bookmarks, a global search, a revision timeline driven by what is due, and
   offline access so the material still works with no data.

### 1.4 Who uses it

| User | What they do in the app |
|---|---|
| **Student** | Uploads material, generates summaries and cards, studies, takes quizzes |
| **Tutor / Teacher** | Publishes course material, checks AI content before students see it, sees who is falling behind |
| **Study Group Member** | Shares folders, revises with friends, joins live group quizzes |
| **Admin** | Manages users and roles, moderates content, handles reports, reads the audit log |

The brief names these four roles. The rubric needs at least three, so we have one to spare.

### 1.5 What makes it different

Other apps solve one step of studying. NotebookLM summarises but has no phone revision loop and no
flashcards. Quizlet has cards and quizzes but is cloud-only, English-first, and not based on your
own uploads. Anki has excellent repetition but is hard to use and has no AI.

StudyForge does the whole chain in one app:

> **upload → generate → schedule → practise → measure → adapt**

Three extra things set it apart:

1. **It works offline and the AI runs on the phone first.** Cheaper and more private, which matters
   when students pay for mobile data by the gigabyte.
2. **Every AI answer shows its source.** The app says which part of the file the answer came from,
   and how confident it is.
3. **It is built for this region.** Full Arabic right-to-left layout, plus easy-to-read fonts for
   dyslexia.

### 1.6 What we hand in, and what it is worth

| Component | Weight | Marked | When |
|---|---|---|---|
| Individual App | 10% | Individually | Already completed |
| **Design Document** | 10% | Group | **22 Oct 2026, 23:55** |
| Prototype (Figma) | 10% | Group | **12 Nov 2026, 23:55** |
| Sprints | 10% | **Individually** | Continuous during implementation |
| **iOS App Implementation & Demonstration** | **60%** | Group | Continuous, then in person |

**Two conditions to pass:** an aggregate of 60% or more, **and** a pass in the 60% app component.
So the working app is the most important deliverable, and Figma is not.

### 1.7 Where we are now

- **Figma prototype:** 123 screens built and interactive, with 130 rough wireframes and 17 flow diagrams.
- **iPhone app:** F01 to F15 implemented, it builds, and 723 unit tests pass.
- **Design document:** draft assembled, waiting on the tutor interview for section 3.
- **Sprints:** in progress. Only one member currently has commits in git, which is a real risk.

### 1.8 The team

| Handle | Name | Student ID | Main area | Features owned |
|---|---|---|---|---|
| **M1** | Saleh Abdulla | 202300540 | Data, auth and admin | F01, F02, F14 |
| **M2** | Mohammed Almadhoon | 202401702 | AI/ML and tutor tools | F03, F04, F05, F11, F15 (shared) |
| **M3** | Tasbeeh Saeed | 202305409 | Architecture and payments | F06, F07, F13, F15 (shared) |
| **M4** | Shahad Ashoor | 202305767 | UI/UX, collaboration and admin | F08, F09, F10, F12 |

---

## 2. The features (F01 to F17)

### 2.1 The full list

| # | Feature name | Who uses it | What it does | Built by | Tested by |
|---|---|---|---|---|---|
| **F01** | Authentication & Role-Based Onboarding | Everyone | Sign up, verify your email, pick your role, and land on the right home screen for that role | M1 | M5 |
| **F02** | Material Upload & Course Library | Student, Tutor | Turn a PDF, photo, scan or link into a library item you can search, tag and open offline | M1 | M3 |
| **F03** | AI Summary & Notes Generation | Student | Get an accurate summary of your file with key points and a glossary, and see where each part came from | M2 | M1 |
| **F04** | Flashcard Generation & Spaced Repetition | Student | Turn your file into flashcards, then review them with the app deciding when each card comes back | M2 | M4 |
| **F05** | Quiz Generation & Attempt Analytics | Student, Tutor | Make a quiz from your material, answer it, get a score, and see which topics you are weak in | M2 | M5 |
| **F06** | Study Plan Scheduling & Adaptive Re-planning | Student | Get a revision calendar that fits your exam dates, and fixes itself when you miss a session | M3 | M2 |
| **F07** | Progress Tracking & Analytics | Student, Tutor | See your streak, mastery, time studied, and a weakness radar over time | M3 | M1 |
| **F08** | Shared Study Folders | Study Group Member | Share resources with your group, with real permissions: view, comment or edit | M4 | M3 |
| **F09** | Group Revision Spaces | Study Group Member | Revise together live: shared board, group chat, and a real-time group quiz with a leaderboard | M4 | M1 |
| **F10** | Resource Bookmarking & Collections | Student | Save anything for later into collections, and actually find it again | M4 | M3 |
| **F11** | Tutor Content Studio | Tutor | Publish course material, check AI content before students see it, and see who is behind | M2 | M4 |
| **F12** | Admin Content Management & Moderation | Admin | Manage users and roles, handle reports, manage tags, and read the audit log | M4 | M2 |
| **F13** | Subscription & Payments | Student | Buy and manage a paid plan securely, in Bahraini dinar, with a receipt | M3 | M5 |
| **F14** | Notifications & Reminders | Everyone | Nudge you at the right moment, for example when a flashcard is due, and respect quiet hours | M1 | M3 |
| **F15** | **AI Study Companion (the ADVANCED feature)** | Student | Ask questions about your own material, get answers with sources, change how simple the explanation is, and get a recommended study path | **M2 + M3** | M1 |
| **F16** | **Admin-Moderated Group Chat** | Admin, Study Group Member | Chat with your study group in a room an admin moderates and is **always present in**, so anything unsafe can be removed with a reason | M5 | M4 |
| **F17** | **Active Recall Space (Anki-style)** | Student | Review everything due across **every** deck in one place, with learning steps and daily limits, exactly like Anki | M5 | M2 |

*Table 15.1, the 17 features with their user, purpose, developer and tester.*

### 2.2 The same list, one line each

1. **F01, Authentication & Role-Based Onboarding:** get a verified user to the correct home screen.
2. **F02, Material Upload & Course Library:** turn a file or link into a searchable, offline library item.
3. **F03, AI Summary & Notes Generation:** an accurate, cited summary of one material.
4. **F04, Flashcard Generation & Spaced Repetition:** cards that come back on a smart schedule.
5. **F05, Quiz Generation & Attempt Analytics:** test yourself and find your weak topics.
6. **F06, Study Plan Scheduling & Adaptive Re-planning:** a realistic calendar that repairs itself.
7. **F07, Progress Tracking & Analytics:** mastery, streaks and weak areas over time.
8. **F08, Shared Study Folders:** share resources with real permissions.
9. **F09, Group Revision Spaces:** revise together in real time, including live group quizzes.
10. **F10, Resource Bookmarking & Collections:** save anything and revisit it later.
11. **F11, Tutor Content Studio:** publish material and approve AI content for a cohort.
12. **F12, Admin Content Management & Moderation:** keep the platform correct, safe and compliant.
13. **F13, Subscription & Payments:** buy and manage a paid tier securely.
14. **F14, Notifications & Reminders:** bring the user back at the right moment.
15. **F15, AI Study Companion (advanced):** ask anything grounded in your own material, with sources.

### 2.3 How they group by area

| Area | Features |
|---|---|
| Getting in | F01 |
| Your material | F02, F10 |
| AI study tools | F03, F04, F05, **F15** |
| Planning and progress | F06, F07 |
| Working with others | F08, F09 |
| Tutor tools | F11 |
| Admin tools | F12 |
| Money | F13 |
| Staying in touch | F14 |

### 2.4 Two things the rubric checks in this list

- **Every member owns at least 2 features.** We have 3, 4, 3 and 4, plus F15 shared. Nobody is short.
- **Nobody tests their own feature.** Look down the last two columns of Table 15.1: the pairs never match.

**F15 is the one to watch.** It is the advanced feature the brief requires, it must be approved by
the tutor, and it must be built by only one or two students. That is exactly what interview question 1
asks for, in writing.

---

## 3. The questions for the tutor interview

### 3.1 How the interview works

| Rule | Detail |
|---|---|
| When | Second session of this week, in the section the group is allocated to |
| Length | 15 minutes |
| Who must attend | At least 4 members, or the interview does not go ahead and the group must use office hours. **The group is now 5, so all five attend and three ask** |
| Who asks | 2 to 3 members. Ours are M1, M2 and M4 |
| Who writes | One member takes notes, because the recording may be unclear |
| Graded parts | The **transcript** and the **summary** are graded parts of the Design Document |
| Our questions | 10 core questions in a fixed order, plus 3 buffers |

**Why these questions and not others:** they are all specific to Brief 2, and none of them can be
answered by reading the brief or Moodle. They target the gaps, and every answer changes something
in our design.

### 3.2 The 10 questions, in plain words

| # | Question | Rubric bullet it serves | Asked by |
|---|---|---|---|
| 1 | "Our advanced feature is F15. It is an AI helper that answers only from the student's own uploaded files, and then builds a study plan. Two of us will build it. The brief says the advanced feature must be agreed with you and built by one or two students. Is F15 advanced enough, and is it fine that two of us share it? Can we have your approval in writing today? If F15 is not advanced enough, would F09, the live group quiz room, be acceptable instead?" | Features List: *"Include one approved advanced feature assigned to one or two developers."* | M2 |
| 2 | "Mockups are worth 8 of the 20 marks. We have 106 screens, and every screen has a written description and labelled buttons and fields. To get full marks, do we show every screen, or only the main screens of each feature? Do the error, empty, loading and no-internet screens each need their own labelled screen?" | Mockups: *"Include all required screens and clear navigation flow"* and *"Label key UI elements clearly."* | M4 |
| 3 | "The brief asks how uploaded files become accurate study material. Our plan is: the AI answers only from the student's own file, it shows which part of the file each answer came from, it tells the student how sure it is, and a tutor can check AI content before students see it. We never let AI mark real coursework. Is that what you expect, or do you also want us to measure and report how accurate the AI is?" | Background Research: the real-world problem and why it matters. Innovation: *"relevance, feasibility, and added value."* | M2 |
| 4 | "We have 17 features across 4 user roles, so each of us builds 2 to 4 features, and the minimum is 2. Is 17 the right number, or would you prefer fewer features with more detail in each one?" | Features List: *"Each student must develop at least two features"* and the workload-balance clause. Mockups: coverage. | M4 |
| 5 | "Phase 1 asks for low-fidelity mockups, but the brief says we may use Figma. Our document shows finished, high-fidelity Figma screens. Could showing finished screens cost us mockup marks, or is it fine as long as we cover every screen and label everything?" | Mockups: *"Submit low-fidelity mockups for assigned features."* | M4 |

| 6 | "Brief 2 does not mention payment at all. We added a paid subscription (F13) using Tap, and we wrote down that the App Store would require Apple's own payment system instead. Is that a good extra idea, or is it outside the brief and better left as a note for future work?" | Innovation: *"meaningful enhancement of the selected brief"* and *"relevance."* | M2 |
| 7 | "Innovation is marked on whether the idea is relevant, realistic and adds value. Our main ideas are: the AI runs on the phone first and only uses the cloud when needed, every AI answer shows its source, the app finds weak topics and rebuilds the study plan, and full Arabic right to left with easy-to-read fonts for dyslexia. For full marks, does each idea need a screen or a piece of code to prove it, or is a written explanation enough?" | Innovation: *"Demonstrate original, user-focused improvements"* and *"feasibility."* | M1 |
| 8 | "The brief lists Study Group Member as a role. In our design it is not a separate account: a student joins a group and then gets the group features. Does that still count as 4 roles for the rubric?" | Features List: *"Use at least three user roles."* | M2 |
| 9 | "The transcript and the summary are graded parts of the document. Do you want the transcript word for word and complete? Should it go inside the main document or in an appendix? May we quote your answers directly?" | Background Research: *"Include questions asked and summary of responses."* Document Organization: structure and consistency. | M4 |
| 10 | "We plan to test the app with 5 classmates and give them a standard usability questionnaire, the SUS. What permission and privacy rules do you need from us, and should we avoid asking them to upload their real study files?" | Background Research: supporting research. Mockups: usability of layout. | M1 |

*Table 15.2, the 10 interview questions with the rubric bullet each serves and who asks it.*

### 3.3 Buffer questions (only if time is left)

1. "Is a working iPhone app next to the Figma prototype seen as a plus, or as too much?"
2. "Sprint dates and the final demo date are not in the brief. Can we set five two-week sprints to match the 22 October and 12 November deadlines, and is the final demo live on a real device?"
3. "How much of the Tap against Apple payment conflict should the document explain: one paragraph, or the full plan for switching?"

### 3.4 Timing plan for the 15 minutes

| Time | What happens |
|---|---|
| 0:00 to 0:45 | Ask permission to record, and frame the interview |
| 0:45 to 2:30 | **Q1**, advanced feature approval |
| 2:30 to 4:15 | **Q2**, mockup coverage |
| 4:15 to 5:45 | **Q3**, how accurate the AI must be |
| 5:45 to 7:00 | **Q4**, number of features |
| 7:00 to 8:15 | **Q5**, finished screens in Phase 1 |
| 8:15 to 9:30 | **Q6**, payment, which the brief never mentions |
| 9:30 to 10:30 | **Q7**, what proves an innovation |
| 10:30 to 11:30 | **Q8**, user roles |
| 11:30 to 12:30 | **Q9**, transcript and summary format |
| 12:30 to 13:30 | **Q10**, usability testing rules |
| 13:30 to 15:00 | Buffers and closing |

Q1 is asked first and is never sacrificed, because the rubric needs that approval in writing.

### 3.5 Words to avoid, and what to say instead

| Do not say | Say this |
|---|---|
| RAG, retrieval-augmented generation | "the AI answers only from the student's own uploaded files" |
| grounded generation | "the AI is not allowed to make things up, it uses the student's file" |
| provenance, citation chip | "the answer shows which part of the file it came from" |
| confidence band | "the app says how sure the AI is" |
| low-fidelity / high-fidelity | "rough sketch" / "finished screen" |
| SUS | "a standard 10-question usability survey, scored out of 100" |
| capability set, role layering | "a student joins a group and then gets the group features" |
| monetisation, entitlement | "the paid subscription" |

### 3.6 On the day

- [ ] Confirm the slot and that **5 members** will be there
- [ ] Print Table 15.2, with the timing plan on it
- [ ] Ask permission to record **before** the first question
- [ ] One member writes the answers down as a backup to the recording
- [ ] Get the **F15 approval in writing before leaving the room**
- [ ] Transcribe the recording the same day
- [ ] Fill Design Document section 3.3, one row per question, including what changed as a result
- [ ] File the transcript in `research/interviews/`
- [ ] Rebuild the PDF (`bash tools/build-pdf.sh`) after the interview content lands

---

## Related documents

| Topic | Document |
|---|---|
| The full plan and decoded brief | [00, Master Plan](00-MASTER-PLAN.md) |
| Feature list with flows, edge cases and testers | [02, Feature List & Ownership](02-FEATURE-LIST-OWNERSHIP.md) |
| Every rubric bullet and its evidence | [08, Rubric Coverage Matrix](08-RUBRIC-COVERAGE-MATRIX.md) |
| Interview pack, transcript template and capture sheet | [research/interviews](../research/interviews/README.md) |
| The Design Document itself | [deliverables/design-document](../deliverables/design-document/DESIGN-DOCUMENT.md) |
