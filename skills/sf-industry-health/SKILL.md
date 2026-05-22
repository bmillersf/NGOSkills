---
name: sf-industry-health
description: >
  Health Cloud architecture with industry-first routing precedence.
  TRIGGER when: user asks to "build a care plan", "design a patient 360 view",
  "stand up a care request workflow", "wire up EHR/FHIR integration",
  "configure provider network management", "coordinate a care team",
  "run a utilization management review", "track social determinants of health",
  "set up intelligent appointment management", "design a home health workflow",
  "build a member services console for a payer", "launch patient services",
  "close care gaps", "model the household for care coordination", or touches
  HealthCloudGA__ / CareRequest / CarePlan / CareTeamMember / ClinicalEncounter /
  ClinicalServiceRequest / PatientHousehold / HealthcareProvider objects;
  also triggers on phrases like "we're on Health Cloud", "this is a payer org",
  "provider directory", "prior authorization in Salesforce", "PHI lives in this
  field", "HIPAA-compliant Salesforce design".
  DO NOT TRIGGER when: generic Sales Cloud B2C account design with no clinical
  data (use sf-sales-cloud); generic Service Cloud Case routing unrelated to
  clinical workflows (use sf-service-cloud); standard Case/Queue/Omni-Channel
  setup for non-clinical contact centers (use sf-service-case); writing Apex
  classes/triggers unrelated to Health Cloud objects (use sf-apex); building
  Lightning Web Components that happen to render clinical data but have no
  Health Cloud data model decision (use sf-lwc); authoring Salesforce Flows
  that do not orchestrate Care Plan / Care Request objects (use sf-flow);
  human services / social services / case management that is explicitly
  non-clinical and nonprofit-run (use sf-nonprofit-program-case — the clinical
  vs. human-services boundary is "is a licensed clinician authoring a care
  plan against a patient record with PHI?" — if no, route to program-case);
  Data Cloud ingestion / harmonization / segmentation even when the data is
  clinical (use sf-datacloud and its phase skills — this skill does not own
  Data Cloud pipeline design); Public Sector Solutions where a Benefit,
  License, Permit, or Inspection object dominates the workflow over Care
  (use sf-industry-public-sector); authoring OmniStudio OmniScripts,
  FlexCards, Integration Procedures, or Data Mappers even when used for
  Health Cloud assessments (use sf-industry-commoncore-omniscript and its
  siblings — this skill decides WHEN an Assessment is the right modeling
  choice and delegates the BUILD to the OmniStudio skills).
license: MIT
compatibility: "Requires Health Cloud managed package (namespace HealthCloudGA__) + Health Cloud user licenses; OmniStudio is commonly bundled for Assessments and Patient Services; Shield Platform Encryption strongly recommended for PHI fields"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "150 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.hc_admin_intro.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://developer.salesforce.com/docs/atlas.en-us.health_cloud_object_reference.meta/health_cloud_object_reference/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/industries/health
    anchor: ""
    sha256: ""
    importance: supplemental
  - url: https://help.salesforce.com/s/articleView?id=sf.hc_admin_care_plans.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.hc_admin_utilization_management.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_health.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "150-pt rubric (7 categories: Regulatory 25 / Data Model 25 / Clinical Workflow 25 / FHIR 20 / UX 20 / PHI 20 / Testing 15) — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  health_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Clinical data-model correctness. Maps to Data Model (25) + Clinical Workflow (25). Patient as Person Account, Care Plan / Care Request / Clinical Encounter wired correctly, lifecycle states honored, no shadow data model on top of Health Cloud objects."
      automatic_hard_fail_rules:
        - "Patient modeled as a Business Account when the org has Health Cloud's Person Account configuration enabled"
        - "Custom object created to model a clinical concept that already has a first-class Health Cloud object (e.g., custom Care_Plan__c when CarePlan exists)"
        - "Care Request lifecycle state transition that bypasses HealthCloudGA__ status enums (writing arbitrary Status values via DML)"
        - "Clinical Encounter or Care Plan written without the required HealthcareProvider / Patient lookups populated — orphan records"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "PHI + HIPAA safeguards. Maps to PHI (20) + Regulatory (25). Heaviest robustness floor — PHI exposure is a regulated breach with mandatory disclosure. Shield Platform Encryption, Event Monitoring, Field Audit Trail, signed BAA are baseline for any covered entity / BA workflow."
      automatic_hard_fail_rules:
        - "PHI-bearing custom field created on a clinical object without Shield Platform Encryption when the org is a Covered Entity or Business Associate"
        - "Care Team membership granting clinician access to a patient outside their assigned panel without role-based sharing rule justification"
        - "EHR / FHIR integration writing PHI to a non-encrypted staging object or to Platform Events without encrypted-payload guarantee"
        - "Reports or dashboards exposing PHI to roles below the patient's care team without runtime sharing enforcement"
        - "Audit trail (Field Audit Trail or Event Monitoring) not enabled on the PHI fields the workflow writes"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Pattern adherence to Health Cloud + FHIR conventions. Maps to FHIR (20) + portions of Data Model (25). Use OmniStudio Assessments for clinical questionnaires (not custom Visualforce), respect FHIR R4 resource boundaries on integration, follow Salesforce naming for custom extensions."
      automatic_hard_fail_rules:
        - "Custom clinical questionnaire built without OmniStudio Assessment when Assessment is the documented Salesforce pattern"
        - "FHIR resource mapping that splits a single FHIR resource across multiple unrelated Salesforce objects (e.g., FHIR Patient mapped to Account + Contact + custom object)"
        - "Custom field naming on Health Cloud objects without HealthCloudGA__-aware namespace consideration (causes upgrade collisions)"
        - "Care Plan written via raw Apex instead of using Health Cloud Care Plan templates / Care Plan Goal / Care Plan Activity hierarchy"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "UX + testing + scale. Maps to UX (20) + Testing (15). Console layout works under clinical-workflow load, FHIR callouts respect API limits, Apex test coverage on the clinical write paths is real (not mocked)."
      automatic_hard_fail_rules:
        - "Care Team console FlexiPage exceeding 25 components on a single page (Lightning performance cliff)"
        - "FHIR callout pattern firing N callouts in a loop instead of using Composite API or batched Integration Procedure"
        - "Apex coverage on clinical write paths below 75% OR coverage achieved purely via mocked HealthCloudGA__ stubs without an integration test"
        - "Report on PHI fields without selective filter that would scale beyond 50k rows in production volume"
  test_rubric:
    unit:
      required: true
      criteria: "Health Cloud object metadata validates. Lifecycle state transitions enumerate valid HealthCloudGA__ Status values. Apex unit tests on Care Plan / Care Request / Clinical Encounter write paths assert lookup integrity and PHI field encryption."
    integration:
      required: true
      criteria: "End-to-end clinical workflow runs against a Health Cloud sandbox: Patient → Care Plan → Care Team assignment → Clinical Encounter logged → Care Gap surfaced. FHIR integration round-trips a representative R4 resource (Patient / Observation / Condition) without data loss."
    smoke:
      required: true
      criteria: "Care Team member opens the patient console, sees only patients in their panel (sharing enforced), can document an encounter, and PHI fields appear encrypted in reports/exports for users without explicit decrypt permission."
---

# sf-industry-health: Health Cloud Architect

Expert Salesforce architect specializing in **Health Cloud**: payer and provider data models, Care Plans, Care Requests, Clinical Encounters, EHR/FHIR integration, OmniStudio-powered Assessments, Care Team coordination, Utilization Management, Provider Network Management, Intelligent Appointment Management, Patient Services, Home Health, Social Determinants of Health (SDoH), and Care Gap closure.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 150-pt rubric across 7 clinical/regulatory categories, mapped onto the 4-dim shape with Robustness floor at 18 — PHI exposure is a regulated breach with mandatory disclosure. Hard-fail rules block unencrypted PHI fields, cross-panel Care Team access, FHIR mappings that fracture R4 resources, custom Care_Plan__c when CarePlan exists, and audit-trail-disabled PHI write paths. Disable with `eval_harness.enabled: false`.

---

This is an **industry skill**. Health Cloud introduces a first-class clinical data model (Patient as Person Account, Care Plan, Care Request, Clinical Encounter, etc.) that generic Sales Cloud or Service Cloud skills must not override. When Health Cloud is installed and the request touches clinical objects, this skill owns the task end-to-end.

> **PHI / HIPAA callout.** Every workflow in this skill MUST be evaluated against HIPAA Technical Safeguards (45 CFR 164.312). If the org is a Covered Entity or Business Associate and PHI is involved, Shield Platform Encryption, Event Monitoring, Field Audit Trail, and a signed BAA with Salesforce are baseline — not optional. See section 6 and the dedicated PHI/HIPAA checklist.

---

## 1. When this skill owns the task

Use `sf-industry-health` when the work involves Health Cloud's clinical data model or any of its packaged workflow families (Care Plan, Care Request, Utilization Management, Provider Network Management, Intelligent Appointment Management, Patient Services, Home Health, SDoH, Care Gaps, Assessments).

### Delegation table

| Need | Delegate to | Reason |
|---|---|---|
| Generic Service Cloud case routing, Omni-Channel, queues with no clinical object | [sf-service-cloud](../sf-service-cloud/SKILL.md) | non-clinical contact center |
| Case lifecycle mechanics (status models, escalations) unrelated to CareRequest | [sf-service-case](../sf-service-case/SKILL.md) | phase skill |
| Apex triggers, handlers, batch/queueable against Health Cloud objects | [sf-apex](../sf-apex/SKILL.md) | code implementation after this skill sets the data-model decision |
| Lightning Web Components rendering patient data | [sf-lwc](../sf-lwc/SKILL.md) | UI code after this skill specifies the object surface |
| Salesforce Flows orchestrating Care Plan / Care Request transitions | [sf-flow](../sf-flow/SKILL.md) | declarative automation after this skill specifies the workflow |
| Data Cloud ingestion / harmonization / segmentation of clinical data | [sf-datacloud](../sf-datacloud/SKILL.md) | Data Cloud is a separate product surface |
| OmniStudio OmniScript build for Assessments, intake, or Patient Services | [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) | build step after this skill decides Assessment is the right model |
| OmniStudio Integration Procedure orchestrating FHIR callouts | [sf-industry-commoncore-integration-procedure](../sf-industry-commoncore-integration-procedure/SKILL.md) | build step after this skill specifies the callout shape |
| OmniStudio FlexCard for Patient 360 surface | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) | build step |
| OmniStudio Data Mapper between FHIR payload and Health Cloud objects | [sf-industry-commoncore-datamapper](../sf-industry-commoncore-datamapper/SKILL.md) | build step |
| Named Credentials / External Services for EHR callouts | [sf-integration](../sf-integration/SKILL.md) | wire-up after this skill chooses connector vs. custom integration |
| Connected App / OAuth for an EHR vendor | [sf-connected-apps](../sf-connected-apps/SKILL.md) | prerequisite for Named Credentials |
| Permission set design for clinical roles (physician, care manager, UM reviewer) | [sf-permissions](../sf-permissions/SKILL.md) | access audit after this skill defines role boundaries |
| Custom metadata for PHI-adjacent fields | [sf-metadata](../sf-metadata/SKILL.md) | object/field creation after this skill names the extension points |
| Human services / nonprofit program enrollment (non-clinical) | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) | different industry vertical; see §2 boundary test |

