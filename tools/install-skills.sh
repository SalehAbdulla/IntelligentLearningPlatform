#!/usr/bin/env bash
# Installs the Cline agent skills recommended for StudyForge.
# See docs/07-CLINE-SKILLS-AND-TOOLING.md section 3.
#
# Usage:  bash tools/install-skills.sh
#
# NOTE: installs LOCALLY into the repository (not globally).
# The CLI rejects global installs ("PromptScript does not support global skill
# installation"), and a local install is better anyway: the skills are committed
# alongside the project so every team member gets the identical setup.

set -uo pipefail

SKILLS=(
  # --- Firebase (official) -------------------------------------------------
  "firebase/agent-skills@firebase-basics"
  "firebase/agent-skills@firebase-auth-basics"
  "firebase/agent-skills@firebase-firestore"
  "firebase/agent-skills@firebase-ai-logic-basics"
  "firebase/agent-skills@firebase-security-rules-auditor"
  "firebase/agent-skills@xcode-project-setup"
  "firebase/agent-skills@firebase-crashlytics"
  # --- SwiftUI / Swift ----------------------------------------------------
  "avdlee/swiftui-agent-skill@swiftui-expert-skill"
  "twostraws/swiftui-agent-skill@swiftui-pro"
  "emilkowalski/skills@write-swift"
  "uizze.sh@ios-design"
  # --- Testing / accessibility --------------------------------------------
  "twostraws/swift-testing-agent-skill@swift-testing-pro"
  "avdlee/swift-testing-agent-skill@swift-testing-expert"
  "dpearson2699/swift-ios-skills@ios-accessibility"
  # --- Figma (installs figma-use, figma-use-figjam, figma-use-motion,
  #     figma-use-slides; there is no separate "implement-design" skill) ----
  "figma/mcp-server-guide"
)

# NOT INSTALLABLE (verified 2026-09-28):
#   uizze.sh@ios-design  -> "Failed to clone repository: 'uizze.sh@ios-design' does
#                           not exist". It is a registry listing with no source repo.
#   Substitute: swiftui-pro + swiftui-expert-skill (already in the list above),
#               plus the house design system in docs/06-DESIGN-SYSTEM.md.

ok=0
fail=0

for skill in "${SKILLS[@]}"; do
  printf '\n=== %s ===\n' "$skill"
  if npx --yes skills add "$skill" -y </dev/null 2>&1 | tail -6; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    printf '!! FAILED: %s\n' "$skill"
  fi
done

printf '\n──────── summary ────────\n'
printf 'installed/attempted : %d\n' "${#SKILLS[@]}"
printf 'reported success    : %d\n' "$ok"
printf 'reported failure    : %d\n' "$fail"
printf '\nVerifying:\n'
npx --yes skills check 2>&1 | tail -30
