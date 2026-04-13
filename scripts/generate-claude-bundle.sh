#!/bin/bash
# generate-claude-bundle.sh
# Generates a single Claude-compatible system prompt from all SKILL.md files.
#
# Usage:
#   ./scripts/generate-claude-bundle.sh                    # All skills
#   ./scripts/generate-claude-bundle.sh --domain nonprofit # Skills matching a pattern
#   ./scripts/generate-claude-bundle.sh --skill sf-apex    # Single skill
#
# Output goes to stdout. Redirect to a file:
#   ./scripts/generate-claude-bundle.sh > claude-system-prompt.txt
#   ./scripts/generate-claude-bundle.sh --domain demo > claude-demo-bundle.txt

SKILLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills"
FILTER=""
SINGLE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --domain) FILTER="$2"; shift ;;
    --skill)  SINGLE="$2"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# ── Header ────────────────────────────────────────────────────────────────────
cat <<'HEADER'
You are a Salesforce development assistant specialized in Nonprofit Cloud (NPC), NPSP, Agentforce, Data Cloud, OmniStudio, and the full Salesforce platform stack. The following skill documents define your methodology, coding standards, scoring rubrics, and workflow for each domain. When the user's request matches a skill's trigger conditions, apply that skill's complete methodology.

---
HEADER

# ── Single skill mode ─────────────────────────────────────────────────────────
if [[ -n "$SINGLE" ]]; then
  SKILL_FILE="$SKILLS_DIR/$SINGLE/SKILL.md"
  if [[ ! -f "$SKILL_FILE" ]]; then
    echo "Error: Skill not found at $SKILL_FILE" >&2
    exit 1
  fi
  echo ""
  echo "## Skill: $SINGLE"
  echo ""
  cat "$SKILL_FILE"
  exit 0
fi

# ── All skills (with optional domain filter) ─────────────────────────────────
SKILL_COUNT=0
for SKILL_PATH in "$SKILLS_DIR"/*/SKILL.md; do
  SKILL_NAME=$(basename "$(dirname "$SKILL_PATH")")

  # Apply domain filter if set
  if [[ -n "$FILTER" && "$SKILL_NAME" != *"$FILTER"* ]]; then
    continue
  fi

  echo ""
  echo "---"
  echo "## Skill: $SKILL_NAME"
  echo ""
  cat "$SKILL_PATH"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

# ── Footer ───────────────────────────────────────────────────────────────────
cat <<FOOTER

---
## Summary

$SKILL_COUNT skills loaded. Apply the appropriate skill based on the user's request using the TRIGGER conditions defined in each skill above. Never mix NPC and NPSP object models. Always apply the skill's scoring rubric before responding.
FOOTER

echo "" >&2
echo "✅ Bundle generated: $SKILL_COUNT skills" >&2
