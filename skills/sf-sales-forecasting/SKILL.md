---
name: sf-sales-forecasting
description: >
  Sales Cloud Collaborative Forecasts: forecast types (Revenue, Quantity, Custom),
  forecast categories, forecast hierarchies, adjustments, submissions, cumulative
  rollups, quotas, partner forecasts, and forecast sharing, with industry-first
  routing precedence.
  TRIGGER when: user sets up or troubleshoots Collaborative Forecasts and says
  things like "enable Collaborative Forecasts", "set up forecast types for
  Revenue and Quantity", "build a custom forecast type on OpportunityLineItem",
  "configure the forecast hierarchy with role-based managers", "override the
  forecast hierarchy because the role hierarchy doesn't match sales management",
  "load quotas for Q3", "allow managers to submit adjustments", "show me
  cumulative forecast rollups", "configure partner forecasts for channel",
  "turn on forecast sharing with Sales Ops", "submit a forecast for this period",
  "why does my forecast show zero", "map stage to forecast category", "split
  revenue into forecast types by product family", or any other Collaborative
  Forecasts / quota / adjustment question.
  DO NOT TRIGGER when: the request is a multi-capability Sales Cloud design (use
  sf-sales-cloud); the request is about Opportunity modeling, stages, splits,
  teams, contact roles, Pipeline Inspection, or Deal Insights (use
  sf-sales-opportunity); the request is about cadences, Sales Dialer, EAC, or
  prioritized work (use sf-sales-engagement); the org has Financial Services
  Cloud and the forecast is AUM-based or advisor book-of-business (use
  sf-industry-fsc); the org has Health Cloud and the forecast is a payer /
  provider network pipeline (use sf-industry-health); the org has Education
  Cloud or EDA and the forecast is an advancement / giving forecast on EDA
  (use sf-industry-education); the org has Public Sector Solutions and the
  forecast is a grant funding pursuit (use sf-industry-public-sector); the
  request is Field Service capacity forecasting on Service Appointments
  (use sf-field-service); the org has Nonprofit Cloud and the "forecast" is a
  pledged-gift or grant-award pipeline on NPC (use sf-nonprofit-cloud); the
  org has NPSP and the "forecast" is a donation pipeline on NPSP (use
  sf-nonprofit-npsp); the org has Manufacturing Cloud and the forecast is an
  Account Forecast / Advanced Account Forecast / Sales Agreement forecast
  (use sf-industry-manufacturing); the org has Consumer Goods Cloud and the
  forecast is a Trade Promotion volume forecast (use sf-industry-consumer-goods);
  the org has Communications Cloud and the forecast is MRR / ARR on
  subscription carts (use sf-industry-communications); the org has Media Cloud
  and the forecast is subscription revenue / entitlement (use sf-industry-media);
  the org has Energy & Utilities Cloud and the forecast is load / service-point
  revenue (use sf-industry-energy); the request is Revenue Cloud Advanced
  revenue waterfall, Billing Schedule, or Subscription Management revenue
  recognition (use sf-revenue-cloud); the request is Service Cloud KPI
  dashboards (use sf-service-cloud); the request is marketing pipeline-source
  reporting (use sf-marketing-cloud-growth or sf-marketing-account-engagement);
  the work is Apex code quality (use sf-apex); the work is LWC (use sf-lwc);
  the work is Flow XML mechanics (use sf-flow); the work is Data Cloud (use
  sf-datacloud); the work is nonprofit fundraising (use sf-nonprofit-fundraising);
  the work is NPSP configuration (use sf-nonprofit-npsp).
license: MIT
compatibility: "Requires Sales Cloud edition with Collaborative Forecasts; industry-first routing applies"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.forecasts3_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.forecasts3_types.htm
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

# sf-sales-forecasting: Collaborative Forecasts, Types, and Adjustments

Owns Collaborative Forecasts end to end: forecast types (Revenue, Quantity, Custom on OLI / Splits / Product Families / custom number fields), forecast categories, hierarchy design, adjustment policy, quota loading, partner forecasts, cumulative rollups, and forecast sharing. Opportunity modeling, splits, and pipeline inspection are upstream of this skill and handed off to `sf-sales-opportunity`; cadences and dialer are out of scope.

