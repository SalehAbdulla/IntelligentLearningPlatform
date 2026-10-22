#!/usr/bin/env bash
# check-commits.sh — the log-level rules, checked where they cannot be skipped.
#
# WHY THIS EXISTS
#   `tools/commit.sh` refuses a bad message and `tools/check-lane.sh` refuses a foreign file,
#   but both are LOCAL tools, run by someone who is already trying to comply. A member who
#   types `git commit -m "view"` instead of using the tool, and who never opens a pull request,
#   is contradicted by nothing at all. That is not hypothetical: `feat/F03-AI-SUMMARY` carried
#   five subjects that are not Conventional Commits (`view`, `configure view`, `edit sheet`,
#   `quate view`, `source sheet`), was authored under a personal address, and had **no pull
#   request** — so no check in this repository ever looked at it. docs/12 §3.1 states the
#   principle: a rule that can be silently bypassed is not a rule. This script is the
#   server-side half of that pair; `.github/workflows/ios.yml` runs it on every push and PR.
#
# WHAT IT CHECKS — per commit in the range, merge commits skipped
#   1. IDENTITY  the author address resolves, through `.mailmap`, to a team address. An address
#                that resolves to nothing is invisible to `git shortlog`, and the individual
#                sprint mark is read off that — so this protects the member's own mark, not
#                just the repository's tidiness.
#   2. MESSAGE   Conventional Commits, using the SAME pattern `tools/commit.sh` enforces. The
#                pattern is read out of that file rather than copied, so the two cannot drift.
#   3. LANE      the branch diff is run through `tools/check-lane.sh` for the member who owns
#                the feature named in the branch. F15 has two owners, so it passes if the diff
#                is inside EITHER one's lane.
#   4. ONE FILE PER COMMIT — reported, never failed. A rename or a formatter sweep is legitimate.
#
# USAGE
#   bash tools/check-commits.sh                                  # origin/develop..HEAD, from branch
#   bash tools/check-commits.sh --member M3
#   bash tools/check-commits.sh --range 196bf0b..HEAD --member owner
#   bash tools/check-commits.sh --range origin/develop..HEAD --branch feat/F07-student-home
#   bash tools/check-commits.sh --range origin/develop..HEAD --branch feat/F03-x --rules-ref origin/develop
#
#   --branch     when HEAD is detached (CI). A local run reads the current branch instead.
#   --rules-ref  judge by THAT ref's rules — its `tools/commit.sh`, its allowlist, its
#                `tools/check-lane.sh` and its `.mailmap` — while the tool under test is still
#                the working tree's. This is what makes the check bootstrap-safe: the pull
#                request that INTRODUCES a change to the rules is judged by the rules already on
#                the base branch, so nobody can relax the rule that judges them.
#
#   The LANE check reads the CURRENT CHECKOUT, because that is what `tools/check-lane.sh` does.
#   In CI that is the branch under test, which is correct. When auditing somebody else's branch
#   locally, check that branch out first, or run this from a scratch clone.
#
# EXCEPTIONS
#   `tools/commit-hygiene-allowlist.txt` names individual commits that are exempt, each with a
#   written reason. An exception is recorded, never silent — and under `--rules-ref` it is read
#   from the base branch, so a member cannot add one to their own pull request.
#
# Exit 0 = the log is readable and attributable. Exit 1 = stop and fix.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

red() { printf '\033[31m%s\033[0m\n' "$1"; }
grn() { printf '\033[32m%s\033[0m\n' "$1"; }
ylw() { printf '\033[33m%s\033[0m\n' "$1"; }
hdr() { printf '\033[36m%s\033[0m\n' "$1"; }

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANGE=""; MEMBER=""; BRANCH_ARG=""; RULES_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --range)     RANGE="${2:-}"; shift 2 ;;
    --member)    MEMBER="${2:-}"; shift 2 ;;
    --branch)    BRANCH_ARG="${2:-}"; shift 2 ;;
    --rules-ref) RULES_REF="${2:-}"; shift 2 ;;
    -h|--help)   sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) red "unknown argument '$1'"; exit 2 ;;
  esac
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── the rules ──────────────────────────────────────────────────────────────
# Everything that DEFINES a rule is read through here: from the base branch when a rules ref is
# given, from the working tree otherwise. `basename` is deliberate — the files live together in
# tools/, and one of them (`check-lane.sh`) has to be executed from a temp path.
rules_file() {
  local path="$1" out
  if [[ -z "$RULES_REF" ]]; then
    printf '%s\n' "$TOOLS_DIR/$(basename "$path")"
    return 0
  fi
  out="$TMP/$(basename "$path")"
  git show "$RULES_REF:$path" > "$out" 2>/dev/null || return 1
  printf '%s\n' "$out"
}

