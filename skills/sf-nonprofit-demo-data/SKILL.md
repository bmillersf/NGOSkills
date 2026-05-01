---
name: sf-nonprofit-demo-data
description: >
  Nonprofit demo data factory. Generates story-coherent, persona-matched
  Salesforce demo data for Nonprofit Cloud (NPC) and NPSP orgs based on
  a demoscript.md or persona definitions. Produces JSON trees, sf data
  import commands, and Anonymous Apex scripts with realistic names, amounts,
  dates, and relationships that make the demo story feel real. Populates
  EVERY writeable field on every generated record with realistic values
  unless the demoscript explicitly marks a field as empty-by-design (because
  a later demo step fills it in live), so layouts never look half-empty
  during a demo.
  TRIGGER when: user asks to seed demo data for a nonprofit demo, generate
  nonprofit demo records, create test data from a demoscript, populate the
  org with demo data, or asks for NPC/NPSP data that matches personas. Also
  triggers when user asks for "realistic test records", "populate my demo
  org", "fake donors for the demo", or "seed data for [persona]".
  DO NOT TRIGGER when: generic non-nonprofit data operations (use sf-data),
  metadata deployment (use sf-deploy), SOQL queries only (use sf-soql), or
  demo validation (use sf-demo-validate).
license: MIT
metadata:
  version: "1.2.0"
  author: "Brian Miller"
  scoring: "170 points across 8 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_data_unified.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.data_sample_import.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/data-model
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_api.htm
---

# sf-nonprofit-demo-data: Nonprofit Demo Data Factory

Expert nonprofit Salesforce data architect. Generates realistic, story-coherent demo data packages for Nonprofit Cloud (NPC) and NPSP orgs. Every record maps to a persona from the demoscript, uses realistic names and amounts, and is dated for demo freshness so nothing looks stale on demo day.

## Core Responsibilities

1. **Demoscript Parsing**: Read persona cards, data requirements, **and the empty-by-design field list** from `demoscript.md`
2. **Platform Detection**: Determine NPC vs NPSP and generate records with the correct object model
3. **Field Inventory**: Describe every target object and inventory all writeable fields (createable / updateable, FLS-accessible) before generating values
4. **Full-Field Population**: Generate realistic values for every writeable field on every record except the ones explicitly marked empty-by-design — no half-empty layouts on demo day
5. **Report-Shaped Distribution**: When the demo shows a dashboard / chart / KPI / trend, distribute records across realistic shapes (donor pyramid, seasonality, Pareto, funnel) so charts don't look one-sided
6. **Story Coherence**: Ensure data tells the same story as the demoscript (names, amounts, dates match)
7. **Data Package Generation**: Produce JSON trees, sf data CLI commands, and Anonymous Apex scripts
8. **Freshness Management**: Date all records appropriately -- future shifts, recent gifts, active enrollments
9. **Cleanup Scripts**: Generate teardown scripts to reset the org between demo runs

---

## Scoring Rubric (170 points)

| Category | Points | What's Evaluated |
|---|---|---|
| Story coherence | 30 | Data names, amounts, and relationships match the demoscript personas |
| Field population completeness | 20 | Every writeable, FLS-accessible field is populated unless on the empty-by-design list |
| Report-shape realism | 20 | Charts/dashboards fed by this data show realistic distributions (pyramid, seasonality, funnel) — no one-sided / flat / suspiciously even shapes |
| Platform accuracy | 25 | Correct object model for NPC vs NPSP |
| Data freshness | 20 | Future-dated shifts, recent gifts, no stale test artifacts |
| Relationship completeness | 25 | All record relationships are correctly wired (lookup/junction) |
| Import reliability | 20 | JSON trees and CLI commands execute without errors |
| Cleanup coverage | 10 | Teardown scripts reset all demo data cleanly |

**Thresholds**: ✅ 135+ (Ready to seed) | ⚠️ 100–134 (Review before seeding) | ❌ <100 (Fix required)

---

## Document Map

