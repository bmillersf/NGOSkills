---
name: sf-nonprofit-demo-data
description: >
  Nonprofit demo data factory. Generates story-coherent, persona-matched
  Salesforce demo data for Nonprofit Cloud (NPC) and NPSP orgs based on
  a demoscript.md or persona definitions. Produces JSON trees, sf data
  import commands, and Anonymous Apex scripts with realistic names, amounts,
  dates, and relationships that make the demo story feel real.
  TRIGGER when: user asks to seed demo data for a nonprofit demo, generate
  nonprofit demo records, create test data from a demoscript, populate the
  org with demo data, or asks for NPC/NPSP data that matches personas.
  DO NOT TRIGGER when: generic non-nonprofit data operations (use sf-data),
  metadata deployment (use sf-deploy), SOQL queries only (use sf-soql), or
  demo validation (use sf-demo-validate).
license: MIT
metadata:
  version: "1.0.0"
  author: "Brian Miller"
  scoring: "130 points across 6 categories"
---

# sf-nonprofit-demo-data: Nonprofit Demo Data Factory

Expert nonprofit Salesforce data architect. Generates realistic, story-coherent demo data packages for Nonprofit Cloud (NPC) and NPSP orgs. Every record maps to a persona from the demoscript, uses realistic names and amounts, and is dated for demo freshness so nothing looks stale on demo day.

## Core Responsibilities

1. **Demoscript Parsing**: Read persona cards and data requirements from `demoscript.md`
2. **Platform Detection**: Determine NPC vs NPSP and generate records with the correct object model
3. **Story Coherence**: Ensure data tells the same story as the demoscript (names, amounts, dates match)
4. **Data Package Generation**: Produce JSON trees, sf data CLI commands, and Anonymous Apex scripts
5. **Freshness Management**: Date all records appropriately -- future shifts, recent gifts, active enrollments
6. **Cleanup Scripts**: Generate teardown scripts to reset the org between demo runs

---

## Scoring Rubric (130 points)

| Category | Points | What's Evaluated |
|---|---|---|
| Story coherence | 30 | Data names, amounts, and relationships match the demoscript personas |
| Platform accuracy | 25 | Correct object model for NPC vs NPSP |
| Data freshness | 20 | Future-dated shifts, recent gifts, no stale test artifacts |
| Relationship completeness | 25 | All record relationships are correctly wired (lookup/junction) |
| Import reliability | 20 | JSON trees and CLI commands execute without errors |
| Cleanup coverage | 10 | Teardown scripts reset all demo data cleanly |

**Thresholds**: ✅ 105+ (Ready to seed) | ⚠️ 80–104 (Review before seeding) | ❌ <80 (Fix required)

---

## Document Map

| Need | Document | Description |
|---|---|---|
| **NPC data model** | [references/npc-data-model.md](references/npc-data-model.md) | NPC objects, relationships, required fields for demo data |
| **NPSP data model** | [references/npsp-data-model.md](references/npsp-data-model.md) | NPSP objects, namespace fields, household patterns |
| **Data patterns** | [references/data-patterns.md](references/data-patterns.md) | Reusable patterns: giving history, volunteer history, enrollment sequences |
| **Sample data** | [assets/sample-data/](assets/sample-data/) | Ready-to-use JSON trees for common nonprofit scenarios |

---

## Workflow (5-Phase Pattern)

### Phase 1: Platform Detection

Before generating any data, determine the platform:

**Ask if not provided**:
> "Is this org running Nonprofit Cloud (NPC) or Nonprofit Success Pack (NPSP)?"

**NPC signals** (use NPC data model):
- Person Account model for individuals
- `npc__Gift_Transaction__c` for gifts
- `npc__Program_Enrollment__c` for enrollments
- `IndividualApplication__c` for volunteer intake

**NPSP signals** (use NPSP data model):
- Contact + Household Account model
- `Opportunity` (with `npsp__` fields) for gifts
- `npsp__Program_Enrollment__c` or `pmdm__` for programs
- Standard `Contact` for volunteer records

Never mix models -- generate one or the other based on the detected platform.

---

### Phase 2: Persona Data Mapping

Read the persona cards from the demoscript and map each to the records needed:

| Persona type | Records to create |
|---|---|
| Volunteer (applicant) | Contact/Person Account, IndividualApplication__c, VolunteerShiftSignup or equivalent |
| Volunteer Coordinator | User record (or verify existing), permission set assignment |
| Donor | Contact/Person Account, Gift Transactions or Opportunities, giving history (3+ years) |
| Program Participant | Contact/Person Account, Program Enrollment, Service Deliveries |
| Program family | Account (Household), multiple Contacts, shared enrollment |
| Grantee | Account (Organization), Grant Application, Award records |

For each persona, use:
- **The exact name** from the persona card (James Okafor, Maria Santos, etc.)
- **Realistic field values** that match their story (a tutor volunteer has tutoring skills; a major donor has a 10-year giving history)

---

### Phase 3: Data Package Design

Design the full data package before writing any code:

```
Data Package: [Demo Name]
Platform: NPC | NPSP
─────────────────────────────────────────
Accounts/Person Accounts:
  - James Okafor (Person Account) — volunteer applicant
  - Eleanor Whitfield (Person Account) — major donor
  - The Johnson Family (Household Account) — program family
    └── Aisha Johnson (Contact)
    └── Marcus Johnson (Contact)

Gifts (NPC: Gift Transactions | NPSP: Opportunities):
  - Eleanor Whitfield: $25,000 (current year, Closed Won)
  - Eleanor Whitfield: $22,500 (prior year, Closed Won)
  - Eleanor Whitfield: $20,000 (2 years prior, Closed Won)
  - Open Pledge: $30,000 (next year)

Volunteer Records:
  - IndividualApplication__c for James Okafor (submitted today - 2 days)
  - Open Shifts (3 records, each future-dated 7-14 days out)
  - Skills match: Tutoring on both the applicant and the open shifts

Program Enrollments:
  - Aisha Johnson enrolled in "After School Tutoring" (active, start date 30 days ago)
  - Service deliveries: 4 sessions logged

Users:
  - maria@demo.org (Volunteer Coordinator)
─────────────────────────────────────────
```

