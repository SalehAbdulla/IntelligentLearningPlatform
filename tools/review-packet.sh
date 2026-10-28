#!/usr/bin/env bash
# review-packet.sh — everything a reviewer needs, on one screen.
#
# WHY THIS EXISTS
#   The Sprints mark is 10% and assessed per person, and `develop` requires one approving review
#   before anything merges — so a review is simultaneously the project's bottleneck and a member's
#   cheapest legitimate piece of evidence. The blocker is not reluctance, it is that a 36-commit,
#   2,897-line pull request looks like an afternoon.
#
#   It is not an afternoon. It is three questions and a diff. This prints the three questions, the
#   files where the risk actually is, the tests that are the proof, and the exact commands — so a
#   review takes about ten minutes instead of being deferred.
#
# USAGE
#   bash tools/review-packet.sh            # list the open pull requests
#   bash tools/review-packet.sh 135        # the packet for one of them
#
# WHAT IT IS NOT
#   It is not a review. An approval produced by this output and not by reading the diff is worse
#   than no approval — it is the one thing on this project that cannot be undone. This tool removes
#   the excuse, not the work.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

PR="${1:-}"

if [[ -z "$PR" ]]; then
  printf '\n  review-packet.sh — the open pull requests\n\n'
  gh pr list --state open \
    --json number,title,mergeable,reviewDecision,author \
    --template '{{range .}}  #{{.number}}  {{.mergeable}}  {{.reviewDecision}}  by {{.author.login}}
      {{.title}}
{{end}}'
  printf '  Run: bash tools/review-packet.sh <number>\n\n'
  exit 0
fi

hdr() { printf '\n\033[36m%s\033[0m\n' "$1"; }

printf '\n\033[36m════════════════════════════════════════════════════════════════════\033[0m\n'
printf '\033[36m  review packet — PR #%s\033[0m\n' "$PR"
printf '\033[36m════════════════════════════════════════════════════════════════════\033[0m\n'

# ── the shape of it ──────────────────────────────────────────────────────
gh pr view "$PR" --json title,headRefName,commits,files,additions,deletions,mergeable,reviewDecision \
  --jq '"  \(.title)\n\n  branch      \(.headRefName)\n  size        \(.commits | length) commits · \(.files | length) files · +\(.additions) / -\(.deletions)\n  state       \(.mergeable) against develop · \(.reviewDecision)"' 2>/dev/null \
  || { printf '  could not read PR #%s — is the number right, and are you online?\n\n' "$PR"; exit 1; }

printf '  CI          '
gh pr checks "$PR" --json name,bucket \
  --jq '[.[] | (if .bucket == "pass" then "✓" elif .bucket == "fail" then "✗" else "…" end) + " " + .name] | unique | join("   ")' 2>/dev/null \
  || printf '(no checks reported — on Windows this is your build machine, so that matters)'

# ── what it claims ───────────────────────────────────────────────────────
hdr '  WHAT IT CLAIMS  (read this first — it is the thing you are checking)'
gh pr view "$PR" --json body --jq '.body' 2>/dev/null \
  | sed '/^[[:space:]]*$/d' | head -4 \
  | awk '{ print "  " (length($0) > 150 ? substr($0, 1, 149) "…" : $0) }'

# ── where the risk is ────────────────────────────────────────────────────
hdr '  THE BIGGEST FILES  (where the risk is, so read these)'
gh pr view "$PR" --json files \
  --jq '.files | sort_by(-.additions) | .[0:8][] | "  \(.additions) added  \(.path)"' 2>/dev/null

# ── where the proof is ───────────────────────────────────────────────────
hdr '  THE TESTS  (the proof — if there are none, that is the finding)'
TESTS="$(gh pr view "$PR" --json files --jq '.files[].path' 2>/dev/null | grep -iE 'Test' || true)"
if [[ -n "$TESTS" ]]; then
  printf '%s\n' "$TESTS" | sed 's/^/  /'
elif gh pr view "$PR" --json files --jq '.files[].path' 2>/dev/null \
     | grep -qvE '^(docs/|research/|deliverables/|tools/|\.github/)'; then
  # It touches real code and brings no test with it. That is the finding, and it is worth saying
  # out loud rather than leaving the reviewer to notice the section is empty.
  printf '  NONE. Ask what would fail if this behaviour broke.\n'
else
  printf '  NONE — and none expected: this pull request changes no app code.\n'
fi

# ── the three questions ──────────────────────────────────────────────────
hdr '  THE THREE QUESTIONS  (answer these and you have reviewed it)'
cat <<'QUESTIONS'
  1. Does it do what the title says — no more, and no less?
  2. Is there a test that would FAIL if the behaviour broke? (Not "are there tests" — would
     one actually fail.)
  3. Would you be comfortable standing in front of a marker and demoing this screen?
QUESTIONS

# ── how to do it ─────────────────────────────────────────────────────────
hdr '  HOW TO LOOK AT IT'
cat <<HOWTO
  gh pr diff $PR                       # the whole diff, in the terminal
  gh pr checkout $PR                   # to run it locally (macOS)
  # On Windows: CI is your build machine. Read the run above instead — that is what it is for.
  gh pr review $PR --approve --body "Reviewed. Checked: ..."
  gh pr review $PR --comment --body "file.swift:120 — <what is wrong>"

  One approval is what merges this. If you find something, --comment still counts as work and is
  more useful than an approval nobody meant.
HOWTO

printf '\n'
