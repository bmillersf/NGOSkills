---
name: sf-demo-data
description: >
  Story-coherent, persona-matched Salesforce demo data factory for Sales Cloud,
  Service Cloud, Revenue Cloud, industry clouds, and Agentforce demos.
  TRIGGER when: user asks to seed demo data for a non-nonprofit demo,
  generate cross-cloud demo records, populate the org with demo data, or
  requests realistic test records for Sales/Service/Marketing/Revenue/FSC/Health/
  PSS/Field Service/Manufacturing/Slack demos; also "populate my demo org",
  "fake customers for the demo", "seed data for the Sales demo".
  DO NOT TRIGGER when: nonprofit demo (use sf-nonprofit-demo-data), generic
  non-demo data ops (use sf-data), metadata deployment (use sf-deploy), SOQL
  queries only (use sf-soql), demo validation (use sf-demo-validate).
license: MIT
compatibility: "Works with Sales Cloud, Service Cloud, Revenue Cloud, industry clouds, Agentforce demos"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "130 points across 8 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.data_sample_import.htm
    importance: supplemental
---

# sf-demo-data: Cross-Cloud Demo Data Factory

Expert Salesforce data architect for **non-nonprofit demos**. Generates realistic, story-coherent demo data packages across Sales Cloud, Service Cloud, Revenue Cloud, industry clouds (FSC, Health, Education, Public Sector, Field Service, Manufacturing, Consumer Goods, Communications, Media, E&U), Marketing Cloud Growth / MCAE, Tableau, Slack, and Agentforce. Every record maps to a persona from the demoscript, uses realistic names, amounts, and dates, and produces story-shaped aggregate distributions for the dashboards, pipelines, case volumes, and forecasts the demo shows.

This is the cross-cloud peer of `sf-nonprofit-demo-data`. The two skills share the same 6-phase workflow, the same empty-by-design contract, and the same report-shape distribution discipline. This one owns everything *except* nonprofit data models; `sf-nonprofit-demo-data` owns NPC and NPSP.

---

## When this skill owns the task (delegate table)

Route the data-seeding task via this table so the right factory runs. The `sf-demo-orchestrate` Phase 5 routing already consults this exact mapping.

| Demo surface | Owning skill | Reason |
|---|---|---|
| Nonprofit Cloud (NPC) demo | `sf-nonprofit-demo-data` | Gift Transaction / Gift Designation / Program Enrollment / Individual Application; household / soft-credit patterns; donor-pyramid math |
| NPSP demo | `sf-nonprofit-demo-data` | NPSP `npe03__` Recurring Donation, `npsp__` Allocations, Household Account model |
| Sales Cloud demo (no industry) | **this skill** | Lead -> Opportunity pipeline, Forecasts, Cadences, Contact Roles, Sales Team |
| Service Cloud demo (no industry) | **this skill** | Case / Entitlement / Knowledge / Omni-Channel routing records |
| Revenue Cloud Advanced / CPQ demo | **this skill** | Product2 / Pricebook2 / Quote / Order / Contract / Subscription / Billing Schedule |
| FSC demo | **this skill** | Person Accounts + Households + Financial Accounts + Life Events + Financial Goals |
| Health Cloud demo | **this skill** | Patient + Care Plan + Care Request + Care Team (PHI redaction) |
| Education Cloud / EDA demo | **this skill** | Student + Program Enrollment (edu) + Course Connection + Affiliation |
| Public Sector Solutions demo | **this skill** | Constituent + Benefit + License + Permit + Inspection + Regulatory Code Violation |
| Field Service demo | **this skill** | Work Order + Service Appointment + Service Resource + Territory |
| Manufacturing Cloud demo | **this skill** | Sales Agreement + Account Forecast + Rebate Program |
| Consumer Goods / Communications / Media / E&U | **this skill** | Industry-specific objects (Visit, Offer, Subscriber, Premise) |
| Marketing Cloud Growth demo | **this skill** | Segment seed data + journey entry list + template records |
| MCAE (Pardot) demo | **this skill** | Prospect / List / Form / Landing Page / Scoring records |
| Tableau / CRM Analytics demo | **this skill** | Operational seed data feeding workbooks / datasets / Pulse metrics |
| Agentforce demo | **this skill** | Grounding records the agent reads (cases, accounts, order history) + sample conversation seed rows |
| Slack-First demo | **this skill** | Salesforce-side records whose events drive the Slack workflow |
| Mixed nonprofit + cross-cloud overlay | BOTH | Nonprofit first for parents; this skill second for the commercial overlay |

