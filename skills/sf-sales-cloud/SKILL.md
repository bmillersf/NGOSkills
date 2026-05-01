---
name: sf-sales-cloud
description: >
  Salesforce Sales Cloud product orchestrator for lead-to-cash, pipeline, forecasting,
  and sales engagement workflows, with industry-first routing precedence.
  TRIGGER when: user designs or troubleshoots a Sales Cloud implementation across
  multiple capabilities and says things like "set up lead management end-to-end",
  "design lead routing and assignment", "build the pipeline stage model", "configure
  opportunity team selling", "stand up collaborative forecasts for this org",
  "enable pipeline inspection and deal insights", "turn on Einstein for Sales /
  Einstein Opportunity Scoring / Einstein Lead Scoring", "configure campaign
  influence and campaign member statuses", "design product and price book strategy",
  "wire up quote-to-order hand-off", "set up territory management / enterprise
  territory management", "roll out sales engagement cadences", "activate Sales
  Dialer and Einstein Activity Capture", "review our Sales Cloud data model", or
  any multi-capability Sales Cloud initiative that needs a routing decision across
  Opportunity, Forecasting, Engagement, Territory, and Revenue Intelligence.
  DO NOT TRIGGER when: the request is narrowly about Opportunity modeling, splits,
  teams, pipeline inspection, or deal insights (use sf-sales-opportunity);
  narrowly about Collaborative Forecasts, forecast types, forecast hierarchies,
  adjustments, or quotas (use sf-sales-forecasting); narrowly about Sales
  Engagement, cadences, Sales Dialer, Einstein Activity Capture, or prioritized
  work queues (use sf-sales-engagement); the org has Financial Services Cloud and
  the request touches Households, Financial Accounts, Life Events, ARC, or
  FinServ__ objects (use sf-industry-fsc); the org has Health Cloud and touches
  Patient, Care Plan, Care Request, or HealthCloudGA__ objects (use
  sf-industry-health); the org has Education Cloud or EDA and touches Student,
  Course, Affiliation, Term, or hed__ objects (use sf-industry-education); the
  org has Public Sector Solutions and touches Benefit, License, Permit, or
  Inspection (use sf-industry-public-sector); the request involves Work Orders,
  Service Appointments, Service Territories, or dispatcher scheduling (use
  sf-field-service); the org has Nonprofit Cloud and touches Gift Transaction,
  Funding Award, Program Enrollment, or Case Plan (use sf-nonprofit-cloud); the
  org has NPSP and treats Opportunity as a donation or uses Recurring Donation,
  Household Account, or Allocation (use sf-nonprofit-npsp); the org has
  Manufacturing Cloud and touches Sales Agreement, Account Forecast, or Rebate
  Program (use sf-industry-manufacturing); the org has Consumer Goods Cloud and
  touches Retail Store, Visit, or Trade Promotion (use sf-industry-consumer-goods);
  the org has Communications Cloud and touches Product Catalog, Offer, Cart, or
  Order Decomposition (use sf-industry-communications); the org has Media Cloud
  and touches Subscriber, Billing Account, or Entitlement (use sf-industry-media);
  the org has Energy & Utilities Cloud and touches Premise, Service Point, Meter,
  or Work Request (use sf-industry-energy); the request involves Quote-to-Cash,
  CPQ product rules, Subscription Management, Billing Schedules, or Order Products
  as revenue (use sf-revenue-cloud); the request is a Service Cloud Case lifecycle,
  entitlement, milestone, or omni-channel routing question (use sf-service-cloud);
  the request is a Marketing Cloud Growth / Account Engagement (Pardot) campaign
  execution, journey, or email-send question (use sf-marketing-cloud-growth or
  sf-marketing-account-engagement); the work is Apex code quality (use sf-apex);
  the work is LWC components (use sf-lwc); the work is Flow XML mechanics (use
  sf-flow); the work is Data Cloud ingestion, harmonization, segmentation, or
  activation (use sf-datacloud); the work is nonprofit fundraising (use
  sf-nonprofit-fundraising); the work is nonprofit NPSP configuration (use
  sf-nonprofit-npsp).
license: MIT
compatibility: "Requires Sales Cloud edition; industry-first routing applies"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.sales_core.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.forecasts3_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/sales
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_sales.htm
---

