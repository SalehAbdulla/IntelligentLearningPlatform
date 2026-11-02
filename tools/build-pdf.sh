#!/usr/bin/env bash
# build-pdf.sh — build the Design Document PDF from its committed Markdown source.
#
# WHY THIS EXISTS
#   deliverables/design-document/DESIGN-DOCUMENT.md is the source of truth, but the brief is
#   submitted as a PDF, and the rubric asks for an export with embedded fonts, images at
#   150 dpi or better, and live links (docs/08, the "PDF exported" line). Exporting by hand
#   each time the document changes is how a submission ends up generated from a stale draft.
#   This script makes the export reproducible: one command, from the committed Markdown.
#
# WHAT IT DOES
#   1. renders DESIGN-DOCUMENT.md to HTML with markdown-it (via npx, nothing vendored)
#   2. wraps it in a print stylesheet: A4, table rules, no orphaned headings
#   3. appends Appendix A: one figure per page, from figures/ and mockups/figures/,
#      downscaled with sips so the PDF carries print-resolution JPEGs rather than 2x PNGs
#   4. prints it through a headless Chromium browser (Brave, Chrome, Chromium or Edge)
#   5. verifies the output: page count, embedded images, links, size
#
# USAGE
#   bash tools/build-pdf.sh                   # full document with Appendix A (the submission)
#   bash tools/build-pdf.sh --text-only       # body only, no appendix (fast draft)
#   bash tools/build-pdf.sh --out /tmp/x.pdf  # write somewhere else
#   bash tools/build-pdf.sh --html /tmp/x     # also keep the print-ready HTML + images, for a
#                                             # browser print with page numbers and a header
#
# REQUIREMENTS  node/npx (fetches markdown-it, so the first run needs network), sips
#   (macOS, for the downscale) and one Chromium browser. Missing sips or browser is a hard
#   error rather than a silent degradation.
#
# HONEST LIMIT, and how it is now closed: Chromium's command-line printer cannot add page
#   numbers or running headers, and a CSS position:fixed header repeated unreliably when it
#   was measured (two of three test pages). So the header is added a different way: step 4
#   drives the DevTools Protocol through tools/pdf-headers.js, whose Page.printToPDF accepts
#   headerTemplate and footerTemplate. The brief asks for the app name and logo in a header on
#   every page, and that is what the default build now produces. The plain CLI print is still
#   there as the fallback, and --no-headers selects it deliberately.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

DOC="deliverables/design-document/DESIGN-DOCUMENT.md"
OUT="deliverables/design-document/StudyForge-Design-Document.pdf"   # the submission filename
APPENDIX=1
HTML_DIR=""
HEADERS=1   # the brief asks for the app name and logo in a header on every page; see step 4

while [[ $# -gt 0 ]]; do
  case "$1" in
    --text-only) APPENDIX=0; shift ;;
    --out) OUT="${2:-}"; [[ -n "$OUT" ]] || { echo "--out needs a path" >&2; exit 2; }; shift 2 ;;
    --html) HTML_DIR="${2:-}"; [[ -n "$HTML_DIR" ]] || { echo "--html needs a directory" >&2; exit 2; }; shift 2 ;;
    --no-headers) HEADERS=0; shift ;;
    *) echo "unknown argument '$1'" >&2; exit 2 ;;
  esac
done

die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }
info() { printf '  %s\n' "$1"; }

[[ -f "$DOC" ]] || die "$DOC not found; run this from the repository."

TMP="$(mktemp -d)"
KEEP_TMP=0
# The scratch tree (HTML + print-resolution images) is thrown away on success, and kept when
# printing failed so the HTML can still be printed by hand.
trap '[[ "$KEEP_TMP" -eq 1 ]] || rm -rf "$TMP"' EXIT

# ── 1. render the Markdown ──────────────────────────────────────────────
command -v npx >/dev/null 2>&1 || die "npx not found. Install Node, or export the PDF by hand."
info "rendering $DOC with markdown-it"
if ! npx --yes markdown-it@14 -l -t -o "$TMP/body.html" "$DOC" >"$TMP/mdit.log" 2>&1; then
  cat "$TMP/mdit.log" >&2
  die "markdown-it failed (it is fetched with npx, so the first run needs network)."
fi
[[ -s "$TMP/body.html" ]] || die "markdown-it produced an empty file."
ok "body rendered ($(wc -c < "$TMP/body.html" | tr -d ' ') bytes of HTML)"

