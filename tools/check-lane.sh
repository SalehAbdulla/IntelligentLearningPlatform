#!/usr/bin/env bash
# check-lane.sh — verify that the current branch and diff stay inside ONE member's lane.
#
# WHY THIS EXISTS
#   The tutor requires branch-based work with meaningful commits. Three members will
#   run AI agents against this repo at the same time. Two failure modes are predictable
#   and both are expensive: an agent committing to `main`/`develop`, and an agent
#   editing a file that belongs to someone else, which then conflicts on merge.
#
#   Documentation alone prevents neither. This does. It is the same reasoning behind
#   tools/commit.sh (docs/12 section 3.1: "a rule that can be silently bypassed is not
#   a rule").
#
# WHAT IT CHECKS
#   1. The branch is not main or develop.
#   2. The branch name matches the member's allowed feature prefixes.
#   3. Every changed file is inside the member's lane, is a declared SHARED file, or is
#      a NEW file the member is creating.
#   4. Anything in the FORBIDDEN list is refused outright.
#
# USAGE
#   bash tools/check-lane.sh M2        # Mohammed
#   bash tools/check-lane.sh M3        # Tasbeeh
#   bash tools/check-lane.sh M4        # Shahad
#   bash tools/check-lane.sh owner                        # M1: the project-level lane + F01/F02/F14
#   bash tools/check-lane.sh owner --allow-protected      # M1 hotfix: also permits main/develop
#
# The `owner` form is the only one that permits main/develop, and only with the explicit
# --allow-protected flag, which prints OWNER BYPASS first. It exists for the owner hotfix path
# in docs/12 §3.1 (decision D26 in docs/09) and it never relaxes a member's refusal.
#
# Exit 0 = safe to commit and push. Exit 1 = stop and fix.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

red() { printf '\033[31m%s\033[0m\n' "$1"; }
grn() { printf '\033[32m%s\033[0m\n' "$1"; }
ylw() { printf '\033[33m%s\033[0m\n' "$1"; }
hdr() { printf '\033[36m%s\033[0m\n' "$1"; }

MEMBER=""
ALLOW_PROTECTED=0
for arg in "$@"; do
  case "$arg" in
    --allow-protected) ALLOW_PROTECTED=1 ;;
    M1|M2|M3|M4|owner|OWNER) MEMBER="$arg" ;;
    *) red "unknown argument '$arg'"; exit 2 ;;
  esac
done

case "$MEMBER" in
  M1|owner|OWNER) MEMBER=owner ;;
  M2|M3|M4) ;;
  *) red "usage: bash tools/check-lane.sh M2|M3|M4|owner [--allow-protected]"
     printf "  M2|M3|M4            a member's lane, protected branches refused\n"
     printf '  owner               M1: the project-level lane plus F01/F02/F14 files\n'
     printf '  owner --allow-protected  also permits main/develop, for an owner hotfix\n'
     exit 2 ;;
esac

# ── lane definitions ────────────────────────────────────────────────────
# TOUCH  : existing files this member may MODIFY. Kept tight on purpose.
# NEW    : directory prefixes where this member may ADD new files.
# OWNED  : directory prefixes the member owns outright, modify or add. Used only
#          for the owner (M1), whose lane is the project level rather than the app.
# SHARED : may be modified only under the shared-file protocol below.

OWNED_DIRS=()
OWNER_MODE=0

