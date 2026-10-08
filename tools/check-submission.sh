#!/usr/bin/env bash
# check-submission.sh — the pre-submission gate for the two remaining deliverables.
#
# WHY THIS EXISTS
#   docs/TODOLIST.md is the single live list of what is left. A list is not a gate: it can
#   be read, nodded at, and submitted anyway. This script turns sections 4 (Design Document,
#   10%) and 5 (Figma Prototype, 10%) into a gate that exits non-zero while any item is
#   open, so "we will do it at the end" becomes visible now.
#
# WHAT IT CHECKS, per item
#   1. The TODOLIST box is ticked.
#   2. The evidence the item claims actually exists. Ticking a box is NOT enough: an item
#      whose box is ticked but whose artefact is missing still fails.
#   3. Any section 4 or 5 item with no registered check is reported as UNMAPPED and fails,
#      so a newly added item can never be silently skipped.
#
# ITEM KINDS
#   machine  evidence lives in the repository and is checked directly
#   audit    evidence is a recorded measurement in deliverables/prototype/figma-audit.md,
#            because a shell script cannot read the Figma document
#   human    needs a person (an interview, a real participant test, a portal upload); it
#            blocks the gate until it is done, and the script says so explicitly
#
# USAGE
#   bash tools/check-submission.sh            # full gate
#   bash tools/check-submission.sh --quiet    # only failures and the summary
#
# Exit 0 = every section 4 and 5 item is cleared with evidence. Exit 1 = not ready to submit.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

DOC="deliverables/design-document/DESIGN-DOCUMENT.md"
MOCK="deliverables/design-document/mockups/SCREEN-DESCRIPTIONS.md"
FIGS="deliverables/design-document/mockups/figures"
DFIGS="deliverables/design-document/figures"
AUDIT="deliverables/prototype/figma-audit.md"
LINK="deliverables/prototype/figma-link.txt"
TODOS="docs/TODOLIST.md"

BOLD=$(printf '\033[1m'); RED=$(printf '\033[31m'); GRN=$(printf '\033[32m')
YLW=$(printf '\033[33m'); DIM=$(printf '\033[2m'); OFF=$(printf '\033[0m')

PASSN=0; FAILN=0; HUMAN=0

hdr()  { printf '\n%s%s%s\n' "$BOLD" "$1" "$OFF"; }
good() { PASSN=$((PASSN + 1)); [ "$QUIET" = 1 ] || printf '  %sPASS%s  %-24s %s\n' "$GRN" "$OFF" "$1" "$2"; }
bad()  { FAILN=$((FAILN + 1)); printf '  %sOPEN%s  %-24s %s\n' "$RED" "$OFF" "$1" "$2"; }
hum()  { HUMAN=$((HUMAN + 1)); FAILN=$((FAILN + 1)); printf '  %sHUMAN%s %-24s %s\n' "$YLW" "$OFF" "$1" "$2"; }
note() { [ "$QUIET" = 1 ] || printf '        %s%s%s\n' "$DIM" "$1" "$OFF"; }

# ── the TODOLIST line for an item, and whether its box is ticked ───────────────
tick_state() { # $1 = fragment to match in sections 4 and 5 ; echoes ticked / open / missing
  local frag="$1" found
  found=$(awk '/^## 4\./,/^## 6\./' "$TODOS" | grep -E '^- \[[ x]\]' | grep -F -- "$frag" | head -1)
  [ -z "$found" ] && { echo missing; return; }
  case "$found" in
    *'- [x]'*) echo ticked ;;
    *) echo open ;;
  esac
}

# ── predicates ────────────────────────────────────────────────────────────────
# Each prints its own reasons and returns 0 (evidence present) or 1 (evidence missing).

pred_interview() {
  if grep -q 'to be recorded' "$DOC"; then
    note "DESIGN-DOCUMENT section 3.1 still says the interview date is 'to be recorded'"
    note "sections 3.2 and 3.3 need the tutor's answers and what changed as a result"
    return 1
  fi
  return 0
}