# ── 2. the figures, downscaled for print ────────────────────────────────
: > "$TMP/figlist.tsv"
if [[ "$APPENDIX" -eq 1 ]]; then
  command -v sips >/dev/null 2>&1 || die "sips not found (macOS). Use --text-only to skip the appendix."
  mkdir -p "$TMP/print"
  i=0
  while IFS= read -r src; do
    i=$((i + 1))
    name="$(printf '%02d' "$i")_$(basename "$src" .png).jpg"
    # 1600 px long edge is ~240 dpi across a 17 cm page width: comfortably past the 150 dpi
    # the rubric asks for, and a fraction of the size of the 2x screen PNGs.
    sips -Z 1600 -s format jpeg -s formatOptions 78 "$src" --out "$TMP/print/$name" >/dev/null 2>&1 \
      || die "sips could not convert $src"
    printf '%s\t%s\n' "$src" "$name" >> "$TMP/figlist.tsv"
  done < <(ls -1 deliverables/design-document/figures/*.png \
                deliverables/design-document/mockups/figures/*.png 2>/dev/null || true)
  ok "figures prepared for print: $i"
fi

# ── 3. the appendix, the print stylesheet, and the internal cross-references ──
info "assembling the print HTML"
python3 - "$TMP/body.html" "$TMP/figlist.tsv" "$TMP/print" "$TMP/index.html" <<'PYEOF'
import html, os, re, sys

body_path, tsv_path, print_dir, out_path = sys.argv[1:5]
body = open(body_path, encoding='utf-8').read()

def natural(s):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s)]

rows = []
if os.path.exists(tsv_path) and os.path.getsize(tsv_path):
    for line in open(tsv_path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line:
            continue
        src, name = line.split('\t')
        rows.append((src, name))
rows.sort(key=lambda r: (0 if r[0].startswith('deliverables/design-document/figures/') else 1,
                         natural(os.path.basename(r[0]))))

def title(basename):
    return re.sub(r'\s+', ' ', basename.replace('_', ' ')).strip()

figs = []
for i, (src, name) in enumerate(rows, start=1):
    base = os.path.basename(src)[:-4]
    figs.append(
        '<figure class="fig" id="fig-%s">\n'
        '  <img src="print/%s" alt="%s">\n'
        '  <figcaption><b>Figure A.%d</b> &middot; %s<br>'
        '<span class="src">%s</span></figcaption>\n'
        '</figure>' % (html.escape(base), html.escape(name), html.escape(base),
                       i, html.escape(title(base)), html.escape(src)))

appendix = ''
if figs:
    appendix = (
        '<h1 id="appendix-a">Appendix A. Figure appendix</h1>\n'
        '<p class="note">Every exported figure, one per page: the document figures first, then '
        'the mockup exports, each group in filename order. The caption repeats the exact '
        'repository path, so any page here can be matched to the entry in the List of figures '
        'and to the file drawn in Figma.</p>\n'
        + '\n'.join(figs) + '\n')

# Point the document's own figure paths at the appendix instead of at a file:// path that
# exists only on the machine that built the PDF. A marker reading the PDF gets a working
# jump rather than a dead link.
def rewrite(match):
    href = match.group(1)
    if href.startswith(('http://', 'https://', '#', 'mailto:')):
        return match.group(0)
    if href.rstrip('/') == 'mockups/figures':
        return match.group(0).replace(href, '#appendix-a')
    base = os.path.basename(href)[:-4] if href.endswith('.png') else None
    if base and any(base == os.path.basename(s)[:-4] for s, _ in rows):
        return match.group(0).replace(href, '#fig-%s' % base)
    return match.group(0)

body = re.sub(r'<a href="([^"]+)">', rewrite, body)

CSS = """
@page { size: A4; margin: 15mm 14mm 17mm; }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { font: 10.5pt/1.45 -apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif; color: #111; margin: 0; }
h1, h2, h3, h4 { line-height: 1.2; page-break-after: avoid; }
h1 { font-size: 19pt; margin: 0 0 8pt; padding-bottom: 4pt; border-bottom: 1.5pt solid #cfd6e0; }
h1:first-of-type { page-break-before: avoid; }
h2 { font-size: 14pt; margin: 18pt 0 5pt; page-break-before: always; }
h1 + h2 { page-break-before: avoid; }   /* the tagline under the title stays on the cover */
h3 { font-size: 12pt; margin: 13pt 0 4pt; }
h4 { font-size: 10.5pt; margin: 10pt 0 3pt; }
p, li { orphans: 3; widows: 3; }
a { color: #0b5ed7; text-decoration: none; }
code, pre { font-family: "SF Mono", Menlo, Consolas, monospace; }
code { font-size: 9pt; background: #f3f5f8; padding: 0 2pt; border-radius: 2pt; }
pre { font-size: 8.5pt; background: #f7f8fa; border: 0.5pt solid #cfd6e0; padding: 6pt;
      white-space: pre-wrap; page-break-inside: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 8.6pt; margin: 6pt 0 10pt; }
th, td { border: 0.5pt solid #cfd6e0; padding: 3pt 4.5pt; text-align: left; vertical-align: top; }
th { background: #eef1f6; font-weight: 600; }
thead { display: table-header-group; }
tr { page-break-inside: avoid; }
blockquote { margin: 8pt 0; padding: 4pt 9pt; border-left: 2.5pt solid #cfd6e0; color: #444; }
hr { border: 0; border-top: 0.5pt solid #cfd6e0; margin: 10pt 0; }
img { max-width: 100%; }
.note { font-size: 9pt; color: #444; }
figure.fig { page-break-before: always; page-break-inside: avoid; text-align: center; margin: 0; }
figure.fig img { max-width: 100%; max-height: 222mm; border: 0.5pt solid #cfd6e0; }
figure.fig figcaption { font-size: 8.5pt; margin-top: 5pt; text-align: left; }
figure.fig .src { display: block; font-family: Menlo, Consolas, monospace; font-size: 7.5pt; color: #666; }
"""

doc = ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n'
       '<title>StudyForge, Design Document</title>\n<style>%s</style>\n</head>\n<body>\n'
       '%s\n%s</body>\n</html>\n' % (CSS, body, appendix))
open(out_path, 'w', encoding='utf-8').write(doc)
print('  appendix figures : %d' % len(figs))
PYEOF

# ── 4. print it ─────────────────────────────────────────────────────────
BROWSER=""
for candidate in \
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
do
  [[ -x "$candidate" ]] && { BROWSER="$candidate"; break; }
done
[[ -n "$BROWSER" ]] || die "no Chromium browser found in /Applications. Install one, or print the generated HTML by hand."

mkdir -p "$(dirname "$OUT")"
info "printing with $(basename "$BROWSER")"

# Chromium's first-run flow hangs when it is handed a brand-new profile, so every attempt
# carries --no-first-run and a watchdog: an attempt that has produced no file inside the
# window is killed rather than allowed to hold the terminal. Strategy 1 uses the real profile
# (fast, and proven fine with the browser already open), strategy 2 an isolated one for the
# case where the real profile is locked.
BROWSER_WAIT="${BROWSER_WAIT:-30}"
print_attempt() {
  rm -f "$OUT"
  "$BROWSER" --disable-gpu --no-pdf-header-footer \
    --no-first-run --no-default-browser-check --disable-sync "$@" \
    --print-to-pdf="$OUT" "file://$TMP/index.html" >"$TMP/browser.log" 2>&1 &
  local pid=$! waited=0
  while [[ $waited -lt $BROWSER_WAIT ]]; do
    [[ -s "$OUT" ]] && { kill "$pid" 2>/dev/null; return 0; }
    sleep 1
    waited=$((waited + 1))
    kill -0 "$pid" 2>/dev/null || break
  done
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  [[ -s "$OUT" ]]
}

# The running header and the page numbers. The brief asks for the app name and logo in a header
# on every page; Chromium's `--print-to-pdf` has no header-template flag, so tools/pdf-headers.js
# drives the DevTools Protocol instead, where `Page.printToPDF` accepts headerTemplate and
# footerTemplate. If that path is unavailable (no node, no magick, or the printer fails) the
# script falls through to the plain CLI print below — faster, but with no header and no page
# numbers. Pass --no-headers to force that path deliberately, e.g. for a quick draft.
HEADER_PRINTED=0
LOGO_SRC="ios/StudyForge/StudyForge/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
if [[ "$HEADERS" -eq 1 ]] && command -v node >/dev/null 2>&1 && [[ -f tools/pdf-headers.js ]]; then
  LOGO=""
  if [[ -f "$LOGO_SRC" ]] && command -v magick >/dev/null 2>&1; then
    magick "$LOGO_SRC" -resize x30 -strip "$TMP/logo30.png" >/dev/null 2>&1 && LOGO="$TMP/logo30.png"
  fi
  info "printing with the running header (app name + logo) and page numbers"
  if node tools/pdf-headers.js "$TMP/index.html" "$OUT" "$LOGO"; then HEADER_PRINTED=1; fi
  [[ "$HEADER_PRINTED" -eq 1 ]] || info "the header printer did not finish; using the plain CLI print instead"
fi

PRINTED=$HEADER_PRINTED
if [[ "$PRINTED" -eq 0 ]]; then
  for mode in "--headless=new" "--headless"; do
    for profile in "--no-first-run" "--no-first-run --user-data-dir=$TMP/profile"; do
      if print_attempt $mode $profile; then PRINTED=1; break 2; fi
    done
  done
fi
if [[ "$PRINTED" -eq 0 ]]; then
  KEEP_TMP=1
  die "the browser did not produce a PDF in ${BROWSER_WAIT}s per attempt (a fresh profile can hang).
    Print the generated HTML by hand instead; it has been kept at:
      $TMP/index.html"
fi
[[ -s "$OUT" ]] || die "the browser reported success but $OUT is empty."

# ── 5. verify, do not assume ────────────────────────────────────────────
python3 - "$OUT" "$APPENDIX" <<'PYEOF'
import os, re, sys
path, appendix = sys.argv[1], sys.argv[2] == '1'
data = open(path, 'rb').read()
figures = data.count(b'DCTDecode')          # one JPEG stream per appendix figure
print('  pages            : %d' % len(re.findall(rb'/Type\s*/Page[^s]', data)))
print('  figure images    : %d%s' % (figures, '' if appendix else '  (--text-only, no appendix)'))
print('  external links   : %d' % len(re.findall(rb'/URI', data)))
print('  size             : %.1f MB' % (os.path.getsize(path) / 1048576))
print('  header           : %s' % data[:5].decode('latin1'))
if appendix and figures == 0:
    print('  WARNING: the appendix was requested but the PDF holds no figure images.')
PYEOF

# A structural check is not a content check. If poppler is available, confirm that what was
# printed is actually this document, on the first page and in the figure appendix, rather than
# a blank or half-rendered export.
if command -v pdftotext >/dev/null 2>&1; then
  pdftotext -f 1 -l 1 "$OUT" "$TMP/p1.txt" 2>/dev/null
  if grep -q "StudyForge" "$TMP/p1.txt"; then
    ok "cover text verified (page 1 names the app)"
  else
    die "page 1 does not contain 'StudyForge': the PDF is not the expected document."
  fi
  if [[ "$APPENDIX" -eq 1 ]]; then
    last="$(python3 -c "import re,sys; d=open(sys.argv[1],'rb').read(); print(len(re.findall(rb'/Type\s*/Page[^s]', d)))" "$OUT")"
    pdftotext -f "$last" -l "$last" "$OUT" "$TMP/plast.txt" 2>/dev/null
    grep -q "Figure A\." "$TMP/plast.txt" \
      && ok "appendix verified (the last page carries a figure caption)" \
      || die "the last page carries no figure caption: the appendix did not render."
  fi
else
  info "pdftotext not found, so the content check was skipped (pages and figure streams were still counted)."
fi

ok "wrote $OUT"

# ── 6. the human print path, on request ─────────────────────────────────
# The default build already carries the running header and page numbers (step 4). Keeping the
# HTML next to its images is still useful: it is the checkable artefact the PDF is printed
# from, and a browser print is the manual fallback if the CDP path is unavailable.
if [[ -n "$HTML_DIR" ]]; then
  mkdir -p "$HTML_DIR"
  cp "$TMP/index.html" "$HTML_DIR/index.html"
  [[ -d "$TMP/print" ]] && cp -R "$TMP/print" "$HTML_DIR/"
  ok "print-ready HTML: $HTML_DIR/index.html"
  info "  open -a \"Brave Browser\" \"$HTML_DIR/index.html\"  then Print, Save as PDF,"
  info "  with 'Headers and footers' switched on, if the header printer could not run."
fi

if [[ "$HEADER_PRINTED" -eq 1 ]]; then
  info "the running header (app name + logo) and 'Page X of Y' are in this export, added"
  info "through tools/pdf-headers.js. --no-headers builds without them."
else
  info "this export has no running header or page numbers: the header printer did not run."
  info "Re-run without --no-headers, or use --html <dir> and print from a browser."
fi
