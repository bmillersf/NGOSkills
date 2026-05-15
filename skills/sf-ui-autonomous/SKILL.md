---
name: sf-ui-autonomous
description: >
  Autonomous Salesforce UI flow capture, replay, and shared knowledge library.
  An AI agent drives the browser via MCP (Playwright MCP / browser-use / Stagehand)
  to perform a Lightning task end-to-end without recorded clicks, then compiles
  the trace into a deterministic Playwright spec, indexes it in a shared library
  keyed by intent + org-shape, and replays the spec on subsequent invocations.
  Captured flows are committed to NGOSkills as `learn(sf-ui-autonomous): ...`
  so every user benefits from every other user's discovered scripts.
  PRECONDITION (must be true before triggering): the task has been confirmed
  UI-only — either (a) sf CLI / Metadata API / Tooling API / Apex / Flow /
  Data Loader cannot accomplish it, (b) the demoscript or use case explicitly
  requires a *visual* outcome (screenshot, presenter walkthrough, end-user
  click path), or (c) the user has explicitly said "we have to do this in
  the UI". If a CLI/metadata path exists, that path is preferred — this
  skill exists to capture flows that genuinely cannot be automated any
  other way, not as a faster route to the same outcome.
  TRIGGER when (UI-only confirmed): user asks to "capture this UI-only flow",
  "autonomously walk the UI for this demo step", "replay a captured
  Lightning flow from the shared library", "find an existing UI script for
  <intent>", "share this captured flow with the team", "build a UI-only
  demo step without me clicking through it", or "the CLI path doesn't
  exist, drive it through Lightning". Also triggers when sf-demo-orchestrate
  Phase 6/7 routes a step here after confirming no CLI/metadata path.
  DO NOT TRIGGER when: any CLI/metadata/Apex/Flow path can accomplish the
  same outcome (use sf-deploy, sf-metadata, sf-apex, sf-flow, sf-data, etc.
  — UI automation is a last resort, not a default), user already has a
  `demoscript.md` and wants the full pre-flight test suite (use
  sf-demo-playwright — deterministic generation from a written click path),
  reactive one-shot UI fallback for a CLI dead-end (use
  sf-ui-fallback-playwright — single-use, not library-bound), full demo
  orchestration from notes (use sf-demo-orchestrate — composes this skill
  at Phase 6/7 *after* CLI viability is ruled out), generic web QA outside
  Salesforce (use gstack-qa or gstack-browse), seeding demo data (use
  sf-nonprofit-demo-data or sf-demo-data — never click through record
  creation), configuring Setup / Experience Builder / Agent Builder /
  Flow Builder (those are metadata edits — use sf-metadata, sf-experience-cloud,
  sf-ai-agentforce, sf-flow respectively, *never* this skill), or writing
  production LWC Jest tests (use sf-lwc).
license: MIT
metadata:
  version: "0.2.0"
  author: "Brian Miller"
  scoring: "170 points across 7 categories"
  status: "bootstrap — library awaiting first captured flows"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-07
upstream_refs:
  - url: https://github.com/microsoft/playwright-mcp
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://playwright.dev/docs/codegen
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://docs.stagehand.dev/
    anchor: ""
    sha256: ""
    importance: supplemental
  - url: https://github.com/browser-use/browser-use
    anchor: ""
    sha256: ""
    importance: supplemental
  - url: https://playwright.dev/docs/auth
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://playwright.dev/docs/release-notes
---

# sf-ui-autonomous: Autonomous Lightning Flow Capture and Shared Library

Drive the Salesforce UI **without recorded clicks**. An agent navigates Lightning to perform an intent, the trace becomes a Playwright spec, and the spec lands in a team-shared library so the next person who asks for the same intent gets a deterministic replay instead of another autonomous run.

This skill is the autonomous-discovery counterpart to `sf-demo-playwright` (deterministic generation from a written demoscript) and `sf-ui-fallback-playwright` (one-shot reactive fallback). Use this when the click path **is not yet known**.

