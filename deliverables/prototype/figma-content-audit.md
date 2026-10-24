# P9-09 / P9-10 — content and consistency audit, by a second reader

> **What this is.** The recorded evidence for two prototype checklist items, specified in
> `docs/01-ROADMAP-PHASES-TODOLIST.md`:
>
> | Item | Requirement, verbatim |
> |---|---|
> | **P9-09** | Content audit — *no lorem ipsum, no "Screen 1", realistic names and grades throughout* |
> | **P9-10** | Consistency audit — *colours, type scale, spacing, radii, icon style all match the design system* |
>
> **Why a "second reader" is the point of it.** Both items are self-audits unless somebody who did
> **not draw the screen** reads it. **M1 (Saleh Abdulla, `202300540`) drew 36 of the 106
> wireframes** — groups A, B, C and M — so M1 is a genuine second reader for the other **70** and is
> *not* one for his own. That split is stated below rather than glossed over: this audit covers **70
> wireframes as a second reader**, and names the 36 that still need somebody else.
>
> **How it was measured — three passes, all reproducible.**
> 1. `bash tools/check-tokens.sh` — the Figma ↔ SwiftUI token parity check, the mechanical half of
>    P9-10 (it exits 0 and is run by `tools/check-submission.sh`).
> 2. Pattern sweeps over the appendix and the frame inventory: placeholder text, generic screen
>    names, and the frame-number sequence.
> 3. A line-by-line read of `deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md` (106
>    screens) against `docs/03-SCREEN-INVENTORY.md`, `docs/02-FEATURE-LIST-OWNERSHIP.md` and the
>    application source — so the copy was checked against what the app actually does rather than
>    against itself.

**Audit date:** 23 October 2026 · **Auditor:** M1 Saleh Abdulla (`202300540`) · **Scope:** the 106 low-fidelity wireframes on Figma page `5 · Low-Fi Wireframes`, their written descriptions in Appendix A, and the design-system consistency of the frame set

> **Superseded in part, 24 October 2026.** The wireframe set grew from **106 to 130** (13 for groups N/O, 11 for the reworked F13 subscription states), Appendix A's coverage audit moved from §A.15 to §A.17, and the counts quoted throughout this audit refer to the 106-frame set it measured. The findings below are kept as the dated record; the current counts live in `figma-audit.md` and `docs/03`.

---

## Verdict

| Item | Requirement | Result |
|---|---|---|
| **P9-09a** | No lorem ipsum or placeholder text | ✅ **PASS** — 0 matches across the appendix, the inventory and the screen descriptions |
| **P9-09b** | No `Screen 1`-style generic names | ✅ **PASS** — 106 of 106 rows carry a real, descriptive name; 0 matches for the generic pattern |
| **P9-09c** | Realistic names and grades | ✅ **PASS** — with one defect found and fixed (F1) |
| **P9-10a** | Colours and tokens match the design system | ✅ **PASS** — `tools/check-tokens.sh` exits 0, machine-checked, and runs inside the submission gate |
| **P9-10b** | Type scale, spacing, radii, icon style | ⚠️ **PASS by construction, not by measurement** — see the limit below. Stated rather than implied |
| **Coverage** | Every built frame is described | ⚠️ **106 described of 119 built** — the 13-frame gap is F16/F17, already recorded, and now named in the appendix itself (F4) |

## Findings, and what changed

**Five findings, all in `SCREEN-DESCRIPTIONS.md`, all fixed in this pass.** None of them changed a
Figma frame: every one is copy in the written appendix, which is the artefact a marker reads
alongside the wireframes.

