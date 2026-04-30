---
name: sf-demo-validate
description: >
  Autonomous demo script validation and repair for Salesforce orgs with 200-point scoring.
  Covers platform prerequisites, metadata, data quality, permissions (including content),
  automations, visual UI, Experience Cloud sites, end-to-end user simulation,
  and product-specific validation for Agentforce, Data Cloud, Slack, Marketing Cloud,
  Tableau/CRM Analytics, and OmniStudio.
  TRIGGER when: user says "validate demo", "check demo script", "demo not working",
  "fix demo", "run demoscript", or references a demoscript.md / demo-script file,
  or asks to verify a Salesforce demo environment is ready. Also triggers when
  user says "is the demo ready", "does this demo still work", or "verify the demo".
  DO NOT TRIGGER when: writing Apex code (use sf-apex), deploying metadata only
  (use sf-deploy), running Apex tests only (use sf-testing), or building demo
  data without a script (use sf-data).
license: MIT
metadata:
  version: "3.0.0"
  scoring: "200 points across 10 categories"
---

# sf-demo-validate: Autonomous Demo Script Validation & Repair

Expert Salesforce demo environment engineer specializing in end-to-end validation of demo paths, autonomous issue detection, and iterative repair using the full sf-* skill ecosystem.

## Core Responsibilities

1. **Format Standardization**: Define and enforce a structured demoscript.md format for repeatable validation
2. **Org Connection Verification**: Confirm sf CLI auth, org type, and prerequisite packages/features
3. **Platform Prerequisite Verification**: Verify org-level features the demo depends on (Person Accounts, Record Types, queues, custom fields)
4. **End-to-End Validation**: Check metadata, data, permissions, automations, components, and integrations for every demo step
5. **Data Quality & Freshness**: Verify demo data is complete, correctly populated, future-dated, and free of stale test artifacts
6. **Permission Content Validation**: Verify permission sets grant the specific Apex class access, object/field access, and Experience site membership the demo requires
7. **Visual Validation**: Screenshot Salesforce pages via Playwright and visually verify UI matches expected state
8. **Experience Cloud Validation**: Verify public guest site and logged-in member site render correctly with live data; HTTP-ping the public URL
9. **E2E User Simulation**: Execute ALL transactional demo paths (intake form submission AND shift sign-up) as specific demo users via Anonymous Apex
10. **Autonomous Repair**: Fix failing steps by delegating to the appropriate sf-* skill -- no user intervention required
11. **Iterative Re-Validation**: Loop fix-then-validate up to 3 times until all steps pass or escalate
12. **Completion Reporting**: Produce a scored pass/fail summary with details on every step

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Demoscript format** | [references/demoscript-format.md](references/demoscript-format.md) | Full format spec, YAML schema, step types, annotated examples |
| **Validation checks** | [references/validation-checks.md](references/validation-checks.md) | Validation strategy and commands per step type |
| **Fix strategies** | [references/fix-strategies.md](references/fix-strategies.md) | Fix patterns per issue type, cross-skill delegation rules |
| **Starter template** | [assets/demoscript-template.md](assets/demoscript-template.md) | Blank demoscript.md users can copy and fill in |
| **Screenshot script** | [scripts/screenshot.js](scripts/screenshot.js) | Playwright utility for headless page screenshots |

---

## Demoscript.md Format (Overview)

> Full spec with annotated examples: [references/demoscript-format.md](references/demoscript-format.md)

A demoscript.md has four sections:

1. **YAML Frontmatter** -- title, org alias, org type, required features/packages
2. **Prerequisites** -- data, users, config that must exist before the demo starts
3. **Demo Steps** -- ordered steps with action, expected outcome, and optional explicit check
4. **Teardown** (optional) -- cleanup instructions after the demo

Each step may include a `type` hint to direct the validation strategy:

| Type | Validates |
|------|-----------|
| `navigation` | App, tab, page, or record page exists and is accessible |
| `data` | Records exist with expected field values (SOQL) |
| `metadata` | Objects, fields, record types, page layouts exist |
| `automation` | Flows, triggers, or process builders are active and fire correctly |
| `permission` | User/profile/permission set grants the required access |
| `component` | LWC or Aura components are deployed |
| `integration` | Named credentials, external services, or connected apps are configured |
| `experience` | Experience Cloud site renders correctly for guest and/or member users |
| `e2e_simulation` | Controller-level flow executes successfully as a specific demo user (shift sign-up) |
| `intake_simulation` | Guest intake form submission creates ApplicationForm + Applicant + Person Account + Task |
| `dashboard` | Reports, report types, and dashboards exist and display data |
| `agentforce` | Agent Builder config: topics, actions, PromptTemplates, GenAI plugins deployed and active |
| `data_cloud` | Data streams, DMOs, identity resolution, segments, activations configured and healthy |
| `slack` | Slack integration: connected app, channel configs, Slack workflows, bot user provisioned |
| `marketing_cloud` | MC connector installed, journeys configured, email templates exist, audiences synced |
| `tableau_analytics` | CRM Analytics (Tableau) apps, datasets, dataflows, dashboards, lenses deployed with data |
| `omnistudio` | OmniScripts, FlexCards, Integration Procedures, Data Mappers deployed and active |

