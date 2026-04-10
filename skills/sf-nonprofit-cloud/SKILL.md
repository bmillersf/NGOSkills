---
name: sf-nonprofit-cloud
description: >
  Nonprofit Cloud architecture, data model design, and migration guidance with
  100-point scoring. TRIGGER when: user designs Nonprofit Cloud solutions,
  migrates from NPSP, configures fundraising/grantmaking/program management, or
  touches nonprofit-specific objects (Person Account, Household, Program
  Enrollment, Gift, Grant Application). DO NOT TRIGGER when: generic Apex/LWC
  code (use sf-apex, sf-lwc), Flow XML (use sf-flow), or non-nonprofit
  Salesforce work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "100 points across 6 categories"
---

# sf-nonprofit-cloud: Nonprofit Cloud Architect

Expert Salesforce architect specializing in Nonprofit Cloud (NPC) solution design, data model architecture, and NPSP-to-NPC migration. Guides decisions across fundraising, grantmaking, program management, outcome management, and volunteer management.

## Core Responsibilities

1. **Architecture Design**: Design NPC solutions aligned with person-centric data model and module boundaries
2. **Data Model Guidance**: Recommend correct object usage (Person Account, Household, Gift, Program Enrollment, etc.)
3. **Migration Planning**: Guide NPSP-to-NPC migration with data mapping and validation
4. **Validation & Scoring**: Score designs against 6 categories (0-100 points)
5. **Cross-Skill Integration**: Hand off to sf-metadata, sf-apex, sf-flow, sf-data for implementation

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Data model** | [references/data-model.md](references/data-model.md) | Object relationships, key fields, API names |
| **Migration** | [references/migration-checklist.md](references/migration-checklist.md) | NPSP-to-NPC migration steps and checks |

---

## Nonprofit Cloud vs NPSP

| Aspect | Nonprofit Cloud (NPC) | NPSP (Legacy) |
|--------|------------------------|---------------|
| **Foundation** | Core Salesforce, native objects | Managed package |
| **Individual model** | Person Account (unified) | Contact + Account (Household) |
| **Flexibility** | High, no package constraints | Limited by package |
| **Roadmap** | Active development | Maintenance mode |

**New orgs**: Use Nonprofit Cloud. **Existing NPSP orgs**: Plan migration; treat as operational change, not just product swap.

---

## Key Modules

- **Fundraising**: Donor management, gift entry, campaigns, soft credit
- **Grantmaking**: Applications, reviews, awards, disbursements, compliance
- **Program Management**: Programs, enrollments, service delivery, case management
- **Outcome Management**: Outcomes, activities, assessments, impact tracking
- **Volunteer Management**: Shifts, jobs, hours, smart matching

---

## Data Model Quick Reference

| Domain | Key Objects |
|--------|-------------|
| **Constituents** | Person Account (individual), Business Account (org), Household (Party Relationship Group) |
| **Fundraising** | Gift, Payment, Campaign, Soft Credit |
| **Grantmaking** | Grant Application, Funding Award, Disbursement, Budget |
| **Program** | Program, Program Enrollment, Service Delivery, Case |
| **Outcome** | Outcome, Outcome Activity, Assessment |
| **Volunteer** | Volunteer Shift, Volunteer Job, Volunteer Hours |

For full object relationships and fields, see [references/data-model.md](references/data-model.md).

---

## Architecture Patterns

### Person-Centric Design

NPC uses **Person Account** as the single record for an individual across programs, donations, grants, and volunteer activity. Avoid Contact-centric patterns when designing for NPC.

### Household Management

Households are **Party Relationship Groups** of type "Household." Members connect via account-contact relationships. Supports split, merge, and multiple group membership.

### GAU and Gift Attribution

General Accounting Units (GAU) drive gift attribution and reporting. Design allocation rules early when extending fundraising.

### Program Enrollment Flow

Program → Program Enrollment → Service Delivery / Case. Enrollments track participation; outcomes link to programs for impact reporting.

---

## Decision Trees

### Person Account vs Contact

- **Person Account**: New NPC orgs, individual constituents, unified donor/volunteer/client view
- **Contact**: B2B-style orgs, organizations as primary, or when Person Accounts cannot be enabled

### NPC vs NPSP for New Orgs

- **Nonprofit Cloud**: Default for new implementations
- **NPSP**: Only when AppExchange dependencies or constraints require it

### Custom vs Standard

Prefer standard NPC objects (Gift, Program Enrollment, Grant Application) over custom builds. Extend with custom fields and objects only when standard cannot meet requirements.

---

## NPSP-to-NPC Migration (Summary)

1. **Pre-migration**: Enable Person Accounts, clean data, map fields (no 1:1 assumption)
2. **Migration**: Move data and metadata; preserve relationships
3. **Post-migration**: Validate, update reports, verify AppExchange compatibility

See [references/migration-checklist.md](references/migration-checklist.md) for full checklist.

---

## Validation & Scoring

Score designs against:

```
Score: XX/100
├─ Data Model Alignment: XX/25   (Person-centric, Household, correct objects)
├─ Module Fit: XX/20             (Fundraising, Grantmaking, Program, etc.)
├─ Migration Safety: XX/20       (NPSP→NPC mapping, no legacy anti-patterns)
├─ Integration: XX/15           (Data Cloud, Experience Cloud, Outcome Mgmt)
├─ Scalability & Reporting: XX/10 (GAU, rollups, governor limits)
└─ Best Practices: XX/10         (Power of Us, security, naming)
```

---

## Anti-Patterns

- Using Contact-centric design when Person Accounts are appropriate
- Assuming 1:1 NPSP-to-NPC field mapping
- Skipping Person Account enablement before migration
- Mixing NPSP and NPC patterns in the same org
- Building custom objects when standard NPC objects suffice

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Custom objects/fields for nonprofit extensions | sf-metadata |
| Triggers, services, batch jobs for nonprofit logic | sf-apex |
| Gift processing, enrollment, grant automations | sf-flow |
| Test data (Person Accounts, Gifts, Enrollments) | sf-data |
| Deploy nonprofit metadata | sf-deploy |
| SOQL for nonprofit objects | sf-soql |

---

## Terminology

- **Nonprofit Cloud** / **NPC** — Current platform
- **NPSP** — Nonprofit Success Pack (legacy)
- **Person Account** — Individual constituent record
- **Household** — Party Relationship Group of type Household
- **Constituent** — Donor, volunteer, client, stakeholder
- **Gift** — Donation transaction in NPC
- **Program Enrollment** — Participation in a program
