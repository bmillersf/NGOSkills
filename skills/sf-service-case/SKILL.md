---
name: sf-service-case
description: >
  Service Cloud Case data model, automation, and SLA skill. Owns Case record types,
  Case Teams, Case Comments & Emails, Web-to-Case, Email-to-Case, Assignment Rules,
  Escalation Rules, Auto-Response Rules, Entitlements, Milestones, SLA Processes,
  Service Contracts, Assets, Incident Management (Case → Incident → Problem), Case
  Merge, and Case Feed.
  TRIGGER when: user works on the Case object, says "add a Case record type", "wire
  up Email-to-Case", "configure Web-to-Case", "design escalation rules", "build an
  assignment rule for cases", "set up SLA on Case", "create an Entitlement Process",
  "configure Milestones for first-response / resolution", "attach Service Contracts
  to an Asset", "stand up Incident Management", "link Case to Incident", "enable
  Case Merge", "audit Case Teams", "design the Case Feed", "add Case Comments
  automation"; or any request that touches Case automation (assignment, escalation,
  auto-response), SLA objects (Entitlement, SlaProcess, MilestoneType, CaseMilestone,
  EntitlementContact, ContractLineItem, ServiceContract), Asset-Entitlement linkage,
  or the Incident / Problem / Change / Broadcast Alert object family.
  DO NOT TRIGGER when: the request is about Omni-Channel routing, Presence, Queues,
  Skills-Based or Attribute-Based Routing, Supervisor — even when the routed object
  is Case (use sf-service-omnichannel); Knowledge articles, article types, data
  categories, article-to-case — article model, not Case model (use sf-service-knowledge);
  Work Orders, Service Appointments, technician scheduling (use sf-field-service);
  an industry cloud is installed and the Case carries industry-specific record types
  or objects — defer via Phase 0 to sf-industry-fsc, sf-industry-health,
  sf-industry-education, sf-industry-public-sector, sf-field-service,
  sf-nonprofit-program-case, sf-nonprofit-cloud, sf-industry-manufacturing,
  sf-industry-consumer-goods, sf-industry-communications, sf-industry-media,
  sf-industry-energy; a multi-phase Service Cloud design spanning Case + Omni +
  Knowledge (use sf-service-cloud orchestrator); generic Sales Cloud pipeline
  (use sf-sales-cloud); Opportunity / Sales Engagement (use sf-sales-opportunity,
  sf-sales-engagement); Marketing email journeys (use sf-marketing-cloud-growth);
  Apex trigger on Case — come here for the data model, then route the code (use
  sf-apex); LWC rendering Case data (use sf-lwc); Flow XML authoring on Case
  (use sf-flow); Data Cloud pipeline sourcing Case (use sf-datacloud); Agentforce
  topics/actions on Case (use sf-ai-agentforce).
