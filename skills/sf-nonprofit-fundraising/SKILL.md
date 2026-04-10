---
name: sf-nonprofit-fundraising
description: >
  Nonprofit fundraising architecture with 120-point scoring. TRIGGER when: user
  designs donor management, gift entry, campaigns, soft credits, GAU allocations,
  recurring giving, payment processing, or donor engagement strategies on
  Nonprofit Cloud. DO NOT TRIGGER when: generic Apex/LWC code (use sf-apex,
  sf-lwc), grant management (use sf-nonprofit-grants), program management
  (use sf-nonprofit-program-case), or non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "120 points across 6 categories"
---

# sf-nonprofit-fundraising: Nonprofit Fundraising Architect

Expert Salesforce architect specializing in Nonprofit Cloud fundraising: donor lifecycle management, gift processing, campaign attribution, recurring giving, soft credits, and fundraising analytics.

## Core Responsibilities

1. **Gift Architecture**: Design gift entry, processing, and attribution flows
2. **Donor Management**: Person Account-based donor records, engagement scoring, stewardship
3. **Campaign Strategy**: Campaign hierarchies, attribution models, ROI tracking
4. **Recurring Giving**: Payment schedules, retry logic, donor retention
5. **GAU & Allocations**: Fund accounting, split allocations, reporting alignment
6. **Validation & Scoring**: Score designs against 6 categories (0-120 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Gift processing** | [references/gift-processing.md](references/gift-processing.md) | Gift entry flows, payment methods, batch processing |
| **Donor lifecycle** | [references/donor-lifecycle.md](references/donor-lifecycle.md) | Engagement scoring, stewardship, retention strategies |

---

## Key Data Model

| Object | Purpose | Key Fields |
|--------|---------|------------|
| **Gift** | Donation transaction (replaces Opportunity) | Amount, Gift Date, Payment Method, Status |
| **Payment** | Individual payment against a Gift | Amount, Payment Date, Status, Payment Method |
| **Campaign** | Outreach initiative | Name, Type, Status, Expected Revenue, ROI |
| **Soft Credit** | Attribution to additional constituents | Person Account, Gift, Role, Amount |
| **GAU** | General Accounting Unit for fund tracking | Name, Active, Description |
| **GAU Allocation** | Links Gift to GAU with amount/percentage | Gift, GAU, Amount, Percentage |
| **Gift Commitment** | Recurring giving pledge | Amount, Frequency, Start Date, Status |
| **Gift Commitment Schedule** | Payment schedule for commitments | Amount, Frequency, Day of Month |

---

## Architecture Patterns

### Gift Entry Flow

```
Donor → Gift Entry UI → Gift (Draft)
  → Payment Authorization → Payment (Pending)
  → GAU Allocation (auto or manual)
  → Soft Credit (if applicable)
  → Gift Status → Completed
  → Acknowledgment / Receipt
```

### Gift Attribution

Gifts connect to donors via Person Account. Use **Soft Credits** for secondary attribution (board member who secured donation, spouse, matching gift contact). GAU Allocations drive fund-level reporting.

### Recurring Giving

Gift Commitment → Gift Commitment Schedule → auto-generated Gifts + Payments per schedule. Design retry logic for failed payments. Track donor retention via commitment status changes.

### Campaign Attribution

Campaigns support hierarchy (parent-child). Use Campaign Member for donor-campaign association. Primary Campaign Source on Gift drives first-touch attribution. Campaign Influence enables multi-touch.

---

## Decision Trees

### Gift vs Opportunity

- **Gift**: Nonprofit Cloud fundraising (default for NPC orgs)
- **Opportunity**: Only when legacy NPSP patterns or Sales Cloud overlap require it

### GAU Allocation Strategy

- **Auto-allocate**: Default GAU on gift entry; simplest for single-fund orgs
- **Manual allocate**: Multi-fund orgs with complex attribution
- **Split allocate**: Percentage or amount-based splits across multiple GAUs

### Payment Processing

- **Elevate (Salesforce Payments)**: Native integration, PCI compliant
- **Third-party gateway**: Stripe, PayPal — requires Named Credential + External Service
- **Offline payments**: Check, cash, in-kind — manual entry, no gateway

---

## Gift Entry Best Practices

1. **Batch Gift Entry**: Use for high-volume processing (events, mail campaigns)
2. **Single Gift Entry**: Standard form for individual donations
3. **Online Giving**: Experience Cloud forms with payment gateway integration
4. **Matching Gifts**: Link employer match to original gift via Soft Credit or related Gift
5. **In-Kind Gifts**: Track with Gift Type = "In-Kind"; separate fair market value field

---

## Donor Engagement Patterns

| Strategy | Implementation |
|----------|---------------|
| **LYBUNT** (Last Year But Unfortunately Not This year) | SOQL: gifts last year, no gifts this year |
| **SYBUNT** (Some Year But Unfortunately Not This year) | SOQL: any prior gift, no gift this year |
| **Upgrade candidates** | Donors with 2+ consecutive years, increasing amounts |
| **At-risk** | Declining gift frequency or amount trend |
| **Major donor threshold** | Configurable cumulative or single-gift threshold |

---

## Validation & Scoring

```
Score: XX/120
├─ Gift Processing: XX/25       (Entry, validation, status lifecycle)
├─ Donor Model: XX/20           (Person Account, Household, engagement)
├─ Campaign & Attribution: XX/20 (Hierarchy, soft credit, ROI)
├─ Recurring Giving: XX/20      (Schedules, retry, retention)
├─ GAU & Reporting: XX/20       (Allocations, fund tracking, analytics)
└─ Best Practices: XX/15        (Security, acknowledgments, compliance)
```

---

## Anti-Patterns

- Using Opportunity instead of Gift in NPC orgs
- Hardcoding GAU allocations instead of configurable rules
- Skipping soft credits for attribution (breaks reporting)
- No retry logic for failed recurring payments
- Mixing NPSP donation patterns with NPC Gift model
- Building custom donation objects when Gift suffices

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Gift processing automations (flows) | sf-flow |
| Apex triggers for gift validation | sf-apex |
| Donor portal / online giving | sf-nonprofit-experience-cloud |
| Portal UX for donation forms | sf-nonprofit-experience-cloud-ux |
| Grant-funded program donations | sf-nonprofit-grants |
| Custom objects for fundraising extensions | sf-metadata |
| Deploy fundraising metadata | sf-deploy |
| SOQL for donor analytics | sf-soql |
| Test data for gift scenarios | sf-data |

---

## Terminology

- **Gift** — Donation transaction in NPC (replaces Opportunity)
- **Payment** — Individual payment against a Gift
- **GAU** — General Accounting Unit for fund attribution
- **Soft Credit** — Secondary gift attribution to additional constituents
- **Gift Commitment** — Recurring giving pledge
- **LYBUNT** — Last Year But Unfortunately Not This year
- **SYBUNT** — Some Year But Unfortunately Not This year
- **Elevate** — Salesforce native payment processing platform
