---
name: sf-industry-consumer-goods
description: >
  Consumer Goods Cloud architecture stub with industry-first routing precedence.
  Owns namespace claim and industry-specific process routing; delegates
  implementation to OmniStudio common-core skills.
  TRIGGER when: user says "retail execution", "visit planning for reps",
  "trade promotion management", "perfect store compliance", "penny perfect order",
  "assortment planning", "in-store audit", "CG Cloud offline mobile",
  or designs field sales workflows for consumer packaged goods reps visiting stores.
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
compatibility: "Requires Consumer Goods Cloud license (standard namespace + CG Offline Mobile app)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "50 points across 5 categories — Industry detection 10 / Object model 10 / Offline-mobile awareness 10 / Process routing 10 / License gating 10"
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
  consumer_goods_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Industry detection + Object model. Maps to Industry detection (10) + Object model (10). RetailStore extension of Account; Visit + VisitedParty; Assortment for per-store product lineups; first-class CG objects."
      automatic_hard_fail_rules:
        - "Stores modeled as plain Account without RetailStore extension"
        - "Visits modeled as custom Events instead of Visit + VisitedParty"
        - "Promotion treated as a Campaign (TPM has its own lifecycle — Promotion + PromotionChannel)"
        - "Per-store product lists hardcoded instead of using Assortment / AssortmentProduct"
        - "Generic Field Service / Sales Cloud routing in a CG-detected org (industry override)"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Offline-mobile awareness. Maps to Offline-mobile awareness (10). CG reps work offline first; online-only pages break for them."
      automatic_hard_fail_rules:
        - "Online-only Lightning pages designed for offline-first reps (CG Offline Mobile serializes differently)"
        - "OmniScript used for offline screens (offline screens use CG-specific templates, not OmniScript)"
        - "Offline sync constraints not considered in design (record-pruning / partial-sync edges fail)"
        - "Testing skips offline-sync scenarios (visit-to-order path untested in airplane mode)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Process routing + Delegation. Maps to Process routing (10). OmniStudio-online vs CG-offline template chosen correctly; online OmniScript / IP / DM / FlexCard delegated to common-core."
      automatic_hard_fail_rules:
        - "OmniScript / IP / Data Mapper / FlexCard / Callable Apex authored here instead of delegated to sf-industry-commoncore-*"
        - "CG-offline template chosen for an online-only surface (or vice versa)"
        - "Standard automation work authored here instead of routed to sf-flow / sf-apex"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "License gating. Maps to License gating (10). TPM + Einstein Visual + Penny Perfect add-ons confirmed before recommending features that depend on them."
      automatic_hard_fail_rules:
        - "TPM features recommended without confirming TPM license"
        - "Einstein Visual recommended without confirming Einstein Visual entitlement"
        - "Penny Perfect Order features recommended without confirming Penny Perfect license / external ERP integration path"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.cg_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/consumer-goods
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_consumer_goods.htm
---

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 50-pt rubric across 5 router categories, mapped onto the 4-dim shape. Robustness floor at 14 — CG reps work offline-first; online-only pages break for them. Hard-fail rules block stores-as-plain-Account, visits-as-custom-Events, Promotion-as-Campaign, hardcoded per-store product lists (Assortment is the pattern), online-only pages for offline-first reps, OmniScript for offline screens, and license-gated features recommended without entitlement check. Disable with `eval_harness.enabled: false`.

## When this skill owns the task

Own the task whenever the org is Consumer Goods Cloud and work touches industry-specific objects: `RetailStore`, `Visit`, `RetailStoreKpi`, `InStoreLocation`, `Promotion`, `Assortment`, `OrderPenaltyType`, or CPG field-sales processes. Anchor processes:

- Retail execution (visits, tasks, surveys, image recognition)
- Visit planning and route optimization for field reps
- Trade promotion management (TPM)
- Perfect Store compliance (planogram + KPI audits)
- Penny Perfect Order accuracy

Do NOT own generic B2B sales (`sf-sales-cloud`), DTC commerce, or generic Field Service.

## Industry precedence note

When CG Cloud is detected (license + `RetailStore`/`Visit`), this skill wins over `sf-sales-cloud`/`sf-service-cloud`. Implementation delegates to `sf-industry-commoncore-*`. CG Cloud uses the **standard namespace** + CG-specific components; Offline Mobile serializes differently.

## Required context to gather first

1. CG Cloud edition + Offline Mobile entitlement?
2. Reps online-only or Offline Mobile?
3. TPM licensed, or Retail Execution only?
4. Einstein Visual enabled?
5. Penny Perfect native, or external ERP?

## Workflow phases

1. **Detection** — confirm license + `RetailStore`/`Visit`.
2. **Process ID** — visit, TPM, assortment, perfect store, or order.
3. **Route** — offline screens → CG templates (not OmniScript); online UI → `sf-industry-commoncore-omniscript`; orchestration → `sf-industry-commoncore-integration-procedure`.
4. **Testing** — include offline-sync scenarios; `sf-demo-validate` for visit-to-order.

## Scoring rubric (50 points)

| Category | Pts | Criteria |
|---|---|---|
| Industry detection | 10 | CG Cloud vs generic Sales/FSL identified |
| Object model | 10 | `RetailStore`/`Visit`/`Assortment` used properly |
| Offline-mobile awareness | 10 | Offline sync constraints considered |
| Process routing | 10 | OmniStudio-online vs CG-offline template chosen |
| License gating | 10 | TPM, Einstein Visual, Penny Perfect gated |

## Anti-patterns

- Stores as plain `Account` without `RetailStore` extension.
- Visits as custom Events — use `Visit` + `VisitedParty`.
- Online-only Lightning pages for offline-first reps.
- Treating `Promotion` as a Campaign — TPM has its own lifecycle.
- Hard-coding per-store product lists instead of `Assortment`.

## Industry object cheat sheet

| Object | Purpose |
|---|---|
| `RetailStore` | Store extension of `Account` |
| `Visit` | Rep visit to a store |
| `VisitedParty` | Visit↔party link |
| `RetailStoreKpi` | Per-store KPI target |
| `InStoreLocation` | Aisle/shelf inside a store |
| `Assortment` | Product lineup per cluster |
| `AssortmentProduct` | Assortment line |
| `Promotion` | TPM header |
| `PromotionChannel` | Channel promo instance |
| `OrderPenaltyType` | Accuracy penalty config |
| `RetailStoreGroup` | Store cluster |
| `VisitTemplate` | Reusable visit def |
| `RetailVisitKpi` | KPI captured on visit |
| `PlanogramAsset` | Planogram asset |

## Delegation table

| Concern | Skill |
|---|---|
| Online OmniScript (visit wrap-up) | `sf-industry-commoncore-omniscript` |
| IP (order submit, TPM calc) | `sf-industry-commoncore-integration-procedure` |
| Data Mapper (ERP → assortment) | `sf-industry-commoncore-datamapper` |
| FlexCard (store scorecard) | `sf-industry-commoncore-flexcard` |
| Callable Apex for IPs | `sf-industry-commoncore-callable-apex` |
| Namespace / dependency audit | `sf-industry-commoncore-omnistudio-analyze` |
| Custom Apex (pricing/penalty) | `sf-apex` |
| Record-triggered automation | `sf-flow` |
| Retail signals in Data Cloud | `sf-datacloud` |