case "$MEMBER" in
  owner) NAME="Saleh Abdulla (repository owner)"; ID=202300540; WHO=owner
      OWNER_MODE=1
      FEATURES="F01 F02 F14 + the project level (docs, deliverables, tools, research)"
      BRANCH_RE='^(feat/F(01|02|14)-|fix/|docs/|chore/|release/)'
      # The owner's lane is everything that is not a member's app code: the planning
      # docs, the deliverables, the tooling and the evidence, plus F01/F02/F14 files.
      OWNED_DIRS=(
        "docs/"
        "deliverables/"
        "tools/"
        "research/"
        ".github/"
        "CONTRIBUTING.md"
        "README.md"
        ".gitignore"
        ".mailmap"
        ".vscode/"
        "skills-lock.json"
        "ios/StudyForge/StudyForge/Core/Auth/"
        "ios/StudyForge/StudyForge/Core/Config/"
        "ios/StudyForge/StudyForge/Core/Localisation/"
        "ios/StudyForge/StudyForge/Core/Materials/"
        "ios/StudyForge/StudyForge/Core/Notifications/"
        "ios/StudyForge/StudyForge/Core/Profile/"
        "ios/StudyForge/StudyForge/Core/Search/"
        "ios/StudyForge/StudyForge/Core/State/"
        "ios/StudyForge/StudyForge/Features/Auth/"
        "ios/StudyForge/StudyForge/Features/Library/"
        "ios/StudyForge/StudyForge/Features/Notifications/"
        "ios/StudyForge/StudyForge/Features/Onboarding/"
        "ios/StudyForge/StudyForge/Features/Profile/"
        "ios/StudyForge/StudyForge/Features/ProfileEdit/"
        "ios/StudyForge/StudyForge/Features/ProfileSetup/"
        "ios/StudyForge/StudyForge/Features/Search/"
        "ios/StudyForge/StudyForge/Features/DesignSystemGallery/"
        "ios/StudyForge/StudyForgeTests/"
      )
      TOUCH=(
        "ios/StudyForge/StudyForge/Core/ContentHash.swift"
      )
      NEW=() ;;
  M2) NAME="Mohammed Almadhoon"; ID=202401702; WHO=mohammed
      FEATURES="F03 F04 F05 F11 F15"
      BRANCH_RE='^feat/F(03|04|05|11|15)-'
      TOUCH=(
        "ios/StudyForge/StudyForge/Core/AI/PromptTemplates.swift"
        "ios/StudyForge/StudyForge/Core/AI/AITier.swift"
        "ios/StudyForge/StudyForge/Core/AI/AIRouter.swift"
        "ios/StudyForge/StudyForge/Core/AI/AIProvider.swift"
        "ios/StudyForge/StudyForge/Core/AI/OnDeviceProvider.swift"
        "ios/StudyForge/StudyForge/Core/Admin/AIConfiguration.swift"
        "ios/StudyForge/StudyForge/Features/Flashcards/FlashcardReviewViewModel.swift"
        "ios/StudyForge/StudyForge/Features/Flashcards/FlashcardReviewView.swift"
        "ios/StudyForge/StudyForge/Features/Flashcards/FlashcardGenerateViewModel.swift"
        "ios/StudyForge/StudyForgeTests/AIRouterTests.swift"
        "ios/StudyForge/StudyForgeTests/AIVocabularyTests.swift"
        "ios/StudyForge/StudyForgeTests/FlashcardReviewViewModelTests.swift"
        "ios/StudyForge/StudyForgeTests/FlashcardGenerateViewModelTests.swift"
        "ios/StudyForge/StudyForgeTests/SummaryFlowViewModelTests.swift"
      )
      NEW=(
        "ios/StudyForge/StudyForge/Core/AI/"
        "ios/StudyForge/StudyForge/Features/Flashcards/"
        "ios/StudyForge/StudyForge/Features/Summaries/"
        "ios/StudyForge/StudyForge/Features/Quizzes/"
        "ios/StudyForge/StudyForge/Features/Tutor/"
        "ios/StudyForge/StudyForgeTests/"
      ) ;;
  M3) NAME="Tasbeeh Saeed"; ID=202300549; WHO=tasbeeh
      FEATURES="F06 F07 F13 F15"
      BRANCH_RE='^feat/F(06|07|13|15)-'
      TOUCH=(
        "ios/StudyForge/StudyForge/Core/Planning/StudyPlan.swift"
        "ios/StudyForge/StudyForge/Core/Planning/StudyPlanner.swift"
        "ios/StudyForge/StudyForge/Core/Planning/StudyPlanStore.swift"
        "ios/StudyForge/StudyForge/Core/Planning/FileStudyPlanStore.swift"
        "ios/StudyForge/StudyForge/Core/Planning/InMemoryStudyPlanStore.swift"
        "ios/StudyForge/StudyForge/Core/Tutor/CohortSnapshot.swift"
        "ios/StudyForge/StudyForge/Features/StudyPlan/StudyPlanWizardView.swift"
        "ios/StudyForge/StudyForge/Features/StudyPlan/StudyPlanWizardViewModel.swift"
        "ios/StudyForge/StudyForge/Features/StudyPlan/StudyPlanViewModel.swift"
        "ios/StudyForge/StudyForge/Features/StudyPlan/StudySessionDetailView.swift"
        "ios/StudyForge/StudyForge/Features/Home/SignedInHomeView.swift"
        "ios/StudyForge/StudyForge/Features/Progress/ProgressDashboardView.swift"
        "ios/StudyForge/StudyForgeTests/StudyPlannerTests.swift"
        "ios/StudyForge/StudyForgeTests/NotificationViewModelTests.swift"
        "ios/StudyForge/StudyForgeTests/CohortSnapshotTests.swift"
      )
      NEW=(
        "ios/StudyForge/StudyForge/Core/Planning/"
        "ios/StudyForge/StudyForge/Core/Payments/"
        "ios/StudyForge/StudyForge/Features/StudyPlan/"
        "ios/StudyForge/StudyForge/Features/Progress/"
        "ios/StudyForge/StudyForge/Features/Subscription/"
        "ios/StudyForge/StudyForgeTests/"
      ) ;;
  M4) NAME="Shahad Ashoor"; ID=202305767; WHO=shahad
      FEATURES="F08 F09 F10 F12"
      BRANCH_RE='^feat/F(08|09|10|12)-'
      TOUCH=(
        "ios/StudyForge/StudyForge/Core/Groups/StudyGroup.swift"
        "ios/StudyForge/StudyForge/Core/Groups/LiveQuizSession.swift"
        "ios/StudyForge/StudyForge/Core/Groups/GroupStore.swift"
        "ios/StudyForge/StudyForge/Core/Groups/FileGroupStore.swift"
        "ios/StudyForge/StudyForge/Core/Groups/InMemoryGroupStore.swift"
        "ios/StudyForge/StudyForge/Core/Bookmarks/BookmarkStore.swift"
        "ios/StudyForge/StudyForge/Core/Bookmarks/FileBookmarkStore.swift"
        "ios/StudyForge/StudyForge/Core/Bookmarks/InMemoryBookmarkStore.swift"
        "ios/StudyForge/StudyForge/Core/Bookmarks/BookmarkCollection.swift"
        "ios/StudyForge/StudyForge/Features/Groups/LiveQuizView.swift"
        "ios/StudyForge/StudyForge/Features/Groups/LiveQuizViewModel.swift"
        "ios/StudyForge/StudyForge/Features/Groups/GroupDetailView.swift"
        "ios/StudyForge/StudyForge/Features/Admin/AdminDashboardView.swift"
        "ios/StudyForge/StudyForgeTests/BookmarkStoreTests.swift"
        "ios/StudyForge/StudyForgeTests/BookmarkViewModelTests.swift"
        "ios/StudyForge/StudyForgeTests/GroupViewModelTests.swift"
        "ios/StudyForge/StudyForgeTests/GroupStoreTests.swift"
        "ios/StudyForge/StudyForgeTests/AdminTests.swift"
      )
      NEW=(
        "ios/StudyForge/StudyForge/Core/Groups/"
        "ios/StudyForge/StudyForge/Core/Bookmarks/"
        "ios/StudyForge/StudyForge/Core/Folders/"
        "ios/StudyForge/StudyForge/Features/Groups/"
        "ios/StudyForge/StudyForge/Features/Folders/"
        "ios/StudyForge/StudyForge/Features/Bookmarks/"
        "ios/StudyForge/StudyForge/Features/Admin/"
        "ios/StudyForge/StudyForgeTests/"
      ) ;;
