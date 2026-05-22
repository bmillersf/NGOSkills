---
name: sf-industry-public-sector
description: >
  Public Sector Solutions (PSS) architecture with industry-first routing.
  TRIGGER when: user builds a "constituent intake workflow", designs a
  "benefit application and disbursement" process, handles
  "license/permit issuance" or "permit renewal workflow",
  configures "regulatory inspection management", tracks
  "violation tracking" against regulatory codes, manages a
  "grant (government) management" program for a government agency,
  stands up "emergency program response", handles "complaint intake"
  from the public, or says "we need to issue a business license",
  "build an inspection checklist", "let residents apply for benefits
  online", "assign a case worker to a benefit application",
  "renew permits annually", "track code violations by inspector",
  "disburse SNAP / WIC / TANF benefits", "run an emergency
  assistance program", or "constituent 360". Covers Person Account
  constituent model, Benefit / BenefitAssignment / BenefitDisbursement,
  BusinessLicense, Permit, Inspection, RegulatoryCode,
  RegulatoryCodeViolation, CaseType, IndividualApplication, and
  Complaint. Industry precedence: this skill wins over sf-sales-cloud,
  sf-service-cloud, and sf-service-case whenever PSS is installed and
  the work touches Benefit, License, Permit, or Inspection objects.
  DO NOT TRIGGER when: generic pipeline / Lead / Opportunity CRM work on
  a non-PSS org (use sf-sales-cloud); generic Case management without
  PSS CaseType or Benefit/License/Permit involvement (use
  sf-service-cloud or sf-service-case); writing Apex classes, triggers,
  or handlers (use sf-apex); building Lightning Web Components (use
  sf-lwc); authoring record-triggered or screen Flows as the primary
  deliverable (use sf-flow); nonprofit / foundation / philanthropy grant
  management where the funder is a 501(c)(3) rather than a government
  agency — non-governmental grants route to sf-nonprofit-grants;
  Data Cloud unified-profile / segmentation work for constituents (use
  sf-datacloud); authoring OmniScript / Integration Procedure / Data
  Mapper / FlexCard components once intake shape is agreed (use
  sf-industry-commoncore-omniscript, sf-industry-commoncore-integration-procedure,
  sf-industry-commoncore-datamapper, sf-industry-commoncore-flexcard).