---

## 2. Industry precedence note (read before doing anything)

**Health Cloud wins.** When Health Cloud is detected (package namespace `HealthCloudGA__` present, Health Cloud user licenses assigned, or CareRequest/CarePlan/CareTeamMember standard objects are in scope), this skill overrides:

- `sf-sales-cloud` — Health Cloud replaces the generic Account/Contact/Opportunity model with Person Account + PersonAccount EHR extensions + clinical objects. Do NOT recommend a generic B2C Sales Cloud shape.
- `sf-service-cloud` — Health Cloud has its own service patterns (CareRequest, Utilization Management, Patient Services console). Do NOT recommend a generic Case/Queue/Omni-Channel rebuild when a Health Cloud packaged workflow already owns the semantics.
- `sf-service-case` — CareRequest is **not** a Case. It is a discrete object with its own status model, relationships to CarePlan/CarePlanTemplate, and regulatory semantics (e.g., prior authorization). A generic Case skill would destroy that structure.

This skill does **not** run `references/industry-precheck.md` — industry skills are the destination of that check, not a caller.

### Human services vs. clinical boundary (sf-nonprofit-program-case vs. this skill)

The most common mis-route is between this skill and `sf-nonprofit-program-case`. Use this decision test:

> **Is a licensed clinician (MD, DO, NP, PA, RN, LCSW acting in clinical scope) authoring or approving a care plan, clinical order, or assessment against a patient record whose fields are regulated as PHI?**
>
> - **Yes** → `sf-industry-health` (this skill). Health Cloud, Care Plan, Clinical Encounter, HIPAA apply.
> - **No, it's wraparound / case management / enrollment by a non-clinical case worker at a nonprofit** → `sf-nonprofit-program-case`. Program/Enrollment/Benefit objects, not CarePlan.
> - **Both, in the same org** → this skill owns the clinical slice, program-case owns the social-service slice. They coexist via shared Person Account; do not merge their data models.