---

## When this skill owns the task

Use `sf-sales-forecasting` when the work involves:

- Enabling Collaborative Forecasts for the first time
- Defining or editing **Forecast Types** — Revenue, Quantity, Custom (OLI, Product Family, Opportunity Split, custom numeric fields)
- Mapping Opportunity stages to **Forecast Categories** (`Pipeline` / `Best Case` / `Commit` / `Closed` / `Omitted`)
- Designing the **Forecast Hierarchy** — usually derived from role hierarchy, but can be overridden
- Adjustment policy — who can adjust, what levels show adjustments (manager + own), audit trail
- Forecast submission cadence and lock/unlock policy
- Quota loading — bulk upload via Data Loader, per-period, per-type
- Partner forecasts — channel manager visibility into partner user pipeline
- Cumulative Forecast Rollups (vs individual category rollups)
- Forecast Sharing — extending the default hierarchical visibility to specific users (Sales Ops, BI)
- Multi-currency forecasts and currency rate-at-forecast-time decisions

Delegate elsewhere when:

| Scope | Route to |
|---|---|
| Opportunity stage model, splits, teams, contact roles, pipeline inspection | [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md) |
| Cadence-driven activity that affects forecast inputs | [sf-sales-engagement](../sf-sales-engagement/SKILL.md) |
| Multi-capability design (lead-to-cash, Einstein, intelligence) | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) |
| Revenue recognition, subscription waterfall, Billing Schedule | [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md) |
| Apex / LWC / Flow implementation | [sf-apex](../sf-apex/SKILL.md) / [sf-lwc](../sf-lwc/SKILL.md) / [sf-flow](../sf-flow/SKILL.md) |

---

## Phase 0: Industry Pre-Check (MANDATORY)

**Before any forecast design, run the shared industry pre-check.** See [references/industry-precheck.md](../../references/industry-precheck.md) for the full detection + deferral protocol.

Procedure:

1. **Detect.** Run license / namespace / object scans per the reference.
2. **Cross-reference.** If the user's "forecast" is actually an industry-packaged forecast artifact, halt and forward:

   | Detected | "Forecast" is really | Route to |
   |---|---|---|
   | FSC (`FinServ__`) | AUM book-of-business, wealth pipeline tied to Financial Accounts | `sf-industry-fsc` |
   | Health Cloud (`HealthCloudGA__`) | Payer contracting pipeline, provider network forecast | `sf-industry-health` |
   | Education Cloud / EDA (`hed__`) | Advancement / gift cultivation forecast on EDA | `sf-industry-education` |
   | Public Sector (`OutfundsPS__`) | Grant funding pursuit / benefit disbursement forecast | `sf-industry-public-sector` |
   | Field Service | Service Appointment capacity / resource utilization forecast | `sf-field-service` |
   | Nonprofit Cloud | Pledged-gift pipeline, grant-award forecast | `sf-nonprofit-cloud` + children |
   | NPSP | Donation pipeline on Opportunity-as-donation | `sf-nonprofit-npsp` |
   | Manufacturing Cloud | Account Forecast, Advanced Account Forecast, Sales Agreement forecast | `sf-industry-manufacturing` |
   | Consumer Goods Cloud | Trade Promotion volume forecast, Visit outcomes | `sf-industry-consumer-goods` |
   | Communications Cloud (`vlocity_cmt__`) | MRR / ARR forecast on subscription cart | `sf-industry-communications` |
   | Media Cloud (`vlocity_media__`) | Subscription revenue / entitlement forecast | `sf-industry-media` |
   | Energy & Utilities (`vlocity_ins__` + E&U) | Load forecast, service-point revenue forecast | `sf-industry-energy` |
   | Revenue Cloud Advanced / CPQ | Revenue waterfall, Billing Schedule projection | `sf-revenue-cloud` |

3. **Defer.** Emit the standard handoff line and stop generic work.
4. **Proceed only when clean** or the user has explicitly opted out or the forecast is purely standard Opportunity Amount / Quantity on a stock data model.

