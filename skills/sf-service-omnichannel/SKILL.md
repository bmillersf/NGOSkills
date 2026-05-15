---
name: sf-service-omnichannel
description: >
  Omni-Channel routing, Presence, Queues, Skills-Based Routing, Attribute-Based
  Routing, External Routing, Supervisor Dashboard, Service Console utility bar
  configuration, Omni Flow, and Omni-Channel API. Owns work-item push, capacity
  model, and routing configuration.
  TRIGGER when: user says "set up Omni-Channel", "route cases by skill", "route by
  attribute", "configure Presence", "design Presence statuses", "create Routing
  Configurations", "cap agent capacity", "build a Supervisor dashboard", "use
  External Routing with our telephony platform", "route via Omni Flow", "balance
  work across queues", "agent is getting too many cases", "agent is getting no
  cases", "cases aren't being pushed", "push chat to specific agents"; or works
  on RoutingConfiguration, ServiceChannel, PresenceUserConfig, PresenceDeclineReason,
  PresenceConfigureStatusAccess, Skill-Based Routing rules, Attribute Setup, or
  Omni-Channel Flow mechanics.
  DO NOT TRIGGER when: Case data model / SLA / Entitlements / Milestones / Escalation
  / Case Teams / Case Merge (use sf-service-case); Knowledge article routing or
  Knowledge base design (use sf-service-knowledge); Work Order scheduling, Service
  Appointment dispatch, Service Territory / Resource / Skill scheduling (all Field
  Service concepts, use sf-field-service — Field Service uses its own scheduling
  engine, not Omni-Channel); multi-phase Service Cloud orchestration (use
  sf-service-cloud); an industry cloud is installed and the routed record is
  industry-owned — defer via Phase 0 to sf-industry-fsc, sf-industry-health,
  sf-industry-education, sf-industry-public-sector, sf-field-service,
  sf-nonprofit-program-case, sf-nonprofit-cloud, sf-industry-manufacturing,
  sf-industry-consumer-goods, sf-industry-communications, sf-industry-media,
  sf-industry-energy; Sales routing / lead assignment (use sf-sales-cloud,
  sf-sales-engagement); Marketing Cloud routing (use sf-marketing-cloud-growth);
  Apex invocable that pushes to Omni-Channel (use sf-apex for the code, return
  here for routing design); LWC for Supervisor custom views (use sf-lwc); Flow
  XML authoring for Omni Flow routing (use sf-flow for the XML, return here for
  routing design); Data Cloud segmentation routing work items (use sf-datacloud);
  Agentforce agent routing (use sf-ai-agentforce).
license: MIT
compatibility: "Requires Service Cloud user licenses with Omni-Channel enabled; Skills-Based Routing requires an additional permission; Attribute-Based Routing is an add-on feature; External Routing requires a connected telephony / routing platform"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.service_presence_intro.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.omnichannel_setup_routing.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.omnichannel_skills_based_routing.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.omnichannel_supervisor_intro.htm
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_service_omnichannel.htm
---

# sf-service-omnichannel: Routing, Presence & Queues

Owns the Omni-Channel routing stack: how work items (Cases, Leads, custom objects, Chats, Voice Calls, Messaging Sessions) get from a queue to an available agent based on capacity, skills, or attributes. Owns Presence, capacity math, Supervisor tooling, and the Service Console utility bar for the Omni widget.

Comes after [sf-service-cloud](../sf-service-cloud/SKILL.md) orchestration or in parallel with [sf-service-case](../sf-service-case/SKILL.md) once Case creation is wired.

---

## When This Skill Owns the Task

Use `sf-service-omnichannel` when the work involves:

- Enabling Omni-Channel for the org and for specific users (Omni-Channel User permission + Presence Status access)
- Designing Service Channels (`ServiceChannel`) per routable object — one per Case, one per LiveChatTranscript, one per MessagingSession, one per custom object, etc.
- Routing Configurations (`RoutingConfiguration`) — Routing Model (Most Available, Least Active, External), Units of Capacity, Work Item Size, Push Timeout, Overflow behavior
- Queues that source work for Omni-Channel (Group + Queue with `DoesSendEmailToMembers` + `SupportedObjects`)
- Presence Statuses — Online, Busy, Break, Training, etc. — and which are Omni-eligible (`AllowsAgentsToAcceptTransfers` vs push)
- Presence Decline Reasons + Presence Configurations tying statuses to capacity
- Skills-Based Routing rules — Skill model (`Skill`, `ServiceResource`, `SkillRequirement`) and how skills attach to work items
- Attribute-Based Routing — Attribute Setup records, attribute matching rules, fallback routing
- External Routing (where a 3rd-party platform — Genesys, NICE, Five9, Talkdesk — makes routing decisions and pushes via Omni-Channel API)
- Omni Flow (flow-based routing where a record-triggered flow evaluates a work item, applies skills/attributes, and calls Route Work Action)
- Omni-Channel Supervisor dashboards — agent state, queue backlog, work item details, barge/whisper/monitor for Voice
- Omni-Channel API (Canvas / Conversational-agent integrations that accept/decline work via REST)
- Service Console utility bar — the Omni widget, sizing, default launch behavior

