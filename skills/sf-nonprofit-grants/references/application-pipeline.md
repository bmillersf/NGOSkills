# Grant Application Pipeline Reference

## Application Lifecycle

```
                ┌───────────────┐
                │  Draft        │  (Applicant working on submission)
                └───────┬───────┘
                        ↓
                ┌───────────────┐
                │  Submitted    │  (Received by grantmaker)
                └───────┬───────┘
                        ↓
                ┌───────────────┐
                │  Screening    │  (Eligibility check)
                └──┬─────────┬──┘
                   ↓         ↓
          ┌──────────┐  ┌───────────────┐
          │ Ineligible│  │  In Review    │
          └──────────┘  └───────┬───────┘
                                ↓
                        ┌───────────────┐
                        │  Scored       │  (All reviews complete)
                        └───────┬───────┘
                                ↓
                        ┌───────────────┐
                        │  Committee    │  (Decision meeting)
                        └──┬─────────┬──┘
                           ↓         ↓
                  ┌──────────┐  ┌───────────┐
                  │ Declined │  │  Approved  │
                  └──────────┘  └─────┬─────┘
                                      ↓
                              ┌───────────────┐
                              │ Award Created │
                              └───────────────┘
```

---

## Staged Application (LOI Model)

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

## Review Assignment

### Assignment Algorithm

1. Pull reviewer pool for funding program
2. Filter by expertise match (tags on reviewer profile vs application topics)
3. Exclude conflicts of interest:
   - Reviewer is board member of applicant org
   - Reviewer has personal relationship (self-declared)
   - Reviewer has financial interest
4. Assign minimum 2 reviewers per application
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

### Review Record Fields

| Field | Type | Purpose |
|-------|------|---------|
| Grant Application | Lookup | Application being reviewed |
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

After all reviews complete:

1. Calculate average score per criterion across reviewers
2. Calculate overall weighted score
3. Flag applications with high reviewer variance (>2 point spread)
4. Rank applications by overall score
5. Present ranked list to decision committee

---

## Decision Workflow

### Committee Decision

1. Present ranked applications with scores and reviewer comments
2. Committee discusses borderline cases
3. Record decision: Approved, Declined, Deferred, Approved with Conditions
4. For approvals: set award amount (may differ from requested)
5. Document rationale for each decision
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

### Review Deadline

- Notify reviewers at assignment
- Reminder at 50% and 75% of review period
- Escalate incomplete reviews to grants manager at deadline
- Option: reassign if reviewer unresponsive
