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

**Audit date:** 24 October 2026 · **Auditor:** M1 Saleh Abdulla (202300540) · **File revision:** the revision that adds the F16/F17 and F13 low-fidelity wireframes — 123 screens, 130 wireframes, 130 dark variants, 17 feature flows

> **Re-run on 15 Oct 2026** after F16 and F17 were drawn and wired. Every number below was
> measured again from the live file on that date; none of them is carried over.

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
| **P9-06** | Every frame named `NN_ScreenName_FirstName_StudentID` | **123 of 123** frames match the rule, 0 violations | ✅ PASS |
| **P9-06b** | Authorship visible per member | Saleh `202300540` 42 · Mohammed `202401702` 31 · Tasbeeh `202305409` 29 · Shahad `202305767` 21 · Fatema `202304804` 0 (sum 123). Naming follows the brief's *named-by-developer* rule, so the F16/F17 frames carry M1 and M3, who drew them; M5 owns both features | ✅ PASS |
| **P9-07** | Prototype wiring, no dead ends | **320** reactions across the screens (was 296), **110** distinct destination frames, 9 frames that are never a click target: `24`, `30`, `41`, `77`, `78`, `88`, `126`, `133`, `134`, every one of them a named flow start point. **No screen has zero reactions** | ✅ PASS |
| **P9-07b** | Hotspot placement | **111** screens carry their hotspots on real elements (buttons, tab items, list rows, modal actions) and **8** are deliberately tap-anywhere: `27`, `28`, `46`, `59`, `124`, `128`, `138`, `139` | ✅ PASS |
| **P9-08** | Every screen is a fixed iOS frame | **122 of 123** frames measure exactly **390 × 844**. ⚠️ **One exception, found on 24 Oct 2026:** `172_Checkout_ExamBoost_Tasbeeh_202305409` measures **390 × 980** (the extra height was needed for the one-time-purchase breakdown). Its low-fidelity wireframe is drawn at the standard 390 × 844 | ⚠️ PASS with one stated exception |
| **P9-08b** | No clipped content inside the wireframes | **130 of 130** wireframes contain their content. **Five pre-existing overflows were found and repaired on 24 Oct 2026** — long single-line text nodes that ran past the 390 px frame edge and were visibly clipped on export: `LF_46` (`55:2431`), `LF_47` (`55:2451`, which also collided with its legend), `LF_93` (`57:707`), `LF_124` (`55:4360`) and `LF_126` (`55:4432`). Each was re-wrapped inside its frame and its figure re-exported | ✅ PASS |
| **P9-11** | Accessibility and RTL proof frames | `138_Accessibility_LargeText_Example_Saleh_202300540` and `139_RTL_Arabic_Example_Saleh_202300540` both exist | ✅ PASS |
| **P9-12** | Dark-mode screen variants | Figma page `6 · Dark Mode Variants (P9-12)` holds **130** variants: one for each of the **123 built screens**, plus the **7 retained** from the superseded F13 first cut (`DARK_118`, `DARK_120`–`DARK_122`, `DARK_124`–`DARK_126`), kept as the record of that pass just as their wireframes are on page 5. Every one carries the `Dark` mode of the `Color` variable collection set explicitly, with the dark canvas gradient applied to the clone. The 11 F13 screens added in the 24 Oct 2026 rework were given their variants the same day | ✅ PASS |
| **Mockups** | 130 low-fidelity wireframes | Figma page `5 · Low-Fi Wireframes` holds **130** wireframe frames (131 children including the page header), each with its numbered callouts and legend panel — every built screen, groups A–O. ✅ **The N/O gap recorded on 15 Oct 2026 was closed on 24 Oct 2026** (see below). Wireframe authorship follows the brief's *named-by-developer* rule: F16 (`LF_142`–`LF_147`) by M1 Saleh, F17 (`LF_148`–`LF_154`) by M3 Tasbeeh, drawn from M5's prototype screens | ✅ PASS |
| **Flow diagrams** | One per feature | Figma page `2 · Flow Overview` holds **17** `FLOW_Fnn_…` diagrams (F01–F17) plus the global navigation map and the four system diagrams of Figures 5.1, 8.1, 14.1 and 14.2 | ✅ PASS |
| **Figures** | 2× PNG exports for the document | **154** PNGs in `mockups/figures/` (130 wireframe exports + 17 flow diagrams + the four system diagrams, navigation map, flow-diagrams header and wireframe-page header), the smallest **1720 px** wide, clearing the 150 dpi floor | ✅ PASS |

### The gap this audit found, and its closure

**Closed 24 October 2026.** The 15 October re-run found that **groups N and O had no low-fidelity wireframes** — the 106 wireframes on page `5` covered F01–F15 only — and that the supervisor's answer at Design Document §3.3 (question 5) made **low-fidelity what the mockup component expects**. That gap is now closed:

| Added | Frames | Why |
|---|---|---|
| F16 moderation wireframes | `LF_142`–`LF_147` | The 13 F16/F17 screens had no low-fidelity counterpart |
| F17 Recall Space wireframes | `LF_148`–`LF_154` | Same gap |
| F13 subscription-state wireframes | `LF_155`–`LF_157`, `LF_172`–`LF_179` | The 24 Oct 2026 F13 rework replaced screens 118/120–126 with 11 new screens |

