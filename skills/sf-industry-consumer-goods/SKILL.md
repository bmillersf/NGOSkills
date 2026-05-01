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