When in doubt, ask the user: "Is this clinical (licensed provider, PHI, HIPAA) or human services (case worker, programs, benefits)?" — one short clarifying question is cheaper than rebuilding on the wrong object model.

---

## 3. Required context to gather first

Before proposing architecture, surface the following. Do not assume — one confused answer here propagates into every downstream design decision.

### 3.1 Persona / business model
- **Payer** (health plan, managed care org) — focus on Utilization Management, Provider Network Management, Member Services, claims-adjacent workflows
- **Provider** (hospital, clinic, physician group) — focus on Patient Services, Care Plans, Clinical Encounters, EHR integration
- **Life Sciences / Pharma** — different product (Health Cloud for Life Sciences / MedTech) — flag if selected; much of this skill still applies but consent and HCP/HCO interactions dominate
- **Home Health / community care** — focus on Home Health, SDoH, Care Team coordination across a household
- **Hybrid payvider** — both payer and provider semantics; expect both workflow families

### 3.2 Regulatory and data-sensitivity context
- Is the org a HIPAA Covered Entity, Business Associate, or neither?
- Is there a signed Salesforce BAA? (required for any Covered Entity storing PHI)
- Which fields are PHI? (name, DOB, SSN, MRN, diagnosis, treatment, encounter notes, lab results, claim data, genetic data)
- Is Shield Platform Encryption provisioned? Which fields are encrypted?
- Is Event Monitoring + Field Audit Trail enabled?
- Are there additional regimes? (HITECH, state privacy laws like CA CMIA, 42 CFR Part 2 for SUD records, GDPR if EU data, FHIR US Core 6.0+ / ONC certification requirements)

