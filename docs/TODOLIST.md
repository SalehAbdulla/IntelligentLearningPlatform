# TODOLIST, StudyForge open work

> **Single live list of what is left.** Built from the live sources on 7 Oct 2026 and kept current by hand from here.
> Sources: `bash tools/todos.sh` (in-code markers), `docs/01`, `docs/08`, `docs/10` (planning checklists), the design-document status markers, and the repository tree.
>
> **Caveat on the other checklists.** The tickboxes in `docs/01`, `docs/08` and `docs/10` are **unmaintained**: many are already done (repo exists, Firebase config, F01 to F15 built, tokens frozen) but were never ticked. This file is the accurate remainder. The only machine-accurate source is `bash tools/todos.sh`.

Legend: `[ ]` open, `[x]` done.

> **Gate:** `bash tools/check-submission.sh` turns sections 4 and 5 below into a gate. It exits non-zero while any item there is open, it re-checks the evidence behind every ticked box (an empty tick still fails), it refuses to pass if a new item has no registered check, and it runs `verify-docs.py` and `check-strings.py` as well. Current state: **16 of 26 items cleared, 10 open, 9 of those human-only.**

---

## 0. Done recently (context, not work)

- [x] F12 admin: K04 moderation queue, K05 decision panel, K08 audit log (PR #44)
- [x] F12 admin: K06 taxonomy management and K09 broadcast composer (group K complete)
- [x] Accessibility: VoiceOver pass on 8 screens (F04, F05, F06, F13, F15)
- [x] Accessibility: Dynamic Type really scales to AX5; VoiceOver recorded on every product screen (F01-F17); Reduce Motion honoured where it animates; the one fill-hue-as-text contrast defect fixed
- [x] Backend: `onUserCreate` claims trigger and `rollupDailyMetrics` implemented (typechecked)
- [x] Commit the VS Code tooling and `tools/run-ios.sh` (PR #46)
- [x] Add this file, `docs/TODOLIST.md` (PR #48)
- [x] Release `develop` to `main` (PRs #45, #47); `main` and `develop` level
- [x] **Released `develop` to `main` again (PR #106, 15 Oct 2026), after `main` had fallen 233 commits behind.** Found because a reader looking at the README **on `main`** reported that the fifth member was missing — she was not missing, **the branch was stale**. `main` carried **645 lines of the Design Document against `develop`'s 1095**, and **no `research/testing/`, `research/usability/`, `research/reviews/`, `research/meeting-notes/` or `research/demo/` at all**, so any demo or review reading `main` would have seen a materially wrong state. **`main` was identical to `develop` at the moment the release merged** (`git diff --stat origin/main origin/develop` was empty). It falls behind again by exactly the number of commits made after it — which is the normal state between releases, not drift, and the distinction matters: **the problem was 233 commits, not 2.** The release PR **deliberately did not use the documented body template** (*"Sprint N complete. Golden path verified."*) because neither was true: sprint 1 ends 18 Oct, and the golden path is **still unproven on a physical device**. **Lesson recorded:** a release line is only a demo line if it is released; `main` drifted silently for 30 releases because nothing checks it
- [x] **Fifth member added** — **M5 Fatema Ghareeb** `202304804` fills the brief's default fifth seat, so the four-member deviation D16 is closed. Features went **15 → 17**, frames **141 → 154**, the lane map **47 → 49 files across four member lanes**. Recorded in [doc 02 §2.1](02-FEATURE-LIST-OWNERSHIP.md), [doc 03 §3](03-SCREEN-INVENTORY.md) and [doc 09 D27](09-RISKS-OPEN-QUESTIONS.md)
- [x] **F16 and F17 specified end to end** — **F16 Admin-Moderated Group Chat** (the admin is always in the space, enforced in `firestore.rules`) and **F17 Active Recall Space** (Anki-style: one cross-deck queue, learning steps, daily limits, maturity states). Added to the feature list, the screen inventory (groups N and O, frames 142–154), the test rotation, the rubric matrix and the graded Design Document
- [x] **F16/F17 core implemented, tested and pushed** — `feat/F16-moderated-group-chat` (**16 tests**) and `feat/F17-recall-space` (**29 tests**), both building clean and both awaiting review into `develop`. Scaffolded by M1; **M5 owns, extends and finishes them**, with the remaining work marked as `TODO(M5 · F16|F17)` in the code

## 1. In-code TODO markers (14 open — **none of them M1's**)

Run `bash tools/todos.sh` for the live list; each line names its file and feature. Verified **15 Oct 2026**: **M1 0 · M2 3 · M3 3 · M4 3 · M5 5**.

### M1, Saleh Abdulla — **all four closed**

- [x] `UserSession.swift:44` route `AppRole.displayName` and `SubscriptionPlan.displayName` through L10n (F01)
- [x] `AcademicCatalogue.swift:73` replace the scaffolding with the student's real enrolled courses (F02)
- [x] `ImportMaterialViewModel.swift:25` detect a duplicate upload by content hash, offer Replace / Keep both (F02)
- [x] `NotificationPreferencesView.swift:11` add a "Send a test reminder" action (F14)

Verified: `grep -rn 'TODO(M1' ios/` returns **nothing**, and `bash tools/todos.sh M1` reports **0 open**. The heading above said *13 open* until 15 Oct 2026 and this section still listed all four as outstanding — the count had drifted **and** the list contradicted the tool that generates it.

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

### M5, Fatema Ghareeb

- [ ] `GroupModeration.swift:68` add the localised titles and the consequence sentence for each action (F16)
- [ ] `GroupModeration.swift:129` map these to `AppError` with localised copy, **in the same commit that adds them** (F16)
- [ ] `GroupModeration.swift:256` build the **N01–N06** screens on top of this state — the presence banner and the moderator controls (F16)
- [ ] `RecallQueue.swift:141` build the **O01 Recall Space** screen on top of this queue — the due-today list (F17)
- [ ] `RecallSettings.swift:51` add the localised titles for O01's state counters (F17)

> **M5 was absent from this section until 15 Oct 2026**, despite having **five** open markers — more than anyone else. The section had been written when the group had four members and was never revisited when she joined. Her five are also the reason the heading's count moved from 13 to 14 rather than down to 10: **the count had been wrong, not the code.**

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

- [x] Section 3.3 tutor-interview responses and "what changed" — **five questions asked and answered verbatim** in `research/interviews/tutor-interview-transcript.md`, with the impact on the design recorded in Table 3.3
- [x] Section 3.1 — the interview date is **Tuesday 13 October 2026, 2:40 pm**, all five members attended; location, slot and format recorded. (The scribe and the recording-consent answer were not captured in the notes and are marked as such rather than invented)
- [x] Section 3.4 written approval for F15. ✅ **APPROVED in writing on Thursday 15 October 2026 at 2:14 pm** by **Ghassan AlShajjar** (Tutor, EDICT Programming), replying to the request sent at 1:11 pm the same day. Filed verbatim as [`research/interviews/f15-advanced-feature-approval.md`](../research/interviews/f15-advanced-feature-approval.md) and recorded in Design Document §3.4. **The approval carries three conditions**, each tracked to where it is met: the **ownership split** in the feature list (§7, §8.4), **F15 separated from the core AI features** (§7), and the **F02/F05 dependencies** noted (§8.5). F09 was held in reserve as a substitute and was **not needed**
- [ ] Section 17.3 usability test with 5 users plus a SUS score. **Pack prepared, test not run** (15 Oct 2026): `research/usability/` now carries the protocol and facilitator script, the consent form, the SUS questionnaire with its scoring rule, the participant log and the results template, and Design Document §17.3 links them. **What remains is the session itself** — five participants, then fill `results.md` and paste it into §17.3. No score is recorded yet, deliberately: a figure entered before the session would be invented
- [x] Appendix A, the labelled screen descriptions and mockups — `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md` now covers all **106** screens (purpose, layout, named UI elements). The PNG exports into `mockups/figures/` are the only part left.
- [x] PDF export with embedded fonts and live links. **Cleared on 8 Oct 2026:** the exported figures (132 artboards at 2×, smallest 1720 px wide, so every figure clears 150 dpi), the figure list (`DESIGN-DOCUMENT.md` "List of figures", including the §10.4 per-screen index), the table list ("List of tables", **27** tables after the F15 approval additions, every caption numbered) **and the PDF itself**: `bash tools/build-pdf.sh` builds `deliverables/design-document/StudyForge-Design-Document.pdf` from the Markdown (162 pages, Appendix A carries all 132 figures one per page at print resolution, fonts embedded by the browser, 6 external links live plus a working jump from every figure reference into the appendix). **Rebuilt 15 Oct 2026 after the F15 approval landed: 168 pages, 134 figures, 32 external links, 20.9 MB**, with the print HTML kept at `/tmp/ddprint/index.html` via `--html` for a browser print if page numbers are wanted. The rebuild is verified against the print input rather than the PDF bytes, because Chromium's export glyph-encodes its text streams — the HTML the PDF is printed *from* is the checkable artefact. **Known gap, stated in `tools/build-pdf.sh`:** Chromium's command-line printer cannot add page numbers or a running header, so if the marker needs them, re-run with `--html <dir>` and print the generated HTML from a browser with "Headers and footers" on. **Rebuild the PDF after every content change** (the tutor interview and the usability section still land after this export, and Figures 4.1 and 13.1 still need a competitor capture and a real app screenshot)
- [x] Create `research/dossier.md` (missing; referenced by section 2 and `docs/01` P1-10). **Done:** the dossier now carries the problem evidence, the 13 sources with what each forces in the design, the affected-population context, the competitor teardown with a stage-coverage table, the SDG mapping with a source per row, the change log from evidence to design, the Harvard list, and the roadmap P1-01 to P1-10 coverage table. It also lists the market figures that are still unverified, so nothing is silently asserted
- [ ] Re-verify the section 2 market figures against their primary sources before submission
- [x] Reconcile the section 1 claim of 98 screens with the final Figma count — reconciled to **106** in `DESIGN-DOCUMENT.md` §1 and §10.1, and in `README.md`

## 5. Figma Prototype, 10%, due 12 Nov 2026

> **State verified against the live file on 8 Oct 2026, and re-measured the same day.** 106 high-fidelity screens, every one exactly 390 × 844 and named to the brief's rule; **296 prototype reactions**, 97 distinct destination screens, and the 9 screens that are never a click target (`24`, `30`, `41`, `77`, `78`, `88`, `126`, `133`, `134`) are all named flow start points, so no screen is a dead end. Also in the file: **106 low-fidelity wireframes**, **15 per-feature flow diagrams**, and **106 dark-mode variants**. The measurements, and what was deliberately not measured, are recorded in `deliverables/prototype/figma-audit.md`

- [ ] P9-03/04 usability test with 5 users plus a SUS score
- [x] P9-06 frame-naming audit, all 106 frames match `NN_ScreenName_FirstName_StudentID`
- [x] P9-07 hotspot and link audit: 320 connections, 110 of 119 reachable by clicking, the other 9 are named flow start points, **zero dead ends**
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
> `bash tools/check-lane.sh M2|M3|M4` refuses a protected branch or an out-of-lane file, and
> `bash tools/check-lane.sh owner` does the same for M1's project-level lane.

- [x] **R23 is CLOSED — every member can push** (15 Oct 2026, verified against the API): `mohdalmadhon` (M2), `Tasbeeh37` (M3), `shaahaadhani43-debug` (M4) and `FatemaGhareeb` (M5) all hold **write**, and the pending-invitation list is **empty**. **This removes the last external cause and changes what the remaining gap means:** the four members' missing commits are no longer explained by access. Every stale "invitation pending" claim has been cleared from `README.md`, `docs/16-TEAM-KICKOFF.md`, `docs/TODO-M2-mohammed.md`, `docs/TODO-M4-shahad.md` and `docs/09` R23
- [ ] M2, M3, M4 and M5 still have zero authored commits (only Saleh appears in `git shortlog`). The F16/F17 scaffolding on `feat/F16-moderated-group-chat` and `feat/F17-recall-space` is **M1's**, deliberately: M1's task is "split the codebase so others can own it". **M5 must review, extend, test and commit those features under her own identity** before they count as hers
- [x] Sprint-1 contribution logs. **M1's is filled** (15 Oct 2026) from real commits on **7, 8, 14 and 15 Oct**, with the four-day spread recorded honestly rather than hidden; **M2–M5's are still empty templates** — the same blocker as their missing commits
- [ ] Missing artefacts. **`research/testing/` now exists** (5 files: the convention plus four test logs for F03, F07, F09, F15) and **`research/reviews/` now exists** (the convention plus the AI-code review, with nine named corrections and the commit that fixed each). **`research/usability/` is new** — the test pack. **`research/meeting-notes/` now exists** as well (the channel-minutes convention and the minutes template — the async stand-up is defined as three lines in the team channel, so a day's minutes are compiled from what was actually posted). **`research/demo/` now exists too** (the run sheet with per-step fallback lines, the 3×/week regression log, the backup-capture inventory and the injected-failure plan), so **every evidence folder named in `research/README.md` is now present**. Still outstanding inside them: `research/interviews/` needs the recorded transcript and the written F15 approval, and the demo folder's tables need the actual runs and recordings
- [ ] Sprint review recording, `board.png`, `retro.md`
- [ ] Keep the per-member cheat sheets current
- [ ] Each member: set the local git identity, confirm `.mailmap`, claim a feature, make a real change, write a test log

## 7. App and VIVA readiness (docs/11)

- [ ] Golden path proven on a physical device, twice, no dead ends. **The log now exists** — [`research/demo/regression-log.md`](../research/demo/regression-log.md) is the 3×/week record [doc 11 §3](../docs/11-APP-IMPLEMENTATION-VIVA.md) control 3 requires, with a step-per-column table and a **failure table that matters more than the pass table**. The run sheet's **per-step fallback lines** and the **injected-failure plan** (R19) are in the same folder
- [ ] Loading, empty and error states visible; aeroplane-mode graceful degradation
- [ ] Seed demo data and four verified accounts (student, tutor, group, admin)
- [ ] Demo script, two timed rehearsals, backup screen recording on the device and on a USB stick
- [x] Accessibility: 44 pt targets (`Layout.minTouchTarget`), Dynamic Type to AX5, Reduce Motion, VoiceOver on the golden path
- [x] Accessibility: contrast (no fill hue left as text after the `PaymentView` fix; ratios recorded in `docs/06` §1.1) and VoiceOver across the remaining screens (Tutor, Admin, Onboarding, Profile/ProfileSetup, groups)

## 8. Blocked, needs a decision (work-queue E)

- [ ] C1 normalise about 1,289 hardcoded corner radii onto `Radius` tokens
- [ ] C2 de-dash `ios/` and `backend/` and `tools/` (about 814 files still contain em dashes)
- [ ] C3 standardise 119 comma-separated doc headings to colons
- [ ] **R25 — the paywall advertises three plan limits and only one is enforced.** `PlanCompareView` shows *AI generations/day*, *saved materials* and *group spaces*; **only the AI quota is checked** (`AICostGovernor`, wired into `AIRouter`), while `includedMaterials` (20/200/∞) and `includedGroupSpaces` (1/5/∞) exist **only in paywall display code**. **Decide, then do one of two things:** wire both caps at the write, following the `AICostGovernor` pattern so a refusal explains itself; **or** stop presenting them as limits and sell the paid tiers on what is genuinely metered — remembering that **on-device AI is unlimited on every tier including Free**, which makes that second option stronger than it sounds. Full analysis and evidence in [`docs/09` R25](09-RISKS-OPEN-QUESTIONS.md)
- [ ] `docs/09` section 3 open questions Q2 to Q7, Q9, Q12, Q13

## 9. Doc-versus-code contradictions to fix

- [x] `tools/check-tokens.sh`. **Implemented 15 Oct 2026, and it immediately found two real defects.** It was a five-line stub printing `TODO` and exiting **0**, while `docs/06` section 6 and `docs/09` R10 both claimed it failed the build on divergence — false twice over, since no CI workflow exists either. It now checks the **colour** tokens name-for-name between `docs/06` section 1.1 and `ColorTokens.swift`, fails in **either** direction, and **fails closed** if it cannot read its inputs. Both docs now state its real scope. **What it found:** (1) `onError` was in the code and absent from the documentation — fixed; (2) **R24**, a token named for one role and used in another, recorded in `docs/09` for the design system's owner because `DesignSystem/` is outside M1's lane. **The other token groups are not machine-checked**, and the reason is now written down: their names differ by convention on each side (`Space/4` vs `s4`, `Type/body` vs `sfBody`), so a name-grep would fail on every row
- [x] **Three different frame counts were being used as if they were one.** Reconciled 15 Oct 2026: **106** low-fidelity **wireframes** (the Mockups requirement, `SCREEN-DESCRIPTIONS.md`), **119** hi-fi **frames built** of a **154**-frame **inventory** (the prototype), and per-owner totals of **M1 48 · M2 41 · M3 25 · M4 27 · M5 13**. `docs/08` had a stale audit row reading *"frames-per-developer: M1 36, M2 31, M3 18, M4 21"* — **106 frames and omitted M5 entirely**, from before the fifth seat existed — and a `c2` row claiming *"141 total"*, which was neither number. All corrected, and the c7/demo1 owners now include **M5**
- [x] **`tools/check-release.sh` added (15 Oct 2026), and wired into `tools/check-submission.sh`.** Written because `main` had drifted **233 commits** behind `develop` and nothing detected it across **30 releases**. It **fails** when a whole directory exists on `develop` and is absent from `main` — the condition that actually broke `main`, and one a commit count cannot see — and **warns** past a commit threshold without failing, because this project made 301 commits in a day and a check that fires every afternoon gets ignored. **Verified in both directions:** it exits **1** against the old drifted `main` (`8a7d3d0`, naming `research/demo`, `research/interviews`, `research/testing` and `research/usability` as absent) and **0** against the current one. `RELEASE_MAIN` / `RELEASE_DEV` / `RELEASE_MAX_DRIFT` / `RELEASE_MIN_DIR_FILES` make it testable, because a check that cannot be made to fail is not a check. **`tools/check-tokens.sh` is now wired into the gate too**, so `docs/06` section 6's claim that it gates a submission is true rather than aspirational. The gate's denominator moved **26 → 28** as a result
- [ ] Tick or reconcile the stale checklists in `docs/01`, `docs/08` and `docs/10`. **Measured 15 Oct 2026: `docs/01` has 148 unchecked boxes, `docs/08` 25 and `docs/10` 6.** **Not ticked in this pass, deliberately:** most of those boxes are completed work, but confirming each one means reading the artefact it names, and **ticking a box that has not been checked is worse than leaving it unticked** — it converts a visible gap into a false claim. Two items in this section were reconciled because they were verifiable in one command (`tools/check-tokens.sh`, and M1's four TODO markers, both confirmed against the code). **The rest is a real audit, not a quick win**, and it is worth doing properly rather than quickly
- [ ] `README.md` lines 161 and 163 show "App identity frozen" and "Cline agent skills installed" as open, which look out of date

## 10. Suggested order

1. The three teammates author their first commits (section 6): gates 10 percent plus the VIVA.
2. The Design Document items (section 4): the nearest deadline, 22 Oct.
3. K09 (section 2): the last admin surface.
4. The decisions (section 8).