If the demoscript includes an industry-specific object that already has a dedicated `sf-industry-*` skill covering architecture, this skill still owns *data generation* for that industry. The industry skill owns architecture / metadata decisions; the data factory owns record generation and freshness. That boundary is identical to how `sf-nonprofit-demo-data` relates to `sf-nonprofit-cloud`.

---

## Industry pre-check (route or generate)

Before generating, run the industry pre-check from [`/references/industry-precheck.md`](../../references/industry-precheck.md). For this skill:

1. If **NPC or NPSP is detected** AND the demoscript's personas are nonprofit (donors, volunteers, clients, grantees), **halt and forward to `sf-nonprofit-demo-data`**. Print a one-line handoff and stop. This skill never generates Gift Transaction / Applicant / Program Enrollment records.
2. If any other industry (FSC / Health / EDA / PSS / Field Service / Manufacturing / Consumer Goods / Communications / Media / E&U) is detected, engage the matching **Industry Factory** in Phase 4 of this skill.
3. If no industry is detected and the demo is generic Sales / Service / Revenue / Marketing / Tableau / Slack / Agentforce, use the **Cross-Cloud Factory** in Phase 4.

Always record the routing decision in the generated Data Package plan so the orchestrator and downstream validators can audit it.

---

## Required context

Before Phase 1 runs, this skill needs:

1. **Target org alias** (`--target-org` value)
2. **`demoscript.md`** or equivalent persona / data-seed specification (what `sf-demo-author` produces)
3. **Product / industry detection** from `sf-demo-orchestrate` Phase 2.5 (or a direct run of `industry-precheck.md`)
4. **Demo duration** (from Phase 3 of `sf-demo-orchestrate`, if invoked downstream of the orchestrator). Duration bounds record counts — a 5-minute Lightning demo doesn't need a 60-donor pyramid; a 60-minute Workshop demo does.
5. **Empty-by-design field list** (fields the presenter fills in live). If absent, the skill asks for it.

If the skill is invoked standalone (no orchestrator), it prompts for each missing piece in sequence instead of guessing.

---

## Workflow phases

### Phase 1 — Persona extraction

Read the demoscript and extract a structured persona list. Each persona is the primary character in one or more demo steps and becomes a record (or a tight cluster of records) in the seed package.

| Persona archetype | Typical record set |
|---|---|
| B2B buyer (Sales demo) | `Account` (business) + 2-3 `Contact` + 1 `Lead` (converted) + 2-4 `Opportunity` at stages + `OpportunityContactRole` + `OpportunityTeamMember` + `Task` / `Event` |
| B2C customer (Service demo) | `Account` (Person Account) + 4-8 `Case` across priorities/statuses + `Entitlement` + `CaseMilestone` |
| FSC client / household member | `Account` (Person Account) + Household (Account + `AccountContactRelation` or v2 Household model) + `FinServ__FinancialAccount__c` (multiple types) + `FinServ__LifeEvent__c` + `FinServ__FinancialGoal__c` |
| Health Cloud patient | `Account` (Person Account, patient RT) + `CarePlan` + `CarePlanGoal` + `CarePlanProblem` + `CareTeamMember` + `CareRequest` + optional `ClinicalEncounter` |
| Education Cloud student | `Contact` (Student) or Education Account + `Program_Enrollment__c` + `Course_Connection__c` + `Affiliation__c` + `Term__c` |
| PSS constituent | `Account` + `BusinessLicense` + `RegulatoryCode__c` + `Inspection` + `RegulatoryCodeViolation` + `CareRequest` |
| Field Service customer | `Account` + `Asset` + `ServiceContract` + `WorkOrder` + `WorkOrderLineItem` + `ServiceAppointment` + `ServiceResource` / `ServiceTerritory` |
| Manufacturing distributor | `Account` + `SalesAgreement` + `AccountForecast` + `ProgramRebateType` + `SalesAgreementProduct` |
| Revenue Cloud customer | `Account` + `Opportunity` + `Quote` + `QuoteLineItem` + `Order` + `OrderItem` + `Contract` + `SubscriptionManagement` + `BillingSchedule` |
| Slack-First scenario | Driver records whose events emit to Slack (Opportunity stage change, Case escalation, Incident open) |
| Agentforce grounding | 20-40 records the agent reads: Accounts + Cases + Order history + Knowledge articles + Entitlements matching the agent's topic scope |