### 3.3 EHR / FHIR integration scope
- Which EHR(s)? (Epic, Cerner/Oracle Health, MEDITECH, athenahealth, other)
- Which FHIR profile? (US Core, Da Vinci PDex for payers, Argonaut, SMART on FHIR for apps)
- Which direction is the data moving? (read-only view of EHR, bidirectional sync, event-driven updates via FHIR subscriptions, bulk FHIR export)
- Is the Salesforce-packaged EHR connector (Health Cloud EHR Integration) in use, or custom integration?

### 3.4 Org readiness
- Health Cloud managed package version and org edition
- Person Account enabled? (required — cannot be disabled once enabled)
- OmniStudio present? (needed for Assessments, Patient Services, Intake)
- Experience Cloud site for patients/members? (patient portal, member portal)
- Data Cloud provisioned for 360 analytics? (route cross-skill to `sf-datacloud` for pipeline)
- Which Health Cloud features are licensed? (Utilization Management, Provider Network Management, Intelligent Appointment Management, Home Health, Care Gaps — several require separate SKUs)

### 3.5 Scope of the request
- Greenfield build, feature addition, or remediation of an existing Health Cloud implementation?
- Timeline and migration pressure (legacy EHR-bolted custom objects → Health Cloud native objects is a common and high-risk migration)
- Downstream consumers (reporting, analytics, Agentforce agents surfacing patient context)

If any of §3.1–§3.4 is unknown, stop and ask. Proposing a care-plan model for a payer org is a top-3 failure mode.

---

## 4. Workflow phases

Execute in this order. Each phase gates the next.

### Phase 1 — Persona + regulatory context
Lock in answers to §3.1–§3.2. Produce a one-paragraph summary: "This is a [payer / provider / life sciences / home health / hybrid] org, HIPAA [Covered Entity / BA / non-HIPAA], PHI boundaries are [...], applicable regimes beyond HIPAA are [...]." Every subsequent decision cites this summary.

### Phase 2 — Patient / Member data model
Anchor on **Person Account** as the patient/member record. Extend via **PersonAccount EHR extensions** (Health Cloud adds fields like PrimaryCareProvider, BirthSex, GenderIdentity, PreferredLanguage, MaritalStatus, EthnicityDetails, RaceDetails). Model:

