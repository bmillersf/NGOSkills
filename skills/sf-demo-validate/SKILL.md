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
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://architect.salesforce.com
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://playwright.dev/docs/intro
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_summary.htm
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

Beyond checking that flows/triggers exist and are active, the skill **fires automations and verifies their side effects**. Order of preference, strongest to weakest:

1. **Authored FlowTest (preferred)**: if the flow has a `.flowtest-meta.xml` covering the demo step's behavior, run it via `sf logic run test --tests "FlowTesting.<flow-test-name>" --target-org [alias] --synchronous --json` (or `sf flow run test --tests <name>` on older CLIs). FlowTests evaluate without committing DML, so there's no cleanup; assertions on intermediate elements (`WasVisited`, `HasError`) catch regressions side-effect inspection misses; they participate in `--code-coverage`. **If the demo step claims a flow fires and no FlowTest exists, author one** (see [sf-flow/references/flow-test-authoring.md](../sf-flow/references/flow-test-authoring.md) for schema + verified examples) before falling back to the side-effect simulation below.
2. **Record-triggered flows/triggers (fallback when no FlowTest exists)**: insert or update a test record that matches the trigger criteria, then query for expected side effects (new child records, field updates, Tasks, emails). Clean up afterward. Use this when authoring a FlowTest is out of scope for the validation pass.
3. **Screen flows via REST API**: invoke the flow via `POST /services/data/v62.0/actions/custom/flow/[FlowApiName]` with test input variables, then verify outputs. (FlowTest's `InputVariable` parameter type is reserved for future use, so screen flows still need this fallback.)
4. **Autolaunched/invocable flows**: call via REST API or Anonymous Apex using `Flow.Interview.createInterview()`.
5. **Automation chain verification**: for multi-step chains (e.g., insert Applicant → trigger fires → Person Account created → Task created → Flow sends email), the simulation verifies each link in the chain, not just the final state. Author one FlowTest per link where possible; chain-test the rest via side-effect inspection.

**Example — Coordinator Status Update Chain** (Act 3):
- **First** check whether `ApplicationForm_Approval_Test.flowtest-meta.xml` (or similar) exists — if so, run it via `sf logic run test`.
- If no FlowTest covers the chain, author one for the record-triggered link and fall back to side-effect simulation for the rest:
  - Update `ApplicationForm.ApplicationStatus` to `'Approved'`
  - Verify downstream side effects (Task created, email sent, status propagated)
  - Roll back the status change and clean up

> Full flow execution patterns: [references/validation-checks.md](references/validation-checks.md). FlowTest authoring schema + examples: [sf-flow/references/flow-test-authoring.md](../sf-flow/references/flow-test-authoring.md).

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

#### Sales Cloud Validation

If a step touches Sales Cloud pipeline, opportunities, forecasting, or sales engagement (and no industry overlay like FSC / NPC claims it), validate pipeline health:

1. **Opportunity records per stage** — SOQL-aggregate `Opportunity` by `StageName` and verify at least one record exists in each active stage the demoscript walks through. A demo that narrates "move from Qualification to Proposal" fails if both stages are empty.
2. **Forecast Types configured** — query `ForecastingType` for IsActive = true and confirm the demo's forecast category (Revenue, Quantity, Custom) is enabled; verify `ForecastingCategoryMapping` reflects the demoscript's categories.
3. **Forecast Hierarchy populated** — query `UserRole` and `ForecastingUserPreference` to confirm the role hierarchy used by the demo has at least two levels with submitters below the manager persona.
4. **Cadences running** — query `SalesCadence` and `SalesCadenceTarget` for active cadences with non-empty target lists. A demo showing "the cadence auto-emails on day 3" fails if the cadence has zero targets.
5. **Pipeline Inspection accessible** — verify the Pipeline Inspection app exists (`AppDefinition`), the page is reachable for the demo user, and at least one saved view filter matches the demo narrative.
6. **Opportunity Teams / Splits** — if the demoscript shows opportunity splits, confirm `OpportunitySplitType` records exist and at least one `OpportunitySplit` row is present for the demo Opportunity.
7. **Deal Insights / Einstein** — if the demo mentions Deal Insights, verify the Einstein feature is enabled on the org and at least one Opportunity has been scored.

Routes repairs to `sf-sales-cloud` -> `sf-sales-opportunity`, `sf-sales-forecasting`, or `sf-sales-engagement` depending on what failed.

#### Service Cloud Validation

If a step touches Service Cloud Case lifecycle, Omni-Channel, Knowledge, or Entitlements (and no industry overlay like Health / PSS claims it), validate:

1. **Entitlements active** — query `Entitlement` for `Status = 'Active'` and `EndDate >= TODAY`; confirm the demo's entitlement is tied to an `Asset` or `Account` the demoscript references, and that at least one `MilestoneType` is in play.
2. **SLA Process / Milestones firing** — query `ProcessMilestone` and `CaseMilestone` for recent completions; verify the case used in the demo has an active milestone with expected `TargetDate`.
3. **Omni-Channel queue capacity** — query `ServiceChannel`, `PresenceConfiguration`, and `PresenceUserConfig`; confirm at least one queue has `CapacityUnit = 'Weight'` or `'Count'` with unused capacity. Verify the demo user has a Presence status assigned.
4. **Omni-Channel Routing Configurations** — confirm `RoutingConfiguration` records exist and reference the queues the demoscript mentions; skills-based routing verifies `Skill` records and `SkillRequirement` per queue.
5. **Knowledge articles published** — query `Knowledge__kav` (or `KnowledgeArticleVersion`) with `PublishStatus = 'Online'` and `IsLatestVersion = true`; confirm at least one published article matches the demoscript's Data Category path.
6. **Web-to-Case / Email-to-Case active** — if the demoscript shows inbound case creation, verify `EmailServicesFunction` / `EmailServicesAddress` records exist and are active; verify `WebToCaseHttpPost` default assignment rule is configured.
7. **Case Assignment / Escalation Rules** — query `AssignmentRule` and `EscalationRule` with `Active = true` that match the demo's case record type.
8. **Service Console layout** — verify `AppDefinition` for the Service Console matches the demoscript; utility bar components required by the demo (Omni Widget, Macros, Softphone) are present.

Routes repairs to `sf-service-cloud` -> `sf-service-case`, `sf-service-omnichannel`, or `sf-service-knowledge`.

#### Marketing Cloud Validation (Growth and Account Engagement)

If a step touches MC Growth or MCAE, validate the variant the org is running:

**MC Growth** (`MarketingCloudGrowth` feature + Data Cloud enabled):

1. **Journey active** — query `MarketingAppExtensionActivity` or use the Marketing Cloud Growth REST API to verify at least one journey referenced by the demoscript is in `Active` status.
2. **Journey goal + exit criteria** — confirm goal and exit criteria are configured (not left blank); empty goals break the analytics view the demo shows.
3. **Segment membership non-zero** — the journey's entry segment (Data Cloud segment) must have `MemberCount > 0`.
4. **Email / SMS templates published** — confirm `ContentVersion` or Growth content records for the email/SMS asset exist and are in `Published` state.
5. **Sender Profile configured** — verify the journey's from-address / sender profile resolves to an active `EmailSenderProfile` record.

**MCAE / Pardot** (`pi__` namespace):

1. **Automation Rules firing** — query `pi__automation_rule__c` (or Tooling API on the MCAE business unit) for `Active = true` and `matched_count__c > 0` within the last 30 days.
2. **Forms + Landing Pages published** — confirm `pi__form__c` and `pi__landing_page__c` records exist, are published, and are accessible via their public URL (HTTP 200 smoke check).
3. **Dynamic Lists populated** — verify `pi__list__c` with `list_type = 'Dynamic'` has non-zero `prospect_count__c`.
4. **Scoring / Grading categories** — verify the scoring category definitions referenced by the demoscript exist and are attached to assets.
5. **Connector status** — verify the MCAE-to-Salesforce connector is `Verified` (not `Not Verified` or `Paused`), via the `pi__connector__c` object.

Routes repairs to `sf-marketing-cloud-growth` or `sf-marketing-account-engagement`.

#### Revenue Cloud Validation

If a step touches Revenue Cloud Advanced or legacy CPQ, validate:

1. **Price Books active** — query `Pricebook2` with `IsActive = true` and at least one `PricebookEntry` per demo product; confirm the demo user's default price book matches the demoscript.
2. **Products configured** — query `Product2` for `IsActive = true`; confirm the products referenced by the demoscript exist and have the right product family, product rules, and feature codes.
3. **Quote flow end-to-end** — create a test Quote + QuoteLineItem via Anonymous Apex (or REST) for the demo Opportunity; verify the quote generates without hitting product-rule validation errors; delete afterward.
4. **Order + Contract scaffolding** — for Order/Contract demos, verify `Order` record types exist, `OrderItem` relationship holds, and the Contract auto-creation rule fires on Order activation.
5. **Subscription / Billing Schedules** — for subscription demos, verify `SubscriptionManagement` records exist (RCA) or `SBQQ__Subscription__c` records exist (CPQ); `BillingSchedule` has non-zero lines.
6. **Revenue Cloud feature flags** — confirm the org has the `RevenueCloudAdvanced` or `SBQQ__` feature enabled (industry-precheck reconfirm).
7. **Product Rules + Pricing Rules** — verify at least one `ProductRule` and `PricingRule` are `Active = true` and reference the demo's products.

Routes repairs to `sf-revenue-cloud`.

#### Tableau Validation

If a step touches Tableau, Tableau Next, or CRM Analytics, validate:

1. **Workbooks / Dashboards published** — for Tableau Desktop/Server/Cloud, confirm the workbook URL is reachable and returns the expected title; for CRM Analytics, query `WaveDashboard` / `AnalyticsDashboard` for the expected assets. For Tableau Next, query the Semantic Model / Pulse Metric records.
2. **Data sources connected** — Tableau Server/Cloud published data sources have a recent successful refresh; CRM Analytics datasets have a `LastDataUpdateDate` within the freshness window the demoscript expects.
3. **Pulse Metrics (Tableau Next)** — verify at least one `PulseMetric` is published and has recent datapoints; confirm the subscription/follow count matches the demo persona.
4. **Einstein Discovery stories** — if the demo showcases Einstein Discovery, verify the story is deployed (`EDStory`) and the model is trained; confirm predictions are non-null for the demo records.
5. **Embed in Salesforce** — if the demo shows a Tableau viz embedded on a record page, verify the `FlexiPage` references the Tableau LWC and the embed token / Connected App is valid.
6. **Permissions to view** — verify the demo user has the right permission set assignments for CRM Analytics (`CRMAnalyticsPlus` or equivalent); Tableau uses the Connected App / SSO principal.

Routes repairs to `sf-tableau`.

#### MuleSoft Validation

If a step touches MuleSoft Anypoint Platform, MuleSoft for Flow, or DataWeave, validate:

1. **Named Credentials pointing at Anypoint** — query `NamedCredential` and confirm the callout endpoint matches the Anypoint API instance URL (not a stale sandbox URL); confirm OAuth/mTLS is valid.
2. **MuleSoft for Flow connectors online** — verify the Connected App for MuleSoft for Flow is authorized; query `InvocableAction` for MuleSoft-provided flow actions to confirm the connector is loaded.
3. **External Services registered** — query `ExternalServiceRegistration` for the Anypoint Exchange-published API; confirm the latest version is registered and the schema matches the demo's invocable action.
4. **API Manager policies** — for demos that highlight policy enforcement (rate limit, client ID), confirm the policy is applied on the API instance (via Anypoint REST or a smoke call that expects the policy to fire).
5. **DataWeave transforms in Flow** — if the demoscript uses a DataWeave step inside a Salesforce Flow, verify the Flow is active and the DataWeave expression compiles (can test by triggering the flow once with safe input).
6. **Runtime Manager app status** — if the demo mentions the Mule application directly, confirm it is `Started` on CloudHub / RTF.

Routes repairs to `sf-mulesoft` + `sf-integration`.

#### Slack Validation (Extended)

In addition to the existing Slack section above, for Slack-First demos (Canvases, Slack AI, Slack Sales Elevate, Slack for Service):

1. **Slack app installed** — query `ConnectedApplication` for the Salesforce-Slack bridge; confirm the app manifest version matches the demoscript's expected features.
2. **Workflows published** — verify the Slack workflows referenced by the demoscript are `Published` (via Slack Workflow Builder or manifest inspection); the bot user is a member of the target channels.
3. **Slack Canvases** — if the demo shows an auto-generated Canvas, verify the Canvas template exists and the bot has `canvases:write` scope.
4. **Slack AI Recaps** — if the demo highlights AI summaries, confirm the Slack AI feature is provisioned on the workspace (cannot be verified from Salesforce; escalate to manual check if ambiguous).
5. **Sales Elevate / Service panels** — verify the Slack Sales Elevate or Slack for Service LWC / panel is deployed and the Connected App scopes include `record.read`.
6. **Channel routing** — verify the Flow or trigger that pushes a record event to Slack references the right `ChannelConfiguration__c` / custom metadata entry the demoscript expects.

Routes repairs to `sf-slack` + `sf-integration`.

#### Industry Cloud Validation Blocks

For any step that touches an industry cloud, defer to the owning skill's detection pattern and score against its rubric. One block per industry:

**FSC (Financial Services Cloud)** -> `sf-industry-fsc`:
- Household account present (`AccountContactRelation` with Role = 'Household Member' or FSC's Household Model v2)
- Financial Accounts (`FinServ__FinancialAccount__c`) linked to the household
- Life Events (`FinServ__LifeEventMoment__c` or the v2 `FinServ__LifeEvent__c`) recent within the demo window
- Financial Goals, Relationship Map population
- ARC (Actionable Relationship Center) configured if demo highlights the visual tree

**Health Cloud** -> `sf-industry-health`:
- Patient record (Person Account with Health Cloud patient attributes)
- Care Plan template active (`CarePlanTemplate`) with at least one `CarePlanProblem` + `CarePlanGoal`
- Care Team members resolved (`CareTeamMember`)
- Care Request in a non-terminal status (`CareRequest`)
- Clinical Encounter / Assessment records if the demo shows them
- PHI redaction verified in sandbox (no real patient data present)

**Education Cloud / EDA** -> `sf-industry-education`:
- Student record (Contact or EducationAccount depending on variant)
- Program Enrollment active, Course Connections present, Affiliations to Educational Institution
- Term / Academic Period current
- Advising / Recruiting / Retention records populated if the demo covers them

**Public Sector Solutions** -> `sf-industry-public-sector`:
- Constituent intake record (`BusinessLicense`, `RegulatoryCodeCase`, or `PublicComplaint`)
- Benefit, License, Permit, Inspection records per demo step
- Regulatory Code Violation tied to the right jurisdiction
- Section 508 accessibility guardrails enforced on pages the demo shows

**Field Service** -> `sf-field-service`:
- Work Order + Work Order Line Items resolved
- Service Appointment scheduled with `SchedStartTime` future-dated
- Service Resource + Service Territory populated
- Scheduling Policy + Dispatcher Console configured
- Mobile offline briefcase includes the demo's WOLIs

**Manufacturing Cloud** -> `sf-industry-manufacturing`:
- Sales Agreement active with forecast/actual splits
- Account Forecast has recent calculation
- Rebate Program with non-zero accruals

**Consumer Goods Cloud** -> `sf-industry-consumer-goods`:
- Retail Store + Visit records populated
- Trade Promotion active, Assortment resolved
- Perfect Store compliance task open

**Communications Cloud** -> `sf-industry-communications`:
- Enterprise Product Catalog items loaded
- Order Decomposition pattern executes for the demo product
- Number Management pool non-empty

**Media Cloud** -> `sf-industry-media`:
- Subscriber + Billing Account records resolved
- Entitlement active

**Energy & Utilities Cloud** -> `sf-industry-energy`:
- Premise + Service Point records linked
- Meter with recent interval data
- Work Request in a non-terminal status

Each block links to its owning `sf-industry-*` skill for the detection SOQL and full prerequisite matrix. Routes repairs accordingly.

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

## Scoring Rubric (base 200 + cross-cloud add-on categories)

The base 200-point rubric covers the original 10 categories (unchanged). Cross-cloud and industry validation add new **prorated** categories that appear in the score ONLY when the demo exercises those surfaces. If a demo has no Sales Cloud step, the Sales Cloud category is not assessed, it does not appear in the scorecard, and the denominator shrinks accordingly. This preserves additivity: nothing in the legacy rubric changes.

### Base rubric (200 pts — unchanged)

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

### Cross-cloud add-on categories (only scored when demoed)

| Add-on category | Points | What's Checked | Routes to |
|---|---|---|---|
| **Sales Cloud** | 20 | Opportunities per stage, Forecast Types active, cadences running, Pipeline Inspection reachable | sf-sales-cloud (sf-sales-opportunity / -forecasting / -engagement) |
| **Service Cloud** | 20 | Entitlements active, Omni-Channel queue capacity, Knowledge published, Case Assignment / Escalation rules | sf-service-cloud (sf-service-case / -omnichannel / -knowledge) |
| **Marketing Cloud (Growth or MCAE)** | 20 | MCG journey active + segment membership + templates published; OR MCAE automation rules firing + forms published + connector verified | sf-marketing-cloud-growth / sf-marketing-account-engagement |
| **Revenue Cloud** | 20 | Price Books + Products active, quote flow end-to-end, subscription/billing schedule populated | sf-revenue-cloud |
| **Tableau / Analytics** | 20 | Workbooks/dashboards published, data sources connected + fresh, Pulse metrics non-zero, Einstein Discovery story trained | sf-tableau |
| **MuleSoft** | 20 | Named Credentials -> Anypoint, MuleSoft for Flow connectors online, External Services registered, API Manager policies applied | sf-mulesoft + sf-integration |
| **Slack (Slack-First)** | 20 | Slack app installed, workflows published, Canvases accessible, channel routing correct | sf-slack + sf-integration |
| **FSC** | 20 | Household resolved, Financial Accounts linked, Life Event recent, Financial Goal populated, Relationship Map/ARC present | sf-industry-fsc |
| **Health Cloud** | 20 | Patient record, active Care Plan template, Care Team resolved, Care Request in non-terminal status, PHI redacted in sandbox | sf-industry-health |
| **Education Cloud / EDA** | 20 | Student + Program Enrollment + Course Connection + Affiliation + Term current | sf-industry-education |
| **Public Sector Solutions** | 20 | Benefit / License / Permit / Inspection records per demo step, Regulatory Code tie, Section 508 guardrails | sf-industry-public-sector |
| **Field Service** | 20 | Work Order + Service Appointment (future), Service Resource + Territory, Scheduling Policy, mobile briefcase | sf-field-service |
| **Manufacturing Cloud** | 20 | Sales Agreement active, Account Forecast calculated, Rebate Program with accruals | sf-industry-manufacturing |
| **Consumer Goods / Communications / Media / E&U** | 20 each | Per-industry object population (Visit, Offer, Subscriber, Premise/Meter) | sf-industry-consumer-goods / -communications / -media / -energy |

### Thresholds (prorated)

For a demo with N applicable categories, total possible = N × 20. Thresholds scale the same way:

- **>= 90% of possible** -> Deploy-ready (e.g., 180/200, or 216/240 with two add-ons)
- **70 - 89%** -> Review needed
- **< 70%** -> Blocked; requires manual intervention

Scoring is **prorated** based on which categories apply. The legacy 200-point ceiling stays intact for nonprofit volunteer demos (no add-ons). A cross-cloud demo that includes Sales + Service + Slack adds 60 points and targets >= 234/260.

Example prorated scorecards:

```
Nonprofit volunteer demo:       180 / 200 (Deploy-ready)
FSC + Agentforce + Tableau:     216 / 240 (Deploy-ready)   [+FSC +Tableau]
Sales + Service + MC Growth:    205 / 260 (Review)         [+Sales +Service +MC]
Health + Field Service + Slack: 198 / 260 (Review)         [+Health +FieldService +Slack]
```

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
