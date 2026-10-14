#!/usr/bin/env python3
"""Verify the StudyForge planning docs: links, frames, tiers, ownership integrity."""
import os, re, glob, collections

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(BASE)
FAIL = []

# ─────────────────────────────────────────────────────────── 1. internal links
# Only scan OUR markdown. Walking into node_modules or build output produces
# hundreds of false positives from third-party READMEs.
SKIP_DIRS = {".git", "node_modules", ".agents", ".claude", ".build",
             "DerivedData", "xcuserdata", ".firebase", "lib", "Pods"}


def our_markdown():
    for root, dirs, files in os.walk(BASE):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if name.endswith(".md"):
                yield os.path.join(root, name)


bad = []
for f in our_markdown():
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
rows = re.findall(r"^\| ([A-O]\d{2}) \| `(\d{2,3})_([^`]+)` \| ([^|]*)\| (P\d) \|", inv, re.M)
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

# every frame must end in an owner handle {M1}..{M5}. M5 is a real member since
# 14 Oct 2026 (Fatema Ghareeb), so the handle is expected, not forbidden.
handles = [re.search(r"\{(M\d)\}$", r[2]) for r in rows]
badh = [(r[0], r[2]) for r, h in zip(rows, handles) if not h]
print("   frames without handle :", badh or "none")
if badh:
    FAIL.append("frame missing an owner handle")

own = collections.Counter(h.group(1) for h in handles if h)
print("   frames per owner      :", dict(sorted(own.items())), "| sum:", sum(own.values()))
if sum(own.values()) != len(rows):
    FAIL.append("per-owner frame sum mismatch")
unknown_owner = sorted(set(own) - {"M1", "M2", "M3", "M4", "M5"})
print("   unknown owner handles :", unknown_owner or "none")
if unknown_owner:
    FAIL.append("unknown frame owner handle(s): %s" % unknown_owner)

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
expected = ["F%02d" % i for i in range(1, 18)]
print("   F01..F17 present      :", seen == expected)
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
               "G": "M3", "I": "M4", "J": "M2", "K": "M4", "L": "M3", "M": "M1",
               "N": "M5", "O": "M5"}
# group H is the co-owned advanced feature: its frames are tagged {M2}
# groups N and O are M5's two features, F16 (moderated group chat) and F17 (active recall space)
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

# ─────────────────────────────────────────────── 4. member roster sanity
# M5 is a real member since 14 Oct 2026 (Fatema Ghareeb, 202304804), so a mention of M5 is
# no longer stale in itself. What IS stale is a sentence that still asserts the fifth SEAT is
# empty or removed WITHOUT framing that historically — those sentences were true between
# 28 Sep and 14 Oct and must now read as history, not as the current state.
#
# The phrases are deliberately narrow. A bare "removed"/"deleted" is NOT evidence of a stale
# seat: F16 legitimately describes a moderator deleting a message, and F12 a suspended user.
STALE_M5 = ("has been removed", "was removed", "remove m5", "removed m5", "m5 is gone",
            "no m5", "without m5", "unfilled", "vacant", "fifth seat is empty",
            "seat is empty", "empty seat", "fifth member is absent")
FRAMED = ("former", "resolved", "redistribut", "distribut", "history", "histor",
          "14 oct", "joined", "filled", "brief's default", "brief's own default",
          "between 28 sep")
stale_found = []
for f in ["README.md"] + sorted(glob.glob("docs/*.md")):
    for l in open(f, encoding="utf-8").read().splitlines():
        low = l.lower()
        if "m5" in low and any(k in low for k in STALE_M5):
            if not any(k in low for k in FRAMED):
                stale_found.append((f, l.strip()[:90]))
print("4. stale M5 references   :", stale_found if stale_found else "none")
if stale_found:
    FAIL.append("stale M5 reference")

# the roster must actually name the fifth member, in doc 02 and in the README
roster = open("docs/02-FEATURE-LIST-OWNERSHIP.md", encoding="utf-8").read()
readme = open("README.md", encoding="utf-8").read()
missing_m5 = [n for n, t in (("docs/02", roster), ("README.md", readme))
              if "Fatema Ghareeb" not in t or "202304804" not in t]
print("   roster names M5       :", "yes" if not missing_m5 else "missing in %s" % missing_m5)
if missing_m5:
    FAIL.append("the fifth member is not named in the roster: %s" % missing_m5)

print()
print("VERDICT:", "ALL CHECKS PASSED" if not FAIL else "FAILURES: %s" % FAIL)
raise SystemExit(1 if FAIL else 0)