| Need | Document | Description |
|---|---|---|
| **NPC data model** | [references/npc-data-model.md](references/npc-data-model.md) | NPC objects, relationships, required fields for demo data |
| **NPSP data model** | [references/npsp-data-model.md](references/npsp-data-model.md) | NPSP objects, namespace fields, household patterns |
| **Data patterns** | [references/data-patterns.md](references/data-patterns.md) | Reusable patterns: giving history, volunteer history, enrollment sequences |
| **Sample data** | [assets/sample-data/](assets/sample-data/) | Ready-to-use JSON trees for common nonprofit scenarios |

---

## Workflow (6-Phase Pattern)

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

### Phase 3: Field Inventory + Empty-by-Design Contract

Before generating any record values, inventory every writeable field on every target object and resolve which ones must stay empty for the demo. This is what stops layouts from looking half-built on demo day **and** stops you from pre-filling a field the presenter is supposed to type live.

**Step 1 — Describe every target object** (run in parallel, one per object the package will touch):

```bash
sf sobject describe --sobject Account                       --target-org <alias> --json > .demo-cache/Account.describe.json
sf sobject describe --sobject npc__Gift_Transaction__c      --target-org <alias> --json > .demo-cache/Gift_Transaction.describe.json
sf sobject describe --sobject IndividualApplication__c      --target-org <alias> --json > .demo-cache/IndividualApplication.describe.json
# ...one per target object
```

**Step 2 — Filter the field list** for each object. Keep:

- `createable: true` AND `updateable: true` (writeable today and on future updates)
- FLS-accessible by the seeding user (skip otherwise — populating breaks the import)

Skip:

| Skip category | Why |
|---|---|
| Formula / rollup / auto-number fields | Calculated; you can't write them |
| System audit fields (`CreatedById`, `LastModifiedDate`, `SystemModstamp`, etc.) | Managed by the platform |
| `IsDeleted`, `OwnerId` (unless persona-specific) | Defaults are correct; only override `OwnerId` when the demo needs it |
| Long encrypted text / blob fields | Brittle; only populate if the demo references them |
| Master-detail or required lookups whose target wasn't generated yet | Will fail import; defer to Phase 4 ordering |

**Step 3 — Read the empty-by-design list** from the demoscript's `## Data Seed Requirements` section. Each record block in the demoscript may include an `Empty fields:` line:

```
### IndividualApplication
- James Okafor: Status=Submitted, CreatedDate=TODAY-2, VolunteerType=Tutor
  Empty fields: Background_Check_Status__c, Approval_Notes__c
  # ^ left blank because Step 4 of the demo shows Maria filling them in live
```

Build a per-object exclusion set from these lines. Every other writeable field gets a value in Phase 4.

**Step 4 — Emit a Field Population Plan** (one table per object) for the user to skim before generation runs:

```
## Field Population Plan: IndividualApplication__c
- 47 writeable fields detected
- 2 excluded (empty-by-design): Background_Check_Status__c, Approval_Notes__c
- 4 system-skipped: CreatedById, LastModifiedById, IsDeleted, SystemModstamp
- 41 will be populated for each record
  Sample values for James Okafor:
    FirstName__c              = "James"
    LastName__c               = "Okafor"
    Email__c                  = "james.okafor@demo.volunteer"
    Phone__c                  = "(312) 555-0142"
    Status__c                 = "Submitted"
    VolunteerType__c          = "Tutor"
    SubmittedDate__c          = 2026-04-19
    Description__c            = "Available weekday evenings; previous tutoring experience with after-school programs."
    PreferredCommunication__c = "Email"
    ...
```

If the user invokes the skill standalone (no demoscript), prompt: *"Are there fields that should stay empty so the presenter can fill them in live? Paste the list (Object.Field per line) or say 'none'."*

---

### Phase 4: Data Package Design

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

### Phase 5: Data Generation

Generate the data package using the correct method for each record type. **Every writeable field from the Phase 3 plan must appear** — partial records are a Phase 5 failure even if the script imports cleanly.

