#!/usr/bin/env bash
# todos.sh - list the team's open TODO tasks, grouped by member.
#
# Convention (see ios/StudyForge/CONTRIBUTING.md §4b): a task is marked in the code as
#     // TODO(Mx · Fyy): one-line task
#     // Done when: the acceptance criterion
# This script finds them so each member can read their own list.
#
# Usage:  bash tools/todos.sh   [M2]     # all members, or just one

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
SRC="ios/StudyForge"

members=("${1:-M1}" "${1:-M2}" "${1:-M3}" "${1:-M4}")
if [ "$#" -ge 1 ]; then members=("$1"); fi

total=0
for who in "${members[@]}"; do
  hits="$(grep -rn "TODO($who" "$SRC" --include='*.swift' || true)"
  count=0
  if [ -n "$hits" ]; then
    count="$(printf '%s\n' "$hits" | grep -c "TODO($who")"
  fi
  total=$((total + count))
  printf '\n── %s : %s open ──────────────────────────────\n' "$who" "$count"
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits" | sed 's|^|  |'
  fi
done

printf '\nTotal open tasks: %s\n' "$total"
