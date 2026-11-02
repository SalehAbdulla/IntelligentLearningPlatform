#!/usr/bin/env bash
# build-docx.sh — build the Design Document .docx from its committed Markdown source, in the
# university's own template.
#
# WHY THIS EXISTS
#   The IT8108 template (tools/templates/IT8108-Design-Document-Template.docx) is the required
#   shape of the Design Document: its cover page, its running header, its heading and table
#   styles. The template also says "submit the document as a PDF", and the portal asks for the
#   editable Word file, so both are produced, from one source, by one command each:
#   this script does the .docx, tools/build-pdf.sh does the PDF.
#
# WHAT IT DOES
#   1. derives a reference document from the template: its styles, headers, footers, numbering
#      and theme, with the template's instruction body removed (pandoc --reference-doc)
#   2. writes the cover page from the template's own fields: app logo, app name, module and
#      semester, then Group ID, Section, Project Brief, Tutor and Submission Date, and the
#      five-member Student ID and Name table
#   3. appends Appendix A, one figure per page, from figures/ and mockups/figures/, the same
#      figures and the same order as the PDF's appendix
#   4. renders cover + DESIGN-DOCUMENT.md + appendix through pandoc, then styles every table
#      with the template's TableGrid
#   5. verifies the output: heading styles, table style, figures, running header, footer, and
#      that the two cover fields are not still the template's placeholders
#
# USAGE
#   bash tools/build-docx.sh                    # deliverables/design-document/StudyForge-Design-Document.docx
#   bash tools/build-docx.sh --out /tmp/x.docx  # write somewhere else
#   bash tools/build-docx.sh --text-only        # no figure appendix (fast draft)
#   bash tools/build-docx.sh --check            # rebuild to a temp file and compare with the committed one
#   GROUP_ID=S3-G4 SECTION="Section 3" bash tools/build-docx.sh
#
# REQUIREMENTS  pandoc (brew install pandoc). Group ID and Section are the two cover fields the
#   repository does not hold; they come from the environment and default to the template's own
#   bracketed placeholders, which must be replaced before submission.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

DOC_DIR="deliverables/design-document"
SRC="$DOC_DIR/DESIGN-DOCUMENT.md"
TEMPLATE="tools/templates/IT8108-Design-Document-Template.docx"
LOGO="ios/StudyForge/StudyForge/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
OUT="$DOC_DIR/StudyForge-Design-Document.docx"
APPENDIX=1
CHECK=0
GROUP_ID="${GROUP_ID:-[S#-G#]}"
SECTION="${SECTION:-[Section #]}"

while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --text-only) APPENDIX=0; shift ;;
    --check) CHECK=1; shift ;;
    -h|--help) sed -n '1,33p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

ok()   { printf '  \033[32mok\033[0m   %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; }
die()  { printf '  \033[31mfail\033[0m %s\n' "$*" >&2; exit 1; }

command -v pandoc >/dev/null 2>&1 || die "pandoc not found. Install it with: brew install pandoc"
[ -f "$SRC" ] || die "$SRC is missing"
[ -f "$TEMPLATE" ] || die "$TEMPLATE is missing"
[ -f "$LOGO" ] || die "$LOGO is missing"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
[ "$CHECK" -eq 1 ] && OUT="$TMP/check.docx"

echo "== 1. reference document: the template's styles, without its instructions =="
python3 - "$TEMPLATE" "$TMP/ref.docx" <<'PY'
import re, shutil, sys, zipfile

src, dst = sys.argv[1], sys.argv[2]
z = zipfile.ZipFile(src)
doc = z.read('word/document.xml').decode('utf-8')
# Keep only the final sectPr: it carries the page size, margins and the header/footer
# references, so the running header and the page-number footer survive into the output.
sect = re.search(r'<w:sectPr\b.*?</w:sectPr>', doc, re.S)
if not sect:
    sys.exit('the template has no sectPr')
body = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<w:body>' + sect.group(0) + '</w:body></w:document>')
out = zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED)
for item in z.infolist():
    if item.filename == 'word/document.xml':
        out.writestr(item, body)
    else:
        out.writestr(item, z.read(item.filename))
out.close()
print('   template body replaced, %d parts carried over' % len(z.namelist()))
PY
ok "reference document written"

echo "== 2. cover page, from the template's own fields =="
cat > "$TMP/cover.md" <<EOF
![]($(cd "$(dirname "$LOGO")" && pwd)/$(basename "$LOGO")){width=1.4in}

# StudyForge

## Design Document

**IT8108 Mobile Programming**

**Semester A, 2026-2027**

| | |
|---|---|
| **Group ID** | $GROUP_ID |
| **Section** | $SECTION |
| **Project Brief** | Project Brief 2, Intelligent Learning Platform |
| **Tutor** | Haetham Alhaddad (Coordinator) · Ghassan AlShajjar |
| **Submission Date** | 24 October 2026 |

**Team Members**

| Student ID | Student Name |
|---|---|
| 202300540 | Saleh Abdulla |
| 202401702 | Mohammed Almadhoon |
| 202305409 | Tasbeeh Saeed |
| 202305767 | Shahad Ashoor |
| 202304804 | Fatema Ghareeb |

