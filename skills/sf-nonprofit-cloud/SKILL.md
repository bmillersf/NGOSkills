---
name: sf-nonprofit-cloud
description: >
  Nonprofit platform orchestrator — routes to Nonprofit Cloud (NPC) or
  Nonprofit Success Pack (NPSP) skill tracks based on org context.
  TRIGGER when: user designs nonprofit Salesforce solutions, asks about
  NPC vs NPSP, migrates between platforms, or touches nonprofit-specific
  objects. Also triggers when user asks "should we use NPC or NPSP",
  "which nonprofit platform", "migrate from NPSP to NPC", or "comparing
  Nonprofit Cloud and NPSP". DO NOT TRIGGER when: generic Apex/LWC code
  (use sf-apex, sf-lwc), Flow XML (use sf-flow), or non-nonprofit
  Salesforce work.
license: MIT
metadata:
  version: "2.0.0"
  scoring: "100 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.npc_admin_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud_object_reference.meta/nonprofit_cloud_object_reference/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/nonprofit
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_nonprofit.htm
---

# sf-nonprofit-cloud: Nonprofit Platform Orchestrator

Routes nonprofit Salesforce work to the correct product track — **Nonprofit Cloud (NPC)** or **Nonprofit Success Pack (NPSP)** — and provides cross-cutting architecture, migration planning, and platform comparison.

## First Question

Before designing anything, determine the platform:

> **"Is this org running Nonprofit Cloud (NPC) or Nonprofit Success Pack (NPSP)?"**

| Signal | Likely Platform |
|--------|----------------|
| Person Account for individuals | **NPC** |
| Contact + Household Account for individuals | **NPSP** |
| Gift Transaction object for donations | **NPC** |
| Opportunity for donations, `npsp__` namespace fields | **NPSP** |
| Application object (native) | **NPC** |
| Outbound Funds Module installed (`outfunds__` namespace) | **NPSP + OFM** |
| Volunteers for Salesforce (`GW_Volunteers__` namespace) | **NPSP + V4S** |
| Program Management Module (`pmdm__` namespace) | **NPSP + PMM** |
| Engagement Plan Template object | **NPSP** |
| New org, no legacy data | **NPC** (default) |

---

## Skill Routing

Once the platform is known, dispatch to the correct sub-skills:

### Nonprofit Cloud (NPC) Track

| Domain | Skill | Key Objects |
|--------|-------|-------------|
| Fundraising | sf-nonprofit-fundraising | Gift Transaction, Payment Instrument, Gift Commitment, Gift Soft Credit, Gift Designation |
| Grantmaking | sf-nonprofit-grants | Application, Funding Award, Funding Disbursement |
| Program & Case Mgmt | sf-nonprofit-program-case | Program, Program Enrollment, Benefit, Benefit Disbursement, Case |
| Portals | sf-nonprofit-experience-cloud | Experience Cloud sites for NPC constituents |
| Portal UX | sf-nonprofit-experience-cloud-ux | Design patterns for nonprofit portals |

### NPSP Track

| Domain | Skill | Key Objects |
|--------|-------|-------------|
| NPSP Platform | sf-nonprofit-npsp | Contact, Household Account, Opportunity, Recurring Donation, Affiliation |
| Stewardship | sf-nonprofit-npsp (Engagement Plans, Levels) | Engagement Plan Template, Level |
| Grant Mgmt (OFM) | sf-nonprofit-npsp (OFM section) | Funding Request, Disbursement, Requirement (outfunds__) |
| Volunteer Mgmt (V4S) | sf-nonprofit-npsp (V4S section) | Volunteer Job, Shift, Hours (GW_Volunteers__) |
| Program Mgmt (PMM) | sf-nonprofit-npsp (PMM section) | Program, Program Engagement, Service Delivery (pmdm__) |
| Portals | sf-nonprofit-experience-cloud | Experience Cloud sites for NPSP constituents |
| Portal UX | sf-nonprofit-experience-cloud-ux | Design patterns for nonprofit portals |

---

## Nonprofit Cloud vs NPSP — Full Comparison

