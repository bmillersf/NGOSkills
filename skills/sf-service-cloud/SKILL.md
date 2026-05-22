---
name: sf-service-cloud
description: >
  Salesforce Service Cloud product orchestrator covering the Case lifecycle, Service Console,
  Omni-Channel routing, Knowledge, Entitlements/Milestones, Service Contracts, Assets,
  Incident Management, Service Cloud Voice, Messaging/Live Chat, Self-Service, CTI, and
  Einstein for Service.
  TRIGGER when: user asks for a multi-phase Service Cloud design or remediation; says
  "stand up Service Cloud", "design a support operation", "build a case-to-resolution
  workflow", "configure the Service Console", "rework our contact center on Salesforce",
  "SLA-driven support model", "enable omni-channel with knowledge and entitlements";
  asks how to wire Case + Omni-Channel + Knowledge together; needs a cross-phase decision
  about where routing, SLA, or KB ownership lives; asks about Service Cloud Voice,
  Messaging for In-App and Web, Einstein Case Classification / Reply / Work Summaries,
  Incident Management linking Cases → Incidents → Problems, CTI/Open CTI integration,
  or Service Contracts + Assets + Entitlements layering. Also triggers on "which
  Service Cloud skill should I use" and any request that spans two or more Service
  Cloud phase skills below.
  DO NOT TRIGGER when: the task is clearly scoped to one Service Cloud phase — Case,
  Entitlements, Milestones, SLA, Email-to-Case, Web-to-Case (use sf-service-case);
  Omni-Channel routing, Presence, Queues, Skills-Based or Attribute-Based Routing,
  Supervisor dashboards, Omni Flow (use sf-service-omnichannel); Knowledge articles,
  data categories, article workflow, multi-language, Einstein Search Answers
  (use sf-service-knowledge); Work Orders, Service Appointments, dispatcher console,
  mobile technician workflow, scheduling optimization (use sf-field-service); an
  industry cloud is installed and the request touches industry-owned objects — defer
  via Phase 0 to sf-industry-fsc, sf-industry-health, sf-industry-education,
  sf-industry-public-sector, sf-field-service, sf-nonprofit-program-case,
  sf-nonprofit-cloud, sf-industry-manufacturing, sf-industry-consumer-goods,
  sf-industry-communications, sf-industry-media, sf-industry-energy; generic Sales
  Cloud pipeline work (use sf-sales-cloud); Opportunity / forecasting / CPQ
  (use sf-sales-opportunity, sf-sales-engagement); Marketing Cloud Growth journeys
  or email campaigns (use sf-marketing-cloud-growth); Apex classes, triggers, or
  invocables — even ones that fire on Case (use sf-apex); LWCs that render on the
  Service Console (use sf-lwc); Flow XML authoring, screen or record-triggered
  flows acting on Case (use sf-flow); Data Cloud ingestion/harmonization/segmentation
  /activation of service data (use sf-datacloud and phase skills); Agentforce agent
  topics/actions built on Case or Knowledge (use sf-ai-agentforce — return here only
  for the Service data model question).
