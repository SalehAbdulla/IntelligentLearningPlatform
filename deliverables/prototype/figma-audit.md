# Figma prototype audit, measured evidence

> **What this is.** The recorded measurements behind the Prototype checklist items in
> `docs/TODOLIST.md` section 5, so a marker (or `tools/check-submission.sh`) can see the
> number and how it was obtained rather than a claim.
>
> **How it was measured.** Through the Figma MCP server against the live file
> `uzTHnydXGeZSmImS5k2cLv` using the Plugin API in read-only scripts: frame names, frame
> sizes and reactions were read from the document tree, and the prototype link graph was
> built from every `reactions` array on every descendant of every screen. Nothing here is
> estimated.
>
> **Re-run this audit** whenever the Figma file changes, and change the date below. A stale
> audit is worse than no audit.

**Audit date:** 8 October 2026 · **Auditor:** M1 Saleh Abdulla (202300540) · **File revision:** the revision exported as `StudyForge.fig` on 8 Oct 2026

---

## Measured results

```text
P9-06 naming audit: PASS
P9-07 link audit: PASS
P9-08 overflow audit: PASS (frame size)
P9-11 accessibility frames: PASS
P9-12 dark mode variants: PASS
```

| Item | Requirement | Measured | Result |
|---|---|---|---|
| **P9-06** | Every frame named `NN_ScreenName_FirstName_StudentID` | **106 of 106** frames match the rule, 0 violations | ✅ PASS |
| **P9-06b** | Authorship visible per member | Saleh `202300540` 36 · Mohammed `202401702` 31 · Tasbeeh `202300549` 18 · Shahad `202305767` 21 (sum 106) | ✅ PASS |
| **P9-07** | Prototype wiring, no dead ends | **296** reactions across the screens, **97** distinct destination frames, 9 frames that are never a click target: `24`, `30`, `41`, `77`, `78`, `88`, `126`, `133`, `134`, every one of them a named flow start point | ✅ PASS |
| **P9-08** | Every screen is a fixed iOS frame | **106 of 106** frames measure exactly **390 × 844** | ✅ PASS |
| **P9-11** | Accessibility and RTL proof frames | `138_Accessibility_LargeText_Example_Saleh_202300540` and `139_RTL_Arabic_Example_Saleh_202300540` both exist | ✅ PASS |
| **P9-12** | Dark-mode screen variants | Figma page `6 · Dark Mode Variants (P9-12)` holds **106** variants, one per screen, and **106 of 106** carry the `Dark` mode of the `Color` variable collection set explicitly | ✅ PASS |
| **Mockups** | 106 low-fidelity wireframes | Figma page `5 · Low-Fi Wireframes` holds **106** wireframe frames (107 children including the page header), each with its numbered callouts and legend panel | ✅ PASS |
| **Flow diagrams** | 15 per-feature flows | Figma page `2 · Flow Overview` holds **15** `FLOW_Fnn_…` diagrams plus the global navigation map | ✅ PASS |
| **Figures** | 2× PNG exports for the document | **121** exports (106 wireframes + 15 flow diagrams) at 1720 × 1920 px and larger, plus the navigation map, the states panel, the design system sheet, the glass reference and the cover | ✅ PASS |

## What this audit does not cover

Stated so the gap is not mistaken for a pass:

| Not measured here | Why | Where it is tracked |
|---|---|---|
| Text overflow inside each frame at pixel level | P9-08 records the *frame size* measurement. The earlier overflow review was a visual check, not a pixel diff, and it is not re-measured here | `docs/TODOLIST.md` section 5, P9-08 wording |
| P9-09 / P9-10 content and consistency audits | These require a **second reader** who is not the author of the screen, per the process in `docs/08-RUBRIC-COVERAGE-MATRIX.md` | Open in `docs/TODOLIST.md` section 5 |
| The 5-user usability test and its SUS score | Requires real participants, so it cannot be measured from the file | Open in `docs/TODOLIST.md` sections 4 and 5 |
| The "Anyone with the link, Can view" permission | A Figma account setting, not a property of the file | Open in `docs/TODOLIST.md` section 5 and `figma-link.txt` section 9 |

## How the dark variants were produced

The Dark variables already existed and were complete, but the screens were only drawn in
light mode. Each variant was produced by cloning its screen onto page `6 · Dark Mode
Variants (P9-12)`, setting the `Dark` mode of the `Color` variable collection explicitly on
the clone, and giving the clone the dark canvas gradient (`bg/a` `#0B1220` to `bg/b`
`#10233A`).

That last step is needed because of an honest finding: on the 106 screens **every surface,
card, text and blob fill is variable-bound** (48 of 49 nodes on a typical screen), but the
**root frame's background gradient is a fixed light gradient**, so the mode switch alone
would leave light text on a light canvas. Page 3 is untouched: the variants live only on
page 6, so the brief's 106 frame names on the screens page still read exactly as audited
above. Two rendered proofs are stored in `deliverables/prototype/dark-mode-proof/`.

## Frame inventory note

The 106 screens are the frames on page `3 · Screens (all features)`. Page `5 · Low-Fi
Wireframes` is a separate low-fidelity set (`LF_…`, `Wire_…` and `Legend_…` prefixes) and
page `6` is the dark-mode set (`DARK_…`), so no frame can be confused with a prototype
screen.
