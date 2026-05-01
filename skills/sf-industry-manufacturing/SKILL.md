---
name: sf-industry-manufacturing
description: >
  Manufacturing Cloud architecture stub with industry-first routing precedence.
  Owns namespace claim and industry-specific process routing; delegates
  implementation to OmniStudio common-core skills.
  TRIGGER when: user says "sales agreement forecast", "account forecast in Manufacturing Cloud",
  "rebate program for distributors", "advanced account forecast", "demand plan",
  "partner channel for manufacturers", "manufacturing work order", or designs
  revenue commitments, run-rate business, or channel partner programs on Manufacturing Cloud.
  DO NOT TRIGGER when: generic Sales Cloud pipeline (use sf-sales-cloud), generic
  Service Cloud case work (use sf-service-cloud), Apex-only work (use sf-apex),
  LWC-only work (use sf-lwc), Flow-only work (use sf-flow), OmniScript build
  (use sf-industry-commoncore-omniscript), Integration Procedure build
  (use sf-industry-commoncore-integration-procedure), Data Mapper build
  (use sf-industry-commoncore-datamapper), FlexCard build
  (use sf-industry-commoncore-flexcard), callable Apex for IPs
  (use sf-industry-commoncore-callable-apex), OmniStudio dependency analysis
  (use sf-industry-commoncore-omnistudio-analyze), or Data Cloud work (use sf-datacloud).
license: MIT
compatibility: "Requires Manufacturing Cloud license (standard namespace — no vlocity managed package)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.mfg_admin_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/manufacturing
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_manufacturing.htm
---

## When this skill owns the task

Own the task whenever the org is Manufacturing Cloud and the work touches industry-specific objects: `SalesAgreement`, `AccountForecast`, `AdvancedAccountForecast`, `RebateProgram`, `ManufacturingWorkOrder`, or run-rate / channel-partner processes. Anchor processes:

- Sales agreement lifecycle (create, activate, revise, renew)
- Account forecasting (standard + Advanced)
- Rebate program setup, payout calc, member enrollment
- Partner channel / distributor programs
- Manufacturing-specific work order routing

Do NOT own generic pipeline or CPQ — route to `sf-sales-cloud` / `sf-service-cloud`.

## Industry precedence note

When Manufacturing Cloud is detected (license + `SalesAgreement`/`AccountForecast`), this skill wins over `sf-sales-cloud`/`sf-service-cloud`. Implementation (UI, orchestration, mapping) delegates to `sf-industry-commoncore-*`. Manufacturing Cloud uses the **standard namespace** — no `vlocity_*__`.

## Required context to gather first

1. Manufacturing Cloud edition + license add-on?
2. Advanced Account Forecast enabled?
3. Rebate Management licensed?
4. OmniStudio present?
5. Partner/Experience Cloud for distributor portal?

## Workflow phases

1. **Detection** — confirm license + `SalesAgreement`/`AccountForecast`.
2. **Process ID** — agreement, forecast, rebate, WO, or channel.
3. **Route** — OmniStudio work → common-core; standard automation → `sf-flow`/`sf-apex`; domain rules stay here.
4. **Testing** — `sf-testing` + `sf-demo-validate`.

## Scoring rubric (50 points)

| Category | Pts | Criteria |
|---|---|---|
| Industry detection | 10 | Manufacturing Cloud vs generic Sales Cloud identified |
| Object model | 10 | `SalesAgreement`/`AccountForecast` used; no Opportunity workaround |
| Process routing | 10 | OmniStudio work delegated; domain rules kept here |
| Namespace hygiene | 10 | No `vlocity_*__` — standard API names |
| License gating | 10 | Rebate/Advanced Forecast add-ons confirmed |

## Anti-patterns

- Modeling sales agreements as custom Opportunities — use `SalesAgreement`.
- Forecast rollups in Apex when `AccountForecast` auto-calculates.
- Assuming `vlocity_cmt__` — Manufacturing is standard namespace.
- Rebate calc in Flow — use Rebate Management engine.
- Reusing Field Service `WorkOrder` instead of `ManufacturingWorkOrder`.

## Industry object cheat sheet

| Object | Purpose |
|---|---|
| `SalesAgreement` | Revenue commitment header |
| `SalesAgreementProduct` | Agreement line |
| `AccountForecast` | Period forecast rollup |
| `AccountForecastPeriodMetric` | Per-period metric values |
| `AdvancedAccountForecast` | Data Cloud-backed ML forecast |
| `RebateProgram` | Rebate rules header |
| `RebateProgramMember` | Enrolled account |
| `RebateMemberProduct` | Product-level rate |
| `RebatePayout` | Calculated payout |
| `ManufacturingWorkOrder` | Plant-floor WO |
| `ProductionSchedule` | Planned production runs |
| `ChannelProgramMember` | Partner enrollment |
| `PartnerFundRequest` | MDF/co-op request |
| `PartnerFundClaim` | Claim vs approved fund |

## Delegation table

| Concern | Skill |
|---|---|
| OmniScript wizard (agreement revision) | `sf-industry-commoncore-omniscript` |
| IP (ERP sync, forecast refresh) | `sf-industry-commoncore-integration-procedure` |
| Data Mapper (ERP → SalesAgreement) | `sf-industry-commoncore-datamapper` |
| FlexCard (agreement summary) | `sf-industry-commoncore-flexcard` |
| Callable Apex for IPs | `sf-industry-commoncore-callable-apex` |
| Namespace / dependency audit | `sf-industry-commoncore-omnistudio-analyze` |
| Custom Apex (rebate calc ext) | `sf-apex` |
| Record-triggered automation | `sf-flow` |
| Forecast source in Data Cloud | `sf-datacloud` |