### Delegate outside this skill when

| Need | Route to | Boundary |
|---|---|---|
| Case data model / SLA | [sf-service-case](../sf-service-case/SKILL.md) | Data model, Entitlements, Milestones |
| Knowledge article surfaced to agent | [sf-service-knowledge](../sf-service-knowledge/SKILL.md) | Article model |
| Work Order scheduling & dispatch | [sf-field-service](../sf-field-service/SKILL.md) | Field Service uses its own scheduler, not Omni-Channel |
| Multi-phase Service Cloud design | [sf-service-cloud](../sf-service-cloud/SKILL.md) | Orchestrator |
| Apex invocable calling Route Work Action | [sf-apex](../sf-apex/SKILL.md) | Code authoring |
| Flow XML for Omni Flow | [sf-flow](../sf-flow/SKILL.md) | Flow mechanics |
| LWC Supervisor custom widget | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Omni widget permission set audit | [sf-permissions](../sf-permissions/SKILL.md) | Access audit |
| Named Credential for External Routing platform | [sf-integration](../sf-integration/SKILL.md) | Wiring |
| Connected App / OAuth for telephony partner | [sf-connected-apps](../sf-connected-apps/SKILL.md) | Auth foundation |

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before any routing design, run the shared [industry pre-check](../../references/industry-precheck.md). Generic routing must defer when the routed record belongs to an industry cloud's data model.

**NEVER silently override an industry data model.** If an industry cloud is installed AND the work item being routed is industry-owned, halt and forward. Generic Omni-Channel capacity rules cannot be imposed on industry record types without the industry skill's participation.

### Deferral map for routing-adjacent industry ownership

| Detected industry | Routing targets owned by the industry | Route to |
|---|---|---|
| Financial Services Cloud (`FinServ__`) | FSC Case record types (`FinServ__BankingCare`, `FinServ__WealthCare`, `FinServ__InsuranceCare`), Interaction-linked work, Referral routing | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) |
| Health Cloud (`HealthCloudGA__`) | CareRequest routing, Patient-service routing, UM review routing | [sf-industry-health](../sf-industry-health/SKILL.md) |
| Education Cloud / EDA (`hed__`) | Advising / Student-support routing on Term / Program Enrollment | [sf-industry-education](../sf-industry-education/SKILL.md) |
| Public Sector Solutions (`OutfundsPS__`) | License / Permit / Inspection routing, Complaint triage routing | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) |
| Field Service (`FieldServiceStandard`) | WorkOrder / ServiceAppointment routing uses the Field Service scheduling engine, NOT Omni-Channel | [sf-field-service](../sf-field-service/SKILL.md) |
| Nonprofit Cloud program/case (`NonprofitCloudCaseManagement`) | Intake and ProgramEnrollment routing to case workers | [sf-nonprofit-program-case](../sf-nonprofit-program-case/SKILL.md) |
| Nonprofit Cloud generic | Donor-service and grantee-service routing | [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) |
| Manufacturing Cloud (`Mfg`) | Sales Agreement dispute routing, warranty case routing | [sf-industry-manufacturing](../sf-industry-manufacturing/SKILL.md) |
| Consumer Goods Cloud (`CG`) | Retail Execution dispute routing, Visit-linked case routing | [sf-industry-consumer-goods](../sf-industry-consumer-goods/SKILL.md) |
| Communications Cloud (`vlocity_cmt__`) | Order / Number Management / ESM case routing | [sf-industry-communications](../sf-industry-communications/SKILL.md) |
| Media Cloud (`vlocity_media__`) | Subscriber / Billing Account case routing | [sf-industry-media](../sf-industry-media/SKILL.md) |
| Energy & Utilities (`vlocity_ins__` + `EnergyAndUtilities`) | Premise / Service Point / Work Request routing | [sf-industry-energy](../sf-industry-energy/SKILL.md) |