#### Method 1: JSON Tree (`sf data import tree`)
Best for hierarchical records (Account → Contacts → related records). Note how every writeable field on the Person Account is populated:

```json
[
  {
    "attributes": { "type": "Account", "referenceId": "EleanorWhitfieldRef" },
    "FirstName": "Eleanor",
    "LastName": "Whitfield",
    "Salutation": "Ms.",
    "MiddleName": "Anne",
    "Suffix": "",
    "IsPersonAccount": true,
    "PersonEmail": "eleanor.whitfield@demo.ngo",
    "PersonHomePhone": "(773) 555-0188",
    "PersonMobilePhone": "(773) 555-0177",
    "PersonOtherPhone": "",
    "PersonTitle": "Retired Educator",
    "PersonDepartment": "",
    "PersonBirthdate": "1952-03-14",
    "PersonMailingStreet": "1244 N. Lake Shore Dr, Apt 12B",
    "PersonMailingCity": "Chicago",
    "PersonMailingState": "IL",
    "PersonMailingPostalCode": "60610",
    "PersonMailingCountry": "United States",
    "PersonLeadSource": "Major Gift Officer Referral",
    "PersonAssistantName": "Diane Foster",
    "PersonAssistantPhone": "(773) 555-0190",
    "npe01__PreferredPhone__pc": "Home",
    "npo02__Best_Gift_Year__c": "2024",
    "npo02__TotalOppAmount__c": 67500
  }
]
```

#### Method 2: Anonymous Apex
Best for complex records, calculated fields, or records that require specific timing. Use the field inventory from Phase 3 to populate **everything** except the empty-by-design exclusions:

```apex
// Create James Okafor's volunteer application -- 41 of 47 writeable fields populated
// (2 empty-by-design per demoscript Phase 3, 4 system-skipped)
RecordType paRT = [SELECT Id FROM RecordType
                   WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

Account jamesAccount = new Account(
    Salutation                = 'Mr.',
    FirstName                 = 'James',
    MiddleName                = 'Adetola',
    LastName                  = 'Okafor',
    RecordTypeId              = paRT.Id,
    PersonEmail               = 'james.okafor@demo.volunteer',
    PersonHomePhone           = '(312) 555-0142',
    PersonMobilePhone         = '(312) 555-0143',
    PersonTitle               = 'Software Engineer',
    PersonDepartment          = 'Backend Platform',
    PersonBirthdate           = Date.newInstance(1992, 6, 11),
    PersonMailingStreet       = '4416 N. Greenview Ave, #2',
    PersonMailingCity         = 'Chicago',
    PersonMailingState        = 'IL',
    PersonMailingPostalCode   = '60640',
    PersonMailingCountry      = 'United States',
    PersonLeadSource          = 'Volunteer Hub Sign-up',
    PersonOtherPhone          = '(312) 555-0199',
    Description               = 'Engineer interested in tutoring high schoolers in math and CS. Available Tue/Thu evenings.'
);
insert jamesAccount;

IndividualApplication__c app = new IndividualApplication__c(
    FirstName__c              = 'James',
    LastName__c               = 'Okafor',
    Email__c                  = 'james.okafor@demo.volunteer',
    Phone__c                  = '(312) 555-0142',
    Status__c                 = 'Submitted',
    VolunteerType__c          = 'Tutor',
    PreferredSubject__c       = 'Mathematics',
    SecondarySubject__c       = 'Computer Science',
    AvailabilityWeekday__c    = 'Tue;Thu',
    AvailabilityTimeOfDay__c  = 'Evening',
    HoursPerWeek__c           = 4,
    SubmittedDate__c          = Date.today().addDays(-2),
    Source__c                 = 'Volunteer Hub',
    PreferredCommunication__c = 'Email',
    Description__c            = 'Available weekday evenings; previous tutoring experience with after-school programs in college.',
    EmergencyContactName__c   = 'Ada Okafor',
    EmergencyContactPhone__c  = '(312) 555-0144',
    npe03__Organization__c    = jamesAccount.Id
    // EMPTY-BY-DESIGN (per demoscript step 4): Background_Check_Status__c, Approval_Notes__c
);
insert app;
```

