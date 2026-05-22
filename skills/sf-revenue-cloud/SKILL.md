---
name: sf-revenue-cloud
description: >
  Salesforce Revenue Cloud Advanced (RCA) and legacy CPQ architecture with
  140-point scoring and industry-first routing precedence.
  TRIGGER when: user designs Product Catalog, Price Book, Quote, Quote Line,
  Order, Order Product, Contract, Subscription, Billing Schedule, Invoice,
  Payment, Asset, Product Rule, Pricing Rule, Decision Matrix, Revenue
  Schedule, or Discount on Revenue Cloud Advanced; or works with SBQQ__
  objects on legacy CPQ; or asks "build a quote-to-cash process", "configure
  a subscription billing schedule", "migrate from CPQ to RCA", "which
  revenue product do I use", "set up Salesforce Billing", "product bundle
  with constraints", "tiered pricing rule", "usage-based billing".
  DO NOT TRIGGER when: user is quoting inside an industry vertical
  (FSC wealth proposal → sf-industry-fsc; Communications order decomposition
  → sf-industry-communications; Health Cloud coverage benefits →
  sf-industry-health); pure Opportunity pipeline work with no Quote line
  configuration (use sf-nonprofit-fundraising for nonprofit gift pipeline,
  or standard Opportunity guidance in sf-apex/sf-flow); custom Apex with no
  Revenue Cloud object (use sf-apex); generic Flow automation not touching
  Quote/Order/Contract (use sf-flow); nonprofit gift-entry (use
  sf-nonprofit-fundraising).
license: MIT
compatibility: "Requires Revenue Cloud Advanced license OR legacy Salesforce CPQ (SBQQ) managed package"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "140 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.revenuecloud_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/revenue-cloud
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.cpq_overview.htm
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_sales_revenue_cloud.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "140-pt rubric inline (7 categories: Product Catalog Design 20, Pricing Architecture 25, Quote Lifecycle Integrity 20, Order to Asset/Subscription 20, Billing + Revenue 25, Migration + Coexistence 15, Test + Audit 15), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  revenue_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Catalog + pricing math correct. Maps to Product Catalog Design (20) + Pricing Architecture (25)."
      automatic_hard_fail_rules:
        - "Any pricing rule with duplicated math across procedures (single source of truth violated)"
        - "Any bundle without ProductRelatedComponent for child products"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Billing + revenue is load-bearing. Maps to Billing + Revenue (25). Heaviest robustness — broken billing breaks the business. ASC 606 Revenue Schedule, idempotent invoicing."
      automatic_hard_fail_rules:
        - "Any Invoice generation pattern that isn't idempotent (duplicate billing on retry)"
        - "Any Billing Schedule cadence not aligned to the Order's contract term"
        - "Any ASC 606 Revenue Schedule mismatched with Performance Obligation"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "RCA vs CPQ chosen correctly. Maps to Migration + Coexistence (15) + Quote Lifecycle Integrity (20)."
      automatic_hard_fail_rules:
        - "Any silent dual-stack (RCA + CPQ on same product) — pick one with documented justification"
        - "Any quote → order flow without Opportunity sync verified"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Order-to-asset/subscription correct + tested. Maps to Order to Asset/Subscription (20) + Test + Audit (15)."
      automatic_hard_fail_rules:
        - "Any amendment / renewal flow that doesn't preserve Asset / Subscription lineage (audit broken)"
        - "Any deploy without end-to-end test scenario (catalog → quote → order → invoice → revenue)"
  test_rubric:
    unit:
      required: true
      criteria: "Pricing procedure rules unit-tested. Bundle structure validation passes."
    integration:
      required: true
      criteria: "End-to-end quote → order → asset → subscription → invoice → revenue test scenario completes against connected org."
    smoke:
      required: true
      criteria: "Amendment + renewal preserve Asset/Subscription lineage. Rollups verified post-amendment."
---

# sf-revenue-cloud: Revenue Cloud Advanced (RCA) + Legacy CPQ

Quote-to-cash architecture expert for Salesforce Revenue Cloud Advanced (RCA — the 2024+ Core Platform product) with explicit coverage of legacy **Salesforce CPQ** (`SBQQ__` managed package) for orgs not yet migrated. Owns Product Catalog, Pricing, Quote, Order, Contract, Subscription, Billing, Invoice, and Payment surfaces.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 140-pt rubric in fresh context. Robustness floor at 18 — broken billing breaks the business; non-idempotent invoicing on retry is catastrophic. Disable with `eval_harness.enabled: false`.

