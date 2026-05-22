---
name: sf-ui-fallback-playwright
description: >
  Reactive Playwright-based UI fallback for Salesforce tasks the CLI cannot
  complete. Opens a persistent browser session authenticated via SFDX session
  token, generates a Playwright script on the fly, executes it, saves it to
  a library for replay, and self-heals selectors when Salesforce UI changes.
  TRIGGER when: agent determines a task requires UI interaction that sf CLI /
  Metadata API / Tooling API cannot perform; user says "there's no CLI for
  this", "we have to click through Setup", "publish the agent in Agent
  Builder", "activate the PromptTemplate in Prompt Builder", "drag this
  component in Experience Builder", "toggle this Setup switch", "flip the
  Einstein activation toggle", "enable this feature in Setup", "adjust the
  Data Cloud home-page admin settings", or "activate the license in the UI";
  also triggers when another skill surfaces "no CLI path exists — need
  Playwright fallback".
  DO NOT TRIGGER when: sf CLI / Metadata API / Tooling API can do the job
  (route to sf-deploy for deploy commands, sf-metadata for metadata XML,
  sf-apex for Apex, sf-data for data operations), OR when authoring a
  proactive pre-flight demo test suite from a demoscript (use
  sf-demo-playwright — that is proactive suite authoring; this is reactive
  on-demand single-task fallback), OR when running the full demo pipeline
  (use sf-demo-orchestrate which invokes this skill only on CLI dead-ends),
  OR when validating the demo end-to-end (use sf-demo-validate).
license: MIT
compatibility: "Requires Playwright (npm install playwright), sf CLI authenticated to target org"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "120 points across 7 categories — Auth hygiene 15 / CLI-exhaustion check 20 / Selector resilience 25 / Self-heal logic 20 / Screenshot coverage 15 / Library organization 15 / Safety rails 10 (96 is passing)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (7 categories) extracted from existing 'Scoring rubric (120 points)' section in this SKILL.md (line 273). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  ui_fallback_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "CLI-exhaustion check + selector resilience. Maps to CLI-exhaustion check (20) + Selector resilience (25). The skill is supposed to fire only when CLI / Metadata / Tooling API have been tried first; selectors must be from the ladder's top tiers, not raw xpath."
      automatic_hard_fail_rules:
        - "Phase 1 CLI-exhaustion check not documented in the script header comment (skill ran reactive when sf-deploy / sf-metadata / sf-apex / sf-data was the right path)"
        - "Selector ladder violation — <80% of selectors from tiers 1-3 (getByRole / getByText / data-aura-class)"
        - "Raw xpath used outside last-resort fallback path (e.g., xpath=/html/body/div[3]/... — breaks on every Salesforce release)"
        - "Skill invoked when sf-demo-playwright (proactive suite authoring) is the right path"
        - "Skill invoked when sf-demo-orchestrate (full pipeline) or sf-demo-validate (E2E validation) is the right path"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Auth hygiene + Safety rails. Maps to Auth hygiene (15) + Safety rails (10). Heaviest robustness floor — playwright fallbacks run authenticated UI automation; auth leaks + unconfirmed prod writes are the dominant catastrophic failure modes."
      automatic_hard_fail_rules:
        - "Raw password / username stored in playwright.config.ts or env vars (must use SFDX session token via 'sf org display --json' — breaks MFA on CI)"
        - "storageState file committed to git (auth token leak)"
        - "storageState path not gitignored in the project's .gitignore"
        - "Prod write attempted without --write flag + typed confirmation gate"
        - "Read-only default not enforced — script defaults to write mode"
        - "Destructive operation (delete records, deactivate user, drop config) without typed confirmation regardless of org type"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Self-heal logic + library organization. Maps to Self-heal logic (20) + Library organization (15). Script regenerates broken steps and saves to the canonical library path; USAGE.md kept in sync."
      automatic_hard_fail_rules:
        - "locator.waitFor timeout silently passes — no self-heal regeneration, no log entry (masks Salesforce UI changes; drift accumulates)"
        - "Self-heal attempts >2 without escalation to user (infinite-loop risk)"
        - "Script saved outside .claude/playwright-fallbacks/<task-name>.spec.ts (library divergence)"
        - "USAGE.md not updated when a new fallback is saved (next caller can't discover it)"
        - "Inline screenshots / Playwright traces written to project root instead of the documented output dir (clutters repo)"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Screenshot coverage + report on fail. Maps to Screenshot coverage (15). Screenshot after every state change; HTML report opens on failure for debugging."
      automatic_hard_fail_rules:
        - "Screenshot missing after a state change (Setup toggle flipped, modal opened, button clicked) — failure-mode debugging blocked"
        - "HTML report not auto-opened on test failure"
        - "Trace recording disabled (no time-travel debugging on a flake)"
        - "Test runtime exceeds documented budget for the action without retry/timeout discipline (single fallback step >60s without justification)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://playwright.dev/docs/intro
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_org_unified.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://playwright.dev/docs/locators
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes: []
---

