#!/bin/bash
# nonprofit-skill-router.sh
# Cursor hook: intercepts prompts and auto-detects which nonprofit
# skill(s) should be applied based on keyword matching.
#
# Hook event: beforeSubmitPrompt
# Delegates to the Python router for reliable JSON/keyword handling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROUTER="$REPO_ROOT/.cursor/hooks/nonprofit-skill-router.py"

if command -v python3 &>/dev/null && [ -f "$ROUTER" ]; then
  python3 "$ROUTER" "$REPO_ROOT"
else
  echo '{"permission": "allow"}'
fi

exit 0