---

## When This Skill Owns the Task

Use `sf-revenue-cloud` when the work involves:

- Product Catalog design (Product2, ProductCategory, ProductRelatedComponent, ProductAttribute)
- Pricing (PricebookEntry, PricingProcedure, PricingRule, DecisionMatrix, DiscountSchedule)
- Quote lifecycle (Quote, QuoteLineItem, configuration, approval)
- Order orchestration (Order, OrderItem, OrderAction, Fulfilment)
- Contract + Asset lifecycle (Contract, ContractLineItem, Asset, AssetAction, Amendment, Renewal)
- Subscription Management (Subscription, SubscriptionItem, BillingSchedule, RevenueSchedule)
- Billing + Invoicing (Invoice, InvoiceLine, Payment, PaymentAllocation, Credit Memo, Refund)
- Product Rules / Attribute-Based Configuration (ProductRule, ConfigurationRule, ConstraintRule)
- Legacy CPQ (`SBQQ__Quote__c`, `SBQQ__QuoteLine__c`, `SBQQ__ProductRule__c`, etc.)
- **Migration** from legacy CPQ → RCA

Delegate outside this skill when:

| Scope | Route to | Reason |
|---|---|---|
| Industry-specific quote (FSC wealth proposal, mortgage app) | `sf-industry-fsc` | FSC owns Financial-Account-anchored quoting |
| Health Cloud coverage / benefit package | `sf-industry-health` | Coverage Benefit ≠ RCA subscription |
| Communications Cloud order decomposition, EPC | `sf-industry-communications` | Industries-CPQ (vlocity_cmt) is a separate product |
| Manufacturing Sales Agreement, rebate program | `sf-industry-manufacturing` | Sales Agreement is not a Quote |
| Public Sector Benefit issuance / disbursement | `sf-industry-public-sector` | Benefit + Disbursement are PSS objects |
| Nonprofit donation / gift entry | `sf-nonprofit-fundraising` | Gift Transaction is not a Quote |
| Generic Opportunity pipeline (no Quote lines) | `sf-apex` / `sf-flow` | Standard Sales object surface |
| Named Credential / payment-gateway callout | `sf-integration` | Integration layer, not Revenue layer |
| Pure Apex against RCA outputs | `sf-apex` | Code-only implementation |
| Flow automation after Quote sync | `sf-flow` | Declarative orchestration |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before producing any artifact, run the shared industry pre-check at [`references/industry-precheck.md`](../../references/industry-precheck.md).

Revenue Cloud sits directly downstream of the Sales Cloud pipeline and is frequently **extended or replaced** by industry-specific quoting engines. The pre-check resolves that boundary **first**.

1. Detect installed industry clouds via `sf org display --json` license/feature scan and namespace scan (see pre-check reference).
2. If FSC, Health Cloud, Communications Cloud, Media Cloud, Energy & Utilities Cloud, Manufacturing Cloud, or Consumer Goods Cloud is installed AND the user's request touches that industry's quoting/ordering/billing model, **halt and forward**:
   - FSC wealth/mortgage/insurance proposals → `sf-industry-fsc`
   - Communications Cloud (Industries-CPQ / vlocity_cmt) EPC, Cart, Offer, Order Decomposition → `sf-industry-communications`
   - Manufacturing Sales Agreement / Advanced Account Forecast → `sf-industry-manufacturing`
   - Media Cloud Subscriber / Billing Account → `sf-industry-media`
   - Energy & Utilities Cloud Contract / Premise → `sf-industry-energy`
3. If the org has a **nonprofit** cloud (NPC or NPSP) and the user's request is a donation, pledge, or recurring gift, forward to `sf-nonprofit-fundraising`. Gifts are not Quotes.
4. **If no industry overlap and no nonprofit overlap**, continue with Phase 1.
5. If the user explicitly says "use standard Revenue Cloud / bypass the industry overlay", document the exception and proceed (see exceptions clause in the pre-check reference).

Print a single-line handoff on deferral, e.g.:

```
Detected Communications Cloud (vlocity_cmt). Routing to sf-industry-communications
because this request touches Cart + Order Decomposition — Industries-CPQ owns that flow.
```

---

## RCA vs Legacy CPQ — Decision Tree

Salesforce is **actively migrating customers off legacy CPQ (`SBQQ__`) onto Revenue Cloud Advanced (RCA)** on the Core Platform. New implementations should default to RCA. Support existing CPQ orgs until migration is scheduled.