# sf-ui-fallback-playwright

Reactive Playwright fallback. Invoked only when an agent has exhausted the CLI / Metadata API / Tooling API and is blocked by a UI-only Salesforce action. Generates a Playwright script on the fly, executes it, captures screenshots at every step, saves the script to a reusable library, and self-heals selectors when Salesforce changes the DOM.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 7 reactive-fallback categories, extracted from this skill's existing scoring section (line 273) and mapped onto the 4-dim shape. Robustness floor at 18 — Playwright fallbacks run authenticated UI automation; auth leaks and unconfirmed prod writes are the dominant catastrophic failure modes. Hard-fail rules block CLI-exhaustion check undocumented, selector-ladder violations (>20% raw xpath), passwords in config, storageState committed to git, prod writes without --write flag + typed confirmation, silent timeout passes (no self-heal), library path divergence, and missing screenshots after state changes. Disable with `eval_harness.enabled: false`.

This skill is the **escape hatch**, not the preferred path. Every time it runs, the Usage Log grows, and recurring UI-only gaps become CLI feature requests filed back to the Salesforce CLI team.

---

## 1. When this skill owns the task

This skill owns the task **only** when all of the following are true:

1. The work cannot be completed with `sf` CLI commands
2. The work cannot be completed via Metadata API (`sf project deploy`, `sf project retrieve`)
3. The work cannot be completed via Tooling API (`sf data query --use-tooling-api`)
4. The work is a **Setup UI** or **Builder UI** action with no public API

### Delegation table — route CLI-achievable work back to CLI skills

| Task | Owning skill | Why NOT this skill |
|---|---|---|
| Deploy metadata (objects, fields, flows) | `sf-deploy` | `sf project deploy start` works |
| Create/update custom fields | `sf-metadata` | Metadata API has full CRUD |
| Create/update permission sets | `sf-permissions` | Metadata API has full CRUD |
| Write/update Apex classes | `sf-apex` | Tooling API + Metadata API both work |
| Query records | `sf-soql` | `sf data query` works |
| Bulk data operations | `sf-data` | `sf data import/export` works |
| Run Apex tests | `sf-testing` | `sf apex run test` works |
| Build an agent topic/action file | `sf-ai-agentforce` | Metadata: `.genAiPlugin`, `.genAiFunction` |
| Query Data Cloud | `sf-datacloud-retrieve` | Data Cloud SQL API |
| **Configure Experience Cloud site pages, branding, routes, guest profile, nav menu** | `sf-nonprofit-experience-cloud-build` (or `sf-experience-cloud`) | **ExperienceBundle / Network / NavigationMenu / Profile / BrandingSet all have full Metadata API coverage.** Edit the JSON/XML and `sf project deploy start` + `sf community publish`. Builder UI drag-drop is iframe-wrapped, shadow-DOM heavy, and fragile — authoring via metadata is both faster and reliable. |
| Publish a community / site | `sf-experience-cloud` | `sf community publish --name "<Site Name>"` works |
| **Publish** an agent (Setup toggle) | **This skill** | No CLI / API for publish click |
| **Activate** a Prompt Template | **This skill** | Activation is UI-only |
| Toggle Einstein Activation | **This skill** | Setup toggle, no API |
| Data Cloud home-page admin settings | **This skill** | Some settings are UI-only |
| Licensing activation without API | **This skill** | Org-level UI action |

If the task is in the top rows, stop and route to the owning CLI skill. Only proceed if the task is truly a UI-only gap.

---

## 2. Cross-cloud scope note

