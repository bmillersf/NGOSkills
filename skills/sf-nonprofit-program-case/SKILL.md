---
name: sf-nonprofit-program-case
description: >
  Nonprofit Cloud (NPC) program and case management architecture with 120-point
  scoring. TRIGGER when: user designs program enrollment, benefit delivery,
  case management, intake processes, outcome tracking, referral management, or
  wraparound services on Nonprofit Cloud using native Program/Enrollment/Benefit objects.
  Also triggers when user asks about "intake form for clients", "case load
  management", "client tracking", or "track program participants".
  DO NOT TRIGGER when: NPSP orgs without NPC program objects (use sf-nonprofit-npsp
  for constituent model, custom-build program tracking), fundraising
  (use sf-nonprofit-fundraising), grant management (use sf-nonprofit-grants),
  generic Apex/LWC (use sf-apex, sf-lwc), or non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "2.0.0"
  scoring: "120 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.npc_program_management.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud_object_reference.meta/nonprofit_cloud_object_reference/program.htm
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
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (6 categories: Program Design 25 / Enrollment Lifecycle 20 / Benefit Delivery 20 / Case Management 20 / Outcome Tracking 20 / Best Practices 15) — extracted from existing workflow narrative 2026-05-22; mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  program_case_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Program + enrollment data-model correctness. Maps to Program Design (25) + Enrollment Lifecycle (20). Native NPC objects used for program / enrollment / benefit / case / outcome; lifecycle status transitions documented and honored; Person Account model for individuals."
      automatic_hard_fail_rules:
        - "Custom enrollment object built (Program_Enrollment__c) when Program Enrollment exists in NPC — shadow data model"
        - "Custom service tracking object built when Benefit / Benefit Disbursement objects exist in NPC"
        - "Opportunity used for program intake tracking (wrong cloud — fundraising belongs to sf-nonprofit-fundraising)"
        - "Program Enrollment with no status lifecycle (single State) — can't track Applied → Waitlisted → Enrolled → Active → Completed/Withdrawn"
        - "Individuals modeled as Contact + Household Account when org is NPC (NPC uses Person Account; NPSP would use sf-nonprofit-npsp instead)"
        - "Care Plan / Goal Definition / Referral custom-built when those native objects exist in NPC"
    - name: Robustness
      max: 25
      hard_fail_below: 16
      description: "Client-data safeguards + case integrity. Maps to Best Practices (15) + Case Management (20) and the consent/data-sharing concerns called out in NPC. Heavy floor — program data is sensitive (vulnerable populations, regulated services); consent + sharing must be explicit."
      automatic_hard_fail_rules:
        - "Client sensitive data captured (intake assessments, case notes, identity documents) without consent-tracking field or object"
        - "Case record with no ownership / assignment rule (orphaned cases)"
        - "Cross-program data sharing (referrals) without sharing rule scoped to receiving program staff (over-exposure of client info)"
        - "File uploads attached to records without explicit AccessLevel / Sharing setting (default-shared sensitive documents)"
        - "Case Team / multi-disciplinary coordination missing on wraparound services (every case soloed by one owner)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Pattern adherence + NPC vs NPSP routing. Maps to portions of Program Design + Best Practices. Skill applied only on NPC orgs; PMM/custom-build path taken on NPSP; Case vs Benefit Disbursement choice matches the work pattern; Indicator framework wired to outcomes."
      automatic_hard_fail_rules:
        - "Skill applied to an NPSP org without PMM (program objects don't exist — should route to sf-nonprofit-npsp + custom-build path)"
        - "Routine scheduled service (tutoring, meal distribution) modeled as Case instead of Benefit Disbursement (Case is for complex interventions)"
        - "Complex intervention with follow-up modeled as Benefit Disbursement instead of Case (no resolution / case-team support)"
        - "Outcome tracking without Indicator Definition / Indicator Result — claims to measure impact but has no measurement objects wired"
        - "Mixing program data with fundraising data in shared custom objects (constituent privacy + reporting blast)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Outcome tracking + scale. Maps to Outcome Tracking (20). Indicator Performance Periods bounded, indicator results aggregated efficiently, attendance via Benefit Schedule (not bulk-DML loops), reports scoped per program for caseload sizes."
      automatic_hard_fail_rules:
        - "Indicator Result records written one-per-disbursement when periodic / aggregated measurement is the documented pattern (write amplification on bulk)"
        - "Attendance tracking implemented via per-session Apex DML loops instead of Benefit Schedule + Benefit Disbursement records"
        - "Reports / list views on Case or Program Enrollment with no filter scoped to caseload (full-org scan when each user only owns ~50 records)"
        - "Outcome Activity junction missing — Outcomes claim coverage but never link to Program/Benefit/Goal Definition (uncomputed impact)"
  test_rubric:
    unit:
      required: true
      criteria: "Metadata validates: Program / Program Enrollment / Benefit / Case / Outcome / Indicator Definition use native NPC objects (no custom-shadow). Status picklists enumerate documented lifecycle values. Person Account record types correct."
    integration:
      required: true
      criteria: "End-to-end intake-to-outcome flow runs in an NPC sandbox: Referral → Intake → Eligibility → Program Enrollment (with status lifecycle) → Benefit Disbursement → Indicator Result → Outcome Activity computed. Sharing rules enforce caseload boundaries for restricted-profile users."
    smoke:
      required: true
      criteria: "Caseworker user opens their caseload, sees only their assigned enrollments + cases, can record a benefit disbursement and indicator result that flow into outcome reporting. Cross-program referral lands in receiving program with referral source visible to receiving staff but not to unrelated users."
