# Application Pipeline Reference

## Application Lifecycle

Stages are configured via **Application Stage Definition** records, which control the workflow progression.

```
        ┌─────────────────────────┐
        │  Funding Opportunity    │  (Published by grantmaker)
        └───────────┬─────────────┘
                    ↓
                ┌───────────────┐
                │  Draft        │  (Applicant working on submission)
                └───────┬───────┘
                        ↓
                ┌───────────────┐
                │  Submitted    │  (Application received by grantmaker)
                └───────┬───────┘
                        ↓
                ┌───────────────┐
                │  Screening    │  (Eligibility check)
                └──┬─────────┬──┘
                   ↓         ↓
          ┌──────────┐  ┌────────────────────┐
          │ Ineligible│  │  In Review         │  (Application Review)
          └──────────┘  └───────┬────────────┘
                                ↓
                        ┌───────────────┐
                        │  Scored       │  (All Application Reviews complete)
                        └───────┬───────┘
                                ↓
                        ┌───────────────┐
                        │  Committee    │  (Decision meeting)
                        └──┬─────────┬──┘
                           ↓         ↓
                  ┌──────────┐  ┌───────────┐
                  │ Declined │  │  Approved  │
                  └────┬─────┘  └─────┬─────┘
                       ↓              ↓
              ┌────────────────┐  ┌───────────────────┐
              │ Application    │  │ Application       │
              │ Decision       │  │ Decision          │
              │ (Decline)      │  │ (Award)           │
              └────────────────┘  └─────┬─────────────┘
                                        ↓
                                ┌───────────────────┐
                                │ Funding Award     │
                                │ Created           │
                                └───────────────────┘
```

---

## Staged Application (LOI Model)

Applicants respond to a published **Funding Opportunity**. Application Stage Definitions configure the workflow stages below.

### Stage 1: Letter of Intent

Lightweight expression of interest to reduce applicant burden.

| Field | Required | Purpose |
|-------|----------|---------|
| Organization Name | Yes | Identify applicant |
| Mission Statement | Yes | Alignment check |
| Project Summary | Yes | Brief description (500 words) |
| Requested Amount | Yes | Budget range |
| Geographic Focus | Yes | Service area |
| Contact Info | Yes | Primary contact |

### Stage 2: Invited Full Application

Invited applicants submit detailed proposal.

| Section | Content |
|---------|---------|
| Project Narrative | Goals, activities, timeline, staffing |
| Budget | Line-item budget with justification |
| Outcomes | Expected results with measurement plan |
| Organizational Capacity | Staff qualifications, prior experience |
| Financials | Annual budget, audit, 990 |
| Board List | Names, affiliations, demographics |
| Letters of Support | Partner/community endorsements |

---

## Eligibility Screening

### Auto-Screen Criteria (Flow-Based)

| Criterion | Logic | Outcome |
|-----------|-------|---------|
| Organization type | 501(c)(3) status verified | Pass/Fail |
| Geographic eligibility | Service area within funded region | Pass/Fail |
| Budget range | Requested amount within program range | Pass/Fail |
| Prior grantee standing | No outstanding compliance issues | Pass/Flag |
| Application completeness | All required fields populated | Pass/Incomplete |

### Manual Screen Criteria

| Criterion | Reviewer Action |
|-----------|----------------|
| Mission alignment | Read narrative, assess fit |
| Capacity assessment | Review org history and staff |
| Duplication check | Ensure not duplicate of existing grant |

---

## Application Review Assignment

### Assignment Algorithm

1. Pull reviewer pool for funding program
2. Filter by expertise match (tags on reviewer profile vs Application topics)
3. Exclude conflicts of interest:
   - Reviewer is board member of applicant org
   - Reviewer has personal relationship (self-declared)
   - Reviewer has financial interest
4. Assign minimum 2 Application Reviews per Application
5. Balance workload across reviewer pool
6. Notify reviewers with deadline

### Conflict of Interest Check

| Check | Method |
|-------|--------|
| Organizational | Match reviewer Account affiliations to applicant Account |
| Self-declared | Reviewer confirms no conflict before accessing application |
| Historical | Check if reviewer previously employed by or consulted for applicant |

---

## Scoring Implementation

### Application Review Record Fields

| Field | Type | Purpose |
|-------|------|---------|
| Application | Lookup | Application being reviewed |
| Reviewer | Lookup(User) | Assigned reviewer |
| Mission Score | Number(1-5) | Mission alignment rating |
| Capacity Score | Number(1-5) | Organizational capacity rating |
| Design Score | Number(1-5) | Project design rating |
| Budget Score | Number(1-5) | Budget reasonableness rating |
| Outcome Score | Number(1-5) | Measurable outcomes rating |
| Overall Score | Formula | Weighted average |
| Recommendation | Picklist | Fund, Fund with Conditions, Decline |
| Comments | Long Text | Qualitative feedback |
| Conflict Check | Checkbox | Reviewer confirmed no conflict |

### Score Aggregation

After all Application Reviews complete:

1. Calculate average score per criterion across reviewers
2. Calculate overall weighted score
3. Flag applications with high reviewer variance (>2 point spread)
4. Rank applications by overall score
5. Present ranked list to decision committee

---

## Decision Workflow

### Committee Decision

1. Present ranked applications with scores and Application Review comments
2. Committee discusses borderline cases
3. Create **Application Decision** record: Approved, Declined, Deferred, Approved with Conditions
4. For approvals: set award amount (may differ from requested)
5. Document rationale in Application Decision record (decider, rationale)
6. Generate notification letters (award/decline)

### Notification Templates

| Decision | Notification Content |
|----------|---------------------|
| Approved | Award amount, terms, next steps, agreement timeline |
| Approved with Conditions | Conditions to meet, revised timeline |
| Declined | Reason (general), encouragement to reapply if applicable |
| Deferred | Timeline for reconsideration, any additional info needed |

---

## Deadline Management

### Application Deadline

- Flow auto-updates application status to "Late" after deadline
- Option: grace period (configurable hours/days)
- Option: hard close (no submissions after deadline)
- Reminder notifications: 2 weeks, 1 week, 2 days before deadline

### Application Review Deadline

- Notify reviewers at Application Review assignment
- Reminder at 50% and 75% of review period
- Escalate incomplete Application Reviews to grants manager at deadline
- Option: reassign if reviewer unresponsive