Page `5` therefore holds **130 wireframes** (131 nodes with the page header), and page `6` holds **130 dark variants**, one per built screen. The `.fig` re-export is **done** — recorded in [`figma-link.txt`](figma-link.txt) §9 as re-exported on 24 October 2026 at 1,830,424 bytes, which is the size of the committed file. (This line previously said the export was *"still open"*; it was written on the same day, before the export ran. Corrected 28 Oct 2026.)

### What the re-run also had to fix

The 13 new frames were first drawn with **literal hex fills**. That is invisible in light mode but
fatal in dark mode: the mode switch recolours only *variable-bound* paints, so the variants
rendered dark text on a dark canvas. All **478** paints across the 13 frames were therefore bound
to the `Color` variables, and the dark variants were regenerated from the bound frames. The
binding used an **explicit hex-to-variable map**, not a hex lookup — five variables share
`#ffffff` (`onError`, `surface`, `glass/surface`, `glass/strong`, `glass/border`) and a
first-match lookup silently bound card surfaces to `onError`.

## Phase 5 re-measurement, 28 October 2026

> **Why this section exists.** The Phase 5 block in [`docs/01` §8](../../docs/01-ROADMAP-PHASES-TODOLIST.md)
> carried **16 unticked boxes** while this file reported PASSes and `prototype-v1` was tagged, so
> there was no way to tell which of the two was right. Everything below was measured from the live
> file on **28 October 2026** with a read-only Plugin API script, the same way the rest of this file
> was measured — and the script is committed as [`tools/figma-phase5-audit.js`](../../tools/figma-phase5-audit.js)
> so the numbers can be re-run rather than believed. The verdicts they support are in `docs/01` §8.

```text
Page 3 · Screens (all features)     123 numbered frames      (agrees with P9-06's 123 of 123)
  Group A  (M1, F01)                 10 of 10   01-10
  Group B  (M1, F01 F14)              8 of 13   11-18        absent 19-23, all P1
  Group C  (M1, F02)                 10 of 11   24-31,33,34  absent 32, P1
  Group M  (M1, F14)                  8 of 14   128,129,132,133,134,138,139,141
                                                     absent 130,131,135,136,137,140, all P1

Page 1 · Design System              2 boards · 2 frames + 17 COMPONENT, 0 COMPONENT_SET
  components                        Button/{Primary,Secondary,Destructive} · Chip/{Default,Tag}
                                    · Input/Text · 11 × Glass/{Card,Surface}
  variables                         3 collections / 52: Color 38 (Light + Dark), Spacing 9, Radius 5
  bindings                          139 nodes carry a variable binding (all survived)
  styles                            11 text · 4 effect · 0 paint

Overflow                            NONE on 122 frames; VERTICAL on 172 (set 28 Oct, see below)
Transitions                         226 reactions across the 123 screens
                                      37 SMART_ANIMATE across 32 distinct pairs · 189 DISSOLVE
                                      · 0 with no transition object
Tallest frame                       172_Checkout_ExamBoost 390 x 980; the other 122 are 390 x 844
Page 0 · Cover & Legend             00_Cover_StudyForge, 67 nodes, full team legend
```

**Four findings, recorded because each one cost marks or was about to:**

1. **P5-01's library was artwork, and is now components.** The page held **13 frames and 0
   `COMPONENT` nodes**, so nothing could be reused or restyled in one place. It now holds **17 named
   components** plus the 2 boards: three button variants, two chips, a text input and eleven glass
   surfaces. Every one kept its exact position and size, its children, its fills and its **55 child
   effects** (the `LAYER_BLUR` glow, `BACKGROUND_BLUR`, the dual `DROP_SHADOW`, the `INNER_SHADOW`),
   and all **139 variable bindings** survived. **The item stays open** because the boards carry six
   of the fifteen element types it lists, and 3 of the 5 button variants. **Consequence recorded:**
   a component draws its name on the canvas, so the two board figures in
   `deliverables/design-document/figures/` — and the submitted PDF built from them — show the boards
   *without* labels. They were left as the document's dated snapshot; regenerating them without
   rebuilding the PDF would only have moved the disagreement.
2. **P5-14 was recorded as NOT DONE, and that was WRONG — corrected here the same day.** The first
   pass read `reaction.transition`, which is `null` on **every** reaction in this file, and reported
   *"0 of 298 carry a transition"*. The transition lives on **`action.transition`**. Read correctly:
   **37 Smart Animate reactions across 32 distinct pairs**, `EASE_OUT`, 0.30–0.35 s, with the
   remaining 189 reactions `DISSOLVE` and **nothing left instant**. The false verdict had already
   reached `docs/01` and was one step from an edit to this prototype to fix a problem that did not
   exist — the read-back is what stopped it. The trap is now written into
   [`tools/figma-phase5-audit.js`](../../tools/figma-phase5-audit.js).