license: MIT
compatibility: "Requires Public Sector Solutions license (commonly includes OmniStudio, Experience Cloud, Shield)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "150 points across 7 categories — Workload fit 25 / Data model 25 / Intake UX 20 / Process automation 20 / Accessibility+Compliance 25 / Security 20 / Testing 15. Failing <105; rework <120; per-category ≥60% of max."
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "150-pt rubric (7 categories) extracted from existing 'Scoring rubric' section in this SKILL.md (line 233). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  pss_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Workload fit + Data model. Maps to Workload fit (25) + Data model (25). Right PSS object for the regulatory program; Person Account constituent model; RecordType strategy; sharing model; multi-jurisdiction support."
      automatic_hard_fail_rules:
        - "Standard Case used instead of PSS CaseType (CaseType inherits Case but adds regulatory metadata, benefit disbursement lineage, compliance audit trail)"
        - "Individual constituent modeled as Contact + Business Account instead of Person Account (PSS benefit eligibility, Constituent-360 FlexCards, OOTB automation all assume Person Account)"
        - "Custom shadow object built when Benefit / BenefitAssignment / BenefitDisbursement / BusinessLicense / Permit / Inspection / RegulatoryCode / RegulatoryCodeViolation / IndividualApplication / Complaint exists"
        - "Sharing model not documented for multi-jurisdiction org (constituent visible across jurisdictions when state regs prohibit)"
        - "RecordType strategy missing — single record type for distinct regulatory programs"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Accessibility + Compliance + Security. Maps to Accessibility+Compliance (25) + Security (20). Heaviest robustness floor — Section 508 / WCAG 2.1 AA non-compliance is legal liability (DOJ ADA Title II); FedRAMP boundary violations are program-ending."
      automatic_hard_fail_rules:
        - "Public-facing intake without Section 508 / WCAG 2.1 AA verification (legal liability — 'fix post-launch' is not acceptable)"
        - "Assistive-tech testing skipped (screen reader / keyboard-only / voice-control)"
        - "FedRAMP boundary not respected — constituent PII flowing to a non-FedRAMP integration target without documented + approved Interconnection Security Agreement (ISA)"
        - "Data residency requirement violated (constituent data in a region the regulatory program prohibits)"
        - "Shield Platform Encryption not configured for PII fields when org is FedRAMP / regulated"
        - "Shield Event Monitoring not configured (no audit signal on PII / benefit access)"
        - "Guest profile granting more than the documented least-privilege scope on a public intake site"
        - "Named Credentials not used for outbound integrations (inline auth / hardcoded keys)"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Intake UX + Process automation. Maps to Intake UX (20) + Process automation (20). OmniScript over custom LWC intake; Flow Orchestration for multi-stage workflows; no Apex for declarative-eligible work."
      automatic_hard_fail_rules:
        - "Custom LWC intake built when OmniScript owns the surface (re-implements accessibility / save-and-resume / field audit / IP wiring from scratch)"
        - "Save-and-resume not configured on long intake forms (constituent abandonment on session loss)"
        - "Server-side validation absent on intake (client-only validation easily bypassed)"
        - "Apex written for declarative-eligible work (Flow Orchestration / Record-Triggered Flow expresses the same logic)"
        - "Multi-stage workflow built as single Flow when Flow Orchestration is the documented pattern"
        - "Hardcoded benefit amounts in Flow or Apex instead of BenefitAssignment rules (amounts change every fiscal year by statute — code push every July 1)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Testing. Maps to Testing (15). ≥85% Apex coverage, E2E intake test, orchestration path coverage, pen test, accessibility audit."
      automatic_hard_fail_rules:
        - "Apex coverage <85% on PSS write paths"
        - "E2E intake test (constituent → Application → Benefit → Disbursement) absent"
        - "Orchestration path coverage incomplete (some Stages / Decisions never exercised)"
        - "Pen test not commissioned for public-facing intake before go-live"
        - "Accessibility audit (axe / Lighthouse / manual) not run before launch"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.pss_admin_intro.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.public_sector_solutions_object_reference.meta/public_sector_solutions_object_reference/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/public-sector
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_pss.htm
---

# sf-industry-public-sector: Public Sector Solutions Orchestrator

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 150-pt rubric across 7 PSS categories, extracted from this skill's existing Scoring rubric section (line 233) and mapped onto the 4-dim shape. Robustness floor at 18 — Section 508 / WCAG 2.1 AA non-compliance is legal liability (DOJ ADA Title II); FedRAMP boundary violations are program-ending. Hard-fail rules block standard Case instead of CaseType, Contact+BusinessAccount instead of Person Account, missing 508/WCAG verification, FedRAMP boundary crossings without ISA, custom LWC intake when OmniScript owns the surface, hardcoded benefit amounts (changes every fiscal year by statute), and missing pen test / a11y audit before go-live. Disable with `eval_harness.enabled: false`.

Expert Salesforce architect for **Public Sector Solutions (PSS)**: constituent services, benefit management, licensing and permitting, inspections, regulatory code enforcement, grantmaking for government agencies, emergency program management, and OmniStudio-powered intake.

This is an **industry skill**. When PSS is installed and the user's request touches Benefit, BusinessLicense, Permit, Inspection, RegulatoryCode, RegulatoryCodeViolation, CaseType, IndividualApplication, or Complaint objects, this skill **wins over** the generic cloud skills (sf-sales-cloud, sf-service-cloud, sf-service-case). Industry skills do not run `references/industry-precheck.md` — they are the destination.

> **Compliance note**: PSS deployments for federal and many state/local agencies commonly require **FedRAMP Moderate or High** authorization boundaries, **Section 508 / WCAG 2.1 AA** accessibility for all public-facing intake, and **data-residency** controls (US-only Hyperforce regions, often GovCloud-adjacent). Treat these as hard constraints, not "nice to haves" — miss one and the deployment cannot go live.