When no type is given, the skill infers the appropriate strategy from the step description.

---

## Workflow (7 Phases)

### Phase 1: Parse

Read the demoscript.md file and extract:
- YAML frontmatter (org alias, org type, features, packages)
- Prerequisites (list of preconditions)
- Demo steps (ordered, with action + expected outcome + optional check)
- Teardown instructions (if present)

Normalize each step's type. If the step has no explicit `type`, infer it from keywords:
- "navigate", "open", "click tab", "go to" --> `navigation`
- "record", "field value", "shows", "displays data" --> `data`
- "object", "field", "layout", "record type" --> `metadata`
- "flow", "trigger", "automation", "fires", "runs automatically" --> `automation`
- "access", "permission", "profile", "can see", "visibility" --> `permission`
- "component", "LWC", "lightning", "custom UI" --> `component`
- "API", "callout", "credential", "external", "connected app" --> `integration`
- "Experience", "community", "portal", "site", "guest", "public site" --> `experience`
- "sign up", "shift sign-up", "register for shift", "end-to-end", "as [UserName]", "log in as" --> `e2e_simulation`
- "apply", "intake", "application form", "applicant", "submit volunteer", "guest form" --> `intake_simulation`
- "dashboard", "report", "chart", "metric" --> `dashboard`
- "agent", "Agentforce", "topic", "action", "PromptTemplate", "GenAI", "copilot" --> `agentforce`
- "Data Cloud", "data stream", "DMO", "identity resolution", "segment", "activation", "data space" --> `data_cloud`
- "Slack", "channel", "Slack workflow", "bot", "Slack app" --> `slack`
- "Marketing Cloud", "journey", "email template", "MC connector", "audience sync", "Account Engagement" --> `marketing_cloud`
- "CRM Analytics", "Tableau", "TCRM", "dataflow", "dataset", "lens", "analytics dashboard", "recipe" --> `tableau_analytics`
- "OmniScript", "FlexCard", "Integration Procedure", "Data Mapper", "DataRaptor", "OmniStudio" --> `omnistudio`

### Phase 2: Connect & Platform Prerequisites

```bash
sf org display --target-org [alias] --json
```

Verify:
1. Org is authenticated and accessible
2. Org type matches frontmatter (scratch, sandbox, production)
3. Required features are enabled (query `Organization` or feature-specific objects)
4. Required packages are installed:
```bash
sf package installed list --target-org [alias] --json
```

**STOP if org is unreachable.** All subsequent phases require a live connection.

After org connection, run **platform prerequisite checks** (these are features the demo depends on that are deeper than packages):

5. **Person Accounts enabled** — query `RecordType WHERE SobjectType = 'Account' AND IsPersonType = true`. If 0 rows, the demo cannot function.
6. **NPC objects exist** — verify `ApplicationForm`, `Applicant`, `JobPosition`, `JobPositionShift`, `JobPositionAssignment` via `EntityDefinition`
7. **ApplicationForm "Programs" Record Type** — query `RecordType WHERE SobjectType = 'ApplicationForm' AND DeveloperName IN ('Programs','Program','NPC_Programs') AND IsActive = true`. The intake controller throws if missing.
8. **Custom fields on NPC objects** — verify `Description__c` on `ApplicationForm` (used by `VolunteerIntakeService`)
9. **Volunteer_Review queue** — query `Group WHERE Type = 'Queue' AND DeveloperName = 'Volunteer_Review'`. The applicant trigger creates Tasks owned by this queue.
10. **Provisioner script exists** — verify `scripts/apex/provision-demo-member.apex` exists in the local project

> Full prerequisite checks: [references/validation-checks.md](references/validation-checks.md)

### Phase 3: Validate

For each demo step, run the appropriate check based on step type.

> Full command reference per type: [references/validation-checks.md](references/validation-checks.md)

Summary of validation strategies:

| Type | Primary Check |
|------|---------------|
| `navigation` | SOQL on `TabDefinition`, `CustomTab`, or `FlexiPage`; verify app tab configuration |
| `data` | `sf data query --query "SELECT ..." --target-org [alias]` + data quality checks (completeness, freshness, stale artifacts) |
| `metadata` | SOQL on `EntityDefinition`, `FieldDefinition`, `RecordType` + Apex compilation health |
| `automation` | SOQL on `FlowDefinitionView` (IsActive), `ApexTrigger` |
| `permission` | SOQL on `PermissionSetAssignment`, `FieldPermissions`, `ObjectPermissions` + **perm set content validation** (Apex class access, network member groups) |
| `component` | `sf project retrieve start --metadata LightningComponentBundle:[name]` |
| `integration` | SOQL on `NamedCredential`, `ExternalServiceRegistration`, `ConnectedApplication` |

Record each step result as PASS or FAIL with diagnostic detail.

#### Experience Cloud Validation

If a step has type `experience`, validate the public site and/or member site:

1. **Resolve the Experience site URL** from Network/Site records in the org
2. **Guest validation**: Use Playwright to load the public URL (no auth cookies) and verify:
   - The page renders without errors
   - Expected LWC components appear (catalog cards, shift details, forms)
   - Live data from the org is visible (program names, shift dates, locations)
3. **Member validation**: Use the frontdoor.jsp URL from `sf org open --url-only` redirected to the Experience site to load the authenticated member view, then verify:
   - The logged-in header/nav is visible
   - Member-specific features are accessible (e.g., sign-up buttons, my shifts)
4. Record PASS/FAIL with screenshots

> Full Experience Cloud validation workflow: [references/validation-checks.md](references/validation-checks.md)

#### E2E User Simulation (Multi-User)

If a step has type `e2e_simulation`, execute the demo flow as the specified demo user. The skill supports **three approaches** for multi-user testing, selected based on what the step requires:

**Approach A — Admin-Context Data Simulation** (default, always available):
Anonymous Apex that manually walks the same logic the controller uses. Tests the *data path* (record resolution, DML, side effects) but runs as the admin user. Suitable for verifying data integrity and automation chains.

**Approach B — Deployed Test Class with `System.runAs()`** (permission testing):
Deploy a temporary `@IsTest` class that uses `System.runAs(demoUser)` to call the actual `@AuraEnabled` controller methods. This tests the *real permission context* — whether the user's perm set, sharing rules, and FLS allow the operation. The test class is deployed, executed via `sf apex run test`, and cleaned up afterward.

**Approach C — REST API with User Session** (controller + permission testing):
Obtain a user-specific session via frontdoor.jsp or login-as, then call `@AuraEnabled` methods via the Aura/LWC REST endpoints. This tests the *actual controller call path* with the user's session context, including `UserInfo.getUserId()` resolution.

**CRITICAL**: `System.runAs()` does NOT work in Anonymous Apex — it only works inside `@IsTest` classes. The skill must use Approach A (data path) or Approach B (deploy test class) for user-context testing.

For each simulation:
1. **Resolve the demo user** by querying `User` by alias or username from the demoscript
2. **Verify user config** (TimeZoneSidKey, ContactId, IsActive, profile/perm sets)
3. **Check for stale data** from previous demo runs
4. **Execute the simulation** using the appropriate approach
5. **Verify outcomes**: Query for expected side-effects
6. **Rollback**: Delete any records created during testing
7. Record PASS/FAIL with details

> Full multi-user simulation patterns: [references/validation-checks.md](references/validation-checks.md)

#### Intake Form Simulation (Guest Apply)

If a step has type `intake_simulation`, execute the guest intake form submission end-to-end via Anonymous Apex:

1. **Call `VolunteerIntakeGuestController.submitVolunteer()`** with test data (use a test-prefix email like `e2e.test@example.com`)
2. **Verify ApplicationForm created** with RecordType = Programs, UsageType = Volunteer, ApplicationStatus = Submitted
3. **Verify Applicant created** with correct FirstName, LastName, Email, linked to the ApplicationForm
4. **Verify trigger chain fires**:
   - Person Account matched or created for the test email
   - Applicant.AccountId and Applicant.ContactId populated
   - ApplicationForm.AccountId linked to the same Person Account
   - Task created with Subject containing "New volunteer application" and OwnerId = Volunteer_Review queue
5. **Cleanup**: Delete Task, Applicant, ApplicationForm, and the test Person Account (in reverse order) to avoid cluttering the demo
6. Record PASS/FAIL with details on which trigger chain steps succeeded/failed

> Full intake simulation patterns: [references/validation-checks.md](references/validation-checks.md)

#### Flow Execution & Automation Chain Testing

Beyond checking that flows/triggers exist and are active, the skill **fires automations and verifies their side effects**:

