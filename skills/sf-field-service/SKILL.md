---
name: sf-field-service
description: >
  Salesforce Field Service architecture for work orders, scheduling, and mobile workforce.
  TRIGGER when: user designs or troubleshoots a Field Service implementation and says things
  like "create a work order", "schedule a service appointment", "dispatcher console
  configuration", "mobile app workflow for field technicians", "service territory design",
  "skill-based scheduling", "preventive maintenance plan", "scheduling optimization policy",
  "resource absence management", "emergency scheduling", "multi-day work order", "enhanced
  scheduling and optimization (ESO)", "appointment booking for customers", "service crew
  setup", "offline mobile flow for technicians", or "work type vs work type group";
  also triggers on "FSL" (the legacy name for Field Service) and any request that touches
  WorkOrder, ServiceAppointment, ServiceResource, ServiceTerritory, SchedulingPolicy,
  MaintenancePlan, or Asset in a mobile-workforce context.
  DO NOT TRIGGER when: the work is a non-work-order Case in Service Cloud with no dispatch
  component (use sf-service-cloud or sf-service-case); the user is writing generic Apex
  triggers or classes unrelated to Field Service dispatch logic (use sf-apex); the user
  is building a generic Lightning Web Component with no Field Service object binding
  (use sf-lwc); the user is authoring a Flow that does not touch Field Service objects
  (use sf-flow); the user is in a Sales Cloud opportunity/quote flow with no post-sale
  service component (use sf-sales-cloud); the org is running Home Health visits on
  Health Cloud's Visit/Care Plan model rather than Field Service objects (use
  sf-industry-health); the user is running regulatory inspections in a government context
  on Public Sector Solutions' Inspection object (use sf-industry-public-sector);
  the user is ingesting Field Service telemetry into a unified profile or building
  segments (use sf-datacloud).
license: MIT
compatibility: "Requires Field Service managed package + Field Service user licenses (Dispatcher, Technician, Mobile)"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "140 points across 7 categories — Data model 25 / Scheduling policy 25 / Dispatcher UX 20 / Mobile offline 25 / Asset+Maintenance 15 / External integration 15 / Testing 15 (105 is passing)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "140-pt rubric (7 categories) extracted from existing 'Scoring Rubric — 140 Points' section in this SKILL.md (line 200). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  field_service_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 18
      description: "Field Service data model + Asset/Maintenance integration. Maps to Data model (25) + Asset+Maintenance (15). Heaviest correctness floor — Case-as-Work-Order is the dominant defect, and it's permanent (breaks scheduling forever)."
      automatic_hard_fail_rules:
        - "Field work modeled on Case instead of Work Order (the moment work has duration / resource / location / asset, it's a Work Order — Case fields can't duplicate the FS data model without breaking scheduling)"
        - "Work Order without WOLI breakdown when the work has multiple line items (atomic work isn't dispatchable)"
        - "ServiceAppointment without Service Resource link or with wrong territory (dispatcher can't see / route)"
        - "Asset not linked to Work Order when service history matters (service history doesn't roll up; Maintenance Plans can't generate)"
        - "Maintenance Plan + Maintenance Work Rules generating Work Orders against wrong work-type template (maintenance vs corrective intent mismatch)"
        - "Skills + Skill Levels not modeled when scheduling depends on certifications"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Mobile offline correctness + integration robustness. Maps to Mobile offline (25) + External integration (15). The mobile app has a different runtime + priming model; offline failure mode is the dominant production incident."
      automatic_hard_fail_rules:
        - "Briefcase priming not defined per persona (technicians prime everything or nothing — too much data or empty offline)"
        - "Custom LWC / Quick Action used in mobile context without offline-safe verification"
        - "Service report layout undefined for the work-type templates (technician can't close out work)"
        - "Mobile testing skipped — desktop-only verification on a feature that runs on mobile"
        - "Mobile offline window not tested for the longest realistic interval (e.g., 8h shift in dead-zone — fails at 4h)"
        - "Synchronous callout in a Work Order / ServiceAppointment trigger (governor-limit exposure on bulk dispatch)"
        - "External Services / Named Credentials not used for third-party scheduling / inventory / billing (auth-in-code or stale OAuth tokens)"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Scheduling policy fit + Dispatcher UX. Maps to Scheduling policy (25) + Dispatcher UX (20). Work Rules + Service Objectives over custom Apex; Gantt views scoped by territory + role; ESO configured if licensed."
      automatic_hard_fail_rules:
        - "Custom dispatcher Apex when Work Rules + Service Objectives express the constraint (custom Apex bypasses the optimizer, can't participate in ESO, impossible to tune)"
        - "Multiple Scheduling Policies for the same scenario (one policy per scenario — overlap = unpredictable assignment)"
        - "ESO licensed but not configured (paying for the optimizer + leaving it off)"
        - "Gantt views unscoped by territory + role (dispatchers see out-of-scope appointments — operational chaos)"
        - "Custom Gantt actions used when standard configuration covers the need (technical debt + future-release breakage)"
        - "Map layers not configured for territory / region / customer-density (dispatcher can't make geographic routing decisions)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Testing coverage. Maps to Testing (15). Apex unit tests for custom logic, scheduling-policy tests with expected outcomes, mobile offline tested on device, end-to-end scenarios + regression."
      automatic_hard_fail_rules:
        - "Apex unit tests missing on custom dispatch / WO automation"
        - "Scheduling-policy tests missing with no documented expected outcomes (next dispatcher-experienced edge case fails silently)"
        - "Mobile testing skipped on real device with airplane mode"
        - "End-to-end scenario tests absent (Work Order created → scheduled → dispatched → completed → service-report path untested)"
        - "Regression path undefined for production releases"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.fs_admin_intro.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/field-service
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_field_service.htm
---