---

## Why this skill exists

Hand-writing Playwright scripts for Lightning is slow because:

- Shadow DOM forces brittle, deeply-nested selectors
- Every demo org is shaped slightly differently (NPSP vs NPC, package versions, custom layouts)
- The "right" way to perform a flow drifts release-over-release

The fix is to **discover the path once with an agent, lock it down with a script, and share the script**. After the first capture for a given intent + org-shape, every subsequent run is fast and deterministic.

---

## Scoring Rubric (170 points)

| Category | Points | What's Evaluated |
|---|---|---|
| **UI-only precondition** | **20** | **Phase 0 gate explicitly run; CLI/metadata alternatives ruled out and documented in the capture metadata. -20 if skipped.** |
| Discovery success | 30 | Agent completed the intent end-to-end without human help |
| Spec compilation | 25 | Generated `.spec.ts` runs cleanly from cold cache |
| Selector resilience | 25 | Locators use role/text/testid, not deep CSS or XPath |
| Library indexing | 25 | `library.json` entry has correct intent, org_profile, fragility, last_verified, and `precondition_reason` |
| Replay reliability | 25 | Captured spec replays green twice in a row |
| Sharing hygiene | 20 | Auto-commit follows `learn(sf-ui-autonomous): ...` convention; no PII / org-specific IDs leaked |

**Thresholds**: ✅ 136+ (Ship it) | ⚠️ 102–135 (Review) | ❌ <102 (Recapture)

A capture that scores well everywhere except the precondition gate is **still a fail**. UI automation that should have been a CLI call is a worse outcome than no automation at all — it adds maintenance burden without value.

---

## Document Map

| Need | Document | Description |
|---|---|---|
| **Library schema** | [library/library.json](library/library.json) | Intent → script index. Authoritative manifest of every captured flow |
| **Captured flows** | [library/flows/](library/flows/) | One `.spec.ts` per intent + org-shape. Generated, not hand-written |
| **Reusable fragments** | [library/fragments/](library/fragments/) | Sub-flows shared across multiple specs (App Launcher, global search, etc.) |
| **Verify all flows** | [scripts/verify-library.sh](scripts/verify-library.sh) | Replays every spec against an org and updates `last_verified` dates |
| **Capture a new flow** | [scripts/capture-flow.sh](scripts/capture-flow.sh) | Wrapper that drives the agent through a discovery session and writes the spec |
| **Selector patterns** | [references/lightning-selectors.md](references/lightning-selectors.md) | Resilient selector recipes for shadow DOM, App Launcher, related lists |
| **Org-shape profiles** | [references/org-profiles.md](references/org-profiles.md) | The four profiles the library indexes against (NPSP, NPC, NPC+EDA, vanilla) |
| **Sharing protocol** | [references/sharing-protocol.md](references/sharing-protocol.md) | Commit convention, PII redaction rules, pull-from-team flow |

---

## Workflow (6-Phase Pattern)

### Phase 0: UI-Only Precondition Check (MANDATORY GATE)

Before any browser is opened, confirm the task genuinely requires UI manipulation. This skill is a **last resort**, not a default — the global policy is to automate via metadata/CLI/Apex first.

Run through this checklist. The skill **aborts** unless at least one box is checked:

- [ ] **No CLI/metadata path exists.** The user's intent cannot be expressed as `sf project deploy`, `sf data create`, `sf apex run`, a Tooling API call, a Metadata API deploy, or a Flow invocation. (Examples that *do* have CLI paths and should NOT use this skill: creating records → `sf data create record`; deploying metadata → `sf project deploy`; activating a flow → Tooling API; configuring an agent → Agent API / metadata; seeding demo data → `sf-nonprofit-demo-data`.)
- [ ] **The visual outcome is the deliverable.** A screenshot, presenter walkthrough, end-user click path, or visual proof is what the user is asking for — not the underlying state change.
- [ ] **The user has explicitly said it's UI-only.** They've stated "we have to do this in the UI" or have already confirmed no CLI path exists.
- [ ] **An upstream skill is routing here after ruling out CLI.** `sf-demo-orchestrate` Phase 6/7 has confirmed no CLI/metadata path is viable for this step.