**Output**: a structured persona list with name, role, domain, cluster, and story-arc anchor (which demo step "belongs" to this persona). Store under `Phase 1 — Personas` in the Data Package plan.

### Phase 2 — Cloud / industry detection

Re-run the industry pre-check and re-confirm the routing decision. This is defensive — the orchestrator may have made its call minutes or hours ago, and a later install could change the answer. Record results in `.demo-cache/industry-precheck.json`.

For each cloud in scope, emit a Factory Selection row:

```
Factory Selection
─────────────────
Sales Cloud      -> Cross-Cloud.SalesPipelineFactory
FSC              -> Industry.FSC.HouseholdFactory
Agentforce       -> Cross-Cloud.GroundingFactory
Slack            -> Cross-Cloud.SlackTriggerFactory
Tableau          -> Cross-Cloud.AnalyticsFeederFactory
```

A factory is just a named recipe for generating a specific record cluster. The cheat sheet (below) lists the built-in factories.

### Phase 3 — Record count sizing

Size the package so the aggregate visuals feel alive but the demo stays performant. Duration bounds rule:

| Duration tier | Typical record budget |
|---|---|
| **Lightning (5 min)** | 10-20 records total; one driver persona; no dashboards |
| **Short (15 min)** *(default)* | 25-60 records; 1-2 personas; one dashboard |
| **Standard (30 min)** | 60-150 records; 2-3 personas; two dashboards |
| **Extended (45 min)** | 150-300 records; 3-4 personas; three dashboards |
| **Workshop (60 min)** | 300-600 records; 4-6 personas; full analytics tab |

Within the budget, allocate counts per cluster according to the aggregate views the demo shows. A Sales Cloud demo showing a 5-stage pipeline dashboard wants at least 3-5 records per stage; a Service Cloud demo showing priority-distribution wants counts following a realistic shape (P1 ~10%, P2 ~25%, P3 ~45%, P4 ~20%).

### Phase 4 — Relationship graph + generation

**Relationship graph first.** Before generating any record, draw the parent-child / lookup / junction dependency graph so import order is correct. Canonical ordering for cross-cloud demos:

1. `User` (presenter, demo personas if they log in)
2. `Account` (including Person Accounts) — parents of nearly everything
3. `Contact` — attached to Accounts
4. `Lead` — standalone until converted
5. Industry parents: `Household` (FSC), `CarePlanTemplate` (Health), `Program` (EDA), `ServiceTerritory` (Field Service)
6. Product catalog: `Product2`, `Pricebook2`, `PricebookEntry`
7. Opportunity + child records: `OpportunityContactRole`, `OpportunityLineItem`, `OpportunityTeamMember`
8. Case + child records: `CaseComment`, `CaseTeamMember`, `CaseMilestone`, `Entitlement`, `EmailMessage`
9. Industry children: `FinServ__FinancialAccount__c`, `CareRequest`, `Course_Connection__c`, `WorkOrder`, `SalesAgreement`
10. Revenue: `Quote`, `Order`, `Contract`, `Subscription`, `BillingSchedule`
11. Activities: `Task`, `Event`
12. Knowledge: `Knowledge__kav` and `DataCategorySelection`
13. Segments / Journey entry (MCG / MCAE) — last, since they reference everything above

**Generation methods** (identical to the peer skill):

- **Method 1 — JSON Tree (`sf data import tree`)**: preferred for hierarchical clusters (Account -> Contacts -> Opportunities -> OpportunityContactRole). File one tree per cluster, reference parents by `@referenceId`.
- **Method 2 — Anonymous Apex**: preferred for records needing computed values (Case age, Opportunity ExpectedRevenue recomputation, industry Apex hooks like FSC Relationship Map rebuild, Field Service scheduling engine triggers).
- **Method 3 — `sf data create record` / `sf data import bulk`**: preferred for flat record sets (bulk Leads, bulk Cases, bulk Contacts).

