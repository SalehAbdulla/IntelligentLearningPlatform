#!/usr/bin/env bash
# commit.sh — commit files with meaningful Conventional Commit messages.
#
# Implements the rules in docs/12-GIT-WORKFLOW.md:
#   rule 1  never commit directly to main or develop
#   rule 2  one file per commit
#   rule 3  every commit message must be meaningful
#   rule 6  never commit secrets
#
# Usage:
#   bash tools/commit.sh <path> "<message>"
#   bash tools/commit.sh --push <path> "<message>"
#   bash tools/commit.sh --multi <path> "<message>" [<path> "<message>" ...]
#   bash tools/commit.sh --push --multi <p1> "<m1>" <p2> "<m2>"
#   bash tools/commit.sh --owner --push <path> "<message>"      # owner hotfix only
#
# --owner is for the repository owner (M1) alone, and only for a hotfix that cannot wait
# for a pull request. It permits a commit on main/develop with a printed warning. It does
# NOT relax rules 2, 3 and 6, and it changes nothing for M2, M3 and M4. See docs/12 §3.1.
#
# Examples:
#   bash tools/commit.sh docs/12-GIT-WORKFLOW.md "docs: add the branch and commit workflow"
#   bash tools/commit.sh --push src/SpacedRepetition.swift "feat(F04): implement SM-2 interval calculation"
#   bash tools/commit.sh --multi a.swift "feat(F04): add SM-2 engine" b.swift "test(F04): cover lapse case"

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

PUSH=0
MULTI=0
OWNER=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --push)  PUSH=1 ;;
    --multi) MULTI=1 ;;
    --owner) OWNER=1 ;;
    *)       ARGS+=("$a") ;;
  esac
done

die()  { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$1"; }
warn() { printf '\033[33m! %s\033[0m\n' "$1" >&2; }

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# ── rule 1: never commit straight to a protected branch ──────────────────
if [[ "$BRANCH" == "main" || "$BRANCH" == "develop" ]]; then
  if [[ "$OWNER" -eq 1 ]]; then
    warn "OWNER BYPASS: committing directly to '$BRANCH'."
    warn "  A pull request is still required for M2, M3 and M4. This exemption is yours"
    warn "  alone (docs/12 §3.1, docs/09 D26). Prefer a branch and a PR for anything that"
    warn "  is not a hotfix — you cannot force-push your way out of a bad commit here."
  else
    die "refusing to commit directly to '$BRANCH'.
    Create a branch first:  bash tools/new-branch.sh feat/F04-sm2-scheduling
    Owner hotfix, you are M1:  bash tools/commit.sh --owner <path> \"<message>\""
  fi
fi

# ── rule 3: the message must be a meaningful Conventional Commit ─────────
CONV_RE='^(feat|fix|test|docs|refactor|chore|style|perf)(\([A-Za-z0-9_.-]+\))?: .{8,}'
BAD_WORDS='^(update|updates|changes?|wip|stuff|final|temp|asdf|save|commit|misc|fixes?|added|done)$'

check_message() {
  local msg="$1" low
  low="$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  if [[ "$low" =~ $BAD_WORDS ]]; then
    die "message '$msg' is not meaningful. See docs/12-GIT-WORKFLOW.md §4.1"
  fi
  if ! [[ "$msg" =~ $CONV_RE ]]; then
    die "message '$msg' is not a Conventional Commit.
    Expected:  type(scope): subject
    Example:   feat(F04): implement SM-2 interval calculation
    Types:     feat fix test docs refactor chore style perf
    See docs/12-GIT-WORKFLOW.md §4"
  fi
}

# ── rule 6: never stage a secret ─────────────────────────────────────────
SECRET_NAME_RE='(GoogleService-Info\.plist|\.env$|serviceAccountKey|\.p12$|\.mobileprovision$|secret|credential)'
SECRET_BODY_RE='(AIza[0-9A-Za-z_-]{20,}|sk_live_[0-9A-Za-z]+|-----BEGIN [A-Z ]*PRIVATE KEY-----)'

# Values that MATCH a secret pattern but are public by design.
#
# The Firebase Web API key is not a credential: it identifies the project to the Identity
# Toolkit endpoints and ships inside every build of the app, so it is already in the App
# Store binary. Access control lives in the security rules and in App Check — never in
# this value's secrecy.
#
# It is listed EXPLICITLY rather than by loosening the regex, so the scanner still catches
# every other AIza… value. Adding anything here requires the same justification.
PUBLIC_VALUE_ALLOWLIST=(
  'AIzaSyDTlYX9eHFd9bfuD8i9MNhZ9fj5Hlolpc8'
)

check_secret() {
  local path="$1"
  [[ "$(basename "$path")" =~ $SECRET_NAME_RE ]] && \
    die "'$path' looks like a secret/credential file. It must stay in .gitignore."

  [[ -f "$path" ]] || return 0

  # Strip the known-public values first, then scan what remains. A file holding ONLY an
  # allowlisted value passes; a file holding one alongside a real key still fails, because
  # the real key survives the strip.
  local scrubbed
  scrubbed="$(cat "$path")"
  for public_value in "${PUBLIC_VALUE_ALLOWLIST[@]}"; do
    scrubbed="${scrubbed//$public_value/}"
  done

  if printf '%s' "$scrubbed" | grep -qEI "$SECRET_BODY_RE"; then
    die "'$path' appears to contain a key or private key. Remove it before committing.
    If the value is public by design, add it to PUBLIC_VALUE_ALLOWLIST in tools/commit.sh
    with a written justification — do not use --no-verify."
  fi
}

commit_one() {
  local path="$1" msg="$2"
  [[ -e "$path" ]] || die "'$path' does not exist."
  check_message "$msg"
  check_secret "$path"

  git add -- "$path"
  if git diff --cached --quiet; then
    warn "no staged change for '$path' — skipping"
    return 0
  fi

  # rule 2: warn if this commit accidentally bundles more than one file
  local n
  n="$(git diff --cached --name-only | wc -l | tr -d ' ')"
  [[ "$n" -gt 1 ]] && warn "this commit contains $n files — rule 2 prefers one file per commit"

  git commit -q -m "$msg"
  ok "$msg"
}

# ── argument handling ───────────────────────────────────────────────────
if [[ "$MULTI" -eq 1 ]]; then
  (( ${#ARGS[@]} % 2 == 0 )) || die "--multi needs pairs: <path> \"<message>\" [<path> \"<message>\" ...]"
  (( ${#ARGS[@]} > 0 )) || die "--multi needs at least one <path> \"<message>\" pair"
  i=0
  while (( i < ${#ARGS[@]} )); do
    commit_one "${ARGS[i]}" "${ARGS[i+1]}"
    i=$((i+2))
  done
else
  (( ${#ARGS[@]} == 2 )) || die "usage: bash tools/commit.sh [--push] <path> \"<message>\""
  commit_one "${ARGS[0]}" "${ARGS[1]}"
fi

# ── push ────────────────────────────────────────────────────────────────
if [[ "$PUSH" -eq 1 ]]; then
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push
    ok "pushed to $(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')"
  else
    git push -u origin "$BRANCH"
    ok "pushed and set upstream: origin/$BRANCH"
  fi
  printf '\nNext: gh pr create --base develop --fill\n'
fi
