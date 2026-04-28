# Outbound Funds Module (OFM) Reference

## Overview

Outbound Funds Module is a **separate managed package** (`outfunds__` namespace) that provides grant management capabilities for NPSP orgs. It is designed for organizations that distribute funds to other entities (grantmaking).

**Install**: Available on AppExchange as "Outbound Funds Module" by Salesforce.org.

---

## OFM Data Model

### Funding Program

Top-level container for a funding initiative.

```
outfunds__Funding_Program__c
├── Name = "Community Health Grants 2024"
├── outfunds__Status__c = "In Progress"
├── outfunds__Description__c = "..."
├── outfunds__Total_Program_Amount__c = 500000
├── outfunds__Start_Date__c = 2024-01-01
└── outfunds__End_Date__c = 2024-12-31
```

### Funding Request

Grant application from an organization or individual.

```
outfunds__Funding_Request__c
├── Name = "FR-2024-0042"
├── outfunds__Applying_Organization__c = Account (grantee org)
├── outfunds__Applying_Contact__c = Contact (applicant)
├── outfunds__FundingProgram__c = Funding Program
├── outfunds__Status__c = "In Progress"
├── outfunds__Requested_Amount__c = 25000
├── outfunds__Awarded_Amount__c = null
├── outfunds__Requested_For__c = "Youth mentoring expansion"
├── outfunds__Application_Date__c = 2024-02-15
├── outfunds__Close_Date__c = 2024-06-30
└── outfunds__Geo_Area_Served__c = "Northeast Region"
```

### Funding Request Role

Links additional Contacts to a Funding Request (reviewers, co-applicants).

```
outfunds__Funding_Request_Role__c
├── outfunds__Funding_Request__c = Funding Request
├── outfunds__Contact__c = Contact
└── outfunds__Role__c = "Reviewer"
```

### Funding Request as Award (Dual-Purpose)

OFM does **not** have a separate Funding Award object. When a Funding Request is approved, its status changes to "Awarded" and the award fields are populated on the same record:

- `outfunds__Status__c` → "Awarded"
- `outfunds__Awarded_Amount__c` = approved amount
- The Funding Request continues to serve as the parent record for Disbursements, Requirements, and Reviews

### Review

Reviewer comments and recommendations on a Funding Request.

```
outfunds__Review__c
├── outfunds__FundingRequest__c = Funding Request
├── outfunds__Status__c = "Submitted"
├── outfunds__Review_Comments__c = "Strong proposal with clear outcomes..."
└── outfunds__Reviewer__c = User
```

### Disbursement

Payment made against a Funding Request (after award).

```
outfunds__Disbursement__c
├── outfunds__Funding_Request__c = Funding Request
├── outfunds__Amount__c = 10000
├── outfunds__Scheduled_Date__c = 2024-05-15
├── outfunds__Disbursement_Date__c = 2024-05-15
├── outfunds__Status__c = "Paid"
├── outfunds__Disbursement_Method__c = "Check"
└── outfunds__Type__c = "Initial"
```

### Requirement

Compliance deliverables tied to a Funding Request.

```
outfunds__Requirement__c
├── outfunds__Funding_Request__c = Funding Request
├── outfunds__Type__c = "Report"
├── outfunds__Status__c = "Open"
├── outfunds__Due_Date__c = 2024-09-30
├── outfunds__Requirements_Name__c = "Mid-Year Progress Report"
└── outfunds__Completed_Date__c = null
```

---

## OFM Lifecycle

### Grantmaker Workflow

```
1. Create Funding Program (set budget, dates, criteria)
2. Receive Funding Requests (applications)
3. Assign reviewers (Funding Request Roles)
4. Collect Reviews (outfunds__Review__c — reviewer comments/recommendations)
5. Award decision → Update Funding Request status to "Awarded", populate outfunds__Awarded_Amount__c
6. Set Requirements (reports, audits, deliverables)
7. Schedule Disbursements against the awarded Funding Request (single, milestone, periodic)
8. Track Requirement completion
9. Process Disbursements (mark as Paid)
10. Closeout (final reporting, reconciliation)
```