esac

# Array lengths, so an empty TOUCH/NEW never expands under `set -u` on bash 3.2 (macOS).
TOUCH_LEN="${#TOUCH[@]}"
NEW_LEN="${#NEW[@]}"

# Declared shared files: anyone may touch these, under the protocol below.
SHARED=(
  "ios/StudyForge/StudyForge/App/AppContainer.swift"
  "ios/StudyForge/StudyForge/Resources/en.lproj/Localizable.strings"
  "ios/StudyForge/StudyForge/Resources/ar.lproj/Localizable.strings"
)

# Nobody touches these, ever. The owner's list is shorter: docs, deliverables, tools and the
# repo-level files ARE the owner's lane (see OWNED_DIRS above), so only the project file and
# the backend stay forbidden.
if [[ "$OWNER_MODE" -eq 1 ]]; then
  FORBIDDEN_RE='^(ios/StudyForge/StudyForge\.xcodeproj/|ios/StudyForge/StudyForge\.xcworkspace/|backend/)'
else
  FORBIDDEN_RE='^(ios/StudyForge/StudyForge\.xcodeproj/|ios/StudyForge/StudyForge\.xcworkspace/|docs/|deliverables/|backend/|tools/|\.github/|README\.md$|\.mailmap$|\.gitignore$)'
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
FAILED=0