| Aspect | Nonprofit Cloud (NPC) | NPSP (Legacy) |
|--------|------------------------|---------------|
| **Foundation** | Core Salesforce platform, native objects | Managed package (`npsp__` namespace) |
| **Individual model** | Person Account (unified Account+Contact) | Contact + Household Account |
| **Donation object** | Gift Transaction | Opportunity |
| **Recurring giving** | Gift Commitment + Schedule | Recurring Donation (`npe03__`) |
| **Soft credits** | Gift Soft Credit object | Partial Soft Credit + Opportunity Contact Role |
| **Fund accounting** | Gift Designation + Gift Transaction Designation | GAU Allocation (`npsp__`) |
| **Relationships** | Contact Contact Relationship, Account Contact Relationship, Account Account Relationship, Party Relationship Group | Relationship (`npe4__`) + Affiliation (`npe5__`) |
| **Household** | Party Relationship Group (type=Household) | Household Account (auto-created) |
| **Grant management** | Native: Application, Funding Award, Funding Disbursement | Outbound Funds Module (separate managed package) |
| **Program management** | Native: Program, Program Enrollment, Benefit, Benefit Disbursement | No native equivalent — custom build or AppExchange |
| **Outcome tracking** | Native: Outcome, Outcome Activity, Indicator Definition, Indicator Result | No native equivalent |
| **Volunteer mgmt** | Native: Job Position, Job Position Shift, Job Position Assignment | Volunteers for Salesforce (GW_Volunteers__, separate package) |
| **Program mgmt (basic)** | Native: Program, Program Enrollment, Benefit, Benefit Disbursement | Program Management Module (pmdm__, separate package) |
| **Settings UI** | Standard Salesforce Setup | NPSP Settings tab (custom settings) |
| **Triggers/rollups** | Platform native | NPSP managed triggers + TDTM framework |
| **Customization** | Full platform flexibility | Constrained by managed package |
| **Roadmap** | Active development | Maintenance mode (critical fixes only) |
| **Best for** | New implementations, orgs ready to migrate | Existing orgs with deep NPSP investment |

---

## New Org Decision

```
Is this a new Salesforce org for a nonprofit?
├── YES → Use Nonprofit Cloud (NPC)
│         Route to: sf-nonprofit-fundraising, sf-nonprofit-grants,
│                   sf-nonprofit-program-case
└── NO → Is NPSP currently installed?
         ├── YES → Are they migrating to NPC?
         │         ├── YES → Use migration checklist (below)
         │         └── NO → Route to: sf-nonprofit-npsp
         └── NO → Use Nonprofit Cloud (NPC)
```

---

## Key Modules (NPC)

- **Fundraising**: Donor management, gift entry, campaigns, gift soft credits
- **Grantmaking**: Applications, reviews, funding awards, funding disbursements, compliance
- **Program Management**: Programs, enrollments, benefits, benefit disbursements, case management
- **Outcome Management**: Outcomes, activities, indicator definitions, indicator results, impact tracking
- **Volunteer Management**: Job positions, shifts, assignments, smart matching

## Key Modules (NPSP)

- **Donation Management**: Opportunities, recurring donations, matching gifts
- **Household & Relationships**: Household Accounts, relationships, affiliations
- **Campaign Attribution**: Campaign Members, primary campaign source
- **GAU & Allocations**: Fund accounting, split allocations
- **Customizable Rollups**: CRLP engine for donation summaries
- **Outbound Funds Module**: Grant management (separate install)
- **Volunteers for Salesforce**: Volunteer management (separate install)

---

## Data Model Quick Reference

### NPC Objects

| Domain | Key Objects |
|--------|-------------|
| **Constituents** | Person Account, Business Account, Party Relationship Group (Household) |
| **Fundraising** | Gift Transaction, Gift Soft Credit, Campaign, Gift Designation |
| **Grantmaking** | Application, Funding Award, Funding Disbursement, Budget |
| **Program** | Program, Program Enrollment, Benefit, Benefit Disbursement, Case |
| **Outcome** | Outcome, Outcome Activity, Indicator Definition, Indicator Result |
| **Volunteer** | Job Position, Job Position Shift, Job Position Assignment |