---

# sf-nonprofit-program-case: Nonprofit Cloud Program & Case Management Architect

Expert Salesforce architect specializing in **Nonprofit Cloud (NPC)** program management, case management, intake workflows, benefit delivery tracking, outcome measurement, and referral coordination.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 6 NPC program/case categories, extracted from this skill's existing workflow narrative and mapped onto the 4-dim shape. Robustness floor at 16 — program data covers vulnerable populations and regulated services; consent + sharing-rule scoping must be explicit. Hard-fail rules block shadow data models (custom Program_Enrollment__c when NPC native exists), missing consent tracking, NPSP orgs routed here without PMM, Case-vs-Benefit-Disbursement misuse, and outcome claims without Indicator wiring. Disable with `eval_harness.enabled: false`.

---

> **Platform note**: Program, Program Enrollment, Benefit, Benefit Disbursement, Outcome, and Indicator objects are **NPC-native** — they do not exist in NPSP. NPSP orgs needing program management must custom-build or use the PMM (Program Management Module) package. Standard Case object is available on both platforms. For NPSP constituent model, see **sf-nonprofit-npsp**.

## Core Responsibilities

1. **Program Design**: Structure programs, cohorts, eligibility, and capacity management
2. **Enrollment Workflows**: Intake, application, waitlist, enrollment lifecycle
3. **Benefit Delivery**: Benefit sessions, attendance, disbursement documentation
4. **Case Management**: Client cases, care plans, task management, case notes
5. **Outcome Tracking**: Outcome definitions, indicator definitions, indicator results, impact measurement
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
| **Program Cohort** | Groups enrollments for cohort-based reporting | Program, Name, Start/End Date |
| **Program Cohort Member** | Many-to-many link between enrollments and cohorts | Program Cohort, Program Enrollment |
| **Benefit** | Specific activity/service within a program | Name, Type, Program, Status |
| **Benefit Type** | Cross-program benefit categories | Name, Description |
| **Benefit Assignment** | Benefit eligibility/allocation for a participant | Person Account, Benefit, Start/End Date |
| **Benefit Disbursement** | Individual delivery event | Benefit, Program Enrollment, Date, Quantity |
| **Benefit Session** | Scheduled instance of a benefit | Date, Location, Capacity |
| **Benefit Schedule** | Recurring schedule for benefit delivery, manages attendance | Benefit, Frequency, Start/End Date |
| **Unit of Measure** | How benefits are measured | Name (meals, dollars, hours) |
| **Case** | Support/intervention record | Person Account, Status, Priority, Origin |
| **Care Plan** | Structured support plan with stages | Case, Status (Proposed → Draft → Active → Completed → Canceled) |
| **Goal Definition** | Measurable milestones within care plans | Care Plan, Target, Status |
| **Referral** | Inter-program or inter-org referral | Person Account, From Program, To Program, Status |
| **Outcome** | Defined result/impact measure | Program, Target, Measurement Type |
| **Outcome Activity** | Junction linking Outcome to Program, Benefit, or Goal Definition | Outcome, Program, Benefit |
| **Indicator Definition** | What is measured | Name, Measurement Type, Target |
| **Indicator Result** | Actual measurement value | Indicator Definition, Value, Date, Person Account |
| **Indicator Assignment** | Links indicator to program/outcome | Indicator Definition, Program, Outcome |
| **Indicator Performance Period** | Time-bound target and baseline | Indicator Definition, Start/End Date, Target, Baseline |