### Funding Request Status Values

| Status | Meaning |
|--------|---------|
| In Progress | Application being prepared |
| Submitted | Application submitted by grantee |
| In Review | Under review by grantmaker |
| Awarded | Approved for funding |
| Rejected | Not approved |
| Withdrawn | Applicant withdrew |

### Disbursement Status Values

| Status | Meaning |
|--------|---------|
| Scheduled | Payment planned |
| Approved | Approved for release |
| Paid | Payment completed |
| Cancelled | Payment cancelled |

---

## OFM Architecture Patterns

### Budget Tracking

OFM does not have a dedicated Budget object. Track budget at the Funding Program level:

- `outfunds__Total_Program_Amount__c` = total budget
- Rollup awarded Funding Requests (`outfunds__Awarded_Amount__c`) to calculate committed funds
- Rollup Disbursements to calculate spent funds
- Available = Total - Committed (or Total - Spent, depending on reporting needs)

For detailed line-item budgets, use custom objects or extend Requirement with budget categories.

### Multi-Year Grants

Use Funding Request award dates for the grant period. Create Disbursements for each year's payments. Use Requirements for annual reports.

```
Funding Request — Status: "Awarded" (3-year grant, $60K)
├── Disbursement: Year 1 ($20K, May 2024)
├── Requirement: Year 1 Report (due March 2025)
├── Disbursement: Year 2 ($20K, May 2025)
├── Requirement: Year 2 Report (due March 2026)
├── Disbursement: Year 3 ($20K, May 2026)
└── Requirement: Final Report (due March 2027)
```

### Dual-Role Organizations

Orgs that are both grantmakers and grantees:

- **As grantmaker**: Use OFM objects (Funding Requests received/awarded, Disbursements sent)
- **As grantee**: Use Opportunity with Record Type = "Grant" (grants received as revenue)
- Keep these separate — different objects serve different purposes

### Grantee Portal

Use Experience Cloud to give grantees access to:

- Submit Funding Requests
- Upload documents (attach to Requirement)
- Check application status
- View awarded Funding Request details and Disbursement schedule
- Submit Requirement deliverables

Sharing: Use sharing sets mapping the grantee Contact to Funding Request and related records.

---

## OFM with NPSP Integration Points

| Integration | Pattern |
|-------------|---------|
| Grantee as Contact/Account | Funding Request → Applying Organization (Account) + Applying Contact |
| Grant as revenue | When org *receives* a grant, track as Opportunity (Record Type = Grant) |
| Campaign linkage | Link Funding Program to Campaign for outreach tracking |
| Reporting | Cross-object reports: Funding Programs + Requests + Disbursements + Reviews |
| Donor-funded grants | Donor Opportunity → GAU Allocation → Funding Program budget |

---

## OFM Object Relationship Summary

```
outfunds__Funding_Program__c
└── outfunds__Funding_Request__c (dual-purpose: application + award)
    ├── outfunds__Funding_Request_Role__c → Contact
    ├── outfunds__Review__c (reviewer comments/recommendations)
    ├── outfunds__Requirement__c (compliance deliverables)
    └── outfunds__Disbursement__c (payments — after award)
```

---

## OFM Customization

### Common Extensions

| Need | Approach |
|------|----------|
| Scoring rubric | Custom object related to Funding Request, or custom fields on Funding Request Role |
| Budget line items | Custom object related to Funding Request (Category, Amount, Narrative) |
| Match/leverage tracking | Custom fields on Funding Request (Other Funding Sources, Match Amount) |
| Geographic targeting | Use outfunds__Geo_Area_Served__c + custom picklists for regions |
| Letter generation | Flow + Email Template or Document Generation (Conga, Formstack) |

### Automation Opportunities

| Trigger | Action |
|---------|--------|
| Funding Request submitted | Notify review team, create tasks |
| All Requirements completed | Auto-advance Funding Request status |
| Disbursement scheduled date reached | Alert finance team |
| Funding Request status → Closed | Trigger final reporting Requirement |
| Funding Program budget exceeded | Validation rule or Flow alert |
