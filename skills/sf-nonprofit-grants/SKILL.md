---
name: sf-nonprofit-grants
description: >
  Nonprofit grant management architecture with 110-point scoring. TRIGGER when:
  user designs grant applications, review workflows, funding awards,
  disbursements, budgets, compliance tracking, funder reporting, or grantmaking
  pipelines on Nonprofit Cloud. DO NOT TRIGGER when: fundraising/donations
  (use sf-nonprofit-fundraising), program management (use sf-nonprofit-program-case),
  generic Apex/LWC code (use sf-apex, sf-lwc), or non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "110 points across 6 categories"
---

# sf-nonprofit-grants: Grant Management Architect

Expert Salesforce architect specializing in Nonprofit Cloud grantmaking: grant application pipelines, review workflows, funding awards, disbursement schedules, budget tracking, compliance, and funder reporting.

## Core Responsibilities

1. **Application Pipeline**: Design grant application intake, review, and decision workflows
2. **Review Process**: Scoring rubrics, reviewer assignment, conflict-of-interest checks
3. **Award Management**: Funding awards, terms, conditions, amendments
4. **Disbursement**: Payment schedules, milestone-based releases, financial tracking
5. **Compliance & Reporting**: Funder requirements, progress reports, audit readiness
6. **Validation & Scoring**: Score designs against 6 categories (0-110 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Application pipeline** | [references/application-pipeline.md](references/application-pipeline.md) | Application lifecycle, review workflows, decision patterns |
| **Disbursement & compliance** | [references/disbursement-compliance.md](references/disbursement-compliance.md) | Payment schedules, budget tracking, reporting |

---

## Key Data Model

| Object | Purpose | Key Fields |
|--------|---------|------------|
| **Grant Application** | Application from grantee | Applicant (Account), Program, Status, Requested Amount |
| **Funding Award** | Approved grant | Grant Application, Amount, Start/End Date, Status |
| **Disbursement** | Payment against award | Funding Award, Amount, Date, Status, Milestone |
| **Budget** | Grantee budget | Funding Award, Category, Budgeted Amount, Spent |
| **Grant Report** | Progress/financial report from grantee | Funding Award, Period, Status, Due Date |
| **Review** | Reviewer evaluation | Grant Application, Reviewer, Score, Recommendation |

---

## Architecture Patterns

### Grant Lifecycle (Grantmaker Perspective)

```
Funding Opportunity Published
  → Grant Application Received
  → Eligibility Screening
  → Review & Scoring
  → Decision (Award / Decline)
  → Funding Award Created
  → Agreement Executed
  → Disbursement(s) Released
  → Grantee Reporting
  → Grant Closeout
```

### Grant Lifecycle (Grantee Perspective)

```
Discover Opportunity
  → Submit Application
  → Respond to Review Questions
  → Receive Award Notification
  → Execute Agreement
  → Receive Disbursements
  → Submit Progress/Financial Reports
  → Grant Closeout
```

### Dual-Role Organizations

Some nonprofits are both grantmakers (funding others) and grantees (receiving grants). Design data model to support both directions:

- **As grantmaker**: Grant Applications received, Awards issued, Disbursements sent
- **As grantee**: Applications submitted, Awards received, Disbursements received
- Use a direction indicator or separate record types

---

## Decision Trees

### Application vs Opportunity

- **Grant Application**: NPC standard object for grant intake — use as default
- **Opportunity**: Only when grant tracking overlaps with Sales Cloud pipeline (rare)

### Review Model

- **Internal review**: Staff-only scoring and recommendation
- **Panel review**: Multiple reviewers with averaged/weighted scores
- **External review**: Peer reviewers with conflict-of-interest management
- **Hybrid**: Internal screening → external panel → internal decision

### Disbursement Schedule

- **Lump sum**: Single payment at award or milestone
- **Scheduled**: Fixed periodic payments (quarterly, semi-annual)
- **Milestone-based**: Payment tied to deliverable completion
- **Reimbursement**: Payment against documented expenses

---

## Application Pipeline Best Practices

1. **Staged application**: Letter of Intent (LOI) → invited full application (reduces applicant burden)
2. **Eligibility pre-check**: Auto-screen before full application (org type, geography, mission alignment)
3. **Budget template**: Standardized budget categories for consistent review
4. **Document upload**: Attach financials, board list, project narrative to application
5. **Deadline management**: Auto-close applications after deadline, grace period option
6. **Applicant portal**: Experience Cloud site for submission and status tracking

---

## Review Workflow

### Scoring Rubric Pattern

| Criterion | Weight | Score Range |
|-----------|--------|-------------|
| Mission Alignment | 25% | 1-5 |
| Organizational Capacity | 20% | 1-5 |
| Project Design | 25% | 1-5 |
| Budget Reasonableness | 15% | 1-5 |
| Measurable Outcomes | 15% | 1-5 |

### Reviewer Assignment

1. Match reviewers to applications (expertise, geography)
2. Check for conflicts of interest (org affiliation, personal relationship)
3. Assign minimum 2 reviewers per application
4. Set review deadline
5. Collect scores and comments
6. Calculate weighted average score
7. Flag outlier scores for discussion

---

## Validation & Scoring

```
Score: XX/110
├─ Application Pipeline: XX/20    (Intake, eligibility, deadline management)
├─ Review Process: XX/20          (Rubric, assignment, conflict checks)
├─ Award Management: XX/20       (Terms, amendments, status tracking)
├─ Disbursement: XX/20           (Schedules, milestones, reconciliation)
├─ Compliance & Reporting: XX/15 (Funder reports, audit trail, deadlines)
└─ Best Practices: XX/15         (Security, portal access, documentation)
```

---

## Anti-Patterns

- Using Opportunity for grant tracking in NPC orgs
- No review scoring rubric (subjective decisions without documentation)
- Disbursements without budget reconciliation
- Missing compliance deadlines (no automated reminders)
- Hardcoding grant terms instead of configurable award templates
- No audit trail on application status changes
- Mixing grantmaker and grantee records without clear separation

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Application and review automations | sf-flow |
| Apex logic for scoring engines | sf-apex |
| Applicant/grantee portal | sf-nonprofit-experience-cloud |
| Portal UX for application forms | sf-nonprofit-experience-cloud-ux |
| Grant-funded program tracking | sf-nonprofit-program-case |
| Grant revenue as fundraising | sf-nonprofit-fundraising |
| Custom objects for grant extensions | sf-metadata |
| Deploy grant metadata | sf-deploy |
| SOQL for grant reporting | sf-soql |
| Test data for grant scenarios | sf-data |

---

## Terminology

- **Grant Application** — Formal request for funding from a grantee
- **Funding Award** — Approved grant with terms and amount
- **Disbursement** — Payment release against a funding award
- **Budget** — Grantee's financial plan for awarded funds
- **LOI** — Letter of Intent (preliminary application)
- **Grantmaker** — Organization that awards grants
- **Grantee** — Organization that receives grants
- **Closeout** — Final reporting and reconciliation at grant end
