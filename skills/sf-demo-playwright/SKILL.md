---
name: sf-demo-playwright
description: >
  Persistent Playwright test suite and human presenter guide generator.
  Reads a demoscript.md and generates: (1) a reusable Playwright test
  file per demo step, (2) an HTML visual report with screenshots at each
  step, and (3) an annotated presenter guide with embedded screenshots
  and talking points. The test suite runs as a pre-flight check before
  every demo session to confirm nothing has broken.
  TRIGGER when: user asks to "generate Playwright tests from a demoscript",
  "create a demo test suite", "build a presenter guide", "automate
  screenshot validation", "run pre-flight demo checks", "make a demo
  preflight spec", "generate demo-preflight.spec.js", "build a presenter
  walkthrough with screenshots", or "validate the demo script end-to-end
  with Playwright"; or references a `demoscript.md` and wants an
  automated click-path test suite.
  DO NOT TRIGGER when: reactive UI fallback for a CLI dead-end mid-task
  (use sf-ui-fallback-playwright — that is self-healing on-demand Playwright,
  this is proactive pre-flight suite authoring), one-off demo validation
  without generating a test suite (use sf-demo-validate), authoring a new
  demoscript from notes (use sf-demo-author), seeding demo data (use
  sf-nonprofit-demo-data or sf-demo-data), orchestrating the full
  notes-to-presenter pipeline (use sf-demo-orchestrate), or writing
  production Apex/LWC Jest tests (use sf-apex, sf-lwc).
license: MIT
metadata:
  version: "1.0.0"
  author: "Brian Miller"
  scoring: "120 points across 5 categories"
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
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://playwright.dev/docs/release-notes
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric in this SKILL.md (Scoring Rubric section), mapped onto the 4-dimension Phase 7 rubric from skill-eval-harness-SPEC.md §16"
  hard_fail_dimensions: [Test_Coverage, Visual_Fidelity, Presenter_Clarity, Resilience]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  phase7_dimensions:
    - name: Test_Coverage
      max: 25
      hard_fail_below: 15
      description: "Every step in click-path.json (from upstream Phase 4) has a corresponding Playwright assertion. A test suite that skips steps cannot be a pre-flight check — by definition it misses the regression it was built to catch."
      automatic_hard_fail_rules:
        - "Any step in click-path.json with no corresponding describe/test block in the generated Playwright spec"
        - "Any step's expected_visible[] array with no corresponding assertion in the generated test"
    - name: Visual_Fidelity
      max: 25
      hard_fail_below: 12
      description: "Screenshots at each step match what the demoscript claims will be shown. The audience-facing screenshots in the presenter guide must reflect actual Salesforce state, not stale captures or wrong screens."
    - name: Presenter_Clarity
      max: 25
      hard_fail_below: 10
      description: "Talking points reference what's visible on the screenshot, not abstract concepts. Each step's narration ties to specific UI elements the presenter will point at."
    - name: Resilience
      max: 25
      hard_fail_below: 13
      description: "Tests handle Salesforce UI lag, async loads, auth re-prompts, and timeout-prone operations. A pre-flight check that fails on transient UI delay is worse than no check — it cries wolf."
      automatic_hard_fail_rules:
        - "Any test using brittle selectors (text content matchers without role/label fallbacks) for elements that change between Salesforce releases"
        - "Any test missing explicit wait_for / wait_until on async-load elements (lightning-record-form, related lists, dynamic UIs)"
---

# sf-demo-playwright: Demo Test Suite and Presenter Guide Generator

Expert demo automation engineer. Converts a `demoscript.md` click path into a persistent, reusable Playwright test suite that runs before every demo session as a pre-flight check, and generates an annotated presenter guide with embedded screenshots so whoever is presenting can follow the same path and see exactly what they should see.

## Core Responsibilities

1. **Test Suite Generation**: One Playwright test file per demo step, organized as a single spec file
2. **Screenshot Capture**: Capture and store screenshots at every visual step
3. **HTML Report Generation**: Build a visual pass/fail report with screenshots after each test run
4. **Presenter Guide Generation**: Annotated Markdown/HTML guide with screenshots + talking points
5. **Pre-flight Check Script**: Shell script that runs the full suite before a demo session
6. **Failure Diagnosis**: When tests fail, emit a clear diagnosis and delegate fixes to `sf-demo-validate`

---

## Scoring Rubric (120 points)