---

## Architecture Patterns

### Program Lifecycle

```
Program (Active)
├── Benefit (activities/services offered)
│   ├── Benefit Session (scheduled instances)
│   └── Benefit Schedule (recurring schedule)
├── Program Enrollment
│   ├── Applied → Waitlisted → Enrolled → Active → Completed
│   │                                        ↓
│   │                                    Withdrawn
│   ├── Benefit Assignment (eligibility/allocation)
│   ├── Benefit Disbursement (delivery events)
│   ├── Case (support interventions)
│   └── Indicator Result (measurements)
├── Program Cohort → Program Cohort Members
└── Outcome → Outcome Activity → Indicator Definition
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

Multiple programs and cases connect to a single Person Account. Use Case Teams for multi-disciplinary coordination. Link cases to program enrollments for full participant view. Benefit Disbursements across programs provide a complete service history.

### Outcome Measurement

Programs define Outcomes (targets). Outcome Activities link Outcomes to Programs/Benefits. Indicator Definitions describe what is measured. Indicator Results record individual measurement values. Indicator Performance Periods set time-bound targets and baselines.

---

## Decision Trees

### Case vs Benefit Disbursement

- **Benefit Disbursement**: Routine, scheduled services (tutoring session, meal distribution, counseling appointment)
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

## Benefit Delivery Patterns

| Pattern | Use Case | Implementation |
|---------|----------|---------------|
| **Session-based** | Classes, workshops, counseling | Benefit Session per session with attendance via Benefit Schedule |
| **Ongoing** | Case management, mentoring | Benefit Disbursement records at milestones |
| **Drop-in** | Food bank, clothing closet | Benefit Disbursement per visit (supports anonymous recipients) |
| **Group** | Support groups, cohort programs | Benefit Disbursement per participant per session |

---

## Outcome Framework

### Outcome Hierarchy

```
Impact Goal (org-level)
└── Outcome (program-level)
    └── Outcome Activity (junction → Program/Benefit)
        └── Indicator Definition (what is measured)
            ├── Indicator Assignment (→ program/outcome)
            ├── Indicator Performance Period (target + baseline)
            └── Indicator Result (actual measurement)