# sf-field-service: Salesforce Field Service Orchestrator

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 140-pt rubric across 7 Field Service categories, extracted from this skill's existing Scoring Rubric section (line 200) and mapped onto the 4-dim shape. Correctness floor at 18 — Case-as-Work-Order is the dominant defect, and it's permanent (breaks scheduling forever). Hard-fail rules block Case-as-Work-Order, missing Briefcase priming per persona, custom dispatcher Apex when Work Rules + Service Objectives express the constraint, multiple Scheduling Policies per scenario, ESO licensed but not configured, Gantt views unscoped by territory/role, and synchronous callouts in WO/SA triggers. Disable with `eval_harness.enabled: false`.

Use this skill when the user is designing, configuring, or troubleshooting a Salesforce Field Service deployment — work orders, service appointments, dispatcher console, scheduling policies, mobile technician flows, preventive maintenance, and asset servicing. Field Service is an **industry-like product layer** on top of Service Cloud; this skill is the authoritative entry point whenever a Work Order, Service Appointment, or Service Resource is in scope.

This skill is the pre-check's destination for field-workforce scenarios. It does **not** run `references/industry-precheck.md` — it is already downstream of that gate.

---

## 1. When This Skill Owns the Task

This skill owns any request that touches the Field Service data model, scheduling engine, dispatcher experience, mobile offline workflow, or asset/maintenance lifecycle. It applies the moment Work Orders or Service Appointments are the system of record for the work being performed.

Delegate to another skill when the task is outside that surface:

| User need | Route to | Why |
|---|---|---|
| Non-dispatch Case management (inbound support, email-to-case, entitlements without field visits) | [sf-service-case](../sf-service-case/SKILL.md) | Case is the owner; no Work Order involved |
| Service Cloud orchestration outside field work (omnichannel routing, knowledge, chat) | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Field Service is a different product layer |
| Generic Apex triggers, batch/queueable, test classes unrelated to dispatch | [sf-apex](../sf-apex/SKILL.md) | Platform code with no Field Service data binding |
| Generic LWC components not bound to Field Service objects | [sf-lwc](../sf-lwc/SKILL.md) | UI primitive, not a Field Service surface |
| Flow XML that does not touch WorkOrder / ServiceAppointment | [sf-flow](../sf-flow/SKILL.md) | Generic declarative automation |
| Sales Cloud opportunity-to-cash before service is scheduled | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) | Pre-sale, not post-sale service |
| Home Health visits on Health Cloud Visit / Care Plan objects | [sf-industry-health](../sf-industry-health/SKILL.md) | Health Cloud owns care-plan-driven visits |
| Government / public sector inspections on PSS Inspection object | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) | PSS owns regulatory inspection lifecycles |
| Ingesting Field Service telemetry into unified profiles, segments, activations | [sf-datacloud](../sf-datacloud/SKILL.md) | Different runtime (Data Cloud), downstream of Field Service |

