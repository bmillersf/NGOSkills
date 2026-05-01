---
name: sf-industry-fsc
description: >
  Financial Services Cloud (FSC) architecture with industry-first routing precedence.
  TRIGGER when: user is working in an FSC-enabled org on banking, wealth, insurance,
  mortgage, or lending use cases; scenarios include "build a household" / "model a
  household with multiple members", "life event moment" / "capture a life event
  (marriage, home purchase, retirement)", "track financial accounts" / "surface
  checking + savings + loan balances on the client 360", "mortgage/lending workflow"
  / "originate a mortgage through FSC" / "loan application pipeline", "insurance
  policy management" / "tie P&C and Life policies to an Individual or Household",
  "wealth management client 360" / "advisor book of business" / "relationship map
  for an advisor", "ARC (actionable relationship center) configuration" / "set up
  Actionable Relationship Center with the right groups/sections", "referrals
  management" / "route an intelligent need-based referral from banker to advisor",
  "compliant data sharing setup" / "CDS role hierarchy for a private bank",
  "FinServ__* object", "Person Account for a retail banking customer", "Rollups
  by Lookup Filter for household AUM", "Interaction Summary for a client
  meeting", "Engagement plan for an insurance renewal", or any request that
  touches FinServ__ namespace objects or FSC-branded features.
  DO NOT TRIGGER when: generic Sales Cloud Opportunity / pipeline work on a
  standard Account model with no FSC package present (use sf-sales-cloud); generic
  Service Cloud Case triage with no FSC-owned Case extensions (use sf-service-case);
  writing Apex triggers, handlers, batch jobs, or invocable methods, including
  ones that touch FinServ__ objects, where the question is code quality and not
  FSC data model design (use sf-apex); building LWCs that happen to render FSC
  fields — the LWC code itself (use sf-lwc); authoring Flow XML / record-triggered
  or screen flows, even when acting on FinServ__ objects, where the question is
  flow mechanics (use sf-flow); nonprofit donor/gift/grant/program work even if
  the nonprofit operates a credit union (use sf-nonprofit-fundraising,
  sf-nonprofit-grants, sf-nonprofit-program-case, sf-nonprofit-cloud); Data Cloud
  ingestion, harmonization, segmentation, activation, or identity resolution,
  even for FSC source data (use sf-datacloud and its phase skills); Data Cloud
  SQL / vector search (use sf-datacloud-retrieve); SOQL-only queries against
  FinServ__ objects (use sf-soql); permission set / FLS audits (use sf-permissions);
  metadata XML authoring for custom fields on FinServ__ objects (use sf-metadata
  after FSC data model is confirmed); deployment pipelines (use sf-deploy);
  Agentforce agents built on FSC data (use sf-ai-agentforce and route here only
  for the data model question).
license: MIT
compatibility: "Requires FSC managed package (namespace FinServ__) + FSC user licenses"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.fsc_admin_intro.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud_object_reference.meta/financial_services_cloud_object_reference/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/financial-services
    anchor: ""
    sha256: ""
    importance: supplemental
  - url: https://help.salesforce.com/s/articleView?id=sf.fsc_arc_overview.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.fsc_compliant_data_sharing_overview.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_fsc.htm
---

# sf-industry-fsc: Financial Services Cloud Architect

Owns all Financial Services Cloud (FSC) data model, relationship, process, and UX design work. FSC is a managed package with the `FinServ__` namespace layered on top of core Sales + Service Cloud, so the rules that govern a vanilla org no longer apply: Person Account is usually on; Household is a role, not an object type; Financial Accounts, Financial Goals, and Life Events have first-class objects; Rollups replace custom aggregation Apex; and ARC / Compliant Data Sharing / Intelligent Need-Based Referrals change how records are surfaced and shared.

This skill is the **first line of defence** when FSC is detected. Generic cloud skills (`sf-sales-cloud`, `sf-service-case`) are required to defer here for any work that touches FSC-owned objects or features.

---

## When This Skill Owns the Task

Use `sf-industry-fsc` when the work involves any of:

