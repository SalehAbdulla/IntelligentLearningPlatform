#!/usr/bin/env bash
# check-release.sh — fails when `main` has drifted so far from `develop` that it is no longer a
# usable demo line.
#
# ── WHY THIS EXISTS ──────────────────────────────────────────────────────────
#   On 15 Oct 2026 a reader looking at README.md **on `main`** reported that the fifth member was
#   missing from the roster. She was not missing. **`main` had silently fallen 233 commits behind
#   `develop`** and was showing a version of the file from before she joined.
#
#   What `main` was actually missing:
#     · 645 lines of the Design Document, against develop's 1095
#     · `research/testing/`, `research/usability/`, `research/reviews/`,
#       `research/meeting-notes/` and `research/demo/` — **entirely absent**
#     · the F15 written approval
#
#   docs/12 section 3 defines `main` as "Stable, always builds and runs. This is the demo/release
#   line." It had not been a demo line for **30 releases**, because **nothing checked it**.
#
#   Fixing it once was a two-minute pull request. This script is so it cannot recur silently.
#
# ── WHAT IT CHECKS ───────────────────────────────────────────────────────────
#   1. STRUCTURAL DRIFT — a hard failure. A directory that exists on `develop` with several files
#      and has NO files at all on `main`. This is the serious kind of drift: it is how a demo line
#      ends up missing whole evidence folders, and a commit count cannot see it.
#   2. COMMIT DISTANCE — a warning past a threshold, never a failure on its own. `main` falls
#      behind by exactly the number of commits made after it, which is NORMAL between releases.
#   3. KEY-FILE DIVERGENCE — informational. The Design Document, the README and the TODOLIST,
#      compared by line count, because those are the files a reader actually opens.
#
# ── WHY A COMMIT THRESHOLD ALONE WOULD BE THE WRONG CHECK ────────────────────
#   This project made **301 commits in a single day**. A count-based gate with a small threshold
#   would fire every afternoon and be ignored within a week — a check that cries wolf is worse
#   than no check, because it trains people to skip the output. The condition that actually broke
#   `main` was **structural**, so that is the failure and the count is only a warning.
#
# ── WHAT IT DOES NOT CHECK ───────────────────────────────────────────────────
#   Whether `main` builds. A release can be structurally complete and still not compile; that is
#   what the build health check in docs/11 section 8 is for.
#
# ── READS LOCAL REFS, DOES NOT FETCH ─────────────────────────────────────────
#   A check must not hit the network or mutate the clone. It reads `origin/main` and
#   `origin/develop` as they are, and **fails closed** if either is unknown, so a stale clone
#   reports "unknown" rather than silently passing.
#
# USAGE
#   bash tools/check-release.sh                          # check
#   RELEASE_MAX_DRIFT=200 bash tools/check-release.sh    # raise the warning threshold (default 100)
#   RELEASE_MIN_DIR_FILES=5 bash tools/check-release.sh  # raise the "whole directory" bar (default 3)
#
# See docs/12-GIT-WORKFLOW.md section 3 and docs/TODOLIST.md section 0.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

MAIN="${RELEASE_MAIN:-origin/main}"
DEV="${RELEASE_DEV:-origin/develop}"
MAX_DRIFT="${RELEASE_MAX_DRIFT:-100}"
MIN_DIR_FILES="${RELEASE_MIN_DIR_FILES:-3}"

for ref in "$MAIN" "$DEV"; do
  if ! git rev-parse --verify --quiet "$ref" >/dev/null; then
    echo "check-release: FAIL — $ref is unknown in this clone."
    echo "check-release: a release check that cannot see its refs must not pass."
    echo "check-release: run 'git fetch origin', then re-run."
    exit 1
  fi
done

behind=$(git rev-list --count "$MAIN..$DEV")
ahead=$(git rev-list --count "$DEV..$MAIN")
status=0

# ── 1. structural drift: a whole directory present on develop, absent on main ─────────────────
dirs_of() { git ls-tree -r --name-only "$1" | awk -F/ 'NF>1 {print $1"/"$2}' | sort -u; }
wholly_missing=$(comm -13 <(dirs_of "$MAIN") <(dirs_of "$DEV"))

drifted_dirs=""
while IFS= read -r d; do
  [ -z "$d" ] && continue
  n=$(git ls-tree -r --name-only "$DEV" -- "$d" | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge "$MIN_DIR_FILES" ]; then
    drifted_dirs="${drifted_dirs}${d} (${n} files)${NL:-$'\n'}"
  fi
done <<EOF
$wholly_missing
EOF

if [ -n "$drifted_dirs" ]; then
  echo "check-release: FAIL — whole directories exist on $DEV and are absent from $MAIN:"
  printf '%s' "$drifted_dirs" | while IFS= read -r l; do [ -n "$l" ] && echo "  · $l"; done
  echo "  This is the drift that made main unusable on 15 Oct 2026."
  status=1
fi

# ── 2. commit distance ───────────────────────────────────────────────────────────────────────
echo "check-release: $MAIN is ${behind} commit(s) behind $DEV, and ${ahead} ahead (previous releases)"
if [ "$behind" -gt "$MAX_DRIFT" ]; then
  echo "check-release: WARNING — that exceeds RELEASE_MAX_DRIFT=${MAX_DRIFT}."
  echo "check-release: main is the demo line (docs/12 section 3). Release it:"
  echo "check-release:   gh pr create --base main --head develop --title \"release(sprint-N): merge develop into main\""
fi

# ── 3. key-file divergence, informational ────────────────────────────────────────────────────
echo "check-release: key files, lines on $MAIN vs $DEV"
for f in deliverables/design-document/DESIGN-DOCUMENT.md README.md docs/TODOLIST.md; do
  m=$(git show "$MAIN:$f" 2>/dev/null | wc -l | tr -d ' ')
  d=$(git show "$DEV:$f" 2>/dev/null | wc -l | tr -d ' ')
  printf 'check-release:   %-52s %5s vs %5s\n' "$f" "${m:-absent}" "${d:-absent}"
done

main_date=$(git log -1 --format=%cs "$MAIN")
echo "check-release: $MAIN last moved on ${main_date}"

# ── verdict ─────────────────────────────────────────────────────────────────────────────────
if [ "$status" -ne 0 ]; then
  echo
  echo "check-release: FAIL — release main, then re-run:  bash tools/check-release.sh"
  exit 1
fi

echo "check-release: OK — no structural drift; $MAIN carries every directory that $DEV does"
