---
name: sf-industry-communications
description: >
  Communications Cloud (Industries CPQ for Comms) architecture stub with industry-first
  routing precedence. Owns `vlocity_cmt__` namespace claim and industry-specific process
  routing; delegates implementation to OmniStudio common-core skills.
  TRIGGER when: user says "enterprise product catalog", "order decomposition",
  "configure/price/quote telecom offer", "number management (MSISDN/DID)",
  "enterprise service management ESM", "telco CPQ", "cart-based ordering for comms",
  "bundle promotion for a carrier", or designs BSS/OSS order flows on Salesforce for telcos.
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
compatibility: "Requires Communications Cloud license + `vlocity_cmt__` managed package (Vlocity Comms/Media Tech)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.comms_admin_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/communications
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_communications.htm
---

## When this skill owns the task

Own the task whenever the org is Communications Cloud and work touches `vlocity_cmt__` objects: `Catalog__c`, `Offer__c`, `CartItem__c`, `Order__c`, `InventoryItem__c`, `TelcoAsset__c`, or telco ESM constructs. Anchor processes:

- Enterprise/consumer product catalog (EPC) + offer design
- Cart/quote flow, configuration, bundle pricing
- Order decomposition (commercial → technical)
- Number / DID / MSISDN management
- Enterprise Service Management (ESM)

Comms Cloud is **heavily OmniStudio-centric** — nearly all UI/flow is OmniScript + IP + DM.

## Industry precedence note

When Comms Cloud is detected (`vlocity_cmt__` + Catalog/Offer), this skill wins over `sf-sales-cloud`/`sf-service-cloud`. Because the platform is OmniStudio-first, implementation routes aggressively to `sf-industry-commoncore-*`. Keep domain rules here; push metadata build to common-core. Namespace note: `vlocity_cmt__` is shared with Media Cloud — always disambiguate via license + object presence.

## Required context to gather first

1. EPC + Industries CPQ installed?
2. `vlocity_cmt__` version?
3. OM for decomposition?
4. Consumer, SMB, or enterprise channel?
5. Digital Commerce exposing catalog?

## Workflow phases

1. **Detection** — confirm `vlocity_cmt__` + Catalog/Offer.
2. **Process ID** — catalog, cart, decomposition, number mgmt, ESM.
3. **Route** — wizard → `sf-industry-commoncore-omniscript`; server orchestration → `sf-industry-commoncore-integration-procedure`; Apex ext → `sf-industry-commoncore-callable-apex`; namespace audit → `sf-industry-commoncore-omnistudio-analyze`.
4. **Testing** — `sf-testing` + cart regression via `sf-demo-validate`.

## Scoring rubric (50 points)

| Category | Pts | Criteria |
|---|---|---|
| Industry detection | 10 | `vlocity_cmt__` attributed to Comms (not Media) |
| Object model | 10 | `Catalog__c`/`Offer__c`/`CartItem__c` used properly |
| Decomposition awareness | 10 | Commercial vs technical order separation respected |
| Routing to common-core | 10 | OmniStudio work delegated, not inlined |
| License gating | 10 | OM, Digital Commerce, ESM add-ons gated |

## Anti-patterns

- Telco products as plain `Product2` without `vlocity_cmt__` extension.
- Order decomposition in Flow — use Industries OM rules.
- Custom Apex cart mutations bypassing `CartItem__c` API.
- Ignoring namespace when moving code between Comms and Media orgs.
- Hard-coded MSISDN ranges instead of Number Management.

## Industry object cheat sheet (all `vlocity_cmt__`)

| Object | Purpose |
|---|---|
| `Catalog__c` | Catalog root |
| `Offer__c` | Sellable offer/bundle |
| `ProductChildItem__c` | Bundle child link |
| `CartItem__c` | Cart line |
| `Order__c` | Commercial order |
| `OrchestrationPlan__c` | Technical plan |
| `OrchestrationItem__c` | Technical order item |
| `InventoryItem__c` | Reservable inventory |
| `TelcoAsset__c` | Installed asset |
| `PriceList__c` | Offer price list |
| `PromotionItem__c` | Promo eligibility |
| `Rule__c` | Eligibility/compat rule |
| `ContextAction__c` | Context-driven action |

## Delegation table

| Concern | Skill |
|---|---|
| Configurator / quote wizard | `sf-industry-commoncore-omniscript` |
| Cart validate, order submit, decomposition | `sf-industry-commoncore-integration-procedure` |
| Catalog extract / external sync | `sf-industry-commoncore-datamapper` |
| Cart summary / offer card | `sf-industry-commoncore-flexcard` |
| Callable Apex for IPs | `sf-industry-commoncore-callable-apex` |
| Namespace / dependency audit | `sf-industry-commoncore-omnistudio-analyze` |
| Custom Apex (pricing ext) | `sf-apex` |
| Record-triggered automation | `sf-flow` |
| Telco usage in Data Cloud | `sf-datacloud` |