license: MIT
compatibility: "Requires Service Cloud user licenses; Voice, Messaging, Einstein for Service, and Knowledge are add-ons"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "150 points across 11 categories — orchestrator (Industry pre-check 15 / Edition+license 15 / Phase localization 20 / Routing topology 15 / Case+SLA 20 / Knowledge+self-service 15 / Console 10 / Voice/CTI 10 / Einstein+Agentforce 10 / Metrics+governance 10 / Delegation+output 10)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "150-pt rubric (11 categories) extracted from existing 'Scoring Rubric' section in this SKILL.md (line 248). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  service_cloud_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 16
      description: "Industry pre-check + Phase localization. Maps to Industry pre-check (15) + Phase localization (20). Like sf-sales-cloud, this is an orchestrator — silent override of an industry data model is the dominant defect class."
      automatic_hard_fail_rules:
        - "Industry pre-check skipped (FSC/Health/Education/PSS/Field Service/Manufacturing/Consumer Goods/Comms/Media/Energy/Nonprofit) — automatic fail per the rubric"
        - "Industry signal positive but no deferral emitted — silent override of an industry-owned data model"
        - "Single-phase work (Case-only / Omni-only / Knowledge-only / Voice-only) authored here instead of routed to the focused phase skill"
        - "Field Service signal (FieldServiceStandard) detected but work-order-adjacent cases not routed to sf-field-service"
        - "Channel → queue → skill → agent routing topology missing or partial when Omni-Channel is in scope"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Case data model + SLA + Voice integrity. Maps to Case+SLA (20) + Voice/CTI (10). SLA strategy is regulated by entitlement vs contract vs flow choice; Voice introduces PII recording obligations."
      automatic_hard_fail_rules:
        - "Custom Flow-based SLA timer recommended when Entitlements + Milestones cover the requirement (duplicates platform capability + drifts on Business Hours change)"
        - "Voice / CTI recommended without naming recording retention + PII redaction + data residency model (PCI/HIPAA/GDPR exposure)"
        - "Assignment rules + Omni-Channel both wired without explicit precedence (double-assignment bug)"
        - "Per-product Case record types for every SKU (record-type sprawl — page-layout unmaintainability)"
        - "Einstein Case Classification recommended without confirming ≥1,000 labeled cases per field (model degrades; agents distrust)"
        - "Service Cloud Voice + Messaging recommended without confirming Voice edition / Messaging channel licenses are present"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "Routing topology + Knowledge strategy + Console productivity. Maps to Routing topology (15) + Knowledge+self-service (15) + Console (10) + Delegation+output (10). Phase skills receive needed context; Knowledge uses Data Categories + Publication Workflow; utility bar audited; structured handoff emitted."
      automatic_hard_fail_rules:
        - "Knowledge org without Article Types + Data Categories + Publication Workflow + Multi-Language strategy (devolves into stale drafts + duplicate articles)"
        - "Console utility bar 'junk drawer' — every utility bar item recommended without 80%-of-agents-in-30-days usage criterion"
        - "Hand-off to phase skill (sf-service-case / sf-service-omnichannel / sf-service-knowledge / sf-field-service) without context (deferred work loses the orchestrator's analysis)"
        - "Cross-cloud boundary (Sales / Marketing / Data Cloud / Industry / Voice partner) drawn implicitly — adjacent skill not explicitly called out"
        - "Output not in the documented orchestrator output format (industry pre-check confirmation + per-phase delegation status + scoring summary)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Edition/license/channel mix + metrics + Einstein readiness. Maps to Edition/license/channel (15) + Metrics+governance (10) + Einstein+Agentforce (10). All 14 context items captured; metrics + reporting surface chosen + ownership named; Einstein activated only with training-data maturity."
      automatic_hard_fail_rules:
        - "Edition / license / channel mix incomplete (one or more of the 14 context items neither captured nor explicitly N/A'd)"
        - "Reply Recommendations recommended without labeled Chat transcripts (no signal)"
        - "Work Summaries recommended without completed-case transcripts (no signal)"
        - "Metrics surface (CSAT / FCR / AHT / SLA attainment / NPS) recommended without naming reporting tool + ownership"
        - "Score below 120 / 150 returned to user without revise pass"
  test_rubric:
    unit:
      required: true
      criteria: "Phase 0 industry pre-check executed: ApexClass NamespacePrefix scan + license + edition check. All 14 context items captured or N/A'd. Channel-queue-skill-agent topology documented. Stage → Forecast Category-equivalent (Case status → SLA outcome) mapping explicit."
    integration:
      required: true
      criteria: "Recommended changes deploy to a Service Cloud sandbox without industry-package upgrade conflicts. Case lifecycle runs end-to-end (channel intake → assignment → SLA timer → resolution → closure). Omni-Channel routes a sample work item correctly. Knowledge article surfaces in console for the right Case type."
    smoke:
      required: true
      criteria: "Agent walks the case-to-resolution path on the Service Console: case received via configured channel → routed via Omni-Channel → SLA timer fires → Knowledge article suggested → resolution recorded → closure satisfies milestone. Voice / Messaging / Einstein features respect license boundaries."
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.service_cloud_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.service_presence_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/service
    anchor: ""
    sha256: ""
    importance: supplemental
  - url: https://help.salesforce.com/s/articleView?id=sf.incidentmgmt_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.voice_intro.htm
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_service.htm
---