```
START
 │
 ├─ Org already has SBQQ__ installed?
 │    ├─ YES  → Is migration to RCA in scope?
 │    │          ├─ YES → Run hybrid plan: preserve CPQ runtime, model new
 │    │          │         capability in RCA, plan cutover by product family.
 │    │          └─ NO  → Use Legacy CPQ (SBQQ__) patterns.
 │    └─ NO  → RCA is the only Salesforce-supported new build.
 │
 ├─ Need subscription + usage billing + revenue recognition in one stack?
 │    └─ RCA (Subscription Management + Billing) — no CPQ equivalent.
 │
 ├─ Industry cloud installed (see Phase 0)?
 │    └─ Defer to industry skill; do not dual-stack RCA with Industries-CPQ.
 │
 └─ Pure catalog + simple discounting + quote PDF?
      ├─ Existing CPQ → stay.
      └─ New build    → RCA Product Catalog + Pricing Procedure (no CPQ).
```

Never dual-stack RCA **and** CPQ for the same product family. Pick one authoritative engine per revenue stream.

---

## Required Context to Gather First

Ask for or infer:

- Target org alias and API version
- Which product: **RCA**, **legacy CPQ (SBQQ)**, or **both installed** (migration org)
- License flags: `RevenueCloudAdvanced`, `SubscriptionManagement`, `SalesforceBilling`, `SBQQ__` namespace presence
- Industry cloud flags (see Phase 0)
- Revenue model: one-time, subscription, usage, hybrid
- Pricing complexity: list price only, tiered, volume, attribute-based, context-driven
- Does the process need: Configurator, Amendment, Renewal, Cancellation, Co-term?
- Billing needs: Invoice, Credit Memo, Refund, Payment Gateway integration
- Revenue recognition requirement (RCA Revenue Schedule) — ASC 606 in scope?
- Downstream system (ERP, tax engine, payment processor) — integration pattern?

---

## Workflow Phases

### Phase 1: Catalog Design

1. Model **Product2** hierarchy: standalone, bundle, option, add-on.
2. For RCA, define `ProductCategory` + `ProductRelatedComponent` for bundle structure. For CPQ, use `SBQQ__ProductFeature__c` + `SBQQ__ProductOption__c`.
3. Attach `ProductAttribute` (RCA) or `SBQQ__ProductAttribute__c` (CPQ) for attribute-based configuration.
4. Publish to **Pricebook2** with `PricebookEntry`. RCA supports multi-currency + context-aware pricebook selection; CPQ layers `SBQQ__PriceBook2Id__c` on Quote.

### Phase 2: Pricing Design

1. **RCA**: `PricingProcedure` + `PricingRule` + `DecisionMatrix` for list/tier/volume/attribute/discount logic. Decision Matrices are the preferred externalised lookup.
2. **CPQ**: `SBQQ__PriceRule__c` + `SBQQ__PriceCondition__c` + `SBQQ__PriceAction__c` + `SBQQ__Lookup__c` (Price Lookup Queries).
3. Discount schedules: `DiscountSchedule` + `DiscountTier` (RCA) vs `SBQQ__DiscountSchedule__c` + `SBQQ__DiscountTier__c` (CPQ).
4. Partner / channel / customer-specific pricing → Context Service (RCA) or `SBQQ__CustomAction__c` (CPQ).

### Phase 3: Quote Lifecycle

1. Create Quote (primary) from Opportunity.
2. Add Quote Lines via configurator (bundles) or directly.
3. Apply Product Rules / Constraint Rules:
   - **RCA**: `ProductRule` + `ConfigurationRule` + `ConstraintRule`
   - **CPQ**: `SBQQ__ProductRule__c` with validation/selection/filter/alert types
4. Price calculation (pricing procedure runs on save/calculate).
5. Approval: RCA integrates with Approvals or Advanced Approvals; CPQ uses `sbaa__` Advanced Approvals package.
6. Output: Quote PDF (RCA CLM or CPQ Output Document).
7. **Synchronize to Opportunity** — Quote → OpportunityLineItem.

### Phase 4: Order + Contract + Asset

1. Convert Primary Quote → Order (on close).
2. Activate Order → generate Contract + ContractLineItem (CPQ) or `AssetAction` + `Asset` (RCA).
3. For subscriptions, generate `Subscription` + `SubscriptionItem` (RCA) or `SBQQ__Subscription__c` (CPQ).
4. Asset lifecycle: `AssetStatePeriod` (RCA) tracks state transitions across amend/renew/cancel.

### Phase 5: Amendment / Renewal / Cancellation

