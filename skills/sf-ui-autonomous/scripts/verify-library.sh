#!/bin/bash
# sf-ui-autonomous: verify every captured flow against an org
# Usage: ./scripts/verify-library.sh <org-alias> [--profile NPSP|NPC|NPC+EDA|vanilla]
#
# Replays each spec in library/flows/ that matches the org's profile.
# Updates library.json with new last_verified dates on success.
# Increments replay_failures on failure; quarantines after 3 failures in 30 days.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBRARY_JSON="$SKILL_DIR/library/library.json"

ORG_ALIAS="${1:-}"
FILTER_PROFILE=""

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) FILTER_PROFILE="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$ORG_ALIAS" ]]; then
  echo "Usage: $0 <org-alias> [--profile NPSP|NPC|NPC+EDA|vanilla]" >&2
  exit 2
fi

if ! sf org display --target-org "$ORG_ALIAS" --json > /dev/null 2>&1; then
  echo "❌ Org $ORG_ALIAS is not authenticated." >&2
  exit 1
fi

INSTANCE_URL=$(sf org display --target-org "$ORG_ALIAS" --json | jq -r '.result.instanceUrl')
TOTAL=$(jq '.flows | length' "$LIBRARY_JSON")

if [[ "$TOTAL" -eq 0 ]]; then
  echo "ℹ️  Library is empty. Capture a flow first: ./scripts/capture-flow.sh $ORG_ALIAS"
  exit 0
fi

echo "Verifying $TOTAL flow(s) against $ORG_ALIAS..."
PASS=0
FAIL=0
SKIP=0

# Build the jq filter for profile matching
if [[ -n "$FILTER_PROFILE" ]]; then
  PROFILE_FILTER=".flows[] | select(.org_profile == \"$FILTER_PROFILE\")"
else
  PROFILE_FILTER=".flows[]"
fi

while IFS= read -r flow; do
  ID=$(echo "$flow" | jq -r '.id')
  SPEC=$(echo "$flow" | jq -r '.spec_path')
  PROFILE=$(echo "$flow" | jq -r '.org_profile')

  if [[ ! -f "$SKILL_DIR/$SPEC" ]]; then
    echo "⚠️  Skip $ID: spec file missing at $SPEC"
    SKIP=$((SKIP+1))
    continue
  fi

  echo ""
  echo "▶ Replay: $ID ($PROFILE)"

  if SF_ORG_ALIAS="$ORG_ALIAS" \
     SF_INSTANCE_URL="$INSTANCE_URL" \
     FLOW_INPUTS='{}' \
     npx playwright test "$SKILL_DIR/$SPEC" --reporter=list 2>&1 | tail -20; then
    echo "✅ $ID passed"
    PASS=$((PASS+1))
    # Update last_verified atomically
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    tmp=$(mktemp)
    jq --arg id "$ID" --arg ts "$NOW" \
      '.flows = (.flows | map(if .id == $id then .last_verified = $ts | .replay_failures = 0 else . end))' \
      "$LIBRARY_JSON" > "$tmp" && mv "$tmp" "$LIBRARY_JSON"
  else
    echo "❌ $ID failed"
    FAIL=$((FAIL+1))
    tmp=$(mktemp)
    jq --arg id "$ID" \
      '.flows = (.flows | map(if .id == $id then .replay_failures = ((.replay_failures // 0) + 1) | (if .replay_failures >= 3 then .quarantined = true else . end) else . end))' \
      "$LIBRARY_JSON" > "$tmp" && mv "$tmp" "$LIBRARY_JSON"
  fi
done < <(jq -c "$PROFILE_FILTER" "$LIBRARY_JSON")

echo ""
echo "════════════════════════════════════════"
echo "  Verification complete"
echo "  ✅ Passed:    $PASS"
echo "  ❌ Failed:    $FAIL"
echo "  ⚠️  Skipped:  $SKIP"
echo "════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
