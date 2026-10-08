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
- [x] Accessibility: Dynamic Type really scales to AX5; VoiceOver recorded on every product screen (F01-F15); Reduce Motion honoured where it animates; the one fill-hue-as-text contrast defect fixed
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
- [x] Appendix A, the labelled screen descriptions and mockups — `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md` now covers all **106** screens (purpose, layout, named UI elements). The PNG exports into `mockups/figures/` are the only part left.
- [ ] PDF export with embedded fonts and live links. **Partly cleared on 8 Oct 2026:** the exported figures (121 PNGs at 2×, smallest 1720 px wide, so every figure clears 150 dpi), the figure list (`DESIGN-DOCUMENT.md` "List of figures", including the §10.4 per-screen index) and the table list ("List of tables", 21 tables, every caption numbered) are done. **What is left is the PDF itself**, which needs a toolchain this machine does not have
- [x] Create `research/dossier.md` (missing; referenced by section 2 and `docs/01` P1-10). **Done:** the dossier now carries the problem evidence, the 13 sources with what each forces in the design, the affected-population context, the competitor teardown with a stage-coverage table, the SDG mapping with a source per row, the change log from evidence to design, the Harvard list, and the roadmap P1-01 to P1-10 coverage table. It also lists the market figures that are still unverified, so nothing is silently asserted
- [ ] Re-verify the section 2 market figures against their primary sources before submission
- [x] Reconcile the section 1 claim of 98 screens with the final Figma count — reconciled to **106** in `DESIGN-DOCUMENT.md` §1 and §10.1, and in `README.md`

## 5. Figma Prototype, 10%, due 12 Nov 2026

> **State verified against the live file on 8 Oct 2026, and re-measured the same day.** 106 high-fidelity screens, every one exactly 390 × 844 and named to the brief's rule; **296 prototype reactions**, 97 distinct destination screens, and the 9 screens that are never a click target (`24`, `30`, `41`, `77`, `78`, `88`, `126`, `133`, `134`) are all named flow start points, so no screen is a dead end. Also in the file: **106 low-fidelity wireframes**, **15 per-feature flow diagrams**, and **106 dark-mode variants**. The measurements, and what was deliberately not measured, are recorded in `deliverables/prototype/figma-audit.md`

- [ ] P9-03/04 usability test with 5 users plus a SUS score
- [x] P9-06 frame-naming audit, all 106 frames match `NN_ScreenName_FirstName_StudentID`
- [x] P9-07 hotspot and link audit: 296 connections, 97 of 106 reachable by clicking, the other 9 are named flow start points, **zero dead ends**
- [x] P9-08 overflow audit: every screen is a fixed 390×844 iOS frame, verified no text overflows its frame
- [ ] P9-09/10 content and consistency audits (a second reader, per the doc 08 process)
- [x] P9-11 accessibility and RTL frames: `138_Accessibility_LargeText_Example`, `139_RTL_Arabic_Example`
- [x] P9-12 dark-mode frame variants. **Done 8 Oct 2026:** Figma page `6 · Dark Mode Variants (P9-12)` holds **106** variants, one per screen, each with the `Dark` mode of the `Color` variable collection set explicitly and the dark canvas gradient applied to the clone, so no light text sits on a light canvas. Page 3 is untouched. Measured in `deliverables/prototype/figma-audit.md`; two rendered proofs in `deliverables/prototype/dark-mode-proof/`
- [x] P9-14 export the `.fig` into `deliverables/prototype/` — done 8 Oct 2026, 1.2 MB, verified as a real Figma export
- [x] P9-17 assemble `deliverables/prototype/figma-link.txt` (the text document the brief requires). The `.fig` half is P9-14
- [ ] P9-18/19 submit and `git tag prototype-v1`
- [ ] **Human only:** Figma Share -> Anyone with the link -> Can view; File -> Save local copy into `deliverables/prototype/StudyForge.fig`
- [x] **NEW** Phase 1 mockups: 106 low-fidelity wireframes with numbered callouts and per-screen legend panels on Figma page 5, plus `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md`
- [x] **NEW** 15 per-feature flow diagrams on Figma page 2, each ending in its error/edge case
- [x] **NEW** closed two coverage holes: F09 Group Revision Spaces had **zero** screens (88–94 now built and wired) and `57_Quiz_Submit_Confirm` was missing from the quiz flow


## 6. Sprints, 10%, individual (work-queue D, highest open risk)

> **Ready-to-hand agent files for this section.** One per member, self-contained:
> [M2 Mohammed](TODO-M2-mohammed.md) · [M3 Tasbeeh](TODO-M3-tasbeeh.md) ·
> [M4 Shahad](TODO-M4-shahad.md). Each sets the member's git identity, requires a written
> plan before any code, enforces **one commit per file** and a **push on completion**, and
> requires **at least two of that member's features** to carry a real, tested, committed
> change. Conflict prevention is enforced, not documented:
> [doc 14](14-COLLEAGUE-AI-AGENT-PROMPTS.md) holds the disjoint file-lane map and
> `bash tools/check-lane.sh M2|M3|M4` refuses a protected branch or an out-of-lane file.

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
- [x] Accessibility: contrast (no fill hue left as text after the `PaymentView` fix; ratios recorded in `docs/06` §1.1) and VoiceOver across the remaining screens (Tutor, Admin, Onboarding, Profile/ProfileSetup, groups)

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