If none of the above are true, the skill emits:

> ⚠️  This task may not require UI automation. Before proceeding, consider:
> - `sf-deploy` for metadata deployment
> - `sf-data` / `sf-nonprofit-demo-data` for record creation
> - `sf-apex` for behavior changes
> - `sf-flow` / `sf-ai-agentforce` for declarative configuration
> - `sf-metadata` for Setup-equivalent changes
>
> Confirm UI-only or route to one of the above. Aborting capture.

This gate exists because UI captures are slow to produce, brittle to maintain, and bypass the audit trail metadata changes get. They should only exist when no alternative does.

---

### Phase 1: Intent Resolution

Parse the user's request into a structured intent:

```yaml
intent: "create a contact, link to existing account, set role"
org_profile: NPSP                    # one of NPSP | NPC | NPC+EDA | vanilla
expected_inputs: [first_name, last_name, account_name, role]
expected_outcome: "Contact record visible with related Account and AccountContactRelation"
```

Look up `library/library.json`:

- **Match found + `last_verified` < 30 days old**: skip to Phase 5 (replay).
- **Match found but stale**: replay first; on failure, proceed to Phase 2.
- **No match**: proceed to Phase 2 (discovery).

---

### Phase 2: Autonomous Discovery

Drive the browser via the agent's MCP browser tools. The default tool stack:

| Tier | Tool | When to use |
|---|---|---|
| 1 | Playwright MCP (`mcp__plugin_browser_browser__*`) | Default. Cheap, in-session, accessibility-tree based |
| 2 | Stagehand `act()` / `observe()` | When Tier 1 stalls on dynamic Lightning components |
| 3 | browser-use agent | Long flows that span many pages and need autonomous recovery |

**Auth**: never log in inside the discovery loop. Pre-establish a session via `sf org open -p /lightning/page/home -r --target-org <alias>` and capture the session cookie / `storageState.json` to `~/.claude/sf-ui-autonomous/<org-alias>/storageState.json`.

**During discovery, the agent logs every action** to a structured trace:

```jsonl
{"step": 1, "action": "navigate", "url": "/lightning/o/Contact/new", "ts": "2026-05-07T15:42:01Z"}
{"step": 2, "action": "wait_for", "role": "dialog", "name": "New Contact"}
{"step": 3, "action": "fill", "role": "textbox", "name": "First Name", "value": "{{first_name}}"}
...
```

Values from `expected_inputs` become `{{template_vars}}` so the spec is parameterizable.

---

### Phase 3: Spec Compilation

The trace compiles into a Playwright `.spec.ts`:

```typescript
// library/flows/contact-create-with-account.spec.ts
// Auto-captured by sf-ui-autonomous on 2026-05-07
// Intent: create a contact, link to existing account, set role
// Org profile: NPSP
// Last verified: 2026-05-07

import { test, expect } from '@playwright/test';
import { storageStateFor } from '../../scripts/auth';

test.use({ storageState: storageStateFor(process.env.SF_ORG_ALIAS!) });

test('contact-create-with-account', async ({ page }) => {
  const { firstName, lastName, accountName, role } = JSON.parse(
    process.env.FLOW_INPUTS ?? '{}'
  );

  await page.goto(`${process.env.SF_INSTANCE_URL}/lightning/o/Contact/new`);
  await expect(page.getByRole('dialog', { name: 'New Contact' })).toBeVisible();

  await page.getByRole('textbox', { name: 'First Name' }).fill(firstName);
  await page.getByRole('textbox', { name: 'Last Name' }).fill(lastName);
  await page.getByRole('combobox', { name: 'Account Name' }).fill(accountName);
  await page.getByRole('option', { name: accountName }).first().click();

  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText(`${firstName} ${lastName}`)).toBeVisible();
});
```