1. **Record-triggered flows/triggers**: Insert or update a test record that matches the trigger criteria, then query for expected side effects (new child records, field updates, Tasks, emails). Clean up afterward.
2. **Screen flows via REST API**: Invoke the flow via `POST /services/data/v62.0/actions/custom/flow/[FlowApiName]` with test input variables, then verify outputs.
3. **Autolaunched/invocable flows**: Call via REST API or Anonymous Apex using `Flow.Interview.createInterview()`.
4. **Automation chain verification**: For multi-step chains (e.g., insert Applicant → trigger fires → Person Account created → Task created → Flow sends email), the simulation verifies each link in the chain, not just the final state.

**Example — Coordinator Status Update Chain** (Act 3):
- Update `ApplicationForm.ApplicationStatus` to `'Approved'`
- Verify a record-triggered flow fires (if configured)
- Verify downstream side effects (Task created, email sent, status propagated)
- Roll back the status change and clean up

> Full flow execution patterns: [references/validation-checks.md](references/validation-checks.md)

#### Coordinator Simulation (Internal User Path)

If the demo includes an internal coordinator workflow (e.g., "open app → view list → review record → update status"), simulate the coordinator's path:

1. **Verify app accessibility**: Confirm the coordinator's perm set grants access to the app and all tabs
2. **Verify list view data**: Query the same objects/list views the coordinator would see, verify expected records appear
3. **Verify record page data**: Open the same record the demo would show, verify all fields and related lists have data
4. **Simulate status update**: Update the record field the coordinator would change (e.g., ApplicationStatus → Approved), verify automation fires
5. **Roll back**: Restore the original field value to leave the demo in its pre-demo state

> Full coordinator simulation: [references/validation-checks.md](references/validation-checks.md)

#### Agentforce Validation

If a step has type `agentforce`, validate the agent configuration:

1. **Agent metadata exists**: Query for `GenAiPlugin` and `GenAiFunction` via Tooling API to verify the agent is deployed
2. **Topics and actions configured**: Verify each topic has at least one action, and actions reference valid Apex classes, Flows, or PromptTemplates
3. **PromptTemplates deployed**: Retrieve `PromptTemplate` metadata and verify it exists and references valid merge fields
4. **Agent testing** (optional): Delegate to `sf-ai-agentforce-testing` to run automated agent test specs if they exist in the project
5. **Agent activation**: Verify the agent channel (e.g., Experience Cloud, Slack) is configured and active

> Cross-skill delegation: sf-ai-agentforce (build), sf-ai-agentforce-testing (test), sf-ai-agentscript (FSM agents), sf-ai-agentforce-persona (persona review)

#### Data Cloud Validation

If a step has type `data_cloud`, validate the Data Cloud pipeline:

1. **Data streams active**: Use `sf data360 stream list` or REST API to verify streams are ingesting
2. **DMOs exist with mappings**: Query for Data Model Objects and verify field mappings are complete
3. **Identity resolution configured**: Verify rulesets and unified profiles are generating
4. **Segments published**: Verify segments are in "Published" status with non-zero member counts
5. **Activations configured**: Verify activation targets exist and are connected
6. **Data space verification**: Confirm the correct data space is selected for the demo context

> Cross-skill delegation: sf-datacloud (orchestrator), sf-datacloud-connect, sf-datacloud-prepare, sf-datacloud-harmonize, sf-datacloud-segment, sf-datacloud-act, sf-datacloud-retrieve

#### Slack Validation

If a step has type `slack`, validate the Salesforce-to-Slack integration:

1. **Slack connected app exists**: Query `ConnectedApplication` for the Slack app
2. **Slack integration package installed**: Check for Slack-related managed packages
3. **Channel configurations**: Verify Slack channel mappings exist (Custom Settings, Custom Metadata, or platform-specific config)
4. **Bot user provisioned**: Verify the Slack bot user exists in the org's user list
5. **Slack workflow/notification config**: Verify Flow or automation triggers that send to Slack are active

**Limitations**: Slack workspace-side validation (channel existence, bot permissions, workspace access) cannot be verified from the Salesforce org. These are escalated for manual verification.

#### Marketing Cloud Validation

If a step has type `marketing_cloud`, validate the Salesforce-to-MC connection:

1. **MC Connector installed**: Check installed packages for Marketing Cloud connector
2. **Connected App configured**: Query `ConnectedApplication` for MC-related apps
3. **Synchronized objects**: Verify MC-synced objects are configured and data is flowing
4. **Journey entry sources**: Verify the Salesforce objects/events that trigger MC journeys exist and have test data
5. **Email templates** (if in Salesforce): Verify `EmailTemplate` records referenced in the demoscript exist

**Limitations**: Marketing Cloud-side validation (journey builder status, email content, audience segments in MC) requires MC API access and is escalated. The skill validates the Salesforce half of the bridge.

#### Tableau / CRM Analytics Validation

If a step has type `tableau_analytics`, validate CRM Analytics (TCRM) assets:

1. **Analytics app exists**: Query `Folder` with `Type = 'Insights'` for the analytics app
2. **Datasets exist and have data**: Query `AnalyticsDataset` or use the Wave REST API to verify datasets are populated
3. **Dataflows active**: Query `AnalyticsDataflow` to verify dataflows are scheduled and have recent successful runs
4. **Dashboards/lenses deployed**: Query `AnalyticsDashboard` or `AnalyticsLens` for the expected assets
5. **Dashboard renders**: Use Playwright to screenshot the analytics dashboard URL and verify it renders with data (not empty charts)
6. **Recipes** (if applicable): Verify Data Prep recipes exist and have run successfully

> For Tableau Cloud/Server integrations, the skill validates the Salesforce-side embed configuration and Connected App but escalates Tableau-side verification.

#### OmniStudio Validation

If a step has type `omnistudio`, validate OmniStudio components:

1. **OmniScript deployed and active**: Query `OmniProcess` (or vlocity equivalent) for the specified OmniScript with `IsActive = true`
2. **FlexCards deployed**: Query `OmniUiCard` for the expected FlexCards
3. **Integration Procedures accessible**: Query for IPs and verify they are active and their data sources return data
4. **Data Mappers configured**: Verify `OmniDataTransform` records exist with correct field mappings
5. **Namespace detection**: Use sf-industry-commoncore-omnistudio-analyze to detect the namespace (Core vs vlocity_cmt vs vlocity_ins) and adjust queries accordingly

> Cross-skill delegation: sf-industry-commoncore-omniscript, sf-industry-commoncore-flexcard, sf-industry-commoncore-integration-procedure, sf-industry-commoncore-datamapper, sf-industry-commoncore-omnistudio-analyze

#### Dashboard Validation

If a step has type `dashboard`, validate reports and dashboards:

1. **Check report type existence** via Tooling API query on `ReportType`
2. **Check report existence** via SOQL on `Report`
3. **Check dashboard existence** via SOQL on `Dashboard`
4. **If metadata deployment of report types fails** (common with NPC/Industry objects), fall back to creation via Analytics REST API or Anonymous Apex
5. Record PASS/FAIL

> Full dashboard validation and fallback: [references/validation-checks.md](references/validation-checks.md)

#### Data Quality & Freshness

For every `data` step and as a cross-cutting concern, validate the *quality* of demo data beyond mere existence:

1. **Location data completeness**: At least 4 of 6 locations must have `Description`, `DrivingDirections`, and `TimeZone` populated. Missing data = empty modals during the demo.
2. **Shift date freshness window**: Warn if all shifts expire within 7 days. Warn if no shifts extend 30+ days out. At least 5 shifts must have `StartDate >= TODAY + 14` for comfortable scheduling.
3. **RemainingCapacity**: At least some shifts must have `RemainingCapacity > 0` (or NULL = unlimited). If all shifts show 0 remaining, the sign-up button won't appear.
4. **Stale demo data**: Check for and report old test artifacts that clutter the demo view:
   - `ApplicationForm` with test-prefix names or `[E2E_TEST]` markers
   - `JobPositionAssignment` records with stale `ScheduledStartTime` in the past
   - `Task` records from previous intake simulations
5. **Duplicate assignment prevention**: Verify Jamie doesn't have leftover `JobPositionAssignment` records from previous demo runs that would block new sign-ups.

> Full data quality checks: [references/validation-checks.md](references/validation-checks.md)

#### Permission Content Validation

Beyond checking permission sets exist and are assigned, validate their **contents**:

1. **Apex class access**: Verify each permission set grants access to the Apex classes listed in the demo script:
   - `Acme_Volunteer_Guest_Run_Intake_Flow` → `VolunteerExploreGuestController`, `VolunteerIntakeGuestController`, `VolunteerIntakeSubmitInvocable`
   - `Acme_Volunteer_Member_Demo` → all guest controllers + `VolunteerShiftSignupController`
   - `Acme_Volunteer_Coordinator` → coordinator-level class access
2. **Network member groups**: Verify the Experience site allows "Customer Community Plus Login User" under Members
3. **App tab configuration**: Verify `Acme Volunteer Demo` app contains the tabs listed in the demo script (Application Form, Applicant, Account, Job Position)

> Full permission content checks: [references/validation-checks.md](references/validation-checks.md)

#### Apex & Metadata Health

1. **Apex compilation check**: Query all project Apex classes for compilation status. A class can exist but have errors after a dependency change.
2. **Experience site URL reachability**: HTTP GET the public site URL and verify it returns 200 (not 403, 404, or 500)

> Full health checks: [references/validation-checks.md](references/validation-checks.md)

#### Visual Validation (Opt-In)