**Full-field population contract** (inherited verbatim from `sf-nonprofit-demo-data`): every writeable, FLS-accessible field on every generated record is populated with a realistic value *unless* the demoscript explicitly lists it as empty-by-design. Half-populated layouts on demo day are a Phase 4 failure regardless of whether the import succeeded. The field inventory + Field Population Plan is the gatekeeper.

**Realistic-data guardrails** (inherited verbatim from the peer skill):

- Use `555-01XX` for phone numbers (FCC-reserved fictional block)
- Use `@demo.<context>` email domains (`@demo.sales`, `@demo.service`, `@demo.fsc`, `@demo.health`, `@demo.edu`, `@demo.pss`, `@demo.fs`, `@demo.mfg`, `@demo.media`, `@demo.utility`) so cleanup never touches real data
- Never hard-code calendar dates; always `Date.today()` ± offset so re-seeding stays fresh
- Never use "Test" / "Sample" / "Lorem ipsum" values in populated fields — every populated field appears somewhere on screen

### Phase 5 — Verification + freshness

After import, run a smoke pass to confirm:

1. **Row counts match the plan** (query each object, compare to the plan; halt if delta > 5%)
2. **Freshness thresholds** — Cases created within last 14 days; Opportunities with `CloseDate` in the current or next quarter; Work Orders with `StartDate >= TODAY`; Sales Agreements active today; FSC Life Events within trailing 90 days
3. **Relationship integrity** — parent Ids resolved, no dangling lookups; `OpportunityLineItem.PricebookEntryId` non-null; `CaseMilestone.MilestoneTypeId` non-null
4. **Distribution realism** — the aggregate charts the demo will show pass the Phase 5 sanity-check loop inherited from the peer skill (multiple non-zero buckets, visible peaks/troughs, long-tail outliers for pyramid/Pareto)
5. **PHI / PII guardrail** — Health Cloud / FSC demos in sandbox confirmed to contain no real patient or client records (name-pattern scan against the seeding domain list; anything outside `@demo.*` fails the guardrail)

**Teardown**: generate a cleanup script that deletes records by `@demo.*` email or by a `Demo_Marker__c = true` custom field (if present in the target org). Reverse dependency order. Never hit production rows.

---

## Scoring rubric (130 points)

| Category | Points | What's evaluated |
|---|---|---|
| Story coherence | 20 | Persona names / roles / amounts / dates match demoscript and each other |
| Field population completeness | 15 | Every writeable, FLS-accessible field populated unless on empty-by-design list |
| Cloud / industry accuracy | 20 | Correct object model for each cloud; FSC vs Health vs PSS objects chosen correctly; industry-first routing honored |
| Report-shape realism | 15 | Pipeline / case-priority / agreement-amount distributions look like real data (pyramid, funnel, seasonality), no flat / perfectly-even curves |
| Relationship integrity | 15 | All lookups resolved, junctions wired (OpportunityContactRole, CareTeamMember, AccountContactRelation, SalesAgreementProduct) |
| Freshness | 15 | Dates anchored to `Date.today()` ± offset; Cases recent; Opportunities in current/next quarter; Work Orders future-dated |
| Import reliability | 15 | Tree files + Apex scripts + CLI commands run first-try; zero rollback; cleanup script runs idempotently |
| PII / PHI / regulatory guardrails | 15 | Demo domains used consistently; no real PII in sandbox; Section 508 copy on PSS records; HIPAA-redacted values in Health records |

**Thresholds**: 117+ (Ready to seed) | 90-116 (Review before seeding) | <90 (Fix required)

---

## Anti-patterns

