# Funding Disbursement & Compliance Reference

## Funding Disbursement Lifecycle

```
Scheduled → Pending Approval → Approved → Processed → Paid
                                  ↓
                              On Hold (Funding Award Requirement issue)
```

---

## Funding Disbursement Schedule Patterns

### Lump Sum

```
Funding Award ($50,000)
└── Funding Disbursement: $50,000 (at agreement execution)
```

### Quarterly Scheduled

```
Funding Award ($100,000, 12-month grant)
├── Q1 Funding Disbursement: $25,000 (Month 1)
├── Q2 Funding Disbursement: $25,000 (Month 4)
├── Q3 Funding Disbursement: $25,000 (Month 7)
└── Q4 Funding Disbursement: $25,000 (Month 10)
```

### Milestone-Based

```
Funding Award ($75,000)
├── Milestone 1: $25,000 (Project plan approved)
├── Milestone 2: $25,000 (Mid-term report accepted)
└── Milestone 3: $25,000 (Final report accepted)
```

### Reimbursement

```
Funding Award ($40,000)
├── Reimbursement 1: $12,500 (Q1 expenses submitted)
├── Reimbursement 2: $8,750 (Q2 expenses submitted)
├── Reimbursement 3: $11,200 (Q3 expenses submitted)
└── Reimbursement 4: $7,550 (Q4 expenses submitted)
     Total reimbursed: $40,000 (capped at award)
```

---

## Budget Tracking

### Budget Categories

| Category | Example Line Items |
|----------|-------------------|
| Personnel | Salaries, benefits, consultants |
| Travel | Staff travel, participant transportation |
| Equipment | Technology, furniture, supplies |
| Contractual | Subcontracts, professional services |
| Other Direct | Printing, postage, communications |
| Indirect | Overhead rate (negotiated or de minimis) |

### Budget vs Actual Tracking

| Field | Type | Purpose |
|-------|------|---------|
| Category | Picklist | Budget line item category |
| Budgeted Amount | Currency | Originally approved amount |
| Amended Amount | Currency | After budget modification |
| Spent to Date | Currency | Expenses recorded |
| Remaining | Formula | Amended - Spent |
| Variance | Formula | (Spent / Amended) as percentage |

### Budget Modification Rules

- Minor reallocations (<10% between categories): grantee notification only
- Significant reallocations (10-25%): written approval required
- Major changes (>25% or new categories): formal **Funding Award Amendment** required
- Track all modifications with date, reason, and approver via Funding Award Amendment records

---

## Compliance Tracking

### Compliance Checklist

| Funding Award Requirement | Frequency | Auto-Track |
|---------------------------|-----------|------------|
| Progress report submission | Per schedule (quarterly/semi-annual) | Due date + reminder Flow |
| Financial report submission | Per schedule | Due date + reminder Flow |
| Audit submission | Annual (if >$750K federal) | Annual reminder |
| Insurance verification | Annual | Expiration date tracking |
| Board resolution | At award | One-time checklist item |
| Signed agreement | At award | One-time checklist item |
| Final report | At closeout | Closeout checklist |
| Expenditure documentation | Ongoing | Spot-check schedule |

### Compliance Status

| Status | Meaning | Action |
|--------|---------|--------|
| Compliant | All Funding Award Requirements current | Continue Funding Disbursements |
| Warning | Funding Award Requirement overdue <30 days | Send reminder, flag for review |
| Non-Compliant | Funding Award Requirement overdue >30 days or issue identified | Hold Funding Disbursements, require response |
| Remediation | Corrective action plan in progress | Monitor monthly |
| Resolved | Issue addressed, returned to compliance | Resume normal schedule |

---

## Funding Award Requirements (Grantee Reporting)

Each reporting obligation is tracked as a **Funding Award Requirement** record. Sub-items within a requirement are tracked as **Funding Award Requirement Section** records.

### Progress Report (Funding Award Requirement)

| Funding Award Requirement Section | Content |
|-----------------------------------|---------|
| Summary | Overall progress toward goals |
| Activities | Key activities completed this period |
| Outcomes | Progress on measurable outcomes |
| Challenges | Barriers encountered and mitigation |
| Participants | Number served, demographics |
| Modifications | Any changes to project plan |
| Next Steps | Plans for upcoming period |

### Financial Report (Funding Award Requirement)

| Funding Award Requirement Section | Content |
|-----------------------------------|---------|
| Budget vs Actual | Line-item comparison |
| Expenditure Detail | Transaction-level for sampled categories |
| Modifications | Budget reallocations made |
| Projections | Expected spending for remaining period |
| Match/Leverage | Other funding secured (if required) |

---

## Grant Closeout

### Closeout Checklist

1. Final progress Funding Award Requirement received and reviewed
2. Final financial Funding Award Requirement received and reconciled
3. Unexpended funds returned or reallocated (per agreement)
4. All deliverables received (publications, data sets, etc.)
5. Equipment disposition documented (if applicable)
6. Final Funding Disbursement processed
7. Grant record status → Closed
8. Outcome data captured for portfolio reporting
9. Grantee relationship record updated

### Closeout Timeline

| Milestone | Deadline |
|-----------|----------|
| Final report due | 30-90 days after grant end |
| Grantmaker review | 30 days after receipt |
| Fund return (if any) | 60 days after grant end |
| Record closure | After all items complete |

---

## Funder Relationship Management

### Funder Record (Business Account)

Track grantmakers/funders as Business Accounts with:

- Funding priorities and focus areas
- Application deadlines and cycles
- Historical awards (Funding Awards linked to Account)
- Relationship contacts
- Reporting requirements and preferences

### Funding Pipeline

Track prospective grants through stages:

| Stage | Probability | Actions |
|-------|-------------|---------|
| Researching | 10% | Identify alignment, review guidelines |
| Cultivating | 25% | Build relationship, attend events |
| LOI Submitted | 40% | LOI sent, awaiting invitation |
| Application Submitted | 60% | Full application sent |
| Under Review | 75% | Application in review process |
| Awarded | 100% | Grant approved |
| Declined | 0% | Document reason, plan next steps |