| Category | Points | What's Evaluated |
|---|---|---|
| Test coverage | 30 | Every demoscript step has at least one test assertion |
| Screenshot fidelity | 25 | Visual steps produce useful, labeled screenshots |
| Report clarity | 20 | HTML report is readable and actionable for a non-developer |
| Presenter guide usability | 30 | Guide is self-contained -- a presenter can follow it cold |
| Pre-flight reliability | 15 | Suite completes in < 5 minutes and has clear pass/fail output |

**Thresholds**: ✅ 96+ (Ship it) | ⚠️ 72–95 (Review) | ❌ <72 (Rework required)

---

## Document Map

| Need | Document | Description |
|---|---|---|
| **Test patterns** | [references/test-patterns.md](references/test-patterns.md) | Playwright selector patterns for Salesforce UI elements |
| **Report template** | [references/report-template.md](references/report-template.md) | HTML report structure and screenshot embedding |
| **Pre-flight script** | [scripts/preflight.sh](scripts/preflight.sh) | Shell script to run suite + open report before a demo |
| **Playwright config** | [scripts/playwright.config.js](scripts/playwright.config.js) | Base Playwright configuration for Salesforce orgs |
| **Eval harness (pilot)** | [skills-cursor/sf-skill-eval-harness/SKILL.md](../../skills-cursor/sf-skill-eval-harness/SKILL.md) | Three-agent adversarial loop verifying test suite + presenter guide. See "Eval Harness Wrap" section below. |

---

## Eval Harness Wrap

When `eval_harness.enabled: true` (set in frontmatter above), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md) — a separate skill that owns the orchestration of planner / implementer / evaluator subagents and grades the generated test suite + presenter guide in fresh context against `click-path.json` from the upstream Phase 4.

**This skill provides the rubric (the 120-pt scoring section below, mapped onto the 4-dimension Phase 7 rubric in `skill-eval-harness-SPEC.md` §16) and the test-generation playbook (the 4-phase workflow below). The harness skill provides the loop control and adversarial evaluation.**

The 4-phase workflow is **unchanged** by the harness — it's what the implementer subagent executes. Only the surrounding evaluation flow changes:

- The harness skill spawns a fresh evaluator subagent (no memory of prior iterations) to verify the generated Playwright spec independently. The evaluator parses the spec file directly, cross-checks every `click-path.json` step against a corresponding test block, and runs the test suite headless against the connected org to confirm it actually passes.
- Hard-fail floors block SHIP regardless of total score. **Test_Coverage** (a pre-flight check missing a step is worthless) and **Resilience** (a flaky pre-flight cries wolf) carry the heaviest enforcement at floors 15 and 13.
- The harness writes structured handoffs in `.eval-harness/` so artifacts can't drift between iterations.

### How the harness composes with this skill

| What | Owned by |
|---|---|
| 120-pt scoring rubric | This skill ("Scoring Rubric" section below) |
| 4-dimension Phase 7 rubric mapping | This skill's frontmatter `phase7_dimensions` block |
| 4-phase implementer workflow (Demoscript Parsing → Test Suite Generation → HTML Report → Presenter Guide) | This skill ("Workflow" section below) |
| Playwright config, selector best practices, screenshot scripts | This skill (existing references) |
| Three-agent loop control (SHIP / ITERATE / SPEC-DEFECT verdicts, hard-fail floors, replan budget) | sf-skill-eval-harness |
| Subagent prompts (planner / implementer / evaluator) | sf-skill-eval-harness/prompts/ |
| Append-only TRACE.md primary debugging loop | sf-skill-eval-harness |

### Critical evaluator checks for Phase 7

The evaluator runs four deterministic verifications:

1. **Coverage probe** — for every step in `click-path.json`, locate a corresponding test block in the generated Playwright spec. Missing test = Test_Coverage hard-fail.
2. **Expected-visible probe** — for every `expected_visible[]` entry on every step, locate a matching assertion in the test (e.g., `expect(page.locator(...)).toContainText("...")`). Missing assertion = Test_Coverage hard-fail.
3. **Resilience probe** — scan the spec for brittle patterns: text-content-only selectors on dynamic UI, missing `await` on async operations, missing `waitFor` on lightning-component renders. Each instance = Resilience -1; persistent patterns = Resilience hard-fail.
4. **Live-run probe** — execute the spec headless against the connected org. Any test failing on its first run = candidate hard-fail (might indicate genuine breakage OR a flaky test); evaluator decides which.

### Disabling the harness

Set `eval_harness.enabled: false` in this skill's frontmatter (or remove the `eval_harness:` block entirely). The 4-phase workflow runs as before with no harness wrap.