---

### Phase 4: Data Generation

Generate the data package using the correct method for each record type:

#### Method 1: JSON Tree (`sf data import tree`)
Best for hierarchical records (Account → Contacts → related records):

```json
[
  {
    "attributes": { "type": "Account", "referenceId": "EleanorWhitfieldRef" },
    "FirstName": "Eleanor",
    "LastName": "Whitfield",
    "IsPersonAccount": true,
    "PersonEmail": "eleanor.whitfield@demo.ngo",
    "npe01__PreferredPhone__pc": "Home"
  }
]
```

**Command**:
```bash
sf data import tree --files data/demo-accounts.json --target-org [alias]
```

#### Method 2: Anonymous Apex
Best for complex records, calculated fields, or records that require specific timing:

```apex
// Create James Okafor's volunteer application
Account jamesAccount = new Account(
    FirstName = 'James',
    LastName = 'Okafor',
    RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount'].Id,
    PersonEmail = 'james.okafor@demo.volunteer'
);
insert jamesAccount;

IndividualApplication__c app = new IndividualApplication__c(
    FirstName__c = 'James',
    LastName__c = 'Okafor',
    Email__c = 'james.okafor@demo.volunteer',
    Status__c = 'Submitted',
    VolunteerType__c = 'Tutor',
    SubmittedDate__c = Date.today().addDays(-2),
    npe03__Organization__c = jamesAccount.Id
);
insert app;
```

#### Method 3: sf data CLI (single records / bulk)
Best for records with simple field requirements:

```bash
sf data create record \
  --sobject npc__Gift_Transaction__c \
  --values "npc__Amount__c=25000 npc__Status__c='Closed Won' npc__CloseDate__c=2026-01-15" \
  --target-org [alias]
```

---

### Phase 5: Freshness and Cleanup

**Freshness rules**:
- Volunteer shifts: **7–21 days in the future** (not past)
- Gift close dates: **current calendar year** for "this year's gift"
- Application submission dates: **2–7 days ago** (fresh but not today)
- Program enrollment start dates: **30–60 days ago** (established, not new)
- Upcoming events: **at least 5 days out** (enough time to "sign up" in the demo)

**Cleanup script** (generate always):
```apex
// Demo data teardown -- run before or after each demo session
List<String> demoEmails = new List<String>{
    'james.okafor@demo.volunteer',
    'eleanor.whitfield@demo.ngo',
    'aisha.johnson@demo.family'
};

// Delete in reverse dependency order
delete [SELECT Id FROM npc__Gift_Transaction__c WHERE npc__Donor__r.PersonEmail IN :demoEmails];
delete [SELECT Id FROM IndividualApplication__c WHERE Email__c IN :demoEmails];
delete [SELECT Id FROM Account WHERE PersonEmail IN :demoEmails OR Name = 'The Johnson Family'];
System.debug('Demo data cleanup complete');
```

Always identify demo records by email domain (`@demo.volunteer`, `@demo.ngo`, `@demo.family`) so cleanup never touches real data.

---

## NPC Object Quick Reference

| Data type | Object | Key fields |
|---|---|---|
| Individual | Account (Person Account) | FirstName, LastName, PersonEmail, RecordTypeId |
| Household | Account | Name, RecordType = 'HH_Account' |
| Gift | npc__Gift_Transaction__c | npc__Amount__c, npc__Donor__c, npc__Status__c, npc__CloseDate__c |
| Recurring gift | npc__Recurring_Donation__c | npc__Amount__c, npc__Donor__c, npc__Status__c |
| Program | npc__Program__c | Name, npc__Status__c, npc__Start_Date__c |
| Enrollment | npc__Program_Enrollment__c | npc__Contact__c, npc__Program__c, npc__Status__c |
| Service delivery | npc__Service_Delivery__c | npc__Contact__c, npc__Service__c, npc__Date__c |
| Volunteer app | IndividualApplication__c | FirstName__c, LastName__c, Email__c, Status__c |
| Grant | outfunds__Funding_Request__c | Name, outfunds__Applying_Organization__c, outfunds__Requested_Amount__c |

## NPSP Object Quick Reference

| Data type | Object | Key fields |
|---|---|---|
| Individual | Contact + Account | FirstName, LastName, Email, AccountId (Household) |
| Household | Account | Name (auto: "Okafor Household"), npe01__SYSTEM_AccountType__c |
| Gift | Opportunity | Name, Amount, StageName, CloseDate, npsp__Primary_Contact__c |
| Recurring gift | npe03__Recurring_Donation__c | npe03__Contact__c, npe03__Amount__c, npe03__Date_Established__c |
| Soft credit | npsp__Partial_Soft_Credit__c | npsp__Contact__c, npsp__Opportunity__c, npsp__Amount__c |
| Program enrollment | pmdm__ProgramEngagement__c | pmdm__Contact__c, pmdm__Program__c, pmdm__Stage__c |
| Volunteer | Contact with GW_Volunteers__Volunteer_Status__c | GW_Volunteers__Volunteer_Status__c = 'Active' |