# sf-service-cloud: Service Cloud Product Orchestrator

Use this skill when the user needs **product-level Service Cloud guidance** rather than a single isolated feature: standing up a contact center, redesigning a support operation, wiring the Case object together with Omni-Channel, Knowledge, Entitlements, Service Contracts, and Einstein for Service, or deciding which phase skill should own a given sub-task.

This skill is the **parent router** for the Service Cloud family. It keeps cross-cutting context (edition, licenses, channel mix, SLA model, agent volume, console layout) that every phase skill depends on, and hands off to the specialist skills listed below once the phase is localized.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 150-pt rubric across 11 orchestrator categories, extracted from this skill's existing Scoring Rubric section (line 248) and mapped onto the 4-dim shape. Correctness floor at 16 — like sf-sales-cloud, this is a parent router; silent override of an industry data model is the dominant defect class. Hard-fail rules block missing industry pre-check, custom Flow-based SLA when Entitlements+Milestones cover the requirement, Voice/CTI without recording-retention/PII model, Einstein activated without training-data maturity, and assignment-rules + Omni-Channel both wired without precedence. Disable with `eval_harness.enabled: false`.

---

## When This Skill Owns the Task

Use `sf-service-cloud` when the work involves:

- A greenfield Service Cloud implementation or major redesign spanning Case + Channels + Knowledge + SLA
- Deciding where a responsibility lives (e.g., "should SLA tracking sit on Milestones, Entitlements, or a Flow?")
- Channel strategy — email, web, phone (Voice), chat (Messaging for In-App & Web), in-product, community, case swarming
- Service Console layout, utility bar, workspace tabs, console actions, macro strategy
- Incident Management topology: Case → Incident → Problem → Change, broadcast comms, status page integration
- Service Cloud Voice architecture: Amazon Connect vs Partner Telephony vs Bring Your Own Channel
- Einstein for Service planning: Case Classification, Reply Recommendations, Work Summaries, Article Recommendations
- Assets + Service Contracts + Entitlements layering (who gets what SLA based on which asset/contract)
- Self-Service strategy: Experience Cloud case deflection, chatbot hand-off, Knowledge surfacing
- Cross-phase troubleshooting where the root cause is not yet localized to Case / Omni / Knowledge / Field Service
- Service metrics model: FRT, ART, CSAT, FCR, Milestone compliance, Presence-based capacity

### Delegate to a phase skill

| Phase | Use this skill | Typical scope |
|---|---|---|
| Case data model + SLA | [sf-service-case](../sf-service-case/SKILL.md) | Case record types, Case Teams, Email/Web-to-Case, Assignment/Escalation rules, Entitlements, Milestones, Service Contracts, Incidents on Case |
| Routing + presence + queues | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Omni-Channel Routing Configurations, Presence Statuses, Queues, Skills-Based Routing, Attribute-Based Routing, External Routing, Supervisor, Omni Flow |
| Knowledge base | [sf-service-knowledge](../sf-service-knowledge/SKILL.md) | Lightning Knowledge, Article Types, Data Categories, Article versioning, multi-language, Einstein Search Answers, Article-to-Case |
| Field Service | [sf-field-service](../sf-field-service/SKILL.md) | Work Orders, Service Appointments, Resources, Territories, Skills, Scheduling Policies, Dispatcher Console, Mobile |

### Delegate outside the Service Cloud family