---

## 1. When this skill owns the task

Own the task when PSS is installed **and** the work primarily touches PSS-owned objects, OmniStudio intake bound to PSS, or constituent lifecycle orchestration. Delegate to a phase or component skill when the work is localized.

### Delegation table

| Need | Delegate to | Reason |
|---|---|---|
| Generic Lead → Opportunity pipeline (e.g., economic-development outreach not tied to a license/permit) | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) | PSS does not own sales pipeline; only route back if a constituent-facing record is created |
| Standard Case management with no PSS CaseType, Benefit, License, Permit, or Inspection involvement | [sf-service-cloud](../sf-service-cloud/SKILL.md) / [sf-service-case](../sf-service-case/SKILL.md) | PSS's CaseType subclasses Case — if the user is not using a CaseType record, they are in generic Service |
| Writing Apex classes, triggers, or handlers | [sf-apex](../sf-apex/SKILL.md) | Code is code — PSS only frames the contract |
| Lightning Web Components (portal widgets, custom screens) | [sf-lwc](../sf-lwc/SKILL.md) | Only after confirming the portal widget is not better served by a FlexCard |
| Record-triggered, screen, or autolaunched Flows as the primary deliverable | [sf-flow](../sf-flow/SKILL.md) | PSS prefers Flow Orchestration for multi-stakeholder approvals; simple automations still route to sf-flow |
| Data Cloud unified-profile / segmentation for constituents | [sf-datacloud](../sf-datacloud/SKILL.md) | PSS provides the system of record; Data Cloud provides the activation layer |
| OmniScript intake authoring (once shape is agreed) | [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) | This skill decides **what** the intake collects; OmniScript skill decides **how** it's implemented |
| Integration Procedure orchestration (benefit-eligibility service calls, license-status lookups) | [sf-industry-commoncore-integration-procedure](../sf-industry-commoncore-integration-procedure/SKILL.md) | Server-side orchestration lives in the IP skill |
| Data Mapper (DataRaptor) for extract/transform/load inside an IP or OmniScript | [sf-industry-commoncore-datamapper](../sf-industry-commoncore-datamapper/SKILL.md) | Data Mapper is a component, not an intake contract |
| FlexCard for constituent 360 at-a-glance views | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) | Card rendering is a component concern |
| **Nonprofit** / foundation / philanthropy grant management (funder is a 501(c)(3), not a government agency) | [sf-nonprofit-grants](../sf-nonprofit-grants/SKILL.md) | Government grantmaking uses PSS IndividualApplication + FundingAward; nonprofit grants use NPC Application + FundingAward in a non-regulatory context. Boundary: **who is the funder**. Federal/state/local agency → here. 501(c)(3) → nonprofit-grants. |

---

## 2. Industry precedence note

**PSS wins over sf-service-cloud / sf-service-case when PSS is installed AND any of the following objects are touched**: Benefit, BenefitAssignment, BenefitDisbursement, BusinessLicense, Permit, Inspection, RegulatoryCode, RegulatoryCodeViolation, CaseType, IndividualApplication, Complaint.

How to detect PSS is installed:

- `sf org list metadata --metadata-type CustomObject -o <alias>` and grep for `Benefit`, `BusinessLicense`, `Permit`, `Inspection`, `RegulatoryCode`, `CaseType`
- Look for the **Public Sector Solutions** permission set license on the org
- OmniStudio is almost always bundled — if OmniStudio is enabled and the org is a public-sector customer, assume PSS
- Experience Cloud public-facing intake sites are a strong positive signal

If PSS is installed and the user describes their problem in generic Case terms ("log a complaint", "track a service request", "manage a citizen interaction"), **translate** to the PSS vocabulary (CaseType + Complaint, CaseType + IndividualApplication, etc.) before doing any design work. Do not silently design on the generic Case object — it will not carry the regulatory metadata PSS needs downstream.