### F1 — a screen claimed four roles and drew three (content, P9-09)
`10_RoleSelect_…` read *"Choose the role that routes the whole app. **Four roles are supported.**"*
and then listed **three** role cards — Student, Tutor, Admin. The application settles it: `AppRole`
in `Core/Auth/UserSession.swift` has exactly **three** cases (`student`, `tutor`, `admin`), and
Design Document §6 explains that the fourth role the brief counts, **Study Group Member**, is a
capability layered on Student rather than a separate account. The *screen* was right; the sentence
was wrong.
**Fixed:** the row now says three roles are selectable here and names the fourth as a capability,
citing §6 — so the appendix and the code agree, and the rubric's "four roles" claim is no longer
contradicted by the screen that shows three.

### F2 — a section's prose contradicted its own table (consistency, P9-10)
§A.15 opened with *"the counts below sum to the **119 frames** in the file"*, but the table's own
**Total** row read **106**, and the 13 frames the same sentence mentions — groups N and O — were not
rows in it. The arithmetic was right (106 + 13 = 119); the sentence was not.
### F3 — a superseded student ID in an identity row (consistency)
The *Frames per developer* table carried **`202300549`** for M3. Her student ID was corrected to
**`202305409`** on 23 Oct 2026 (`docs/TODOLIST.md` §0), and the roster, `CONTRIBUTING.md`,
`docs/02` and the tooling all carry the new one — making this table the last place asserting the old
ID as an **identity**.
**Fixed (identity), then revisited (artifact names).** On 23 Oct 2026 the identity was corrected and
the **frame suffix** `Tasbeeh_202300549` was deliberately left **unchanged** — an artifact *name*, not
an identity, and renaming it meant editing the Figma file and rebuilding the PDF.
**Reversed on 24 Oct 2026.** The suffix *was* renamed to `Tasbeeh_202305409` across the file: the
cover's team table was still displaying the **transposed ID as an identity** (the front page a marker
opens first), the page-3 screens were already mostly `202305409`, and the artifact names now match the
corrected roster. 40 nodes were renamed (2 screens, 19 wireframes with their titles and legend
children, 19 dark variants) and 20 figures re-exported. The old address is still the one in
`.mailmap`, because that is what her twelve merged commits are authored under — see the alias note in
`docs/02` §2.

### F4 — a table of four members that summed to 106, with no note saying why (content)
*Frames per developer* named M1–M4 and totalled 106, which reads as *"M5 drew nothing"*. True of the
**wireframes** — F16/F17 have no low-fidelity counterpart — and false of the **prototype**, where M5
has 13 screens.
**Fixed:** the table is now *Wireframes per developer*, names **M5 with 0 wireframes and 13
prototype frames**, and says the zero is the recorded gap rather than a contribution.

### F5 — three different frame counts in one document, unreconciled (consistency)
A reader meets **154** (the planned inventory in `docs/03`), **119** (frames built) and **106**
(wireframes described here). All three are correct in context, and none of the three places said so.
**Fixed:** §A.1 now states all three numbers and what each one counts, in one sentence.

## The one limit, stated rather than hidden

**P9-10b is argued, not measured.** The colour half is machine-checked by `tools/check-tokens.sh`,
but **type scale, spacing, radii and icon style are verified by construction**: the low-fidelity set
is generated from the same frame geometry as the high-fidelity prototype, and the design system is
exported as Figures 12.1 and 12.2. **Nobody has measured, say, every corner radius in the file
against `docs/06`.** That is the honest position, written here rather than left as an implied PASS —
a marker who wants the measurement has not been given one, and should know that.

## The reader this audit still needs

**M1's own 36 wireframes** — groups **A** (01–10), **B** (11–18), **C** (24–34) and **M** (128–141)
— are audited by their author, which is exactly what the P9-09/P9-10 process says not to do. **One
of M2, M3, M4 or M5 needs to read those 36**; it is about twenty minutes with the sweeps in this
file, and it is the difference between an audit and a self-assessment. Until that happens, **this
audit covers 70 of the 106 wireframes as a genuine second reader**, and the 36 are named here rather
than quietly counted in.

---

**Re-run this audit whenever the appendix or the frame set changes, and change the date above.** A
stale audit is worse than no audit: it certifies a document that no longer exists.