1. **Mixing nonprofit objects into a cross-cloud package.** This skill must never emit `Gift_Transaction__c`, `ApplicationForm`, `Program_Enrollment__c` (NPC), or any `npsp__` / `npe03__` / `npo02__` records. If the demo needs them, halt and hand off to `sf-nonprofit-demo-data`.
2. **Generating Opportunities with even stage counts** (`5 records in each of 5 stages`) — real pipelines funnel; seed a funnel shape.
3. **Hard-coded calendar dates** — any record dated `2024-03-15` instead of `Date.today().addDays(-42)` will go stale within weeks.
4. **Ignoring the empty-by-design list** — if the demoscript says the presenter types the Opportunity close date live, that field must stay empty. Pre-filling it ruins the demo beat.
5. **Synthetic-looking amounts** — all Opportunities at exactly `$50,000` or `$100,000`; all Agreements priced at `$1,000,000` round numbers. Use persona-realistic variance.
6. **Person Account confusion on FSC / Health** — generating Contacts when Person Accounts are enabled (or vice versa). Always describe `Account` and check `IsPersonType = true` on the RT scan in Phase 2.
7. **Real PII in sandbox Health / FSC seeds** — using a real name / real address / real SSN that happens to match a living person. Always use the `@demo.*` domain + 555-01XX phone block + fictional address within the right state/city.
8. **Generating Slack seed data but forgetting the Salesforce event driver** — a Slack demo needs the Opportunity / Case / Incident record whose change event emits to Slack. Without it the Slack workflow has nothing to fire on.
9. **Over-seeding.** Generating 500 Opportunities for a 15-minute demo is unnecessary and slows the org. Respect the duration budget from Phase 3.

---

## Common failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| `REQUIRED_FIELD_MISSING` on Opportunity import | `Pricebook2Id` not set; org has no standard pricebook entry for the product | Add `Pricebook2Id` to the Opportunity Apex or seed Pricebook2 + PricebookEntry first |
| `INVALID_CROSS_REFERENCE_KEY` on QuoteLineItem | `QuoteId` references a tree entry that wasn't imported yet | Reorder the tree: Quote must import before QuoteLineItem in the same `sf data import tree` call, OR use separate `--plan-file` with explicit ordering |
| Entitlement shows no active milestone | `MilestoneType` not linked or `SlaProcessId` inactive | Verify `SlaProcess.IsActive = true` in the org; link Entitlement to it via Apex |
| FSC Household not displaying members | `AccountContactRelation` Role = 'Household Member' missing, or v2 Household model requires different relationship object | Detect FSC data model version first (v1 ACR vs v2 `FinServ__IndividualHouseholdRelationship__c`); generate for the active version only |
| Case Milestones don't fire | `Entitlement.StartDate` is in the future or `EndDate` in the past | Set `StartDate <= TODAY` and `EndDate >= TODAY + 365` |
| Service Appointment shows 'Unscheduled' forever | `ServiceResource` missing from `ServiceTerritory` member list, or scheduling policy has no primary operating hours | Ensure `ServiceTerritoryMember` links, `OperatingHours` record is attached to the territory |
| Agentforce "I can't find that" responses | Grounding records missing FLS for the running user, or segment DMO hasn't refreshed | Confirm FLS on all grounding objects for the demo user; if Data Cloud, force a segment rebuild (or use `sf-ui-fallback-playwright` to click Publish) |
| Tableau dashboard shows empty chart | Seed records created but dataflow hasn't re-ingested | Trigger a dataflow run after seeding (via CRM Analytics REST) or schedule the seed before the nightly run |
| PSS license / permit validation errors on import | Regulatory Code tie missing or `LicenseType` picklist value doesn't exist in the org | Describe `BusinessLicense` first; pick only active picklist values; seed `RegulatoryCode__c` parent before child |

---

## Cheat sheet — factory templates

Each template below is a minimal-but-realistic starting point. Expand each per the duration budget in Phase 3. Every template follows the full-field population contract in the full run.

### FSC Household (JSON tree)