This skill applies **regardless of industry or cloud**. Nonprofit Cloud, Health Cloud, FSC, Public Sector, Education, Manufacturing, Field Service, Sales, Service, Revenue — all sit on top of core platform Setup UI, and all occasionally expose UI-only toggles (feature activation, beta opt-in, licensing, builder drag-drop). This is **not** a generic cloud skill that requires an industry pre-check — it is a platform-level reactive fallback. Industry precedence rules (`references/industry-precheck.md`) apply to **build decisions**, not to the question of "the CLI doesn't expose this button."

---

## 3. Required context to gather first

Before generating or executing any Playwright script:

1. **Target org alias** — `sf org list` must show an authenticated org
2. **Task description** — one-sentence goal (e.g., "Publish the Volunteer Intake agent in Agent Builder")
3. **Write operation?** — if yes, require explicit user confirmation before execution
4. **Prod org?** — run `sf org display --target-org <alias> --json` and inspect `isSandbox` and `instanceUrl`. If the org is **production** AND the task is a write operation, require the `--write` flag AND a typed confirmation (`YES-I-UNDERSTAND-PROD`) before proceeding. Read-only inspection is allowed on prod without confirmation.
5. **Existing saved script?** — check `.claude/playwright-fallbacks/<task-name>.spec.ts` — if present, proceed to replay (Phase 3). If absent, proceed to generation (Phase 4).

Halt and ask the user only if:

- No org alias is set and the task doesn't name one
- The task description is ambiguous (e.g., "fix the thing in Setup")
- Prod + write and no confirmation flag

Everything else, pick defaults and proceed.

---

## 4. Workflow phases

### Phase 1: Verify CLI genuinely can't do it

Before reaching for Playwright, exhaust the CLI. Minimum checks:

```bash
# 1. Browse the unified command tree
sf commands --json | jq -r '.[] | .id' | grep -i <keyword>

# 2. Search metadata types
sf metadata describe --target-org <alias> --json | jq '.metadataObjects[] | .xmlName' | grep -i <keyword>

# 3. Search Tooling API
sf data query --use-tooling-api \
  --query "SELECT DeveloperName FROM <EntityDefinition> LIMIT 5" \
  --target-org <alias>
```

If any of these return a viable command/type, abort Playwright and route back to the owning CLI skill. Document the CLI command in the final summary.

If all three return nothing relevant, the UI fallback is justified. Continue.

### Phase 2: Authenticate via SFDX session

Extract the live session token from the sf CLI so Playwright can piggy-back the existing auth. Never ask the user for a password.

```javascript
// helpers/sf-auth.js
const { execSync } = require('child_process');

function getSalesforceSession(orgAlias) {
  const out = execSync(
    `sf org display --target-org ${orgAlias} --json`,
    { encoding: 'utf8' }
  );
  const { result } = JSON.parse(out);
  const { accessToken, instanceUrl, username } = result;

  // storageState payload Playwright can load
  return {
    instanceUrl,
    username,
    storageState: {
      cookies: [
        {
          name: 'sid',
          value: accessToken,
          domain: new URL(instanceUrl).hostname,
          path: '/',
          httpOnly: true,
          secure: true,
          sameSite: 'Lax',
        },
      ],
      origins: [],
    },
  };
}

module.exports = { getSalesforceSession };
```

Write the storageState to `.claude/playwright-fallbacks/.auth/<orgAlias>.json` (gitignored). Playwright loads it via `use.storageState` and the first navigation lands already logged in.

### Phase 3: Replay saved script if present

Check `.claude/playwright-fallbacks/<task-name>.spec.ts`. If it exists:

1. Load the script
2. Refresh the auth storageState (Phase 2)
3. Run `npx playwright test <script> --reporter=list`
4. If all steps pass, done. Log to `USAGE.md`.
5. If a step fails with a selector error (`TimeoutError` on `locator.waitFor`), mark the failed step and proceed to **self-heal** (regenerate only the affected step, not the whole script).

**Self-heal logic**:

- Load the failing step
- Take a DOM snapshot of the current page
- Re-generate that step's selector using accessibility-first heuristics (role + name → text → data-aura-class → role+nth → DOM path)
- Rewrite only that step in the script file
- Re-run from the failed step onward
- On success, bump `docs_last_verified` in a comment header on the script file and log the heal event in `USAGE.md`

