---
name: sf-nonprofit-npsp
description: >
  Nonprofit Success Pack (NPSP) managed package architecture with 120-point
  scoring. TRIGGER when: user works with NPSP orgs, configures Opportunity-based
  donations, Recurring Donations, Household Accounts, Affiliations,
  Customizable Rollups, NPSP Settings, Engagement Plans, Levels, Address
  management, Outbound Funds Module (OFM), Volunteers for Salesforce (V4S),
  Program Management Module (PMM), or touches objects with
  npsp__/npe01__/npo02__/npe03__/npe4__/npe5__/outfunds__/GW_Volunteers__/pmdm__
  namespaces. Also triggers when user says "I'm on NPSP", "we use NPSP", or
  "our org is NPSP-based". DO NOT TRIGGER when: Nonprofit Cloud (NPC) orgs using Person
  Account/Gift model (use sf-nonprofit-fundraising, sf-nonprofit-grants,
  sf-nonprofit-program-case), generic Apex/LWC (use sf-apex, sf-lwc), or
  non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "120 points across 6 categories"
---

# sf-nonprofit-npsp: Nonprofit Success Pack Architect

Expert Salesforce architect specializing in Nonprofit Success Pack (NPSP) managed package: Contact-centric data model, Opportunity-based donation tracking, Recurring Donations, Household management, Customizable Rollups, TDTM framework, Outbound Funds Module, and NPSP configuration.

## Core Responsibilities