\`\`\`{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
\`\`\`
EOF
ok "cover written (Group ID $GROUP_ID, $SECTION)"

echo "== 3. appendix A, one figure per page =="
APPEND=""
if [ "$APPENDIX" -eq 1 ]; then
  APPEND="$TMP/appendix.md"
  python3 - "$APPEND" <<'PY'
import os, re, sys

out = sys.argv[1]
dirs = ['deliverables/design-document/figures', 'deliverables/design-document/mockups/figures']


def natural(s):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s)]


rows = []
for d in dirs:
    if not os.path.isdir(d):
        continue
    for f in sorted(os.listdir(d), key=natural):
        if f.lower().endswith('.png'):
            rows.append(os.path.join(d, f))

parts = ['# Appendix A. Figure appendix', '',
         'Every exported figure, one per page: the document figures first, then the mockup exports, '
         'each group in filename order. The caption repeats the exact repository path, so any page '
         'here can be matched to the entry in the List of figures and to the file drawn in Figma.',
         '']
for i, src in enumerate(rows, start=1):
    title = re.sub(r'\s+', ' ', os.path.basename(src)[:-4].replace('_', ' ')).strip()
    parts.append('![](%s){width=6in}' % os.path.abspath(src))
    parts.append('')
    parts.append('**Figure A.%d** · %s' % (i, title))
    parts.append('')
    parts.append('`%s`' % src)
    parts.append('')
    parts.append('```{=openxml}\n<w:p><w:r><w:br w:type="page"/></w:r></w:p>\n```')
    parts.append('')
open(out, 'w', encoding='utf-8').write('\n'.join(parts))
print('   %d figures in the appendix' % len(rows))
PY
  ok "appendix written"
else
  warn "--text-only: no figure appendix"
fi

echo "== 4. render through pandoc =="
pandoc "$TMP/cover.md" "$SRC" ${APPEND:+"$APPEND"} \
  -o "$TMP/raw.docx" --reference-doc="$TMP/ref.docx" --resource-path=. --wrap=none \
  || die "pandoc failed"
ok "pandoc wrote $(du -h "$TMP/raw.docx" | cut -f1)"

echo "== 5. table style, then verify =="
python3 - "$TMP/raw.docx" "$OUT" "$GROUP_ID" "$SECTION" <<'PY'
import os, re, shutil, sys, zipfile

src, dst, gid, sec = sys.argv[1:5]
z = zipfile.ZipFile(src)
doc = z.read('word/document.xml').decode('utf-8')

# pandoc asks for a table style named "Table"; the template ships "TableGrid". Point every
# table at the style the template actually defines, or the tables print with no rules at all.
tables = doc.count('<w:tbl>')
doc = doc.replace('<w:tblStyle w:val="Table"/>', '<w:tblStyle w:val="TableGrid"/>')
doc = doc.replace('<w:tblStyle w:val="Table" />', '<w:tblStyle w:val="TableGrid"/>')

out = zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED)
for item in z.infolist():
    out.writestr(item, doc if item.filename == 'word/document.xml' else z.read(item.filename))
out.close()
z.close()

v = zipfile.ZipFile(dst)
d = v.read('word/document.xml').decode('utf-8')
media = [n for n in v.namelist() if n.startswith('word/media/')]
names = set(v.namelist())


def count(style):
    return len(re.findall(r'w:pStyle w:val="%s"' % style, d))


print('   tables                 : %d (TableGrid: %d)' % (tables, d.count('TableGrid')))
print('   headings 1/2/3         : %d / %d / %d' % (count('Heading1'), count('Heading2'), count('Heading3')))
print('   images in the package  : %d' % len(media))
print('   running header         : %s' % ('yes' if any(n.startswith('word/header') for n in names) else 'NO'))
print('   footer (page numbers)  : %s' % ('yes' if any(n.startswith('word/footer') for n in names) else 'NO'))
print('   size                   : %s' % ('%.1f MB' % (os.path.getsize(dst) / 1048576.0)))
print('   cover Group ID / Section: %s / %s' % (gid, sec))
bad = []
if count('Heading2') < 10:
    bad.append('too few Heading2 paragraphs: the body did not render')
if tables and 'TableGrid' not in d:
    bad.append('tables did not receive the template table style')
if 'word/header1.xml' not in names:
    bad.append('the template running header is missing')
if 'word/footer1.xml' not in names:
    bad.append('the template footer is missing')
if gid.startswith('[') or sec.startswith('['):
    print('   NOTE: Group ID and Section are still the template placeholders. Re-run with')
    print('         GROUP_ID=... SECTION=... bash tools/build-docx.sh before submitting.')
for b in bad:
    print('   FAIL %s' % b)
sys.exit(1 if bad else 0)
PY
ok "verified"

if [ "$CHECK" -eq 1 ]; then
  echo "== --check: compare with the committed file =="
  python3 - "$TMP/check.docx" "$DOC_DIR/StudyForge-Design-Document.docx" <<'PY'
import sys, zipfile

new, old = sys.argv[1], sys.argv[2]
try:
    a, b = zipfile.ZipFile(new), zipfile.ZipFile(old)
except FileNotFoundError:
    sys.exit('no committed .docx to compare with: %s' % old)
if a.read('word/document.xml') != b.read('word/document.xml'):
    sys.exit('FAIL the committed .docx differs from a fresh build. Re-run bash tools/build-docx.sh')
if sorted(n for n in a.namelist() if n.startswith('word/media/')) != \
        sorted(n for n in b.namelist() if n.startswith('word/media/')):
    sys.exit('FAIL the committed .docx carries different images from a fresh build')
print('  ok   the committed .docx matches a fresh build')
PY
else
  ok "written: $OUT"
fi