```

### Indicator Measurement Patterns

| Type | Example | Frequency |
|------|---------|-----------|
| Pre/Post | Indicator Result at enrollment start and end | 2x per enrollment |
| Periodic | Monthly Indicator Result (wellness score, attendance rate) | Monthly |
| Milestone | Indicator Result at milestone (certification pass/fail) | At milestone |
| Continuous | Ongoing Indicator Results aggregated per Indicator Performance Period | Rolling |

---

## Validation & Scoring

```
Score: XX/120
├─ Program Design: XX/25        (Structure, eligibility, capacity)
├─ Enrollment Lifecycle: XX/20  (Intake, waitlist, status transitions)
├─ Benefit Delivery: XX/20      (Benefits, disbursements, sessions, attendance)
├─ Case Management: XX/20       (Cases, care plans, referrals)
├─ Outcome Tracking: XX/20      (Outcomes, indicators, results, performance periods)
└─ Best Practices: XX/15        (Security, consent, data quality)
```

---

## NPC vs NPSP Program/Case Availability

| Capability | NPC (this skill) | NPSP |
|------------|-------------------|------|
| **Program** | Native object | Program (pmdm__Program__c) via PMM package |
| **Program Enrollment** | Native object | Program Engagement (pmdm__ProgramEngagement__c) via PMM package |
| **Benefit / Benefit Disbursement** | Native objects | Service Delivery (pmdm__ServiceDelivery__c) via PMM package |
| **Indicator Definition / Indicator Result** | Native objects | Not available — custom build required |
| **Case** | Standard object (available) | Standard object (available) |
| **Care Plan / Goal Definition / Referral** | Native objects | Not available — custom build required |
| **Volunteer Management** | Native (Job Position, Job Position Shift, Job Position Assignment) | Volunteers for Salesforce (separate package) |
| **Individual record** | Person Account | Contact + Household Account |

NPSP orgs requiring program management often use PMM (Program Management Module), a first-party Salesforce.org package, or AppExchange solutions (e.g., Apricot, Efforts to Outcomes), or plan migration to NPC to gain native program capabilities.

---

## Anti-Patterns

- Building custom enrollment objects when Program Enrollment exists (NPC)
- Building custom service tracking when Benefit / Benefit Disbursement objects exist (NPC)
- Using Opportunity for program intake tracking
- No status lifecycle on Program Enrollment (stuck in one state)
- Skipping Indicator Definitions (no way to measure impact)
- Case records without clear ownership or assignment rules
- Mixing program data with fundraising data in same custom objects
- No consent tracking for sensitive client data
- Ignoring native Care Plan / Goal Definition objects and building custom equivalents

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
| NPSP constituent model (if NPSP org) | sf-nonprofit-npsp |
| Deploy program metadata | sf-deploy |
| SOQL for participant reporting | sf-soql |
| Test data for program scenarios | sf-data |

---

## Terminology

- **Program** — Service or initiative offered by the organization
- **Program Enrollment** — Individual's participation in a program
- **Program Cohort** — Groups enrollments for cohort-based reporting
- **Benefit** — Specific activity or service within a program
- **Benefit Type** — Cross-program benefit category
- **Benefit Assignment** — Benefit eligibility/allocation for a participant (what they SHOULD receive)
- **Benefit Disbursement** — Individual delivery event recording service provided
- **Benefit Session** — Scheduled instance of a benefit
- **Benefit Schedule** — Recurring schedule for benefit delivery, manages attendance
- **Unit of Measure** — How benefits are measured (meals, dollars, hours)
- **Case** — Support or intervention record requiring follow-up
- **Care Plan** — Structured support plan with stages (Proposed → Draft → Active → Completed → Canceled)
- **Goal Definition** — Measurable milestone within a care plan
- **Referral** — Inter-program or inter-org referral for a participant
- **Outcome** — Defined result or impact measure linked to a program
- **Outcome Activity** — Junction linking Outcome to Program, Benefit, or Goal Definition
- **Indicator Definition** — What is measured for outcome tracking
- **Indicator Result** — Actual measurement value for an indicator
- **Indicator Assignment** — Links an indicator to a program or outcome
- **Indicator Performance Period** — Time-bound target and baseline for an indicator
- **Job Position** — Volunteer role within a program
- **Job Position Shift** — Scheduled volunteer shift
- **Job Position Assignment** — Volunteer's hours/assignment to a shift
- **Intake** — Process of receiving and evaluating new participants
- **Wraparound** — Coordinated multi-service support for a participant