| Need | Route to | Boundary |
|---|---|---|
| Apex triggers / handlers / batch on Case | [sf-apex](../sf-apex/SKILL.md) | This skill owns the data model; sf-apex writes the code |
| LWC for the Service Console | [sf-lwc](../sf-lwc/SKILL.md) | Specify fields here, build the component there |
| Flow authoring (record-triggered, screen, Omni Flow XML mechanics) | [sf-flow](../sf-flow/SKILL.md) | Name the trigger object here, build the flow there |
| Custom fields / record types / layouts XML | [sf-metadata](../sf-metadata/SKILL.md) | After the Service design is locked |
| SOQL against Case, CaseMilestone, KnowledgeKavs | [sf-soql](../sf-soql/SKILL.md) | Query authoring only |
| Permission set / FLS / Service Cloud user license audit | [sf-permissions](../sf-permissions/SKILL.md) | License sizing stays here; FLS audit routes out |
| Named Credential / callout to CRM adjuncts, CTI middleware, ITSM | [sf-integration](../sf-integration/SKILL.md) | Integration design here, wiring there |
| Connected App / OAuth for CTI or Voice partner | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Foundation before sf-integration |
| Agentforce topics/actions on Case or Knowledge | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Service model here, agent metadata there |
| Data Cloud ingestion of service data | [sf-datacloud](../sf-datacloud/SKILL.md) | Case → DMO mapping lives in the Data Cloud family |
| Marketing Cloud outbound transactional email | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | Transactional journey design lives there |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before any Service Cloud work, run the shared [industry pre-check](../../references/industry-precheck.md). This is non-negotiable for every generic cloud skill.

**NEVER silently override an industry data model.** If an industry cloud is installed AND the user's request touches industry-owned objects or processes, halt immediately and forward to the industry skill. The generic Service Cloud stack does not customize on top of industry models — it defers.

### Deferral map

| Detected industry (license / namespace) | Objects / processes where this skill MUST defer | Route to |
|---|---|---|
| Financial Services Cloud (`FinServ__`, `FinancialServicesCloudStandard`) | Case record types `FinServ__BankingCare` / `FinServ__WealthCare` / `FinServ__InsuranceCare`, Interaction / Interaction Summary, Compliant Data Sharing participants on Case, Financial Account-linked cases | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) |
| Health Cloud (`HealthCloudGA__`, `HealthCloudGA`) | CareRequest, Care Plan Case, Clinical Service Request, Patient Case, utilization management cases | [sf-industry-health](../sf-industry-health/SKILL.md) |
| Education Cloud / EDA (`hed__`, `EducationCloudForStudentSuccess`) | Advising Cases, Student Support Case record types, Case → Program Enrollment linkage | [sf-industry-education](../sf-industry-education/SKILL.md) |
| Public Sector Solutions (`OutfundsPS__`, `PublicSectorSolutions`) | BusinessLicense, Permit, Inspection, RegulatoryCodeViolation, IndividualApplication, Complaint-to-Case workflow | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) |
| Field Service (`FieldServiceStandard`, `FSL`) | WorkOrder, WorkOrderLineItem, ServiceAppointment, ServiceResource, ServiceTerritory, Skill, Dispatcher Console, Mobile | [sf-field-service](../sf-field-service/SKILL.md) |
| Nonprofit Cloud program/case (`NonprofitCloudCaseManagement`) | Program, ProgramEnrollment, CasePlan, Benefit, Goal, nonprofit client case management | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) |
| Nonprofit Cloud generic | Gift Transaction-linked service cases, Funding Award-linked cases, constituent service | [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) |
| Manufacturing Cloud (`ManufacturingCloudUser`, `Mfg`) | Sales Agreement cases, ManufacturingWorkOrder, warranty-linked cases, rebate disputes | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) |
| Consumer Goods Cloud (`ConsumerGoodsCloudUser`, `CG`) | Retail Store Visit cases, Retail Execution disputes, trade promotion disputes | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) |
| Communications Cloud (`vlocity_cmt__`, `CommunicationsCloudUser`) | Order management cases, number management cases, ESM-backed cases | [sf-industry-communications](../sf-industry-communications/SKILL.md) |
| Media Cloud (`vlocity_media__`, `MediaCloudUser`) | Subscriber cases, entitlement disputes, billing-account cases | [sf-industry-media](../sf-industry-media/SKILL.md) |
| Energy & Utilities Cloud (`vlocity_ins__` + `EnergyAndUtilities`) | Premise/Service Point cases, Meter disputes, Work Request service cases | [sf-industry-energy](../sf-industry-energy/SKILL.md) |

### Deferral procedure

