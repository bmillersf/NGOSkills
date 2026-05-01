# Industry Pre-Check (Shared Reference)

**Every generic cloud skill (Sales / Service / Marketing / Revenue / Tableau / MuleSoft / Slack / Experience Cloud / Reports / Lightning App Builder) MUST run this pre-check as Phase 0 of its workflow before producing any artifact.**

If an industry solution is installed AND the user's request touches industry-owned objects or processes, **halt and forward** to the matching `sf-industry-*` or `sf-nonprofit-*` skill. Never silently override an industry data model.

---

## Detection signals

Run these in order. Any positive hit triggers the industry-first deferral.

### 1. License / feature flag

```
sf org display --json
sf org list all --json
```

Inspect `org.features` and `org.licenses` for:

| Industry | License / feature string |
|---|---|
| Financial Services Cloud | `FinancialServicesCloudStandard`, `FinServ` |
| Health Cloud | `HealthCloudUser`, `HealthCloudGA` |
| Education Cloud / EDA | `EducationCloudForStudentSuccess`, `HEDA` |
| Public Sector Solutions | `PublicSectorSolutions`, `PSS` |
| Field Service | `FieldServiceStandard`, `FSL` |
| Nonprofit Cloud | `NonprofitCloudForPrograms`, `NonprofitCloudForFundraising`, `NonprofitCloudCaseManagement` |
| NPSP | managed package `npsp` installed |
| Manufacturing Cloud | `ManufacturingCloudUser`, `Mfg` |
| Consumer Goods Cloud | `ConsumerGoodsCloudUser`, `CG` |
| Communications Cloud | `CommunicationsCloudUser`, `vlocity_cmt` namespace |
| Media Cloud | `MediaCloudUser`, `vlocity_media` namespace |
| Energy & Utilities Cloud | `EnergyCloudUser`, `vlocity_ins` + `EnergyAndUtilities` |
| Revenue Cloud Advanced | `RevenueCloudAdvanced`, `RCA` |
| CPQ (classic) | `SBQQ__` namespace |
| Tableau CRM (Analytics) | `CRMAnalyticsUser`, `Wave` |

### 2. Namespace scan

```
sf org list metadata-types --json | jq '.result[] | select(.xmlName)'
```

Check for any of: `FSC__`, `HealthCloudGA__`, `hed__`, `OutfundsPS__`, `FieldService__`, `npsp__`, `npe01__`, `npo02__`, `npe03__`, `vlocity_cmt__`, `vlocity_ins__`, `vlocity_media__`, `SBQQ__`.

### 3. Object existence scan (fallback if 1 + 2 are ambiguous)

Query `EntityDefinition` for industry-specific objects:

```sql
SELECT QualifiedApiName FROM EntityDefinition
WHERE QualifiedApiName IN (
  'AccountContactRelation',              -- FSC uses this heavily
  'FinServ__FinancialAccount__c',        -- FSC
  'HealthCloudGA__EhrEncounter__c',      -- Health Cloud
  'hed__Term__c',                        -- EDA
  'ServiceAppointment',                  -- Field Service
  'WorkOrder',                           -- Field Service
  'ProgramEnrollment',                   -- NPC program management
  'GiftTransaction',                     -- NPC fundraising
  'npe03__Recurring_Donation__c',        -- NPSP
  'BusinessLicense',                     -- Public Sector Solutions
  'CareRequest',                         -- Public Sector / Health
  'ManufacturingWorkOrder',              -- Manufacturing Cloud
  'Quote',                               -- shared; not industry-exclusive
  'SubscriptionManagement'               -- Revenue Cloud Advanced
)
```

---

## Deferral table (who owns what)

**When industry detection is positive AND the user's request includes any listed keyword/object, halt the generic skill and forward to the owner.**

| Detected | Industry-owned objects/processes | Route to |
|---|---|---|
| FSC | Households, Financial Accounts, Financial Goals, Relationship Maps, Life Event Moments, Investment Accounts | `sf-industry-fsc` |
| Health Cloud | Patient, Care Plan, Care Request, Clinical Encounter, EHR, Assessment, Care Team | `sf-industry-health` |
| Education Cloud / EDA | Student, Course, Program Enrollment (edu), Affiliation, Term, Course Connection, Educational Institution | `sf-industry-education` |
| Public Sector Solutions | Benefit, License, Permit, Inspection, Case Type, Application, Regulatory Code Violation | `sf-industry-public-sector` |
| Field Service | Work Order, Service Appointment, Resource, Territory, Skill, Scheduling Policy, Dispatcher Console | `sf-field-service` |
| Nonprofit Cloud | Gift Transaction, Gift Designation, Funding Award, Program, Program Enrollment, Benefit (NPC), Goal, Case Plan | `sf-nonprofit-cloud` (orchestrator), then specific `sf-nonprofit-*` |
| NPSP | Opportunity (as donation), Recurring Donation, Household Account, Allocation, Level, Engagement Plan | `sf-nonprofit-npsp` |
| Manufacturing Cloud | Sales Agreement, Account Forecast, Rebate Program, Advanced Account Forecast | `sf-industry-manufacturing` |
| Consumer Goods Cloud | Retail Store, Visit, Retail Execution, Trade Promotion, Assortment | `sf-industry-consumer-goods` |
| Communications Cloud | Product Catalog, Offer, Cart, Order Decomposition, Number Management, ESM | `sf-industry-communications` |
| Media Cloud | Subscriber, Product, Billing Account, Entitlement (media), Campaign Response | `sf-industry-media` |
| Energy & Utilities Cloud | Premise, Service Point, Meter, Work Request, Contract, Interval Data | `sf-industry-energy` |
| Revenue Cloud Advanced / CPQ | Quote, Quote Line, Contract (as revenue), Subscription, Asset (as subscription), Billing Schedule, Order Product, Product Rule | `sf-revenue-cloud` |

---

## Deferral behavior (what the generic skill does)

```
1. Detect → at least one positive signal found
2. Cross-reference user request against the deferral table
3. If user request overlaps with industry-owned rows:
   a. Print a single-line handoff:
      "Detected {industry} is installed. Routing to sf-{industry-skill}
       because this request touches {matched object/process}."
   b. STOP generic workflow
   c. Return control to parent agent with skill={industry-skill} as next action
4. If user request does NOT overlap (pure generic work on standard objects
   the industry doesn't extend): proceed with generic skill.
```

---

## Exceptions (when generic still owns the task even with industry present)

The generic skill still owns the work if **all** of:

- User explicitly says "use standard Salesforce" / "bypass the industry overlay" / "ignore FSC/Health/etc."
- The object in question has no industry-specific extensions in the detected industry's data model
- The work is cross-industry infrastructure (e.g., raw Apex class unrelated to industry objects, generic trigger framework, Connected App config)

Document the exception reasoning in the skill's output so the decision is auditable.

---

## Last verified against

- Spring '26 release notes
- Industry Cloud editions available as of 2026-05-01
- Salesforce license SKUs active as of Spring '26

Update this file whenever a new industry cloud GA'd or a namespace/license string changes.