pred_f15_approval() {
  if grep -q 'Status: \*\*pending\*\*' "$DOC"; then
    note "section 3.4 still records the F15 written approval as pending"
    return 1
  fi
  return 0
}

pred_usability() {
  if grep -qE 'SUS score of|SUS: [0-9]|System Usability Scale score of' "$DOC"; then return 0; fi
  note "no participant table and no SUS score recorded in section 17.3"
  return 1
}

pred_appendix_a() {
  local n
  n=$(ls -1 "$FIGS"/LF_*.png 2>/dev/null | grep -v 'LF_00_PageHeader' | wc -l | tr -d ' ')
  [ -f "$MOCK" ] || { note "$MOCK is missing"; return 1; }
  [ "${n:-0}" -ge 106 ] || { note "only ${n:-0} wireframe exports in $FIGS"; return 1; }
  note "$MOCK plus ${n} exported wireframes"
  return 0
}

pred_figures() {
  local rc=0 min
  grep -q '^## List of figures' "$DOC" || { note "no List of figures in the document"; rc=1; }
  grep -q '^## List of tables'  "$DOC" || { note "no List of tables in the document"; rc=1; }
  min=$(python3 -c "
import glob, os, struct, sys
w = 10**9
f = glob.glob('$FIGS/*.png') + glob.glob('$DFIGS/*.png')
for p in f:
    with open(p,'rb') as fh:
        w = min(w, struct.unpack('>I', fh.read(24)[16:20])[0])
print(w if f else 0)
")
  if [ "${min:-0}" -lt 1500 ]; then
    note "smallest exported figure is ${min}px wide, which is below the 150 dpi floor here"
    rc=1
  else
    note "smallest exported figure is ${min}px wide, so every figure clears 150 dpi"
  fi
  if [ ! -f deliverables/design-document/StudyForge-Design-Document.pdf ]; then
    note "the PDF export is missing: deliverables/design-document/StudyForge-Design-Document.pdf"
    note "this machine has no PDF toolchain, so the PDF is a human step"
    rc=1
  fi
  return $rc
}

pred_dossier() {
  [ -s research/dossier.md ] || { note "research/dossier.md is missing or empty"; return 1; }
  return 0
}

pred_market() {
  local open
  open=$(grep -c '⬜ to verify' research/dossier.md 2>/dev/null | tr -d ' ')
  if [ "${open:-1}" -gt 0 ]; then
    note "research/dossier.md section 2.1 still lists ${open} market figures as unverified"
    note "each row names the primary source to check; an unverifiable figure must be removed"
    return 1
  fi
  return 0
}

pred_count() {
  grep -q '106 designed screens' "$DOC" && return 0
  grep -q '106 frames' "$DOC" && return 0
  note "the 106-screen count is not stated in the document"
  return 1
}

pred_audit() { # $1 = audit line prefix, eg P9-06
  [ -f "$AUDIT" ] || { note "$AUDIT is missing"; return 1; }
  if grep -q "^$1 .*: PASS" "$AUDIT"; then return 0; fi
  note "no PASS line for $1 in $AUDIT (re-run the audit after any Figma change)"
  return 1
}

pred_second_reader() {
  [ -f deliverables/prototype/figma-content-audit.md ] && return 0
  note "no second-reader content audit: P9-09 and P9-10 need a reader who did not draw the screen"
  note "record it as deliverables/prototype/figma-content-audit.md"
  return 1
}

pred_fig_file() {
  if [ -s deliverables/prototype/StudyForge.fig ]; then
    note "StudyForge.fig present, $(wc -c < deliverables/prototype/StudyForge.fig | tr -d ' ') bytes (gitignored, so it is not in a clean clone)"
    return 0
  fi
  note "deliverables/prototype/StudyForge.fig is missing: re-export it from Figma"
  return 1
}

pred_figma_link() {
  [ -s "$LINK" ] || { note "$LINK is missing"; return 1; }
  grep -q 'https://www.figma.com/design/' "$LINK" || { note "no shared design URL in $LINK"; return 1; }
  return 0
}

pred_tag() {
  git tag --list 'prototype-v1' | grep -q 'prototype-v1' && return 0
  note "the prototype-v1 tag does not exist yet, and the portal submission is still to do"
  return 1
}

pred_share() {
  grep -q '\[x\] Figma -> Share' "$LINK" && return 0
  note "$LINK section 9 still has the Share toggle unchecked. A human must set"
  note "Share -> Anyone with the link -> Can view, then open it in a private browser window"
  return 1
}

pred_mockups() {
  local n
  n=$(ls -1 "$FIGS"/LF_*.png 2>/dev/null | grep -v 'LF_00_PageHeader' | wc -l | tr -d ' ')
  [ "${n:-0}" -ge 106 ] || { note "only ${n:-0} of 106 wireframes exported"; return 1; }
  return 0
}

pred_flows() {
  local n
  n=$(ls -1 "$FIGS"/FLOW_F*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "${n:-0}" -ge 15 ] || { note "only ${n:-0} of 15 flow diagrams exported"; return 1; }
  return 0
}

pred_coverage() {
  grep -q '88' "$MOCK" || { note "no F09 group-space screens in $MOCK"; return 1; }
  grep -q '57' "$MOCK" || { note "the quiz submit-confirm screen is missing from $MOCK"; return 1; }
  return 0
}

pred_p906() { pred_audit P9-06; }
pred_p907() { pred_audit P9-07; }
pred_p908() { pred_audit P9-08; }
pred_p911() { pred_audit P9-11; }
pred_p912() { pred_audit P9-12; }

# ── the registry: every section 4 and 5 item, and what proves it ──────────────
# key | TODOLIST fragment | kind | predicate | description
REGISTRY="
dd-interview|tutor-interview responses|human|pred_interview|Doc 3.2/3.3 tutor interview responses
dd-interview-date|interview date is|human|pred_interview|Doc 3.1 interview date recorded
dd-f15-approval|written approval for F15|human|pred_f15_approval|Doc 3.4 F15 written approval
dd-usability|usability test with 5 users|human|pred_usability|Doc 17.3 usability test and SUS score
dd-appendix-a|Appendix A, the labelled screen descriptions|machine|pred_appendix_a|Appendix A screen descriptions and mockups
dd-figures|PDF export with embedded fonts|machine|pred_figures|Figures at 150 dpi, figure list, table list, PDF
dd-dossier|research/dossier.md|machine|pred_dossier|research/dossier.md exists
dd-market|Re-verify the section 2 market figures|human|pred_market|Section 2 market figures verified
dd-count|Reconcile the section 1 claim|machine|pred_count|106-screen count reconciled in section 1
p9-0304|P9-03/04|human|pred_usability|P9-03/04 usability test and SUS score
p9-06|P9-06|audit|pred_p906|P9-06 frame-naming audit
p9-07|P9-07|audit|pred_p907|P9-07 hotspot and link audit
p9-08|P9-08|audit|pred_p908|P9-08 overflow audit
p9-0910|P9-09/10|human|pred_second_reader|P9-09/10 content and consistency audits
p9-11|P9-11|audit|pred_p911|P9-11 accessibility and RTL frames
p9-12|P9-12|audit|pred_p912|P9-12 dark-mode frame variants
p9-14|P9-14|machine|pred_fig_file|P9-14 StudyForge.fig exported
p9-17|P9-17|machine|pred_figma_link|P9-17 figma-link.txt assembled
p9-1819|P9-18/19|human|pred_tag|P9-18/19 submit and tag prototype-v1
p9-share|Human only:|human|pred_share|Figma link permission set to Can view
new-mockups|Phase 1 mockups|machine|pred_mockups|106 low-fidelity wireframes exported
new-flows|15 per-feature flow diagrams|machine|pred_flows|15 per-feature flow diagrams exported
new-holes|closed two coverage holes|machine|pred_coverage|F09 screens and 57 present in the mockups
"



# ── run every registered item ────────────────────────────────────────────────
run_item() {
  local key="$1" frag="$2" kind="$3" pred="$4" desc="$5"
  local state out ev
  state=$(tick_state "$frag")
  out=$($pred 2>&1); ev=$?
  if [ "$state" = missing ]; then
    bad "$key" "no TODOLIST item in sections 4 or 5 matches '$frag'"
  elif [ "$state" = open ]; then
    if [ "$kind" = human ]; then hum "$key" "$desc"; else bad "$key" "$desc"; fi
  elif [ "$ev" -ne 0 ]; then
    bad "$key" "$desc (box ticked, evidence missing)"
  else
    good "$key" "$desc"
  fi
  if [ -n "$out" ]; then
    printf '%s\n' "$out" | while IFS= read -r l; do note "$l"; done
  fi
}

hdr "Deliverable gate: docs/TODOLIST.md sections 4 (Design Document) and 5 (Prototype)"
if [ -f "$AUDIT" ]; then
  note "Figma audit on record: $(grep -m1 'Audit date' "$AUDIT" | sed 's/[*`]//g')"
fi

while IFS= read -r row; do
  [ -z "$row" ] && continue
  key=${row%%|*}; rest=${row#*|}
  frag=${rest%%|*}; rest=${rest#*|}
  kind=${rest%%|*}; rest=${rest#*|}
  pred=${rest%%|*}; desc=${rest#*|}
  run_item "$key" "$frag" "$kind" "$pred" "$desc"
done <<EOF
$REGISTRY
EOF

# ── every section 4 and 5 item must be covered by the registry ────────────────
hdr "Coverage of the TODOLIST items themselves"
UNMAPPED=0
while IFS= read -r item; do
  [ -z "$item" ] && continue
  hit=0
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    frag=${row#*|}; frag=${frag%%|*}
    case "$item" in *"$frag"*) hit=1 ;; esac
  done <<EOF2
$REGISTRY
EOF2
  if [ "$hit" -eq 0 ]; then
    UNMAPPED=$((UNMAPPED + 1))
    bad "unmapped" "$(printf '%s' "$item" | cut -c1-72)"
  fi
done <<EOF3
$(awk '/^## 4\./,/^## 6\./' "$TODOS" | grep -E '^- \[[ x]\]')
EOF3
[ "$UNMAPPED" -eq 0 ] && good "unmapped" "every section 4 and 5 item has a registered check"

# ── the repository checks that must pass after any change ─────────────────────
hdr "Repository checks"
if python3 tools/verify-docs.py | grep -q 'ALL CHECKS PASSED'; then
  good "verify-docs" "python3 tools/verify-docs.py"
else
  bad "verify-docs" "python3 tools/verify-docs.py did not print ALL CHECKS PASSED"
fi
if python3 tools/check-strings.py | grep -q 'ALL CHECKS PASSED'; then
  good "check-strings" "python3 tools/check-strings.py"
else
  bad "check-strings" "python3 tools/check-strings.py did not print ALL CHECKS PASSED"
fi

# ── verdict ───────────────────────────────────────────────────────────────────
hdr "Verdict"
printf '  cleared %d of %d checked items, %s%d open%s, %sof which human-only: %d%s\n' \
  "$PASSN" "$((PASSN + FAILN))" "$RED" "$FAILN" "$OFF" "$YLW" "$HUMAN" "$OFF"
if [ "$FAILN" -eq 0 ]; then
  printf '\n%sALL SUBMISSION CHECKS PASSED%s\n' "$GRN" "$OFF"
  exit 0
fi
printf '\n%sNOT READY TO SUBMIT: %d item(s) still open.%s\n' "$RED" "$FAILN" "$OFF"
printf 'Tick an item in docs/TODOLIST.md only when its evidence exists: this script re-checks\n'
printf 'the evidence, so an empty tick still fails.\n'
exit 1