1. **Amendment**: mid-term change (add/remove lines, change quantity). Price delta = current contract value − new contract value.
2. **Renewal**: Contract-end-date + 1. RCA supports evergreen; CPQ uses `SBQQ__RenewalForecast__c`.
3. **Cancellation**: partial or full. Triggers credit memo logic if billed.
4. **Co-term**: align multiple contracts to one end date. RCA-native; CPQ requires manual Quote manipulation.

### Phase 6: Billing + Invoicing + Revenue (RCA only)

1. `BillingSchedule` generated from SubscriptionItem. Frequency: one-time, monthly, quarterly, annual, usage.
2. Invoice run → `Invoice` + `InvoiceLine`. Supports consolidated billing across subscriptions.
3. Payment → `Payment` + `PaymentAllocation`. Integrate payment gateway via `sf-integration` Named Credential.
4. Credit Memo → reverses `InvoiceLine`; refund via `Refund`.
5. **Revenue recognition**: `RevenueSchedule` + `RevenueScheduleAllocation` — ASC 606 performance-obligation-based.

Legacy CPQ orgs needing billing must use **Salesforce Billing** (separate `blng__` managed package on top of CPQ). Salesforce Billing is being superseded by RCA Subscription Management — do not greenfield on `blng__`.

### Phase 7: Validation + Handoff

1. Run test quote end-to-end: configure → price → approve → order → activate → invoice → pay.
2. Validate rollups: Account ARR, Opportunity Amount, Contract Total Value, Subscription MRR.
3. Verify audit: who configured, who approved, who closed.
4. Hand off to `sf-deploy` for environment promotion and `sf-testing` for Apex coverage on any custom extensions.

---

## Scoring Rubric

Total: **140 points across 7 categories.** Any category below its pass threshold fails the whole review.

```
Score: XX/140
├─ Product Catalog Design: XX/20        (pass >= 14) Bundle structure, ProductRelatedComponent, attributes, categorization
├─ Pricing Architecture: XX/25          (pass >= 18) Pricing procedure / rules correctness, tier logic, discount schedules, no duplicated math
├─ Quote Lifecycle Integrity: XX/20     (pass >= 14) Configurator rules fire in order, approvals gate the right fields, Opportunity sync correct
├─ Order to Asset / Subscription: XX/20 (pass >= 14) Order activation produces correct Asset / Subscription / Contract records; amendments / renewals preserve lineage
├─ Billing + Revenue (RCA): XX/25       (pass >= 18) Billing Schedule cadence correct, Invoice generation idempotent, ASC 606 Revenue Schedule aligned to POs
├─ Migration + Coexistence: XX/15       (pass >= 10) RCA vs CPQ chosen with justification; no silent dual-stack; CPQ deprecation timeline surfaced
└─ Test + Audit: XX/15                  (pass >= 10) End-to-end test scenario documented, rollups verified, audit trail present
```

Passing score: **100/140 with every category at pass threshold.** Billing + Revenue is load-bearing — a beautiful catalog with broken billing is a failed implementation.

---

## Anti-Patterns

- **Dual-stacking RCA and legacy CPQ on the same product family.** Pricing and amendment semantics diverge; customers end up with two sources of truth for the same subscription. Pick one.
- **Writing custom Apex price logic when `PricingProcedure` + `DecisionMatrix` (RCA) or `SBQQ__PriceRule__c` (CPQ) exists.** Custom Apex pricing silently breaks during managed-package upgrades, multi-currency conversions, and quote recalculations. Use the native rules engine.
- **Creating a custom "Subscription" object instead of using RCA `Subscription` + `SubscriptionItem`.** Fragments billing, renewal, revenue recognition, and usage metering.
- **Treating Opportunity Amount as the source of truth for ARR.** Opportunity Amount reflects the close; Contract Total Value + Subscription MRR reflect the revenue. Map them explicitly.
- **Building Amendment logic as a Flow that clones the Quote.** RCA/CPQ have native amendment flows that preserve price-hold, term alignment, and discount persistence. A clone loses all of it.
- **Bypassing `BillingSchedule` and manually generating Invoices.** Breaks usage-based billing, deferred-revenue recognition, and credit memo linkage. Always start from BillingSchedule.
- **Using legacy CPQ for net-new greenfield builds in 2026.** Salesforce has signalled CPQ is in maintenance mode with RCA as the successor. New builds on CPQ incur migration debt on day one.
- **Hardcoding payment gateway credentials in Apex.** Route through `sf-integration` Named Credential + External Credential.
- **Letting a generic Sales Cloud skill configure quoting in an FSC / Communications / Manufacturing org.** Industry cloud wins — Phase 0 exists for this reason.
- **Configuring Advanced Approvals (sbaa__) in an RCA org without checking if the native Approvals engine covers the requirement.** Double-engine approvals is a debugging nightmare.