1. Run detection per `references/industry-precheck.md` (license scan → namespace scan → EntityDefinition fallback).
2. If a positive match exists AND the user's request overlaps any row above, print a one-line handoff:
   `Detected {industry} is installed. Routing to sf-{industry-skill} because this request touches {matched object/process}.`
3. Stop the generic Service Cloud workflow.
4. Only proceed in this skill if detection is negative, OR the user explicitly requests "standard Salesforce, bypass the industry overlay" (document the exception in the final report).

---

## Required Context to Gather First

Before proposing a Service Cloud design:

1. **Edition & licenses** — Service Cloud (Enterprise / Unlimited / Einstein 1 Service), Voice edition (Starter / Partner Telephony / BYO Channel), Messaging edition, Digital Engagement SKU, Field Service licenses, Einstein for Service SKUs.
2. **Channel mix** — email volume, web-to-case volume, voice call volume & AHT target, chat / messaging volume, community self-service, in-product help, social.
3. **Agent population** — total headcount, concurrent agents by shift, tiers (T1/T2/T3), specializations (skills), work-from-home posture (affects Voice).
4. **SLA posture** — entitlement-driven vs contract-driven vs assignment-rule-driven; how many SLA tiers; business hours model; holidays; milestone cadence (FRT, ART, resolution).
5. **Record type topology** — how many Case record types, what drives them (channel, product line, severity, region, industry), page layout per record type.
6. **Routing model** — queues only, Omni-Channel with pushed work, skills-based, attribute-based, external routing, or a hybrid. Re-routing rules when capacity is full.
7. **Knowledge posture** — Lightning Knowledge on or not; article types; publication workflow; multi-language; Einstein Search Answers licensed; Knowledge surfaced in community.
8. **Incident / Problem model** — using native Incident Management? Linking to an external ITSM (Jira Service Management, ServiceNow)?
9. **CTI / Voice** — Service Cloud Voice, Open CTI partner (Genesys, NICE, Five9, Talkdesk, Amazon Connect), or no integration.
10. **Einstein features** — Case Classification, Case Wrap-up, Reply Recommendations, Work Summaries, Article Recommendations — which are licensed, trained, and deployed.
11. **Self-service** — Experience Cloud customer site, Help Center, Bot (Agentforce / Einstein Bots legacy), case deflection mechanism.
12. **Service metrics source of truth** — are FRT, ART, CSAT reported from Salesforce, from a BI tool, or from the CTI platform?
13. **Integration surfaces** — ERP (SAP, Oracle), order management, billing, asset registry, ITSM, survey platform, knowledge source system.
14. **Compliance** — PCI (payment via phone), HIPAA (Health Cloud overlay), GDPR/CCPA data subject requests on Case, recording retention for Voice.

---

## Workflow Phases

### Phase 1 — Pre-Check & Scope Lock

1. Run **Phase 0 industry pre-check**. Halt and forward if positive.
2. Confirm edition, licenses, and channel mix (context items 1–3 above).
3. Decide whether the work is single-phase (localize and hand off now) or multi-phase (stay in this skill).
4. Document which phase skills will be involved downstream.

### Phase 2 — Channel & Routing Topology

1. List active and planned channels; map each to the Salesforce surface (Email-to-Case, Web-to-Case, Messaging for In-App and Web, Voice, Social Customer Service, Experience Cloud case form, API).
2. Decide on the routing strategy (Queues only vs Omni-Channel; skills-based vs attribute-based vs external). Delegate detail design to [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md).
3. Confirm Presence-based capacity targets (concurrent work items per agent per channel).

### Phase 3 — Case Data Model, SLA & Entitlements

1. Lock Case record types, page layouts, and automation triggers. Delegate to [sf-service-case](../sf-service-case/SKILL.md).
2. Choose the SLA mechanism: Entitlements + Milestones (recommended), Service Contracts + Entitlements, or Flow-only SLAs (not recommended except for edge cases).
3. Wire Assets + Service Contracts + Entitlements if hardware/subscription-backed support.
4. Decide whether native Incident Management (Incident, Problem, Change, Broadcast Alert) is in scope.

### Phase 4 — Knowledge & Self-Service