- Household modelling on Person Account + Account Contact Relationships (ACR)
- `FinServ__FinancialAccount__c`, `FinServ__FinancialAccountRole__c`, `FinServ__FinancialGoal__c`, `FinServ__LifeEvent__c`, `FinServ__Relationship__c`, `FinServ__ReciprocalRole__c`
- Relationship Maps, Relationship Groups, and Actionable Relationship Center (ARC) configuration
- Rollups by Lookup filters driving household-level AUM / liability / net-worth fields
- Interaction Summaries and Compliance metadata (Interaction, Interaction Attendee, Interaction Summary)
- Action Plans and Action Plan Templates scoped to FSC use cases
- Referrals and Intelligent Need-Based Referrals routing between personas (banker → advisor → mortgage officer → insurance agent)
- Compliant Data Sharing (CDS) group/role hierarchy design
- Lending / Mortgage origination on FSC + Mortgage objects (`LoanApplication`, `Residential_Loan_Application`, `MortgageProduct`)
- Insurance (P&C and Life): Policy objects, Claims, Producer, Household beneficiary mapping
- Wealth Management client 360 surfaces (advisor book, AUM rollups, client segmentation)
- Engagement features (Engagement Interactions, Engagement Attendees, Engagement Topics)

### Delegate outside this skill when

| Need | Route to | Boundary |
|---|---|---|
| Apex triggers, handlers, batch, queueable, invocable on FSC objects | [sf-apex](../sf-apex/SKILL.md) | Come back here to confirm the FSC data model first, then hand off code authoring |
| LWCs that render FSC data | [sf-lwc](../sf-lwc/SKILL.md) | This skill specifies the fields and relationships; sf-lwc writes the component |
| Flow XML, record-triggered or screen flows | [sf-flow](../sf-flow/SKILL.md) | This skill defines which FSC object the flow targets; sf-flow builds the flow |
| Data Cloud pipelines sourcing from FSC | [sf-datacloud](../sf-datacloud/SKILL.md) | FSC → DMO mapping lives there, not here |
| Custom fields on FinServ__ objects | [sf-metadata](../sf-metadata/SKILL.md) | After this skill confirms the FSC model doesn't already provide the field |
| SOQL against FinServ__ objects | [sf-soql](../sf-soql/SKILL.md) | Query authoring only |
| Permission set / FLS audit on FSC objects | [sf-permissions](../sf-permissions/SKILL.md) | CDS design stays here; FLS audit routes out |
| Named Credential / REST callout to a core banking or insurance platform | [sf-integration](../sf-integration/SKILL.md) | This skill identifies the FSC hook point; integration skill does the wiring |
| Agentforce topics/actions built on FSC data | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Model lives here; agent metadata lives there |
| Generic Sales Cloud pipeline with no FSC package | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) | Only when FSC is **not** installed |
| Generic Service Cloud case triage with no FSC Case extensions | [sf-service-case](../sf-service-case/SKILL.md) | Only when Case has no FSC-specific fields/record types |
| Nonprofit fundraising / grants / program / case even in a financial-adjacent org | [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) | FSC is not a substitute for NPC; route based on constituent model, not vertical |

---

## Industry Precedence Note

**Industry-first routing is non-negotiable.** When FSC is installed (detectable via `FinServ__` namespace, FSC Permission Set Licenses, or the presence of `FinServ__Household` / `FinServ__FinancialAccount__c` objects) AND the user's request touches any FSC-owned concept, `sf-industry-fsc` **wins** over every generic cloud skill:

- `sf-sales-cloud` MUST defer here for Account / Contact / Opportunity work that touches Person Account, Household ACR, Relationship, or any FinServ__ lookup.
- `sf-service-case` MUST defer here when Case carries FSC-specific record types (`FinServ__BankingCare`, `FinServ__WealthCare`, `FinServ__InsuranceCare`) or when Interaction / Interaction Summary is involved.
- The generic skills' Phase 0 industry pre-check (at `references/industry-precheck.md`) lands here for FSC orgs. Industry skills are the **destination** of that pre-check, not a consumer — this skill does not run the pre-check itself.

If a user prompt is ambiguous ("add a field to Account for the household's primary banker"), resolve ambiguity in favour of FSC as long as the FSC package is confirmed installed. Never silently override the FSC data model with a generic Account customization.

---

## Required Context to Gather First

Before proposing any design, confirm:

1. **FSC edition detected** — Financial Services Cloud Basic, Standard, or Growth? Wealth Starter? Insurance add-on? Mortgage add-on? Each edition changes which objects and features are licensed.
2. **Persona in scope** — Retail banker, wealth advisor, insurance agent (P&C or Life), mortgage loan officer, private banker, commercial banker, relationship manager, compliance officer. The persona determines which objects are canonical and which are peripheral.
3. **Person Accounts enabled** — If not enabled, the FSC data model collapses to Contact + Household Account (NPSP-style); most modern FSC guidance assumes Person Account is on.
4. **ARC (Actionable Relationship Center) license** — Required for the relationship graph UI; without it, fall back to Relationship Map + related lists.
5. **Compliant Data Sharing (CDS) enabled** — Determines whether access is controlled via Participant Groups / roles vs standard sharing rules. CDS has its own object set (`ParticipantRole`, `AccountParticipant`, `OpportunityParticipant`).
6. **Mortgage / Insurance / Wealth clouds installed** — Each adds its own object set; confirm before proposing Lending or Policy designs.
7. **Rollups by Lookup Filter configuration** — Which FinServ rollup definitions already exist? Custom Apex aggregation is an anti-pattern when Rollups cover the need.
8. **Record Types on Account, Contact, Case** — FSC orgs commonly have `IndustriesHousehold`, `IndustriesBusiness`, `PersonAccount` (consumer), plus care record types. Confirm which are active.
9. **Intelligent Need-Based Referrals enabled** — Referral scoring + routing depends on this; if disabled, manual referral flows are the fallback.
10. **Compliance / regulatory boundary** — KYC, AML, FINRA, MiFID II, GDPR, CCPA, state insurance regulators. Data retention, disclosure, and audit requirements change the design.
11. **Engagement Add-On** — Engagement Interactions / Attendees / Topics are a separate feature set within FSC; confirm availability.
12. **Upstream integration surfaces** — Core banking (FIS, Jack Henry, Fiserv), custodian (Pershing, Schwab, Fidelity), policy admin (Duck Creek, Guidewire), loan origination (Encompass, nCino). These shape which fields are writeable vs read-only mirrors.

---

## Workflow Phases

### Phase 1 — Persona Selection

Pick the canonical persona first. Do not model the data before the persona is settled, because each persona has a different anchor object:

| Persona | Anchor | Dominant objects |
|---|---|---|
| Retail banker | Person Account (Individual) | Financial Account, Financial Goal, Life Event, Referral |
| Wealth advisor | Person Account (Individual) + Household | Financial Account, Financial Goal, AUM rollups, Relationship, Interaction Summary |
| Insurance agent (P&C) | Person Account + Policy (Property, Auto) | Policy, PolicyParticipant, Claim, Producer |
| Insurance agent (Life) | Person Account + Life Policy + Beneficiary | Policy (Life), Beneficiary, Household |
| Mortgage loan officer | Residential Loan Application | LoanApplication, Borrower, Property, MortgageProduct |
| Commercial banker | Business Account | Financial Account (commercial), Relationship, Lending |
| Compliance officer | Interaction / Interaction Summary | Interaction, Interaction Summary, Attendee, Action Plan |

If the user describes a multi-persona workflow (e.g., banker-to-advisor referral), both personas' object sets come into play — model them as a single graph, not as two silos.

### Phase 2 — Data Model Mapping

Decide, per record, whether each party is a Household, an Individual Person Account, or a Business Account. Rules of thumb:

- **Household** = Account record type `IndustriesHousehold` (or `FinServ__Household`) with Person Accounts joined via Account Contact Relationship with role `Household Member` / `Head of Household` / `Spouse`.
- **Individual** = Person Account with no Household (single filer, young professional, etc.). Household can be backfilled later.
- **Business** = Account record type `IndustriesBusiness` for commercial banking, RIA entity accounts, trusts, foundations.

A Household is not an object — it is a **relationship pattern** on Account. Never try to create a standalone "Household" custom object.

### Phase 3 — Relationship Modelling

Use the FSC relationship stack in order of preference:

1. **Account Contact Relationship (ACR)** — Person Account ↔ Household Account links (the backbone).
2. **FinServ__Relationship__c** — Person Account ↔ Person Account links (spouse, parent, child, trusted contact, attorney, CPA, referral source).
3. **FinServ__ReciprocalRole__c** — Defines role pairs (Parent ↔ Child, Trustee ↔ Beneficiary). Always create reciprocal roles in pairs, never as one-way.
4. **Relationship Group** — Virtual grouping for reporting and ARC; not a sharing boundary.
5. **Related Contact / Contact-to-Multiple-Accounts** — Platform-level feature, usable for non-FSC-specific relationships.

For an advisor's "book of business", the relationship is between User (advisor) and Account/Person Account via the Account Team or a custom Advisor field — not FinServ__Relationship__c.

### Phase 4 — Core Object Configuration

Configure the FSC primary objects in this order:

1. **Financial Account** (`FinServ__FinancialAccount__c`) — checking, savings, brokerage, IRA, 401(k), credit card, mortgage, auto loan, HELOC, annuity. Set `FinServ__FinancialAccountType__c` and `FinServ__FinancialAccountSubtype__c`; join to Primary Owner (Person Account) and Financial Account Role for joint owners / beneficiaries.
2. **Financial Goal** (`FinServ__FinancialGoal__c`) — retirement, college, home purchase, emergency fund. Link to Person Account and optional Financial Accounts contributing to the goal.
3. **Life Event** (`FinServ__LifeEvent__c`) — marriage, divorce, birth, home purchase, retirement, death, inheritance. Drives next-best-action via Intelligent Need-Based Referrals.
4. **Action Plan** — Template + Tasks for structured workflows (new account opening, retirement readiness review, annual insurance review).
5. **Referral** (`FinServ__Referral__c`) — banker-to-advisor, advisor-to-insurance, etc. Wire to Intelligent Need-Based Referrals if licensed.
6. **Interaction + Interaction Summary** — meeting capture, compliance documentation, AI-assisted summary.
7. **Engagement** — if licensed, model Engagement Interactions / Attendees / Topics for higher-fidelity meeting capture.

### Phase 5 — Process Automation

Order of preference for automation:

1. **Rollups by Lookup Filter** (FSC native) for aggregations (household AUM, household liabilities, total goal progress).
2. **Flow** (record-triggered or autolaunched) for declarative logic.
3. **Action Plans** for multi-step human workflows.
4. **Intelligent Need-Based Referrals** for AI-routed referrals.
5. **Apex** only when declarative options cannot meet the requirement (volume, cross-object, complex calculation). Route code authoring to `sf-apex`.

Never write custom Apex aggregation for AUM / liabilities / net worth — Rollups are the correct tool and they understand FSC relationship nuances (Household vs Individual vs Joint Financial Account).

### Phase 6 — ARC / Lightning App Wiring

- Configure **Actionable Relationship Center** groups and sections to surface the household graph on Person Account and Household record pages.
- Add ARC to the Lightning Record Page for Person Account (Individual) and Account (Household).
- Wire **Financial Account related list** with proper column set (Type, Balance, Primary Owner, Status).
- Add **Relationship Map** component for advisor-facing pages.
- Add **Interaction Summary** related list to Person Account and Household.
- Configure **Life Event timeline** on Person Account.
- Use **FSC-branded utility items** in the App (Referral Capture, Action Plan Launcher).

### Phase 7 — Testing and Rollout

- Create data factory Person Accounts, Households, Financial Accounts, Financial Goals, Life Events (route test data authoring to `sf-data`).
- Apex test classes for any custom code (route to `sf-apex` / `sf-testing`).
- UAT personas: retail banker, advisor, compliance officer, customer.
- Validate Rollups fire in the correct order (parent Household rollup depends on child Individual rollup).
- Validate CDS sharing: a banker without a Participant Role cannot see the wealth-only Financial Accounts on a shared Household.
- Validate Intelligent Need-Based Referrals scoring end-to-end.
- Deployment via `sf-deploy`; include FSC permission set assignments in the release train.

---

## Scoring Rubric

Total: **150 points across 7 categories.** Any category below its pass threshold fails the whole review.

```
Score: XX/150
├─ Persona Fit: XX/20                 (pass ≥ 14) Anchor object matches persona; no object-type mismatch
├─ Data Model Correctness: XX/25      (pass ≥ 18) Person Account vs Household vs Business chosen correctly; ACR roles reciprocal
├─ Relationship Integrity: XX/20      (pass ≥ 14) FinServ__Relationship + Reciprocal Role pairs valid; no orphan roles
├─ Process Automation: XX/25          (pass ≥ 18) Rollups used where possible; Flow > Apex; no duplicated aggregation logic
├─ UX / ARC: XX/20                    (pass ≥ 14) ARC groups + sections configured; Life Event timeline; Interaction Summary placement
├─ Security / Compliance: XX/25       (pass ≥ 18) CDS groups vs standard sharing chosen deliberately; audit trail; KYC/AML/FINRA fields
└─ Testing: XX/15                     (pass ≥ 10) Person Account + Household + Financial Account factory; CDS-aware test users
```

Passing score: **106/150 with every category at pass threshold.** A 130/150 with Security at 12/25 fails — the category floor is load-bearing for an industry skill in a regulated vertical.

---

## Anti-Patterns