```json
[
  {
    "attributes": { "type": "Account", "referenceId": "MeyersHouseholdRef" },
    "Name": "The Meyers Family",
    "RecordType": { "DeveloperName": "IndustriesHousehold" },
    "BillingStreet": "2180 N. Milwaukee Ave",
    "BillingCity": "Chicago",
    "BillingState": "IL",
    "BillingPostalCode": "60647",
    "BillingCountry": "United States",
    "Phone": "(312) 555-0144",
    "Industry": "Banking"
  },
  {
    "attributes": { "type": "Account", "referenceId": "SarahMeyersRef" },
    "FirstName": "Sarah",
    "LastName": "Meyers",
    "Salutation": "Ms.",
    "PersonEmail": "sarah.meyers@demo.fsc",
    "PersonMobilePhone": "(312) 555-0145",
    "PersonBirthdate": "1978-09-22",
    "PersonMailingStreet": "2180 N. Milwaukee Ave",
    "PersonMailingCity": "Chicago",
    "PersonMailingState": "IL",
    "PersonTitle": "Chief of Staff, Cook County",
    "IsPersonAccount": true
  },
  {
    "attributes": { "type": "FinServ__FinancialAccount__c", "referenceId": "SarahCheckingRef" },
    "Name": "Sarah Meyers - Checking",
    "FinServ__PrimaryOwner__c": "@SarahMeyersRef",
    "FinServ__Household__c": "@MeyersHouseholdRef",
    "FinServ__FinancialAccountType__c": "Checking Account",
    "FinServ__Balance__c": 42387.55,
    "FinServ__OpenDate__c": "2018-03-12"
  },
  {
    "attributes": { "type": "FinServ__LifeEvent__c", "referenceId": "HomePurchaseEventRef" },
    "FinServ__PrimaryOwner__c": "@SarahMeyersRef",
    "FinServ__EventType__c": "Home Purchase",
    "FinServ__EventDate__c": "2026-03-28",
    "FinServ__Description__c": "Closing on a single-family home in Logan Square; mortgage pre-approval via FSC advisor workflow."
  },
  {
    "attributes": { "type": "FinServ__FinancialGoal__c", "referenceId": "CollegeSavingsGoalRef" },
    "Name": "529 Plan — Ella (age 10)",
    "FinServ__PrimaryOwner__c": "@SarahMeyersRef",
    "FinServ__GoalType__c": "Education",
    "FinServ__TargetAmount__c": 180000,
    "FinServ__CurrentAmount__c": 47200,
    "FinServ__TargetDate__c": "2035-08-15"
  }
]
```

### Health Cloud Patient Cohort (Apex)

```apex
// Patient + Care Plan template + Care Team + Care Request -- 6 patient cohort
RecordType patientRT = [SELECT Id FROM RecordType
                        WHERE SObjectType = 'Account'
                          AND DeveloperName = 'HC_Patient' LIMIT 1];

List<Account> patients = new List<Account>{
    new Account(FirstName='Marcus', LastName='Okonkwo', RecordTypeId=patientRT.Id,
                PersonEmail='marcus.okonkwo@demo.health', PersonMobilePhone='(415) 555-0120',
                PersonBirthdate=Date.newInstance(1964, 4, 11), IsPersonAccount=true,
                PersonMailingStreet='1402 Page St', PersonMailingCity='San Francisco',
                PersonMailingState='CA', PersonMailingPostalCode='94117'),
    new Account(FirstName='Priya',  LastName='Natarajan', RecordTypeId=patientRT.Id,
                PersonEmail='priya.natarajan@demo.health', PersonMobilePhone='(415) 555-0121',
                PersonBirthdate=Date.newInstance(1979, 11, 2), IsPersonAccount=true)
    // ... 4 more patients with varied demographics
};
insert patients;

// Care Plan Template + Care Plan for diabetes management
Id cptId = [SELECT Id FROM CarePlanTemplate
            WHERE Name = 'Type 2 Diabetes Management' AND IsActive = true LIMIT 1].Id;

List<CarePlan> plans = new List<CarePlan>();
for (Account p : patients) {
    plans.add(new CarePlan(
        Name            = p.FirstName + ' ' + p.LastName + ' — Diabetes Plan',
        PatientId       = p.PersonContactId,
        Status          = 'Active',
        CarePlanTemplateId = cptId,
        StartDate       = Date.today().addDays(-14),
        EndDate         = Date.today().addDays(180)
    ));
}
insert plans;

// Care Request for the first patient (UM review scenario)
insert new CareRequest(
    Subject  = 'Prior authorization — insulin pump',
    PatientId = patients[0].PersonContactId,
    Status   = 'Submitted',
    Priority = 'High',
    Description = 'Requesting coverage for Tandem t:slim X2 pump; PCP notes attached.'
);
// EMPTY-BY-DESIGN per demoscript step 4: CareRequest.Decision, DecisionDate
```

