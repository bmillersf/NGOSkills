---
name: sf-nonprofit-program-case
description: >
  Nonprofit program and case management architecture with 120-point scoring.
  TRIGGER when: user designs program enrollment, service delivery, case
  management, intake processes, outcome tracking, referral management, or
  wraparound services on Nonprofit Cloud. DO NOT TRIGGER when: fundraising
  (use sf-nonprofit-fundraising), grant management (use sf-nonprofit-grants),
  generic Apex/LWC code (use sf-apex, sf-lwc), or non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "120 points across 6 categories"
---

# sf-nonprofit-program-case: Program & Case Management Architect

Expert Salesforce architect specializing in Nonprofit Cloud program management, case management, intake workflows, service delivery tracking, outcome measurement, and referral coordination.

## Core Responsibilities

1. **Program Design**: Structure programs, cohorts, eligibility, and capacity management
2. **Enrollment Workflows**: Intake, application, waitlist, enrollment lifecycle
3. **Service Delivery**: Session tracking, attendance, service documentation
4. **Case Management**: Client cases, care plans, task management, case notes
5. **Outcome Tracking**: Outcome definitions, activities, assessments, impact measurement
6. **Validation & Scoring**: Score designs against 6 categories (0-120 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Enrollment flows** | [references/enrollment-patterns.md](references/enrollment-patterns.md) | Intake, waitlist, enrollment lifecycle patterns |
| **Case management** | [references/case-management.md](references/case-management.md) | Case types, care plans, notes, referrals |

---

## Key Data Model

| Object | Purpose | Key Fields |
|--------|---------|------------|
| **Program** | Service or initiative | Name, Status, Start/End Date, Category |
| **Program Enrollment** | Individual's participation | Person Account, Program, Status, Enrollment Date |
| **Service Delivery** | Record of service provided | Program Enrollment, Date, Type, Duration |
| **Case** | Support/intervention record | Person Account, Status, Priority, Origin |
| **Benefit Assignment** | Benefits provided to participant | Person Account, Benefit, Start/End Date |
| **Outcome** | Defined result/impact measure | Program, Target, Measurement Type |
| **Outcome Activity** | Instance of outcome measurement | Outcome, Person Account, Value, Date |
| **Assessment** | Data collection instrument | Type, Status, Questions, Responses |

---

## Architecture Patterns

### Program Lifecycle

```
Program (Active)
├── Program Enrollment
│   ├── Applied → Waitlisted → Enrolled → Active → Completed
│   │                                        ↓
│   │                                    Withdrawn
│   ├── Service Delivery (sessions, services)
│   ├── Case (support interventions)
│   └── Outcome Activity (measurements)
└── Outcome (program-level targets)
```

### Intake Process

```
Referral / Self-Referral
  → Intake Assessment
  → Eligibility Check
  → Program Match
  → Enrollment (or Waitlist)
  → Orientation / Onboarding
```

### Wraparound Services

Multiple programs and cases connect to a single Person Account. Use Case Teams for multi-disciplinary coordination. Link cases to program enrollments for full participant view.

### Outcome Measurement

Programs define Outcomes (targets). Outcome Activities record individual measurements. Assessments collect structured data. Roll up activities to program-level reporting.

---

## Decision Trees

### Case vs Service Delivery

- **Service Delivery**: Routine, scheduled services (tutoring session, meal distribution, counseling appointment)
- **Case**: Complex intervention requiring tracking, follow-up, and resolution (housing placement, crisis intervention, benefits enrollment)

### Standard Case vs Custom Object

- **Standard Case**: Supports case teams, entitlements, milestones, email-to-case, assignment rules — use when these features add value
- **Custom Object**: Only when Case object constraints block requirements (rare for nonprofits)

### Program Enrollment Status Model

- **Simple**: Applied → Enrolled → Completed (small programs, drop-in services)
- **Standard**: Applied → Waitlisted → Enrolled → Active → Completed/Withdrawn (most programs)
- **Complex**: Add stages for screening, orientation, probation (regulated programs, credentialing)

---

## Intake Best Practices

1. **Single entry point**: One intake form/flow regardless of program destination
2. **Eligibility engine**: Flow-based rules to auto-match eligible programs
3. **Warm handoff**: Referral source visible to receiving program staff
4. **Duplicate detection**: Match incoming clients against existing Person Accounts
5. **Consent management**: Track consent for data sharing, services, assessments
6. **Document collection**: File upload linked to Person Account or Case

---

## Service Delivery Patterns

| Pattern | Use Case | Implementation |
|---------|----------|---------------|
| **Session-based** | Classes, workshops, counseling | Service Delivery per session with attendance |
| **Ongoing** | Case management, mentoring | Service Delivery records at milestones |
| **Drop-in** | Food bank, clothing closet | Aggregate Service Delivery per visit |
| **Group** | Support groups, cohort programs | Service Delivery per participant per session |

---

## Outcome Framework

### Outcome Hierarchy

```
Impact Goal (org-level)
└── Outcome (program-level)
    └── Outcome Activity (individual measurement)
        └── Assessment (data collection)
```

### Assessment Patterns

| Type | Example | Frequency |
|------|---------|-----------|
| Pre/Post | Skills assessment at start and end | 2x per enrollment |
| Periodic | Monthly wellness check | Monthly |
| Milestone | Certification exam pass/fail | At milestone |
| Satisfaction | Client satisfaction survey | At completion |

---

## Validation & Scoring

```
Score: XX/120
├─ Program Design: XX/25        (Structure, eligibility, capacity)
├─ Enrollment Lifecycle: XX/20  (Intake, waitlist, status transitions)
├─ Service Delivery: XX/20      (Tracking, documentation, attendance)
├─ Case Management: XX/20       (Cases, care plans, referrals)
├─ Outcome Tracking: XX/20      (Definitions, activities, assessments)
└─ Best Practices: XX/15        (Security, consent, data quality)
```

---

## Anti-Patterns

- Building custom enrollment objects when Program Enrollment exists
- Using Opportunity for program intake tracking
- No status lifecycle on Program Enrollment (stuck in one state)
- Skipping outcome definitions (no way to measure impact)
- Case records without clear ownership or assignment rules
- Mixing program data with fundraising data in same custom objects
- No consent tracking for sensitive client data

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Intake and enrollment automations | sf-flow |
| Apex logic for eligibility engines | sf-apex |
| Client-facing enrollment portal | sf-nonprofit-experience-cloud |
| Portal UX for program applications | sf-nonprofit-experience-cloud-ux |
| Grant-funded program tracking | sf-nonprofit-grants |
| Fundraising tied to programs | sf-nonprofit-fundraising |
| Custom objects for program extensions | sf-metadata |
| Deploy program metadata | sf-deploy |
| SOQL for participant reporting | sf-soql |
| Test data for program scenarios | sf-data |

---

## Terminology

- **Program** — Service or initiative offered by the organization
- **Program Enrollment** — Individual's participation in a program
- **Service Delivery** — Record of service provided to a participant
- **Case** — Support or intervention record requiring follow-up
- **Benefit Assignment** — Benefits provided to a participant
- **Outcome** — Defined result or impact measure linked to a program
- **Outcome Activity** — Individual measurement instance
- **Assessment** — Structured data collection instrument
- **Intake** — Process of receiving and evaluating new participants
- **Wraparound** — Coordinated multi-service support for a participant
