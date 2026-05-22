---
name: sf-nonprofit-grants
description: >
  Nonprofit Cloud (NPC) grant management architecture with 110-point scoring.
  TRIGGER when: user designs grant applications, review workflows, funding
  awards, disbursements, budgets, compliance tracking, or grantmaking pipelines
  on Nonprofit Cloud using native Application/Funding Award objects. Also
  triggers when user asks about "grants pipeline", "grant application workflow",
  "track a funding award", or "grant decision process". DO NOT TRIGGER
  when: NPSP + Outbound Funds Module (use sf-nonprofit-npsp OFM section),
  fundraising/donations (use sf-nonprofit-fundraising), program management
  (use sf-nonprofit-program-case), generic Apex/LWC (use sf-apex, sf-lwc),
  or non-nonprofit Salesforce work.
license: MIT
metadata:
  version: "2.0.0"
  scoring: "110 points across 6 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.npc_grantmaking.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud_object_reference.meta/nonprofit_cloud_object_reference/funding_award.htm
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
  rubric_ref: "110-pt rubric (6 categories: Application Pipeline 20 / Review Process 20 / Award Management 20 / Funding Disbursement 20 / Compliance & Reporting 15 / Best Practices 15) — converted from existing weighted-criterion rubric (1-5 × weight%) into point-based 4-dim shape per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  grants_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "Grant data-model + lifecycle correctness. Maps to Application Pipeline (20) + Award Management (20). Native NPC objects (Application / Funding Award / Funding Disbursement / Funding Award Requirement) used in correct lifecycle order; no shadow custom objects; grantmaker / grantee direction explicit."
      automatic_hard_fail_rules:
        - "Opportunity used for grant tracking in an NPC org (wrong cloud — Application is the native object)"
        - "OFM objects (outfunds__Funding_Request__c, outfunds__Disbursement__c) used in an NPC org (wrong namespace — native Application/Funding Award exist)"
        - "NPC native objects used in an NPSP+OFM org (should route to sf-nonprofit-npsp instead)"
        - "Custom Grant_Application__c built when native Application exists"
        - "Funding Disbursement records without parent Funding Award (orphan disbursements)"
        - "Mixed grantmaker + grantee records in shared Application records without direction indicator or separate record types"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Review integrity + audit trail. Maps to Review Process (20) + portions of Compliance & Reporting (15). Conflicts of interest checked, scoring rubric applied consistently, decision rationale captured, status changes auditable."
      automatic_hard_fail_rules:
        - "Application Review without conflict-of-interest check before reviewer assignment (org affiliation / personal relationship)"
        - "Single-reviewer-per-application pattern (no second reviewer for cross-check or panel review)"
        - "Application Decision recorded without ApplicationDecision record (decision but no decider / no rationale captured)"
        - "Application status field changes without Field History Tracking enabled (no audit trail on advancement / decline)"
        - "Funding Award amendments applied directly to Funding Award fields without FundingAwardAmendment record (lost change history)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Pattern adherence + scoring rubric structure. Maps to Best Practices (15) + portions of Application Pipeline (20). Staged application (LOI → invited full), eligibility pre-check, weighted scoring rubric documented, applicant portal pattern."
      automatic_hard_fail_rules:
        - "Review scoring without documented rubric (subjective decisions; rubric pattern is Mission Alignment / Org Capacity / Project Design / Budget / Measurable Outcomes weighted 25/20/25/15/15)"
        - "Heavy single-shot application with no LOI / pre-check stage when applicant volume warrants (applicant burden + reviewer overload)"
        - "Application Stage Definition skipped — workflow stages hardcoded in Flow / Apex instead of configurable records"
        - "Hardcoded grant terms in Apex / Flow instead of configurable Funding Award template"
        - "Applicant portal built without Experience Cloud (custom Visualforce / forms hosted off-platform — auth + tracking divergence)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Disbursement reconciliation + reporting scale. Maps to Funding Disbursement (20) + portions of Compliance & Reporting (15). Disbursements reconciled against Budget categories, milestone-based releases honored, compliance deadlines auto-tracked, audit-ready reporting at portfolio scale."
      automatic_hard_fail_rules:
        - "Funding Disbursements without budget reconciliation against Budget object (spent vs budgeted untracked)"
        - "Compliance deadlines (Funding Award Requirement Due Date) without scheduled reminders / process automation (silent non-compliance)"
        - "Reports on grants portfolio without selective filter / record-type scope (full-org scan when each program officer manages a sub-portfolio)"
        - "Closeout step missing — grants reach end-date but no closeout reporting / final disbursement reconciliation triggered"
  test_rubric:
    unit:
      required: true
      criteria: "Metadata validates: Application + Funding Award + Funding Disbursement + Budget + Funding Award Requirement use native NPC objects with correct lookups. Application Stage Definition records configure documented stages. Field History Tracking enabled on Application.Status, FundingAward.Status."
    integration:
      required: true
      criteria: "End-to-end pipeline runs in NPC sandbox: Funding Opportunity published → Application submitted → Reviewer assigned (with COI check) → ApplicationReview scores recorded → ApplicationDecision logged → FundingAward + Agreement created → milestone-based FundingDisbursement released → FundingAwardRequirement deliverables tracked → Closeout. Budget reconciliation balances disbursed against budgeted amounts."
    smoke:
      required: true
      criteria: "Grantee user submits application via Experience Cloud portal, sees only their own applications + awards. Program officer user reviews, scores, and decides. Funder reporting view aggregates portfolio with filters by program / fiscal year. Compliance deadline triggers reminder before due date."