license: MIT
compatibility: "Requires Service Cloud user license; Entitlement Management, Service Contracts, and Incident Management are configured add-ons"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "120 points across 10 categories — Industry pre-check 15 / Channels+record-types 15 / Intake automation 15 / SLA Entitlements+Milestones 20 / Asset+Service Contract 10 / Escalation 10 / Case Teams 10 / Incident Management 10 / Merge+dedup 5 / Output+delegation 10 (95 is passing)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (10 categories) extracted from existing 'Scoring Rubric' section in this SKILL.md (line 233). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  service_case_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Industry pre-check + Case data model + intake. Maps to Industry pre-check (15) + Channels+record-types (15) + Intake automation (15). Phase 0 honored, record types justified, all intake channels (Email-to-Case mode + Web-to-Case + Assignment + Auto-Response) wired."
      automatic_hard_fail_rules:
        - "Phase 0 industry pre-check skipped — automatic fail per the rubric"
        - "Industry-owned Case record type silently overridden — automatic fail"
        - "Custom Parent/Child case hierarchy built when Incident Management is licensed (ad-hoc hierarchy doesn't survive RCA / broadcast / status-page)"
        - "Email-to-Case On-Premise chosen without attachment-size or firewall-policy justification (legacy mode; default is On-Demand)"
        - "Record-type sprawl — new Case record type per SKU/region instead of picklists + Dynamic Forms (reserve record types for genuinely distinct processes)"
    - name: Robustness
      max: 25
      hard_fail_below: 16
      description: "SLA design integrity. Maps to SLA Entitlements+Milestones (20) + Asset+Service Contract (10). Heaviest robustness floor — SLA breaches are contractual + auditable; Flow-based timers drift on Business Hours changes."
      automatic_hard_fail_rules:
        - "SLA timer rolled in Flow when Entitlement Milestone covers it (Flow timer skips Business Hours, misses Milestone Actions, can't be audited against Entitlement compliance reports)"
        - "Milestone completion criteria missing IsClosed=TRUE (or correct completion field) — Milestones start but never complete"
        - "Business Hours mismatch between Entitlement and its Milestones (timer drift)"
        - "Asset → Entitlement → Service Contract chain incomplete (or N/A not justified) when contracts are in scope"
        - "Auto-close via Apex after N days of no customer reply (hard auto-close hides true resolution metrics — staged Pending Customer Flow + reminders is the pattern)"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Escalation + Case Teams + Incident Management + Output. Maps to Escalation (10) + Case Teams (10) + Incident Management (10) + Output+delegation (10). Phase skills receive context; Case ↔ Incident ↔ Problem model documented; swarming decision made."
      automatic_hard_fail_rules:
        - "Escalation rules and Milestones overlap without precedence — both fire on the same SLA breach"
        - "Assignment Rules + Omni-Channel both run on Case without precedence contract (double-assignment + owner-churn)"
        - "Case Teams configured without role definitions / predefined teams (slot-shaped collaboration)"
        - "Incident Management licensed but case-to-incident escalation pattern not documented"
        - "ITSM sync contract missing when Incident Management bridges to external ServiceNow / Jira"
        - "Hand-off to sf-service-omnichannel / sf-service-knowledge / sf-apex / sf-flow without context"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Merge / dedup / close-out hygiene. Maps to Merge+dedup+close-out (5). Dedup rules + close-out quick action defined; Closed Reason / Resolution Summary required to maintain downstream reporting (FCR / RCA / product-area trending)."
      automatic_hard_fail_rules:
        - "Close Case quick action without required Closed Reason / Resolution Summary fields (destroys FCR + RCA + product-area trending)"
        - "Dedup rules absent on Email-to-Case (duplicate cases per inbound thread)"
        - "Case Merge disabled in an org with frequent duplicate inbound (manual merge burden + reporting drift)"
        - "Reports on Case without filter scoped to caseload (full-org scan when each agent owns a queue subset)"
  test_rubric:
    unit:
      required: true
      criteria: "Phase 0 industry pre-check executed. Case record types + intake channel + SLA design metadata validates. Entitlement→Milestone→CaseMilestone chain fields populated. Escalation rule entries ordered without overlap with Milestone Actions."
    integration:
      required: true
      criteria: "Deploys to a Service Cloud sandbox. Intake routes a test case through each configured channel (Email-to-Case / Web-to-Case / API). SLA Entitlement+Milestone fires correctly with Business Hours math. Case ↔ Incident link works (or marked N/A). Close Case quick action gates on required fields."
    smoke:
      required: true
      criteria: "Agent walks the case lifecycle: case received → SLA timer running → comments + emails captured → escalation if breached → resolution recorded → milestone completes → closure with Closed Reason/Summary. FCR + AHT + SLA-attainment metrics computable from the resulting records."
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.cases_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.entitlements_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.incidentmgmt_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.customize_escalationrules.htm
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_service_cases.htm
---

# sf-service-case: Case, Entitlements & Incidents

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 10 Case categories, extracted from this skill's existing Scoring Rubric section (line 233) and mapped onto the 4-dim shape. Robustness floor at 16 — SLA breaches are contractual + auditable; Flow-based timers drift on Business Hours changes. Hard-fail rules block Phase 0 skip, custom Parent/Child when Incident Management is licensed, Email-to-Case On-Premise without justification, Flow-rolled SLA timers when Entitlement Milestones cover the case, Assignment Rules + Omni-Channel both running without precedence, and Close Case action without required Closed Reason / Resolution Summary. Disable with `eval_harness.enabled: false`.