> **Anti-pattern**: Don't use `'Test'`, `'TBD'`, `'Lorem ipsum'`, or `'Sample'` as field values. Every populated field appears on screen during the demo — fillers break the illusion. Use realistic values that fit the persona's story.

#### Method 3: sf data CLI (single records / bulk)
Best for records with simple field requirements:

```bash
sf data create record \
  --sobject npc__Gift_Transaction__c \
  --values "npc__Amount__c=25000 npc__Status__c='Closed Won' npc__CloseDate__c=2026-01-15" \
  --target-org [alias]
```

---

### Phase 6: Freshness and Cleanup

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

## Field Population Standards

The Phase 3 inventory tells you **which** fields to populate. This section tells you **what** to put in them. Realistic values are non-negotiable — every populated field appears somewhere in the UI during the demo, and a sea of "Test123" / "TBD" / "Sample Data" instantly breaks the illusion.

### Value generation by field type

| Salesforce field type | What to write | Avoid |
|---|---|---|
| Text / TextArea | Persona-coherent prose ("Available Tue/Thu evenings; tutored at after-school program in college") | "Test", "Lorem ipsum", "Sample text", a single word |
| Long Text / Rich Text | 2-4 realistic sentences that match the persona's situation | Empty, single line, repeated paragraph |
| Picklist | A real value from the picklist; pick the one that matches the persona's story | First-alphabetical default, "Other" unless story-relevant |
| Multi-Select Picklist | 1-3 values relevant to the persona | All values, single throwaway value |
| Email | `firstname.lastname@demo.<context>` (`@demo.volunteer`, `@demo.ngo`, `@demo.family`) | Real domains, `test@test.com`, generic `info@example.com` |
| Phone | Realistic-format US number using the 555-01XX block (reserved for fictional use) | `1234567890`, `000-000-0000` |
| Address | Real street + city + state + ZIP for the persona's region; coordinates with city/state in the story | "123 Main St, Anytown USA" |
| Date | Anchored to the story timeline (TODAY-2 for "submitted recently", TODAY+14 for "upcoming shift") | Hard-coded historical dates, `1900-01-01` |
| DateTime | Same anchoring as Date + a realistic time-of-day (evenings for volunteers, business hours for staff) | Midnight for everything |
| Number / Currency | Persona-realistic amount (a major donor's gift is $25,000, not $50; a volunteer's hours are 4-12/wk, not 0.5) | Round defaults like 100 or 1000 across all records |
| Percent | A value matching the picklist's story implication (e.g. 75% confidence on a likely-to-give pledge) | 0% or 100% unless story demands it |
| Checkbox | The value that matches the persona's situation (an active volunteer has Active=true) | All checkboxes left at default |
| Lookup / Master-Detail | The Id of a related record generated earlier in the same package | Hard-coded Ids, null when the relationship is required |
| URL | A realistic-looking URL even if it doesn't resolve (`https://linkedin.com/in/james-okafor-demo`) | `http://example.com`, `https://test` |

### What to skip even though it's writeable

| Field pattern | Why to skip |
|---|---|
| `Background_Check_*`, `Approval_*`, `Decision_*` on intake records | Usually filled in live during the demo — confirm against the empty-by-design list |
| `OwnerId` | Defaults to the seeding user; only override when persona handoff is part of the story |
| `RecordTypeId` | Set explicitly when the object has multiple record types and the demo cares; otherwise let the default apply |
| Encrypted text, blob, or binary fields | Brittle to populate via tree/Apex; only fill if the demo references them |
| Fields the running user has no FLS access to | Will fail import; surface this gap to the user instead of silently skipping |

### Realistic-data tactics