---

## Common Failure Modes + Remediation

| Symptom | Root Cause | Fix |
|---|---|---|
| Quote total ≠ sum of Quote Lines | Pricing procedure not triggered on save; or rounding mismatch between line-level and quote-level | Force `calculate()` in after-save; align rounding precision field-by-field |
| Amendment Quote has wrong baseline price | Price-hold / existing contract price not carried forward | On RCA use `Amendment Start Date` properly; on CPQ set `SBQQ__StartingBundle__c` and `SBQQ__PriceHoldEndDate__c` |
| Renewal Quote missing lines | Renewal filter excluded evergreen or cancelled items | Audit `SBQQ__RenewalForecast__c` filter (CPQ) or `SubscriptionItem.Status` (RCA) |
| Invoice generated for cancelled subscription | BillingSchedule not deactivated on cancellation | Ensure cancellation writes `BillingSchedule.Status = 'Cancelled'` and ends `AssetStatePeriod` |
| Product Rule fires in wrong order | Rule evaluation order not set; or circular dependency | Set evaluation order explicitly (CPQ) or use `ConfigurationRule.SequenceNumber` (RCA); break cycles with scoped rules |
| Multi-currency quote shows base currency | Pricebook entry missing target currency row; or conversion not run | Ensure PricebookEntry exists for each ISO code; run currency conversion job |

---

## Cheat Sheet — RCA vs CPQ Object Map

| Concern | RCA (Core Platform) | Legacy CPQ (SBQQ__) |
|---|---|---|
| Product | `Product2` | `Product2` (same) |
| Bundle structure | `ProductRelatedComponent` | `SBQQ__ProductFeature__c` + `SBQQ__ProductOption__c` |
| Attribute | `ProductAttribute` | `SBQQ__ProductAttribute__c` |
| Pricing engine | `PricingProcedure` + `PricingRule` + `DecisionMatrix` | `SBQQ__PriceRule__c` + `SBQQ__PriceCondition__c` + `SBQQ__Lookup__c` |
| Discount schedule | `DiscountSchedule` + `DiscountTier` | `SBQQ__DiscountSchedule__c` |
| Quote | `Quote` + `QuoteLineItem` | `SBQQ__Quote__c` + `SBQQ__QuoteLine__c` |
| Product Rule | `ProductRule` + `ConstraintRule` | `SBQQ__ProductRule__c` |
| Order | `Order` + `OrderItem` | `Order` + `OrderItem` (CPQ extends) |
| Contract | `Contract` + `ContractLineItem` | `Contract` + `SBQQ__Subscription__c` |
| Subscription | `Subscription` + `SubscriptionItem` | `SBQQ__Subscription__c` |
| Asset | `Asset` + `AssetAction` + `AssetStatePeriod` | `Asset` (less native lineage) |
| Billing | `BillingSchedule` + `Invoice` + `InvoiceLine` (native) | `blng__BillingSchedule__c` (Salesforce Billing package) |
| Revenue | `RevenueSchedule` + `RevenueScheduleAllocation` | `blng__RevenueSchedule__c` |
| Approvals | Approvals / Advanced Approvals (native) | `sbaa__` Advanced Approvals package |

---

## Cross-Skill Integration

| To Skill | When to Use |
|---|---|
| `sf-integration` | Payment gateway, tax engine, ERP Named Credential + External Service |
| `sf-apex` | Custom callable extensions, pricing plugins (RCA ProcedureStep) |
| `sf-flow` | Post-order orchestration, approval submission, customer notifications |
| `sf-metadata` | Custom Product / Pricebook field additions |
| `sf-deploy` | Promote RCA configuration (uses Setup Audit Trail + metadata API) |
| `sf-testing` | Apex test coverage for pricing plugins and order-activation triggers |
| `sf-industry-*` | Any industry overlap (see Phase 0) |

---

## Additional Resources

- [Revenue Cloud overview](https://help.salesforce.com/s/articleView?id=sf.revenuecloud_overview.htm)
- [Revenue Cloud architect guide](https://architect.salesforce.com/design/revenue-cloud)
- [Legacy CPQ overview](https://help.salesforce.com/s/articleView?id=sf.cpq_overview.htm)
- [Industry pre-check reference](../../references/industry-precheck.md)