**NEVER silently override an industry data model.** Building a Collaborative Forecast on top of Sales Agreements, Gift Transactions, or Subscription carts produces numbers that don't match the industry's own forecast surface and silently loses the industry's richer aggregation.

---

## Required context to gather first

- **Edition** — Enterprise+ is the minimum for Collaborative Forecasts; Unlimited / Performance unlocks more forecast types.
- **Current forecast surface** — none, Collaborative Forecasts (single-type), Collaborative Forecasts (multi-type), custom Analytics forecast.
- **Forecast object** — Opportunity, OpportunityLineItem (OLI), OpportunitySplit. Each is a different forecast type.
- **Measure** — Amount (Revenue), Quantity, a custom currency field (e.g., ARR), or a custom number field.
- **Period** — monthly vs quarterly vs custom fiscal year; multi-month rollup behavior.
- **Hierarchy source** — role hierarchy as-is, role hierarchy with forecast-specific overrides, or custom sales management hierarchy distinct from role hierarchy.
- **Adjustment policy** — who adjusts (manager only / own forecast), granularity (per category / cumulative), locking.
- **Quotas** — who owns them (Sales Ops), how they're loaded (Data Loader / API), per-type and per-period.
- **Partner visibility** — are channel managers forecasting partner user pipeline?
- **Multi-currency** — dated exchange rates, forecast currency display.
- **Industry overlay** — confirmed clean from Phase 0.

---

## Workflow phases

### Phase 1 — Enablement + forecast type inventory

1. Enable Collaborative Forecasts in Setup. Confirm the base permission set for forecast users (Forecast User feature license is distinct from the feature itself).
2. Inventory the forecast types the business actually needs. Do not create every type — unused forecast types dilute the UX and confuse managers.
3. For each type, decide:
   - **Measure**: Revenue (Amount), Quantity, Custom currency, Custom number
   - **Object**: Opportunity, OLI, OpportunitySplit
   - **Date field**: Close Date (standard), Schedule Date (revenue scheduling), custom date
   - **Filter**: record types, product families, include/exclude closed-lost
4. If a forecast type depends on Opportunity Splits, confirm `sf-sales-opportunity` has split design complete first.

### Phase 2 — Stage → forecast category mapping

1. Pull the current Opportunity stage picklist and its forecast category assignments. This is a cross-skill boundary — `sf-sales-opportunity` owns stage picklist, `sf-sales-forecasting` owns the consequences.
2. Verify every stage is mapped. Unmapped stages default to `Pipeline` silently and produce confusion when closed-won deals appear as pipeline.
3. Verify closed stages map to `Closed` (won) or `Omitted` (lost / disqualified).
4. Verify `Best Case` and `Commit` are used deliberately. Some orgs skip `Best Case` and rely on adjustments — that is a legitimate policy decision, not an error.

### Phase 3 — Forecast hierarchy

1. Inspect the role hierarchy. Collaborative Forecasts derives the forecast hierarchy from role hierarchy by default.
2. Identify role-hierarchy mismatches where sales management doesn't follow the role tree (common in matrixed orgs).
3. Assign forecast managers per role node. A role without an assigned forecast manager rolls up to the next higher manager — usually acceptable, sometimes wrong.
4. Confirm forecast user status on every manager account. Read-only users cannot adjust.

### Phase 4 — Quotas + adjustments + submissions

1. **Quotas** — decide per-type, per-period, per-user. Load via `ForecastingQuota` API (Data Loader or `sf data import bulk`). Confirm quota fiscal period matches forecast period.
2. **Adjustments** — decide whether managers can adjust their own forecast, their direct reports' forecast (default), or the full subtree. Decide granularity: per forecast category vs cumulative.
3. **Submissions** — decide whether submissions are required per period (locks forecast after submission) or advisory.
4. Audit trail — confirm `ForecastingAdjustment` history is retained and that Sales Ops can review adjustment deltas.

### Phase 5 — Cumulative rollups, partner forecasts, sharing