If the user asks "should I use a Case or a Work Order for this?", the answer lives in this skill's **Precedence note** below.

---

## 2. Precedence Note — Field Service Wins Over Generic Service

When any of the following are true, this skill supersedes `sf-service-cloud` and `sf-service-case`:

1. Work Orders (or Work Order Line Items) are involved — even if a Case is the originating record.
2. A Service Appointment needs to be scheduled, dispatched, or optimized.
3. A Service Resource (technician, crew, contractor, equipment) must be assigned.
4. The work is performed in the field, in a customer location, or against an Asset.
5. The user asks for Dispatcher Console, Appointment Booking, Scheduling Policy, or ESO (Enhanced Scheduling and Optimization) behaviour.
6. The mobile Field Service app (technician offline flow) is part of the scope.

The common mistake this supersession prevents: modeling a truck-roll or on-site visit as a plain Case with custom fields. Cases answer "what is the customer asking about?" Work Orders answer "what work will be performed, by whom, where, when, with which parts, against which asset, to which SLA?" Once any of those latter attributes appear, the correct object is Work Order and the correct skill is `sf-field-service`.

A Case **can** be the originator (customer called in, agent triaged it) — the flow is Case → Work Order → Work Order Line Items → Service Appointment(s). The Case stays open until the Work Order is closed, but the Field Service data model owns the work.

---

## 3. Required Context to Gather First

Before designing anything, establish:

- **License mix.** How many Dispatcher licenses? How many Technician (mobile) licenses? How many view-only users? Field Service licenses are separately purchased from Service Cloud seats and gate access to the Dispatcher Console and the Field Service Mobile App.
- **Scheduling engine in use.** Is Enhanced Scheduling and Optimization (ESO) enabled? If not, is the legacy Optimization in use, or is the customer on manual/drag-and-drop scheduling only? The design differs materially.
- **Territory complexity.** One country, one territory? Multi-country with time zones, operating hours, and parent/child territory hierarchies? Cross-territory scheduling allowed?
- **Offline mobile scope.** Which record types must be fully offline-capable (Work Order, Service Appointment, Asset, parts/inventory lookup)? What is the longest expected offline window? Which pages in the mobile app are custom vs. standard?
- **Asset / Maintenance scope.** Does the customer service installed Assets? Are Maintenance Plans (preventive maintenance) in scope, or is this reactive work only?
- **Third-party integrations.** Scheduling systems (ClickSoftware migration, ServiceMax), inventory/parts systems, GPS/telematics, customer notification channels (SMS via Digital Engagement, email, WhatsApp), and CPQ/billing downstream of Work Order completion.
- **Customer-facing booking.** Is Appointment Booking exposed to end customers (Experience Cloud, website widget), or is scheduling internal-only?
- **AI Scheduling / Visual Remote Assistant.** Are these features licensed and targeted for this rollout, or out of scope?

Missing any of the first four is a design-blocking gap. Ask or infer from the org (License Management Setup page, ESO enablement flag, Service Territory list, Field Service Mobile Settings) before proceeding.

---

## 4. Workflow Phases

Run these in order. Do not skip ahead — later phases assume earlier phases are stable.

### Phase 1 — Persona and License Scoping

1. Enumerate the personas: Dispatcher, Field Technician (mobile), Service Manager, Contact Center Agent, Customer (if Appointment Booking is exposed), Administrator.
2. Map each persona to a Field Service license type (Dispatcher, Technician/Mobile, Contractor, Contractor Plus) and identify which require Service Cloud licenses underneath.
3. Confirm the permission set licenses are available in the target org (`Field Service Dispatcher License`, `Field Service Mobile License`, `Field Service Scheduling License` for ESO, etc.).
4. Assign permission sets from the Field Service managed package (`FSL Dispatcher`, `FSL Resource`, `FSL Admin`, `FSL Agent`, etc.) as the baseline, then layer a custom permission set for org-specific tweaks. Never edit the managed-package permission sets directly.
5. Output: a persona-to-license-to-permission-set table. This becomes the access matrix for deployment.