- **Persona consistency**: every field for one persona ladders to one story. James Okafor's title is "Software Engineer", his lead source is "Volunteer Hub", his subject is "Computer Science". They reinforce each other.
- **Variation across personas**: don't use the same area code, employer, or domain for every persona — diversity in seeded data signals a mature org.
- **Address cohesion**: persona's mailing address city/state must match the chapter / region the demo references. A volunteer for a Chicago nonprofit shouldn't live in Phoenix.
- **Phone numbers**: use the **555-01XX** range — it's the block reserved by the FCC for fictional use, so it won't accidentally dial a real person if anyone screenshots the demo.
- **Birthdates / ages**: pick ages that match the persona's role (a major donor is usually 55+, a college-age volunteer is 18-24).
- **Currency amounts**: avoid suspiciously round numbers across the dataset. $25,000 is fine for a major gift; $25,000 / $25,000 / $25,000 across three donors is a tell.
- **Dates**: drive everything off `Date.today()` ± offsets so the data stays fresh on every re-seed. Never hard-code calendar dates.

### Acceptance check before emitting

For each generated record, count: **(populated fields) ÷ (writeable_fields − empty_by_design)** must be **= 1.0**. If it's less, identify which fields were skipped and either populate them or move them to the empty-by-design list with a justification.

---

## Report-Shaped Data Generation

Per-record realism (above) makes a single record look right. **Distribution realism** makes the *aggregate* — the dashboards, summary reports, and trend charts the demo will show — look right. A 12-volunteer dataset where 11 volunteers signed up on the same day produces an unusable bar chart, no matter how well each individual record is populated.

Whenever the demoscript mentions a dashboard, summary report, chart, KPI, trend, or "shows the audience the X view", switch into report-shaped mode for the records that feed it.

### Step 1 — Identify what the data has to plot

Read the demoscript and the dashboard/report XML (if it exists) and answer:

- **Which charts will this data feed?** (donor pyramid, gift trend over time, volunteer-shift fill rate, program enrollment by region, etc.)
- **What dimension is on the X axis or grouping?** (month, gift size bucket, program, region, status)
- **What measure is being aggregated?** (count, sum of amount, % of capacity)
- **How many distinct buckets does the chart need to look "alive"?** (a donut wants 4-7 slices; a trend line wants 12-24 datapoints; a horizontal bar wants 5-8 bars)

Record this per chart in a Report-Shaped Plan before generating.

### Step 2 — Pick a distribution shape that fits the dimension

Don't randomize uniformly. Real-world nonprofit data follows recognizable shapes — match the right one to each dimension:

| Dimension | Realistic shape | Anti-pattern (what NOT to generate) |
|---|---|---|
| **Donor giving size** | Power-law / donor pyramid: ~70% small ($25–$250), ~25% mid ($250–$5K), ~5% major ($5K–$100K+). One or two whales above. | Every donor gives the same amount, or amounts are uniformly distributed |
| **Gift trend over time** | Seasonality: Nov–Dec peak (giving season), modest June (FY end for many nonprofits), low Jan–Feb. ±20% noise per month. | Every month identical, or perfectly linear growth |
| **Recurring vs. one-time** | ~15-25% of donors recurring, ~75-85% one-time | 50/50 split (looks engineered) or 100% one type |
| **Volunteer hours** | Long-tail: most volunteers 1-5 hrs/mo, a small core 20-40 hrs/mo, a couple of superstars 60+ hrs | All volunteers at the same hours |
| **Volunteer shift fill** | 60-85% fill rate across shifts, with a couple of fully-booked and a couple of under-filled to show the operational story | 100% filled (boring) or 0% filled (broken-looking) |
| **Program enrollment by region** | Concentration in 2-3 home regions, a long tail of 1-2 enrollees in distant regions | One region only, or perfectly even distribution |
| **Application status pipeline** | Funnel: ~50% Submitted, ~25% Under Review, ~15% Approved, ~7% Onboarding, ~3% Rejected | Equal counts in every status (no funnel) |
| **Program outcomes / scores** | Bell curve around the target with a couple of outliers on each side | Everyone at exactly the target, or all at the floor |
| **Engagement frequency** | Pareto: ~20% of contacts drive ~80% of activity | Everyone equally engaged |
| **Demographics (age, region, household size)** | Reflect the org's actual service population (verify with the discovery notes) | Single demographic, or a too-clean rainbow distribution |