3. **One frame was unreachable, and is now fixed.** `172_Checkout_ExamBoost_Tasbeeh_202305409` is
   **390 × 980** against an 844 device, so its bottom **136 px** could not be reached in the
   prototype viewer. Its overflow is now set to **`VERTICAL`** (Figma's *Scroll*), verified by
   read-back, with the other **122 frames untouched**. That is the only change this pass made to the
   file.
4. **The `.fig` note further up this file was stale and is corrected here.** It said the re-export
   was *"still open"*; [`figma-link.txt`](figma-link.txt) §9 records it **done on 24 October 2026**,
   re-exported at **1,830,424 bytes**, which is the size of the committed `StudyForge.fig`. Both
   statements were written on 24 Oct, and the audit text was written before the export ran.

> **The `.fig` is stale again as of 28 October 2026.** Finding 3 changed the live file, so the
> committed `StudyForge.fig` no longer matches it. The re-export is manual (Figma → *File* → *Save
> local copy…*) and is **outstanding** — recorded here rather than left for someone to discover. The
> P9 measurements above are **unaffected**: no frame's size, name or wiring changed, so P9-06,
> P9-07, P9-08, P9-11 and P9-12 still describe the file as it stands.

**And one cross-reference that does not resolve.** [`docs/03` §1](../../docs/03-SCREEN-INVENTORY.md)
says *"the exact list of unbuilt screen numbers is recorded in `deliverables/prototype/figma-link.txt`
§9"*. **It is not there** — §9 holds the sharing-permission and `.fig`-export items, and no list of
screen numbers. The measured set above is what the file actually supports: **123 built, and every
absent number in M1's four ranges is P1**. The doc 03 sentence is corrected in this same pass.

## What this audit does not cover

Stated so the gap is not mistaken for a pass:

| Not measured here | Why | Where it is tracked |
|---|---|---|
| Text overflow inside each frame at pixel level | P9-08 records the *frame size* measurement. The earlier overflow review was a visual check, not a pixel diff, and it is not re-measured here | `docs/TODOLIST.md` section 5, P9-08 wording |
| P9-09 / P9-10 content and consistency audits | These require a **second reader** who is not the author of the screen, per the process in `docs/08-RUBRIC-COVERAGE-MATRIX.md` | Open in `docs/TODOLIST.md` section 5 |
| The 5-user usability test and its SUS score | Requires real participants, so it cannot be measured from the file | Open in `docs/TODOLIST.md` sections 4 and 5 |
| The "Anyone with the link, Can view" permission | A Figma account setting, not a property of the file | Open in `docs/TODOLIST.md` section 5 and `figma-link.txt` section 9 |

## How to re-run this audit

The measurements above come from read-only Figma Plugin API scripts, driven through the Figma
MCP server by `tools/figma-cli.js`, which is committed so the numbers can be reproduced rather
than believed:

```bash
# the pages, with their child counts (lazy loading means a page must be loaded first)
node tools/figma-cli.js pages uzTHnydXGeZSmImS5k2cLv

# any Figma MCP tool, eg the exported PNG of one frame
echo '{"fileKey":"uzTHnydXGeZSmImS5k2cLv","nodeId":"1:2948","defaultFormat":"png","defaultScale":2}' > /tmp/args.json
node tools/figma-cli.js call uzTHnydXGeZSmImS5k2cLv download_assets /tmp/args.json

# a read-only measurement script (Plugin API code in a file, `return` for output)
node tools/figma-cli.js script uzTHnydXGeZSmImS5k2cLv /tmp/scan.js "measure the frames"

# re-export every figure named in a TSV list of <kind>\t<nodeId>\t<frameName>
node tools/figma-cli.js export uzTHnydXGeZSmImS5k2cLv deliverables/design-document/mockups/figures /tmp/export_list.tsv
```

The same tool produced the 130 document figures and the 119 dark-mode variants (the clone
scripts were one-off Plugin API code, run through the `script` mode). The tool holds no
credentials: it uses the OAuth token that `mcp-remote` already stored for the signed-in Figma
account, so it acts as that user.

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
page 6, so the brief's **119** frame names on the screens page still read exactly as audited
above. Two rendered proofs are stored in `deliverables/prototype/dark-mode-proof/`.

> **The 15 Oct 2026 re-run added a second half to this finding.** The 13 new F16/F17 frames were
> first drawn with **literal hex fills**, so their dark variants rendered dark text on a dark
> canvas — the mode switch had nothing to recolour. All **478** paints across those frames were
> bound to the `Color` variables before the variants were regenerated, which is what makes the
> **130 of 130** figure above true rather than nominal. The binding used an **explicit
> hex-to-variable map** rather than a hex lookup: five variables share `#ffffff` (`onError`,
> `surface`, `glass/surface`, `glass/strong`, `glass/border`), and a first-match lookup silently
> bound card surfaces to `onError`.

## Frame inventory note

The **119** screens are the frames on page `3 · Screens (all features)`. Page `5 · Low-Fi
Wireframes` is a separate low-fidelity set (`LF_…`, `Wire_…` and `Legend_…` prefixes) and
page `6` is the dark-mode set (`DARK_…`), so no frame can be confused with a prototype
screen.