**Selector hierarchy** (enforced by the compiler — see `references/lightning-selectors.md`):
1. `getByRole` with accessible name
2. `getByLabel`
3. `getByTestId` (Salesforce sets `data-testid` on many lightning-base components)
4. `getByText`
5. CSS / XPath — **forbidden** unless the compiler annotates a TODO for human review

---

### Phase 4: Library Indexing

Append to `library/library.json`:

```json
{
  "id": "contact-create-with-account",
  "intent": "create a contact, link to existing account, set role",
  "org_profile": "NPSP",
  "spec_path": "library/flows/contact-create-with-account.spec.ts",
  "inputs": ["firstName", "lastName", "accountName", "role"],
  "captured_by": "sf-ui-autonomous",
  "captured_at": "2026-05-07T15:48:00Z",
  "last_verified": "2026-05-07T15:48:00Z",
  "salesforce_release": "Spring '26",
  "fragility_score": 0.2,
  "precondition_reason": {
    "category": "visual-deliverable",
    "rationale": "Demo requires the presenter to show the contact creation flow visually for a 'first day with the platform' narrative — the resulting record could be created via sf-data, but the on-screen filling is the deliverable.",
    "alternatives_considered": ["sf-data create record", "sf-nonprofit-demo-data"]
  },
  "tags": ["nonprofit", "core-data", "contact"]
}
```

The `precondition_reason` block is populated by Phase 0 and is **required**. The capture compiler refuses to write the entry without it — that's the data-layer enforcement of the precondition gate.

`fragility_score` is computed from selector mix — pure-role specs score < 0.3; specs that fall back to CSS score > 0.5 and trigger a follow-up TODO.

---

### Phase 5: Replay

Run the spec headlessly with `FLOW_INPUTS` injected:

```bash
SF_ORG_ALIAS=my-demo-org \
SF_INSTANCE_URL=$(sf org display --target-org my-demo-org --json | jq -r '.result.instanceUrl') \
FLOW_INPUTS='{"firstName":"James","lastName":"Okafor","accountName":"By The Hand Club","role":"Volunteer"}' \
npx playwright test library/flows/contact-create-with-account.spec.ts
```

Pass → update `last_verified` and exit. Fail → log the failure mode, fall back to Phase 2 (recapture), and increment a `replay_failures` counter on the library entry. Three failures in 30 days → mark `quarantined: true` and require human review.

---

## Sharing Protocol (the magic)

This is what makes the library team-wide.

### Commit on capture

After Phase 4, auto-commit the new spec + updated `library.json` to NGOSkills using the convention from CLAUDE.md §4:

```
learn(sf-ui-autonomous): add contact-create-with-account flow (NPSP)
```

**Never push.** The user reviews `git log --grep="^learn(sf-ui-autonomous"` and pushes when the captures are worth sharing. See [references/sharing-protocol.md](references/sharing-protocol.md) for the full rules.

### Pull on session start

Other users get new flows automatically through the existing supply chain (CLAUDE.md §5):

1. `auto-update-skills.sh` (SessionStart hook) pulls NGOSkills updates
2. `vendor-install.sh` materializes the new SHA
3. `sync-skills.sh --fix` symlinks the updated `sf-ui-autonomous/` into `~/.claude/skills/`

No new infrastructure. The library rides the existing skill-update rails.

### Redaction (mandatory)

Before any commit, strip from the spec and `library.json`:

- 15/18-char Salesforce record IDs → replaced with `{{template_vars}}` or removed
- Org usernames, My Domain names, sandbox URLs
- Customer / org names → replaced with placeholder unless they're standard demo names ("By The Hand Club" is fine; a real customer name is not)
- Email addresses, phone numbers
- Industry-specific namespace values that tie to one org

