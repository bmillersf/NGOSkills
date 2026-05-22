---
name: sf-industry-education
description: >
  Education Cloud (native) + EDA (legacy) architecture with industry-first routing.
  TRIGGER when: user designs or implements education data models, student
  lifecycle processes, or academic operations on Salesforce; or says
  "student 360 view", "program enrollment workflow", "course connection
  modeling", "advising/recruiting workflow", "retention tracking",
  "alumni engagement", "admissions funnel", "academic plan design",
  "course catalog configuration", "affiliation modeling", "set up Education
  Cloud", "migrate from EDA to Education Cloud", "higher ed CRM", "K-12
  student records in Salesforce", "workforce education learner tracking",
  "track advising appointments", "learning path design", "configure Term
  and Course Offering", or touches objects in the `hed__` namespace or
  native Student / ProgramEnrollment / CourseConnection objects.
  DO NOT TRIGGER when: the task is generic Opportunity/Lead/Account CRM
  work unrelated to education data (use sf-sales-cloud), generic Case
  management outside a student-success context (use sf-service-cloud or
  sf-service-case), generic Apex implementation (use sf-apex), generic
  Lightning Web Component authoring (use sf-lwc), Salesforce Flow XML
  authoring (use sf-flow), nonprofit fundraising / gift processing
  (use sf-nonprofit-fundraising), nonprofit grant management
  (use sf-nonprofit-grants), nonprofit program enrollment where the org
  is NPC/NPSP without an education package installed
  (use sf-nonprofit-program-case), or Data Cloud ingestion of student
  data into DMOs (use sf-datacloud).
license: MIT
compatibility: "Education Cloud (native) OR EDA managed package (namespace hed__); may have both during migration"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "150 points across 7 categories — Edition fit 20 / Data model 30 / Workflow 25 / Process automation 20 / UX 15 / Integration 20 / Testing+compliance 20 (105 is passing). Category thresholds: Edition fit <14 / Data model <20 / Workflow <17 / Testing+compliance <12 = automatic fail."
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "150-pt rubric (7 categories) extracted from existing 'Scoring Rubric' section in this SKILL.md (line 263). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  education_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Edition fit + Data model correctness. Maps to Edition fit (20) + Data model (30). Education Cloud (native) vs EDA (hed__ namespace) is the foundational decision; wrong platform assumption poisons everything downstream."
      automatic_hard_fail_rules:
        - "EDA (hed__) and native Education Cloud confused — wrong objects used for the org's edition (per the rubric: Edition fit <14 = automatic fail)"
        - "Student modeled on Account or Lead instead of native Student object (Education Cloud) or appropriate Contact-with-hed__-record-type (EDA)"
        - "Program Enrollment / Course Connection / Term / Course Offering objects not used for academic operations (custom shadow objects)"
        - "Affiliation modeled with custom junction object when hed__Affiliation__c (EDA) or native Affiliation (EdC) exists"
        - "Migration mid-flight org built as if it were EDA-only or native-only (transition state requires both data models present)"
        - "Data model correctness <20 → automatic fail per the rubric"
    - name: Robustness
      max: 25
      hard_fail_below: 16
      description: "Testing + FERPA compliance. Maps to Testing+compliance (20). FERPA is non-negotiable; restricted-record FLS, Shield posture, persona UAT coverage are how the org survives an audit."
      automatic_hard_fail_rules:
        - "Testing+compliance <12 → automatic fail per the rubric (FERPA is not optional)"
        - "FERPA-restricted record fields not masked for non-privileged personas via FLS"
        - "Shield Platform Encryption not configured for the org's regulated student data when Shield is in scope"
        - "Apex tests / Flow tests missing on student-lifecycle write paths"
        - "Persona UAT coverage missing for student / faculty / advisor / admissions roles"
        - "Directory information vs PII fields not classified per FERPA — entire student record treated as one access tier"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Workflow correctness + Process automation + UX. Maps to Workflow (25) + Process automation (20) + UX (15). Right module for lifecycle stage (recruiting ≠ admissions ≠ advising); Flow-first; persona-appropriate pages."
      automatic_hard_fail_rules:
        - "Workflow correctness <17 → automatic fail per the rubric"
        - "Recruiting / admissions / advising workflows conflated (one process covering all three — module mismatch)"
        - "Apex trigger written when a Record-Triggered Flow expresses the same logic"
        - "Trigger logic without TriggerHandler pattern (handler proliferation; recursion-prone)"
        - "Persona pages (student / faculty / advisor / admissions) not differentiated by Record Page Assignment"
        - "Course Catalog / Term / Course Offering hand-rolled when native objects cover it"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Integration. Maps to Integration (20). SIS / LMS / National Student Clearinghouse / FAFSA / Common App wired correctly via documented patterns."
      automatic_hard_fail_rules:
        - "SIS / LMS integration without Named Credential / External Service / Platform Event pattern (raw HTTP / inline auth)"
        - "Synchronous SIS callouts in triggers (governor-limit / SIS-rate-limit exposure)"
        - "End-to-end test (SIS inbound → Program Enrollment → Course Connection → LMS grade writeback) skipped"
        - "FAFSA / Common App / Clearinghouse integration without staging-data smoke test"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.edc_overview.htm&type=5
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://powerofus.force.com/s/article/EDA-Documentation
    anchor: ""
    sha256: ""
    importance: authoritative
    status: "broken (410 / URL No Longer Exists as of 2026-05-04) — EDA docs retired from Power of Us Hub; Education Cloud is the supported path"
  - url: https://architect.salesforce.com/design/industries/education
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_industries_education.htm
---