If self-heal fails 2× in a row for the same step, give up and escalate: report the failure with DOM snapshot + screenshot and suggest the user file a CLI feature request.

### Phase 4: Generate a new script

When no saved script exists:

1. Launch Playwright codegen pointed at `instanceUrl` with the authenticated storageState:
   ```bash
   npx playwright codegen --load-storage .claude/playwright-fallbacks/.auth/<orgAlias>.json <instanceUrl>
   ```
2. Walk the user through the UI once (or use the DOM cheat sheet below to generate selectors programmatically for known Setup paths)
3. Post-process the generated script:
   - Replace raw CSS selectors with accessible-name or role+text selectors where possible
   - Add `expect(...).toBeVisible()` between every action for resilience
   - Add `page.screenshot({ path: 'screenshots/step-NN-<label>.png' })` after every state change
   - Add a `test.describe` block named after the task
4. Save to `.claude/playwright-fallbacks/<task-name>.spec.ts`

**Selector priority ladder** (top = best):

1. `page.getByRole('button', { name: 'Publish' })` — accessible role + name
2. `page.getByText('Active', { exact: true })` — visible text
3. `page.locator('[data-aura-class="forceAgentBuilderToolbar"] button', { hasText: 'Publish' })` — Lightning component hook + text
4. `page.locator('one-app-nav-bar-item:has-text("Setup")')` — web component + text
5. `page.locator('button.slds-button_brand:has-text("Save")')` — SLDS class + text
6. Raw DOM path (`xpath=/html/body/...`) — last resort, brittle

### Phase 5: Execute with screenshots at each step

Run the spec:

```bash
npx playwright test .claude/playwright-fallbacks/<task-name>.spec.ts \
  --reporter=html,list \
  --output=.claude/playwright-fallbacks/results/<task-name>-<timestamp>
```

Playwright config must set:

```javascript
// playwright.config.ts
export default {
  use: {
    screenshot: 'on',            // every step, not just failures
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },
  reporter: [['html', { outputFolder: '.claude/playwright-fallbacks/report' }], ['list']],
};
```

Open the HTML report automatically on failure so the human can see exactly what broke.

### Phase 6: Save to library + update USAGE.md

After a successful run:

1. Commit the script to `.claude/playwright-fallbacks/<task-name>.spec.ts` (persisted across sessions — next time, Phase 3 replays it)
2. Append a row to `.claude/playwright-fallbacks/USAGE.md`:

```markdown
| Date       | Task                                 | Script                                 | Outcome | Notes                                  |
|------------|--------------------------------------|----------------------------------------|---------|----------------------------------------|
| 2026-05-01 | Publish Volunteer Intake agent       | publish-agent-volunteer-intake.spec.ts | PASS    | 4 steps, 12s, 0 heals                  |
| 2026-05-03 | Activate Donor Summary prompt        | activate-prompt-donor-summary.spec.ts  | HEALED  | step-3 selector re-generated (role+nm) |
```

3. Recurring patterns in USAGE.md (same task type ≥3 times) become **CLI feature requests** — file against the `salesforcecli/cli` GitHub. The goal is to drive this skill toward zero use over time.

---

## 5. Scoring rubric (120 points)

| Category | Points | What's evaluated |
|---|---|---|
| Auth hygiene | 15 | SFDX session token used; no passwords; storageState gitignored |
| CLI-exhaustion check | 20 | Phase 1 checks documented in script header comment |
| Selector resilience | 25 | ≥80% of selectors from ladder tiers 1–3; no raw xpath except last-resort |
| Self-heal logic | 20 | Script regenerates broken steps, retries, escalates after 2 heal failures |
| Screenshot coverage | 15 | Screenshot after every state change; report opens on fail |
| Library organization | 15 | Script saved to `.claude/playwright-fallbacks/<task-name>.spec.ts`; USAGE.md updated |
| Safety rails | 10 | Prod write requires `--write` + typed confirmation; read-only default |

**Thresholds**: 96+ ship | 72-95 review | <72 rework.

---

## 6. Anti-patterns