If a step includes a `**Visual**` block or a `<!-- visual: true -->` tag, take a screenshot after the SOQL/metadata checks:

1. Get an authenticated URL for the page described in the step:
```bash
sf org open --url-only --target-org [alias] --path "[lightning-path]" --json
```
2. Capture the page with Playwright:
```bash
node [skill-path]/scripts/screenshot.js "[url]" "screenshots/step-[n].png"
```
3. Read the saved PNG with the Read tool (which natively supports images)
4. Compare the visual to the `**Visual**` description or the `**Expected**` block
5. Record visual PASS or FAIL with a description of what looks wrong

Screenshots are saved to a `screenshots/` directory in the working directory. Visual failures are reported but not auto-fixed -- they require UI-level changes (Lightning App Builder, page layouts) that cannot be automated via CLI.

> Full visual validation workflow: [references/validation-checks.md](references/validation-checks.md)

### Phase 4: Report

Output a step-by-step status report:

```
DEMO VALIDATION REPORT: [Demo Title]
================================================================

Org: [alias] ([type])    Steps: [total]    Iteration: [n]/3

PREREQUISITES
----------------------------------------------------------------
[PASS] Package: ServiceCloud installed (v58.0)
[FAIL] Feature: Knowledge not enabled

DEMO STEPS
----------------------------------------------------------------
Step 1: [Title]                                          [PASS]
Step 2: [Title]                                          [FAIL]
  Issue: Custom object Invoice__c not found
  Type: metadata
Step 3: [Title]                                          [PASS]
Step 4: [Title]                                     [VISUAL FAIL]
  Issue: Record page missing Knowledge sidebar component
  Screenshot: screenshots/step-4.png
...

SUMMARY: [passed]/[total] steps passing
```

If all steps pass, skip to Phase 7.

### Phase 5: Fix

For each failing step, delegate to the appropriate sf-* skill.

> Full fix patterns and delegation rules: [references/fix-strategies.md](references/fix-strategies.md)

| Issue Type | Delegate To | Action |
|------------|-------------|--------|
| Platform prereq missing | sf-metadata + sf-deploy | Enable Person Accounts (escalate), create record types, queues, custom fields |
| Missing object/field | sf-metadata + sf-deploy | Generate XML, deploy |
| Missing data | sf-data | Insert records via sf CLI |
| Data quality / freshness | sf-data (Apex) | Update shift dates, populate location fields, clean stale test data |
| Missing permissions | sf-permissions + sf-deploy | Create/update permission set, deploy |
| Perm set content wrong | sf-permissions + sf-deploy | Add Apex class access to perm set XML, redeploy |
| Inactive flow | sf-flow + sf-deploy | Activate flow, deploy |
| Missing component | sf-lwc + sf-deploy | Check source, deploy bundle |
| Broken integration | sf-integration | Check named credential config |
| Apex errors / compilation | sf-apex + sf-deploy | Fix code, deploy |
| Dashboard/report type failure | sf-data (Apex) | Create via Analytics REST API or Anonymous Apex when metadata deploy fails |
| Experience site not rendering | sf-lwc + sf-deploy | Check component deployment, guest profile access, site publish status |
| Experience URL unreachable | -- (escalate) | Report URL status; may need `sf community publish` or DNS config |
| E2E simulation failure | sf-apex + sf-data | Fix controller logic, ensure data/permissions allow the flow |
| Intake simulation failure | sf-apex + sf-data | Fix intake controller/trigger/service, ensure RT + queue exist |
| Jamie timezone mismatch | sf-data | Update `User.TimeZoneSidKey` via CLI |
| Stale test data | sf-data (Apex) | Delete old test ApplicationForms, Applicants, Assignments |
| Network member groups wrong | -- (escalate) | Experience site membership requires Setup UI |
| Agentforce agent missing/broken | sf-ai-agentforce + sf-deploy | Deploy agent metadata, fix topics/actions/prompts |
| Agentforce test failure | sf-ai-agentforce-testing | Run agent test specs, report routing/action failures |
| Data Cloud stream/DMO issue | sf-datacloud + sub-skills | Fix stream config, mappings, identity rules, segments |
| Data Cloud segment empty | sf-datacloud-segment | Verify SQL, republish segment |
| Slack config missing | sf-integration + sf-connected-apps | Verify connected app; escalate Slack workspace config |
| Marketing Cloud connector | sf-integration | Verify connector package + connected app; escalate MC-side |
| CRM Analytics asset missing | sf-deploy | Deploy analytics app/dashboard/dataset metadata |
| CRM Analytics dataflow broken | -- (escalate) | Report dataflow error; recommend Analytics Studio repair |
| OmniScript/FlexCard missing | sf-industry-commoncore-* + sf-deploy | Deploy OmniStudio metadata from local source |
| OmniScript inactive | sf-deploy | Activate and deploy |
| Visual/UI mismatch | -- (escalate) | Report with screenshot, recommend manual fix |

