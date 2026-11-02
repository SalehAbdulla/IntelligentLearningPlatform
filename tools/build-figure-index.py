#!/usr/bin/env python3
"""Generate the §10.4 figure index table for DESIGN-DOCUMENT.md from the exported files.

Idempotent: it rewrites the table in place, so re-run it after any re-export of the
wireframes. It does not touch the prose around the table.
"""
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
table = '\n'.join(rows)

doc = open(P, encoding='utf-8').read()
lines = doc.split('\n')
start = None
for i, ln in enumerate(lines):
    if ln.strip() == '| Figure | Screen | Wireframe file |':
        start = i
        break
assert start is not None, 'figure index table header not found'
end = start
while end + 1 < len(lines) and lines[end + 1].startswith('|'):
    end += 1
lines[start:end + 1] = table.split('\n')
open(P, 'w', encoding='utf-8').write('\n'.join(lines))
print('figure index written: %d wireframe figures (10.2 to 10.%d)' % (len(files), len(files) + 1))
