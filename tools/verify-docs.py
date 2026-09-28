#!/usr/bin/env python3
"""Verify the StudyForge planning docs: links, frame counts, tier totals."""
import os, re, glob, collections

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(BASE)

# 1. internal markdown link check
bad = []
for f in glob.glob(BASE + "/**/*.md", recursive=True):
    d = os.path.dirname(f)
    for m in re.finditer(r"\]\(([^)]+)\)", open(f, encoding="utf-8").read()):
        link = m.group(1).split("#")[0]
        if link.startswith(("http", "mailto")) or not link:
            continue
        if not os.path.exists(os.path.normpath(os.path.join(d, link))):
            bad.append((os.path.relpath(f, BASE), link))
print("BROKEN LINKS:", bad if bad else "none")

# 2. count frames in the screen inventory
txt = open("docs/03-SCREEN-INVENTORY.md", encoding="utf-8").read()
rows = re.findall(r"^\| ([A-M]\d{2}) \| `(\d{2,3})_([^`]+)` \| ([^|]*)\| (P\d) \|", txt, re.M)
print("frames listed:", len(rows))
print("per group:", dict(sorted(collections.Counter(g[0] for g, *_ in rows).items())))
nums = sorted(int(n) for _, n, *_ in rows)
print("numbering contiguous 1..N:", nums == list(range(1, len(nums) + 1)), "| max:", nums[-1] if nums else 0)
dups = [n for n, c in collections.Counter(nums).items() if c > 1]
print("duplicate frame numbers:", dups or "none")

# 3. tier totals
print("tier counts:", dict(collections.Counter(r[4] for r in rows)))

# 4. claimed totals in the summary table
m = re.search(r"\*\*Total\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\*", txt)
print("summary table claims (frames/P0/P1/P2):", m.groups() if m else "not found")

# 5. features declared vs screens mapped
feat = open("docs/02-FEATURE-LIST-OWNERSHIP.md", encoding="utf-8").read()
ids = sorted(set(re.findall(r"\*\*(F\d{2})\*\*", feat)))
print("feature IDs found:", len(ids), ids)