1. Confirm Lightning Knowledge is enabled; design article types and the data-category hierarchy. Delegate to [sf-service-knowledge](../sf-service-knowledge/SKILL.md).
2. Decide whether Einstein Search Answers + Article Recommendations are licensed and in scope.
3. Determine self-service surfaces: Experience Cloud site, Help Center, chatbot, in-product help.
4. Plan article-to-case linking + deflection metrics.

### Phase 5 — Console, Productivity & Agent Experience

1. Design the Service Console: workspace tabs, utility bar (Omni widget, Voice softphone, Macros, History, Notes, Knowledge sidebar), list views, console actions.
2. Plan Macros, Quick Text, Email Templates, Lightning Email Composer.
3. Decide on case swarming strategy (Slack Swarming, case team collaboration, case hierarchy).
4. Plan Einstein for Service UI surfaces (Reply recommendations, Work Summaries, Field predictions).

### Phase 6 — Voice / CTI (if applicable)

1. Choose Voice edition: Service Cloud Voice with Amazon Connect, Partner Telephony (NICE, Genesys, Five9, Talkdesk), or BYO Channel. Each has distinct telephony cost, data residency, and recording model trade-offs.
2. Plan the Voice Call record model, transcription storage, recording retention, and PII redaction.
3. Wire softphone (Open CTI or Voice-native) and plan the agent login flow.
4. Plan supervisor features: live monitoring, whisper coach, barge.

### Phase 7 — Incident Management & Escalation

1. If native Incident Management is in scope, model Incident, Problem, Change, Broadcast Alert record linkages.
2. Link Case → Incident (many-to-one), Incident → Problem (many-to-one), Incident → Change.
3. Define the major-incident escalation flow: detection → Incident creation → stakeholder broadcast → status page → postmortem → Problem.
4. Integrate with ITSM if external (typically ServiceNow or Jira Service Management) via Named Credentials + Platform Events. Delegate wiring to [sf-integration](../sf-integration/SKILL.md).

### Phase 8 — Einstein for Service & Agentforce

1. Enumerate Einstein features in scope (Case Classification, Reply Recommendations, Work Summaries, Article Recommendations, Service Replies for Chat, Einstein Bots / Agentforce agents).
2. Confirm training-data availability (minimum 1,000 labeled cases for Case Classification).
3. For Agentforce hand-off, design the escalation contract: Agent → Human transfer triggers, context carried via Case, transcript preservation. Delegate the agent metadata to [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md).

### Phase 9 — Metrics, Reporting & Governance

1. Define the service metric model (FRT, ART, MTTR, CSAT, FCR, agent utilization, milestone-compliance, deflection rate).
2. Decide reporting surface: standard Reports & Dashboards, CRM Analytics, Tableau, or external BI.
3. Establish governance: record-type ownership, SLA policy ownership, article lifecycle ownership, omni-channel capacity ownership.

### Phase 10 — Verify & Hand Off

1. Confirm each phase skill received the context it needs.
2. Capture assumptions, deferred decisions, and open risks.
3. Emit a structured summary (see Output Format).

---

## Scoring Rubric (150 points total — 120 is passing)

| Category | Max | Pass threshold | What earns points |
|---|---|---|---|
| Industry pre-check executed and documented | 15 | 12 | Detection ran; deferral decision explicit; exception (if any) justified |
| Edition / license / channel mix captured | 15 | 11 | All 14 context items gathered or explicitly marked N/A |
| Phase localization correct | 20 | 15 | Single-phase work handed off; multi-phase work stays here with delegation plan |
| Routing topology designed | 15 | 11 | Channel → queue → skill → agent mapping is coherent |
| Case data model + SLA strategy correct | 20 | 15 | Entitlement vs Contract vs Flow decision documented; record-type topology justified |
| Knowledge + self-service strategy | 15 | 11 | Article types, data categories, deflection, multi-language accounted for |
| Console + productivity plan | 10 | 7 | Utility bar, macros, quick text, swarming plan covered |
| Voice / CTI decision (if in scope) | 10 | 7 | Voice edition vs Open CTI partner vs BYO documented; recording/PII model named |
| Einstein + Agentforce plan | 10 | 7 | Features, training data, hand-off contract named |
| Metrics + governance | 10 | 7 | Metrics defined, reporting surface chosen, ownership named |
| Delegation + output format | 10 | 7 | Correct phase skills named; structured summary emitted |