---

# sf-nonprofit-grants: Nonprofit Cloud Grant Management Architect

Expert Salesforce architect specializing in **Nonprofit Cloud (NPC)** grantmaking: grant application pipelines, review workflows, funding awards, disbursement schedules, budget tracking, compliance, and funder reporting.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 110-pt rubric across 6 grantmaking categories, converted from the existing weighted-criterion (1-5 × weight%) rubric into the point-based 4-dim shape. Robustness floor at 14 — grant decisions are funded; conflict checks, two-reviewer audit, decision rationale, and field-history tracking are how integrity is demonstrated to funders + auditors. Hard-fail rules block Opportunity-for-grants, NPC objects in OFM orgs (and vice versa), single-reviewer scoring, undocumented rubric, missing budget reconciliation, and absent compliance reminders. Disable with `eval_harness.enabled: false`.

---

> **Platform note**: This skill covers NPC native grantmaking objects (Application, Funding Award, Funding Disbursement). For NPSP orgs using **Outbound Funds Module (OFM)**, see the OFM section in **sf-nonprofit-npsp**.

## Core Responsibilities

1. **Application Pipeline**: Design grant application intake, review, and decision workflows
2. **Review Process**: Scoring rubrics, reviewer assignment, conflict-of-interest checks
3. **Award Management**: Funding awards, terms, conditions, amendments
4. **Funding Disbursement**: Payment schedules, milestone-based releases, financial tracking
5. **Compliance & Reporting**: Funder requirements, progress reports, audit readiness
6. **Validation & Scoring**: Score designs against 6 categories (0-110 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Application pipeline** | [references/application-pipeline.md](references/application-pipeline.md) | Application lifecycle, review workflows, decision patterns |
| **Disbursement & compliance** | [references/disbursement-compliance.md](references/disbursement-compliance.md) | Payment schedules, budget tracking, reporting |

---

## Key Data Model

| Object | API Name | Purpose | Key Fields |
|--------|----------|---------|------------|
| **Funding Opportunity** | FundingOpportunity | Published grant opportunity that applicants respond to | Program, Deadline, Eligibility Criteria, Amount Range |
| **Application** | Application | Application from grantee | Applicant (Account), Funding Opportunity, Status, Requested Amount |
| **Application Review** | ApplicationReview | Reviewer evaluation | Application, Reviewer, Score, Recommendation |
| **Application Decision** | ApplicationDecision | Tracks who approved/denied and rationale | Application, Decision, Decider, Rationale |
| **Funding Award** | FundingAward | Approved grant | Application, Amount, Start/End Date, Status |
| **Funding Disbursement** | FundingDisbursement | Payment against award | Funding Award, Amount, Date, Status, Milestone |
| **Budget** | Budget | Grantee budget | Funding Award, Category, Budgeted Amount, Spent |
| **Funding Award Requirement** | FundingAwardRequirement | Compliance deliverables from grantee | Funding Award, Type, Status, Due Date |
| **Funding Award Requirement Section** | FundingAwardRequirementSection | Sub-items within a requirement | Funding Award Requirement, Section, Status |
| **Funding Award Amendment** | FundingAwardAmendment | Post-award changes (timeline, scope, budget) | Funding Award, Amendment Type, Effective Date |
| **Individual Application** | IndividualApplication | Supports individual (not just organizational) applicants | Contact, Funding Opportunity, Status |
| **Application Stage Definition** | ApplicationStageDefinition | Configures application workflow stages | Stage Name, Order, Criteria, Auto-Advance |

---

## Architecture Patterns

### Grant Lifecycle (Grantmaker Perspective)

```
Funding Opportunity Published
  → Application Received
  → Eligibility Screening
  → Application Review & Scoring
  → Application Decision (Award / Decline)
  → Funding Award Created
  → Agreement Executed
  → Funding Disbursement(s) Released
  → Funding Award Requirement (Grantee Reporting)
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

- **As grantmaker**: Applications received, Funding Awards issued, Funding Disbursements sent
- **As grantee**: Applications submitted, Funding Awards received, Funding Disbursements received
- Use a direction indicator or separate record types

---

## Decision Trees

### Application vs Opportunity

- **Application**: NPC standard object for grant intake — use as default
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
├─ Funding Disbursement: XX/20   (Schedules, milestones, reconciliation)
├─ Compliance & Reporting: XX/15 (Funder reports, audit trail, deadlines)
└─ Best Practices: XX/15         (Security, portal access, documentation)
```

---

## NPC vs NPSP+OFM Grantmaking Quick Reference

| Concept | NPC (this skill) | NPSP + OFM (sf-nonprofit-npsp) |
|---------|-------------------|-------------------------------|
| **Application** | Application | Funding Request (outfunds__) — serves as both application and award |
| **Award** | Funding Award | Funding Request (status changes to Awarded; outfunds__Awarded_Amount__c populated) |
| **Disbursement** | Funding Disbursement | Disbursement (outfunds__Disbursement__c) |
| **Budget** | Budget object (native) | No native budget — custom build |
| **Compliance** | Funding Award Requirement | Requirement (outfunds__Requirement__c) |
| **Reviewers** | Application Review | Review (outfunds__Review__c) |
| **Installation** | Built-in | Separate managed package |
| **Namespace** | None | outfunds__ |

> **Note**: OFM has no separate Funding Award object — the Funding Request serves dual purpose as both application and award record.

If the org has `outfunds__` namespace objects, route to **sf-nonprofit-npsp** OFM section instead.

---

## Anti-Patterns

- Using Opportunity for grant tracking in NPC orgs
- Using OFM objects in an NPC org (use native Application instead)
- Using OFM Funding Request patterns in an NPC org (use native Application instead)
- No review scoring rubric (subjective decisions without documentation)
- Funding Disbursements without budget reconciliation
- Missing compliance deadlines (no automated reminders)
- Hardcoding grant terms instead of configurable award templates
- No audit trail on Application status changes
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
| NPSP + OFM grant management (if NPSP org) | sf-nonprofit-npsp |
| Deploy grant metadata | sf-deploy |
| SOQL for grant reporting | sf-soql |
| Test data for grant scenarios | sf-data |

---

## Terminology

- **Funding Opportunity** — Published grant opportunity that applicants respond to
- **Application** — Formal request for funding from a grantee
- **Application Review** — Reviewer evaluation with scoring and recommendation
- **Application Decision** — Record of who approved/denied and rationale
- **Funding Award** — Approved grant with terms and amount
- **Funding Disbursement** — Payment release against a funding award
- **Funding Award Requirement** — Compliance deliverable owed by the grantee
- **Funding Award Requirement Section** — Sub-item within a Funding Award Requirement
- **Funding Award Amendment** — Post-award change to timeline, scope, or budget
- **Individual Application** — Application submitted by an individual (not an organization)
- **Application Stage Definition** — Configures workflow stages for applications
- **Budget** — Grantee's financial plan for awarded funds
- **LOI** — Letter of Intent (preliminary application)
- **Grantmaker** — Organization that awards grants
- **Grantee** — Organization that receives grants
- **Closeout** — Final reporting and reconciliation at grant end