### Phase 2 — Core Data Model

Design in this order, top-down:

1. **WorkType** and **WorkTypeGroup** — the templates. Define duration, skills required, default Work Order Line Items, and which Work Type Group each belongs to (for Appointment Booking grouping).
2. **WorkOrder** — the parent record. Decide whether Work Orders are created from Cases (Service Cloud → Field Service), from Assets (preventive maintenance), from Opportunities (install after sale), or directly.
3. **WorkOrderLineItem** — the granular work. Each line item can have its own Service Appointment; multi-visit jobs use multiple line items or multi-day scheduling.
4. **ServiceAppointment** — the schedulable unit. One Work Order or Work Order Line Item can have many. This is what the scheduling engine actually optimizes against.
5. **ServiceResource** — people (User-based), crews (ServiceCrew-based), contractors, or equipment (Asset-based resources). Each ServiceResource has ServiceTerritoryMember records that define where and when they can work.
6. **ServiceTerritory** — geographic + operating-hours + time-zone container. Can be hierarchical.
7. **ServiceCrew** and **ServiceCrewMember** — for multi-person appointments.
8. **Skill** + **ServiceResourceSkill** + required-skill junctions on Work Types / Work Orders / Service Appointments — the skill matching inputs.
9. **Asset** — the thing being serviced. Link Work Orders to Assets so service history rolls up.
10. **Product / ProductRequired / ProductConsumed** — parts and consumption, with ProductRequest and ProductTransfer for inventory movement between van stock, warehouses, and customer sites.

Output: an ERD (delegate to `sf-diagram-mermaid`) showing WorkOrder → WorkOrderLineItem → ServiceAppointment as the spine, with ServiceResource / ServiceTerritory / Skill / Asset hanging off it.

### Phase 3 — Scheduling Policy Design

Scheduling policies are the brain. Do not write custom Apex to replace what a Scheduling Policy can express.

1. Identify the business priorities in plain English (e.g., "minimize travel", "respect SLA", "balance workload", "prefer preferred resource", "emergency first"). Rank them.
2. Translate each into Work Rules (hard constraints — time, skills, territory, working hours, resource availability) and Service Objectives (soft preferences — weighted: travel time, overtime cost, customer preference, appointment grade).
3. Create one Scheduling Policy per meaningful business scenario: e.g., `Customer-First`, `Travel-Optimized`, `Emergency`, `High-Intensity-Scheduling`.
4. If ESO is enabled, configure the Enhanced Scheduling settings (resource-based, appointment-based) and set optimization frequency (continuous, scheduled, on-demand).
5. If multi-day scheduling is in scope (appointments spanning > 1 working day, e.g., installs), enable Multi-Day Service Appointments and configure the policy to respect daily capacity limits.
6. Configure Appointment Booking for the policies that back customer-facing booking. Grade slots so better-scoring slots surface first.

Output: a scheduling-policy matrix — rows are business scenarios, columns are the work rules and service objectives applied.

### Phase 4 — Dispatcher Console Configuration

1. Define the Gantt list views the dispatcher will live in (by territory, by status, by priority). Set the default list view per dispatcher persona.
2. Configure the map layers (resources, appointments, territories, traffic) and default map center.
3. Configure the appointment list columns, resource list columns, and custom actions (e.g., "Send arrival SMS", "Mark emergency").
4. Set up filtering: territory-scoped, role-scoped, policy-scoped. Dispatchers should never see appointments outside their territories by default.
5. Configure drag-and-drop behaviour (pin to resource, cascade follow-up appointments, honor travel-time recalculation).
6. Add custom Lightning components on the Dispatcher Console page only if standard features cannot express the need. Custom dispatcher code is a last resort.

### Phase 5 — Mobile App Offline Configuration

The mobile app is a different client — do not assume desktop UX carries over.