See [the harness skill's SKILL.md](../../skills-cursor/sf-skill-eval-harness/SKILL.md) for the full orchestration playbook.

---

## Workflow (4-Phase Pattern)

### Phase 1: Demoscript Parsing

Read the `demoscript.md` and extract:

1. **Org credentials** from frontmatter (`org_alias`) -- used to get the login URL via `sf org display`
2. **All steps** with their type, action, expected outcome, visual flag, and visual_path
3. **Persona user aliases** -- each visual step should be captured as the correct demo user
4. **Check blocks** -- SOQL/Apex checks become test assertions

**Auth setup**:
```javascript
// Get org access token and URL from sf CLI
const { execSync } = require('child_process');
const orgInfo = JSON.parse(execSync('sf org display --target-org [alias] --json').toString());
const { instanceUrl, accessToken } = orgInfo.result;
```

---

### Phase 2: Test Suite Generation

Generate a single Playwright spec file: `demo-preflight.spec.js`

**File structure**:
```javascript
// demo-preflight.spec.js
// Auto-generated by sf-demo-playwright from demoscript.md
// Run: npx playwright test demo-preflight.spec.js

const { test, expect } = require('@playwright/test');
const { getSalesforceSession } = require('./helpers/sf-auth');

test.describe('[Demo Title] Pre-flight Checks', () => {

  test.beforeAll(async ({ browser }) => {
    // Authenticate via sf CLI session cookie injection
  });

  // One test block per demoscript step
  test('Step 1: [Step Title]', async ({ page }) => {
    // ...
  });

});
```

**Test block patterns** by step type:

`navigation`:
```javascript
test('Step 1: Open the Volunteer Hub App', async ({ page }) => {
    await page.goto(`${instanceUrl}/lightning/app/Acme_Volunteer_Hub`);
    await expect(page).toHaveTitle(/Volunteer Hub/);
    await page.screenshot({ path: 'screenshots/step-01-volunteer-hub.png', fullPage: false });
});
```

`data`:
```javascript
test('Step 3: View James Okafor Application', async ({ page }) => {
    // Navigate to the record
    const appId = await getRecordId('IndividualApplication__c',
        "FirstName__c = 'James' AND LastName__c = 'Okafor'");
    await page.goto(`${instanceUrl}/lightning/r/IndividualApplication__c/${appId}/view`);

    // Assert expected field values
    await expect(page.locator('[data-field="Status__c"]')).toContainText('Submitted');
    await expect(page.locator('[data-field="LastName__c"]')).toContainText('Okafor');

    await page.screenshot({ path: 'screenshots/step-03-james-application.png' });
});
```

`automation`:
```javascript
test('Step 5: Verify Intake Flow is Active', async ({ page }) => {
    // SOQL assertion via sf data query
    const result = JSON.parse(execSync(
        `sf data query --query "SELECT IsActive FROM FlowDefinitionView WHERE ApiName = 'Acme_Volunteer_Intake' AND IsActive = true" --json --target-org ${orgAlias}`
    ).toString());
    expect(result.result.totalSize).toBeGreaterThan(0);
});
```

`experience` (Experience Cloud):
```javascript
test('Step 7: Guest Portal Loads', async ({ page }) => {
    const portalUrl = await getExperienceSiteUrl('Acme_Volunteer_Hub1');
    await page.goto(portalUrl);
    await expect(page.locator('h1, .siteforceContentArea')).toBeVisible();
    await page.screenshot({ path: 'screenshots/step-07-guest-portal.png', fullPage: true });
});
```

`e2e_simulation`:
```javascript
test('Step 8: E2E Intake Form Submission', async ({ page }) => {
    // Navigate to guest intake form
    await page.goto(`${portalUrl}/volunteer-apply`);

    // Fill form as James Okafor
    await page.fill('[name="firstName"]', 'James');
    await page.fill('[name="lastName"]', 'Okafor');
    await page.fill('[name="email"]', 'james.okafor@demo.volunteer');
    await page.selectOption('[name="volunteerType"]', 'Tutor');
    await page.click('button[type="submit"], .slds-button:has-text("Submit")');

    // Assert confirmation
    await expect(page.locator('.confirmation, [class*="success"]')).toBeVisible();
    await page.screenshot({ path: 'screenshots/step-08-intake-confirmation.png' });

    // Verify record created in Salesforce
    await new Promise(r => setTimeout(r, 3000)); // allow trigger to fire
    const count = JSON.parse(execSync(
        `sf data query --query "SELECT COUNT() FROM IndividualApplication__c WHERE Email__c = 'james.okafor@demo.volunteer' AND CreatedDate = TODAY" --json --target-org ${orgAlias}`
    ).toString());
    expect(count.result.totalSize).toBeGreaterThan(0);
});
```

---

### Phase 3: HTML Report Generation

After the test run, Playwright generates an HTML report. Augment it with:

1. **Screenshot thumbnails** next to each test result
2. **Demo step context** (the Action and Expected from the demoscript) above each test
3. **Pass/Fail summary** at the top: "8/9 steps passed. 1 issue requires attention."
4. **Fix instructions** for any failed step, with the delegating skill noted

**Playwright HTML reporter config** (`playwright.config.js`):
```javascript
module.exports = {
  reporter: [
    ['html', { outputFolder: 'demo-report', open: 'never' }],
    ['list']
  ],
  use: {
    screenshot: 'on',
    video: 'retain-on-failure',
    trace: 'retain-on-failure'
  }
};
```

---

### Phase 4: Presenter Guide Generation

Generate `PRESENTER-GUIDE.md` -- a human-readable document the presenter uses on demo day.

**Structure**:

```markdown
# [Demo Title] — Presenter Guide
Generated: [date]  |  Org: [alias]  |  Last validated: [date]

## Quick Reference
| Step | Title | Persona | Time |
|---|---|---|---|
| 1 | Open Volunteer Hub | Maria Santos | ~30s |
| 2 | Review Applications | Maria Santos | ~45s |
...

## Demo Opening
> Read aloud before Step 1:
> "Meet Maria. She's a Volunteer Coordinator at By The Hand Club. 
>  Every week she matches dozens of volunteers with kids who need them.
>  Before Salesforce, that meant emails and spreadsheets. Let's see
>  what a Monday morning looks like now."

---

## Step 1: Open the Volunteer Hub App

![Step 1 Screenshot](screenshots/step-01-volunteer-hub.png)

**You do**: Click the App Launcher (grid icon, top left). Type "Volunteer Hub". Click "Acme Volunteer Hub".

**You see**: The Volunteer Hub home page with the Application list view showing recent submissions.

**Say**:
> "This is Maria's starting point every morning. Everything she needs is right here — 
>  no toggling between systems."

---
[repeat for each step]

## Demo Closing
> Say after the final step:
> "Maria just reviewed James's application, matched him to a shift, and sent 
>  him a confirmation — in under 5 minutes. The kids at that tutoring session
>  on Thursday will have the right volunteer. That's what this looks like."
```

---

## Pre-flight Script

Generate `scripts/preflight.sh` -- run this before every demo session:

```bash
#!/bin/bash
# Demo Pre-flight Check
# Usage: ./scripts/preflight.sh [org-alias]

ORG=${1:-my-demo-org}
echo "🔍 Running pre-flight checks for $ORG..."
echo ""

# 1. Verify org auth
sf org display --target-org $ORG --json > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Not authenticated. Run: sf org login web --alias $ORG"
  exit 1
fi
echo "✅ Org authenticated"

# 2. Run Playwright suite
npx playwright test demo-preflight.spec.js --reporter=list
if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Pre-flight FAILED. Open demo-report/index.html for details."
  echo "   Run sf-demo-validate to auto-repair issues."
  exit 1
fi

echo ""
echo "✅ All pre-flight checks passed. You're ready to demo."
echo "📋 Presenter guide: PRESENTER-GUIDE.md"
echo "📸 Screenshots: screenshots/"
```

---

## Failure Handling

When a Playwright test fails, determine the cause and delegate:

| Failure type | Delegate to | Example |
|---|---|---|
| Page not found / 404 | `sf-demo-validate` → `sf-nonprofit-experience-cloud` | Experience Cloud site down |
| Field value wrong | `sf-demo-validate` → `sf-nonprofit-demo-data` | Stale demo data |
| Element not visible | `sf-demo-validate` → `sf-lwc` | Component not deployed |
| Flow not active | `sf-demo-validate` → `sf-flow` | Automation inactive |
| Auth / permission error | `sf-demo-validate` → `sf-permissions` | Permission set missing |
| Form submission failed | `sf-demo-validate` → `sf-apex` | Trigger or controller error |

Always emit: "Step [N] failed: [what was expected] vs [what was found]. Recommend running `sf-demo-validate` to auto-repair."
