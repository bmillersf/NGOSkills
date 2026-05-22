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
  scoring: "50 points across 5 categories — Industry detection 10 / Object model 10 / Process routing 10 / Namespace hygiene 10 / License gating 10"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "50-pt rubric (5 categories) extracted from existing 'Scoring rubric (50 points)' section in this SKILL.md (line 72). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  manufacturing_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Industry detection + Object model. Maps to Industry detection (10) + Object model (10). Manufacturing Cloud detection + correct first-class object usage (SalesAgreement / AccountForecast / RebateProgram / ManufacturingWorkOrder)."
      automatic_hard_fail_rules:
        - "Manufacturing Cloud detected but Sales Cloud objects (Opportunity / Quote) used instead of SalesAgreement / AccountForecast (industry override)"
        - "Sales agreements modeled as custom Opportunities instead of SalesAgreement"
        - "Account forecasting rolled up via Apex when AccountForecast auto-calculates"
        - "Rebate calculation built in Flow when Rebate Management engine handles it"
        - "Field Service WorkOrder reused for plant-floor work instead of ManufacturingWorkOrder"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "License gating. Maps to License gating (10). Add-ons (Rebate Management, Advanced Account Forecast) confirmed present before recommending features that depend on them."
      automatic_hard_fail_rules:
        - "Rebate Management features recommended without confirming Rebate Management license"
        - "Advanced Account Forecast features recommended without confirming Advanced add-on license"
        - "Distributor portal / Partner Channel features recommended without confirming Experience Cloud / Partner license"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Process routing + Delegation hygiene. Maps to Process routing (10). OmniStudio work delegated to common-core; standard automation to sf-flow/sf-apex; domain rules stay here."
      automatic_hard_fail_rules:
        - "OmniScript / IP / Data Mapper / FlexCard / Callable Apex authoring done here instead of delegated to sf-industry-commoncore-*"
        - "Standard automation work (Record-Triggered Flow / Apex) authored in this skill instead of routed to sf-flow / sf-apex"
        - "Generic Sales Cloud pipeline work handled here (route to sf-sales-cloud)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Namespace hygiene. Maps to Namespace hygiene (10). Manufacturing Cloud uses standard namespace; vlocity_*__ namespace assumption is wrong."
      automatic_hard_fail_rules:
        - "vlocity_cmt__ / vlocity_*__ namespace assumed (Manufacturing Cloud is STANDARD namespace — no managed package)"
        - "API names hardcoded with namespace prefix that doesn't exist on the org"
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

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 50-pt rubric across 5 router categories, mapped onto the 4-dim shape. Correctness floor at 14 — Manufacturing Cloud uses standard namespace + first-class objects (SalesAgreement / AccountForecast / RebateProgram / ManufacturingWorkOrder); custom Opportunity / Apex rollup / Field-Service WorkOrder reuse are the dominant defects. Hard-fail rules block sales agreements as Opportunities, custom Apex forecast rollups, Rebate calc in Flow when Rebate Management handles it, FS WorkOrder reuse, license gating skips, and vlocity_cmt__ namespace assumption. Disable with `eval_harness.enabled: false`.

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
