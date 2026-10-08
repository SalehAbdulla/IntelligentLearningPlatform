# Design Document deliverables

The exported PDF is built from the Markdown source in this folder, not assembled by hand.

- `DESIGN-DOCUMENT.md`               the source of truth for the document (all 19 sections)
- `StudyForge-Design-Document.pdf`   ✅ **the submission export**, built by `bash tools/build-pdf.sh`: 162 pages, its Appendix A carries every one of the 132 figures one per page at print resolution, fonts embedded by the browser, links live. It is **gitignored on purpose** (`.gitignore` line 79: the PDF goes through the portal, not git), which is exactly why the build is a script: the PDF is reproducible from the Markdown on any machine, and the tool is what gets reviewed here
- `mockups/`                         ✅ the low-fidelity mockups deliverable: `SCREEN-DESCRIPTIONS.md` (purpose, layout and named UI elements for all 106 screens) + `figures/` with the **128 exported 2× PNGs** (106 wireframes, 15 flow diagrams, the four system diagrams drawn 8 Oct 2026, the navigation map and two page headers)
- `figures/`                         ✅ the document figures that are not mockups: the Figma cover, the design system sheet, the glass reference and the cross-cutting states panel

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

**Rebuild it after every change to `DESIGN-DOCUMENT.md`.** The document is still waiting on the
tutor interview, the usability section and the figures its own List of figures marks as
to-draw; a PDF exported before those land is stale evidence rather than a finished one.

**Known gap.** Chromium's command-line printer cannot add page numbers or a running header, and
a CSS `position: fixed` header repeats unreliably (measured: it appeared on two of three test
pages, so it was not used). If the marker wants page numbers, or the "app name in the header of
every page" the document's own cover note promises, run the build with `--html <dir>` and print
`<dir>/index.html` from a browser with "Headers and footers" switched on.

`DESIGN-DOCUMENT.md` is the single source of truth for the submitted PDF, assembled from
`../../../docs/` (which remains the working planning set).
