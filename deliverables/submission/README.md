# StudyForge — submission bundle

Assembled **24 October 2026** from the repository's `deliverables/`. Everything the brief
asks for across the **Design Document (10%, group)** and the **Prototype (10%, group)** is
in this one directory, so the whole folder can be zipped and uploaded.

## Contents

| Folder | Serves | What is inside |
|---|---|---|
| `01-Design-Document/` | **Design Document (10%)** | `StudyForge-Design-Document.pdf` — **the graded artefact**: 197 pages, 159 figures, 36 live external links, fonts embedded, a running header on every page and “Page X of Y”, 25.1 MB. `StudyForge-Design-Document.docx` — **the editable export the portal asks for**, 22.6 MB, built in the university's own template by `bash tools/build-docx.sh`: its cover page filled in (app logo, Group ID, Section, Project Brief, Tutor, Submission Date, the five-member table), its heading and table styles, its running header and page-number footer, and the same Appendix A. `DESIGN-DOCUMENT.md` — the Markdown source both exports are built from (the single source of truth). `figures/` — the 4 document figures: cover, design-system sheet, glass reference, cross-cutting states panel |
| `02-Mockups/` | Design Document §10 + Appendix A | `SCREEN-DESCRIPTIONS.md` — purpose, layout and named UI elements for all **130** wireframes, plus the coverage and state-coverage audits. `figures/` — the **154** exported 2× PNGs: 130 wireframes, 17 per-feature flow diagrams, 4 system diagrams, the navigation map and the page headers. Smallest 1720 px wide, so every figure clears 150 dpi |
| `03-Prototype/` | **Prototype (10%)** | `StudyForge.fig` — the interactive file (1,830,424 bytes, exported from the Figma desktop app 24 Oct 2026, `meta.json` `exported_at 2026-10-23T23:01:26Z`). `figma-link.txt` — the shared-link text document the brief requires, with the plain token-free URL and the per-flow walkthrough. `dark-mode-proof/` — the two rendered dark-mode proofs |

## Readiness at a glance

| Component | State |
|---|---|
| Design Document PDF | ✅ complete and rebuilt 24 Oct 2026 |
| Appendix A / mockups (130 wireframes, described and labelled) | ✅ complete |
| Feature list, flows, design system, references, appendices | ✅ complete |
| `.fig` + shared link + "Anyone with the link → Can view" | ✅ complete and verified |
| §17.3 **usability test with 5 users + SUS score** | ⬜ **not run** — the pack is ready in `research/usability/`, only the sessions are missing. The document says so plainly rather than inventing a score |
| Figure **4.1** (competitor teardown screenshots) | ⬜ not captured; marked open in the document's List of figures |
| Figure **13.1** (provenance citation chip + confidence band) | ✅ **captured** 24 Oct 2026 from prototype screens 38 and 59 — `figures/13_Provenance_Citation_StudyForge.png` |
| `git tag prototype-v1` | ✅ **created and pushed 24 Oct 2026** at `7cd1bb6`, the branch head when the tag was placed |
| Portal upload | ⬜ the human submission act itself |

Two further notes, both recorded in the documents rather than hidden:

- **Deadline.** The project briefing lists the Design Document as due **22 Oct 2026, 23:55**
  and the Prototype as due **12 Nov 2026, 23:55**.
- **Running header.** ✅ **Closed 24 Oct 2026.** Every page now carries the app name and the logo in
  a header, and `Page X of Y` in the footer — `tools/build-pdf.sh` adds them through
  `tools/pdf-headers.js` (DevTools Protocol), because Chromium's command-line printer cannot.
  `--no-headers` builds without them if a plain draft is wanted.

## Verification

```
bash tools/build-bundle.sh       →  the bundle and the zip match the sources byte for byte
bash tools/check-submission.sh   →  26 of 29 checks cleared; the 3 open are human-only
python3 tools/verify-docs.py     →  ALL CHECKS PASSED
```
The three open checks are the usability test (counted twice) and **P9-18/19 — the portal submission
itself**: the `prototype-v1` tag now exists, but the check also wants the submission to have
happened, so it stays open until it has.

## Rebuilding this bundle

```bash
bash tools/build-pdf.sh                       # rebuild the PDF from DESIGN-DOCUMENT.md
bash tools/build-bundle.sh                    # re-copy, re-zip and byte-verify this bundle
python3 tools/build-figure-index.py           # regenerate §10.4 after any figure re-export
node tools/figma-cli.js export <fileKey> deliverables/design-document/mockups/figures <list.tsv>
```

**This folder is committed** (since 24 Oct 2026), so its layout is browsable in the repository, and so
is the zip (`deliverables/StudyForge-Submission.zip`, ~43 MB) — one clone gets the whole submission
either way. It is a **copy, not a source**: 167 of its 168 files are byte-identical to files under
`deliverables/`, so edit the source and re-copy. Re-copy and re-zip after any change to the documents
or the Figma file, and commit both: `bash tools/build-pdf.sh` plus the copy commands above reproduce
every byte.
