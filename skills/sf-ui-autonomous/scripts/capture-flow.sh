#!/bin/bash
# sf-ui-autonomous: capture a new flow
# Usage: ./scripts/capture-flow.sh <org-alias> [--intent "<text>"] [--profile NPSP|NPC|NPC+EDA|vanilla]
#
# Drives the autonomous discovery loop and writes a Playwright spec into library/flows/.
# Updates library/library.json with the new entry.
# Auto-commits with `learn(sf-ui-autonomous): add <flow-id> flow (<profile>)`.
# Never pushes — user reviews and pushes when ready.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBRARY_JSON="$SKILL_DIR/library/library.json"
FLOWS_DIR="$SKILL_DIR/library/flows"
AUTH_DIR="$HOME/.claude/sf-ui-autonomous"

ORG_ALIAS="${1:-}"
INTENT=""
PROFILE=""

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --intent) INTENT="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$ORG_ALIAS" ]]; then
  echo "Usage: $0 <org-alias> [--intent \"<text>\"] [--profile NPSP|NPC|NPC+EDA|vanilla]" >&2
  exit 2
fi

echo "╔══════════════════════════════════════════════╗"
echo "║   sf-ui-autonomous — capture a new flow      ║"
echo "╚══════════════════════════════════════════════╝"
echo "  Org alias: $ORG_ALIAS"
echo "  Intent:    ${INTENT:-<will prompt>}"
echo "  Profile:   ${PROFILE:-<will infer>}"
echo ""

# 1. Verify org auth
if ! sf org display --target-org "$ORG_ALIAS" --json > /dev/null 2>&1; then
  echo "❌ Org $ORG_ALIAS is not authenticated." >&2
  echo "   Run: sf org login web --alias $ORG_ALIAS" >&2
  exit 1
fi

INSTANCE_URL=$(sf org display --target-org "$ORG_ALIAS" --json | jq -r '.result.instanceUrl')
echo "✅ Org authenticated: $INSTANCE_URL"

# 2. Establish storageState (this is the long-lived auth artifact)
mkdir -p "$AUTH_DIR/$ORG_ALIAS"
STORAGE_STATE="$AUTH_DIR/$ORG_ALIAS/storageState.json"
if [[ ! -f "$STORAGE_STATE" ]]; then
  echo ""
  echo "ℹ️  No saved storageState for $ORG_ALIAS. Establishing session..."
  echo "   Open the frontdoor URL once, log in, and Playwright will save the cookies."
  echo "   (This only happens on first capture for each org.)"
  # Real implementation: drive sf org open + Playwright storageState capture here.
  # Bootstrap leaves this as a TODO; first capture session writes the file.
  echo "   TODO[bootstrap]: implement storageState bootstrap via sf org open + Playwright"
fi

# 3. Drive autonomous discovery
# This is where the agent's MCP browser tools take over. The shell script
# delegates to the agent's runtime — see SKILL.md Phase 2 for the contract.
#
# The agent receives:
#   - INSTANCE_URL
#   - STORAGE_STATE path
#   - INTENT (prompted if empty)
#   - PROFILE (inferred from sf org display + installed packages if empty)
#
# The agent emits a JSONL trace to a temp file, then this script invokes
# the compiler to produce the .spec.ts and update library.json.

echo ""
echo "🤖 Handing control to the agent for autonomous discovery."
echo "   (The agent reads INTENT and INSTANCE_URL from the environment.)"
echo "   TODO[bootstrap]: wire the agent invocation. First real capture seeds this."

# 4. Compile trace → spec (placeholder — real compiler is the agent's responsibility)
# 5. Update library.json (atomic write via jq)
# 6. Auto-commit with `learn(sf-ui-autonomous): ...` convention
# 7. Print summary; never push

echo ""
echo "Done. Review the new entry with: jq '.flows[-1]' $LIBRARY_JSON"
echo "Push to share: git log --grep='^learn(sf-ui-autonomous' && git push public HEAD"
