#!/usr/bin/env bash
# push-learnings.sh
#
# Guided push flow for local skill-learning commits.
#
# Shows every `learn(...)` commit since last push, displays the diff, and
# prompts before pushing. Never force-pushes. Never squashes without asking.
#
# Usage:
#   ./scripts/push-learnings.sh              # interactive (default)
#   ./scripts/push-learnings.sh --dry-run    # show what WOULD push, no push
#   ./scripts/push-learnings.sh --since 7d   # limit to last 7 days
#
# The agent never calls this script itself — it only commits. The user runs
# this when ready to share learnings with the repo.

set -euo pipefail

REPO_ROOT="${HOME}/Cursor/Skills/NGOSkills"
SINCE=""
DRY_RUN=0
REMOTE="public"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --since)   SINCE="$2"; shift 2 ;;
    --remote)  REMOTE="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT"

branch="$(git branch --show-current)"
if [[ -z "$branch" ]]; then
  echo "ERROR: detached HEAD; checkout a branch before pushing." >&2
  exit 1
fi

# Figure out what's unpushed
if git rev-parse --quiet --verify "${REMOTE}/${branch}" >/dev/null 2>&1; then
  BASE="${REMOTE}/${branch}"
else
  BASE="${REMOTE}/main"
  echo "info: remote branch ${REMOTE}/${branch} does not exist; diffing against ${BASE}"
fi

if [[ -n "$SINCE" ]]; then
  RANGE="--since=$SINCE"
else
  RANGE="${BASE}..HEAD"
fi

LEARNING_COMMITS="$(git log $RANGE --grep="^learn(" --oneline 2>/dev/null || true)"

if [[ -z "$LEARNING_COMMITS" ]]; then
  echo "No learn(...) commits to push."
  exit 0
fi

count="$(echo "$LEARNING_COMMITS" | wc -l | tr -d ' ')"

echo ""
echo "=== Pending learning commits on branch '$branch' ==="
echo ""
echo "$LEARNING_COMMITS"
echo ""
echo "Total: $count"
echo ""

# Show stats per skill
echo "=== Skills touched ==="
git log $RANGE --grep="^learn(" --name-only --pretty=format: 2>/dev/null \
  | grep -E "skills/[^/]+/SKILL\.md" \
  | sort | uniq -c | sort -rn | head -20
echo ""

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry-run. No push performed."
  echo "To see the full diff per commit:"
  echo "  git show <sha>"
  echo "To push for real:"
  echo "  $0"
  exit 0
fi

echo "=== Preview diff of all learnings ==="
echo "(press q to skip, space to page)"
echo ""
if [[ -t 1 ]]; then
  git log $RANGE --grep="^learn(" -p | less -R || true
else
  echo "(non-interactive; skipping preview)"
fi

echo ""
read -r -p "Push $count learning commits to ${REMOTE}/${branch}? [y/N] " ans
case "$ans" in
  y|Y|yes)
    git push "$REMOTE" "$branch"
    echo ""
    echo "Pushed. GitHub URL: https://github.com/bmillersf/NGOSkills/tree/$branch"
    ;;
  *)
    echo "Aborted. Nothing pushed."
    exit 0
    ;;
esac