- **Using standard Account instead of Person Account for consumer banking.** Retail banking + wealth in FSC assumes Person Account; a vanilla Account model forces a separate Contact for every individual and breaks ACR-based Household modelling, Rollups, ARC, and nearly every FSC feature.
- **Writing custom household aggregation Apex when Rollups by Lookup Filter exists.** Custom Apex aggregation for household AUM / liabilities is the single most common architectural mistake in FSC. Rollups handle it declaratively, survive managed-package upgrades, and respect FSC relationship semantics.
- **Treating `FinServ__FinancialAccount__c` as a standard Account.** Financial Accounts are a separate object with their own sharing, their own owner model (Primary Owner + Joint Owners via Financial Account Role), and their own rollups. Do not try to map them to custom Account records.
- **Creating a custom "Household" object.** Household is an Account record type plus an ACR pattern. A custom object fragments the data model and disables every Household-aware feature (Rollups, ARC, CDS, Relationship Map).
- **One-way `FinServ__Relationship__c` records with no reciprocal role.** Relationships must be created in pairs via `FinServ__ReciprocalRole__c`. A one-way relationship surfaces only on one Person Account's ARC and creates misleading client-360 views.
- **Bypassing Compliant Data Sharing with standard sharing rules in a CDS org.** If CDS is enabled, the Participant model governs access. Stacking OWD / sharing rules on top creates invisible grants and audit gaps.
- **Using Opportunity for every banking / wealth / mortgage deal.** Opportunity has a role (referral-to-close pipeline for advisors), but it is not the anchor for a Financial Account, a Life Event, or a Residential Loan Application. Overloading Opportunity fragments the data.
- **Letting `sf-sales-cloud` or `sf-service-case` run its own design on an FSC org.** Any generic cloud skill that touches FSC-owned objects must defer here. Silent override is a routing bug.
- **Putting KYC / AML / compliance fields on the wrong object.** KYC is typically on Person Account (individual identity); AML flags belong on Financial Account (transaction context). Swapping them breaks compliance reporting.
- **Configuring ARC without confirming the license.** ARC is a licensed add-on in some editions. If unlicensed, the design must fall back to Relationship Map + native related lists.

---

## Common Failure Modes and Remediation

| Symptom | Root Cause | Fix |
|---|---|---|
| Household AUM field is blank on Household record | Rollup by Lookup Filter not configured, OR rollup order is wrong (parent runs before child) | Audit `FinServ__RollupFilter__c` and `FinServ__RollupByLookupConfig__c`; reorder so Individual rollups fire before Household rollup |
| Referral created but never appears on the recipient's queue | Intelligent Need-Based Referrals scoring / routing rules not configured, or the recipient persona has no Participant Role | Confirm referral routing config; if CDS is on, add recipient to the correct Participant Group |
| Person Account disabled in a new org halfway through build | Person Account was never enabled, OR was enabled then feature flag flipped | Person Account is a one-way switch; escalate to Salesforce Support if it's off and required. Design with Contact + Household Account as a fallback only if support cannot enable it |
| ARC shows only direct relationships, not the extended graph | ARC Group / Section config missing, OR FinServ__Relationship records are one-way | Configure ARC Group with the right object set; audit Reciprocal Roles; backfill missing reciprocals |
| CDS sharing grants access to records a compliance officer should not see | Participant Role hierarchy inverted, OR standard sharing rule is bleeding through | Map the Participant Role tree against the regulatory boundary; disable or tighten standard sharing where CDS is authoritative |
| Financial Account balances are stale | No integration sync, OR sync writes to a custom field instead of `FinServ__CurrentBalance__c` | Confirm Named Credential + integration (route to `sf-integration`); standardize on FSC-native balance fields |

---

## FSC Object Cheat Sheet