Owns the Case data model, Case automation, and the SLA family (Entitlements, Milestones, Service Contracts), plus native Incident Management when present. Comes after the [sf-service-cloud](../sf-service-cloud/SKILL.md) orchestrator has localized the work to this phase.

---

## When This Skill Owns the Task

Use `sf-service-case` when the work involves:

- Case object design: record types, page layouts, picklists, fields, validation rules, dependent layouts
- Case intake automation: Web-to-Case HTML form + SSL guard, Email-to-Case routing addresses + On-Demand vs On-Premise, Email Service handlers
- Case routing automation that runs at creation (Assignment Rules, Auto-Response Rules) — routing *after* creation that uses Omni-Channel belongs to [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md)
- Escalation Rules + Case Escalation Actions (reassign, notify, field update)
- Case Teams (role-based) and Case Team predefined membership
- Case Comments, Case Emails (EmailMessage + EmailRelation), Case Feed layout
- Entitlement Management: Entitlement, Entitlement Contact, Entitlement Process (= SlaProcess), Milestone Types, Case Milestones, Milestone Actions (time-triggered or evaluated), Business Hours + Holidays applied to SLAs
- Service Contracts + Contract Line Items + Assets, and which SLA a customer inherits based on the Asset they own
- Incident Management: Incident, Problem, Change, Broadcast Alert, Related Incident on Case, Incident-to-Problem promotion, RCA fields
- Case Merge (native, up to 3 cases), deduplication rules on Case, duplicate rules
- Case Hierarchy (Parent Case / Child Case) for swarming and multi-line incidents

### Delegate outside this skill when

| Need | Route to | Boundary |
|---|---|---|
| Routing by capacity / skills / attributes after creation | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Omni-Channel is a separate object surface |
| Knowledge articles surfaced on the Case | [sf-service-knowledge](../sf-service-knowledge/SKILL.md) | Article model lives there |
| Work Orders spawned from a Case | [sf-field-service](../sf-field-service/SKILL.md) | Field Service owns WorkOrder |
| Multi-phase Service Cloud design | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Orchestrator owns cross-phase decisions |
| Apex trigger / handler / batch on Case | [sf-apex](../sf-apex/SKILL.md) | This skill specifies the data model; sf-apex writes the code |
| Flow XML on Case | [sf-flow](../sf-flow/SKILL.md) | Name the triggering object here, build the flow there |
| LWC rendering on Case | [sf-lwc](../sf-lwc/SKILL.md) | Field list here, component there |
| Custom fields / object XML | [sf-metadata](../sf-metadata/SKILL.md) | After data model is locked |
| SOQL on Case / CaseMilestone / Incident | [sf-soql](../sf-soql/SKILL.md) | Query authoring only |
| Permission Set / FLS audit on Case | [sf-permissions](../sf-permissions/SKILL.md) | Access audit |
| Named Credential / ITSM callout for Incident sync | [sf-integration](../sf-integration/SKILL.md) | Wiring |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before any Case work, run the shared [industry pre-check](../../references/industry-precheck.md). Every generic cloud skill is required to run this pre-check; `sf-service-case` is no exception.

**NEVER silently override an industry data model.** If an industry cloud is installed AND the Case work touches industry-owned record types, objects, or processes, halt and forward to the industry skill.

### Deferral map for Case-adjacent industry ownership

