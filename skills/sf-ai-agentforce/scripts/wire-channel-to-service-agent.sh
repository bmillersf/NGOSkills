#!/usr/bin/env bash
# Wire a MIAW MessagingChannel directly to an Agentforce ServiceAgent (no flow handoff).
#
# Why this exists:
#   - The metadata-format <MessagingChannel> XML schema does NOT expose a way to point at a
#     BotDefinition. The only valid <sessionHandlerType> values it accepts include "Flow"
#     (with <sessionHandlerFlow> + <sessionHandlerQueue>). Any attempt to use
#     <sessionHandlerBotDefinition> fails with "Element ... invalid at this location".
#   - But the LIVE record DOES have a single SessionHandlerId reference field that accepts
#     either a FlowDefinition Id (300...) OR a BotDefinition Id (0Xx...). The server-side
#     runtime branches on the prefix.
#   - So the supported automation path is: PATCH MessagingChannel.SessionHandlerId via the
#     standard sObject REST API, then RE-PUBLISH the EmbeddedServiceConfig (publish snapshots
#     wiring at publish time — a metadata deploy alone is not enough to flip live behavior).
#
# Usage:
#   TARGET_ORG=<alias> CHANNEL_DEV_NAME=<name> BOT_DEV_NAME=<name> ./wire-channel-to-service-agent.sh
#
# Optional:
#   ESC_DEV_NAME=<name>   # if set, prints the Setup URL for the operator to publish (or
#                          drive Playwright at)
set -euo pipefail

: "${TARGET_ORG:?Set TARGET_ORG (sf alias)}"
: "${CHANNEL_DEV_NAME:?Set CHANNEL_DEV_NAME (MessagingChannel.DeveloperName)}"
: "${BOT_DEV_NAME:?Set BOT_DEV_NAME (BotDefinition.DeveloperName, must be EinsteinServiceAgent type)}"

org_json=$(sf org display --target-org "$TARGET_ORG" --json)
sid=$(echo "$org_json" | python3 -c 'import sys,json,re; print(json.loads(re.sub(r"\x1b\[[0-9;]*m","",sys.stdin.read()))["result"]["accessToken"])')
inst=$(echo "$org_json" | python3 -c 'import sys,json,re; print(json.loads(re.sub(r"\x1b\[[0-9;]*m","",sys.stdin.read()))["result"]["instanceUrl"])')

# Resolve IDs
ch=$(sf data query --target-org "$TARGET_ORG" --query "SELECT Id FROM MessagingChannel WHERE DeveloperName='$CHANNEL_DEV_NAME'" --json | sed 's/\x1b\[[0-9;]*m//g')
ch_id=$(echo "$ch" | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["records"]; print(r[0]["Id"] if r else "")')
[ -n "$ch_id" ] || { echo "MessagingChannel '$CHANNEL_DEV_NAME' not found." >&2; exit 1; }

bot=$(sf data query --target-org "$TARGET_ORG" --query "SELECT Id, AgentType FROM BotDefinition WHERE DeveloperName='$BOT_DEV_NAME'" --json | sed 's/\x1b\[[0-9;]*m//g')
bot_id=$(echo "$bot" | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["records"]; print(r[0]["Id"] if r else "")')
agent_type=$(echo "$bot" | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["records"]; print(r[0].get("AgentType","") if r else "")')
[ -n "$bot_id" ] || { echo "BotDefinition '$BOT_DEV_NAME' not found." >&2; exit 1; }

if [ "$agent_type" != "EinsteinServiceAgent" ] && [ "$agent_type" != "AgentforceServiceAgent" ]; then
  echo "WARNING: BotDefinition.AgentType=$agent_type — customer-facing MIAW only engages AgentType=EinsteinServiceAgent or AgentforceServiceAgent." >&2
  echo "If this bot is AgentforceEmployeeAgent / InternalCopilot, the runtime will silently NOT engage it." >&2
fi

echo "Wiring channel $CHANNEL_DEV_NAME ($ch_id) -> bot $BOT_DEV_NAME ($bot_id)"

http_status=$(curl -s -o /tmp/wire-resp -w '%{http_code}' \
  -X PATCH \
  -H "Authorization: Bearer $sid" \
  -H "Content-Type: application/json" \
  -d "{\"SessionHandlerId\":\"$bot_id\"}" \
  "$inst/services/data/v66.0/sobjects/MessagingChannel/$ch_id")

if [ "$http_status" != "204" ]; then
  echo "PATCH failed (HTTP $http_status):" >&2
  cat /tmp/wire-resp >&2 || true
  exit 1
fi
echo "PATCH ok (204)."

# Verify
verify=$(sf data query --target-org "$TARGET_ORG" --query "SELECT SessionHandlerId, TargetQueueId FROM MessagingChannel WHERE Id='$ch_id'" --json | sed 's/\x1b\[[0-9;]*m//g')
echo "$verify" | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["records"][0]; print(f"  SessionHandlerId = {r[\"SessionHandlerId\"]}\n  TargetQueueId    = {r[\"TargetQueueId\"]}")'

if [ -n "${ESC_DEV_NAME:-}" ]; then
  esc=$(sf data query --target-org "$TARGET_ORG" --use-tooling-api --query "SELECT Id FROM EmbeddedServiceConfig WHERE DeveloperName='$ESC_DEV_NAME'" --json | sed 's/\x1b\[[0-9;]*m//g')
  esc_id=$(echo "$esc" | python3 -c 'import sys,json; r=json.load(sys.stdin)["result"]["records"]; print(r[0]["Id"] if r else "")')
  if [ -n "$esc_id" ]; then
    echo ""
    echo "Next: republish the EmbeddedServiceConfig — runtime config endpoint snapshots wiring at publish time."
    echo "      Setup URL: $inst/lightning/setup/EmbeddedServiceDeployments/$esc_id/view"
    echo "      Or use: TARGET_ORG=$TARGET_ORG ESC_ID=$esc_id npx playwright test publish-esc.spec.ts"
  fi
fi