# sf-industry-education: Education Cloud + EDA Architect

Expert Salesforce architect for **Education Cloud (native, 2024+)** and the **legacy Education Data Architecture (EDA) managed package** (namespace `hed__`). This skill owns the full student lifecycle on Salesforce: recruiting, admissions, enrollment, advising, retention, student success, alumni engagement, and academic operations (courses, terms, programs, plans).

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 150-pt rubric across 7 Education categories, extracted from this skill's existing Scoring Rubric section (line 263) and mapped onto the 4-dim shape. Two heaviest floors: Correctness 16 (Edition fit + Data model — wrong platform poisons everything downstream) and Robustness 16 (FERPA is non-negotiable). Hard-fail rules block EDA/Education-Cloud confusion, Student modeled on Account/Lead, FERPA-restricted fields exposed to non-privileged personas, recruiting/admissions/advising workflows conflated, persona pages undifferentiated, SIS/LMS integration via raw HTTP, and end-to-end test skipped. Disable with `eval_harness.enabled: false`.

This is an **industry skill**. When the org has Education Cloud or EDA installed and the request touches a student, program, course, term, affiliation, advising, recruiting, retention, or admissions concept, this skill wins over `sf-sales-cloud`, `sf-service-cloud`, and `sf-service-case` and they must defer here.

> **Edition note**: Education Cloud (native, built on the Industries Core platform since 2024) and EDA (Education Data Architecture, a managed package with the `hed__` namespace) are **different products with different data models**. Some orgs run one, some run the other, and orgs in active migration run both in parallel. This skill handles all three cases.

---

## 1. When This Skill Owns the Task

Use `sf-industry-education` when the work involves any of:

- Student records, Student Success records, or Person Account-based learners
- Program Enrollment (education context — native `ProgramEnrollment` or `hed__Program_Enrollment__c`)
- Course Connection, Course Offering, Course Catalog, Section
- Term, Academic Plan, Plan Requirement, Learning Path
- Affiliation (student ↔ institution, student ↔ department)
- Educational Institution records and hierarchy (institution → college → department)
- Recruiting (prospective student pipeline), Admissions funnel
- Advising appointments, advising notes, advisor caseload
- Retention risk modeling, early-alert workflows, student success cases
- Alumni engagement (graduated student lifecycle, giving intent, event attendance)
- FERPA handling considerations in Salesforce
- Migrating from EDA to Education Cloud, or integrating both during transition

### Delegate outside this skill