Exception: if PSS is installed but the user's task genuinely has no PSS-owned object in scope (e.g., internal HR Case Type for employee helpdesk), delegate back to sf-service-case.

---

## 3. Required context to gather first

Before any design work, ask for or infer:

1. **Agency type**: federal, state, county, municipal, tribal, school district, special district. Federal and state agencies have materially different compliance regimes.
2. **Workload focus**: benefits administration, licensing and permitting, inspections and code enforcement, grantmaking, emergency program management, constituent 360, or a composite. Each workload has a different dominant object set.
3. **FedRAMP requirement**: Moderate, High, None. If Moderate or High, confirm the org is in an authorized boundary (Salesforce Government Cloud or Government Cloud Plus) **before** designing integrations — retrofitting is expensive.
4. **Accessibility target**: Section 508, WCAG 2.1 AA (most common for state/local), WCAG 2.2 AA, or none. Public-facing intake (OmniScript on an Experience Cloud site) is the single largest accessibility risk.
5. **Multi-tenant jurisdiction**: is one Salesforce org serving multiple agencies, departments, or jurisdictions? If yes, record-type + sharing-set strategy is a Day-One concern.
6. **Data residency**: US-only, state-only, international restrictions. Impacts Hyperforce region selection and cross-org integrations.
7. **Existing legacy**: mainframe (MVS/CICS), COBOL case-management systems, on-prem benefit eligibility engines (e.g., CÚRAM). PSS typically integrates rather than replaces these on Day One.
8. **Constituent identity model**: Person Account (standard PSS) or B2C-style Contact+Account split. PSS strongly prefers Person Account for individual constituents.
9. **OmniStudio readiness**: is OmniStudio runtime installed, licensed, and are FlexCards / OmniScripts already authored, or is this greenfield?
10. **Experience Cloud strategy**: public unauthenticated intake, authenticated constituent portal, hybrid, or none.

If any of the top four (agency type, workload, FedRAMP, accessibility) are unknown, stop and ask — they change the architecture fundamentally, not just the details.

---

## 4. Workflow phases

### Phase 1 — Agency and workload scoping

Confirm the agency type, primary workload, and compliance regime. Produce a one-page scoping artifact with:

- Agency type and jurisdiction
- Primary workload (benefits / licensing / inspections / grantmaking / emergency / complaint intake)
- FedRAMP boundary
- Accessibility standard
- Data residency constraints
- In-scope PSS objects (pulled from section 8 cheat sheet)
- Out-of-scope (explicitly called out — prevents scope creep)

### Phase 2 — Constituent data model

Decide the constituent identity model:

- **Person Account** — default for PSS; unifies individual constituents into a single record that behaves like both an Account (for licenses, permits, benefits) and a Contact (for communications). Required for most PSS OOTB features.
- **Contact + Business Account** — only when the constituent is acting on behalf of a business entity (e.g., a licensed contractor, a permitted business).
- **Both** — common in licensing, where an individual (Person Account) holds a license on behalf of a business (Business Account). Use the Party Relationship model to link them.

Document the case-type / record-type strategy:

- One CaseType per regulatory program (e.g., "SNAP Recertification", "Food Service Inspection", "Building Permit Review")
- RecordType on Benefit / BusinessLicense / Permit distinguishing program variants
- Sharing model: role hierarchy + sharing sets for multi-jurisdictional deployments

### Phase 3 — Benefit / License / Permit object selection

Pick the right object for the workload. Common mistakes are tracked in section 6.