### Deferral procedure

1. Run detection per `references/industry-precheck.md`.
2. If positive AND the routed record belongs to a row above, print: `Detected {industry} is installed. Routing to sf-{industry-skill} because this request touches {matched object/process}.`
3. Halt and return control.
4. Only proceed if detection is negative, OR the user explicitly says "use standard Omni-Channel, ignore the industry overlay" (document the exception).

Special note for Field Service: when `FieldServiceStandard` is installed, WorkOrder/ServiceAppointment are **always** routed by the Field Service scheduler, not Omni-Channel. The deferral is unconditional.

---

## Required Context to Gather First

1. **Routable objects** — Case, Lead, LiveChatTranscript, MessagingSession, VoiceCall, custom objects. Which are in scope?
2. **Volume model** — peak concurrent work items per channel, per queue, per agent. Used to size Units of Capacity.
3. **Capacity philosophy** — flat capacity per agent, per-channel capacity, or tiered capacity by agent level. Example: 1 voice + 3 chats + 5 cases concurrently.
4. **Routing model** — Most Available (best for idle-time fairness), Least Active (best for current-load fairness), External (3rd-party makes the decision).
5. **Skill model** — which skills exist, how they attach to work items (hard-coded in Flow, via Attribute-Based Routing, via Apex `ISVRoutingAttributes`), fallback to queue if no skilled agent is available.
6. **Attribute-Based Routing posture** — simple attribute matching, composite rules, or not in use.
7. **External Routing posture** — telephony / messaging partner that drives routing decisions (Genesys, NICE, Five9, Talkdesk, custom Omni-Channel API consumer).
8. **Presence topology** — how many Presence Statuses, which are push-eligible, which pause SLA timers (coordinated with [sf-service-case](../sf-service-case/SKILL.md)).
9. **Queue topology** — tier (T1/T2/T3), language, region, product-line; per-queue capacity overrides, queue membership source of truth.
10. **Supervisor tooling** — out-of-box Supervisor dashboard, custom LWCs, or a dedicated BI tool.
11. **Agent desktop** — Service Console layout, utility bar configuration, softphone integration.
12. **Push timeout + decline model** — how long an agent has to accept before it re-routes; decline reasons; tolerable decline rate.

---

## Workflow Phases

### Phase 1 — Pre-Check & Scope Lock

1. Run **Phase 0 industry pre-check**. Halt and forward if positive.
2. Confirm routable objects, volume, and capacity philosophy.
3. Decide whether Field Service scheduling is in scope (if yes, route to [sf-field-service](../sf-field-service/SKILL.md) for WorkOrder/ServiceAppointment routing).

### Phase 2 — Enable & Permission

1. Enable Omni-Channel in Setup (one-time).
2. Assign Omni-Channel User permission + the appropriate Presence Status Access via Permission Set (not profile — keep profiles generic).
3. For Skills-Based Routing, assign the Use Skills-Based Routing permission.
4. Verify user licenses are Service Cloud (Omni-Channel is not included in Sales Cloud–only licenses).

### Phase 3 — Service Channels & Queues

1. Create one Service Channel per routable object. Set Custom Console Footer Component if needed.
2. Design queues with a naming convention (e.g., `T1-EN-US-Billing`). Queue membership from Public Groups, not individual users.
3. For each Service Channel, decide Seconds in Queue Before Overflow and Overflow Assignee.

### Phase 4 — Routing Configurations

1. For each Service Channel + queue combination, create a Routing Configuration.
2. Choose Routing Model: Most Available vs Least Active vs External. Document why.
3. Set Units of Capacity per work item — a case might be 1, a chat might be 2, a voice call might be 4.
4. Set Push Timeout (typical 30–60s) + Decline behavior (Stay in Queue / Go Offline / Change Status).
5. Set Work Item Size carefully — this is the "cost" of the work item against agent capacity.

### Phase 5 — Presence Statuses & Configurations

1. Enumerate Presence Statuses (`Online`, `Busy`, `Break`, `Training`, `After-Call Work`, `Outbound-Only`).
2. Mark which are `AllowsOmniAssignment = true` (push-eligible) vs offline/manual-only.
3. Create Presence Configurations per agent cohort: Overall Capacity (sum of all in-progress Work Item Sizes the agent can carry), auto-accept flags, auto-decline reasons.
4. Assign Presence Configurations via Permission Set.
5. Align with SLA pause behavior from [sf-service-case](../sf-service-case/SKILL.md) — if Presence Status "Break" should pause Milestones, wire that in the Entitlement Process, not here.