| Need | Delegate to | Reason |
|---|---|---|
| Pure sales pipeline (Leads → Opportunities) not tied to admissions/recruiting | [sf-sales-cloud] (generic) | Out of education scope |
| Generic customer-support Cases unrelated to students | [sf-service-case](../sf-service-case/SKILL.md) | Student support Cases stay here |
| Apex trigger / class implementation | [sf-apex](../sf-apex/SKILL.md) | Code execution, not model design |
| LWC component authoring | [sf-lwc](../sf-lwc/SKILL.md) | Component code, not data model |
| Salesforce Flow XML authoring | [sf-flow](../sf-flow/SKILL.md) | Declarative automation code |
| Ingesting student data into Data Cloud DMOs | [sf-datacloud](../sf-datacloud/SKILL.md) | Data Cloud unified-profile pipeline |
| Nonprofit program enrollment where **no education package is installed** | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) | NPC program model, not academic |
| Nonprofit fundraising against alumni (when donation is the primary ask) | [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) | Alumni giving is fundraising scope |
| OmniScript-based student intake forms | [sf-industry-commoncore-omniscript](../sf-industry-commoncore-omniscript/SKILL.md) | Guided UX belongs to OmniStudio |

---

## 2. Industry Precedence Note

`sf-industry-education` is an **industry skill**. Per the industry-first precedence rule:

- When Education Cloud or EDA is installed AND the request touches education-owned objects (Student, ProgramEnrollment, CourseConnection, Term, Affiliation, `hed__*`, LearningPath, AcademicPlan, etc.), `sf-sales-cloud`, `sf-service-cloud`, and `sf-service-case` must **halt and forward** here.
- This skill does **not** run `references/industry-precheck.md` — it is the destination of that pre-check.
- A student-support Case, even if it looks like "generic Case management", stays here because Education Cloud's Case Management for Students has education-specific fields, topics, and routing semantics that `sf-service-case` must not override.
- Admissions and Recruiting, even though they resemble Opportunity/Lead pipelines, use **Education Cloud's native recruiting/admissions objects** (or EDA Affiliations + custom stages). Do not silently recreate an Opportunity pipeline for applicants.

If in doubt, default to this skill whenever either package is detected.

---

## 3. EDA vs Native Education Cloud: Decision Tree

### Detection signals

Run these probes in order. First match wins.

```text
1. Does the org have the native Student object (API: Student) and
   ProgramEnrollment (native, not hed__Program_Enrollment__c)?
      YES → Native Education Cloud installed.
2. Does the org have objects in the hed__ namespace
   (hed__Term__c, hed__Course__c, hed__Course_Offering__c,
    hed__Program_Enrollment__c, hed__Affiliation__c)?
      YES → EDA managed package installed.
3. Both sets present?
      → Migration-in-progress. Ask the user which is authoritative for
        the workflow being designed. Do not silently pick one.
4. Neither?
      → Not an education org yet. Ask the user whether to install EDA
        (legacy track, still common in K-12 and small higher-ed) or stand
        up Education Cloud (preferred for net-new greenfield orgs).
```

Quick CLI / SOQL probes:

```bash
# Detect native Education Cloud
sf sobject describe -s Student -o <alias> 2>/dev/null
sf sobject describe -s ProgramEnrollment -o <alias> 2>/dev/null

# Detect EDA managed package
sf sobject describe -s hed__Program_Enrollment__c -o <alias> 2>/dev/null
sf sobject describe -s hed__Course_Offering__c -o <alias> 2>/dev/null

# Check installed packages
sf package installed list -o <alias>
```

### Migration considerations (EDA → Education Cloud)

- Education Cloud is **not** a simple upgrade of EDA. It is a re-platform onto the Industries Core (Person Account-based) data model. Field-by-field migration is rarely 1:1.
- Core re-mappings to plan for:
  - `hed__Account__c` (Administrative / Household / Business) → `Account` with `IsPersonAccount = true` for learners, standard Account for institutions.
  - `hed__Program_Enrollment__c` → `ProgramEnrollment` (native) — different picklists, different status lifecycle, new Affiliation relationship.
  - `hed__Course_Enrollment__c` / Course Connection → `CourseConnection` (native).
  - `hed__Term__c` → `Term` (native).
  - `hed__Affiliation__c` → `Affiliation` (native) with a normalized role/status model.
  - `hed__Education_History__c` → typically replaced by native admissions / prior-learning objects plus custom extensions.