| Workload | Primary object | Supporting objects |
|---|---|---|
| Benefits administration (SNAP, WIC, TANF, LIHEAP, unemployment) | Benefit + BenefitAssignment + BenefitDisbursement | IndividualApplication, CaseType, Person Account |
| Business / professional licensing | BusinessLicense | License renewal Case, Inspection, RegulatoryCode |
| Permits (building, event, occupancy) | Permit | Inspection, RegulatoryCode, Complaint (downstream) |
| Inspections (food, building, environmental) | Inspection | RegulatoryCode, RegulatoryCodeViolation, BusinessLicense or Permit |
| Code enforcement | RegulatoryCodeViolation | RegulatoryCode, Inspection, Complaint, CaseType |
| Complaint intake from the public | Complaint | CaseType, Inspection (downstream) |
| Government grantmaking | IndividualApplication + FundingAward | Application Review, FundingDisbursement, FundingAwardRequirement |
| Emergency program response | Benefit (with an "Emergency" RecordType) + IndividualApplication | CaseType, BenefitDisbursement |

### Phase 4 — Intake design (OmniScript)

Intake is the **public-facing** surface. It is the single biggest accessibility, security, and FedRAMP risk area.

Contract this skill owns:
- What fields the intake collects
- What validation runs client-side vs server-side
- Which Integration Procedures back it (eligibility checks, duplicate-constituent detection, address validation)
- Accessibility requirements (labels, keyboard nav, color contrast, screen-reader landmarks)
- Section 508 / WCAG 2.1 AA compliance checklist
- Save-and-resume behavior (critical for long benefit applications)

Then delegate to [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) for implementation, and [sf-industry-commoncore-integration-procedure](../sf-industry-commoncore-integration-procedure/SKILL.md) for the backing IPs.

### Phase 5 — Process automation (Flow Orchestration for approvals)

Use **Flow Orchestration** (not plain record-triggered Flow) for:

- Multi-stage benefit eligibility approval (caseworker → supervisor → program director)
- License issuance workflow with inspections, background checks, and fee payment gates
- Permit review with plan-check, inspection, and sign-off stages
- Grant award review (eligibility screen → technical review → program-officer decision → contract execution)

Simple single-stage automations (status updates, email notifications) stay in Flow — delegate to [sf-flow](../sf-flow/SKILL.md).

### Phase 6 — Accessibility and security

Accessibility (mandatory for public-facing intake):

- **Section 508 / WCAG 2.1 AA** at minimum. Many state agencies now require 2.2 AA.
- Test with NVDA or JAWS on Windows, VoiceOver on macOS/iOS, TalkBack on Android
- Automated scans catch ~40% of issues; manual audit with assistive tech is required
- OmniScript form controls must have explicit labels (not just placeholder text)
- Color contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI components
- Keyboard navigation must complete every intake path without a mouse
- Timeouts must warn the user before expiring (24-minute warning on a 30-minute session)

Security (mandatory for constituent PII):

- Shield Platform Encryption on PII fields (SSN, DOB, benefit amount history)
- Shield Event Monitoring for audit trails on benefit decisions
- Named Credentials + External Credentials for every external integration — never hardcoded secrets
- Guest user profiles on public intake sites: principle of least privilege, no standard-object access
- File upload virus scanning (Salesforce handles this OOTB for internal uploads; verify for Experience Cloud guest uploads)
- FedRAMP deployments: no cross-boundary integrations without a documented and approved Interconnection Security Agreement (ISA)

### Phase 7 — Testing

Minimum test matrix:

- Apex unit tests on all custom triggers and classes touching PSS objects, ≥ 85% coverage (not the 75% minimum — regulatory code deserves higher)
- OmniScript intake E2E tests via Playwright or Provar, executed with assistive tech for accessibility verification
- Flow Orchestration path tests covering every approval branch (approve, deny, request-more-info, escalate)
- Sandbox-based load tests for benefit disbursement batches (if disbursing > 10k recipients per cycle, verify async batch sizing)
- Penetration test on public-facing Experience Cloud site before go-live
- Accessibility manual audit with a certified tester (CPACC / WAS credentialed)

---

## 5. Scoring rubric

**Target: 150 points across 7 categories**. Below 105 (70%) is failing. Below 120 (80%) requires rework before production.

