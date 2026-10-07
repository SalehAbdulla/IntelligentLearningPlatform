# TODOLIST, StudyForge open work

> **Single live list of what is left.** Built from the live sources on 7 Oct 2026 and kept current by hand from here.
> Sources: `bash tools/todos.sh` (in-code markers), `docs/01`, `docs/08`, `docs/10` (planning checklists), the design-document status markers, and the repository tree.
>
> **Caveat on the other checklists.** The tickboxes in `docs/01`, `docs/08` and `docs/10` are **unmaintained**: many are already done (repo exists, Firebase config, F01 to F15 built, tokens frozen) but were never ticked. This file is the accurate remainder. The only machine-accurate source is `bash tools/todos.sh`.

Legend: `[ ]` open, `[x]` done.

---

## 0. Done recently (context, not work)

- [x] F12 admin: K04 moderation queue, K05 decision panel, K08 audit log (PR #44)
- [x] Commit the VS Code tooling and `tools/run-ios.sh` (PR #46)
- [x] Release `develop` to `main` (PRs #45, #47); `main` and `develop` level

## 1. In-code TODO markers (23 open)

Run `bash tools/todos.sh` for the live list; each line names its file and feature.

### M1, Saleh Abdulla

- [ ] `UserSession.swift:44` route `AppRole.displayName` and `SubscriptionPlan.displayName` through L10n (F01)
- [ ] `AcademicCatalogue.swift:73` replace the scaffolding with the student's real enrolled courses (F02)
- [ ] `ImportMaterialViewModel.swift:25` detect a duplicate upload by content hash, offer Replace / Keep both (F02)
- [ ] `NotificationPreferencesView.swift:11` add a "Send a test reminder" action (F14)
- [ ] `backend/functions/src/index.ts:47` backend prerequisites, see section 3

### M2, Mohammed Almadhoon

- [ ] `PromptTemplates.swift:22` add a `PromptTemplateStore` protocol and a Firestore-backed implementation (F15)
- [ ] `AITier.swift:114` implement the planned tier engine behind the `AIProvider` seam (F15)
- [ ] `FlashcardGenerateView.swift:11` VoiceOver for the generating progress (F04)
- [ ] `FlashcardReviewViewModel.swift:119` track "Hard" separately from "correct" in SM-2 (F04)
- [ ] `CitationSheetView.swift:11` VoiceOver, each citation row reads its source and page (F15)
- [ ] `CoachHomeView.swift:11` VoiceOver for the suggested questions and empty state (F15)
- [ ] `QuizGenerateView.swift:11` VoiceOver for the type and count controls (F05)

### M3, Tasbeeh Saeed

- [ ] `StudyPlan.swift:100` per-course exam-date capture feeding the planner (F06)
- [ ] `SignedInHomeView.swift:144` replace the placeholder with the real student home B05 (F07)
- [ ] `StudySessionDetailView.swift:24` VoiceOver for subject, date and duration (F06)
- [ ] `CheckoutView.swift:18` VoiceOver for the order summary and pay button (F13)
- [ ] `PlanCompareView.swift:17` VoiceOver for each plan card (F13)
- [ ] `NotificationViewModelTests.swift:11` test quiet-hours suppression and a scheduled reminder (F14)
- [ ] `backend/functions/src/index.ts:352` implement `rollupDailyMetrics` (F07)

### M4, Shahad Ashoor

- [ ] `StudyGroup.swift:34` presence seam (`PresenceProvider`) (F09)
- [ ] `LiveQuizSession.swift:16` reconnect and resync path for a disconnected player (F09)
- [ ] `BookmarkStore.swift:14` Firestore-backed `BookmarkStore` (F10)
- [ ] `FlashcardReviewView.swift:11` VoiceOver for the review screen (F04)

## 2. F12 admin (group K)

- [x] K04 moderation queue
- [x] K05 flagged-report decision panel
- [x] K08 dedicated audit log
- [ ] K06 taxonomy management: subject and tag CRUD, drag reorder, merge duplicates, usage count (`114_Admin_Taxonomy_Manage`)
- [ ] K09 broadcast composer: audience segment builder, push preview, schedule, send with confirmation (`117_Admin_Broadcast_Notification`)
- [ ] (optional, K08) redacted-fields indicator (filter and export are done)


## 3. Backend (work-queue B)

- [ ] Deploy prerequisites: Blaze plan, budget alert, spend cap, Tap secrets (account action, human)
- [ ] Add an `onUserCreate` Auth trigger to set the `role` custom claim (unblocks the tutor and admin demo account)
- [ ] Implement `rollupDailyMetrics` (skeleton today, `index.ts:352`)
- [ ] Deploy `createCharge` and `tapWebhook` once Blaze is enabled, then point `.staging` at them
- Note: `cd backend/functions && npx tsc --noEmit` passes today.

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
- [ ] Accessibility audit: VoiceOver, Dynamic Type to AX5, 44 pt targets, contrast 4.5:1, reduce motion

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
3. K06 and K09 (section 2): finish group K.
4. The decisions (section 8).