hdr "check-lane.sh — $NAME ($MEMBER, $ID)"
hdr "your features: $FEATURES"

# ── 1. branch guard ─────────────────────────────────────────────────────
PROTECTED_BYPASS=0
if [[ "$BRANCH" == "main" || "$BRANCH" == "develop" ]]; then
  if [[ "$OWNER_MODE" -eq 1 && "$ALLOW_PROTECTED" -eq 1 ]]; then
    PROTECTED_BYPASS=1
    ylw "OWNER BYPASS: you are on '$BRANCH' and passed --allow-protected."
    printf '     The pull-request rule still applies to M2, M3 and M4. This exemption is\n'
    printf '     yours alone (decision recorded in docs/12 §3.1 and docs/09 D26).\n'
    printf '     For anything that is not an owner hotfix, prefer a branch and a PR.\n'
    printf '     Every commit you make here is permanent on the shared branch: no force-push.\n'
  else
    red "REFUSING: you are on '$BRANCH'. Never work or commit on a protected branch."
    printf '  Create your own branch first:\n'
    if [[ "$OWNER_MODE" -eq 1 ]]; then
      printf '    bash tools/new-branch.sh docs/your-slug\n'
      printf '  Or, for an owner hotfix only: bash tools/check-lane.sh owner --allow-protected\n'
    else
      printf '    bash tools/new-branch.sh feat/Fxx-your-slug\n'
    fi
    exit 1
  fi
fi
if [[ "$BRANCH" == "HEAD" || -z "$BRANCH" ]]; then
  red "REFUSING: detached HEAD. Switch to your own feature branch."
  exit 1
fi
if [[ "$PROTECTED_BYPASS" -eq 1 ]]; then
  ylw "OK  branch is '$BRANCH' — protected, owner bypass active"
else
  grn "OK  branch is '$BRANCH' (not main/develop)"
fi

if [[ "$PROTECTED_BYPASS" -eq 0 && ! "$BRANCH" =~ $BRANCH_RE ]]; then
  ylw "WARN branch '$BRANCH' does not match your expected pattern:"
  printf '     %s\n' "$BRANCH_RE"
  printf '     Allowed feature branches for you: %s\n' "$FEATURES"
fi

# ── 2. collect changed files ────────────────────────────────────────────
BASE="$(git merge-base origin/develop HEAD 2>/dev/null || git merge-base develop HEAD 2>/dev/null || echo "")"
if [[ -z "$BASE" ]]; then
  ylw "WARN no merge-base with develop found; checking the working tree only"
  COMMITTED=""