1. Enumerate every record type the technician needs offline: Work Order, Work Order Line Item, Service Appointment, Asset, Contact, Account, Product, ProductRequired, ProductConsumed, and any custom objects (e.g., inspection checklists).
2. Configure **Briefcase** (or legacy Field Service priming) to prime records: by territory, by assigned technician, time-windowed (e.g., "today + 7 days").
3. Define Mobile Quick Actions and Lightning Web Components that are offline-safe. LWCs on the mobile app must handle the offline case (no callouts, no Apex that hits the network).
4. Configure Service Report templates (branded PDF of work completed, customer signature capture).
5. Configure geotracking, travel tracking (enroute / on-site / completed status transitions), and time-sheet auto-population.
6. Test offline flows on a real device, in airplane mode, for the longest expected offline window. Desktop or simulator testing does not substitute.

### Phase 6 — Asset and Maintenance Plan (If Applicable)

If the customer services installed Assets:

1. Model the Asset hierarchy (parent assets, child components) if relevant.
2. For preventive maintenance, create **Maintenance Plans** with **Maintenance Work Rules** that define frequency (calendar-based, usage-based) and auto-generate Work Orders on a schedule.
3. Link Maintenance Plans to Assets (and optionally to Contract Line Items for entitlement-driven maintenance).
4. Configure the batch that generates upcoming Work Orders (generation horizon — e.g., 90 days out).
5. Confirm the Work Type referenced by each Maintenance Work Rule has the correct duration, skills, and line-item templates.

### Phase 7 — Testing

1. **Unit tests** for any custom Apex triggers/classes on Work Order, Service Appointment, or scheduling-related logic (route to `sf-testing`).
2. **Scheduling-policy tests** — schedule N test appointments against each policy and verify the expected resource/time selection. Document the expected outcomes; do not rely on the live engine to "look right".
3. **Desktop UX walk-through** — dispatcher drags, assigns, reassigns, handles emergency insertion, handles absence insertion.
4. **Mobile offline tests** — on device, airplane mode, cold start, record create/update, attach photo, capture signature, go online, verify sync.
5. **End-to-end scenario tests** — happy path (Case → Work Order → Scheduled → Dispatched → Enroute → On-site → Completed → Closed), emergency path (unscheduled emergency, reassignment), and failure paths (technician marks Cannot Complete, customer reschedules, parts not available).
6. **Integration tests** — if downstream systems consume Work Order completion (billing, CPQ), confirm the event payload.
7. **Regression** — run the Playwright pre-flight if this rollout is demoable (route to `sf-demo-playwright`).

---

## 5. Scoring Rubric — 140 Points

Apply to any Field Service design or build deliverable. Minimum passing: **105 / 140**. Below that, revise before handing off.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Data model correctness** | 25 | 20 | Work Order / WOLI / Service Appointment spine modelled; ServiceResource / Territory / Skill / Asset linked correctly; no Case-as-Work-Order mistakes |
| **Scheduling policy fit** | 25 | 19 | Work Rules and Service Objectives expressed declaratively; one policy per scenario; no custom Apex replicating standard scheduling behaviour; ESO configured if licensed |
| **Dispatcher UX** | 20 | 15 | Gantt views scoped by territory and role; map layers configured; custom actions only where standard cannot express; dispatchers cannot see out-of-scope appointments |
| **Mobile offline correctness** | 25 | 19 | Briefcase priming defined per persona; offline-safe LWCs and Quick Actions; service reports configured; tested on real device in airplane mode for the longest realistic offline window |
| **Asset / Maintenance integration** | 15 | 11 | Assets linked to Work Orders; service history rolls up; Maintenance Plans + Maintenance Work Rules generate Work Orders on schedule; work-type templates match maintenance intent |
| **Integration with external systems** | 15 | 11 | Named Credentials / External Services set up for third-party scheduling/inventory/billing; Platform Events or CDC used for async notifications; no synchronous callouts in triggers |
| **Testing coverage** | 15 | 11 | Apex unit tests for custom logic; scheduling-policy tests with documented expected outcomes; mobile offline tested on device; end-to-end scenario tests; regression path defined |

Sub-threshold categories must be fixed before the deliverable is considered complete, even if the total exceeds 105.

---

## 6. Anti-Patterns