### Phase 6 — Skills-Based Routing (if in scope)

1. Create Skills (`Skill`) and attach to Service Resources (`ServiceResource` reused from Field Service model, or Omni-Channel-only service resources).
2. Wire skill requirements to work items via (a) Omni Flow with Add Skill Requirements action, (b) Apex implementing `Messaging.MessageTypeEnum` / `Service.OmniChannel.Routing.ISVRoutingAttributes`, or (c) Attribute-Based Routing with skill attributes.
3. Define fallback: if no skilled agent is available within N seconds, drop the skill requirement and route by queue. Document the drop policy.

### Phase 7 — Attribute-Based Routing (if in scope)

1. Define Attribute Setup records — which fields on the work item drive routing attributes.
2. Build matching rules linking attribute values to queues or skill sets.
3. Test attribute extraction for every supported channel (Case, Chat, Messaging, Voice, custom).

### Phase 8 — External Routing (if in scope)

1. Identify the external routing partner (Genesys, NICE, Five9, Talkdesk, custom API consumer).
2. Configure the Routing Configuration with Routing Model = External.
3. Wire the external platform to the Omni-Channel API via Named Credential + Connected App (delegate wiring to [sf-integration](../sf-integration/SKILL.md) and [sf-connected-apps](../sf-connected-apps/SKILL.md)).
4. Confirm the platform honors Presence and capacity, or accept that it bypasses them.

### Phase 9 — Omni Flow (if in scope)

1. Design the record-triggered flow that evaluates new work items and applies routing logic (skills, attributes, queue routing).
2. Use the Route Work action within the flow.
3. Keep logic in Flow for declarative operations; route to [sf-apex](../sf-apex/SKILL.md) when routing logic needs callouts or DML beyond flow capabilities.

### Phase 10 — Supervisor & Console

1. Configure the Omni-Channel Supervisor app (tabs: Agents, Queues Backlog, Assigned Work, Skills).
2. Plan custom Supervisor widgets via LWC if needed; delegate to [sf-lwc](../sf-lwc/SKILL.md).
3. Configure the Service Console utility bar: Omni widget (required), Macros, History, Notes, Softphone (if Voice), Knowledge.
4. Set Omni widget defaults — auto-launch, sticky, sizing.

### Phase 11 — Verify, Load-Test & Hand Off

1. Smoke-test: with two agents in different Presence states, create a work item and confirm push lands on the correct agent.
2. Load-test at peak volume × 1.5 to confirm capacity math.
3. Monitor decline rate, reroute rate, and time-to-accept for one week.
4. Emit a structured summary.

---

## Scoring Rubric (120 points total — 95 is passing)

| Category | Max | Pass threshold | What earns points |
|---|---|---|---|
| Industry pre-check executed and documented | 15 | 12 | Detection ran; Field Service deferral explicit if applicable |
| Routable objects + volume model captured | 15 | 11 | All channels + peak volume + capacity philosophy documented |
| Service Channels + queues designed | 15 | 11 | One Service Channel per object; queue naming convention; public-group membership |
| Routing Configurations correct | 20 | 15 | Routing Model justified; Work Item Size sized to capacity; Push Timeout set |
| Presence topology | 15 | 11 | Push-eligible statuses listed; Presence Configurations by cohort; capacity total per cohort |
| Skills-Based Routing (if in scope) | 10 | 7 | Skill attachment mechanism chosen; fallback policy declared |
| Attribute-Based / External / Omni Flow | 10 | 7 | Correct mechanism chosen for the use case; wiring path declared |
| Supervisor + console | 10 | 7 | Supervisor tabs configured; utility bar sized |
| Verification plan | 5 | 4 | Smoke test + load test + week-one monitoring defined |
| Delegation + output format | 5 | 4 | Correct hand-offs; structured summary |

Fail gates: Phase 0 skipped = automatic fail. Routing Field Service WorkOrder/ServiceAppointment through Omni-Channel instead of deferring to [sf-field-service](../sf-field-service/SKILL.md) = automatic fail.

---

## Anti-Patterns