- **Patient / Member** → Person Account
- **Household** → PatientHousehold (household-based care coordination; different from NPC Household — Health Cloud's model is specifically for clinical/SDoH context)
- **Healthcare Provider** (licensed clinician entity) → HealthcareProvider + HealthcarePractitionerFacility
- **Care Team** → CareTeamMember linking Patient ↔ HealthcareProvider with role (PCP, Specialist, Care Manager, Social Worker, Pharmacist)
- **Facility / Site of Care** → HealthcareFacility, HealthcarePracticeFacility

Decide now whether to co-model **Contact-based Health Cloud** (older pattern) or **Person Account-based** (current Salesforce guidance — this is the default and what this skill recommends). Do not mix.

### Phase 3 — Care Plan / Care Request design
- **CarePlanTemplate** → reusable template (e.g., "Type 2 Diabetes Care Plan — Adult")
- **CarePlan** → instance of a template attached to a patient, with problems, goals, and activities
- **CarePlanProblem / CarePlanGoal / CarePlanActivity** → structured child records
- **CareRequest** → referrals, prior auth requests, service requests — **not** a Case
- **CareRequestItem** → line-item detail on a CareRequest
- **CareRequestReviewer** → UM reviewer assignment
- **ClinicalServiceRequest** → orderable clinical service (e.g., lab order, imaging order, procedure order)
- **ClinicalEncounter** / **HealthcareGenericEvent** → the clinical visit itself

Match the user's workflow to Health Cloud's packaged shape first; custom objects are a last resort.

### Phase 4 — Clinical integration (EHR / FHIR)
- Prefer the **Health Cloud EHR Integration** connector and **Salesforce FHIR API** when available
- Use **OmniStudio Integration Procedures** + **Data Mappers** to translate FHIR resources (Patient, Encounter, Condition, Observation, MedicationRequest, CarePlan, ServiceRequest) ↔ Health Cloud objects
- For bulk sync, use **FHIR Bulk Data Access** ($export) into Data Cloud, then stream-reshape to Health Cloud via Data Cloud → CRM activation
- Do **not** hand-roll REST callouts to an EHR FHIR endpoint when the packaged connector + IP/DM path exists

Delegate the concrete wire-up to `sf-integration` (Named Credentials), `sf-industry-commoncore-integration-procedure`, `sf-industry-commoncore-datamapper`.

### Phase 5 — Assessments (OmniStudio)
Health Cloud **Assessments** are OmniStudio-powered. Use this skill to decide WHICH assessments are needed (PHQ-9, GAD-7, SDoH screener, Fall Risk, HEDIS-aligned care-gap closure, admission intake) and how to map their output to:

- CarePlanProblem / CarePlanGoal creation
- CareRequest initiation (if a score triggers a referral)
- ClinicalServiceRequest (if score triggers a lab/imaging order)
- AssessmentTaskResponse + AssessmentIndicatorDefinition for scoring

Delegate the build to `sf-industry-commoncore-omniscript`.

### Phase 6 — Care Team + care coordination
- CareTeamMember roles, effective dates, primary flag
- Care Coordination: assignment via queues + Omni-Channel (clinical skills-based routing), NOT generic Service Cloud Omni routing — use Health Cloud's configured presence statuses
- PatientHousehold → shared SDoH context across household members
- Referrals → CareRequest with type = Referral

### Phase 7 — Security / HIPAA / PHI audit
Run the PHI/HIPAA checklist (§6). Gate the build until every item is green. Specifically verify:

- Shield Platform Encryption on PHI fields
- Field-Level Security audited per clinical role
- Sharing model (Private → Role Hierarchy → Manual Share / Account Team) enforces minimum-necessary
- Event Monitoring + Transaction Security policies catch exfiltration
- Field Audit Trail retention meets retention policy (often 7 years for clinical)
- Login IP restrictions, MFA, and session settings meet HITRUST / org standards
- Guest user access (if Experience Cloud patient portal) is explicitly scoped; no "View All" anywhere near PHI

### Phase 8 — Testing
- Apex tests that assert sharing rules on PHI fields as a different-persona user (use `System.runAs`)
- FLS assertion tests for every clinical role
- Integration tests that exercise the FHIR → Health Cloud mapping with at minimum one record per resource type in scope
- Assessment scoring tests (verify PHQ-9 severity bands, fall-risk stratification, etc.)
- End-to-end care-plan flow test covering template → instance → goal completion
- Negative tests proving non-clinical users cannot read PHI

Delegate concrete test authoring to `sf-testing` (Apex) and `sf-lwc` (Jest).

---

## 5. Scoring rubric (150 points total)

Every Health Cloud design produced by this skill is scored before delivery. Below 105/150 (70%) must be revised.

```
Score: XX/150
├─ Regulatory / HIPAA fit:              XX/25   (≥18 to pass)
├─ Data model (Person Account + HC):    XX/25   (≥18 to pass)
├─ Clinical workflow correctness:       XX/25   (≥18 to pass)
├─ Integration / FHIR:                  XX/20   (≥14 to pass)
├─ UX (Patient/Member/Clinician):       XX/20   (≥14 to pass)
├─ Security / PHI handling:             XX/20   (≥15 to pass)
└─ Testing:                             XX/15   (≥10 to pass)
```

### Category detail

| Category | Full credit looks like | Half credit | Zero |
|---|---|---|---|
| **Regulatory / HIPAA fit** (25) | Named regime (HIPAA + HITECH + state), BAA verified, Covered Entity vs. BA role stated, 42 CFR Part 2 / GDPR flagged if applicable | Only HIPAA named, no BAA check | No regulatory analysis |
| **Data model** (25) | Person Account + PersonAccount EHR extensions + CareTeamMember + PatientHousehold used correctly; no parallel custom objects where standard exists | Mostly standard but one custom object duplicating a Health Cloud standard | Custom Account/Contact patient model; CarePlan modeled as Task or Case |
| **Clinical workflow correctness** (25) | CarePlan / CareRequest / ClinicalEncounter / ClinicalServiceRequest used per their semantic role; status models respected | One object repurposed (e.g., CareRequest used for clinical encounter) | Workflows bolted onto generic Case |
| **Integration / FHIR** (20) | FHIR profile named (US Core, Da Vinci, etc.), packaged connector preferred, IP/DM mapping sketched, bulk vs. real-time choice justified | Custom callouts when connector exists, or FHIR profile unspecified | No FHIR mapping; raw REST |
| **UX** (20) | Role-aware surfaces (clinician Patient 360 vs. member portal vs. UM reviewer console); appropriate FlexCards/OmniScripts | UX not differentiated by role | Single generic Lightning page |
| **Security / PHI handling** (20) | Shield Platform Encryption + Field Audit Trail + Event Monitoring + MFA; FLS matrix per clinical role; sharing minimum-necessary | Encryption mentioned but not scoped per field; generic FLS | PHI in unencrypted custom fields; broad "View All" |
| **Testing** (15) | Apex runAs tests for sharing; FLS assertions; FHIR mapping tests; assessment scoring tests | Only happy-path unit tests | No test plan |

---

## 6. Anti-patterns (minimum 7)

- **Storing PHI in standard Account/Contact without Shield encryption.** Person Account is the Health Cloud shape; standard Account/Contact patient data without Shield Platform Encryption fails HIPAA Technical Safeguards and most HITRUST audits.
- **Writing custom Apex to sync with an EHR when the packaged Health Cloud EHR connector + OmniStudio IP/DM path exists.** Custom sync drifts; the connector honors FHIR profiles and versions. Only hand-roll when the connector provably cannot meet a requirement, and document why.
- **Treating Care Plan as a generic Task or Case.** A CarePlan has CarePlanTemplate / CarePlanProblem / CarePlanGoal / CarePlanActivity structure; flattening it into Task destroys reporting, care-gap closure metrics, and HEDIS alignment.
- **Modeling CareRequest as Case.** CareRequest is a first-class object with its own status model, relationships to CarePlan, and prior-authorization semantics. A Case would lose reviewer assignment and line-item detail.
- **Skipping OmniStudio for Assessments and building them as custom screen flows.** Health Cloud Assessment objects (AssessmentTask, AssessmentTaskResponse, AssessmentIndicatorDefinition) are OmniStudio-wired; custom screen flows do not feed the scoring and care-plan-generation pipeline.
- **Running a patient portal on Experience Cloud guest users with broad object visibility.** Guest user access to PHI is one of the highest-severity Salesforce security failures. Use authenticated community users with sharing sets scoped to the viewing patient only.
- **Mixing Contact-based Health Cloud patterns with Person Account-based patterns in the same org.** Contact-based Health Cloud is the legacy model; Person Account is the current guidance. Mixing them fragments Care Team and sharing rules.
- **Designing a care plan for a payer org.** Payers do not own care plans; providers do. A payer workflow is Utilization Management, Provider Network Management, Member Services — not CarePlan authoring. Wrong-persona modeling is a top-3 field failure.
- **Using Data Cloud as the system of record for clinical data.** Data Cloud harmonizes and segments; the Health Cloud object model is the system of record for clinical entities. Do not push clinical writes through Data Cloud.
- **Ignoring 42 CFR Part 2 for SUD (Substance Use Disorder) records.** Part 2 imposes stricter consent rules than HIPAA. A vanilla HIPAA design can still violate Part 2.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| "Patient data is leaking to the wrong care team members" | Sharing model is Public Read / Public Read-Write, or CareTeamMember records share-grant too broadly | Set Account (Person Account) to Private; grant via CareTeamMember + sharing rules + manual shares scoped to active assignments; audit with `sf-permissions` |
| "The EHR sync is constantly failing with FHIR validation errors" | Custom callout bypasses the packaged FHIR profile; Data Mapper not honoring US Core constraints | Replace custom callout with OmniStudio IP + Data Mapper aligned to the specific FHIR profile (US Core 6.0+, Da Vinci PDex, etc.); delegate rebuild to `sf-industry-commoncore-integration-procedure` |
| "Assessments don't trigger the care plan updates we expected" | Assessment was built as a screen flow, not OmniStudio; AssessmentTaskResponse / AssessmentIndicatorDefinition not populated | Rebuild in OmniStudio OmniScript tied to AssessmentTask; wire scoring to AssessmentIndicatorDefinition; downstream Flow creates CarePlanProblem/Goal based on indicator bands |
| "The UM reviewer queue has the wrong cases" | CareRequest modeled as Case; Omni routing configured on Case instead of CareRequest | Migrate to CareRequest + CareRequestReviewer; reconfigure presence + routing on CareRequest; retire Case-based UM process |
| "We can't report on care gaps for HEDIS" | Care Gap signals stored as custom checkboxes on Account instead of CarePlanProblem / CareGap structured records | Model care gaps as CarePlanProblem linked to a CareGapTemplate-style template; use Assessments to detect; use Next Best Action to surface; reporting aligns to HEDIS measures |

---

## 8. Health Cloud object cheat sheet

### Patient / member / household
- **Account (Person Account)** — Patient or Member. Requires Person Account enablement (irreversible).
- **PersonAccount EHR extensions** — Additional fields (BirthSex, GenderIdentity, PreferredLanguage, RaceDetails, EthnicityDetails, MaritalStatus, DeceasedDate) added by Health Cloud on the PersonAccount.
- **PatientHousehold** — Household unit for care coordination and SDoH.
- **PatientMedicationDosage**, **MedicationStatement**, **MedicationRequest** — medication history.
- **Condition** — problem list / diagnoses.
- **AllergyIntolerance** — allergies.

### Care team / providers
- **CareTeamMember** — junction between Patient (Person Account) and HealthcareProvider with role, start/end dates, primary flag.
- **HealthcareProvider** — licensed clinician entity.
- **HealthcarePractitionerFacility** — provider ↔ facility association.
- **HealthcareFacility** — hospital, clinic, office.

### Care planning
- **CarePlanTemplate** — reusable template.
- **CarePlan** — patient-specific instance.
- **CarePlanProblem** — addressed problem / condition.
- **CarePlanGoal** — measurable goal.
- **CarePlanActivity** — action or intervention.

### Care requests / referrals / utilization management
- **CareRequest** — referral, prior authorization, service request. **Not a Case.**
- **CareRequestItem** — line-item detail.
- **CareRequestReviewer** — UM reviewer assignment.
- **CareRequestDiagnosis** / **CareRequestDrug** / **CareRequestExtension** — enrichment records.

### Clinical encounters / orders
- **ClinicalEncounter** — the clinical visit.
- **HealthcareGenericEvent** — generic clinical event record.
- **ClinicalServiceRequest** — orderable service (lab, imaging, procedure).
- **HealthcareGenericObservation** — observation / vital / lab result when not using a specialized object.
- **HealthCloudGA__EhrEncounter__c** — legacy/custom EHR encounter object (managed-package namespaced; present in older orgs — prefer standard ClinicalEncounter in new builds).

### Assessments (OmniStudio-powered)
- **AssessmentTask** — an instance of an assessment given to a patient.
- **AssessmentTaskResponse** — response to an assessment item.
- **AssessmentIndicatorDefinition** — scoring / stratification definition.
- **AssessmentQuestion** / **AssessmentQuestionResponse** (where applicable in current release) — question-level structure.

### Payer / utilization / network
- **MemberPlan** — member's coverage plan.
- **CoverageBenefit** — benefit detail under a plan.
- **PurchaserPlan** — purchaser-level plan (employer group).
- **CareBenefitVerifyRequest** — benefit verification workflow.
- **CareDeterminationDecision** — UM determination.
- **CareProviderSearchableField** — provider-directory indexing.

### SDoH / care gaps / home health
- **IndividualApplication**, **IndividualResource**, **SocialDeterminant** — SDoH signals (exact object naming varies by release; verify against the upstream Health Cloud object reference).
- **CareGap** / **CareGapRule** — care gap detection and closure (verify release-specific naming).
- **HomeVisitAttendee** / **HomeVisit** — Home Health workflow records (verify release-specific naming).

> When a specific object name is uncertain for the target release, verify against `https://developer.salesforce.com/docs/atlas.en-us.health_cloud_object_reference.meta/health_cloud_object_reference/` before writing code. Health Cloud's object surface evolves meaningfully release-over-release.

---

## 9. PHI / HIPAA checklist (gating — do not skip)

Health Cloud without the right security configuration is a liability, not an asset. Before delivering any design:

- [ ] Signed Salesforce BAA on file (Covered Entities and BAs)
- [ ] Shield Platform Encryption enabled; encrypted field list includes every PHI field in scope
- [ ] Field Audit Trail enabled with retention matching the org's clinical records policy (commonly 7 years)
- [ ] Event Monitoring enabled; Transaction Security policies cover PHI export / mass download
- [ ] MFA enforced for all users with PHI access
- [ ] Login IP ranges or VPN-only access configured per org policy
- [ ] Sharing defaults Private on Account, CarePlan, CareRequest, ClinicalEncounter, ClinicalServiceRequest
- [ ] Field-Level Security matrix documented per clinical role (Physician, Care Manager, UM Reviewer, Social Worker, Front Desk, Patient-facing Portal user)
- [ ] Guest user access (if any) explicitly scoped; no guest access to PHI
- [ ] Experience Cloud patient portal uses authenticated users with sharing sets restricted to `$User.ContactId = Patient.ContactId` or Person Account equivalent
- [ ] Apex `without sharing` usage audited and justified where it exists (should be rare)
- [ ] 42 CFR Part 2 evaluated for SUD data; state-specific privacy regimes (CMIA, etc.) evaluated
- [ ] Break-the-glass / emergency-access procedure defined and auditable
- [ ] Data retention + deletion policy aligned to HIPAA minimum-necessary and applicable state law

---

## 10. Cross-skill integration

| Task | Skill |
|---|---|
| Apex for CarePlan / CareRequest automation | [sf-apex](../sf-apex/SKILL.md) |
| LWC for Patient 360, Care Team, Assessment surfaces | [sf-lwc](../sf-lwc/SKILL.md) |
| Flow for CareRequest status transitions | [sf-flow](../sf-flow/SKILL.md) |
| FHIR callouts, Named Credentials, External Services | [sf-integration](../sf-integration/SKILL.md) |
| Connected App / OAuth for EHR vendors | [sf-connected-apps](../sf-connected-apps/SKILL.md) |
| Permission set design per clinical role | [sf-permissions](../sf-permissions/SKILL.md) |
| Custom fields and objects extending Health Cloud | [sf-metadata](../sf-metadata/SKILL.md) |
| OmniStudio OmniScript for Assessments / Intake | [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) |
| OmniStudio Integration Procedure for FHIR orchestration | [sf-industry-commoncore-integration-procedure](../sf-industry-commoncore-integration-procedure/SKILL.md) |
| OmniStudio FlexCard for Patient 360 | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) |
| OmniStudio Data Mapper for FHIR ↔ Health Cloud | [sf-industry-commoncore-datamapper](../sf-industry-commoncore-datamapper/SKILL.md) |
| Data Cloud ingestion of clinical data | [sf-datacloud](../sf-datacloud/SKILL.md) and phase skills |
| Test authoring (Apex) | [sf-testing](../sf-testing/SKILL.md) |
| SOQL for clinical reporting | [sf-soql](../sf-soql/SKILL.md) |
| Test data factories for Health Cloud scenarios | [sf-data](../sf-data/SKILL.md) |
| Deployment / scratch org setup for Health Cloud | [sf-deploy](../sf-deploy/SKILL.md) |

---

## 11. Output format

When finishing a Health Cloud task, report in this order:

1. **Task classification** — greenfield / feature addition / remediation / migration
2. **Persona** — payer / provider / life sciences / home health / hybrid
3. **Regulatory context** — HIPAA role, BAA status, other regimes
4. **Data-model decisions** — Person Account yes/no, which Health Cloud objects in scope, any custom extension objects and why
5. **Workflow decisions** — CarePlan / CareRequest / ClinicalEncounter / Assessment usage
6. **Integration decisions** — EHR connector vs. custom, FHIR profile, bulk vs. real-time
7. **Security posture** — Shield, FAT, FLS matrix, sharing model, guest access
8. **Score** — `XX/150` with per-category breakdown and pass/fail
9. **Delegations** — which sibling sf-* skills own the next concrete steps
10. **Open questions / risks** — anything the user still needs to answer before build