| Detected industry | Case-adjacent objects/processes owned by the industry | Route to |
|---|---|---|
| Financial Services Cloud (`FinServ__`) | Case record types `FinServ__BankingCare` / `FinServ__WealthCare` / `FinServ__InsuranceCare`, Interaction / Interaction Summary, Compliant Data Sharing participants on Case | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) |
| Health Cloud (`HealthCloudGA__`) | CareRequest, Care Plan Case, Clinical Service Request, Patient/Member service cases, utilization-management cases | [sf-industry-health](../sf-industry-health/SKILL.md) |
| Education Cloud / EDA (`hed__`) | Student-service / advising Cases linked to Term / Course / Program Enrollment | [sf-industry-education](../sf-industry-education/SKILL.md) |
| Public Sector Solutions (`OutfundsPS__`) | BusinessLicense, Permit, Inspection, RegulatoryCodeViolation, IndividualApplication, Complaint-to-Case | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) |
| Field Service (`FieldServiceStandard`) | WorkOrder, WorkOrderLineItem, ServiceAppointment linked from Case | [sf-field-service](../sf-field-service/SKILL.md) |
| Nonprofit Cloud program/case (`NonprofitCloudCaseManagement`) | ProgramEnrollment-linked cases, CasePlan, Benefit, Goal (native NPC client case management) | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) |
| Nonprofit Cloud generic | Gift-Transaction-linked service cases, constituent-service case handling | [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) |
| Manufacturing Cloud (`Mfg`) | ManufacturingWorkOrder-linked cases, warranty / rebate-dispute cases, Sales Agreement disputes | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) |
| Consumer Goods Cloud (`CG`) | Retail Store Visit cases, Retail Execution dispute cases, Trade Promotion disputes | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) |
| Communications Cloud (`vlocity_cmt__`) | ESM-backed cases, order-management cases, number-management cases | [sf-industry-communications](../sf-industry-communications/SKILL.md) |
| Media Cloud (`vlocity_media__`) | Subscriber-service cases, entitlement-dispute cases, billing-account cases | [sf-industry-media](../sf-industry-media/SKILL.md) |
| Energy & Utilities (`vlocity_ins__` + `EnergyAndUtilities`) | Premise / Service Point cases, Meter-read disputes, Work Request service cases | [sf-industry-energy](../sf-industry-energy/SKILL.md) |

### Deferral procedure

1. Run detection per `references/industry-precheck.md`.
2. If positive AND the work touches any row above, print: `Detected {industry} is installed. Routing to sf-{industry-skill} because this request touches {matched object/process}.`
3. Halt and return control.
4. Only proceed if detection is negative, or the user explicitly says "use standard Case, bypass the industry overlay" (document the exception).

---

## Required Context to Gather First

1. **Case intake channels** — Email-to-Case, Web-to-Case, API, Messaging, Voice, Experience Cloud, social. Volumes by channel.
2. **Record-type topology** — existing Case record types, drivers (channel, product, severity, region), page layout per record type.
3. **Business Hours + Holidays** — which calendars exist and which are production-ready. Time zone alignment with SLAs.
4. **Entitlement model** — none / contract-driven / asset-driven / account-driven / user-driven. Number of SLA tiers.
5. **Milestone cadence** — FRT (first response), ART (agent response), resolution, customer-confirmed closure, custom checkpoints.
6. **Escalation model** — chronological (via Escalation Rules) and/or event-driven (via Flow / Apex). Who is notified at each step.
7. **Assignment model** — default owner, rule-based owner at creation, Omni-Channel push after creation, or a hybrid.
8. **Incident Management** — native (Incident + Problem) in scope, external ITSM (Jira Service Management / ServiceNow), or none.
9. **Case swarming** — Slack Swarming, case team predefined membership, case hierarchy, none.
10. **Case Merge** — enabled, 3-case limit, dedup rules in play.
11. **Asset + Service Contract model** — covered products/subscriptions, asset ownership, contract renewal cadence.
12. **Compliance** — PCI-in-Case (avoid storing card data), HIPAA (PHI tagging, audit trail), GDPR/CCPA (subject request handling on Case).

---

## Workflow Phases

### Phase 1 — Pre-Check & Scope Lock

1. Run **Phase 0 industry pre-check**. Halt and forward if positive.
2. Confirm channel mix, record-type topology, SLA posture (context items 1–5).
3. Decide whether this work is standalone or upstream orchestrated by [sf-service-cloud](../sf-service-cloud/SKILL.md).

### Phase 2 — Case Object Design

1. Lock record types and drivers. Prefer fewer record types × more Dynamic Forms over record-type sprawl.
2. Design the Case Feed layout (publisher actions: Log a Call, Email, Comment, Quick Actions for status transitions).
3. Define required fields at each stage (validation rules gated by `ISPICKVAL(Status, ...)`).
4. Define Dependent Picklists (Type → Subtype → Issue Category) and Dynamic Forms visibility rules.