- Run EDA and Education Cloud side-by-side during transition; keep the source of truth explicit per workflow. Decide object by object, not globally.
- Custom fields, validation rules, flows, and Apex that reference `hed__` objects will **not** auto-port. Treat them as net-new builds against the native data model.
- Reporting: dashboards rebuilt against native objects; legacy EDA dashboards will continue to work only against surviving `hed__` data.
- Doc availability: the canonical Power of Us Hub EDA Documentation page (`powerofus.force.com/s/article/EDA-Documentation`) now returns **"URL No Longer Exists"** (verified 2026-05-04). Treat this as a sunset signal — EDA runtime still works, but authoritative EDA reference material is being consolidated onto help.salesforce.com Education Cloud docs, not the Hub. Cache local copies of any EDA setup guides you still depend on.

### When to stay on EDA

- K-12 orgs that rely heavily on `hed__Relationship__c` family trees.
- Small higher-ed orgs with mature EDA customisations and no budget for re-platform.
- Workforce education providers where the managed package already models their cohort / learner / credential lifecycle adequately.

### When to move to (or start on) Education Cloud

- Net-new Salesforce implementations in 2024+.
- Orgs that want tight Data Cloud / Agentforce / Einstein integration (Education Cloud objects are first-class in unified-profile DMOs; `hed__` objects are not).
- Programs needing the native Advising, Retention, Student Success, and Recruiting modules — these are Education Cloud only.

---

## 4. Required Context to Gather First

Ask for or infer before proposing any data model or automation:

1. **Which edition?** Native Education Cloud, EDA, both (migration), or neither?
2. **Which persona / segment?**
   - Higher Ed (4-year, community college, graduate / professional schools)
   - K-12 (district, charter, private, state agencies)
   - Workforce / Continuing Education (bootcamps, credentialing bodies, adult learners)
3. **Learner lifecycle stage focus.** Recruiting, Admissions, Enrolled Student, Advising, Retention, Alumni — or the full spectrum?
4. **Student-or-Alumni focus.** Current-learner CRM vs graduated-constituent engagement have different data models and different permission needs.
5. **FERPA scope.** Is any Personally Identifiable Education Record being stored? Are Shield Platform Encryption, field-level encryption, event monitoring, and transaction security policies already in place?
6. **Integration surface.** Student Information System (SIS) of record? Learning Management System (LMS)? National Student Clearinghouse? Common App / UCAS / SRAR for admissions? FAFSA / financial aid?
7. **Roles & permission model.** Admissions counsellor, academic advisor, registrar, faculty, student success coordinator, retention analyst, alumni engagement officer — each needs a distinct permission set.
8. **Existing customisations** (EDA orgs especially). Custom fields on `hed__` objects? Custom `hed__Relationship__c` types? Trigger handlers on `hed__Affiliation__c`?

Without at least (1), (2), and (3), do not propose a data model. Halt and ask.

---

## 5. Workflow Phases

Always walk the phases in this order. Do not skip.

### Phase 1 — Edition detection

Run the detection tree in section 3. Record the result. If migration-in-progress, capture which side owns which workflow before any build work.

### Phase 2 — Persona / scope definition

Confirm: Higher Ed / K-12 / Workforce, and whether scope is Recruiting, Admissions, Enrollment, Advising, Retention, Student Success, or Alumni (or a combination). Write the scope into the design doc; it drives the data model.

### Phase 3 — Data model

Native Education Cloud core:

- **Student** — Person Account-based learner record. Do not model students as plain Contacts.
- **Educational Institution** — institution / college / department hierarchy via Account parent-child.
- **Affiliation** — links Student to Educational Institution (and sub-unit) with role and status.
- **Program Enrollment** (native) — learner enrolled in a program of study.
- **Course Connection** — learner's enrollment in a Course Offering / Section. Not a generic junction; carries grade, status, enrollment date, completion.
- **Term** — academic term (semester, quarter, trimester, rolling).
- **Course Catalog** + **Course** + **Section** — course definition and scheduled offerings.
- **Academic Plan** + **Plan Requirement** — degree / credential path definition.
- **Learning Path** — sequence of learning activities and milestones.

EDA equivalents (legacy):

- `hed__Program_Enrollment__c`, `hed__Course_Enrollment__c` (Course Connection), `hed__Course__c`, `hed__Course_Offering__c`, `hed__Term__c`, `hed__Affiliation__c`, `hed__Relationship__c`, `hed__Education_History__c`.

Rules:

- Never create a custom "Student__c" object when the native or EDA one fits.
- Never use a generic Case to stand in for a Student Success record.
- Never model courses as custom objects if Course + Course Offering (native) or `hed__Course__c` + `hed__Course_Offering__c` are available.

### Phase 4 — Module selection: Recruiting vs Retention vs Advising

Pick the right native module (Education Cloud only) or architect the EDA equivalent.

| Lifecycle stage | Native module | EDA approximation |
|---|---|---|
| Inquiry → Applicant | Recruiting | Affiliation (status=Prospective) + custom funnel fields |
| Applicant → Admitted | Admissions | Custom stages on Affiliation + `hed__Application__c` (if installed) |
| Admitted → Enrolled | Program Enrollment (native) | `hed__Program_Enrollment__c` |
| Enrolled → Advising | Advising (Appointment, Advisor Caseload) | Custom Advising objects or `hed__Relationship__c` + Events |
| Enrolled → At-Risk | Retention (Early Alert, Risk Score) | Custom retention scoring + Case |
| Enrolled → Case | Case Management for Students | Case with `hed__` lookups |
| Graduated → Alumni | Alumni Engagement | `hed__Affiliation__c` (status=Alumni) + custom |

### Phase 5 — Process automation

- Prefer **Flow** over Apex for student-lifecycle automations; only drop to Apex when state transitions, external callouts, or bulk jobs require it.
- Record-triggered flows on Program Enrollment status changes drive most retention and student-success triggers.
- Platform Events for SIS sync (inbound enrollment, term advancement) and LMS grade writeback.
- **Do not** daisy-chain Program Enrollment → Case → Affiliation updates through Apex triggers without a documented trigger handler. Use one handler per object, not one per workflow.

### Phase 6 — Testing

- Unit-test Apex against Person Account-based Student fixtures (use `sf-data` factory patterns; load a realistic Educational Institution hierarchy).
- Flow tests for every record-triggered automation on Program Enrollment, Course Connection, Affiliation.
- UAT scripts per persona: admissions counsellor can move a student from applicant → enrolled; advisor can log an advising appointment; retention analyst can trigger an early-alert case; alumni officer can record post-graduation engagement.
- FERPA validation: confirm field-level security masks restricted records for non-privileged personas.
- End-to-end: SIS inbound → Program Enrollment → Course Connection → LMS grade writeback, using staging data.

---

## 6. Scoring Rubric

Score 0–150 across 7 categories. Minimum passing score: **105 / 150**.

```
Score: XX/150
├─ Edition fit:              XX/20   (Correct detection of EDA vs native; right data model for the org)
├─ Data model correctness:   XX/30   (Student/Affiliation/Program Enrollment/Course Connection modelled correctly)
├─ Workflow correctness:     XX/25   (Right module for lifecycle stage; recruiting ≠ admissions ≠ advising)
├─ Process automation:       XX/20   (Flow-first, trigger handlers, SIS/LMS event patterns)
├─ User experience:          XX/15   (Persona-appropriate page layouts, record pages, lists)
├─ Integration:              XX/20   (SIS, LMS, National Student Clearinghouse, FAFSA, Common App wired correctly)
└─ Testing & compliance:     XX/20   (FERPA, Shield posture, Apex/Flow tests, persona UAT coverage)
```

Category thresholds (any one below threshold fails the design, regardless of total):

- Edition fit < 14 → fail (wrong platform assumption poisons everything downstream).
- Data model correctness < 20 → fail.
- Workflow correctness < 17 → fail.
- Testing & compliance < 12 → fail (FERPA is not optional).

---

## 7. Anti-Patterns

