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
  TRIGGER when: user asks to "automate a Lightning flow without writing the
  script", "have an agent figure out the click path", "capture a UI flow
  autonomously", "build a reusable demo step without recording", "find an
  existing UI script for X", "replay a captured Lightning flow", "share a
  captured flow with the team", or "drive the Salesforce UI without manual
  clicking".
  DO NOT TRIGGER when: user already has a `demoscript.md` and wants the full
  pre-flight test suite (use sf-demo-playwright — that's deterministic
  spec generation from a written click path, this is autonomous discovery
  followed by spec generation), reactive one-shot UI fallback for a CLI
  dead-end (use sf-ui-fallback-playwright — single-use, not library-bound),
  full demo orchestration from notes (use sf-demo-orchestrate — composes this
  skill at Phase 6/7), generic web QA outside Salesforce (use gstack-qa or
  gstack-browse), seeding demo data (use sf-nonprofit-demo-data or
  sf-demo-data), or writing production LWC Jest tests (use sf-lwc).
license: MIT
metadata:
  version: "0.1.0"
  author: "Brian Miller"
  scoring: "150 points across 6 categories"
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

## Scoring Rubric (150 points)

| Category | Points | What's Evaluated |
|---|---|---|
| Discovery success | 30 | Agent completed the intent end-to-end without human help |
| Spec compilation | 25 | Generated `.spec.ts` runs cleanly from cold cache |
| Selector resilience | 25 | Locators use role/text/testid, not deep CSS or XPath |
| Library indexing | 25 | `library.json` entry has correct intent, org_profile, fragility, last_verified |
| Replay reliability | 25 | Captured spec replays green twice in a row |
| Sharing hygiene | 20 | Auto-commit follows `learn(sf-ui-autonomous): ...` convention; no PII / org-specific IDs leaked |

**Thresholds**: ✅ 120+ (Ship it) | ⚠️ 90–119 (Review) | ❌ <90 (Recapture)

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

## Workflow (5-Phase Pattern)

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
  "tags": ["nonprofit", "core-data", "contact"]
}
```

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