```
Score: XX/150
├─ Workload fit: XX/25              (Right PSS object for the regulatory program; no generic Case masquerading)
├─ Data model: XX/25                (Person Account vs Contact+Account decision documented; RecordType strategy; sharing model; multi-jurisdiction)
├─ Intake UX: XX/20                 (OmniScript chosen over custom LWC; save-and-resume; server-side validation; backed by IPs)
├─ Process automation: XX/20        (Flow Orchestration for multi-stage; simple Flow where appropriate; no Apex for declarative-eligible work)
├─ Accessibility/Compliance: XX/25  (Section 508 / WCAG 2.1 AA verified; FedRAMP boundary respected; data residency; assistive-tech tested)
├─ Security: XX/20                  (Shield encryption on PII; Shield event monitoring; least-privilege guest profile; Named Credentials)
└─ Testing: XX/15                   (≥85% Apex coverage; E2E intake test; orchestration path coverage; pen test; accessibility audit)
```

Per-category pass threshold: each category must score ≥ 60% of its max or the overall design cannot pass, even if total crosses 105.

---

## 6. Anti-patterns

1. **Using standard Case instead of CaseType + Benefit** — standard Case has no regulatory metadata, no benefit disbursement lineage, no compliance audit trail. PSS CaseType inherits Case but adds the regulatory spine. Always use CaseType in PSS orgs.
2. **Building intake as a custom LWC when OmniScript owns this** — custom LWC intake means you re-implement accessibility, save-and-resume, field-level audit, and integration-procedure wiring from scratch. OmniScript gives all four for free on PSS. Only fall back to LWC when OmniScript genuinely cannot express the interaction (rare).
3. **Ignoring Section 508 / WCAG 2.1 AA for public-facing intake** — non-compliance is a legal liability for government agencies (DOJ ADA Title II, state equivalents). "We'll fix it post-launch" is not acceptable. Accessibility is Day-One scope or the site does not go live.
4. **Using Contact + Business Account for individual constituents instead of Person Account** — PSS benefit eligibility, constituent-360 FlexCards, and most OOTB automation assume Person Account. Contact-only models require rebuilding these features.
5. **Hardcoding benefit amounts in Flow or Apex instead of using BenefitAssignment rules** — amounts change every fiscal year by statute. Hardcoded values mean a code push every July 1. Store benefit rules in metadata or configurable records.
6. **Cross-FedRAMP-boundary integrations without an ISA** — moving constituent PII from a FedRAMP High org to a non-FedRAMP integration target (e.g., a marketing automation tool) violates the boundary. Every integration crossing a boundary needs a documented, approved Interconnection Security Agreement.
7. **Using a single sharing model across multiple jurisdictions** — one county's data is typically not visible to another county even within the same state-level org. Sharing sets + role hierarchy + RecordType combined is the standard; skipping sharing sets leaks data across jurisdictions.
8. **Treating Inspection as a Task or Event instead of the PSS Inspection object** — Task/Event has no checklist, no RegulatoryCodeViolation linkage, no inspector assignment rules, no regulatory audit trail. PSS Inspection is purpose-built.
9. **Confusing government grants (sf-industry-public-sector) with nonprofit grants (sf-nonprofit-grants)** — government grants use IndividualApplication + FundingAward within a regulatory framework (often 2 CFR 200 for federal). Nonprofit grants use the same objects in a philanthropic framework. The data model is similar; the compliance regime is entirely different. Wrong skill → wrong compliance guidance.

---

## 7. Common failure modes and remediation

### Failure: Benefit disbursement batch fails at volume

- **Symptom**: BenefitDisbursement batch process completes for small samples but times out or hits governor limits for production disbursement runs (>10k recipients).
- **Root cause**: Synchronous DML on BenefitAssignment → BenefitDisbursement, or insufficient batch sizing on the disbursement processor.
- **Fix**: Move disbursement generation into a Queueable or Batch Apex job with explicit scope size (usually 200–500), aggregate external payment system calls, and stagger FINS integration callouts. Add a disbursement-run audit record so each batch is replayable.

### Failure: OmniScript intake drops partial applications