else
  COMMITTED="$(git diff --name-only "$BASE" HEAD)"
fi
WORKING="$(git diff --name-only HEAD; git diff --name-only --cached; git ls-files --others --exclude-standard)"
CHANGED="$(printf '%s\n%s\n' "$COMMITTED" "$WORKING" | sed '/^$/d' | sort -u)"

if [[ -z "$CHANGED" ]]; then
  grn "OK  no changed files yet"
  printf '\nVERDICT: lane OK\n'
  exit 0
fi

hdr ""
hdr "changed files: $(printf '%s\n' "$CHANGED" | wc -l | tr -d ' ')"

in_list()   { local f="$1"; shift; for e in "$@"; do [[ "$f" == "$e" ]] && return 0; done; return 1; }
under_dir() { local f="$1"; shift; for d in "$@"; do [[ "$f" == "$d"* ]] && return 0; done; return 1; }
exists_base() { [[ -n "$BASE" ]] && git cat-file -e "$BASE:$1" 2>/dev/null; }

SHARED_HIT=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$f" =~ $FORBIDDEN_RE ]]; then
    red "  FORBIDDEN     $f"
    FAILED=1
    continue
  fi
  if [[ "$OWNER_MODE" -eq 1 ]] && under_dir "$f" "${OWNED_DIRS[@]}"; then
    grn "  yours         $f"
    continue
  fi
  if [[ "$f" == research/sprints/* ]]; then
    if [[ "$f" == *"-$WHO-contribution.md" ]]; then grn "  yours         $f"
    else red "  NOT YOURS     $f"; FAILED=1; fi
    continue
  fi
  if [[ "$f" == research/cheatsheets/* ]]; then
    if [[ "$f" == *"/$WHO.md" ]]; then grn "  yours         $f"
    else red "  NOT YOURS     $f"; FAILED=1; fi
    continue
  fi
  if [[ "$f" == research/testing/* || "$f" == research/reviews/* ]]; then
    grn "  yours         $f"
    continue
  fi
  if in_list "$f" "${SHARED[@]}"; then
    ylw "  SHARED        $f   (rebase develop first, keep it to 1-2 lines)"
    SHARED_HIT=1
    continue
  fi
  if [[ "$TOUCH_LEN" -gt 0 ]] && in_list "$f" "${TOUCH[@]}"; then
    grn "  yours         $f"
    continue
  fi
  if [[ "$NEW_LEN" -gt 0 ]] && ! exists_base "$f" && under_dir "$f" "${NEW[@]}"; then
    grn "  new (yours)   $f"
    continue
  fi
  red "  OUT OF LANE   $f"
  FAILED=1
done <<< "$CHANGED"

# ── 3. verdict ──────────────────────────────────────────────────────────
printf '\n'
if [[ $FAILED -eq 1 ]]; then
  red "VERDICT: STOP. You touched something outside your lane."
  printf '  Fix it before committing:\n'
  printf '    git checkout -- <file>        # discard an accidental edit\n'
  printf '    git restore --staged <file>   # unstage it\n'
  printf '  If the change is genuinely needed, ask the team. Do not force it.\n'
  exit 1
fi

if [[ $SHARED_HIT -eq 1 ]]; then
  ylw "VERDICT: lane OK, but you touched a SHARED file. Protocol:"
  printf '  1. git fetch origin && git rebase origin/develop      # before you push\n'
  printf '  2. re-run: bash tools/check-lane.sh %s\n' "$MEMBER"
  printf '  3. keep the shared-file diff to the minimum (1-2 lines)\n'
  printf '  4. if a .strings file changed: python3 tools/check-strings.py\n'
  printf '  5. push. If rejected, rebase again. Never force-push.\n'
  exit 0
fi

grn "VERDICT: lane OK. Safe to commit (one file per commit) and push."

