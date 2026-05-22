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
  scoring: "50 points across 5 categories — Industry detection 10 / Object model 10 / Decomposition awareness 10 / Routing to common-core 10 / License gating 10"
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
  comms_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Industry detection + Object model. Maps to Industry detection (10) + Object model (10). vlocity_cmt__ attributed correctly (Comms vs Media share namespace); first-class objects (Catalog__c / Offer__c / CartItem__c) used."
      automatic_hard_fail_rules:
        - "vlocity_cmt__ namespace detected but skill not disambiguated from Media Cloud (license + object presence is the discriminator)"
        - "Telco products modeled as plain Product2 without vlocity_cmt__ extension"
        - "Catalog / Offer / CartItem authored as custom objects when vlocity_cmt__ equivalents exist"
        - "Hardcoded MSISDN / DID ranges instead of Number Management"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Decomposition awareness. Maps to Decomposition awareness (10). Commercial Order → OrchestrationPlan/OrchestrationItem decomposition pattern; OM rules instead of Flow-built decomposition."
      automatic_hard_fail_rules:
        - "Order decomposition built in Flow instead of Industries OM rules"
        - "Commercial order and technical order conflated (no separation between Order__c and OrchestrationPlan__c / OrchestrationItem__c)"
        - "Custom Apex mutations bypassing CartItem__c API (cart state corruption)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Routing to common-core + Delegation. Maps to Routing to common-core (10). Comms is OmniStudio-first; aggressive delegation of UI/flow to common-core."
      automatic_hard_fail_rules:
        - "OmniScript / IP / Data Mapper / FlexCard / Callable Apex authored here instead of delegated"
        - "Generic Sales/Service Cloud routing in a Comms-detected org (industry override)"
        - "Standard automation work authored here instead of routed to sf-flow / sf-apex"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "License gating + Namespace hygiene. Maps to License gating (10). OM / Digital Commerce / ESM add-ons confirmed; vlocity_cmt__ namespace present in code."
      automatic_hard_fail_rules:
        - "OM (Order Management for decomposition) features recommended without confirming OM license"
        - "Digital Commerce features recommended without confirming Digital Commerce entitlement"
        - "ESM features recommended without confirming ESM license"
        - "Code moved between Comms and Media orgs without namespace audit"
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

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 50-pt rubric across 5 router categories, mapped onto the 4-dim shape. Correctness floor at 14 — vlocity_cmt__ is shared with Media Cloud; misattribution corrupts the routing decision. Hard-fail rules block undisambiguated namespace, telco products as plain Product2, hardcoded MSISDN/DID ranges, order decomposition in Flow (Industries OM rules own it), custom Apex bypassing CartItem__c API, and code moved between Comms/Media orgs without namespace audit. Disable with `eval_harness.enabled: false`.

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
