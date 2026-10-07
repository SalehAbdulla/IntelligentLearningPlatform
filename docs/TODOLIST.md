# TODOLIST, StudyForge open work

> **Single live list of what is left.** Built from the live sources on 7 Oct 2026 and kept current by hand from here.
> Sources: `bash tools/todos.sh` (in-code markers), `docs/01`, `docs/08`, `docs/10` (planning checklists), the design-document status markers, and the repository tree.
>
> **Caveat on the other checklists.** The tickboxes in `docs/01`, `docs/08` and `docs/10` are **unmaintained**: many are already done (repo exists, Firebase config, F01 to F15 built, tokens frozen) but were never ticked. This file is the accurate remainder. The only machine-accurate source is `bash tools/todos.sh`.

Legend: `[ ]` open, `[x]` done.

---

## 0. Done recently (context, not work)

- [x] F12 admin: K04 moderation queue, K05 decision panel, K08 audit log (PR #44)
- [x] F12 admin: K06 taxonomy management and K09 broadcast composer (group K complete)
- [x] Accessibility: VoiceOver pass on 8 screens (F04, F05, F06, F13, F15)
- [x] Accessibility: Dynamic Type really scales to AX5; VoiceOver notes across the golden path (F02, F03, F07, F08, F10, F14); Reduce Motion honoured on the group-chat scroll (F09)
- [x] Backend: `onUserCreate` claims trigger and `rollupDailyMetrics` implemented (typechecked)
- [x] Commit the VS Code tooling and `tools/run-ios.sh` (PR #46)
- [x] Add this file, `docs/TODOLIST.md` (PR #48)
- [x] Release `develop` to `main` (PRs #45, #47); `main` and `develop` level

## 1. In-code TODO markers (13 open)

Run `bash tools/todos.sh` for the live list; each line names its file and feature.

### M1, Saleh Abdulla

- [ ] `UserSession.swift:44` route `AppRole.displayName` and `SubscriptionPlan.displayName` through L10n (F01)
- [ ] `AcademicCatalogue.swift:73` replace the scaffolding with the student's real enrolled courses (F02)
- [ ] `ImportMaterialViewModel.swift:25` detect a duplicate upload by content hash, offer Replace / Keep both (F02)
- [ ] `NotificationPreferencesView.swift:11` add a "Send a test reminder" action (F14)

### M2, Mohammed Almadhoon

- [ ] `PromptTemplates.swift:22` add a `PromptTemplateStore` protocol and a Firestore-backed implementation (F15)
- [ ] `AITier.swift:114` implement the planned tier engine behind the `AIProvider` seam (F15)
- [ ] `FlashcardReviewViewModel.swift:119` track "Hard" separately from "correct" in SM-2 (F04)

### M3, Tasbeeh Saeed

- [ ] `StudyPlan.swift:100` per-course exam-date capture feeding the planner (F06)
- [ ] `SignedInHomeView.swift:144` replace the placeholder with the real student home B05 (F07)
- [ ] `NotificationViewModelTests.swift:11` test quiet-hours suppression and a scheduled reminder (F14)

### M4, Shahad Ashoor

- [ ] `StudyGroup.swift:34` presence seam (`PresenceProvider`) (F09)
- [ ] `LiveQuizSession.swift:16` reconnect and resync path for a disconnected player (F09)
- [ ] `BookmarkStore.swift:14` Firestore-backed `BookmarkStore` (F10)

## 2. F12 admin (group K)

- [x] K04 moderation queue
- [x] K05 flagged-report decision panel
- [x] K08 dedicated audit log
- [x] K06 taxonomy management: subject and tag CRUD, drag reorder, merge duplicates, usage count (`114_Admin_Taxonomy_Manage`)
- [x] K09 broadcast composer: audience segment builder, push preview, schedule, send with confirmation (`117_Admin_Broadcast_Notification`)
- [ ] (optional, K08) redacted-fields indicator (filter and export are done)

Group K (admin content management) is now feature-complete.


## 3. Backend (work-queue B)

- [x] Add an `onUserCreate` Auth trigger that sets the `role` and `plan` custom claims at sign-up
- [x] Implement `rollupDailyMetrics` (activity and quiz aggregation into `progress` and `topicMastery`)
- [ ] Deploy prerequisites: Blaze plan, budget alert, spend cap, Identity Platform, Tap secrets (account action, human)
- [ ] Deploy the four functions once Blaze is enabled, then point `.staging` at them
- Note: `cd backend/functions && npx tsc --noEmit` passes; the functions are not deployed.

## 4. Design Document, 10%, due 22 Oct 2026 (work-queue C)

- [ ] Section 3.2/3.3 tutor-interview responses and "what changed" (blocked on the interview)
- [ ] Section 3.1 interview date is `to be recorded`
- [ ] Section 3.4 written approval for F15 (`pending`)
- [ ] Section 17.3 usability test with 5 users plus a SUS score (planned, not run)
- [ ] Appendix A, the 89 labelled P0 screen descriptions and mockups
- [ ] Figures at 150 dpi or more; figure list; table list; PDF export with embedded fonts and live links
- [ ] Create `research/dossier.md` (missing; referenced by section 2 and `docs/01` P1-10)
- [ ] Re-verify the section 2 market figures against their primary sources before submission
- [ ] Reconcile the section 1 claim of 98 screens with the final Figma count

## 5. Figma Prototype, 10%, due 12 Nov 2026

- [ ] P9-03/04 usability test with 5 users plus a SUS score
- [ ] P9-06 frame-naming audit
- [ ] P9-07 hotspot and link audit, zero dead ends
- [ ] P9-08/09/10 overflow, content and consistency audits
- [ ] P9-11/12 accessibility, dark mode and RTL frames
- [ ] P9-14 export the `.fig`
- [ ] P9-17 assemble the `.fig` plus `deliverables/prototype/figma-link.txt`
- [ ] P9-18/19 submit and `git tag prototype-v1`
- [ ] Human only: Figma Share -> Anyone with the link -> Can view; File -> Save local copy into `deliverables/prototype/StudyForge.fig`

## 6. Sprints, 10%, individual (work-queue D, highest open risk)

- [ ] M2, M3 and M4 still have zero authored commits (only Saleh appears in `git shortlog`)
- [ ] Sprint-1 contribution logs are empty templates
- [ ] Missing artefacts: `research/testing/`, `research/reviews/`, `research/meeting-notes/`, `research/interviews/`, `research/demo/`
- [ ] Sprint review recording, `board.png`, `retro.md`
- [ ] Keep the per-member cheat sheets current
- [ ] Each member: set the local git identity, confirm `.mailmap`, claim a feature, make a real change, write a test log

## 7. App and VIVA readiness (docs/11)

- [ ] Golden path proven on a physical device, twice, no dead ends
- [ ] Loading, empty and error states visible; aeroplane-mode graceful degradation
- [ ] Seed demo data and four verified accounts (student, tutor, group, admin)
- [ ] Demo script, two timed rehearsals, backup screen recording on the device and on a USB stick
- [x] Accessibility: 44 pt targets (`Layout.minTouchTarget`), Dynamic Type to AX5, Reduce Motion, VoiceOver on the golden path
- [ ] Accessibility: contrast 4.5:1 verification, and the VoiceOver pass on the remaining screens (Tutor, Admin, Onboarding, Profile/ProfileSetup, groups live quiz)

## 8. Blocked, needs a decision (work-queue E)

- [ ] C1 normalise about 1,289 hardcoded corner radii onto `Radius` tokens
- [ ] C2 de-dash `ios/` and `backend/` and `tools/` (about 814 files still contain em dashes)
- [ ] C3 standardise 119 comma-separated doc headings to colons
- [ ] `docs/09` section 3 open questions Q2 to Q7, Q9, Q12, Q13

## 9. Doc-versus-code contradictions to fix

- [ ] `tools/check-tokens.sh` is a stub yet `docs/06` section 6 and `docs/09` R10 claim it fails the build on divergence
- [ ] Tick or reconcile the stale checklists in `docs/01`, `docs/08` and `docs/10`
- [ ] `README.md` lines 161 and 163 show "App identity frozen" and "Cline agent skills installed" as open, which look out of date

## 10. Suggested order

1. The three teammates author their first commits (section 6): gates 10 percent plus the VIVA.
2. The Design Document items (section 4): the nearest deadline, 22 Oct.
3. K09 (section 2): the last admin surface.
4. The decisions (section 8).