Fail gates: Industry pre-check skipped = automatic fail. Silent override of an industry data model = automatic fail regardless of total score.

---

## Anti-Patterns

1. **Skipping Phase 0.** Running this skill on an FSC / Health / Education / PSS / Nonprofit / Field Service / Manufacturing / Consumer Goods / Comms / Media / Energy org without running the industry pre-check. Silent override of an industry model is always wrong.
2. **Rolling your own SLA in Flow when Entitlements + Milestones will do.** Custom Flow-based SLA timers duplicate a platform capability, miss business-hour math, and silently drift when the business hours calendar changes. Reserve Flow-based SLA for exotic multi-tier commitments that the standard objects genuinely cannot express.
3. **Letting assignment rules own routing when Omni-Channel is available.** Assignment rules set an owner at creation and stop; Omni-Channel pushes work by real-time capacity. Mixing both without clear precedence produces double-assignment bugs.
4. **Treating Knowledge as a generic content repo.** Without Data Categories + Publication Workflow + Multi-Language, a Lightning Knowledge org rapidly devolves into stale drafts, duplicate articles, and broken article-to-case links.
5. **Wiring Voice before confirming recording retention, PII redaction, and data residency.** Service Cloud Voice records calls by default; PCI/HIPAA/GDPR obligations often require a different design than the out-of-box one.
6. **Creating per-product Case record types for every SKU.** Record-type sprawl kills page-layout manageability. Drive variation with picklists and dynamic forms, keep record types to genuinely distinct process variants (e.g., B2B vs B2C, Incident vs Question vs Complaint).
7. **Letting the Service Console utility bar become a junk drawer.** Each utility bar item eats session memory and slows first load. Audit quarterly; remove anything not used by 80% of agents in the last 30 days.
8. **Enabling every Einstein for Service feature before confirming training data and UI integration.** Case Classification needs 1,000+ labeled cases per field; Reply Recommendations need labeled Chat transcripts; Work Summaries need completed-case transcripts. Without these, the models degrade and agents distrust them.
9. **Forgetting that Field Service is a separate pre-check destination.** If the org has `FieldServiceStandard`, work-order-adjacent cases belong to [sf-field-service](../sf-field-service/SKILL.md), not here.

---

## Common Failure Modes + Remediation

### Symptom: "Omni-Channel drops work items silently"

- **Root cause:** Presence status has `Allow Omni-Channel to push work to me` disabled, or the agent's capacity is already filled by a different routing config. Often a mismatch between Service Channel capacity and Presence configuration.
- **Fix:** Audit Presence Status → Routing Configuration → Service Channel chain for the agent's profile. Delegate the detailed remediation to [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md).

### Symptom: "Milestones start but never complete on closed cases"

- **Root cause:** Case is closed but the Milestone completion criteria still reference a field that didn't change (common when `IsClosed` isn't one of the completion conditions, or when Business Hours are set differently on the Entitlement vs the Milestone).
- **Fix:** Verify Milestone completion criteria includes `IsClosed = TRUE` (or the correct completion field); align Business Hours. Delegate to [sf-service-case](../sf-service-case/SKILL.md).

### Symptom: "Knowledge articles don't appear in the console sidebar"

- **Root cause:** Article publication not confirmed, data category not granted to the profile, or Knowledge not enabled on the Case layout.
- **Fix:** Confirm article is in Published state, data-category visibility is granted, and the Knowledge component is present on the Case Lightning page. Delegate to [sf-service-knowledge](../sf-service-knowledge/SKILL.md).

### Symptom: "Voice call records created but transcript is empty"

- **Root cause:** Voice transcription add-on not licensed, recording language mismatch, or transcription job queue stalled.
- **Fix:** Confirm the Voice transcription SKU; verify the call's language matches a supported locale; inspect Voice Call Transcripts object for queued/failed records. Escalate to Salesforce Support if backlog is platform-wide.

### Symptom: "Einstein Case Classification predicts the same field value for every case"