### Sales Cloud Pipeline (Apex)

```apex
// 30-record pipeline: funnel shape across 5 stages
Account acme = [SELECT Id FROM Account WHERE Name = 'Acme Manufacturing' LIMIT 1];
Id demoUserId = [SELECT Id FROM User WHERE Alias = 'adem' LIMIT 1].Id;

Map<String, Integer> funnel = new Map<String, Integer>{
    'Qualification'    => 12,   // top of funnel
    'Needs Analysis'   =>  8,
    'Value Proposition'=>  5,
    'Proposal/Price Quote' => 3,
    'Negotiation/Review'   => 2
};
Map<String, Decimal> baseAmountByStage = new Map<String, Decimal>{
    'Qualification'        => 25000,
    'Needs Analysis'       => 48000,
    'Value Proposition'    => 72000,
    'Proposal/Price Quote' => 120000,
    'Negotiation/Review'   => 185000
};
List<Opportunity> opps = new List<Opportunity>();
for (String stage : funnel.keySet()) {
    for (Integer i = 0; i < funnel.get(stage); i++) {
        Decimal jitter = baseAmountByStage.get(stage) * (0.7 + (Math.random() * 0.6));  // +/- 30%
        opps.add(new Opportunity(
            Name        = acme.Name + ' — Expansion ' + stage + ' #' + (i + 1),
            AccountId   = acme.Id,
            OwnerId     = demoUserId,
            StageName   = stage,
            Amount      = jitter.setScale(0),
            CloseDate   = Date.today().addDays(14 + Math.mod(i * 7, 60)),
            LeadSource  = (Math.random() < 0.5 ? 'Partner Referral' : 'Trade Show'),
            Type        = 'Existing Customer - Upgrade',
            Description = 'Expansion opportunity tied to Q2 modernization roadmap.'
        ));
    }
}
insert opps;
// Expand with OpportunityContactRole + OpportunityTeamMember + Task/Event per demoscript
```

### Service Cloud Case Volume (Apex)

```apex
// Priority distribution: P1 10% / P2 25% / P3 45% / P4 20%
// Status distribution: New 20% / Working 45% / Escalated 5% / Closed 30%
// Seeded across trailing 14 days so the "Cases opened this week" dashboard looks alive.
List<Account> customers = [SELECT Id, PersonContactId FROM Account
                           WHERE IsPersonAccount = true
                             AND PersonEmail LIKE '%@demo.service' LIMIT 8];

List<Case> cases = new List<Case>();
String[] priorities  = new String[]{ 'High', 'Medium', 'Low', 'Low' };
String[] statuses    = new String[]{ 'New', 'Working', 'Working', 'Closed' };
String[] subjects    = new String[]{
    'Login issue after MFA rollout',
    'Billing discrepancy on March invoice',
    'Feature request: export to CSV',
    'Dashboard not loading in Safari',
    'Password reset email never arrived',
    'API timeout on webhook',
    'Mobile app crash on iOS 17',
    'Refund request — duplicate charge'
};
for (Integer i = 0; i < 40; i++) {
    cases.add(new Case(
        Subject     = subjects[Math.mod(i, subjects.size())],
        Priority    = priorities[Math.mod(i, priorities.size())],
        Status      = statuses[Math.mod(i, statuses.size())],
        Origin      = (Math.mod(i, 3) == 0 ? 'Phone' : (Math.mod(i, 3) == 1 ? 'Email' : 'Web')),
        AccountId   = customers[Math.mod(i, customers.size())].Id,
        ContactId   = customers[Math.mod(i, customers.size())].PersonContactId,
        Description = 'Customer reported issue via primary channel; triage in progress.'
    ));
}
insert cases;

// Backdate CreatedDate via the Tooling API or accept default (demo typically cares about status/priority distribution more than timestamp)
```

### Field Service Work Orders (condensed)