### NPSP Objects

| Domain | Key Objects |
|--------|-------------|
| **Constituents** | Contact, Household Account, Affiliation, Relationship |
| **Fundraising** | Opportunity, Recurring Donation, Partial Soft Credit, GAU Allocation |
| **Settings** | NPSP Settings (custom settings), Trigger Handler, Error Log |
| **OFM (optional)** | Funding Request (dual-purpose: application + award), Disbursement, Requirement, Review |

For full NPC data model, see [references/data-model.md](references/data-model.md).

---

## Architecture Patterns

### Person-Centric Design (NPC)

NPC uses **Person Account** as the single record for an individual across programs, donations, grants, and volunteer activity. Avoid Contact-centric patterns in NPC orgs.

### Contact-Centric Design (NPSP)

NPSP uses **Contact** as the primary individual record. Each Contact auto-creates or joins a **Household Account**. The Account record type and model choice (Household vs One-to-One) is set in NPSP Settings.

### Household Management

| Aspect | NPC | NPSP |
|--------|-----|------|
| **Container** | Party Relationship Group | Household Account |
| **Membership** | Account-Contact Relationship | Contact.AccountId |
| **Naming** | Configurable | NPSP Household Naming Settings |
| **Formal greeting** | Party Relationship Group field | Household Account field |

---

## NPSP-to-NPC Migration (Summary)

1. **Pre-migration**: Enable Person Accounts, clean data, map fields (no 1:1 assumption)
2. **Migration**: Move data and metadata; preserve relationships
3. **Post-migration**: Validate, update reports, verify AppExchange compatibility

See [references/migration-checklist.md](references/migration-checklist.md) for full checklist.

---

## Validation & Scoring

```
Score: XX/100
├─ Data Model Alignment: XX/25   (Correct platform objects, no cross-contamination)
├─ Module Fit: XX/20             (Right modules for requirements)
├─ Platform Selection: XX/15     (NPC vs NPSP decision justified)
├─ Migration Safety: XX/15       (NPSP→NPC mapping, no legacy anti-patterns)
├─ Integration: XX/15            (Data Cloud, Experience Cloud, AppExchange)
└─ Best Practices: XX/10         (Power of Us, security, naming)
```

---

## Anti-Patterns

- Mixing NPC and NPSP patterns in the same org
- Using Contact-centric design in an NPC org
- Using Person Accounts in an NPSP org without migration plan
- Assuming 1:1 NPSP-to-NPC field mapping
- Skipping Person Account enablement before NPC migration
- Building custom objects when standard NPC or NPSP objects suffice
- Installing NPSP in a new org when NPC is available

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| NPC fundraising architecture | sf-nonprofit-fundraising |
| NPSP data model, config, patterns | sf-nonprofit-npsp |
| NPC grantmaking | sf-nonprofit-grants |
| NPC program/case management | sf-nonprofit-program-case |
| Portal architecture | sf-nonprofit-experience-cloud |
| Portal UX/UI | sf-nonprofit-experience-cloud-ux |
| Custom objects/fields | sf-metadata |
| Apex triggers, services, batch jobs | sf-apex |
| Automations (Flows) | sf-flow |
| Test data | sf-data |
| Deployment | sf-deploy |
| SOQL queries | sf-soql |

---

## Terminology

- **Nonprofit Cloud** / **NPC** — Current native Salesforce nonprofit platform
- **NPSP** — Nonprofit Success Pack (legacy managed package)
- **OFM** — Outbound Funds Module (NPSP-era grant management package)
- **Person Account** — NPC individual constituent record (unified Account+Contact)
- **Household Account** — NPSP household container (Account record type)
- **Household** — Party Relationship Group of type Household (NPC)
- **Constituent** — Donor, volunteer, client, stakeholder
- **Gift Transaction** — NPC donation transaction
- **Opportunity** — NPSP donation transaction
- **TDTM** — Table-Driven Trigger Management (NPSP trigger framework)
- **CRLP** — Customizable Rollup Summaries (NPSP rollup engine)
