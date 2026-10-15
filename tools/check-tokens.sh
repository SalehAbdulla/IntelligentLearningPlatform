#!/usr/bin/env bash
# Fails if the documented design tokens and the SwiftUI token source diverge.
#
# ── WHAT THIS CHECKS, PRECISELY ───────────────────────────────────────────────
#   The COLOUR tokens named in docs/06-DESIGN-SYSTEM.md section 1.1 (the light and
#   dark tables) against the top-level `static let` names in
#   DesignSystem/ColorTokens.swift. A token present in one and missing from the other
#   fails the check, in EITHER direction — an undocumented token is drift just as much
#   as a documented one that does not exist.
#
#   Colour is the one group where a name-grep is a valid check, because the names are
#   contractual: ColorTokens.swift's own header says "Figma variables mirror these
#   names exactly", and they do.
#
# ── WHAT THIS DOES NOT CHECK, AND WHY ────────────────────────────────────────
#   1. THE OTHER TOKEN GROUPS. Type, spacing, radius, elevation and motion use a
#      DIFFERENT naming convention on each side, deliberately: Figma carries the
#      grouped Figma name (`Space/4`, `Radius/M`, `Type/body`) and Swift carries the
#      Swift name (`s4`, `m`, `sfBody`). A name-grep across them would compare
#      `space4` against `s4` and fail on every row — it would be a check that can
#      never pass, which is not a check. Their parity is verified at each freeze by
#      comparing counts and values against the tables in docs/06 section 1.2 to 1.4.
#   2. THE FIGMA VARIABLES THEMSELVES. They live in Figma, not in this repository:
#      no script can read them without the Figma API and a token. The Figma side is
#      checked by hand at each freeze, against the list this script prints.
#
#   Both limitations are stated here rather than implied away. An earlier version of
#   this file claimed the build failed on divergence while doing nothing at all, and
#   that is the failure mode this comment exists to prevent.
#
# ── WHY IT FAILS CLOSED ──────────────────────────────────────────────────────
#   If it cannot find either source, it exits non-zero rather than passing. A parity
#   check that silently succeeds when it cannot read its inputs is worse than none.
#
# See docs/06-DESIGN-SYSTEM.md section 6 and docs/09-RISKS-OPEN-QUESTIONS.md R10.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="$ROOT/docs/06-DESIGN-SYSTEM.md"
CODE="$ROOT/ios/StudyForge/StudyForge/DesignSystem/ColorTokens.swift"

for f in "$DOC" "$CODE"; do
  if [ ! -f "$f" ]; then
    echo "check-tokens: FAIL — cannot read ${f#"$ROOT"/}"
    echo "check-tokens: a parity check that cannot read its inputs must not pass"
    exit 1
  fi
done

# ── Documented tokens ────────────────────────────────────────────────────────
# Scoped to section 1.1 (Colour), because that is the group whose names are identical
# on both sides. Table rows of the form:  | `tokenName` | `#RRGGBB` | …
# The light and dark tables repeat names; `sort -u` collapses them.
documented=$(awk '/^### 1\.1 Colour/,/^### 1\.2 Typography/' "$DOC" \
  | grep -oE '^\| `[A-Za-z][A-Za-z0-9]*`' \
  | sed 's/^| `//; s/`$//' \
  | sort -u)

# ── Code tokens ──────────────────────────────────────────────────────────────
# Top-level `static let` inside `enum ColorTokens`, skipping the nested
# `enum Subject` palette, which is a separate documented group rather than a
# top-level token.
coded=$(awk '
  /enum Subject[[:space:]]*\{/ { skip = 1; next }
  skip && /^[[:space:]]{4}\}/    { skip = 0; next }
  skip                           { next }
  match($0, /static let [A-Za-z][A-Za-z0-9]*/) {
    print substr($0, RSTART + 11, RLENGTH - 11)
  }
' "$CODE" | sort -u)

if [ -z "$documented" ]; then
  echo "check-tokens: FAIL — no token table found in docs/06-DESIGN-SYSTEM.md"
  echo "check-tokens: expected rows of the form  | \`tokenName\` | \`#RRGGBB\` | …"
  exit 1
fi

if [ -z "$coded" ]; then
  echo "check-tokens: FAIL — no top-level tokens found in ColorTokens.swift"
  exit 1
fi

# ── Compare, both directions ─────────────────────────────────────────────────
undocumented=$(comm -13 <(echo "$documented") <(echo "$coded"))
missing=$(comm -23 <(echo "$documented") <(echo "$coded"))

status=0

if [ -n "$undocumented" ]; then
  echo "check-tokens: FAIL — in ColorTokens.swift but not documented in docs/06:"
  echo "$undocumented" | sed 's/^/  · /'
  status=1
fi

if [ -n "$missing" ]; then
  echo "check-tokens: FAIL — documented in docs/06 but not in ColorTokens.swift:"
  echo "$missing" | sed 's/^/  · /'
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo
  echo "A token changes in both places in the same commit, or it does not change."
  echo "Fix the divergence above, then re-run:  bash tools/check-tokens.sh"
  exit 1
fi

n=$(echo "$coded" | wc -l | tr -d ' ')
echo "check-tokens: OK — ${n} colour tokens agree between docs/06 and ColorTokens.swift"
echo "check-tokens: note — the Figma variables are NOT covered by this check (see the header)"
