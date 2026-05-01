---
name: sf-industry-energy
description: >
  Energy & Utilities Cloud stub with industry-first routing.
  Owns `vlocity_ins__` (shared-with-Insurance) namespace claim and E&U process
  routing; delegates implementation to OmniStudio common-core skills.
  TRIGGER when: user says "customer service for a utility", "premise / service point",
  "meter-to-cash", "AMI interval read", "outage management", "utility work request",
  "asset hierarchy (substation)", "utility contract", or designs regulated utility, water,
  or energy-retailer workflows on E&U Cloud.
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
compatibility: "Requires E&U Cloud license + `vlocity_ins__` package (EnergyAndUtilities feature, shared with Insurance)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.eu_admin_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/energy
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_energy.htm
---

## When this skill owns the task

Own the task whenever the org is E&U Cloud and work touches `vlocity_ins__` utility objects: `Premise__c`, `ServicePoint__c`, `Meter__c`, `WorkRequest__c`, `IntervalData__c`, `AssetHierarchy__c`, E&U `Contract__c`. Anchor processes:

- Customer service (move-in/out, billing inquiry, high-bill complaint)
- Asset / network hierarchy (substation → feeder → transformer → SP)
- Meter-to-cash (read → bill → pay → collect)
- Outage management (report, cluster, restore, notify)
- Work request / field dispatch

Heavy OmniStudio — route implementation to common-core.

## Industry precedence note

When E&U is detected (`vlocity_ins__` + `Premise__c`/`ServicePoint__c`), this skill wins over `sf-sales-cloud`/`sf-service-cloud`. `vlocity_ins__` is **shared with Insurance Cloud** via the EnergyAndUtilities feature flag. Disambiguate via `Premise__c` vs `Claim__c`.

## Required context to gather first

1. E&U Cloud edition + `vlocity_ins__` version?
2. EnergyAndUtilities feature flag enabled?
3. Regulated utility, deregulated retailer, or water/gas?
4. AMI interval data or summary reads only?
5. Field Service — native FSL or third-party?

## Workflow phases

1. **Detection** — `vlocity_ins__` + `Premise__c`/`ServicePoint__c` (not `Claim__c`).
2. **Process ID** — CS, asset, meter-to-cash, outage, work request.
3. **Route** — move-in wizard → `sf-industry-commoncore-omniscript`; CIS/billing/AMI → `sf-industry-commoncore-integration-procedure`; billing mapping → `sf-industry-commoncore-datamapper`; namespace audit → `sf-industry-commoncore-omnistudio-analyze`; dispatch → `sf-field-service`.
4. **Testing** — outage clustering + billing edges via `sf-testing`; `sf-demo-validate` end-to-end.

## Scoring rubric (50 points)

| Category | Pts | Criteria |
|---|---|---|
| Industry detection | 10 | E&U disambiguated from Insurance (shared ns) |
| Object model | 10 | `Premise__c`/`ServicePoint__c`/`Meter__c` used properly |
| Asset hierarchy | 10 | Substation→feeder→SP via `AssetHierarchy__c` |
| Routing to common-core | 10 | OmniStudio work delegated |
| License gating | 10 | EnergyAndUtilities feature flag verified |

## Anti-patterns

- Premise as plain `Account` without `Premise__c`.
- Interval data as custom child of `Asset` — use `IntervalData__c`.
- Confusing Insurance `Claim__c` with E&U billing objects (shared namespace).
- Outage clustering in Flow — use Industries outage engine / Apex.
- Attaching meter directly to `Account`, skipping `ServicePoint__c`.

## Industry object cheat sheet (all `vlocity_ins__`)

| Object | Purpose |
|---|---|
| `Premise__c` | Premise receiving service |
| `ServicePoint__c` | Point of delivery |
| `Meter__c` | Meter on a SP |
| `IntervalData__c` | AMI interval reads |
| `MeterRead__c` | Discrete read |
| `Contract__c` | Utility contract |
| `WorkRequest__c` | Work request |
| `WorkOrder__c` | Dispatched WO |
| `AssetHierarchy__c` | Network graph |
| `Outage__c` | Outage event |
| `OutageImpact__c` | Affected premises |
| `Bill__c` | Utility bill |
| `RatePlan__c` | Tariff |

## Delegation table

| Concern | Skill |
|---|---|
| Move-in/out / start-service wizard | `sf-industry-commoncore-omniscript` |
| CIS/billing/AMI orchestration, outage clustering | `sf-industry-commoncore-integration-procedure` |
| External CIS/ERP mapping | `sf-industry-commoncore-datamapper` |
| Premise 360 / outage card | `sf-industry-commoncore-flexcard` |
| Callable Apex for IPs | `sf-industry-commoncore-callable-apex` |
| Namespace audit vs Insurance | `sf-industry-commoncore-omnistudio-analyze` |
| Custom Apex (billing/rating ext) | `sf-apex` |
| Record-triggered automation | `sf-flow` |
| Field crew dispatch | `sf-field-service` |
| AMI / usage analytics | `sf-datacloud` |