1. **Skipping Phase 0.** Designing Omni-Channel routing on an industry-cloud org without verifying the routed record isn't owned by that industry.
2. **Routing Field Service WorkOrder / ServiceAppointment through Omni-Channel.** Field Service has its own scheduling engine; Omni-Channel doesn't honor territories, skill overlaps, travel time, or preventive-maintenance plans.
3. **Flat capacity across all channels.** Voice cost ≠ chat cost ≠ case cost. Work Item Size must reflect real cognitive load per channel.
4. **Using profiles to assign Presence and Omni-Channel permission.** Keep profiles generic; put Omni enablement on Permission Sets so agents can be added to / removed from Omni without re-cloning profiles.
5. **Skills-Based Routing without a fallback.** If no skilled agent is online, the work item sits in queue forever. Always define a drop policy (N seconds → drop skill → route by queue).
6. **Push Timeout too low.** Sub-20-second timeouts cause decline spirals in peak load. Start at 30–60s and tune from observed accept-time.
7. **Too many Presence Statuses.** More than ~8 statuses confuses agents and breaks capacity reporting. Keep the list tight.
8. **Letting External Routing bypass Presence entirely.** If the partner pushes work without checking Presence, agents end up double-booked. Either enforce Presence on the partner side or accept the risk in writing.
9. **Supervisor-by-custom-LWC when stock Supervisor works.** Rebuild only when the stock app genuinely lacks a view; stock is upgraded each release, custom rebuilds are not.

---

## Common Failure Modes + Remediation

### Symptom: "Work items sit in queue; no agents get pushed"

- **Root cause:** No agent is in an `AllowsOmniAssignment = true` Presence Status; Routing Configuration capacity is 0; Service Channel not associated with the queue; Omni-Channel User permission not granted.
- **Fix:** Verify at least one agent is Online with push-eligible status; inspect Routing Configuration Capacity and Work Item Size; confirm the queue's Supported Objects list includes the routable object.

### Symptom: "Agent receives more work than capacity allows"

- **Root cause:** Work Item Size on the Routing Configuration is lower than the true cognitive cost; Presence Configuration Overall Capacity is too high; External Routing bypassed Presence.
- **Fix:** Raise Work Item Size or lower Presence Configuration Overall Capacity. If External Routing, enforce capacity check on the partner.

### Symptom: "Skills-Based Routing never matches a skilled agent"

- **Root cause:** Skills attached to `User` not to `ServiceResource`; skill requirements weren't added to the work item; agent skill level doesn't meet the minimum skill level on the work item.
- **Fix:** Confirm skills attach via `SkillRequirement` records on `ServiceResource`; verify the Omni Flow or Apex actually adds skill requirements to the work item; lower the minimum level or raise the agent level.

### Symptom: "Push Timeout declines pile up; work items bounce"

- **Root cause:** Timeout too short for agent context; Presence Configuration Auto-Decline too aggressive; agents not noticing the notification sound.
- **Fix:** Raise Push Timeout; relax Auto-Decline; confirm console sound settings + notification permissions in the browser.

### Symptom: "External Routing partner says it pushed, but no work appears in Omni widget"

- **Root cause:** Named Credential / OAuth misconfigured; Connected App missing the `omni_channel_api` scope; the partner's payload doesn't match the Omni-Channel API contract.
- **Fix:** Re-validate OAuth (route to [sf-connected-apps](../sf-connected-apps/SKILL.md)) and Named Credential (route to [sf-integration](../sf-integration/SKILL.md)); inspect the payload against Omni-Channel API docs.

### Symptom: "MIAW chat shows 'Donor Support Agent joined → Transferring…' then hangs forever"

The flow's `routeWork` action is pushing the conversation to a queue, but no human or agent
in that queue is `Available`. Two valid fixes depending on intent:
- **Want a human-handoff queue:** check `ServicePresenceStatusAccess` and `UserServicePresence`
  — at least one queue member must have a presence status mapped to the `LiveMessage`
  ServiceChannel and be `Online`. Use `Setup → Omni-Channel → Routing → <queue's Routing Config>`
  to confirm `RoutingModel`.
