---
name: sf-nonprofit-fundraising
description: >
  Nonprofit Cloud (NPC) fundraising architecture with 120-point scoring.
  TRIGGER when: user designs donor management, gift entry, campaigns, soft
  credits, Gift Designation allocations, recurring giving, or payment processing
  on Nonprofit Cloud using Gift Transaction/Person Account model. Also triggers
  when user asks to "set up recurring gifts", "monthly giving program",
  "track donations", or "enter a gift". DO NOT TRIGGER
  when: NPSP Opportunity-based donations (use sf-nonprofit-npsp), generic
  Apex/LWC (use sf-apex, sf-lwc), grant management (use sf-nonprofit-grants),
  program management (use sf-nonprofit-program-case), or non-nonprofit
  Salesforce work.
license: MIT
metadata:
  version: "2.0.0"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.npc_fundraising.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud_object_reference.meta/nonprofit_cloud_object_reference/gift_transaction.htm
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

# sf-nonprofit-fundraising: Nonprofit Cloud Fundraising Architect

Expert Salesforce architect specializing in **Nonprofit Cloud (NPC)** fundraising: donor lifecycle management, gift processing, campaign attribution, recurring giving, Gift Soft Credits, and fundraising analytics.

> **Platform note**: This skill covers the NPC Gift Transaction/Person Account model. For NPSP Opportunity/Contact-based donation management, see **sf-nonprofit-npsp**.

## Core Responsibilities

