#!/usr/bin/env bash
# setup.sh
#
# One-shot teammate onboarding. Run this after cloning NGOSkills and you will
# end up with:
#   - every vendor in vendor-pins.txt cloned and checked out at its pinned SHA
#   - every sf-* skill, skills-cursor skill, vendor skill/agent/command
#     symlinked into ~/.claude and ~/.cursor
#   - ~/.claude/CLAUDE.md linked to the canonical agent-autonomy rule
#
# Safe to re-run; everything is idempotent.
#
# Flags passed through to sync-skills.sh:
#   --replace-real            Convert accidental real dirs back to symlinks
#   --migrate-claude-skills   One-time convert ~/.claude/skills from
#                             directory-symlink to a real dir of per-skill
#                             symlinks (required the first time vendors are
#                             added on a machine that already uses NGOSkills)

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 1/3 installing vendor packs at pinned SHAs"
"${REPO_ROOT}/scripts/vendor-install.sh"

echo ""
echo "==> 2/3 verifying vendor SHAs match vendor-pins.txt"
"${REPO_ROOT}/scripts/vendor-install.sh" --verify

echo ""
echo "==> 3/3 wiring symlinks into ~/.claude and ~/.cursor"
"${REPO_ROOT}/scripts/sync-skills.sh" --fix "$@"

echo ""
echo "Done. Verify with:  scripts/sync-skills.sh --check"