### Phase 3 — Intake Automation

1. Choose Email-to-Case mode: Standard (on-platform) vs On-Demand (recommended for most, no server agent required). Configure routing addresses, reply-to alignment, attachment mapping.
2. Choose Web-to-Case: HTML form, spam filter, reCAPTCHA, daily limit (default 5,000).
3. Configure Auto-Response Rules (up to 25 entries per rule, first matching entry wins).
4. Configure Assignment Rules (1 active rule per object; rule entries matter; last entry catches everything).
5. Decide how Omni-Channel interacts with Assignment Rules (Omni can override Assignment Rule by reassigning to a queue the rule targeted). Coordinate with [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md).

### Phase 4 — SLA: Entitlement Processes & Milestones

1. Map SLA tiers → Entitlement → Entitlement Process (SlaProcess metadata) → Milestones.
2. Define Milestone Types: FRT, ART, Resolution, custom checkpoints.
3. For each Milestone: recurrence, Business Hours, time trigger, success criteria, violation actions.
4. Configure Milestone Actions (Success / Violation / Warning) as field updates, email alerts, or invocable flows.
5. Decide Entitlement propagation: manual on Case, auto-populated from Account / Asset / Contract via Flow or Apex trigger. Prefer Flow-driven auto-population with a clear Asset → Entitlement lookup.
6. Wire Business Hours + Holiday calendar into the Entitlement Process.
7. Test: open a Case under each SLA tier, verify Milestone clock starts, pauses on status change (if paused), and respects Business Hours.

### Phase 5 — Assets + Service Contracts

1. Decide whether Assets are imported (serial-numbered products) or synthetic (software subscriptions).
2. Design Service Contract → Contract Line Item → Asset linkage.
3. Wire Entitlement to Contract Line Item so a customer's covered period drives SLA.
4. Plan renewal automation (Flow reminders at T-90/60/30 days, auto-expire past due).

### Phase 6 — Escalation Rules

1. Define escalation entries (filter criteria + time trigger). Only one active Escalation Rule per org; entries are the variance.
2. Decide escalation actions: reassign, notify, field update. Avoid chaining multiple field updates into a single entry — split into ordered entries.
3. Coordinate with Milestones — an Escalation Rule firing the same alert a Milestone already fired is noise. Pick one owner per signal.
4. Plan escalation dashboards (overdue cases by tier, by team).

### Phase 7 — Case Teams + Collaboration

1. Define Case Team Roles (Primary Owner, SME, Reviewer, etc.) and their access levels.
2. Configure Predefined Case Teams to auto-attach on record-type match.
3. Decide on Slack Swarming (requires Slack-Salesforce connector + Service Cloud SKU that includes swarming).
4. Plan case hierarchy (Parent/Child) for multi-line incidents; consider moving Parent/Child to Incident Management if the org has licensed it.

### Phase 8 — Incident Management (if in scope)

1. Confirm Incident Management is enabled (`Incident`, `Problem`, `Change`, `BroadcastAlert`, `RelatedIncident` objects exist).
2. Design Case → Incident linkage model (many-to-one via `RelatedIncident`). Support agents create/link; major-incident managers own the Incident.
3. Design Incident → Problem promotion for recurring root causes.
4. Plan Broadcast Alerts for customer-facing impact; wire status page integration via Named Credential (delegate wiring to [sf-integration](../sf-integration/SKILL.md)).
5. Define the major-incident runbook: detection → Incident → Broadcast → postmortem → Problem → Change.
6. If external ITSM (ServiceNow / Jira Service Management), design the two-way sync contract (case creation, status updates, resolution notes); delegate wiring to [sf-integration](../sf-integration/SKILL.md).

### Phase 9 — Case Merge, Dedup & Close-Out

1. Enable Case Merge (3-case limit). Train on when to merge vs link vs parent/child.
2. Configure Duplicate Rules on Case (by Contact + Subject match within N days).
3. Define close-out required fields (Closed Reason, Resolution Summary, Root Cause Category, Product Area) via a Quick Action with validation.
4. Plan Case reopening rules (Closed → Reopen transition, SLA behavior on reopen).