1. **Storing raw passwords** in `playwright.config.ts` or env vars. Always use the SFDX session token via `sf org display --json`. Passwords in CI break MFA.
2. **DOM paths instead of accessible selectors.** `xpath=/html/body/div[3]/div/...` breaks on every Salesforce release. Always prefer `getByRole` / `getByText` / `data-aura-class`.
3. **Destructive writes in prod without confirmation.** Prod + write must require `--write` flag AND typed confirmation. Defaulting to "just run it" on prod is the single fastest way to lose customer data.
4. **Not regenerating on selector break.** If a step fails with a timeout on `locator.waitFor`, don't silently pass — re-generate the selector (self-heal) and log it. Silent skips mask Salesforce UI changes and hide drift.
5. **Running this skill when CLI would work.** Every invocation must document Phase 1 CLI checks in the script header. If the CLI can do it, use the CLI skill; this skill is strictly the fallback.
5a. **Automating Experience Builder (Aura or LWR Community Builder).** Do NOT use this skill to drag-drop components onto site pages, edit branding panels, configure theme colors, create new pages in Builder, or wire up nav menus via the Builder UI. Every one of those is expressible as ExperienceBundle / Network / NavigationMenu / Profile / BrandingSet metadata — see `sf-nonprofit-experience-cloud-build`. Builder UI is iframe-wrapped and shadow-DOM heavy; each interaction takes 5-15 nested selector lookups and nothing survives a release. Metadata API achieves the same state in ~10 minutes of JSON editing. If you find yourself writing Playwright selectors for Builder, stop and author the ExperienceBundle instead.
6. **Ignoring the USAGE log.** USAGE.md is the data source for CLI feature requests. Every successful / healed / failed run gets a row. Skipping entries hides recurring patterns.
7. **Single-shot non-reusable scripts.** Scripts must be saved to the library so the next session replays instead of regenerating. Throwaway one-offs defeat the self-heal loop.
8. **Missing screenshots on failure.** `screenshot: 'on'` at the config level, not `'only-on-failure'` — we want the full sequence so the human can see where the UI diverged, not just the crash frame.
9. **Running codegen against prod.** Codegen recording is fine against a sandbox; against prod it risks recording real clicks with real side-effects. Codegen = sandbox only.
10. **Hardcoding `instanceUrl`.** Every script must pull `instanceUrl` from `sf org display --target-org <alias> --json` at runtime. Hardcoded domains break when scripts are replayed against a different org.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| `TimeoutError: locator.waitFor` on previously-working step | Salesforce updated Lightning markup this release | Run self-heal (Phase 3). Bump `docs_last_verified` in the script header. If heal fails twice, escalate. |
| `net::ERR_ABORTED` at `instanceUrl` | SFDX session token expired | Re-auth: `sf org login web --alias <alias>`, regenerate storageState. |
| Step 1 loads Salesforce login page (not Setup) | storageState cookie domain mismatch (My Domain vs `.my.salesforce.com`) | Re-derive domain from `new URL(instanceUrl).hostname`. Confirm storageState.cookies[0].domain matches. |
| `Frame detached` during Experience Builder drag-drop | Builder iframe reloaded mid-action | Wrap drag-drop in `page.waitForSelector(iframe)` + retry. Set `actionTimeout: 30_000` for Builder specs. |
| Agent publish button visible but disabled | Draft has validation errors not rendered yet | Before click, wait for `page.getByRole('status', { name: /ready/i })`. Screenshot page state first to confirm. |

---

## 8. Playwright + Salesforce selector cheat sheet

### Setup / global

```typescript
// Setup gear icon (top right)
page.getByRole('link', { name: 'Setup' })

// Setup quick-find (left nav)
page.getByPlaceholder('Quick Find')

// Form field by associated label (preferred over CSS for inputs)
page.getByLabel('Label Text')

// Save button (most Setup pages)
page.getByRole('button', { name: 'Save' })

// Edit button (list views, record pages)
page.getByRole('button', { name: 'Edit', exact: true })

// Confirm modal "Yes"
page.getByRole('button', { name: /^(Yes|Confirm|OK)$/ })
```

### Agent Builder

```typescript
// Navigate to Agent Builder for a specific agent
await page.goto(`${instanceUrl}/lightning/setup/EinsteinCopilot/agents/<agentApiName>/edit`);

// Publish button (top right toolbar)
page.locator('[data-aura-class="forceAgentBuilderToolbar"]').getByRole('button', { name: 'Publish' })

// Activation toggle
page.getByRole('switch', { name: /active/i })

// Topic list
page.locator('lightning-tree-item:has-text("Topics")')

// Add action to topic
page.getByRole('button', { name: 'New', exact: true })
```