### Step 3 — Bucket realistic counts before assigning per-record values

Before generating individual records, decide how many records land in each bucket. Example for a 60-record donor dataset feeding a donor-pyramid chart:

```
Donor pyramid plan (n=60):
  $25 - $99       : 24 donors  (40%)   ← annual fund / first-time
  $100 - $499     : 18 donors  (30%)   ← sustaining donors
  $500 - $2,499   :  9 donors  (15%)   ← mid-level
  $2,500 - $9,999 :  6 donors  (10%)   ← key supporters
  $10,000 - $49K  :  2 donors  (3.3%)  ← major
  $50,000+        :  1 donor   (1.7%)  ← lead gift / capital campaign
```

Then assign each persona to a bucket and pick an amount **within** that bucket — not on the bucket edge. (Don't make every major donor exactly $10,000; spread across $11,500 / $14,000 / $22,500 / $25,000 etc.)

### Step 4 — Add longitudinal variance for trend charts

If the chart is time-series (gift trend, monthly volunteer hours, weekly applications), generate records dated across the full window the chart covers (usually trailing 12 months). For each month:

1. Start from a baseline volume (e.g. avg 8 gifts/month).
2. Apply the seasonality multiplier from Step 2 (Nov × 2.5, Dec × 3.5, June × 1.4, others 1.0 ± 0.2).
3. Add ± 15-25% random noise so two adjacent months never tie exactly.
4. Round to whole records, distribute the gift dates randomly within each month (avoid clustering everything on the 1st or the 15th).

A trend line with realistic seasonality + noise tells a story the audience recognizes from their own data. A flat or perfectly-linear trend looks fake.

### Step 5 — Sanity-check the resulting charts before declaring done

For each chart the demo will show, mentally render it from the generated data and check:

- [ ] **Multiple non-zero buckets**: A bar/donut chart has at least 3 visible segments; no segment is >70% of the total (unless that's the story).
- [ ] **Variance over time**: A trend chart has at least one visible peak and one visible trough; no two adjacent points are identical.
- [ ] **Realistic outliers**: A pyramid / Pareto chart has 1-2 outliers at the top and a long tail; not a flat row of equal-height bars.
- [ ] **Audience recognizes the shape**: The chart shape matches what a person from this nonprofit's real org would expect. If a development director would say "that doesn't look like our data", regenerate.
- [ ] **No accidental tells**: Suspicious patterns to scan for and remove: every persona starts on the 1st, every gift is a round multiple of $5K, every volunteer signed up on the same Tuesday, every program has the same enrollment count.

If any check fails, redistribute records before generating the import scripts. Distribution fixes are cheap before generation, expensive after.

### Apex helper pattern for distribution-aware generation

```apex
// Donor pyramid — 60 donors split across realistic giving buckets.
// Each bucket holds an array of [min, max] amounts; pick one per donor.
Map<String, List<Integer>> pyramid = new Map<String, List<Integer>>{
    'Annual'      => new List<Integer>{ 25,    99   },
    'Sustaining'  => new List<Integer>{ 100,   499  },
    'Mid'         => new List<Integer>{ 500,   2499 },
    'Key'         => new List<Integer>{ 2500,  9999 },
    'Major'       => new List<Integer>{ 10000, 49999},
    'Lead'        => new List<Integer>{ 50000, 100000}
};
Map<String, Integer> bucketCounts = new Map<String, Integer>{
    'Annual' => 24, 'Sustaining' => 18, 'Mid' => 9,
    'Key'    => 6,  'Major'      => 2,  'Lead' => 1
};

// ...then per donor, pick a tier, pick an amount = min + Math.mod(crypto-random, max-min)
// Date-stamp gifts with a seasonality-weighted distribution across trailing 12 months.
```

> **Anti-pattern**: don't generate 60 donors at exactly $1,000 because "it's an even number that scales nicely". Even-money everywhere is the #1 visible tell that data is synthetic.

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