1. **Forcing native Education Cloud where EDA is still in use.** Migration is a project, not a side-effect of one feature. If the user says "just add a field to Program Enrollment" and the org is EDA, add it to `hed__Program_Enrollment__c`, not to the native object.
2. **Treating Course Connection as a generic junction object.** Course Connection carries grade, status, enrollment date, completion, credit earned — it is an entity, not a lookup table. Building a parallel custom junction breaks reporting, rollups, and retention scoring.
3. **Storing FERPA-protected data without Shield or equivalent field-level encryption.** Directory information ≠ education records. Grades, disciplinary records, and disability accommodations require Shield Platform Encryption, audited access, and event monitoring.
4. **Modelling students as plain Contacts** (on Business Accounts) instead of Person Account-based Student records (native) or `hed__Account_Model=Household` (EDA). This breaks every downstream Education Cloud object that expects Student.
5. **Using generic Cases for student-success interventions** instead of Case Management for Students. The native module carries retention-specific fields and routing that generic Service Cloud Case Management does not.
6. **Recreating Admissions as an Opportunity pipeline** because "admissions looks like sales." It isn't. Education Cloud has dedicated recruiting/admissions objects; using Opportunity silently cuts you off from the native admissions funnel, yield analytics, and Enrollment Management.
7. **Skipping Affiliation** and stuffing institution / department information as fields on the Student. Affiliation is how the data model expresses "this student belongs to this college within this institution with this role." Flattening it breaks hierarchy reporting and alumni lifecycle tracking.
8. **One giant Apex trigger on Program Enrollment** that handles enrollment, retention, advising, and alumni in one class. Violates single-responsibility; makes FERPA audits impossible; breaks on bulk SIS syncs.
9. **Ignoring Term in scheduling.** Course Offering belongs to a Term. Skipping Term makes cohort reporting, retention-by-term analysis, and academic plan sequencing impossible.
10. **Mixing EDA and Education Cloud automations on the same record lifecycle** without explicit handoff rules. If both trigger on enrollment change, you get double-writes, infinite loops, or silent data loss.

---

## 8. Common Failure Modes + Remediation

| Symptom | Root cause | Fix |
|---|---|---|
| Students appear twice in reports after EDA → Education Cloud migration | Dual-platform writes (EDA automation still running alongside native) | Disable EDA record-triggered automations on migrated objects; keep EDA read-only until full cutover; add a migration flag field to suppress dual writes |
| Advising appointments not surfacing on student record page | Advisor caseload relationship missing (Affiliation with Role=Advisor not created) | Create Affiliation linking advisor Contact → Student with role=Advisor, active status; add related list to Student page layout |
| Retention early-alert flows not firing on grade drop | Course Connection grade updated via LMS API, bypassing record-triggered flow criteria | Switch to platform-event-driven architecture; LMS emits GradeChanged event, flow subscribes and evaluates retention thresholds |
| FERPA audit flagging exposed grades in reports | Field-level security on Course Connection's grade field not restricted to registrar / faculty | Lock FLS to registrar persona, add Shield encryption on grade field, enable event monitoring on Course Connection read events |
| Alumni engagement metrics missing after graduation | Affiliation status not transitioning from Enrolled → Alumni at program completion | Record-triggered flow on Program Enrollment status=Completed sets matching Affiliation status=Alumni; ensure both native and any legacy `hed__Affiliation__c` records are updated during migration |

---

## 9. Object Cheat Sheet

### Native Education Cloud

| Object | API Name | Purpose | Key Fields |
|---|---|---|---|
| Student | Student | Person Account-based learner | PersonAccount, StudentId, StartDate, Status |
| Educational Institution | Account (RecordType=EducationalInstitution) | Institution / college / department hierarchy | Name, ParentId, Type |
| Affiliation | Affiliation | Student ↔ Institution relationship | Student, Account, Role, Status, StartDate, EndDate |
| Program Enrollment | ProgramEnrollment | Learner in a program of study | Student, Program, Status, EnrollmentDate, ExpectedGraduation |
| Course Connection | CourseConnection | Enrollment in a course offering | Student, CourseOffering, Grade, Status, Credit |
| Term | Term | Academic term | Name, StartDate, EndDate, Type (Semester/Quarter/Trimester) |
| Course Catalog | CourseCatalog | Catalog container | Name, Institution, Active |
| Course | Course | Course definition | Name, Code, Description, Credits, Catalog |
| Section | Section | Scheduled offering instance of a course | Course, Term, Capacity, Instructor |
| Academic Plan | Plan | Degree / credential path | Name, Program, TotalCreditsRequired |
| Plan Requirement | PlanRequirement | Specific requirement within a plan | Plan, Course, RequiredCredits |
| Learning Path | LearningPath | Sequence of learning activities | Name, Student, Status, StartDate |
| Advising Appointment | AdvisingAppointment | Student ↔ Advisor meeting | Student, Advisor, ScheduledDate, Topic |
| Case (Student Success) | Case (RecordType=StudentSuccess) | Student support case | Student, Subject, Status, Priority |