### Prompt Builder

```typescript
// Prompt Template list
await page.goto(`${instanceUrl}/lightning/setup/EinsteinGptStudio/home`);

// Activate button on a template detail page
page.getByRole('button', { name: 'Activate' })

// Versions dropdown
page.getByRole('button', { name: /Version \d+/ })
```

### Experience Builder

```typescript
// Open Experience Builder for a site (requires site Id)
await page.goto(`${instanceUrl}/sfsites/picasso/core/config/commeditor.apexp?servletPath=/s/&siteId=<siteId>`);

// Publish site
page.getByRole('button', { name: 'Publish' })

// Component palette drag source
page.locator('[data-aura-class="communityDesigner"] [data-component-name="<lwcName>"]')

// Drop target (canvas region)
page.locator('[data-region-name="content"]')
```

### Data Cloud home / admin

```typescript
// Data Cloud home
await page.goto(`${instanceUrl}/lightning/n/standard-DataCloudSetup`);

// Enable feature toggle
page.getByRole('switch', { name: /Enable .*/i })
```

### Einstein activation

```typescript
// Einstein setup node
await page.goto(`${instanceUrl}/lightning/setup/EinsteinSetupHome/home`);

// Turn on Einstein
page.getByRole('button', { name: 'Turn on Einstein' })
```

### Licensing / feature activation

```typescript
// Company Information
await page.goto(`${instanceUrl}/lightning/setup/CompanyProfileInfo/home`);

// Permission set license assignments
await page.goto(`${instanceUrl}/lightning/setup/PermSetLicenseAssignment/home`);
```

Prefer this table over codegen for known Setup paths — these selectors are stable across releases because they target accessible names, not internal markup.

---

## 9. Safety section

### Default mode: read-only

Every script runs in **read-only** mode unless the caller passes `--write`. Read-only means:

- Navigate to pages, read values, take screenshots
- No `click()` on `button[name=~/Save|Publish|Activate|Delete/]`
- No `fill()` or `selectOption()`

### Write mode on sandboxes

`--write` enables writes on sandboxes with a single-line confirmation:

```
About to perform WRITE action on sandbox <alias> (<instanceUrl>): Publish agent 'Volunteer_Intake'. Proceed? [y/N]
```

Default `N`. User types `y` to proceed.

### Write mode on prod

Prod orgs require the `--write` flag **AND** typed confirmation of the exact string:

```
⚠ PRODUCTION ORG detected: <alias> (<instanceUrl>)
About to perform WRITE action: Publish agent 'Volunteer_Intake'.
This action is NOT reversible via this script.
Type YES-I-UNDERSTAND-PROD to proceed:
```

Anything other than that exact string aborts. No "y", no "yes", no exceptions.

### Script header template

Every saved script starts with:

```typescript
/**
 * Task: Publish the Volunteer Intake agent
 * Generated: 2026-05-01
 * Last verified: 2026-05-01
 * Org: <alias> (sandbox)  [or: production]
 * CLI checks performed (all negative):
 *   - sf commands | grep -i agent publish   → no match
 *   - sf metadata describe | grep -i Agent  → only .genAiPlugin (draft, no publish)
 *   - Tooling API EntityDefinition          → no publish entity
 * Write flag required: yes
 * Heal count: 0
 */
```

This header is read by `refresh-skills.sh` and the Usage Log parser, so keep the field names exact.

---

## 10. Post-run checklist

After every successful run:

- [ ] Script saved to `.claude/playwright-fallbacks/<task-name>.spec.ts`
- [ ] Screenshots saved to `.claude/playwright-fallbacks/results/<task-name>-<timestamp>/`
- [ ] Row appended to `.claude/playwright-fallbacks/USAGE.md`
- [ ] HTML report reviewed (for first-time generations or heals)
- [ ] If heal count ≥ 3 on this script across runs → file a CLI feature request with the task + selector diff
- [ ] If the same task type appears ≥ 3 times in USAGE.md → file a CLI feature request

The long-term goal is for this library to **shrink**, not grow. Every entry in USAGE.md is a question: "why doesn't the CLI do this yet?"