### Phase 10 — Verify & Hand Off

1. Smoke-test each flow end-to-end: create case via each channel, verify SLA starts, assignment fires, auto-response sends, escalation timer begins, merge works.
2. Document SLA tier → Entitlement → Milestone map.
3. Hand off to [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) for routing-after-creation and to [sf-service-knowledge](../sf-service-knowledge/SKILL.md) for article attachment.

---

## Scoring Rubric (120 points total — 95 is passing)

| Category | Max | Pass threshold | What earns points |
|---|---|---|---|
| Industry pre-check executed and documented | 15 | 12 | Detection ran; deferral decision explicit |
| Case channels + record-type topology | 15 | 11 | All intake channels mapped; record types justified |
| Intake automation correct | 15 | 11 | Email-to-Case mode chosen, Web-to-Case hardened, Assignment + Auto-Response wired |
| SLA design (Entitlements + Milestones) | 20 | 15 | Tiers mapped; Business Hours correct; violation/success actions defined |
| Asset + Service Contract linkage | 10 | 7 | Contract-line-item → Asset → Entitlement chain complete (or marked N/A) |
| Escalation model | 10 | 7 | No overlap with Milestones; entries ordered; actions scoped |
| Case Teams + collaboration | 10 | 7 | Roles defined; predefined teams configured; swarming decision made |
| Incident Management | 10 | 7 | Case ↔ Incident ↔ Problem model documented; ITSM sync contract if external |
| Merge, dedup, close-out | 5 | 4 | Dedup rules + close-out quick action defined |
| Output + delegation correct | 10 | 7 | Correct hand-offs to omnichannel, knowledge, apex, flow |

Fail gates: Phase 0 skipped = automatic fail. Silent override of an industry Case record type = automatic fail.

---

## Anti-Patterns

1. **Skipping Phase 0.** Touching Case record types or SLAs on an FSC / Health / Education / PSS / NPC / FSL / Mfg / CG / Comms / Media / Energy org without first routing to the industry skill.
2. **Rolling an SLA timer in Flow that already exists as an Entitlement Milestone.** Flow-based FRT/ART/Resolution timers skip Business Hours logic, miss Milestone Actions, and can't be audited against Entitlement compliance reports.
3. **Record-type sprawl.** Creating a new Case record type for every product SKU or region. Drive variation with picklists + Dynamic Forms; reserve record types for genuinely distinct *processes*.
4. **Email-to-Case On-Premise without need.** On-Premise requires a listener process and is legacy; prefer On-Demand unless attachment-size or firewall policy explicitly forces On-Premise.
5. **Running Assignment Rules and Omni-Channel on the same object without a precedence contract.** Either Assignment Rule sets the queue and Omni-Channel routes from that queue, or Omni-Channel owns all routing — mixing both without rules causes double-assignment and owner-churn.
6. **Building custom Parent/Child case hierarchy when Incident Management is licensed.** Incident Management exists because ad-hoc Parent/Child doesn't survive RCA, broadcast, or status-page workflows.
7. **Auto-closing cases via Apex after N days of no customer reply.** Prefer a staged Flow with `Pending Customer` status + reminder emails + Milestone-driven pause/resume. Hard auto-close hides true resolution metrics.
8. **Forgetting to gate the Close Case quick action with required fields.** Missing Closed Reason / Resolution Summary destroys downstream reporting (root-cause analysis, product-area trending, FCR calculations).

---

## Common Failure Modes + Remediation

### Symptom: "Milestones never complete when the case closes"

- **Root cause:** Milestone completion criteria reference a custom field that isn't updated at close, or Business Hours mismatch between Entitlement Process and Milestone.
- **Fix:** Set completion criteria to include `IsClosed = TRUE`; confirm Business Hours match on the Entitlement Process. Re-test on a sample Case.

### Symptom: "Escalation Rule never fires"

- **Root cause:** Rule entry filter references a field that's blank at creation, or Business Hours not applied, or Case status is in a "paused" state that doesn't age the entry timer.
- **Fix:** Audit the entry filter; confirm the rule is Active; confirm the Case's Business Hours field is populated (escalation aging uses that field, not the record's own Business Hours).

