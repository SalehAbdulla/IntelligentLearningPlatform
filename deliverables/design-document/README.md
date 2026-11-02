# Design Document deliverables

The exported PDF is built from the Markdown source in this folder, not assembled by hand.

- `DESIGN-DOCUMENT.md`               the source of truth for the document (all 19 sections)
- `StudyForge-Design-Document.docx`   ✅ **the editable export the portal asks for**, built by `bash tools/build-docx.sh` from the university's own template (`tools/templates/IT8108-Design-Document-Template.docx`): the template's cover page filled in (app logo, app name, module, semester, Group ID, Section, Project Brief, Tutor, Submission Date, and the five-member Student ID and Name table), the template's heading and table styles, its running header on every page, its page-number footer, and Appendix A with all 159 figures one per page. **It is committed** so the team can open it from a clone. One caveat: Group ID and Section are the two cover fields the repository does not hold, so they are built from the environment (`GROUP_ID=S3-G4 SECTION="Section 3" bash tools/build-docx.sh`); until then the cover carries the template's own placeholders.
- `StudyForge-Design-Document.pdf`   ✅ **the submission export**, built by `bash tools/build-pdf.sh`: 197 pages, its Appendix A carries every one of the 159 figures one per page at print resolution, fonts embedded by the browser, links live (36 external), and a **running header on every page** (app name + logo) with `Page X of Y` in the footer. **It is committed** (since 24 Oct 2026, so a reviewer opens it straight from a clone; it is inside `deliverables/StudyForge-Submission.zip` too). It stays reproducible: `bash tools/build-pdf.sh` regenerates this exact export from the tracked Markdown and figures on any machine. Because each committed copy is ~25 MB of history, commit it at milestones rather than on every rebuild.
- `mockups/`                         ✅ the low-fidelity mockups deliverable: `SCREEN-DESCRIPTIONS.md` (purpose, layout and named UI elements for all **130** wireframes) + `figures/` with the **154 exported 2× PNGs** (130 wireframes, 17 flow diagrams, the four system diagrams drawn 8 Oct 2026, the navigation map and two page headers)
- `figures/`                         ✅ the document figures that are not mockups: the Figma cover, the design system sheet, the glass reference and the cross-cutting states panel

## Rebuilding the Word document

```bash
bash tools/build-docx.sh                      # the .docx the portal asks for, with Appendix A
bash tools/build-docx.sh --text-only          # body only, no appendix: a fast draft
bash tools/build-docx.sh --check              # rebuild to a temp file and compare with the committed one
GROUP_ID=S3-G4 SECTION="Section 3" bash tools/build-docx.sh   # fill the two cover fields
```

The pipeline is Markdown → pandoc, with a reference document derived from the university's
template (`tools/templates/IT8108-Design-Document-Template.docx`) so the output carries the
template's styles, running header and page-number footer rather than pandoc's defaults. The
script verifies what it produced: heading styles, the template's table style on every table,
the figure count, the header and footer parts, and that the two cover fields are no longer the
template's placeholders. Requires `pandoc` (`brew install pandoc`).

## Rebuilding the PDF

```bash
bash tools/build-pdf.sh                # the submission export, with Appendix A
bash tools/build-pdf.sh --text-only    # body only, no appendix: a fast draft
bash tools/build-pdf.sh --html /tmp/dd # keep the print-ready HTML too (see the gap below)
```

The pipeline is Markdown → HTML (`markdown-it` via `npx`, so the first run needs network) →
print stylesheet (A4, table rules, no orphaned headings) → headless Chromium (Brave, Chrome,
Chromium or Edge). Figures are downscaled with `sips` to a 1600 px long edge, which is never
below ~180 dpi at the largest size the page allows. The script verifies what it produced:
page count, JPEG figure streams, links, file size, and (when `pdftotext` is installed) that
page 1 names the app and that the last page carries a figure caption.

**Rebuild it after every change to `DESIGN-DOCUMENT.md`.** The document is complete apart from the two
items it names itself: the **§17.3 usability test** (prepared, not yet run) and **Figure 4.1**, the
competitor teardown screenshots. Everything else in its List of figures is ✅, including Figure 13.1,
captured 24 Oct 2026. A PDF exported before an edit to the Markdown is stale evidence rather than a
finished one, so rebuild after every change.

**The running header and page numbers are now in the export — this gap is closed.** Chromium's
command-line printer cannot add either, and a CSS `position: fixed` header repeats unreliably
(measured: two of three test pages), so the build adds them a different way: step 4 of
`tools/build-pdf.sh` drives the DevTools Protocol through `tools/pdf-headers.js`, whose
`Page.printToPDF` accepts a `headerTemplate` and a `footerTemplate`. Every page therefore carries
the app name and the logo, and the footer carries `Page X of Y` — which is what the brief asks for
and what the document's own cover note promises. Pass `--no-headers` to build without them, and
`--html <dir>` still keeps the print-ready HTML as the manual fallback.

`DESIGN-DOCUMENT.md` is the single source of truth for the submitted PDF, assembled from
`../../../docs/` (which remains the working planning set).