```apex
// 12 work orders -> scheduled + dispatched + in-progress + completed; territory = Chicago Metro
Id territoryId = [SELECT Id FROM ServiceTerritory WHERE Name = 'Chicago Metro' LIMIT 1].Id;
Id resourceId  = [SELECT Id FROM ServiceResource WHERE Name = 'Diego Alvarez' LIMIT 1].Id;
Account commercialAccount = [SELECT Id FROM Account WHERE Name = 'Lakeshore Properties' LIMIT 1];

List<WorkOrder> wos = new List<WorkOrder>();
for (Integer i = 0; i < 12; i++) {
    wos.add(new WorkOrder(
        Subject = 'Quarterly HVAC service — unit ' + (i + 101),
        AccountId = commercialAccount.Id,
        ServiceTerritoryId = territoryId,
        StartDate = Date.today().addDays(i),
        EndDate   = Date.today().addDays(i).addDays(1),
        Priority  = (Math.mod(i, 4) == 0 ? 'High' : 'Medium'),
        Status    = (i < 4 ? 'Completed' : (i < 8 ? 'In Progress' : 'New')),
        Description = 'Routine quarterly preventive maintenance visit.'
    ));
}
insert wos;

// ServiceAppointment per WorkOrder
List<ServiceAppointment> appts = new List<ServiceAppointment>();
for (WorkOrder w : wos) {
    appts.add(new ServiceAppointment(
        ParentRecordId    = w.Id,
        SchedStartTime    = DateTime.newInstance(w.StartDate, Time.newInstance(9, 0, 0, 0)),
        SchedEndTime      = DateTime.newInstance(w.StartDate, Time.newInstance(12, 0, 0, 0)),
        ServiceTerritoryId = w.ServiceTerritoryId,
        Subject = w.Subject
    ));
}
insert appts;
// Then AssignedResource linking resourceId to each ServiceAppointment
```

### Revenue Cloud quote-to-cash (Apex)

```apex
// Minimal CPQ / Revenue Cloud quote -> order -> contract -> subscription
Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Platform Pro Subscription' LIMIT 1];
Pricebook2 pb  = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name LIKE 'Acme%Expansion%' LIMIT 1];

Quote q = new Quote(
    OpportunityId = opp.Id,
    Name          = 'Acme — Platform Pro Expansion',
    Status        = 'Draft',
    Pricebook2Id  = pb.Id,
    ExpirationDate = Date.today().addDays(30)
);
insert q;

PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry
                      WHERE Pricebook2Id = :pb.Id AND Product2Id = :prod.Id LIMIT 1];

insert new QuoteLineItem(
    QuoteId        = q.Id,
    Product2Id     = prod.Id,
    PricebookEntryId = pbe.Id,
    Quantity       = 50,
    UnitPrice      = pbe.UnitPrice,
    Discount       = 12
);
// Advance to Order + Contract via Apex flows after the demo 'Accept Quote' step fires
```

---

## Handoffs

- **Upstream** invokers: `sf-demo-orchestrate` Phase 5 (most common), or direct user request outside the orchestrator.
- **Downstream** consumer: `sf-demo-validate` Phase 3 reads the records this skill produced and scores them. If validation fails, the fix loop may re-invoke this skill with a targeted diff (e.g., "add 3 P1 cases; freshen shift dates").
- **Peer**: `sf-nonprofit-demo-data` — same contract, different scope. Never overlap.
- **Industry partners**: each `sf-industry-*` skill owns the architecture and metadata; this skill owns the data. If the demoscript needs a new custom field or record type, stop and delegate to the industry skill + `sf-metadata` + `sf-deploy` before resuming data generation.
- **Repair delegation**: `sf-data` for low-level CLI record ops; `sf-apex` for generation logic that grew complex; `sf-soql` for verification queries.

---

## Dependencies

- **Required**: `sf` CLI v2 authenticated to the target org
- **Required**: `sf-demo-author` demoscript (`demoscript.md`) OR an equivalent persona + data-seed spec
- **Required**: industry pre-check run (Phase 2)
- **Recommended**: `sf-nonprofit-demo-data` installed (for nonprofit handoffs), `sf-demo-validate` (for downstream scoring), `sf-ui-fallback-playwright` (when segment / journey publish is CLI-blocked)