### Symptom: "Assignment Rule assigns to a queue; Omni-Channel then reassigns to a different one"

- **Root cause:** The Assignment Rule's target queue is not the same as the Omni-Channel Routing Configuration's source queue.
- **Fix:** Align Assignment Rule target queues with Omni-Channel source queues, or disable Assignment Rules on the record types that Omni-Channel routes.

### Symptom: "Entitlement lookup on Case is null even when the Account has an active Entitlement"

- **Root cause:** Entitlement is linked to an Asset or Contract that isn't on the Case; Salesforce does not auto-copy the Account's Entitlement to every Case.
- **Fix:** Build a before-insert Flow or Apex handler that resolves Case.Account → active Entitlement → sets `EntitlementId`. Document precedence when multiple Entitlements match.

### Symptom: "Case Merge loses custom field values on the losing records"

- **Root cause:** Case Merge only preserves the master record's field values; it does not combine custom field values across merged records.
- **Fix:** Before merge, capture the losing records' custom field values into a merged note or long-text field on the master; document the merge loss in your runbook.

---

## CLI / Metadata Cheat Sheet

```bash
# Case + SLA inspection
sf data query -q "SELECT Id, Subject, Status, EntitlementId, MilestoneStatus FROM Case LIMIT 20" -o <alias>
sf data query -q "SELECT Id, CaseId, MilestoneTypeId, IsCompleted, IsViolated FROM CaseMilestone ORDER BY StartDate DESC LIMIT 50" -o <alias>
sf data query -q "SELECT Id, Name, Type, Status FROM Entitlement LIMIT 20" -o <alias>
sf data query -q "SELECT Id, Name, NumberOfVersions FROM SlaProcess" -o <alias>
sf data query -q "SELECT Id, Name FROM MilestoneType" -o <alias>

# Incident Management inspection
sf data query -q "SELECT Id, IncidentNumber, Severity, Status FROM Incident LIMIT 20" -o <alias>
sf data query -q "SELECT Id, CaseId, IncidentId FROM CaseRelatedIncident LIMIT 20" -o <alias>
sf data query -q "SELECT Id, Subject, Status FROM Problem LIMIT 10" -o <alias>

# Service Contracts / Assets
sf data query -q "SELECT Id, Name, AccountId, Status FROM ServiceContract LIMIT 20" -o <alias>
sf data query -q "SELECT Id, Name, AccountId, SerialNumber, Status FROM Asset LIMIT 20" -o <alias>

# Metadata retrieval for review
sf project retrieve start -m "CustomObject:Case,CustomObject:Incident,CustomObject:Problem,Entitlement:*,SlaProcess:*,MilestoneType:*,AssignmentRules:Case,AutoResponseRules:Case,EscalationRules:Case" -o <alias>
```

Key metadata file families:

- `objects/Case/recordTypes/*.recordType-meta.xml`
- `objects/Case/validationRules/*.validationRule-meta.xml`
- `objects/Entitlement/*.object-meta.xml`
- `slaProcesses/*.slaProcess-meta.xml`
- `assignmentRules/Case.assignmentRules-meta.xml`
- `autoResponseRules/Case.autoResponseRules-meta.xml`
- `escalationRules/Case.escalationRules-meta.xml`
- `quickActions/Case.*.quickAction-meta.xml`
- `businessHoursSettings/*.businessHoursSettings-meta.xml`
- `objects/Incident/*.object-meta.xml`
- `objects/Problem/*.object-meta.xml`
- `objects/ServiceContract/*.object-meta.xml`

---

## Output Format

```text
Case task: <intake / SLA / incident / escalation / merge / close-out>
Industry pre-check: <negative / positive → deferred to sf-{industry-skill}>
Record types in scope: <list>
SLA model: <entitlement / contract / asset-driven / hybrid>
Milestones: <FRT / ART / Resolution / custom>
Incident Management: <native / external-ITSM / none>
Escalation model: <rule-based / flow-based / hybrid>
Assignment vs Omni-Channel precedence: <declared>
Open risks / assumptions: <list>
Next step: <hand-off to sf-service-omnichannel / sf-service-knowledge / sf-apex / sf-integration>
```