The capture compiler runs the redaction pass automatically and refuses to write the spec if it cannot scrub a field.

---

## Integration with sf-demo-orchestrate

Plugs into the `sf-demo-orchestrate` 7-phase pipeline at:

| Pipeline phase | This skill's role |
|---|---|
| Phase 6 (validate / repair loop) | When `sf-demo-validate` finds a gap that requires UI manipulation, this skill captures the manipulation as a reusable spec instead of a one-shot fallback |
| Phase 7 (Playwright pre-flight + presenter guide) | Where a captured flow exists in the library matching a demoscript step, prefer the library spec over generating a new one in `sf-demo-playwright` |

The orchestrator queries `library.json` before each phase and routes accordingly.

---

## Failure handling

| Failure | Cause | Action |
|---|---|---|
| Discovery loop stalls > 5 min | Lightning loading state, modal not detected | Escalate from Tier 1 → Tier 2 (Stagehand `act()`), retry once, then surface to user |
| Spec compiles but won't replay | Race condition, missing wait | Add `expect(...).toBeVisible()` before next action; if persistent, mark `fragility_score += 0.2` |
| Replay green in capture, red in CI | Org-shape mismatch | Confirm `org_profile` match; if different, capture a new entry for the new profile |
| Selector requires CSS/XPath | Component has no role/label/testid | Compiler emits TODO comment + raises `fragility_score`; flag for `sf-lwc` review (component should add `data-testid`) |

---

## Anti-patterns

- **Skipping Phase 0.** Using this skill because it's *available* rather than because the task is *UI-only*. UI captures must be a last resort. If `sf data create record`, `sf project deploy`, `sf apex run`, a Tooling API call, or a Flow invocation can do it, do *that* instead.
- **Capturing record creation as a UI flow.** Almost never correct — record creation has well-defined CLI/API paths. The exception is when the *act of creating a record visually* is the demo (e.g., showing a user filling out a form). In that case, document the reason in the capture metadata.
- **Capturing Setup / Builder configuration as a UI flow.** Setup, Experience Builder, Agent Builder, and Flow Builder are metadata edits in disguise. Use `sf-metadata`, `sf-experience-cloud`, `sf-ai-agentforce`, `sf-flow`. If a config "can only be done via UI", that's a Salesforce platform gap to file, not a capture target.
- **Capturing a flow with hardcoded record IDs.** Every record ID must be templated or looked up at replay time via SOQL.
- **Skipping the org-profile field.** A spec captured against NPSP and replayed in NPC will fail in confusing ways.
- **Letting the agent log in.** Always pre-establish session state. The login flow itself is brittle and not the value of the capture.
- **Pushing learnings without review.** The skill commits locally and stops. The user reviews and pushes.
- **Treating fragility_score > 0.5 as acceptable.** That spec will rot within a release. Re-capture or fix the underlying selector instead.

---

## Common failure modes + remediation

*(populated as real captures happen — bootstrap section)*

---

## Cheat sheet

```bash
# List all captured flows
jq -r '.flows[] | "\(.id)\t\(.org_profile)\t\(.last_verified)"' library/library.json

# Find a flow by intent
jq '.flows[] | select(.intent | contains("contact"))' library/library.json

# Verify every flow against the current org
./scripts/verify-library.sh my-demo-org

# Capture a new flow (interactive intent prompt)
./scripts/capture-flow.sh my-demo-org

# Replay a single flow
SF_ORG_ALIAS=my-demo-org \
SF_INSTANCE_URL=$(sf org display --target-org my-demo-org --json | jq -r '.result.instanceUrl') \
FLOW_INPUTS='{...}' \
npx playwright test library/flows/<flow-id>.spec.ts
```

---

## Status

This skill ships in **bootstrap state**: schema, scripts, and references are in place; the flow library is empty. The first three captures (likely `contact-create`, `campaign-add-member`, `npsp-recurring-donation`) seed it. After that, the library grows organically via the sharing protocol.