COMMIT_SH="$(rules_file tools/commit.sh)" || {
  red "cannot read tools/commit.sh from '${RULES_REF:-the working tree}' — refusing to run."
  exit 2
}
CONV_RE="$(sed -n "s/^CONV_RE='\(.*\)'$/\1/p" "$COMMIT_SH")"
BAD_WORDS="$(sed -n "s/^BAD_WORDS='\(.*\)'$/\1/p" "$COMMIT_SH")"
if [[ -z "$CONV_RE" || -z "$BAD_WORDS" ]]; then
  red "could not read CONV_RE / BAD_WORDS out of $COMMIT_SH."
  printf '  The message rule has one definition, in tools/commit.sh, and this check reads it\n'
  printf '  rather than copying it. If that file no longer defines them, fix that first.\n'
  exit 2
fi

LANE_GUARD="$(rules_file tools/check-lane.sh)" || LANE_GUARD=""
ALLOWLIST="$(rules_file tools/commit-hygiene-allowlist.txt)" || ALLOWLIST=""

# Team identity: the convention everywhere in this repo is Full Name <studentID@student.polytechnic.bh>.
TEAM_EMAIL_RE='<[0-9]{9}@student\.polytechnic\.bh>$'

# Resolve an address the way `git shortlog` will: through the mailmap. Under --rules-ref the
# BASE branch's mailmap is used (mailmap.blob), so a branch cannot widen who counts as a member.
# NOTE: git always reads the working tree's `.mailmap` as well, so that file is in the lane
# guard's scope too — a member editing it fails the lane check before this one matters.
resolve_identity() {
  if [[ -n "$RULES_REF" ]]; then
    git -c "mailmap.blob=$RULES_REF:.mailmap" check-mailmap "$1" 2>/dev/null
  else
    git check-mailmap "$1" 2>/dev/null
  fi
}


# ── what to check ──────────────────────────────────────────────────────────
BRANCH="${BRANCH_ARG:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")}"
if [[ -z "$BRANCH" || "$BRANCH" == "HEAD" ]]; then
  red "detached HEAD and no --branch given."
  printf '  Say which branch this is:  bash tools/check-commits.sh --branch feat/Fxx-slug\n'
  exit 2
fi
# CI checks out a detached commit, and check-lane.sh refuses a detached HEAD. Give it a name.
if [[ -n "$BRANCH_ARG" ]] && ! git symbolic-ref -q HEAD >/dev/null; then
  git switch -c "hygiene-check-$(git rev-parse --short HEAD)" >/dev/null 2>&1 || true
fi

if [[ -z "$RANGE" ]]; then
  if ! git rev-parse --verify -q origin/develop >/dev/null; then
    red "origin/develop is not present — fetch it, or pass --range <base>..<head>."
    exit 2
  fi
  MB="$(git merge-base origin/develop HEAD 2>/dev/null)"
  if [[ -z "$MB" ]]; then
    red "no merge-base between origin/develop and HEAD (shallow clone?)."
    printf '  git fetch --unshallow   (or pass --range <base>..<head>)\n'
    exit 2
  fi
  RANGE="$MB..HEAD"
fi

# Which lane judges this branch? The feature in the branch name decides, using the same FEATURES
# table the guard itself holds — so there is one list of who owns what, not two.
member_features() {
  sed -n "/^  $2) NAME=/,/^      BRANCH_RE=/p" "$1" 2>/dev/null \
    | sed -n 's/^      FEATURES="\(.*\)"$/\1/p'
}
CANDIDATES=""
if [[ -n "$MEMBER" ]]; then
  CANDIDATES="$MEMBER"
elif [[ -n "$LANE_GUARD" ]]; then
  if [[ "$BRANCH" =~ ^feat/F([0-9]{2})- ]]; then
    FEAT="F${BASH_REMATCH[1]}"
    for m in M2 M3 M4 M5; do
      case " $(member_features "$LANE_GUARD" "$m") " in
        *" $FEAT "*) CANDIDATES="$CANDIDATES $m" ;;
      esac
    done
  elif [[ "$BRANCH" =~ ^(docs|chore|fix|release|hotfix)/ ]]; then
    CANDIDATES=" owner"   # the project-level prefixes are the owner's lane
  fi
fi

hdr "check-commits.sh"
hdr "  range  : $RANGE"
hdr "  branch : $BRANCH${RULES_REF:+   (rules from $RULES_REF)}"
[[ -n "$CANDIDATES" ]] && hdr "  lane   :$CANDIDATES"
printf '\n'

git log --no-merges --format='%H%x09%ae%x09%an%x09%s' "$RANGE" > "$TMP/commits"
TOTAL="$(grep -c . "$TMP/commits" 2>/dev/null || true)"
if [[ -z "$TOTAL" || "$TOTAL" -eq 0 ]]; then
  grn "OK  no commits in $RANGE"
  printf '\nVERDICT: log OK\n'
  exit 0
fi

