#!/usr/bin/env python3
"""Generate the §10.4 figure index table for DESIGN-DOCUMENT.md from the exported files."""
import glob
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(REPO, 'deliverables/design-document/DESIGN-DOCUMENT.md')
FIGS = os.path.join(REPO, 'deliverables/design-document/mockups/figures')

files = []
for f in os.listdir(FIGS):
    if not f.endswith('.png'):
        continue
    m = re.match(r'^LF_(\d{2,3})_(.+)\.png$', f)
    if not m or m.group(1) == '00':
        continue
    files.append((int(m.group(1)), f))
files.sort()

rows = ['| Figure | Screen | Wireframe file |', '|---|---|---|']
for k, (num, fn) in enumerate(files):
    fig = '10.%d' % (k + 2)
    rows.append('| %s | `%02d` | [%s](mockups/figures/%s) |' % (fig, num, fn, fn))
rows.append('')
rows.append('Two further exports are page furniture rather than figures and carry no number: '
            '`LF_00_PageHeader_StudyForge.png` (the header on the wireframe page) and '
            '`F00_FlowDiagrams_Header_StudyForge.png` (the header on the flow diagrams page).')
table = '\n'.join(rows)

doc = open(P, encoding='utf-8').read()
assert '<!-- FIGURE-INDEX -->' in doc, 'figure index placeholder not found'
doc = doc.replace('<!-- FIGURE-INDEX -->', table)
open(P, 'w', encoding='utf-8').write(doc)
print('figure index written: %d wireframe figures (10.2 to 10.%d)' % (len(files), len(files) + 1))