- **Symptom**: Constituents start a benefit application but lose it when they leave and return hours later.
- **Root cause**: OmniScript save-and-resume not configured, or the `OmniProcessInstance` retention policy expired the in-flight record.
- **Fix**: Enable OmniScript "Save for Later" with an extended retention window (often 30–90 days for benefit applications per state statute). Create an authenticated constituent portal path so saved applications appear in the constituent's "In Progress" list. Verify the Experience Cloud guest profile can write to `OmniProcessInstance`.

### Failure: Cross-jurisdiction data leak

- **Symptom**: A caseworker in County A sees or can edit a benefit application filed in County B.
- **Root cause**: Org-wide default on Benefit / BenefitAssignment set to Public Read/Write (wrong default for multi-jurisdiction) or sharing set for County scope never deployed.
- **Fix**: Set OWD to Private on Benefit, BenefitAssignment, IndividualApplication, and CaseType. Create sharing sets keyed on a `Jurisdiction` field populated from the caseworker's profile. Re-run a sharing recalculation. Backfill the `Jurisdiction` field on historic records from the constituent's address county before enforcing the sharing set.

### Failure: Accessibility audit fails on OmniScript intake

- **Symptom**: Pre-launch WCAG 2.1 AA audit flags multiple Level A and AA violations on the public intake site.
- **Root cause**: Placeholder-only field labels, missing form landmarks, color contrast under 4.5:1, keyboard traps on custom OmniScript components.
- **Fix**: Add explicit `<label>` elements for every input (OmniScript supports label configuration — use it, do not rely on placeholder text). Add ARIA landmarks around form regions. Raise contrast on brand-critical text and borders. For any custom LWC embedded in OmniScript, run axe DevTools and keyboard-only traversal tests and fix every issue before resubmitting the audit.

### Failure: Flow Orchestration approval stuck forever

- **Symptom**: A benefit application sits in "Pending Supervisor Review" indefinitely with no email, no assignment, no Inbox entry.
- **Root cause**: Orchestration stage assigned to a user who left the agency, or a queue with no active members. Flow Orchestration does not auto-reassign on user deactivation by default.
- **Fix**: Add a scheduled Flow that checks for Orchestration Work Items older than SLA thresholds (e.g., 3 business days) and escalates or reassigns them to a backup queue. Configure queue membership audits so empty queues trigger alerts. On user deactivation, run a pre-deactivation script that reassigns open Orchestration Work Items.

---

## 8. PSS object cheat sheet

| Object | API Name | Purpose | Key relationships |
|---|---|---|---|
| **Business License** | BusinessLicense | Issued business/professional license record | Account (licensee), Inspection, RegulatoryCode |
| **Permit** | Permit | Issued permit (building, occupancy, event) | Account (applicant), Inspection, RegulatoryCode |
| **Inspection** | Inspection | Regulatory inspection record | Inspector (User), BusinessLicense or Permit, RegulatoryCodeViolation |
| **Benefit** | Benefit | Program-level benefit definition (SNAP, WIC, TANF, LIHEAP) | BenefitAssignment, BenefitDisbursement |
| **Benefit Disbursement** | BenefitDisbursement | Individual payment against a BenefitAssignment | BenefitAssignment, Person Account (recipient) |
| **Benefit Assignment** | BenefitAssignment | Links a Person Account to a Benefit with eligibility period | Benefit, Person Account, IndividualApplication |
| **Case Type** | CaseType | PSS regulatory Case subclass with program metadata | Case (parent), RegulatoryCode, Complaint |
| **Regulatory Code** | RegulatoryCode | Codified rule / statute / ordinance | Jurisdiction, RegulatoryCodeViolation, Inspection |
| **Regulatory Code Violation** | RegulatoryCodeViolation | Observed violation against a regulatory code | RegulatoryCode, Inspection, BusinessLicense or Permit |
| **Individual Application** | IndividualApplication | Application filed by an individual constituent (benefits, licenses, grants) | Person Account, Benefit, FundingAward, CaseType |
| **Complaint** | Complaint | Public complaint filed against a business, permit, or regulatory matter | CaseType, Account (respondent), RegulatoryCodeViolation (downstream) |

