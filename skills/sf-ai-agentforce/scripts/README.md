# sf-ai-agentforce automation scripts

Three reusable scripts that fill gaps the Salesforce CLI does not cover for Agentforce + MIAW
operations as of API v66 (2026 spring). Each is generalized over an org alias so they can be
reused across projects.

| Script | What it does | When you need it |
|---|---|---|
| `activate-service-agent.spec.ts` | Drives the Agentforce Builder UI to activate a `EinsteinServiceAgent` BotVersion (no API exists). | Any time you create or clone a customer-facing agent. |
| `wire-channel-to-service-agent.sh` | PATCHes `MessagingChannel.SessionHandlerId` to a BotDefinition Id (Tooling-only field; metadata XML schema does not expose it). | Any time you want a MIAW channel to talk to a ServiceAgent without going through a flow + queue. |
| `publish-esc.spec.ts` | Publishes / re-publishes an `EmbeddedServiceConfig` by direct ID via the Setup UI. | After ANY change to channel wiring, branding, auth mode, or bot — runtime config endpoint snapshots wiring at publish. |

## Quick start

```bash
# Once: install Playwright in your project
npm i -D @playwright/test
npx playwright install chromium

# Activate a freshly-deployed ServiceAgent
TARGET_ORG=mydevhub BOT_DEV_NAME=Donor_Support_Service_Agent \
  npx playwright test path/to/activate-service-agent.spec.ts

# Wire a channel directly to the bot (skip the flow + queue dance)
TARGET_ORG=mydevhub \
  CHANNEL_DEV_NAME=FINCA_Donor_Chat \
  BOT_DEV_NAME=Donor_Support_Service_Agent \
  ESC_DEV_NAME=FINCA_Donor_Chat \
  ./wire-channel-to-service-agent.sh

# Re-publish the ESC so changes go live
TARGET_ORG=mydevhub ESC_DEV_NAME=FINCA_Donor_Chat \
  npx playwright test path/to/publish-esc.spec.ts
```

## Why these are not in the CLI

Each script's docblock has the gory details. Short version:

1. **Activation.** `BotVersion.Status` is read-only at the sObject layer; `<status>` is not in the
   metadata schema; no `/services/data/.../connect/...` endpoint exists for ServiceAgent
   activation. The only path is the Agentforce Builder UI's "Activate" button → "Configuration
   Issues Detected" modal → "Ignore & Activate".

2. **Channel wiring.** The metadata XML for `<MessagingChannel>` only supports
   `<sessionHandlerType>Flow</sessionHandlerType>` with `<sessionHandlerFlow>` +
   `<sessionHandlerQueue>`. Trying to add `<sessionHandlerBotDefinition>` fails schema
   validation. But the live record's `SessionHandlerId` reference field accepts a BotDefinition
   Id (`0Xx...`) directly — the runtime branches on the prefix.

3. **ESC publish.** No API exists. Re-deploying the ExperienceBundle / ESC metadata does not
   flip the published state. Only the Setup UI Publish button updates the snapshot the
   runtime config endpoint serves.

## Caveats

- These rely on Setup UI selectors that Salesforce can change between releases. Each spec uses
  text-based selectors (e.g. `Open in Builder`, `Activate`, `Ignore & Activate`) rather than
  IDs / DOM paths. If a selector breaks after a Salesforce release, update the string in one place.
- The `activate-service-agent.spec.ts` spec assumes the ServiceAgent has a complete-enough
  configuration to pass the soft-fail "Configuration Issues" gate. It clicks **Ignore & Activate**.
  Set `IGNORE_AND_ACTIVATE=false` to opt into the **Review Activation Checklist** path instead.
- For activation, the Builder runs in a separate Lightning app at
  `/AiCopilot/copilotStudio.app#/copilot/builder?copilotId=<id>&versionId=<id>` — if Salesforce
  changes that route, the `Open in Builder` button text-match still works because we navigate
  via the in-page anchor, not a constructed URL.