# sf-sales-cloud: Sales Cloud Orchestrator

Use this skill when the user needs **product-level Sales Cloud workflow guidance** that crosses more than one capability area: lead-to-cash pipeline design, forecasting alignment, sales engagement rollout, territory assignment, or Revenue Intelligence enablement. Sales Cloud is not a single feature — it is the union of Leads, Accounts, Contacts, Opportunities, Activities, Campaigns, Quotes, Orders, Contracts, Products / Price Books, Territory Management, Enterprise Territory Management, Collaborative Forecasts, Sales Engagement, Sales Dialer, Einstein for Sales, Pipeline Inspection, Deal Insights, and Revenue Intelligence.

This orchestrator is the first stop for multi-capability asks. It routes into focused phase skills once the task is localized and halts with an industry-first hand-off whenever an industry solution is installed and the request touches industry-owned objects.

---

## When this skill owns the task

Use `sf-sales-cloud` when the work involves **two or more** of:

- lead lifecycle (capture, qualification, scoring, assignment, conversion)
- account / contact hierarchy + relationship design for B2B or B2C
- opportunity model design (stages, record types, splits, teams) + forecast alignment
- campaign strategy (Salesforce Campaigns, Campaign Member, Campaign Influence) tied to pipeline
- product + price book strategy (standard price book, multi-currency, price book entries) feeding opportunities
- quote generation + opportunity-to-order hand-off (standard Quote object; CPQ/RCA handled by `sf-revenue-cloud`)
- contracts + renewals as a source of future pipeline
- territory + segment assignment (Enterprise Territory Management 2.0, territory hierarchies, assignment rules)
- Einstein for Sales (Opportunity Scoring, Lead Scoring, Forecasting, Conversation Insights)
- Revenue Intelligence, Pipeline Inspection, Deal Insights, and the Analytics app that backs them
- Sales Engagement rollout that touches more than one of Cadences, Dialer, EAC, or prioritized work

Delegate to a focused phase skill when the task is localized:

| Phase / area | Delegate to | Typical scope |
|---|---|---|
| Opportunity, Splits, Teams, Contact Roles, Stage History, Pipeline Inspection, Deal Insights | [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md) | deal modeling, pipeline hygiene, opportunity-level reporting |
| Collaborative Forecasts, forecast types, categories, hierarchies, adjustments, quotas | [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md) | forecast configuration, roll-up design, quota alignment |
| Sales Engagement, cadences, Sales Dialer, Einstein Activity Capture, prioritized work queues | [sf-sales-engagement](../sf-sales-engagement/SKILL.md) | outbound / inbound cadence design, call-center config, activity capture |
| Quote-to-Cash, CPQ, RCA, Subscription Management, Billing Schedules | [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md) | revenue lifecycle past the Opportunity |
| Case lifecycle, entitlements, milestones, omni-channel routing | [sf-service-cloud](../sf-service-cloud/SKILL.md) | post-sale service |
| Campaign execution, journeys, email / mobile sends | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) or [sf-marketing-account-engagement](../sf-marketing-account-engagement/SKILL.md) | top-of-funnel marketing |
| Unified profile, segmentation, activation against Sales Cloud data | [sf-datacloud](../sf-datacloud/SKILL.md) | cross-source unified view |

---

## Phase 0: Industry Pre-Check (MANDATORY)

**Before gathering any other context or producing any artifact, run the shared industry pre-check.** See [references/industry-precheck.md](../../references/industry-precheck.md) for the full detection + deferral protocol.

Procedure:

1. **Detect.** Run `sf org display --json` and `sf org list metadata-types --json` against the target org. Inspect `features`, `licenses`, installed managed-package namespaces, and standard-object extensions per the reference.
2. **Cross-reference.** Compare the detected industry against the user's request. If any of the following match, halt and forward:

   | Detected signal | If request touches | Halt and forward to |
   |---|---|---|
   | `FinancialServicesCloudStandard` / `FinServ__` | Households, Financial Accounts, Financial Goals, Life Events, ARC, CDS, Relationship Maps | `sf-industry-fsc` |
   | `HealthCloudGA` / `HealthCloudGA__` | Patient, Care Plan, Care Request, Clinical Encounter, Care Team | `sf-industry-health` |
   | `EducationCloudForStudentSuccess` / `hed__` | Student, Course, Affiliation, Term, Course Connection, Program Enrollment (edu) | `sf-industry-education` |
   | `PublicSectorSolutions` / `OutfundsPS__` | Benefit, License, Permit, Inspection, Application, Regulatory Code Violation | `sf-industry-public-sector` |
   | `FieldServiceStandard` / `FieldService__` | Work Order, Service Appointment, Service Resource, Territory (FSL), Skill, Scheduling Policy | `sf-field-service` |
   | `NonprofitCloudFor*` | Gift Transaction, Gift Designation, Funding Award, Program Enrollment (NPC), Benefit (NPC), Goal, Case Plan | `sf-nonprofit-cloud` (then its children) |
   | Managed package `npsp` | Opportunity-as-donation, Recurring Donation, Household Account, Allocation, Level, Engagement Plan | `sf-nonprofit-npsp` |
   | `ManufacturingCloudUser` | Sales Agreement, Account Forecast, Advanced Account Forecast, Rebate Program | `sf-industry-manufacturing` |
   | `ConsumerGoodsCloudUser` | Retail Store, Visit, Retail Execution, Trade Promotion, Assortment | `sf-industry-consumer-goods` |
   | `CommunicationsCloudUser` / `vlocity_cmt__` | Product Catalog, Offer, Cart, Order Decomposition, Number Management, ESM | `sf-industry-communications` |
   | `MediaCloudUser` / `vlocity_media__` | Subscriber, Billing Account, Entitlement (media), Campaign Response (media) | `sf-industry-media` |
   | `EnergyCloudUser` / `vlocity_ins__` + E&U | Premise, Service Point, Meter, Work Request, Interval Data | `sf-industry-energy` |
   | `RevenueCloudAdvanced` / `SBQQ__` | Quote, Quote Line, Subscription, Asset (as subscription), Billing Schedule, Product Rule, Order Product | `sf-revenue-cloud` |

3. **Defer.** Emit the single-line handoff from the pre-check reference and stop generic work:

   ```
   Detected {industry} is installed. Routing to sf-{industry-skill} because this
   request touches {matched object/process}.
   ```