- **Want an Agentforce ServiceAgent:** bypass the queue + flow entirely. Route the channel
  directly to the bot via `MessagingChannel.SessionHandlerId` (see "Direct ServiceAgent
  routing" below). The `routingType=AgentforceEmployeeAgent` value in the standard MIAW flow
  template only engages **internal** Agentforce Employee agents — it will not engage a
  customer-facing ServiceAgent and will not route to a human.

### Symptom: "MIAW deployment was created but bootstrap.min.js returns 501"

Deployment exists but is unpublished. Re-publish via Setup or `scripts/publish-esc.spec.ts`
in [sf-ai-agentforce](../sf-ai-agentforce/scripts/) — the script is reusable for any ESC,
not just Agentforce-fronted ones.

### Symptom: "MIAW deployment's runtime config returns authMode=Auth even though channel.IsAuthenticated=false"

`embeddedServiceMessagingChannel.authMode` is snapshotted at **deployment-creation** and is
not refreshed by re-publish or by `PATCH MessagingChannel.IsAuthenticated`. Re-create the
channel via `Setup → Messaging → Channels → New Channel` (the wizard with the "Allow guest
users" toggle), NOT via `Setup → Embedded Service Deployments → New Deployment`.

---

## Direct ServiceAgent routing (no flow + queue)

When the MIAW conversation should go to an Agentforce ServiceAgent, skip the flow + queue
indirection entirely. `MessagingChannel.SessionHandlerId` is a polymorphic reference field
that accepts either a `FlowDefinition` Id (`300...`) or a `BotDefinition` Id (`0Xx...`); the
runtime branches on the prefix. The metadata XML schema does **not** expose this — only
sObject PATCH does:

```bash
SID=$(sf org display -o <alias> --json | jq -r .result.accessToken)
INST=$(sf org display -o <alias> --json | jq -r .result.instanceUrl)
curl -X PATCH -H "Authorization: Bearer $SID" -H "Content-Type: application/json" \
  -d '{"SessionHandlerId":"<botDefinitionId>"}' \
  "$INST/services/data/v66.0/sobjects/MessagingChannel/<channelId>"
# Expected: HTTP 204
```

After this, **re-publish the EmbeddedServiceConfig** — the runtime endpoint
`/embeddedservice/v1/embedded-service-config` snapshots wiring at publish time. A metadata
deploy is not enough.

Reusable script: [`sf-ai-agentforce/scripts/wire-channel-to-service-agent.sh`](../sf-ai-agentforce/scripts/wire-channel-to-service-agent.sh).

---

## CLI / Metadata Cheat Sheet

```bash
# Omni-Channel inventory
sf data query -q "SELECT DeveloperName, MasterLabel, RelatedEntity FROM ServiceChannel" -o <alias>
sf data query -q "SELECT Id, DeveloperName, RoutingModel, Capacity FROM RoutingConfiguration" -o <alias>
sf data query -q "SELECT Id, DeveloperName, IsEnabled FROM PresenceUserConfig" -o <alias>
sf data query -q "SELECT Id, MasterLabel, StatusOption FROM ServicePresenceStatus" -o <alias>

# Active agents + presence
sf data query -q "SELECT Id, UserId, ServicePresenceStatusId, ConfigurationCapacity FROM UserServicePresence WHERE IsCurrentState = true" -o <alias>

# Skills model
sf data query -q "SELECT Id, MasterLabel FROM Skill" -o <alias>
sf data query -q "SELECT Id, SkillId, SkillLevel, ServiceResourceId FROM ServiceResourceSkill LIMIT 50" -o <alias>

# Queue + membership
sf data query -q "SELECT Id, Name, DeveloperName, QueueRoutingConfigId FROM Group WHERE Type='Queue'" -o <alias>

# Metadata retrieval for review
sf project retrieve start -m "ServiceChannel:*,RoutingConfiguration:*,PresenceUserConfig:*,PresenceDeclineReason:*,ServicePresenceStatus:*,Queue:*,Skill:*" -o <alias>
```

Key metadata file families:

- `serviceChannels/*.serviceChannel-meta.xml`
- `routingConfigurations/*.routingConfiguration-meta.xml`
- `presenceUserConfigs/*.presenceUserConfig-meta.xml`
- `presenceDeclineReasons/*.presenceDeclineReason-meta.xml`
- `presenceConfigureStatusAccess/*` (permission set–driven)
- `queues/*.queue-meta.xml`
- `skills/*.skill-meta.xml`
- `flexipages/ServiceConsole.*.flexipage-meta.xml` (utility bar)

---

## Output Format

```text
Omni-Channel task: <setup / redesign / skills-based / attribute-based / external / supervisor>
Industry pre-check: <negative / positive → deferred to sf-{industry-skill}>
Routable objects: <list>
Capacity model: <flat / per-channel / tiered>
Routing model: <most-available / least-active / external>
Skills-Based Routing: <yes+fallback / no>
Attribute-Based Routing: <yes / no>
External Routing partner: <Genesys / NICE / Five9 / Talkdesk / none>
Omni Flow used: <yes / no>
Presence statuses (push-eligible): <count + names>
Verification plan: <smoke + load + week-one monitoring>
Open risks / assumptions: <list>
Next step: <hand-off to sf-service-case / sf-integration / sf-flow / sf-apex>
```
