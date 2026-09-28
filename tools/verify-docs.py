#!/usr/bin/env python3
"""Verify the StudyForge planning docs: links, frames, tiers, ownership integrity."""
import os, re, glob, collections

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(BASE)
FAIL = []

# ─────────────────────────────────────────────────────────── 1. internal links
bad = []
for f in glob.glob(BASE + "/**/*.md", recursive=True):
    d = os.path.dirname(f)
    for m in re.finditer(r"\]\(([^)]+)\)", open(f, encoding="utf-8").read()):
        link = m.group(1).split("#")[0]
        if link.startswith(("http", "mailto")) or not link:
            continue
        if not os.path.exists(os.path.normpath(os.path.join(d, link))):
            bad.append((os.path.relpath(f, BASE), link))
print("1. broken internal links :", bad if bad else "none")
if bad:
    FAIL.append("broken links")

# ─────────────────────────────────────────────────────────── 2. screen inventory
inv = open("docs/03-SCREEN-INVENTORY.md", encoding="utf-8").read()
rows = re.findall(r"^\| ([A-M]\d{2}) \| `(\d{2,3})_([^`]+)` \| ([^|]*)\| (P\d) \|", inv, re.M)
nums = sorted(int(n) for _, n, *_ in rows)
tiers = collections.Counter(r[4] for r in rows)
print("2. frames listed         :", len(rows))
contig = nums == list(range(1, len(nums) + 1))
print("   contiguous 1..N       :", contig, "(max %d)" % (nums[-1] if nums else 0))
dups = [n for n, c in collections.Counter(nums).items() if c > 1]
print("   duplicate numbers     :", dups or "none")
print("   tier split            :", dict(tiers))
m = re.search(r"\*\*Total\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\*", inv)
claimed = tuple(int(x) for x in m.groups()) if m else None
actual = (len(rows), tiers["P0"], tiers["P1"], tiers["P2"])
print("   summary table claims  :", claimed, "| actual:", actual, "->",
      "MATCH" if claimed == actual else "MISMATCH")
if claimed != actual:
    FAIL.append("tier totals mismatch")
if not contig:
    FAIL.append("frame numbering not contiguous")
if dups:
    FAIL.append("duplicate frame numbers")

# every frame must end in an owner handle {M1}..{M4}; {M5} must be gone
handles = [re.search(r"\{(M\d)\}$", r[2]) for r in rows]
badh = [(r[0], r[2]) for r, h in zip(rows, handles) if not h]
print("   frames without handle :", badh or "none")
if badh:
    FAIL.append("frame missing an owner handle")

own = collections.Counter(h.group(1) for h in handles if h)
print("   frames per owner      :", dict(sorted(own.items())), "| sum:", sum(own.values()))
if sum(own.values()) != len(rows):
    FAIL.append("per-owner frame sum mismatch")
if "M5" in own:
    FAIL.append("{M5} handle still present in frames")

# ─────────────────────────────────────────────────────────── 3. feature ownership
feat = open("docs/02-FEATURE-LIST-OWNERSHIP.md", encoding="utf-8").read()
# only the master feature table has Dev/Tester cells that are pure M-handles,
# which reliably excludes the sub-task table further down the document
master = re.findall(
    r"^\| \*\*(F\d{2})\*\* \|.*?\| \*{0,2}(M\d(?: \+ M\d)*)\*{0,2} \| \*{0,2}(M\d(?: \+ M\d)*)\*{0,2} \|\s*$",
    feat, re.M)
seen = [f for f, _, _ in master]
print("3. master-table rows     :", len(master))
dupf = [x for x, c in collections.Counter(seen).items() if c > 1]
print("   duplicate feature IDs :", dupf or "none")
expected = ["F%02d" % i for i in range(1, 16)]
print("   F01..F15 present      :", seen == expected)
if seen != expected:
    FAIL.append("feature IDs incomplete or reordered: %s" % seen)
if dupf:
    FAIL.append("duplicate feature IDs")

dev_counts, test_counts, clash = collections.Counter(), collections.Counter(), []
for fid, dev, tester in master:
    devs = [d.strip() for d in dev.replace("*", "").split("+") if d.strip()]
    tests = [t.strip() for t in tester.replace("*", "").split("+") if t.strip()]
    for d in devs:
        dev_counts[d] += 1
    for t in tests:
        test_counts[t] += 1
    if set(devs) & set(tests):
        clash.append((fid, devs, tests))
print("   features per developer:", dict(sorted(dev_counts.items())))
print("   features per tester   :", dict(sorted(test_counts.items())))
print("   dev==tester clashes   :", clash or "none")
under = {k: v for k, v in dev_counts.items() if v < 2}
print("   devs below min 2      :", under or "none  (rubric needs >=2 each)")
if clash:
    FAIL.append("a developer is also the tester of their own feature")
if under:
    FAIL.append("developer owns fewer than 2 features: %s" % under)

# ownership must agree between doc 02 (master table) and doc 03 (frame handles)
GROUP_OWNER = {"A": "M1", "B": "M1", "C": "M1", "D": "M2", "E": "M2", "F": "M2",
               "G": "M3", "I": "M4", "J": "M2", "K": "M4", "L": "M3", "M": "M1"}
# group H is the co-owned advanced feature: its frames are tagged {M2}
mismatch = []
for grp_id, h in zip([r[0] for r in rows], handles):
    if not h:
        continue
    want = GROUP_OWNER.get(grp_id[0])
    if want and h.group(1) != want:
        mismatch.append((grp_id, h.group(1), want))
print("   group/owner agreement :", "yes" if not mismatch else mismatch)
if mismatch:
    FAIL.append("frame owner disagrees with its group owner")

# ─────────────────────────────────────────────────────────── 4. stale references
stale_found = []
for f in ["README.md"] + sorted(glob.glob("docs/*.md")):
    for l in open(f, encoding="utf-8").read().splitlines():
        low = l.lower()
        # a mention of M5 is only acceptable if the same line frames it historically
        if "m5" in low and not any(k in low for k in (
                "former", "resolved", "redistribut", "distribut", "removed")):
            stale_found.append((f, l.strip()[:90]))
print("4. stale M5 references   :", stale_found if stale_found else "none")
if stale_found:
    FAIL.append("stale M5 reference")

print()
print("VERDICT:", "ALL CHECKS PASSED" if not FAIL else "FAILURES: %s" % FAIL)
raise SystemExit(1 if FAIL else 0)
