#!/usr/bin/env bash
# new-branch.sh — create a correctly named branch from an up-to-date develop.
# See docs/12-GIT-WORKFLOW.md §2.
#
# Usage:
#   bash tools/new-branch.sh feat/F04-sm2-scheduling
#   bash tools/new-branch.sh fix/F13-tap-webhook-idempotency
#   bash tools/new-branch.sh --from main hotfix/demo-login-crash   # hotfixes branch from main
#
# Valid prefixes: feat/ fix/ docs/ chore/ release/ hotfix/

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FROM="develop"
if [[ "${1:-}" == "--from" ]]; then
  FROM="${2:-}"; shift 2
fi

NAME="${1:-}"
[[ -n "$NAME" ]] || {
  echo "usage: bash tools/new-branch.sh [--from <base>] <type>/<slug>" >&2
  echo "  e.g. bash tools/new-branch.sh feat/F04-sm2-scheduling" >&2
  exit 2
}

die() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }
ok()  { printf '\033[32m✓ %s\033[0m\n' "$1"; }

# ── naming rule ─────────────────────────────────────────────────────────
if ! [[ "$NAME" =~ ^(feat|fix|docs|chore|release|hotfix)/[a-z0-9._-]+$ ]]; then
  die "invalid branch name '$NAME'.
    Must be lowercase with hyphens and a valid prefix:
      feat|fix|docs|chore|release|hotfix / <slug>
    Example: feat/F04-sm2-scheduling"
fi

# feat/ branches must carry the feature ID — it is what makes sprint evidence searchable
if [[ "$NAME" == feat/* ]] && ! [[ "$NAME" =~ ^feat/F[0-9]{2}- ]]; then
  die "feature branches must include the feature ID, e.g. feat/F04-sm2-scheduling
    (doc 02 §4 defines F01–F15)"
fi

# ── working tree must be clean ──────────────────────────────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  die "you have uncommitted changes. Commit or stash them first:
      bash tools/commit.sh <path> \"<message>\"   or   git stash"
fi

# ── base branch must exist ──────────────────────────────────────────────
git fetch origin --quiet
if ! git show-ref --verify --quiet "refs/heads/$FROM"; then
  if git show-ref --verify --quiet "refs/remotes/origin/$FROM"; then
    git switch -c "$FROM" --track "origin/$FROM"
  else
    die "base branch '$FROM' does not exist locally or on origin.
    Create it first:  git switch -c develop main && git push -u origin develop"
  fi
fi

git switch "$FROM"
git pull --ff-only origin "$FROM" 2>/dev/null || echo "  (no upstream to pull from — continuing)"

git switch -c "$NAME"
git push -u origin "$NAME"

ok "created and pushed '$NAME' from '$FROM'"
printf '\nNow work, then commit one file at a time:\n'
printf '  bash tools/commit.sh --push <path> "type(Fxx): subject"\n'
printf 'Then open the PR:\n'
printf '  gh pr create --base %s --fill\n' "$FROM"