1. **Cumulative rollups** — enable if managers want to see `Open Pipeline` = Pipeline + Best Case + Commit as a single number. Disable if categories should be reported discretely.
2. **Partner forecasts** — if channel managers own partner-user pipeline, enable partner forecasts and confirm partner user license coverage.
3. **Forecast sharing** — by default, forecasts roll up through the hierarchy only. Grant Sales Ops / BI / RevOps explicit `ForecastingShare` access to view without being in the hierarchy.

### Phase 6 — Verification + report

1. Run end-to-end smoke: create an opportunity at a pipeline stage, confirm it appears in the forecast; advance to commit, confirm it moves; close won, confirm it appears in Closed.
2. Confirm adjustments apply and audit history records.
3. Confirm quota loading completed for the current period.
4. Confirm partner forecasts (if enabled) show partner user pipeline.
5. Confirm the hand-off back to `sf-sales-opportunity` for any stage-model changes required.

---

## Scoring rubric (120 pts)

| Category | Points | Pass threshold |
|---|---|---|
| Phase 0 industry pre-check executed + documented | 20 | Industry detection run; deferral emitted if positive |
| Forecast type inventory (measure + object + filter) | 15 | Each active type has explicit measure, object, date, filter |
| Stage → Forecast Category mapping complete | 20 | Every stage mapped; closed-won not in Pipeline |
| Forecast hierarchy design | 15 | Role mismatches called out; forecast managers assigned |
| Quota loading strategy | 10 | Data Loader / API path documented; period + type alignment verified |
| Adjustment policy (who / granularity / audit) | 10 | Explicit policy; audit retention confirmed |
| Submission policy (required vs advisory, locking) | 5 | Policy documented |
| Cumulative rollups + partner forecasts + sharing | 10 | Each decision explicit |
| Multi-currency handling | 5 | Dated rates and display currency decided |
| Anti-patterns explicitly avoided | 10 | No unmapped stages, no role-hierarchy silence, no industry override |

Pass = 96 / 120. Below 96, revise.

---

## Anti-patterns

1. **Skipping Phase 0.** Building a Collaborative Forecast in a Manufacturing / Revenue Cloud / Nonprofit / FSC org without checking the industry pre-check first.
2. **Silently overriding an industry data model.** NEVER silently override an industry data model. Manufacturing Cloud has its own Account Forecast; Revenue Cloud has its own revenue waterfall; NPSP has its own donation pipeline reporting. Adding a generic Collaborative Forecast on top doesn't replace them — it duplicates and diverges from them.
3. **Unmapped stages.** Leaving Opportunity stages with no Forecast Category. Silent default is `Pipeline`, which eventually produces the "why is this closed-won in my pipeline forecast" support ticket.
4. **Role-hierarchy silence.** Assuming the role hierarchy is the sales management hierarchy. It often isn't. Override the forecast hierarchy where they diverge.
5. **Too many forecast types.** Creating Revenue, Quantity, OLI-by-product-family, Split-by-overlay, and three custom types from day one. Managers ignore what they don't trust. Start with one or two; add only when there's a proven management cadence for each.
6. **Adjustment free-for-all.** Allowing every rep to adjust their own forecast without a submission lock. Produces drift between rep commitment and manager commitment.
7. **Quota period mismatch.** Loading quarterly quotas into a monthly forecast period, or vice versa. The UX silently divides / multiplies and confuses everyone.
8. **Forecasting splits on overlay splits.** Overlay splits can sum above 100%. Running the forecast type on overlay splits rather than revenue splits inflates the number. Revenue splits are the only split type safe for revenue forecasts.

---

## Common failure modes + remediation

### Symptom: "My forecast shows zero even though I have pipeline."
- **Root cause:** User isn't in the forecast hierarchy, or the forecast type's date field is out of the current period, or the stage→category mapping excludes the user's deals.
- **Fix:** Verify forecast user status, forecast type date field vs close date, and stage→category mapping. Most commonly the user is a forecast user but not in the hierarchy.

### Symptom: "Closed-won deals are showing in Pipeline."
- **Root cause:** Stage → forecast category mapping has a closed-won stage mapped to `Pipeline` or unmapped.
- **Fix:** Coordinate with `sf-sales-opportunity` to fix the stage picklist metadata; re-check every stage.