### Related PSS objects worth knowing

- **FundingOpportunity / FundingAward / FundingDisbursement / FundingAwardRequirement** — shared with grantmaking. In PSS context these represent **government grants**; in Nonprofit Cloud they represent **philanthropic grants**. Object identical, compliance regime different.
- **Party / PartyRelationship** — used when an individual (Person Account) relates to a business (Business Account), e.g., licensed contractor working for a construction firm.
- **ApplicationStageDefinition / ApplicationReview / ApplicationDecision** — application workflow metadata; used for review-and-decide flows on IndividualApplication.
- **OrchestrationWorkItem / OrchestrationStageInstance** — Flow Orchestration runtime records; review these when debugging stuck approval paths.

---

## Cross-skill integration

| Task | Skill |
|---|---|
| Author the OmniScript intake once the field list is agreed | [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) |
| Build the IP that backs the intake (eligibility, dedupe, address validation) | [sf-industry-commoncore-integration-procedure](../sf-industry-commoncore-integration-procedure/SKILL.md) |
| Author the Data Mapper (DataRaptor) used inside the IP | [sf-industry-commoncore-datamapper](../sf-industry-commoncore-datamapper/SKILL.md) |
| Build the FlexCard for Constituent 360 | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) |
| Implement Apex triggers / handlers on PSS objects | [sf-apex](../sf-apex/SKILL.md) |
| Build portal LWCs (only after confirming OmniScript / FlexCard cannot cover) | [sf-lwc](../sf-lwc/SKILL.md) |
| Record-triggered or screen Flows for simple automations | [sf-flow](../sf-flow/SKILL.md) |
| Named Credentials and integrations to external eligibility systems | [sf-integration](../sf-integration/SKILL.md) |
| Permission sets and constituent portal guest profile | [sf-permissions](../sf-permissions/SKILL.md) |
| Experience Cloud portal architecture and guest-access model | [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) (patterns transfer to PSS constituent portals) |
| Data Cloud unified-constituent profile and segmentation | [sf-datacloud](../sf-datacloud/SKILL.md) |
| **Non-governmental** (501c3 / foundation) grant management | [sf-nonprofit-grants](../sf-nonprofit-grants/SKILL.md) |
| Apex test execution and coverage verification | [sf-testing](../sf-testing/SKILL.md) |
| Deployment to sandbox / staging / production | [sf-deploy](../sf-deploy/SKILL.md) |

---

## Terminology

- **PSS** — Public Sector Solutions (the Salesforce Industries cloud for government)
- **Constituent** — an individual who interacts with the agency; modeled as a Person Account
- **CaseType** — PSS's regulated subclass of Case with program and statute metadata
- **Benefit** — a program-level benefit definition (SNAP, WIC, TANF, LIHEAP, unemployment)
- **BenefitAssignment** — eligibility record linking a constituent to a Benefit for a period
- **BenefitDisbursement** — an individual payment against a BenefitAssignment
- **BusinessLicense** — issued business or professional license
- **Permit** — issued permit (building, occupancy, event, environmental)
- **Inspection** — regulatory inspection record with checklist and violation linkage
- **RegulatoryCode** — a codified rule, statute, or ordinance
- **RegulatoryCodeViolation** — an observed violation of a RegulatoryCode during inspection or complaint
- **IndividualApplication** — an application filed by a constituent for a benefit, license, permit, or grant
- **Complaint** — a complaint filed by the public
- **FedRAMP** — Federal Risk and Authorization Management Program (Moderate / High boundary requirements)
- **Section 508** — US federal accessibility standard
- **WCAG 2.1 AA** — Web Content Accessibility Guidelines (most common public-sector target)
- **Flow Orchestration** — multi-stage, multi-stakeholder Flow execution framework (distinct from single-stage Flow)
- **OmniScript** — OmniStudio's guided digital intake framework
- **Person Account** — Salesforce record type that unifies Account and Contact for an individual
- **Government grant vs nonprofit grant** — same objects (IndividualApplication, FundingAward), different funder and compliance regime
