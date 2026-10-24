#!/usr/bin/env bash
# build-bundle.sh — assemble the portal bundle and its zip from the sources, then prove
# that what it produced matches those sources byte for byte.
#
# WHY THIS EXISTS
#   deliverables/submission/ and deliverables/StudyForge-Submission.zip are tracked, so the
#   whole team sees the submission from a clone without a rebuild. That only helps while the
#   copy is current: a stale zip is worse than no zip, because it still looks like the
#   submission. This is the one command that rebuilds both, and its final step is a byte
#   comparison rather than a summary line, so a silent drift cannot pass.
#
# USAGE
#   bash tools/build-bundle.sh            # re-copy, re-zip, verify, print a summary
#   bash tools/build-bundle.sh --check    # verify only, change nothing
#
# The bundle's own README.md is deliberately NOT copied: it is written for the bundle and has
# no source counterpart, so it is the one file the comparison skips.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

DD="deliverables/design-document"
PR="deliverables/prototype"
S="deliverables/submission"
ZIP="deliverables/StudyForge-Submission.zip"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

if [ "$CHECK_ONLY" -eq 0 ]; then
  echo "── copying the sources into $S"
  mkdir -p "$S/01-Design-Document" "$S/02-Mockups" "$S/03-Prototype"
  cp "$DD/DESIGN-DOCUMENT.md" "$DD/StudyForge-Design-Document.pdf" "$S/01-Design-Document/"
  rm -rf "$S/01-Design-Document/figures"; cp -R "$DD/figures" "$S/01-Design-Document/figures"
  cp "$DD/mockups/SCREEN-DESCRIPTIONS.md" "$S/02-Mockups/"
  rm -rf "$S/02-Mockups/figures"; cp -R "$DD/mockups/figures" "$S/02-Mockups/figures"
  cp "$PR/StudyForge.fig" "$PR/figma-link.txt" "$S/03-Prototype/"
  rm -rf "$S/03-Prototype/dark-mode-proof"; cp -R "$PR/dark-mode-proof" "$S/03-Prototype/dark-mode-proof"

  echo "── zipping $ZIP"
  rm -f "$ZIP"
  ( cd "$S" && zip -r -q ../StudyForge-Submission.zip . -x '*.DS_Store' )
fi

echo "── verifying the zip against the sources"
TMP="$(mktemp -d)"; RC=0
if ! unzip -q -o "$ZIP" -d "$TMP" >/dev/null 2>&1; then
  echo "  FAIL  $ZIP does not extract"
  rm -rf "$TMP"; exit 1
fi

pair() { if cmp -s "$1" "$2"; then printf '  ok    %s\n' "$1"; else printf '  DIFF  %s\n' "$1"; RC=1; fi; }
dir()  {
  if diff -r -q --exclude='.DS_Store' "$1" "$2" >/dev/null 2>&1; then
    printf '  ok    %s/\n' "$1"
  else
    printf '  DIFF  %s/\n' "$1"
    diff -r -q --exclude='.DS_Store' "$1" "$2" 2>&1 | head -5
    RC=1
  fi
}

pair "$TMP/01-Design-Document/StudyForge-Design-Document.pdf" "$DD/StudyForge-Design-Document.pdf"
pair "$TMP/01-Design-Document/DESIGN-DOCUMENT.md"             "$DD/DESIGN-DOCUMENT.md"
pair "$TMP/02-Mockups/SCREEN-DESCRIPTIONS.md"                "$DD/mockups/SCREEN-DESCRIPTIONS.md"
pair "$TMP/03-Prototype/StudyForge.fig"                      "$PR/StudyForge.fig"
pair "$TMP/03-Prototype/figma-link.txt"                      "$PR/figma-link.txt"
dir  "$TMP/01-Design-Document/figures"                       "$DD/figures"
dir  "$TMP/02-Mockups/figures"                               "$DD/mockups/figures"
dir  "$TMP/03-Prototype/dark-mode-proof"                     "$PR/dark-mode-proof"
rm -rf "$TMP"

echo "── summary"
printf '  files in zip : %s\n' "$(unzip -l "$ZIP" | tail -1 | awk '{print $2}')"
printf '  zip bytes    : %s\n' "$(stat -f %z "$ZIP" 2>/dev/null || stat -c %s "$ZIP")"
printf '  integrity    : %s\n' "$(unzip -t "$ZIP" 2>&1 | tail -1)"
if [ "$RC" -eq 0 ]; then
  echo "  VERDICT: the bundle and the zip match the sources byte for byte"
else
  echo "  VERDICT: STALE — at least one file differs from its source (see DIFF above)"
fi
exit "$RC"