### Symptom: "Manager can't adjust subordinates' forecast."
- **Root cause:** Forecast adjustment policy is set to "own only", or manager isn't assigned as forecast manager for the subordinate's role.
- **Fix:** Update adjustment policy in Setup → Forecasts → Forecast Settings; verify forecast manager assignment per role.

### Symptom: "Quotas loaded but don't appear in the UI."
- **Root cause:** Fiscal period mismatch (monthly quotas with quarterly forecast), or quota loaded against the wrong forecast type.
- **Fix:** Confirm `ForecastingQuota.PeriodId` and `ForecastingTypeId`. Re-load with the correct IDs.

### Symptom: "Partner forecasts aren't rolling up to the channel manager."
- **Root cause:** Partner forecasts not enabled, or partner users lack forecast feature license, or the channel manager isn't in the partner forecast hierarchy.
- **Fix:** Enable partner forecasts, license partner users, and add channel manager as forecast manager in the partner hierarchy branch.

---

## CLI / metadata cheat sheet

```bash
# Forecast type inventory
sf data query --target-org <alias> --query "SELECT DeveloperName, MasterLabel, ForecastObject, SourceDefinitionApiName, IsActive FROM ForecastingType"

# Stage → Forecast Category map
sf data query --target-org <alias> --query "SELECT MasterLabel, ForecastCategory, IsClosed, IsWon FROM OpportunityStage ORDER BY SortOrder"

# Forecast hierarchy (forecast managers per role)
sf data query --target-org <alias> --query "SELECT RoleId, UserId FROM UserRole WHERE UserId != NULL" --use-tooling-api

# Quotas for current period
sf data query --target-org <alias> --query "SELECT QuotaOwnerId, QuotaAmount, ForecastingTypeId, StartDate FROM ForecastingQuota WHERE StartDate = THIS_QUARTER"

# Adjustments audit
sf data query --target-org <alias> --query "SELECT Id, AdjustedAmount, AdjustmentNotes, CreatedDate, CreatedById FROM ForecastingAdjustment ORDER BY CreatedDate DESC LIMIT 50"

# Forecast share (explicit grants beyond hierarchy)
sf data query --target-org <alias> --query "SELECT UserOrGroupId, AccessLevel, ForecastingTypeId FROM ForecastingShare WHERE RowCause = 'Manual' LIMIT 50"
```

Metadata surfaces owned here:

- `ForecastingType` (forecast type definition)
- `ForecastingQuota` (per-user, per-period, per-type)
- `ForecastingAdjustment` (manager and rep adjustments)
- `ForecastingShare` (explicit sharing beyond hierarchy)
- `ForecastingUserPreference` (user-level display config)

Feature / license gates:

- Collaborative Forecasts — Enterprise+
- Custom Forecast Types — Enterprise+
- Forecast feature license — per forecast user
- Partner Forecasts — requires partner user licenses + separate enablement

---

## Output format

```text
Forecasting task: <enablement / new type / hierarchy / adjustments / quotas / partner / sharing>
Phase 0 industry pre-check: <clean / deferred to sf-industry-X (reason)>
Edition + license gates: <Enterprise+ / forecast users confirmed>
Forecast types: <list active types with measure, object, filter>
Stage → forecast category map: <complete / gaps at stages: X, Y>
Hierarchy: <role-hierarchy-derived / overridden where>
Quotas: <loaded for period: X / data path: Y>
Adjustments + submissions: <policy>
Cumulative / partner / sharing: <each decided>
Hand-offs: <sf-sales-opportunity for stage changes / sf-sales-cloud orchestrator for cross-cutting>
Verification: <smoke test passed / quota period aligned>
Next step: <specific config, or re-engage phase skill>
```

---

## References

- [Industry pre-check reference](../../references/industry-precheck.md) — MANDATORY Phase 0
- [sf-sales-cloud orchestrator](../sf-sales-cloud/SKILL.md)
- [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md)
- [sf-sales-engagement](../sf-sales-engagement/SKILL.md)
- [sf-revenue-cloud](../sf-revenue-cloud/SKILL.md)