1. **NPSP Data Model**: Contact + Household Account, Affiliations, Relationships, Address management
2. **Donation Management**: Opportunity-based gifts, Recurring Donations, GAU Allocations, Payments
3. **Household & Relationships**: Household naming, merging, Manage Households UI, address sync
4. **Stewardship**: Engagement Plans, Levels, donor recognition automation
5. **NPSP Configuration**: Settings, TDTM triggers, Customizable Rollups, batch jobs, Health Check
6. **Outbound Funds Module**: Grant management via OFM managed package
7. **Validation & Scoring**: Score designs against 6 categories (0-120 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Data model & objects** | [references/npsp-data-model.md](references/npsp-data-model.md) | Object relationships, namespaces, key fields |
| **OFM grant management** | [references/outbound-funds-module.md](references/outbound-funds-module.md) | Outbound Funds Module objects, patterns, configuration |

---

## NPSP Foundation

NPSP is a **managed package** installed on top of standard Salesforce. It extends the platform with nonprofit-specific objects, automation (via TDTM triggers), rollup calculations, and a dedicated settings UI.

### Package Namespaces

| Namespace | Package | Purpose |
|-----------|---------|---------|
| `npsp__` | Nonprofit Success Pack (core) | Donations, GAU, batch gift entry, settings, engagement plans, levels |
| `npe01__` | Contacts & Organizations | Payments, preferred phone/email |
| `npo02__` | Households | Rollup fields on Contact and Account (TotalOppAmount, etc.) |
| `npe03__` | Recurring Donations | Recurring Donation object and automation |
| `npe4__` | Relationships | Relationship object (person-to-person links) |
| `npe5__` | Affiliations | Affiliation object (person-to-org links) |
| `outfunds__` | Outbound Funds Module | Grant management (separate install) |

---

## Data Model

### Individual: Contact

The **Contact** is the primary individual record. Every Contact belongs to an Account.

- **Key fields**: FirstName, LastName, Email, MailingAddress, npsp__Primary_Affiliation__c
- **Household**: Auto-assigned to Household Account on creation
- **Preferred fields**: npe01__PreferredPhone__c, npe01__Preferred_Email__c

### Household Account

Auto-created when a Contact is created (Household model). Groups individuals sharing a household.

- **Record type**: Household Account
- **Naming**: Auto-generated from member names (configurable in NPSP Settings)
- **Fields**: npsp__Formal_Greeting__c, npsp__Informal_Greeting__c, npsp__Number_of_Household_Members__c
- **Rollups**: Total donations, largest gift, last gift date — rolled up from member Opportunities

### Organization Account

Standard Account for businesses, foundations, and other organizations.

- **Record type**: Organization
- **Use**: Corporate donors, grant funders, employer affiliations

### Relationship (npe4__)

Person-to-person relationship tracking.

- **Object**: npe4__Relationship__c
- **Key fields**: npe4__Contact__c, npe4__RelatedContact__c, npe4__Type__c
- **Reciprocal**: NPSP auto-creates mirror relationship (e.g., Parent ↔ Child)
- **Types**: Spouse, Partner, Parent, Child, Sibling, Friend, Employer, Employee, etc.

### Affiliation (npe5__)

Person-to-organization relationship.

- **Object**: npe5__Affiliation__c
- **Key fields**: npe5__Contact__c, npe5__Organization__c, npe5__Role__c, npe5__Status__c, npe5__Primary__c
- **Use**: Board membership, employment, volunteer roles at organizations

---

## Donation Management

### Opportunity as Donation

NPSP uses **Opportunity** for all donation tracking. The Contact Role links the donor Contact to the Opportunity.

| Field | Purpose |
|-------|---------|
| Amount | Donation amount |
| CloseDate | Gift date |
| StageName | Donation status (Pledged, Posted, Closed Won, etc.) |
| npsp__Primary_Contact__c | Donor (Contact lookup) |
| CampaignId | Campaign attribution |
| RecordTypeId | Donation, Grant, Membership, In-Kind, etc. |
| npsp__Acknowledgment_Status__c | Receipt tracking |

### Donation Flow

```
Donor Contact → Opportunity (Pledged/Received)
  → Payment (npe01__OppPayment__c) — auto-created
  → GAU Allocation (npsp__Allocation__c)
  → Partial Soft Credit (npsp__Partial_Soft_Credit__c)
  → Rollup to Contact + Household Account
```

### Payments

NPSP auto-creates a Payment record for each Opportunity.

- **Object**: npe01__OppPayment__c
- **Key fields**: npe01__Payment_Amount__c, npe01__Payment_Date__c, npe01__Paid__c, npe01__Payment_Method__c
- **Multi-payment**: Split a single Opportunity into multiple payments (installments)
- **Schedule**: Create payment schedules for pledges

### Recurring Donations (Enhanced)

Enhanced Recurring Donations (ERD) is the current standard (replaces legacy RD).

- **Object**: npe03__Recurring_Donation__c
- **Key fields**: npe03__Amount__c, npsp__InstallmentFrequency__c, npe03__Installment_Period__c, npsp__Day_of_Month__c, npsp__Status__c, npsp__RecurringType__c
- **Recurring types** (npsp__RecurringType__c): **Open** = ongoing indefinitely until manually closed; **Fixed** = limited number of installments (uses npsp__InstallmentFrequency__c × npe03__Installment_Period__c to determine total)
- **Schedule**: npsp__InstallmentFrequency__c and npe03__Installment_Period__c work together (e.g., InstallmentFrequency=1 + InstallmentPeriod="Monthly" = every month; InstallmentFrequency=2 + InstallmentPeriod="Weekly" = every 2 weeks)
- **Statuses**: Active, Lapsed, Closed, Paused
- **Installments**: Auto-generates Opportunities per schedule period
- **Pause**: Temporarily halt installment generation without closing
- **Elevate**: Integrates with Salesforce Payments for card/ACH processing

### GAU Allocations

Fund accounting via General Accounting Units.

- **GAU Object**: npsp__General_Accounting_Unit__c
- **Allocation Object**: npsp__Allocation__c
- **Key fields**: npsp__General_Accounting_Unit__c, npsp__Opportunity__c, npsp__Amount__c, npsp__Percent__c
- **Default GAU**: Set in NPSP Settings → Donations → Default allocations
- **Split**: Allocate across multiple GAUs by amount or percentage

### Soft Credits

- **Opportunity Contact Role**: Standard Salesforce mechanism — additional Contacts on an Opportunity
- **Partial Soft Credit** (npsp__Partial_Soft_Credit__c): NPSP object for partial attribution amounts
- **Household soft credit**: Auto-credited to all Household members

---

## NPSP Configuration

### NPSP Settings

Accessed via the **NPSP Settings** tab in the app. Key sections:

| Section | Controls |
|---------|----------|
| **People** | Account model (Household), Household naming, lead conversion |
| **Donations** | Default close date, payment auto-creation, matching gifts |
| **Recurring Donations** | ERD enablement, installment period, fiscal year |
| **Relationships** | Auto-create settings, reciprocal types |
| **Affiliations** | Auto-create from Account, primary affiliation behavior |
| **Bulk Data Processes** | Batch sizes, rollup engine settings |
| **System Tools** | Error handling, TDTM trigger config, automatic scheduling |

### TDTM (Table-Driven Trigger Management)

NPSP uses a trigger handler framework instead of standard Apex triggers.

- **Object**: npsp__Trigger_Handler__c
- **Controls**: Which NPSP automation runs on which object events
- **Customization**: Deactivate specific handlers, adjust load order
- **Caution**: Disabling handlers can break rollups, soft credits, and household naming

### Customizable Rollups (CRLP)

NPSP's rollup engine calculates donation summaries on Contact, Account, and GAU.

- **Rollup fields**: Total Donations, Number of Donations, Largest Gift, First/Last Gift Date, Best Gift Year
- **Target objects**: Contact, Account (Household + Organization), GAU, Recurring Donation
- **Customization**: Create custom rollups via NPSP Settings → Donations → Customizable Rollups
- **Filter groups**: Define which Opportunities to include/exclude (by record type, stage, etc.)
- **Engine**: Batch Apex job — runs on schedule or triggered incrementally

### Error Handling

- **Object**: npsp__Error__c
- **Stores**: Failed trigger actions, rollup errors, batch job failures
- **Monitor**: NPSP Settings → System Tools → Error Notifications
- **Email**: Configure error notification recipients

---

## Engagement Plans

Stewardship task automation — define templates of tasks that auto-create when applied to a Contact, Account, Opportunity, Campaign, Case, or Recurring Donation.

- **Template**: npsp__Engagement_Plan_Template__c — defines a reusable plan (e.g., "New Major Donor Stewardship")
- **Plan Task**: npsp__Engagement_Plan_Task__c — individual task within the template (e.g., "Send thank-you call Day 1," "Schedule site visit Day 14")
- **Plan**: npsp__Engagement_Plan__c — instance linking a template to a specific Contact/Opp/Campaign
- **Behavior**: When an Engagement Plan is applied, NPSP creates Task records on the assigned Contact/Account per the template schedule
- **Dependency**: Tasks can depend on prior task completion before their due dates start counting

### Common Templates

| Template | Use Case | Tasks |
|----------|----------|-------|
| New Donor Welcome | First-time gift acknowledgment | Thank-you call (Day 1), Welcome packet (Day 3), Newsletter signup (Day 7) |
| Major Gift Stewardship | Gifts above threshold | Personal call (Day 1), Impact report (Day 30), Invitation to event (Day 60) |
| Lapsed Donor Re-Engagement | LYBUNT outreach | Email check-in (Day 1), Phone call (Day 14), Personal letter (Day 30) |
| Year-End Campaign | Annual fund cycle | Appeal letter (Day 1), Follow-up email (Day 14), Phone-a-thon call (Day 21) |

---

## Levels

Auto-assign donor recognition levels based on giving thresholds using rollup field values.

- **Object**: npsp__Level__c
- **Key fields**: npsp__Target__c (Contact or Account), npsp__Source_Field__c (rollup field to evaluate), npsp__Minimum_Amount__c, npsp__Maximum_Amount__c
- **Assignment**: Batch job evaluates all Contacts/Accounts against Level definitions and stamps the level on the record
- **Field on Contact**: npsp__Level__c (text — stores the current level name)

### Example Levels

| Level Name | Min Amount | Max Amount | Source Field |
|------------|-----------|-----------|-------------|
| Bronze | 0 | 999.99 | npo02__TotalOppAmount__c |
| Silver | 1,000 | 4,999.99 | npo02__TotalOppAmount__c |
| Gold | 5,000 | 24,999.99 | npo02__TotalOppAmount__c |
| Platinum | 25,000 | — | npo02__TotalOppAmount__c |

---

## Address Management

NPSP manages addresses via a dedicated Address object, supporting multiple addresses per household and seasonal address rotation.

- **Object**: npsp__Address__c
- **Parent**: Account (Household)
- **Key fields**: npsp__MailingStreet__c, npsp__MailingCity__c, npsp__MailingState__c, npsp__MailingPostalCode__c, npsp__MailingCountry__c
- **Default**: npsp__Default_Address__c (boolean) — the currently active mailing address
- **Seasonal**: npsp__Seasonal_Start_Month__c, npsp__Seasonal_Start_Day__c, npsp__Seasonal_End_Month__c, npsp__Seasonal_End_Day__c — auto-switches the Household's mailing address during the seasonal window
- **Sync**: When the default Address changes, NPSP pushes the address to all Contacts in the Household

### Seasonal Address Pattern

Summer home scenario: a donor's Household has a primary address year-round, plus a seasonal address active June–August. NPSP's scheduled batch job auto-switches the Household mailing address on the seasonal start/end dates.

---

## Opportunity Naming

NPSP auto-generates Opportunity names using configurable patterns.

- **Setting**: NPSP Settings → Donations → Opportunity Names
- **Pattern tokens**: `{!Contact.Name}`, `{!Account.Name}`, `{!RecordType.Name}`, `{!CloseDate}`
- **Default**: "Contact Name MM/DD/YYYY RecordTypeName" (e.g., "Jane Doe 03/15/2024 Donation" — where "Donation" is the Opportunity Record Type name)
- **Customization**: Change pattern per Opportunity record type

---

## Lead Conversion

NPSP customizes standard lead conversion:

- Converts Lead to Contact in the correct Household Account (matches existing or creates new)
- Auto-creates Affiliation if Lead has Company
- Creates Opportunity if configured
- Respects NPSP Account model (Household, One-to-One, or Individual Bucket)
- **Setting**: NPSP Settings → People → Lead Conversion

---

## Contact & Account Merge

NPSP extends standard merge to preserve nonprofit-specific data:

- **Contact merge**: Merges Relationships, Affiliations, Partial Soft Credits, Engagement Plans, and recalculates rollups on surviving record
- **Account merge**: Merges Household members, re-parents Contacts, recalculates Household naming and rollups
- **Manage Households UI**: Custom interface (accessed from Household Account) for adding/removing members, splitting households, and updating Household naming

---

## Scheduled Batch Jobs

NPSP runs several batch Apex jobs on a schedule:

| Job | Purpose | Default Schedule |
|-----|---------|-----------------|
| Recurring Donation installments | Create Opportunities for upcoming RD periods | Daily |
| CRLP rollup recalculation | Full recalculation of all rollup fields | Nightly / on-demand |
| Seasonal address update | Switch Household addresses based on seasonal dates | Daily |
| Level assignment | Evaluate and stamp donor levels | Nightly |
| Error cleanup | Purge old npsp__Error__c records | Weekly |

Configure schedule and batch sizes in NPSP Settings → Bulk Data Processes and System Tools.

---

## NPSP Health Check

Built-in diagnostic tool accessible from NPSP Settings.

**Access**: NPSP Settings → System Tools → Health Check

- Validates Account model configuration
- Checks for orphaned Contacts (no Household)
- Verifies TDTM trigger handler integrity
- Identifies misconfigured CRLP definitions
- Flags deprecated settings or legacy configurations
- Reports results with pass/fail/warning for each check

---

## Gift Entry

NPSP provides two gift entry experiences:

### Gift Entry (Current)

The newer Gift Entry experience — a streamlined single-gift and batch-gift UI built on the Data Import infrastructure.

- **Single gift**: Guided form for one-at-a-time entry with donor lookup, amount, payment method
- **Batch gift**: Tabular entry for high-volume processing (events, direct mail)
- **Templates**: Customizable field layouts for different entry scenarios
- **Matching**: Auto-matches or creates Contacts and Opportunities
- **Elevate integration**: Processes card/ACH payments inline when Elevate is connected

### Batch Gift Entry (Legacy)

The original batch processing UI, also built on Data Import objects.

- **Object**: npsp__DataImportBatch__c (batch header), npsp__DataImport__c (individual rows)
- **Process**: Create batch → enter/import rows → match or create Contacts → process → creates Opportunities + Payments
- **Matching**: Auto-match donors by name/email or manual lookup
- **Templates**: Custom field sets control which columns appear in the entry grid
- **Dry run**: Validate before processing

### Acknowledgment & Receipting

NPSP tracks acknowledgment status on Opportunities:

- **Field**: npsp__Acknowledgment_Status__c (To Be Acknowledged, Acknowledged, Do Not Acknowledge)
- **Date**: npsp__Acknowledgment_Date__c
- **Automation**: Use Flow to auto-generate thank-you emails or letters when gifts reach "Closed Won"
- **Batch**: Acknowledgment status can be updated in bulk via reports or batch processing

---

## Outbound Funds Module (OFM)

OFM is a **separate managed package** for grant management, commonly used alongside NPSP.

### OFM Data Model

| Object | Purpose | Key Fields |
|--------|---------|------------|
| outfunds__Funding_Program__c | Funding initiative | Name, Description, Status, Total Budget |
| outfunds__Funding_Request__c | Grant application **and** award (dual-purpose) | Name, Applying Organization, Status, Requested Amount, Awarded Amount |
| outfunds__Disbursement__c | Payment to grantee | Funding Request, Amount, Scheduled Date, Status |
| outfunds__Requirement__c | Compliance requirement | Funding Request, Type, Status, Due Date |
| outfunds__Review__c | Reviewer comments/recommendations | Funding Request, Reviewer, Status, Comments |
| outfunds__GAU_Expenditure__c | Links disbursements to GAU | Disbursement, GAU, Amount |

> **Note**: There is no separate Funding Award object. The Funding Request record serves dual purpose — its Status changes to "Awarded" and `outfunds__Awarded_Amount__c` is populated when a grant is approved.

### OFM Lifecycle

```
Funding Program (budget)
  → Funding Request (application received)
  → Reviews (reviewer comments/recommendations)
  → Decision → Funding Request status changes to "Awarded" (outfunds__Awarded_Amount__c populated)
  → Requirements (compliance docs, reports)
  → Disbursements (payments released against Funding Request)
  → Closeout
```

### OFM vs NPC Grantmaking

| Aspect | OFM (NPSP) | NPC Native |
|--------|-----------|------------|
| **Installation** | Separate managed package | Built-in |
| **Namespace** | outfunds__ | No namespace |
| **Application & award** | Funding Request (dual-purpose: application + award) | Separate Application and Funding Award objects |
| **Integration** | Works alongside NPSP | Native to NPC platform |
| **Customization** | Limited by package | Full platform flexibility |

See [references/outbound-funds-module.md](references/outbound-funds-module.md) for detailed OFM patterns.

---

## Common Companion Packages

NPSP is often installed alongside additional managed packages:

| Package | Namespace | Purpose |
|---------|-----------|---------|
| **Outbound Funds Module** | `outfunds__` | Grantmaking (see OFM section above) |
| **Volunteers for Salesforce** | `GW_Volunteers__` | Volunteer management — jobs, shifts, hours, sign-up |
| **Salesforce Elevate** | — | Payment processing (card, ACH) for Gift Entry and Recurring Donations. **Note**: Elevate is a connected service/platform, not a managed package — it integrates via NPSP configuration, not a separate install. |
| **PMM (Program Management Module)** | `pmdm__` | Basic program/service delivery tracking for NPSP orgs |

### Volunteers for Salesforce (V4S)

Separate managed package for volunteer management, commonly installed with NPSP:

- **Objects**: GW_Volunteers__Volunteer_Job__c, GW_Volunteers__Volunteer_Shift__c, GW_Volunteers__Volunteer_Hours__c, GW_Volunteers__Volunteer_Recurrence_Schedule__c
- **Sign-up**: Sites/Experience Cloud page for public volunteer sign-up
- **Tracking**: Hours worked, status (Confirmed, Completed, No-Show, Canceled)
- **Campaigns**: Volunteer Jobs can link to Campaigns for event-based volunteering
- **NPC equivalent**: NPC has native Job Position, Job Position Shift, and Job Position Assignment objects (no managed package needed)

### Program Management Module (PMM)

Lightweight program tracking for NPSP orgs that need basic program management before migrating to NPC:

- **Objects**: pmdm__Program__c, pmdm__ProgramEngagement__c, pmdm__Service__c, pmdm__ServiceDelivery__c, pmdm__ServiceSchedule__c
- **NPC equivalent**: NPC has native Program, Program Enrollment, Benefit, Benefit Disbursement, Outcome, and Indicator objects with deeper functionality

---

## Decision Trees

### Account Model

NPSP supports multiple account models, but **Household** is the recommended default:

- **Household** (default): Contacts auto-grouped into Household Accounts. Best for individual donors/constituents.
- **One-to-One** (legacy): Each Contact gets its own Account. Not recommended for new orgs.
- **Individual Bucket** (legacy): All Contacts share a single "Individual" Account. Not recommended.

### Opportunity Record Types

Design record types to categorize donations:

| Record Type | Use Case |
|-------------|----------|
| Donation | Standard cash/check/card gifts |
| Grant | Received grants (org as grantee) |
| In-Kind | Non-cash donations (goods, services) |
| Membership | Membership dues |
| Matching Gift | Employer match |
| Major Gift | Gifts above threshold (separate workflow) |

### When to Migrate to NPC

Consider migration when:
- Starting a fresh implementation with no NPSP history
- AppExchange dependencies are compatible with NPC
- Org needs native program/outcome management
- NPSP customization limits are blocking requirements
- Organization is ready for an operational change (not just a product swap)

---

## Common Patterns

### Matching Gifts

1. Original Opportunity linked to donor Contact
2. Matching Opportunity created with Matching Gift Account = employer
3. Link via npsp__Matching_Gift__c lookup or Partial Soft Credit
4. Both roll up to Contact and Household

### Tribute / Memorial Gifts

1. Opportunity created for the paying donor
2. npsp__Tribute_Type__c = "In Honor Of" or "In Memory Of"
3. npsp__Honoree_Contact__c links to the honored person
4. Notification letter sent to honoree or family

### Fiscal Year Reporting

Configure fiscal year in NPSP Settings to align rollups with organizational fiscal calendar. Affects rollup calculations for "This Year," "Last Year," and "Best Gift Year."

---

## Validation & Scoring

```
Score: XX/120
├─ Data Model: XX/25             (Household model, Contacts, Affiliations)
├─ Donation Processing: XX/25    (Opportunities, Payments, GAU, Soft Credits)
├─ Recurring Giving: XX/20       (ERD, installments, payment integration)
├─ NPSP Configuration: XX/20     (Settings, TDTM, CRLP, error handling)
├─ OFM / Grant Management: XX/15 (If applicable — Funding Requests, Disbursements)
└─ Best Practices: XX/15         (Naming, security, AppExchange compat)
```

---

## Anti-Patterns

- Using One-to-One or Individual Bucket account model in new orgs
- Disabling TDTM handlers without understanding downstream impact
- Manually calculating rollups instead of using CRLP engine
- Ignoring npsp__Error__c records (silent failures accumulate)
- Hardcoding NPSP namespace in Apex without using namespace-aware patterns
- Building custom donation objects when Opportunity suffices
- Skipping Payment records (breaks NPSP financial reporting)
- Installing both NPSP and NPC in the same org
- Using OFM without configuring Requirement records (no compliance tracking)
- Building custom stewardship task logic instead of using Engagement Plans
- Manual donor level assignment instead of Level definitions
- Editing Contact addresses directly instead of using npsp__Address__c (breaks Household address sync)
- Not running NPSP Health Check after configuration changes
- Overriding Opportunity naming with workflow instead of NPSP naming settings
- Merging Contacts outside of NPSP merge UI (loses Relationships, Affiliations, Soft Credits)

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Platform comparison / migration | sf-nonprofit-cloud |
| NPC fundraising (if migrating) | sf-nonprofit-fundraising |
| NPC grants (if migrating) | sf-nonprofit-grants |
| Portal for NPSP constituents | sf-nonprofit-experience-cloud |
| Portal UX design | sf-nonprofit-experience-cloud-ux |
| Custom objects for NPSP extensions | sf-metadata |
| Apex triggers alongside TDTM | sf-apex |
| Flow automations | sf-flow |
| Test data (Contacts, Opportunities) | sf-data |
| Deploy NPSP metadata | sf-deploy |
| SOQL for NPSP objects | sf-soql |

---

## Terminology

- **NPSP** — Nonprofit Success Pack (managed package)
- **TDTM** — Table-Driven Trigger Management (NPSP trigger framework)
- **CRLP** — Customizable Rollup Summaries
- **ERD** — Enhanced Recurring Donations
- **OFM** — Outbound Funds Module (grant management package)
- **Household Account** — Account grouping individual Contacts into a household
- **Affiliation** — Person-to-organization relationship (npe5__)
- **Relationship** — Person-to-person relationship (npe4__)
- **GAU** — General Accounting Unit for fund attribution
- **Partial Soft Credit** — NPSP object for partial gift attribution amounts
- **Data Import** — NPSP batch gift entry object
- **Elevate** — Salesforce native payment processing platform
- **Engagement Plan** — Stewardship task automation template
- **Level** — Donor recognition tier based on rollup thresholds
- **Seasonal Address** — Address that auto-activates during a date range
- **Health Check** — NPSP built-in configuration diagnostic tool
- **Manage Households** — Custom UI for household membership management
- **npo02__** — Households namespace (rollup fields on Contact/Account)