- **Using Case instead of Work Order for field work.** Cases are inbound inquiries. The moment the work has a duration, a resource, a location, or an asset, it is a Work Order. Storing field work on Case forces custom fields that duplicate the Field Service data model and breaks scheduling forever.
- **Writing custom dispatcher Apex when Scheduling Policy handles it.** Work Rules + Service Objectives can express almost every real-world constraint (skill match, territory, time, overtime, travel, preferred resource, SLA). Custom Apex that picks the resource bypasses the optimizer, cannot participate in ESO, and is impossible to tune later.
- **Skipping mobile offline testing because desktop UX passed.** The mobile app has a different client, a different LWC runtime, a different priming model, and a different Lightning component offline contract. A feature that works on desktop can and will fail on mobile. Always test on a real device, in airplane mode, for the longest realistic offline window.
- **Ignoring ESO optimization when scheduling > 50 appointments/day.** Manual or first-available scheduling does not scale. Enhanced Scheduling and Optimization exists because manually-dispatched routes have catastrophic travel-time waste above the ~50 appointments/day threshold. If the customer is licensed for ESO and at that volume, use it.
- **One Scheduling Policy for all scenarios.** Emergency, preventive-maintenance, customer-first-booking, and cost-optimized routing have different weights. Collapsing them into one policy means every scenario gets a mediocre compromise.
- **Over-priming the mobile app.** Priming every record for every technician produces a multi-gigabyte offline cache and slow sync. Prime what the technician needs for the scheduled horizon (e.g., today + 7 days) filtered by assigned Service Appointments, not the whole territory.
- **Linking Work Orders to Accounts but not to Assets.** Without the Asset link, service history does not roll up to the installed equipment, preventive maintenance cannot be driven by the asset, and warranty / entitlement lookups break. Always link to Asset when an asset is in scope.
- **Treating `FSL` and `Field Service` as different products.** They are the same product; FSL (Field Service Lightning) is the legacy brand. If a user says "FSL", do not route them elsewhere.
- **Building custom territory/skill matching logic instead of using standard ServiceTerritoryMember + ServiceResourceSkill.** The standard objects participate in scheduling; a custom junction will not.

---

## 7. Common Failure Modes and Remediation

### Failure 1 — "Appointments are not being scheduled to the right technician"
- **Symptom:** Dispatcher sees a Service Appointment routed to a technician who lacks a required skill, or to a technician in the wrong territory.
- **Root cause:** Required-skill junction missing on the Work Type or Work Order; ServiceTerritoryMember record stale; Scheduling Policy's Work Rules not including the "Required Skill" or "Service Territory" rule.
- **Fix:** Validate the Work Type has the correct required skills; confirm every ServiceResource has up-to-date ServiceTerritoryMember records with the right operating hours; audit the Scheduling Policy to ensure Match Skills and Match Territory Work Rules are present and enabled. Run the Scheduling Policy tester against a known appointment.

### Failure 2 — "Mobile app technicians see no work / stale work"
- **Symptom:** Technician opens the Field Service Mobile App, sees yesterday's appointments or nothing at all, even though the dispatcher has assigned today's work.
- **Root cause:** Briefcase priming rules exclude today's date, or the priming job has not run since assignment, or the technician's device cache is stale and the user has not pulled to refresh.
- **Fix:** Check Briefcase filter expressions — prime on `SchedStartTime` in a rolling window (today − 1 day to today + N days). Confirm the priming schedule; run it manually. Have the technician pull to refresh. If structural, reconfigure priming to be event-driven (on assignment) rather than batch-only.

### Failure 3 — "Scheduling optimizer returns no candidates / all slots are red"
- **Symptom:** Appointment Booking flow (or Book Appointment action on a Work Order) returns zero grades / zero slots, or every slot shows as ungraded.
- **Root cause:** No ServiceResource has a matching Skill + Territory + Operating Hours intersection for the requested window; OR the Work Type has a required skill that no resource holds; OR the scheduling horizon is shorter than the earliest available slot.
- **Fix:** Run a coverage audit — for every Work Type, list the resources that match required skills AND have a ServiceTerritoryMember in the Work Order's territory AND have Operating Hours covering the requested window. Gaps fall out immediately. Extend the scheduling horizon, or add coverage (hire, train, contract).