# FAIL CLOSED ON AN IMPLAUSIBLE RANGE. This is not defensive decoration: on its first CI run this
# check was handed `origin/develop..HEAD` in a checkout where that ref did not resolve to
# develop's tip, so it judged **1345 commits** — the repository's whole history — and failed the
# branch on eight non-Conventional subjects from the project's first week. A gate that fails for
# the wrong reason teaches people to ignore it, which is worse than no gate. A feature branch on
# this project brings tens of commits; hundreds means the base is wrong.
RANGE_LIMIT=200
if [[ "$TOTAL" -gt "$RANGE_LIMIT" ]]; then
  red "REFUSING: '$RANGE' contains $TOTAL non-merge commits, which is a history, not a branch."
  printf '  A feature branch here brings tens of commits. This almost always means the base ref is\n'
  printf '  not what it should be — check it with:\n'
  printf '    git rev-parse --short <base>\n'
  printf '  then pass an explicit range:  --range <base-sha>..HEAD\n'
  exit 2
fi

allowlisted() {   # allowlisted <sha> — matched on the first 12 characters
  [[ -n "$ALLOWLIST" && -f "$ALLOWLIST" ]] || return 1
  grep -v '^[[:space:]]*#' "$ALLOWLIST" 2>/dev/null | awk '{print $1}' | grep -q "^${1:0:12}"
}

FAILED=0; BAD_IDS=0; BAD_MSGS=0; MULTI=0; EXEMPT=0

while IFS=$'\t' read -r sha email name subject; do
  [[ -z "$sha" ]] && continue
  short="${sha:0:12}"
  problems=""

  resolved="$(resolve_identity "<$email>")"
  if ! [[ "$resolved" =~ $TEAM_EMAIL_RE ]]; then
    problems="${problems}identity "
    BAD_IDS=$((BAD_IDS + 1))
  fi

  if allowlisted "$sha"; then
    EXEMPT=$((EXEMPT + 1))
  else
    low="$(printf '%s' "$subject" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    if [[ "$low" =~ $BAD_WORDS ]] || ! [[ "$subject" =~ $CONV_RE ]]; then
      problems="${problems}message "
      BAD_MSGS=$((BAD_MSGS + 1))
    fi
  fi

  files="$(git show --format= --name-only "$sha" | grep -c . || true)"
  [[ -n "$files" && "$files" -gt 1 ]] && MULTI=$((MULTI + 1))

  if [[ -n "$problems" ]]; then
    FAILED=1
    red "  $short  FAILED: ${problems% }"
    printf '      author  : %s <%s>%s\n' "$name" "$email" "${resolved:+  ->  $resolved}"
    printf '      subject : %s\n' "$subject"
    printf '      files   : %s\n' "$files"
  else
    grn "  $short  ok"
  fi
done < "$TMP/commits"

# ── the lane, for the whole branch diff rather than per commit ────────────
printf '\n'
if [[ -z "$LANE_GUARD" ]]; then
  ylw "WARN no tools/check-lane.sh available — lane check skipped"
elif [[ -z "$CANDIDATES" ]]; then
  ylw "WARN branch '$BRANCH' names no member lane — lane check skipped"
elif ! git symbolic-ref -q HEAD >/dev/null; then
  ylw "WARN detached HEAD — tools/check-lane.sh refuses that state, so the lane check is skipped"
else
  LANE_OK=0
  LANE_OUT="$TMP/lane.log"
  for m in $CANDIDATES; do
    if bash "$LANE_GUARD" "$m" > "$LANE_OUT" 2>&1; then
      grn "  lane OK for $m"
      LANE_OK=1
      break
    fi
  done
  if [[ "$LANE_OK" -eq 0 ]]; then
    FAILED=1
    red "  lane check FAILED for:$CANDIDATES"
    sed 's/^/      /' "$LANE_OUT"
  fi
fi

# ── verdict ───────────────────────────────────────────────────────────────
printf '\n'
if [[ "$FAILED" -eq 1 ]]; then
  red "VERDICT: STOP. The log is not readable, or the diff is outside its lane."
  printf '  commits checked        : %s\n' "$TOTAL"
  printf '  identity failures      : %s\n' "$BAD_IDS"
  printf '  message failures       : %s\n' "$BAD_MSGS"
  printf '  exempt by the allowlist: %s\n' "$EXEMPT"
  printf '\n  Fix, in this order:\n'
  printf '    1. git config --local user.name  "Your Full Name"\n'
  printf '       git config --local user.email "<studentID>@student.polytechnic.bh"\n'
  printf '    2. commit with the tool:  bash tools/commit.sh <path> "type(Fxx): subject"\n'
  printf '    3. a subject already pushed cannot be reworded without a force-push, which\n'
  printf '       docs/12 §5 forbids. Either the owner records it in\n'
  printf '       tools/commit-hygiene-allowlist.txt with a written reason, or the branch is\n'
  printf '       rewritten by agreement and recorded in the decision log.\n'
  exit 1
fi

grn "VERDICT: log OK. Every commit is attributable, well messaged, and inside its lane."
[[ "$MULTI" -gt 0 ]] && ylw "NOTE $MULTI commit(s) changed more than one file — rule 2 prefers one file per commit."
exit 0