| Object | API name | Purpose |
|---|---|---|
| Household Account | Account (record type `IndustriesHousehold` / `FinServ__Household`) | Household grouping of Person Accounts |
| Individual | Person Account (Account + Contact composite) | A single consumer |
| Business | Account (record type `IndustriesBusiness`) | Commercial banking / trust / entity |
| Account Contact Relationship | AccountContactRelation | Person Account ↔ Household Account roles |
| Relationship | FinServ__Relationship__c | Person Account ↔ Person Account relationships |
| Reciprocal Role | FinServ__ReciprocalRole__c | Role pair definitions (Spouse / Spouse, Parent / Child) |
| Financial Account | FinServ__FinancialAccount__c | Checking, savings, brokerage, loan, credit card, annuity, policy cash value |
| Financial Account Role | FinServ__FinancialAccountRole__c | Joint owner, beneficiary, trustee on a Financial Account |
| Financial Goal | FinServ__FinancialGoal__c | Retirement, college, home, emergency |
| Life Event | FinServ__LifeEvent__c | Marriage, birth, home purchase, retirement, inheritance, death |
| Action Plan | ActionPlan | Structured multi-step workflow |
| Action Plan Template | ActionPlanTemplate | Reusable Action Plan definition |
| Referral | FinServ__Referral__c | Banker → advisor → insurance routing |
| Interaction | Interaction | Meeting / call record |
| Interaction Attendee | InteractionAttendee | Participants on an Interaction |
| Interaction Summary | InteractionSummary | AI-assisted or manually captured summary |
| Engagement Interaction | EngagementInteraction | Higher-fidelity meeting capture (Engagement add-on) |
| Engagement Topic | EngagementTopic | Topic / agenda item on an Engagement |
| Rollup Filter | FinServ__RollupFilter__c | Declarative rollup definition |
| Rollup By Lookup Config | FinServ__RollupByLookupConfig__c | Rollup scoping / ordering |
| Participant Role | ParticipantRole | CDS role definition |
| Account Participant | AccountParticipant | CDS participant on an Account |
| Opportunity Participant | OpportunityParticipant | CDS participant on an Opportunity |
| Loan Application | LoanApplication | Lending pipeline record |
| Residential Loan Application | Residential_Loan_Application (Mortgage) | Mortgage-specific loan application |
| Mortgage Product | MortgageProduct | Mortgage product catalog entry |
| Borrower | Borrower | Borrower role on a mortgage application |
| Property | Property | Real estate on a mortgage / home insurance record |
| Policy | InsurancePolicy | P&C / Life / Health policy |
| Policy Participant | InsurancePolicyParticipant | Insured, beneficiary, dependent on a policy |
| Claim | InsuranceClaim | Policy claim |
| Producer | Producer | Licensed agent / broker record |

---

## Cross-Skill Integration

| Need | Route to | Reason |
|---|---|---|
| Apex trigger on FinServ__FinancialAccount__c | [sf-apex](../sf-apex/SKILL.md) | Code authoring lives there; this skill sets the data model contract |
| LWC for the household client 360 | [sf-lwc](../sf-lwc/SKILL.md) | Component code lives there |
| Flow to auto-create a Financial Goal on a Life Event | [sf-flow](../sf-flow/SKILL.md) | Flow mechanics live there |
| Custom field on FinServ__Referral__c | [sf-metadata](../sf-metadata/SKILL.md) | Only after confirming the FSC model doesn't already ship it |
| SOQL aggregations across Household + Financial Accounts | [sf-soql](../sf-soql/SKILL.md) | Query authoring |
| Bulk load 10k Person Accounts + Households for UAT | [sf-data](../sf-data/SKILL.md) | Bulk data operations |
| CDS Permission Set / FLS audit | [sf-permissions](../sf-permissions/SKILL.md) | Access audit tool |
| Named Credential to core banking / custodian | [sf-integration](../sf-integration/SKILL.md) | Integration wiring |
| Data Cloud pipeline from FSC to unified profile | [sf-datacloud](../sf-datacloud/SKILL.md) | Pipeline orchestration |
| Agentforce agent on top of FSC data | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Agent metadata |
| Diagram the household + referral + advisor graph | [sf-diagram-mermaid](../sf-diagram-mermaid/SKILL.md) | Visualization |
| Deployment of FSC metadata changes | [sf-deploy](../sf-deploy/SKILL.md) | Release train |

---

## Output Format

When finishing an FSC engagement, report in this order:

1. **FSC edition and features confirmed** (Basic / Standard / Growth / Wealth / Insurance / Mortgage)
2. **Persona(s) in scope**
3. **Data model summary** (Household vs Individual vs Business counts; key ACR roles used)
4. **Core objects configured** (Financial Account types, Goals, Life Events)
5. **Automation choices** (Rollups / Flow / Action Plan / Apex with justification)
6. **UX surfaces** (ARC, Relationship Map, Interaction Summary placement)
7. **Security model** (CDS vs standard sharing; KYC/AML field locations)
8. **Testing coverage** (factories, CDS-aware users, Rollup firing order)
9. **Score** against the 150-point rubric, with any failing category called out
10. **Next recommended step** (code handoff, deployment, integration wiring, Data Cloud mapping)