### Failure 4 — "Emergency appointment cannot be inserted / causes cascading reschedules"
- **Symptom:** Dispatcher tries to insert an emergency appointment; the optimizer either refuses, or accepts but reschedules 15 other appointments.
- **Root cause:** No Emergency Scheduling policy configured; the existing policy treats all appointments as equal weight; the optimizer is running Global Optimization on every insertion.
- **Fix:** Create a dedicated Emergency Scheduling Policy with a relaxed set of Work Rules and a Service Objective that heavily favours inserting the emergency with minimal disruption (high penalty on "reassign scheduled appointment"). Invoke it from the emergency action, not the default policy. If ESO is in use, configure Emergency Scheduling mode explicitly.

### Failure 5 — "Maintenance Plans are not generating Work Orders"
- **Symptom:** The Maintenance Plan is active, the Asset is linked, the frequency is set, but no Work Orders appear for the next cycle.
- **Root cause:** The Maintenance Plan generation horizon is too short (fewer days than the next interval), the Generation Timeframe batch has not run, or the Maintenance Work Rule does not have a valid Work Type.
- **Fix:** Set the Maintenance Plan Generation Timeframe to at least `frequency + buffer`. Run the batch manually (`Generate Work Orders` action). Confirm every Maintenance Work Rule references a Work Type that is Active and has Required Skills / Duration set.

---

## 8. Field Service Object Cheat Sheet

Core objects (standard names; namespaces do not apply — these live in the core `FieldService` standard object set or the managed package depending on org lineage):

| Object | Purpose | Key relationships |
|---|---|---|
| **WorkOrder** | The work to be performed. Parent of line items and appointments. | Account, Contact, Case, Asset, ServiceTerritory, WorkType |
| **WorkOrderLineItem** | Granular line-level work within a Work Order. One WOLI can be its own schedulable Service Appointment. | WorkOrder (parent), Asset, WorkType |
| **ServiceAppointment** | The schedulable unit. What the optimizer actually places on the Gantt. | Parent (WorkOrder or WOLI), ServiceTerritory, AssignedResource |
| **ServiceResource** | A technician, crew, contractor, or equipment resource that can be scheduled. | User (for human resources), ServiceCrew (for crews), Asset (for equipment) |
| **ServiceTerritory** | Geographic + operating-hours + time-zone container. May be hierarchical. | Parent ServiceTerritory, OperatingHours |
| **ServiceTerritoryMember** | Junction: this ServiceResource can work in this ServiceTerritory during these hours. | ServiceResource, ServiceTerritory, OperatingHours |
| **ServiceCrew** | A reusable grouping of resources for multi-person appointments. | — |
| **ServiceCrewMember** | Junction: this ServiceResource is part of this ServiceCrew. | ServiceCrew, ServiceResource |
| **Skill** | A named capability. | — |
| **ServiceResourceSkill** | Junction: this ServiceResource holds this Skill (optionally time-bounded). | ServiceResource, Skill |
| **SchedulingPolicy** | The named bundle of Work Rules + Service Objectives the scheduler applies. | WorkRule (many), ServiceObjective (many) |
| **WorkType** | Template for a kind of work (duration, skills, default line items). | Skill (required-skill junctions) |
| **WorkTypeGroup** | Logical grouping of Work Types for Appointment Booking. | WorkType (many) |
| **MaintenancePlan** | Preventive-maintenance schedule for one or more Assets. | Asset, WorkType |
| **MaintenanceWorkRule** | The frequency/cadence rule that drives Work Order generation from a Maintenance Plan. | MaintenancePlan, WorkType |
| **Asset** | The installed thing being serviced. | Account, Contact, parent Asset, Product |
| **ResourceAbsence** | Time off, training, or other unavailability for a ServiceResource. | ServiceResource |
| **TimeSheet** / **TimeSheetEntry** | Technician time tracking, often auto-populated from appointment status transitions. | ServiceResource, ServiceAppointment, WorkOrder |

Secondary but important:

- **ProductRequired** — parts required by a Work Order / WOLI / Work Type.
- **ProductConsumed** — parts actually used on an appointment.
- **ProductRequest** / **ProductTransfer** — inventory movement between locations.
- **ServiceReport** — the branded PDF of work completed, with customer signature.
- **OperatingHours** / **TimeSlot** — reusable schedule templates referenced by ServiceTerritory and ServiceTerritoryMember.

Use this cheat sheet as the first sanity check on any Field Service design: every requirement should map to one or more of these standard objects before any custom object is considered.