4. **Proceed only when clean.** If no industry signal is positive, OR the user has explicitly opted out ("use standard Salesforce", "bypass the industry overlay"), OR the request is pure generic infrastructure (e.g., a stock Campaign on a standard Account model the industry doesn't extend), proceed to Phase 1.

**NEVER silently override an industry data model.** Industry-owned objects have shared sharing rules, package-managed automation, and license-gated UX that generic Sales Cloud patterns will corrupt. If in doubt, halt and forward.

---

## Required context to gather first

Collect or infer before Phase 1:

- **Org edition** — Enterprise, Unlimited, or Performance. Many Sales Cloud features (Collaborative Forecasts, Territory Management 2.0, Einstein for Sales, Pipeline Inspection, Revenue Intelligence) have edition gates.
- **Add-on licenses** — Sales Engagement (formerly HVS), Sales Dialer, Einstein for Sales, Revenue Intelligence, Pipeline Inspection, Einstein Activity Capture user licenses. Feature permission sets are distinct from the base license.
- **Currency model** — single-currency vs multi-currency; advanced currency management for opportunity history.
- **Person Account mode** — on or off. If on, lead conversion rules differ.
- **B2B vs B2C lead model** — B2B uses Lead → Contact + Account + Opportunity conversion; some orgs use Leads for B2C even with Person Account.
- **Territory model** — Enterprise Territory Management (ETM 2.0) active vs legacy Territory Management vs pure role hierarchy + assignment rules.
- **Forecast maturity** — no forecasts, Collaborative Forecasts (single-type), Collaborative Forecasts (multi-type), custom Analytics-based forecasting.
- **Cadence maturity** — no Sales Engagement, HVS-era cadences, current Sales Engagement cadences, or custom work queue only.
- **Personas** — SDR, AE, Sales Manager, Sales Ops, RevOps, CRO. Different personas surface different routing decisions.
- **Downstream integrations** — Revenue Cloud, Marketing Cloud, Data Cloud, ERP / billing, data warehouse.
- **Industry overlay** — confirmed clean from Phase 0.

If any of these are missing and the user cannot supply them, state the assumption in the final report rather than blocking.

---

## Workflow phases

### Phase 1 — Scope + routing decision

1. Confirm industry pre-check is clean (or exception documented).
2. Classify the request against the delegate table above. If it is purely localized, hand off immediately — do not produce orchestrator-level output for a single-phase ask.
3. If multi-capability, sketch the capability map: which Sales Cloud areas are in scope, which are out of scope, and which are hand-offs to adjacent skills (Revenue Cloud, Service Cloud, Marketing, Data Cloud).

### Phase 2 — Data model baseline

1. Verify the Account / Contact model: B2B (Business Accounts), B2C (Person Accounts), or hybrid. Confirm this matches the user's sales motion.
2. Verify Lead model: standard Leads vs lead-less B2C. Confirm lead conversion mapping (Lead fields → Account/Contact/Opportunity fields) is explicit, not implicit.
3. Confirm Opportunity record types, stage values, forecast categories, and probability mapping. Opportunities drive forecasts, pipeline, and Revenue Intelligence — a sloppy stage model corrupts every downstream surface.
4. Confirm Product + Price Book strategy. Multi-currency, multi-price-book, and bundle strategies should be explicit before any Quote work.
5. Confirm Campaign model: Campaign Member statuses per campaign type, Campaign Hierarchy, Campaign Influence (1.0 vs Customizable).
6. If any object is industry-owned in the detected industry, re-run Phase 0 for that object.

### Phase 3 — Process + automation

1. Lead routing + assignment rules, lead scoring (Einstein or custom), lead conversion automation.
2. Opportunity process: stage-entry criteria, required fields per stage, Big Deal Alerts, Opportunity Team auto-add, Opportunity Contact Role population.
3. Territory assignment: ETM rules, manual assignments, inherited territories for opportunities.
4. Activity capture + engagement: decide between Einstein Activity Capture (EAC), Salesforce Inbox / Sales Engagement, or a custom activity strategy. Delegate rollout detail to `sf-sales-engagement`.
5. Forecast submission cadence and adjustment policy — delegate detail to `sf-sales-forecasting`.
6. Quote-to-Order hand-off — delegate detail to `sf-revenue-cloud` if CPQ/RCA, otherwise keep in standard Quote/Order flow.

### Phase 4 — Intelligence + analytics

1. Einstein for Sales activation: Opportunity Scoring, Lead Scoring, Einstein Forecasting, Einstein Conversation Insights. Each has its own permission set and data maturity prerequisite (typically 12 months of closed-won/closed-lost).
2. Pipeline Inspection: activate metric configuration, change filters, inline Opportunity updates, deal momentum indicators.
3. Deal Insights: engagement signals, relationship signals, deal change signals.
4. Revenue Intelligence / Sales Analytics: verify license coverage, dataset refresh cadence, and dashboard stewardship.
5. Confirm that every AI surface's training data passes the industry pre-check — industry-owned fields cannot be silently fed into generic Einstein models.

### Phase 5 — Delegation + hand-off

1. Produce a routing plan listing each downstream skill and the scope it owns.
2. Hand off each localized area to its phase skill with the context gathered in Phases 2–4.
3. Reserve orchestrator responsibility for cross-cutting decisions only (data model alignment, industry guardrails, license coverage).

### Phase 6 — Verification + report

1. Confirm industry pre-check was run, documented, and passed (or exception justified).
2. Confirm each routed phase skill has been engaged (or scheduled to be).
3. Confirm no orchestrator-level artifact silently reimplements a delegate's methodology.
4. Report in the format below.

---

## Scoring rubric (150 pts)

| Category | Points | Pass threshold |
|---|---|---|
| Phase 0 industry pre-check executed + documented | 25 | All three detection signals checked, deferral emitted if positive |
| Correct scope classification (orchestrator vs phase skill) | 20 | Single-phase work routed to the phase skill without orchestrator noise |
| Data model baseline (Account/Contact/Lead/Opportunity/Product/Campaign) | 20 | Each object's record-type / stage / status strategy explicit |
| Process + automation coverage | 20 | Lead routing, stage gates, territory assignment, activity capture all addressed |
| Intelligence + analytics coverage | 15 | Einstein licenses, Pipeline Inspection, Deal Insights, Revenue Intelligence evaluated |
| Edition + license gates called out | 10 | Every feature tagged with required edition/license/PSL |
| Delegation to phase skills done cleanly | 15 | Opportunity / Forecasting / Engagement / Revenue Cloud handed off with context |
| Adjacent-skill hand-offs (Service, Marketing, Data Cloud) identified | 10 | Cross-cloud boundaries drawn explicitly |
| Anti-patterns explicitly avoided | 10 | No stage-explosion, no forecast-category silence, no industry-override |
| Verification + final report structure | 5 | Matches the output format below |

Pass = 120 / 150. Below 120, revise before responding.

---

## Anti-patterns

1. **Skipping Phase 0.** Generating a lead-routing or opportunity model without running the industry pre-check. Every industry-installed org that gets a generic Sales Cloud design here will eventually break sharing, forecasting, or AI.
2. **Orchestrator over-reach.** Writing forecast configuration, cadence design, or opportunity splits in this skill instead of delegating. The phase skills exist so this skill stays thin.
3. **Stage explosion.** Recommending more than ~8 Opportunity stages. Stages are a funnel, not a project plan; fine-grained state lives in record-type or status fields, not stages.
4. **Forecast-category silence.** Building a stage model without mapping every stage to a Forecast Category (`Pipeline`, `Best Case`, `Commit`, `Closed`, `Omitted`). Forecasts break silently if even one stage is unmapped.
5. **Silently overriding industry data models.** NEVER silently override an industry data model. Adding a custom field or stage to an industry-owned Opportunity / Account / Lead without deferring to the industry skill corrupts package upgrades.
6. **Conflating Sales Engagement with Service Omni-Channel.** Cadences are sales-led outbound/inbound; Omni-Channel Routing is service-led inbound assignment. Recommending one in place of the other is a license and UX mismatch.
7. **Treating Pipeline Inspection as a report.** Pipeline Inspection is an inline editing + metric-change surface, not a tabular report. Using it as a dashboard misreads the feature.
8. **Einstein activation without data maturity.** Turning on Einstein Opportunity Scoring or Forecasting in an org with less than ~12 months of closed-won + closed-lost history. The model has nothing to learn from.

---

## Common failure modes + remediation

### Symptom: "My forecast numbers don't match my pipeline report."
- **Root cause:** Stage → Forecast Category mapping gaps, or forecast currency mismatch with opportunity currency.
- **Fix:** Re-verify every stage is mapped to a forecast category. Check advanced currency management and forecast type currency. Then delegate to `sf-sales-forecasting` for hierarchy-level adjustment review.

### Symptom: "Opportunity Team members can't edit the deal even though they're on the team."
- **Root cause:** Opportunity Team sharing is OWD-sensitive. With Private OWD on Opportunity, team roles need Read/Write, and Account Team access may also be needed.
- **Fix:** Confirm OWD, opportunity team role access, and account team access together. Delegate detail to `sf-sales-opportunity`.

### Symptom: "Cadence steps aren't firing / reps don't see the next step."
- **Root cause:** Sales Engagement license missing on the user, cadence not assigned via auto-add rule, or target is on a lead vs contact mismatch.
- **Fix:** Verify Sales Engagement permission set license, cadence auto-add entry criteria, and target type alignment. Delegate to `sf-sales-engagement`.

### Symptom: "Einstein Opportunity Scoring says 'not enough data'."
- **Root cause:** < 12 months of closed-won + closed-lost history, or too few opportunities per segment, or fields the model needs are blank.
- **Fix:** Confirm data maturity, segment the model by record type if volume allows, and fill required fields. Hold off on activation until the model has signal.

### Symptom: "Territory assignment isn't inheriting on new opportunities."
- **Root cause:** Enterprise Territory Management needs explicit enablement + `RunAssignmentRules` on Opportunity create; legacy Territory Management behaves differently.
- **Fix:** Confirm ETM vs legacy, enable opportunity territory assignment, and run the `RunAssignmentRules` invocation. Route detail work to `sf-sales-opportunity`.

---

## CLI / metadata cheat sheet

Readiness + inspection (always safe, read-only):

```bash
# Confirm edition + licenses for Phase 0 pre-check
sf org display --json
sf org list metadata-types --json

# Industry namespace quick scan
sf data query --target-org <alias> --query "SELECT NamespacePrefix FROM ApexClass WHERE NamespacePrefix != NULL" --use-tooling-api

# Opportunity stage + forecast category mapping
sf data query --target-org <alias> --query "SELECT MasterLabel, ForecastCategory, IsClosed, IsWon FROM OpportunityStage ORDER BY SortOrder"

# Forecast type inventory
sf data query --target-org <alias> --query "SELECT DeveloperName, ForecastObject, SourceDefinitionApiName FROM ForecastingType"

# Territory model check
sf data query --target-org <alias> --query "SELECT Name, TerritoryType.Name FROM Territory2"

# Sales Engagement cadence count
sf data query --target-org <alias> --query "SELECT Id, Name, State FROM ActionCadence"

# Einstein feature enablement quick check
sf data query --target-org <alias> --query "SELECT MasterLabel, DeveloperName FROM PermissionSet WHERE Name LIKE 'Einstein%'"
```

Metadata surfaces owned by this orchestrator (route detailed authoring to phase skills):

- `OpportunityStage` (picklist + forecast category)
- `ForecastingType` (forecast type definition)
- `Territory2Model` + `Territory2` (ETM)
- `ActionCadence` + `ActionCadenceStep` (Sales Engagement)
- `EmailTemplate` (Lightning email templates feeding cadences)
- `CampaignMemberStatus` per campaign type

Features gated by edition / license:

- Collaborative Forecasts — Enterprise+
- Enterprise Territory Management — Enterprise+, separate activation
- Sales Engagement — add-on PSL
- Sales Dialer — add-on PSL + number provisioning
- Einstein for Sales — add-on license per feature
- Pipeline Inspection — included Enterprise+ with data maturity
- Revenue Intelligence — add-on license, Tableau-backed

---

## Output format

When finishing, report in this order:

```text
Sales Cloud task: <multi-phase design / audit / remediation / rollout>
Phase 0 industry pre-check: <clean / deferred to sf-industry-X (reason)>
Edition + license gates: <Enterprise/Unlimited + add-ons confirmed>
Capability scope: <leads / accounts / opps / campaigns / products / quotes / territory / engagement / forecasting / intelligence>
Delegations:
  - Opportunity work → sf-sales-opportunity
  - Forecasts → sf-sales-forecasting
  - Engagement → sf-sales-engagement
  - Quote-to-Cash → sf-revenue-cloud (if applicable)
  - Cross-cloud → sf-service-cloud / sf-marketing-* / sf-datacloud (as applicable)
Data model baseline: <Account/Contact/Lead/Opp/Product/Campaign decisions>
Process + automation: <lead routing / stage gates / territory / activity capture>
Intelligence: <Einstein features / Pipeline Inspection / Deal Insights / Revenue Intelligence>
Verification: <industry-clean / licenses confirmed / delegations opened>
Next step: <specific phase skill invocation or user decision point>
```

---

## Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Opportunity modeling, splits, teams, pipeline inspection | [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md) | dedicated deal methodology |
| Collaborative Forecasts, forecast types, adjustments, quotas | [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md) | dedicated forecast methodology |
| Cadences, Sales Dialer, EAC, prioritized work | [sf-sales-engagement](../sf-sales-engagement/SKILL.md) | dedicated engagement methodology |
| Quote-to-Cash, CPQ, RCA | [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md) | revenue lifecycle past the Opportunity |
| Case, Entitlement, Omni-Channel | [sf-service-cloud](../sf-service-cloud/SKILL.md) | post-sale service |
| Campaign execution, journeys, sends | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) / [sf-marketing-account-engagement](../sf-marketing-account-engagement/SKILL.md) | top-of-funnel |
| Unified profile, segmentation, activation | [sf-datacloud](../sf-datacloud/SKILL.md) | cross-source unified view |
| Apex / LWC / Flow implementation detail | [sf-apex](../sf-apex/SKILL.md), [sf-lwc](../sf-lwc/SKILL.md), [sf-flow](../sf-flow/SKILL.md) | code and declarative mechanics |
| Nonprofit donation / gift / program work | [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md), [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) | nonprofit overlay |

---

## Reference map

- [Industry pre-check reference](../../references/industry-precheck.md) — MANDATORY Phase 0
- [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md)
- [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md)
- [sf-sales-engagement](../sf-sales-engagement/SKILL.md)
- [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md)
- [sf-service-cloud](../sf-service-cloud/SKILL.md)
- [sf-datacloud](../sf-datacloud/SKILL.md)
