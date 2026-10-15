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

**Audit date:** 15 October 2026 · **Auditor:** M1 Saleh Abdulla (202300540) · **File revision:** the revision that adds groups N and O (F16, F17) — 119 screens, 17 feature flows

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
| **P9-06** | Every frame named `NN_ScreenName_FirstName_StudentID` | **119 of 119** frames match the rule, 0 violations | ✅ PASS |
| **P9-06b** | Authorship visible per member | Saleh `202300540` 36 · Mohammed `202401702` 31 · Tasbeeh `202300549` 18 · Shahad `202305767` 21 · **Fatema `202304804` 13** (sum 119) | ✅ PASS |
| **P9-07** | Prototype wiring, no dead ends | **320** reactions across the screens (was 296), **110** distinct destination frames, 9 frames that are never a click target: `24`, `30`, `41`, `77`, `78`, `88`, `126`, `133`, `134`, every one of them a named flow start point. **No screen has zero reactions** | ✅ PASS |
| **P9-07b** | Hotspot placement | **111** screens carry their hotspots on real elements (buttons, tab items, list rows, modal actions) and **8** are deliberately tap-anywhere: `27`, `28`, `46`, `59`, `124`, `128`, `138`, `139` | ✅ PASS |
| **P9-08** | Every screen is a fixed iOS frame | **119 of 119** frames measure exactly **390 × 844** | ✅ PASS |
| **P9-11** | Accessibility and RTL proof frames | `138_Accessibility_LargeText_Example_Saleh_202300540` and `139_RTL_Arabic_Example_Saleh_202300540` both exist | ✅ PASS |
| **P9-12** | Dark-mode screen variants | Figma page `6 · Dark Mode Variants (P9-12)` holds **119** variants, one per screen, and **119 of 119** carry the `Dark` mode of the `Color` variable collection set explicitly | ✅ PASS |
| **Mockups** | 106 low-fidelity wireframes | Figma page `5 · Low-Fi Wireframes` holds **106** wireframe frames (107 children including the page header), each with its numbered callouts and legend panel. ⚠️ **Groups N and O have no wireframe yet — see the gap below** | ⚠️ PASS with a stated gap |
| **Flow diagrams** | One per feature | Figma page `2 · Flow Overview` holds **17** `FLOW_Fnn_…` diagrams (F01–F17) plus the global navigation map and the four system diagrams of Figures 5.1, 8.1, 14.1 and 14.2 | ✅ PASS |
| **Figures** | 2× PNG exports for the document | **130** PNGs in `mockups/figures/` (107 wireframe exports + 17 flow diagrams + the system diagrams, navigation map, states panel, design-system sheet and cover), the smallest **1720 px** wide, clearing the 150 dpi floor | ✅ PASS |

### The one gap this re-run found

**Groups N and O have no low-fidelity wireframes.** The 106 wireframes on page `5` cover F01–F15
only. The supervisor's answer at Design Document §3.3 (question 5) was explicit that
**low-fidelity is what the mockup component expects**, so the 13 new screens should get a
low-fidelity counterpart before the prototype is submitted. It is recorded in
[`docs/03`](../../docs/03-SCREEN-INVENTORY.md) §3 and in the Design Document §10.1 as **M5's work**,
and it is deliberately not ticked here.

### What the re-run also had to fix

The 13 new frames were first drawn with **literal hex fills**. That is invisible in light mode but
fatal in dark mode: the mode switch recolours only *variable-bound* paints, so the variants
rendered dark text on a dark canvas. All **478** paints across the 13 frames were therefore bound
to the `Color` variables, and the dark variants were regenerated from the bound frames. The
binding used an **explicit hex-to-variable map**, not a hex lookup — five variables share
`#ffffff` (`onError`, `surface`, `glass/surface`, `glass/strong`, `glass/border`) and a
first-match lookup silently bound card surfaces to `onError`.

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
> **119 of 119** figure above true rather than nominal. The binding used an **explicit
> hex-to-variable map** rather than a hex lookup: five variables share `#ffffff` (`onError`,
> `surface`, `glass/surface`, `glass/strong`, `glass/border`), and a first-match lookup silently
> bound card surfaces to `onError`.

## Frame inventory note

The **119** screens are the frames on page `3 · Screens (all features)`. Page `5 · Low-Fi
Wireframes` is a separate low-fidelity set (`LF_…`, `Wire_…` and `Legend_…` prefixes) and
page `6` is the dark-mode set (`DARK_…`), so no frame can be confused with a prototype
screen.