- **Root cause:** Training data too skewed (single value dominates >80% of labeled cases), or the model hasn't been retrained since the taxonomy changed.
- **Fix:** Re-balance the training set, retrain the model, monitor top-prediction distribution in the Einstein console.

---

## CLI / Metadata Cheat Sheet

```bash
# Org + license detection (Phase 0 input)
sf org display --json
sf org list all --json
sf org list metadata-types -o <alias> --json

# Service feature confirmation
sf data query -q "SELECT Id, MasterLabel, IsActive FROM Entitlement LIMIT 5" -o <alias>
sf data query -q "SELECT Id, Name, Type FROM SlaProcess LIMIT 5" -o <alias>
sf data query -q "SELECT Id, DeveloperName, IsActive FROM PresenceUserConfig" -o <alias>
sf data query -q "SELECT Id, Title, PublishStatus, Language FROM KnowledgeArticleVersion WHERE PublishStatus='Online'" -o <alias>

# Metadata retrieval for review
sf project retrieve start -m "Entitlement:*,SlaProcess:*,RoutingConfiguration:*,ServiceChannel:*,PresenceUserConfig:*,PresenceDeclineReason:*" -o <alias>

# Knowledge language + data category inspection
sf data query -q "SELECT DeveloperName, MasterLabel FROM DataCategoryGroup" -o <alias>

# Incident Management enablement check
sf data query -q "SELECT Id FROM Incident LIMIT 1" -o <alias> # returns error if disabled

# Voice call model
sf data query -q "SELECT Id, CallType, EndTime FROM VoiceCall LIMIT 5" -o <alias>
```

Metadata file families this skill orchestrates (actual authoring belongs to sf-metadata):

- `objects/Case/recordTypes/*.recordType-meta.xml`
- `objects/Entitlement/*.object-meta.xml`
- `objects/SlaProcess/*.object-meta.xml` (SLA Process = Entitlement Process)
- `routingConfigurations/*.routingConfiguration-meta.xml`
- `serviceChannels/*.serviceChannel-meta.xml`
- `presenceUserConfigs/*.presenceUserConfig-meta.xml`
- `presenceDeclineReasons/*.presenceDeclineReason-meta.xml`
- `knowledgeSettings/*.knowledgeSettings-meta.xml`
- `quickActions/Case.*.quickAction-meta.xml`
- `flexipages/ServiceConsole.*.flexipage-meta.xml`

---

## Output Format

When finishing, report in this order:

```text
Service Cloud task: <greenfield / redesign / remediation / single-phase-routing>
Industry pre-check: <negative / positive → deferred to sf-{industry-skill}>
Edition & licenses: <Service Cloud edition, add-ons>
Channel mix: <channels in scope>
Phases in scope: <case / omnichannel / knowledge / voice / incident / einstein>
Phase skills engaged: <sf-service-case / sf-service-omnichannel / sf-service-knowledge / sf-field-service>
Key decisions: <SLA mechanism, routing strategy, Voice edition, Einstein features>
Open risks / assumptions: <list>
Next step: <next phase or cross-skill handoff>
```

---

## Cross-Skill Integration

| Need | Delegate to | Reason |
|---|---|---|
| Case, Entitlements, Milestones, Incidents | [sf-service-case](../sf-service-case/SKILL.md) | Phase owner |
| Omni-Channel routing, Queues, Presence | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Phase owner |
| Knowledge, articles, data categories | [sf-service-knowledge](../sf-service-knowledge/SKILL.md) | Phase owner |
| Work Orders, Service Appointments | [sf-field-service](../sf-field-service/SKILL.md) | Field workforce |
| Apex, triggers, invocables | [sf-apex](../sf-apex/SKILL.md) | Code authoring |
| LWC on Service Console | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Flow XML | [sf-flow](../sf-flow/SKILL.md) | Flow mechanics |
| Data Cloud ingestion of Case | [sf-datacloud](../sf-datacloud/SKILL.md) | Service → DMO pipeline |
| Agentforce agent hand-off | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Agent topics/actions |
| Named Credentials / ITSM callouts | [sf-integration](../sf-integration/SKILL.md) | Integration wiring |
| OAuth / Connected Apps for CTI | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Auth foundation |