**Deploy order**: Objects/Fields --> Permission Sets --> Apex --> Flows (Draft) --> Activate Flows --> Data

Always use `--dry-run` before actual deployment.

### Phase 6: Re-Validate

Re-run Phase 3 on previously failing steps only.

- If all steps now pass --> proceed to Phase 7
- If failures remain and iteration < 3 --> return to Phase 5
- If failures remain and iteration = 3 --> proceed to Phase 7 with escalation

### Phase 7: Summary

Final output:

```
DEMO VALIDATION COMPLETE: [Demo Title]
================================================================

Score: [XX]/200
  Platform Prerequisites:  [XX]/20
  Metadata & Code Health:  [XX]/20
  Data Quality & Freshness:[XX]/20
  Automations:             [XX]/20
  Permissions & Content:   [XX]/20
  Visual/UI:               [XX]/20
  Experience Cloud:        [XX]/20
  E2E Simulation:          [XX]/20
  Intake Simulation:       [XX]/20
  Dashboard & Reporting:   [XX]/20

Result: [ALL PASSING | ISSUES REMAINING]
Iterations: [n]
Steps: [passed]/[total]

[If issues remain:]
UNRESOLVED ISSUES (requires manual intervention):
  - Step [n]: [description of what couldn't be auto-fixed and why]
```

---

## Scoring Rubric (200 Points)

| Category | Points | What's Checked |
|----------|--------|----------------|
| **Platform Prerequisites** | 20 | Person Accounts enabled, NPC objects exist, ApplicationForm RT, custom fields, queues, provisioner script |
| **Metadata & Code Health** | 20 | Objects, fields, record types, apps, tabs exist; Apex classes compile; app tab config matches script |
| **Data Quality & Freshness** | 20 | Demo records present, field values correct, location data complete, shift dates fresh, no stale artifacts |
| **Automations** | 20 | Flows active, triggers deployed, trigger chain fires correctly (Person Account + Task creation) |
| **Permissions & Content** | 20 | Perm sets assigned, Apex class access granted, FLS correct, network member groups configured |
| **Visual/UI** | 20 | Pages render correctly, components visible, layouts match expected state |
| **Experience Cloud** | 20 | Public URL reachable, guest catalog shows live data, member features accessible, no empty Chatter landing |
| **E2E Simulation** | 20 | Shift sign-up as Jamie succeeds; timezone correct; no duplicate assignments; cleanup passes |
| **Intake Simulation** | 20 | Guest intake form creates ApplicationForm + Applicant + Person Account + Task; trigger chain verified |
| **Dashboard & Reporting** | 20 | Report types, reports, dashboard exist and reference correct columns |

**Thresholds**: 180+ Deploy-ready | 140-179 Review needed | <140 Blocked -- requires manual intervention

Scoring is prorated based on which categories apply. If a demo has no Experience Cloud steps, score is out of 180 and thresholds adjust proportionally. Same for Intake Simulation, E2E Simulation, and Visual/UI.

---

## Guardrails (MANDATORY)

| Rule | Rationale |
|------|-----------|
| **Never delete production data** | Demo fixes should only create or update, never destroy existing records |
| **Never modify Profiles directly** | Use Permission Sets for all access changes |
| **Always `--dry-run` before deploying** | Catch deployment errors before they hit the org |
| **Max 3 fix iterations** | Prevent infinite loops; escalate after 3 attempts |
| **Never overwrite user customizations** | If a field/object exists but differs from the script, report rather than overwrite |
| **Preserve existing automations** | Never deactivate a flow/trigger not mentioned in the demoscript |
| **No hardcoded IDs** | All references must use queries or API names |

---

## Cross-Skill Integration

