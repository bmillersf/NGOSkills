#!/usr/bin/env bash
# auto-update-skills.sh
# Cursor hook (beforeSubmitPrompt): non-blocking auto-update of the NGOSkills repo.
#
# This hook is FAST. The actual git fetch happens in a backgrounded subprocess
# spawned by scripts/auto-update-skills.sh; this wrapper just kicks it off
# and immediately returns the required allow-prompt JSON so Cursor doesn't
# perceive any added latency.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UPDATER="$REPO_ROOT/scripts/auto-update-skills.sh"

# Fire and forget. Always non-blocking. Failures are swallowed by the updater.
if [ -x "$UPDATER" ]; then
  "$UPDATER" --quiet </dev/null >/dev/null 2>&1 || true
fi

# Cursor hook protocol: must emit valid JSON to allow the prompt to proceed.
echo '{"permission": "allow"}'
exit 0