1. **Gift Transaction Architecture**: Design gift entry, processing, and attribution flows
2. **Donor Management**: Person Account-based donor records, engagement scoring, stewardship
3. **Campaign Strategy**: Campaign hierarchies, attribution models, ROI tracking
4. **Recurring Giving**: Payment schedules, retry logic, donor retention
5. **Gift Designation & Allocations**: Fund accounting, split allocations, reporting alignment
6. **Validation & Scoring**: Score designs against 6 categories (0-120 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Gift processing** | [references/gift-processing.md](references/gift-processing.md) | Gift entry flows, payment methods, batch processing |
| **Donor lifecycle** | [references/donor-lifecycle.md](references/donor-lifecycle.md) | Engagement scoring, stewardship, retention strategies |

---

## Key Data Model

| Object | API Name | Purpose | Key Fields |
|--------|----------|---------|------------|
| **Gift Transaction** | GiftTransaction | Donation transaction (replaces Opportunity) | Amount, ReceivedDate, PaymentMethod, Status |
| **Payment Instrument** | PaymentInstrument | Reusable payment method storage (card tokens, bank accounts) | Type, Last4, ExpirationDate, PersonAccount |
| **Campaign** | Campaign | Outreach initiative | Name, Type, Status, Expected Revenue, ROI |
| **Gift Soft Credit** | GiftSoftCredit | Attribution to additional constituents | Person Account, Gift Transaction, Role, Amount |
| **Gift Designation** | GiftDesignation | Named fund for tracking (replaces GAU) | Name, Active, Description |
| **Gift Transaction Designation** | GiftTransactionDesignation | Links Gift Transaction to Gift Designation with amount/percentage | GiftTransaction, GiftDesignation, Amount, Percentage |
| **Gift Commitment** | GiftCommitment | Recurring giving pledge | Amount, Frequency, Start Date, Status |
| **Gift Commitment Schedule** | GiftCommitmentSchedule | Payment schedule for commitments | Amount, Frequency, Day of Month |
| **Gift Tribute** | GiftTribute | Honor/memorial gift tracking | TributeType, Honoree, Message |
| **Gift Refund** | GiftRefund | Refund tracking (separate from Gift Transaction status) | Amount, RefundDate, Reason |
| **Gift Default Designation** | GiftDefaultDesignation | Org-wide or campaign-level default fund allocation | GiftDesignation, Campaign |
| **Gift Default Soft Credit** | GiftDefaultSoftCredit | Automatic soft credit rule configuration | Role, Person Account |
| **Donor Gift Summary** | DonorGiftSummary | Rollup object for aggregated donor giving metrics | TotalGiving, LastGiftDate, GiftCount |
| **Outreach Source Code** | OutreachSourceCode | NPC attribution mechanism (message × channel × audience) | Name, Channel, Audience, Message |

---

## Architecture Patterns

### Gift Entry Flow

```
Donor → Gift Entry UI → Gift Transaction (Unpaid)
  → Payment processing → Gift Transaction (Paid)
  → Gift Transaction Designation (auto or manual)
  → Gift Soft Credit (if applicable)
  → Acknowledgment / Receipt
```

### Gift Attribution

Gift Transactions connect to donors via Person Account. Use **Gift Soft Credits** for secondary attribution (board member who secured donation, spouse, matching gift contact). Gift Transaction Designations drive fund-level reporting.

### Recurring Giving

Gift Commitment → Gift Commitment Schedule → auto-generated Gift Transactions per schedule. Design retry logic for failed payments. Track donor retention via commitment status changes.

### Campaign Attribution

Campaigns support hierarchy (parent-child). Use Campaign Member for donor-campaign association. Primary Campaign Source on Gift Transaction drives first-touch attribution. Campaign Influence enables multi-touch.

---

## Decision Trees

### Gift Transaction vs Opportunity

- **Gift Transaction**: Nonprofit Cloud fundraising (default for NPC orgs)
- **Opportunity**: Only when legacy NPSP patterns or Sales Cloud overlap require it

### Gift Designation Strategy

- **Auto-allocate**: Gift Default Designation on gift entry; simplest for single-fund orgs
- **Manual allocate**: Multi-fund orgs with complex attribution via Gift Transaction Designation
- **Split allocate**: Percentage or amount-based splits across multiple Gift Designations

### Payment Processing

Payment data lives on the Gift Transaction itself (no separate Payment object). Payment Instrument stores reusable payment methods (card tokens, bank accounts) for recurring and repeat donors.

- **Elevate (Salesforce Payments)**: Native integration, PCI compliant
- **Third-party gateway**: Stripe, PayPal — requires Named Credential + External Service
- **Offline payments**: Check, cash, in-kind — manual entry, no gateway

---

## Gift Entry Best Practices

1. **Batch Gift Entry**: Use for high-volume processing (events, mail campaigns)
2. **Single Gift Entry**: Standard form for individual donations
3. **Online Giving**: Experience Cloud forms with payment gateway integration
4. **Matching Gifts**: Link employer match to original gift via Gift Soft Credit or related Gift Transaction
5. **In-Kind Gifts**: Track with Gift Type = "In-Kind"; separate fair market value field

---

## Donor Engagement Patterns

| Strategy | Implementation |
|----------|---------------|
| **LYBUNT** (Last Year But Unfortunately Not This year) | SOQL: Gift Transactions last year, none this year |
| **SYBUNT** (Some Year But Unfortunately Not This year) | SOQL: any prior Gift Transaction, none this year |
| **Upgrade candidates** | Donors with 2+ consecutive years, increasing amounts |
| **At-risk** | Declining gift frequency or amount trend |
| **Major donor threshold** | Configurable cumulative or single-gift threshold |

---

## Validation & Scoring

```
Score: XX/120
├─ Gift Processing: XX/25       (Entry, validation, status lifecycle)
├─ Donor Model: XX/20           (Person Account, Household, engagement)
├─ Campaign & Attribution: XX/20 (Hierarchy, Gift Soft Credit, ROI)
├─ Recurring Giving: XX/20      (Schedules, retry, retention)
├─ Gift Designation & Reporting: XX/20 (Allocations, fund tracking, analytics)
└─ Best Practices: XX/15        (Security, acknowledgments, compliance)
```

---

## NPC vs NPSP Fundraising Quick Reference

| Concept | NPC (this skill) | NPSP (sf-nonprofit-npsp) |
|---------|-------------------|--------------------------|
| **Donation record** | Gift Transaction | Opportunity |
| **Donor record** | Person Account | Contact + Household Account |
| **Recurring** | Gift Commitment + Schedule | Recurring Donation (npe03__) |
| **Soft credit** | Gift Soft Credit | Partial Soft Credit + Opp Contact Role |
| **Payment** | Payment data on Gift Transaction + Payment Instrument | Payment (npe01__OppPayment__c) |
| **Batch entry** | Gift Entry UI | NPSP Data Import Batch |
| **Fund tracking** | Gift Designation + Gift Transaction Designation | GAU Allocation (npsp__) |

If the org uses Opportunity for donations and has `npsp__` namespace fields, route to **sf-nonprofit-npsp** instead.

---

## Anti-Patterns

- Using Opportunity instead of Gift Transaction in NPC orgs
- Hardcoding Gift Transaction Designations instead of configurable rules or Gift Default Designations
- Skipping Gift Soft Credits for attribution (breaks reporting)
- No retry logic for failed recurring payments
- Mixing NPSP donation patterns with NPC Gift Transaction model
- Building custom donation objects when Gift Transaction suffices

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Gift Transaction processing automations (flows) | sf-flow |
| Apex triggers for Gift Transaction validation | sf-apex |
| Donor portal / online giving | sf-nonprofit-experience-cloud |
| Portal UX for donation forms | sf-nonprofit-experience-cloud-ux |
| Grant-funded program donations | sf-nonprofit-grants |
| Custom objects for fundraising extensions | sf-metadata |
| NPSP donation management (if NPSP org) | sf-nonprofit-npsp |
| Deploy fundraising metadata | sf-deploy |
| SOQL for donor analytics | sf-soql |
| Test data for Gift Transaction scenarios | sf-data |

---

## Terminology

- **Gift Transaction** — Donation transaction in NPC (replaces Opportunity)
- **Payment Instrument** — Reusable payment method (card tokens, bank accounts); payment data lives on Gift Transaction itself
- **Gift Designation** — Named fund for tracking (replaces GAU)
- **Gift Transaction Designation** — Links a Gift Transaction to a Gift Designation with amount/percentage
- **Gift Soft Credit** — Secondary gift attribution to additional constituents
- **Gift Commitment** — Recurring giving pledge
- **Gift Tribute** — Honor/memorial gift tracking
- **Gift Refund** — Refund tracking (separate object, not a Gift Transaction status)
- **Gift Default Designation** — Org-wide or campaign-level default fund allocation
- **Gift Default Soft Credit** — Automatic soft credit rule configuration
- **Donor Gift Summary** — Rollup object for aggregated donor giving metrics
- **Outreach Source Code** — NPC attribution mechanism (message × channel × audience)
- **LYBUNT** — Last Year But Unfortunately Not This year
- **SYBUNT** — Some Year But Unfortunately Not This year
- **Elevate** — Salesforce native payment processing platform