| Skill | When to Delegate | Example |
|-------|-----------------|---------|
| sf-metadata | Missing objects, fields, record types, layouts | "Create custom object Invoice__c with fields" |
| sf-data | Missing demo records, dashboard creation via Apex | "Insert 5 sample Account records" |
| sf-soql | Complex validation queries | "Query Opportunity with related LineItems" |
| sf-deploy | Deploy any metadata fixes to the org | "Deploy Invoice__c and permission set" |
| sf-permissions | Missing FLS, object access, perm set assignments | "Create permission set for Invoice__c" |
| sf-apex | Broken triggers, classes, test failures, E2E simulations | "Fix compilation error in InvoiceTrigger" |
| sf-flow | Inactive or broken flows | "Activate Record-Triggered Flow on Case" |
| sf-lwc | Missing or broken Lightning components | "Check deployment of invoiceList LWC" |
| sf-integration | Named credential or external service issues | "Verify PaymentGateway named credential" |
| sf-connected-apps | OAuth, JWT bearer, Connected App config | "Verify Slack connected app OAuth scopes" |
| sf-testing | Run Apex tests after fixes to confirm stability | "Run local tests after deployment" |
| sf-ai-agentforce | Agent Builder topics, actions, PromptTemplates | "Deploy agent with 3 topics and 5 actions" |
| sf-ai-agentforce-testing | Agent test specs and routing validation | "Run agent test plan, verify topic routing" |
| sf-ai-agentscript | Deterministic FSM-based agents | "Validate .agent file state machine" |
| sf-ai-agentforce-persona | Agent persona/tone/voice validation | "Verify agent persona matches demo brand" |
| sf-ai-agentforce-observability | Agent session tracing and telemetry | "Extract STDM data, analyze agent conversations" |
| sf-datacloud | Data Cloud multi-phase pipeline orchestration | "Verify connect→prepare→harmonize→segment→act pipeline" |
| sf-datacloud-connect | Data Cloud connectors and source systems | "Verify Snowflake connector is active" |
| sf-datacloud-prepare | Data streams, DLOs, transforms | "Verify data stream is ingesting" |
| sf-datacloud-harmonize | DMOs, mappings, identity resolution | "Verify unified profile is resolving" |
| sf-datacloud-segment | Segments and calculated insights | "Verify segment has non-zero count" |
| sf-datacloud-act | Activations and activation targets | "Verify activation target is configured" |
| sf-datacloud-retrieve | Data Cloud SQL, vector search, describe | "Run Data Cloud query to verify data" |
| sf-industry-commoncore-omniscript | OmniScript creation and validation | "Verify intake OmniScript is active" |
| sf-industry-commoncore-flexcard | FlexCard creation and validation | "Verify account summary FlexCard renders" |
| sf-industry-commoncore-integration-procedure | IP orchestration validation | "Verify IP returns data from Data Mapper" |
| sf-industry-commoncore-datamapper | Data Mapper field mapping validation | "Verify extract Data Mapper pulls Account fields" |
| sf-industry-commoncore-omnistudio-analyze | Namespace detection and dependency analysis | "Detect Core vs vlocity namespace, map dependencies" |

---

## CLI Commands Used

| Command | Purpose |
|---------|---------|
| `sf org display --target-org [alias] --json` | Verify org connection |
| `sf package installed list --target-org [alias] --json` | Check installed packages |
| `sf data query --query "..." --target-org [alias] --json` | Validate data and metadata |
| `sf project deploy start --dry-run --source-dir [path] --target-org [alias]` | Pre-flight deployment check |
| `sf project deploy start --source-dir [path] --target-org [alias]` | Deploy fixes |
| `sf project retrieve start --metadata [type:name] --target-org [alias]` | Check component existence |
| `sf org open --url-only --target-org [alias] --path "[path]" --json` | Get authenticated URL for visual validation |
| `node scripts/screenshot.js "[url]" "[output]"` | Capture page screenshot via Playwright |
| `sf apex run test --test-level RunLocalTests --target-org [alias]` | Post-fix stability check |

---

## Completion Format

After all phases complete:

```
DEMO READY: [Demo Title]
================================================================

Score: [XX]/200 -- [DEPLOY-READY | REVIEW NEEDED | BLOCKED]
Org: [alias] ([type])
Steps Validated: [n]
Platform Prerequisites: [n] checked
Data Quality Checks: [n] (locations, shift freshness, stale data, capacity)
Permission Content Checks: [n] (Apex class access, network members)
Visual Checks: [n] screenshots captured
Experience Checks: [n] site pages verified (URL reachable: yes/no)
E2E Simulations: [n] user flows executed (shift sign-up, intake form)
Intake Simulations: [n] trigger chain steps verified
Fix Iterations: [n]
Fixes Applied: [list of what was fixed]

[If all passing:]
All demo paths validated -- no manual next steps required.

[If escalations remain:]
UNRESOLVED ISSUES (requires manual intervention):
  - [description of what couldn't be auto-fixed and why]
```

The skill is designed to leave **zero manual next-steps** whenever possible. Dashboard creation, Experience Cloud verification, and end-to-end user simulation are all handled autonomously. Only true platform limitations (e.g., Lightning App Builder component placement) are escalated.

---

## Dependencies

- **Required**: `sf` CLI v2 authenticated to target org
- **Required for fixes**: sf-metadata, sf-deploy (auto-delegated)
- **Required for visual checks**: Node.js, Playwright (`npm install playwright && npx playwright install chromium`)
- **Recommended**: sf-data, sf-soql, sf-permissions, sf-apex, sf-flow, sf-lwc, sf-integration, sf-testing