### Legacy EDA (`hed__` namespace)

| Object | API Name | Purpose | Key Fields |
|---|---|---|---|
| Term | hed__Term__c | Academic term | Name, hed__Account__c, hed__Start_Date__c, hed__End_Date__c |
| Course | hed__Course__c | Course definition | Name, hed__Account__c, hed__Credit_Hours__c |
| Course Offering | hed__Course_Offering__c | Scheduled course instance | hed__Course__c, hed__Term__c, hed__Capacity__c |
| Course Connection | hed__Course_Enrollment__c | Learner enrollment in a course offering | hed__Contact__c, hed__Course_Offering__c, hed__Grade__c, hed__Status__c |
| Program Enrollment | hed__Program_Enrollment__c | Learner in a program | hed__Contact__c, hed__Account__c, hed__Enrollment_Status__c |
| Affiliation | hed__Affiliation__c | Contact ↔ Account (institution / department) relationship | hed__Contact__c, hed__Account__c, hed__Role__c, hed__Status__c |
| Relationship | hed__Relationship__c | Contact ↔ Contact (parent, guardian, sibling, spouse) | hed__Contact__c, hed__RelatedContact__c, hed__Type__c |
| Education History | hed__Education_History__c | Prior institutions / degrees | hed__Contact__c, hed__Account__c, hed__Degree_Earned__c |
| Case (Student) | Case + `hed__` lookups | Student case with EDA context | ContactId (student), hed__ custom lookups as configured |

### FERPA Callout

The **Family Educational Rights and Privacy Act (FERPA, 20 U.S.C. § 1232g)** governs disclosure of education records in US institutions. On Salesforce:

- Grades, disciplinary records, disability accommodations, and financial aid details are **education records**, not directory information. Protect them.
- Apply **Shield Platform Encryption** on encrypted fields (grade, SSN, accommodation notes) — probabilistic encryption is insufficient where determinism is not required; use deterministic only where filtering is needed.
- Enable **Event Monitoring** on Course Connection, Program Enrollment, and Case (Student Success) reads.
- Use **Restriction Rules** (not just sharing rules) to gate visibility of FERPA records to registrar / faculty personas with a documented legitimate educational interest.
- Audit permission sets against FERPA scope quarterly. Log reviews in a compliance object.
- When integrating with LMS / SIS, confirm TLS 1.2+, named credentials with rotated secrets, and no PII in log payloads.
- International equivalents (GDPR for EU learners, PIPEDA for Canadian learners, state-level US laws like California SOPIPA for K-12) stack on top of FERPA — scope them per region.

---

## Terminology

- **Education Cloud** — Native Salesforce product for education, launched 2024, built on the Industries Core (Person Account) platform.
- **EDA** — Education Data Architecture, the legacy managed package (namespace `hed__`) that predates Education Cloud; still widely deployed.
- **Student (native)** — Person Account-based learner record in Education Cloud.
- **Program Enrollment** — learner's enrollment in a program of study (degree, credential, certificate).
- **Course Connection** — learner's enrollment in a specific Course Offering / Section (not a generic junction).
- **Affiliation** — relationship between a learner and an Educational Institution (or sub-unit), with role and status.
- **Term** — academic term (semester, quarter, trimester, rolling).
- **Academic Plan** — degree or credential path; composed of Plan Requirements.
- **Learning Path** — sequenced set of learning activities and milestones for a learner.
- **Recruiting** — prospective-student lifecycle (inquiry → applicant).
- **Admissions** — applicant-to-admitted lifecycle.
- **Retention** — tracking and intervention for at-risk enrolled students.
- **Advising** — advisor caseload, appointments, notes.
- **Student Success** — wraparound support case management for enrolled students.
- **Alumni Engagement** — post-graduation constituent engagement.
- **FERPA** — Family Educational Rights and Privacy Act; US federal law governing education-record disclosure.
- **SIS** — Student Information System (system of record for enrollment, grades, schedules).
- **LMS** — Learning Management System (Canvas, Blackboard, Moodle, etc.).
- **Shield** — Salesforce Shield (Platform Encryption + Event Monitoring + Field Audit Trail).
