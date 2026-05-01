---
name: sf-flow-orchestration
description: >
  Salesforce Flow Orchestration (multi-user, multi-step orchestrated flows), Approval Processes,
  Work Queue, and Work Guide architecture with 130-point scoring.
  TRIGGER when: user designs or implements multi-user orchestrated work with Flow Orchestration
  (Stages, Steps, Decisions, Interactive Steps, Background Steps, Async Path), migrates legacy
  Approval Processes to Flow Orchestration or modern Approvals-in-Flow, configures Work Guide on
  a record page, builds a Work Queue item pipeline, troubleshoots Orchestration Runs / Orchestration
  Events / Orchestration Logs, touches `.flow-meta.xml` whose `<processType>` is
  `Orchestrator` (or `RecordBeforeSave` wrapping Orchestrator stages), sets up a human-in-the-loop
  workflow that spans multiple assignees, or says "orchestrate this across teams", "multi-step
  approval", "route this work through review then legal then finance", "assign this to the
  manager then the director", "work queue for underwriters", "interactive step for the user to
  complete", "background step to call an API then wait", "async path after save", "orchestration
  run failed at stage 2", "migrate my Approval Process to Flow", "approvals in Flow", "parallel
  approval", "conditional approval routing", "escalation on timeout", "reassign the step",
  "pause the orchestration until external event".
  DO NOT TRIGGER when: the task is a single record-triggered / screen / scheduled / autolaunched
  flow with no multi-user orchestration (use sf-flow); Apex implementation, triggers, batch or
  queueable jobs (use sf-apex); LWC components, Jest tests, wire service (use sf-lwc); Agentforce
  agents, Agent Script DSL, PromptTemplates (use sf-ai-agentforce / sf-ai-agentscript); Field
  Service dispatching and Service Appointment scheduling (use sf-field-service); Nonprofit Cloud
  or NPSP nonprofit-specific orchestrations driven by Gift Transaction, Program Enrollment,
  Funding Award review lifecycles (use sf-nonprofit-cloud and descendants); Public Sector
  Solutions benefit / license / permit review workflows — these have industry-owned
  orchestration templates (use sf-industry-public-sector); FSC loan / mortgage / wealth onboarding
  review (use sf-industry-fsc); Health Cloud care request / utilization management review
  (use sf-industry-health); generic object-level metadata XML such as creating the custom objects
  or fields the orchestration reads from (use sf-metadata); permission set / profile work for
  the assignees (use sf-permissions); Omni-Channel work routing for service agents — that is
  Omni-Channel, not Orchestration (use sf-service-omnichannel); the task is a single Approval
  Process still intended to stay on the legacy Approval Process engine with no orchestration
  migration in scope (use sf-flow if paired with flow triggers, else stay declarative);
  Marketing Cloud journey steps — Journey Builder in MC Growth is a different product
  (use sf-marketing-cloud-growth).
license: MIT
compatibility: "Requires Flow Orchestration enabled on the org (Unlimited / Enterprise with the Flow Orchestration SKU, or Platform with the add-on). Available in Lightning Experience only."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.flow_concepts_orchestration.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.approvals_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/decision-guides/flow-orchestration
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_automate_flow_orchestration.htm
---

# sf-flow-orchestration: Flow Orchestration + Approvals + Work Queue

Use this skill when the user is building or debugging a **multi-user, multi-step orchestrated workflow** on Salesforce — the work that historically lived in Approval Processes, hand-rolled Chatter post chains, or a tangled graph of subflows — using the modern **Flow Orchestration** runtime (Stages → Steps → Decisions), the **Work Queue** / **Work Guide** UI that surfaces assigned steps to users, and **Approvals in Flow** (the Spring '24+ pattern that replaces legacy Approval Processes). This skill is a platform-level primitive: it applies across any cloud, any industry, any vertical — which is why it does not run an industry pre-check. When an industry skill owns the business semantics, it calls into this skill for the orchestration mechanics.

This skill owns: Flow Orchestration (orchestrator flows, stages, steps, decisions), Interactive Steps, Background Steps, Async Path, Orchestration Events, Orchestration Runs, Orchestration Logs, the Work Queue component, the Work Guide component, Approval Processes (legacy, for migration), and modern Approvals in Flow.

---

## 1. When This Skill Owns the Task

This skill owns the task when the work involves **more than one user** or **more than one decision gate** executing against a coordinated business process, routed through the Orchestrator runtime.

Delegate when the task is narrower or lives in a different runtime:

| User need | Route to | Why |
|---|---|---|
| Single record-triggered, screen, scheduled, or autolaunched flow with no multi-user handoff | [sf-flow](../sf-flow/SKILL.md) | One-flow work; orchestration is overkill |
| Apex trigger, batch, queueable, schedulable, invocable method | [sf-apex](../sf-apex/SKILL.md) | Code implementation, not orchestration config |
| LWC components, screen components embedded in an Interactive Step | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring is its own skill |
| Agentforce agent that should take one of the orchestration steps | [sf-ai-agentforce](../sf-ai-agentforce/SKILL.md) | Agent action can be invoked as a Background Step, but the agent itself is configured there |
| Omni-Channel work routing for service agents (presence, queues, skills-based routing) | [sf-service-omnichannel](../sf-service-omnichannel/SKILL.md) | Different runtime; Omni-Channel is not Orchestrator |
| Field Service dispatch / scheduling | [sf-field-service](../sf-field-service/SKILL.md) | FS has its own scheduling engine |
| NPC fundraising gift review / grants disbursement review | [sf-nonprofit-fundraising](../sf-nonprofit-fundraising/SKILL.md) / [sf-nonprofit-grants](../sf-nonprofit-grants/SKILL.md) | Nonprofit domain owns the semantics; calls back here for mechanics |
| NPSP Opportunity-based donation review | [sf-nonprofit-npsp](../sf-nonprofit-npsp/SKILL.md) | NPSP orchestration templates |
| Public Sector benefit / license / permit / inspection review | [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) | PSS ships orchestration templates |
| FSC loan origination, mortgage underwriting, wealth onboarding review | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) | FSC owns the industry process |
| Health Cloud care request / utilization management review | [sf-industry-health](../sf-industry-health/SKILL.md) | HC owns the UM process |
| Create / edit the underlying custom objects or fields the orchestration touches | [sf-metadata](../sf-metadata/SKILL.md) | Metadata XML authoring |
| Permission sets / profiles for the assignees | [sf-permissions](../sf-permissions/SKILL.md) | Access analysis |
| Deployment, packaging, or CI/CD for the orchestration | [sf-deploy](../sf-deploy/SKILL.md) | DevOps |
| Marketing Cloud Growth journey steps (Email / SMS) | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) | Different product |

---

## 2. Phase 0 Note — No Industry Pre-Check

Flow Orchestration is a **platform-level primitive**, not a cloud-specific surface. It is deliberately cross-cutting — FSC, Health, PSS, NPC, Manufacturing, and every industry cloud eventually orchestrates work through the same runtime. Industry skills that have their own review / approval semantics call into this skill for the Orchestrator mechanics; they do not replace it.

**This skill therefore skips the industry pre-check.** Callers from an industry skill have already resolved industry-vs-generic precedence; by the time this skill is invoked, the decision is that the work belongs to the Orchestrator layer.

Consequence: when an industry skill hands off to this skill, trust the handoff. Do not re-run detection. Do not ask the user to re-confirm license. Do produce orchestration artifacts that reference the industry-owned objects (GiftTransaction, CareRequest, BusinessLicense, Household, etc.) by their exact API names as the industry skill supplies them.

---

## 3. Required Context to Gather First

Before producing any orchestration design, establish:

- **Orchestration type.** Autolaunched (record-triggered or platform-event-triggered) or Record-Triggered? Record-Triggered Orchestrator runs only on create/update; Autolaunched can be invoked from a Flow, REST, or Platform Event.
- **Stages and steps in scope.** How many Stages (parallel lanes of work)? How many Steps per Stage (sequential work within a lane)? Orchestration's power is serialized Stages + parallel Steps inside a Stage.
- **Assignee model per step.** Each Interactive Step has a single assignee expression (User, Queue, Group, or a user formula). Hard-coded User IDs do not survive sandbox refreshes; use formula-driven assignment against the record.
- **Escalation / timeout policy.** Does a step timeout exist? If a step is not completed within N hours/days, does it reassign, notify, or fail? Orchestrator does not ship a native "SLA timer on a step" — escalation is a separate pattern (Scheduled Path on a triggering flow, or a Platform Event emitted by Orchestration Events).
- **Approval vs review semantics.** Is a step a **decision** (user picks Approve / Reject / Request Changes) or a **review checklist** (user confirms N fields then submits)? Both are Interactive Steps, but the screen flow they invoke differs.
- **Parallel vs sequential approvals.** Multiple approvers in parallel (all must approve) vs. sequential (one then the next) vs. conditional (based on amount, account tier, region). Each is a different Stage layout.
- **Async boundaries.** Background Steps that call external APIs should execute via Async Path so the Interactive Step UI doesn't block waiting on a callout.
- **Legacy Approval Process inventory.** If migrating: how many Approval Processes exist today, which objects, which record types, what are the entry criteria, and what is the approver expression? A direct port to Approvals-in-Flow is usually wrong for complex routing — use Flow Orchestration instead.
- **Work Queue surfacing.** Where does the assignee see their pending work — Work Queue standalone page, Work Queue component on Home, Work Guide embedded on the record page, or a Slack-First notification? Different placements change the design.
- **Audit / compliance posture.** Who needs to see the Orchestration Runs / Logs? Is SOX / 21 CFR Part 11 / FedRAMP in scope? Some industries require immutable audit trails — Orchestration Logs are append-only, but retention config matters.
- **Deploy target.** Scratch org / sandbox / production? Orchestration metadata deploys as Flow metadata (`processType=Orchestrator`) but has subtleties (activation, version pins).

Missing the assignee model or escalation policy is a design-blocking gap. Do not guess.

---

## 4. Workflow Phases

Run in order.

### Phase 1 — Process Discovery

1. Write the process as a plain-English sequence: *"When X happens, Person A reviews, then if condition C Person B approves, then system calls API D, then finally record is updated."*
2. Identify every **handoff** — anywhere a different person / role / system takes over. Each handoff is a Stage or Step boundary.
3. Identify every **decision gate** — anywhere the path branches based on data. Each is a Decision element inside a Stage.
4. Identify every **wait** — anywhere the process pauses waiting for a human, a time, or an external event. Each is an Interactive Step (human), a Scheduled Path on the triggering flow (time), or a Platform Event subscription inside an Async Path (external event).
5. Identify every **parallel lane** — work that can happen concurrently by independent actors. Parallel Stages, not parallel Steps within one Stage.
6. Sketch the structure before opening Flow Builder. A whiteboard or Mermaid diagram saves hours of rework.

### Phase 2 — Choose the Orchestration Pattern

| Pattern | When to use | Key trait |
|---|---|---|
| **Simple sequential approval** (2–3 approvers, always the same order) | Classic manager → director → VP | Single Stage, sequential Interactive Steps, formula-assigned approvers |
| **Conditional approval** (path varies by amount / region / record type) | Finance approvals with dollar thresholds | One Stage, Decision element before each Interactive Step |
| **Parallel approval** (legal + finance + security all must approve) | Contract review | One Stage, multiple Interactive Steps marked "parallel" |
| **Sequential Stages** (Intake → Review → Disbursement) | Grant management, benefit application | Multiple Stages, each with one or more Steps, strict serial order |
| **Review-then-callout-then-resume** | Underwriting that calls a credit bureau mid-process | Stage with Interactive Step → Background Step (Async Path) → Interactive Step |
| **Long-running with external event resumption** | Contract sent to DocuSign, waiting for completion callback | Background Step with Platform Event subscription |
| **Escalation / reassignment** | SLA-driven "if not done in 48h, reassign to backup" | Scheduled Path on the triggering flow emits a Platform Event; Orchestration Event subscriber reassigns |

**Do not** try to cram an eight-stage process into a single Stage. Stages are the clearest expression of "phase of work"; Steps are the operators inside a phase.

### Phase 3 — Build the Orchestrator

1. Create a new Flow with `processType=Orchestrator`. Choose Record-Triggered or Autolaunched.
2. Add Stages in execution order. Name them by business phase (`Intake`, `Initial_Review`, `Legal_Review`, `Disbursement`), not by index.
3. Inside each Stage, add Interactive Steps and Background Steps. Each Interactive Step points to a **screen flow** (a separate Flow with `processType=Flow` / screen). Each Background Step points to an **autolaunched flow** (or an invocable Apex action).
4. Configure the assignee for each Interactive Step:
   - **User formula** — e.g., `{!recordVar.Owner.ManagerId}` for "assign to the record owner's manager"
   - **Queue** — for "anyone on the underwriting queue can pick it up"
   - **Group** — for "any member of this public group"
   - Never hard-code User IDs.
5. Add **Decision** elements for branching. Orchestration Decisions route between Steps in the same Stage, or skip to the next Stage, or terminate.
6. Add **Async Path** for any Step that calls an external API, a long-running Apex job, or waits for a Platform Event. Async Path is the only way to avoid blocking the Interactive Step on a callout.
7. Configure **Stage Completion** criteria — does a Stage complete when all Steps complete (AND), when any completes (OR), or when a specific Step completes?
8. Configure **Orchestration Exit** — terminal condition, success vs failure path, and what final record update happens.

### Phase 4 — Build the Step Screen Flows

Each Interactive Step is backed by a screen flow. The screen flow is where the assignee actually does work.

1. Create a screen flow per step type (one for "Manager Approval", one for "Legal Review Checklist", etc.). Keep them narrowly scoped.
2. Pass in the orchestration's context record (the record that triggered or the record variable) as an input variable.
3. Add Screen elements with the fields and decisions the user needs. Use Display Text to explain context. Use Decision components (Approve / Reject / Request Changes radio, followed by a reason text area).
4. Write outputs back to the record (status, reviewer, reviewed-at, decision) — either via record-update Action in the screen flow or by returning output variables that the orchestration then uses.
5. For complex screens, embed an LWC — delegate authoring to [sf-lwc](../sf-lwc/SKILL.md).

### Phase 5 — Surface the Work (Work Queue + Work Guide)

1. Add the **Work Queue** standard component to the user's Home page or a dedicated Lightning App page. It shows every orchestration step assigned to the current user, across every orchestration.
2. Add the **Work Guide** component to the record page for the context record (e.g., Opportunity, Case, Application). When an orchestration is running against the record, Work Guide surfaces the active step inline so the assignee can complete the work without navigating away.
3. Configure **component visibility filters** so Work Queue / Work Guide appears only for users with the right permission set or profile.
4. For Slack-First orgs, consider routing the assignment notification via Slack in addition to Work Queue — delegate to [sf-slack](../sf-slack/SKILL.md).

### Phase 6 — Approvals: Legacy vs Modern

**Legacy Approval Processes** (still supported, still appropriate for simple cases):
- Configure under Setup → Approval Processes.
- Good for: single object, single record type, simple approver hierarchy, no integration with other automation.
- Limits: no parallel approval that Flow can't do better, can't embed callouts, can't easily escalate on timeout, weak audit surface.

**Approvals in Flow** (Spring '24+, the modern path):
- Approval action embedded directly in a screen flow or autolaunched flow.
- Good for: single-step approval inside a larger Flow, where the approval is a discrete sub-step, not a full multi-user orchestration.

**Flow Orchestration** (the most capable, for multi-actor workflows):
- The right tool when you have more than one reviewer, parallel lanes, conditional routing, timeouts, callouts mid-process, or a need to see orchestration runs/logs holistically.
- Replaces most legacy Approval Processes. Do not port one-for-one — redesign the process first.

**Migration heuristic.** If the legacy Approval Process has a single approver and no branching, migrate to **Approvals in Flow**. If it has multiple approvers, parallel paths, or reassignment logic, migrate to **Flow Orchestration**. Never leave a legacy Approval Process alongside a new Flow Orchestration against the same record — you will get duplicate approvals and deadlocks.

### Phase 7 — Testing and Validation

1. **Unit test each Step screen flow** — Flow tests (the built-in test runner) against representative record inputs.
2. **End-to-end orchestration test** — trigger the orchestration against a test record. Walk through every step as each assignee (use User Switcher or test user logins). Verify the Orchestration Run advances correctly, decisions route, and the final record state is correct.
3. **Branch coverage** — exercise every Decision path at least once.
4. **Async Path test** — confirm callouts / Platform Events complete and resume the orchestration correctly. Mock external systems or use a test endpoint.
5. **Failure-path test** — what happens when a step fails (user rejects, callout times out, invocable errors)? Verify the orchestration's failure path runs, not just the happy path.
6. **Log review** — open Setup → Orchestration Runs, confirm the test run shows the expected trajectory through Stages and Steps. Open the per-step log to verify assignment, timestamps, and completion.
7. **Regression** — if this orchestration is demoable, route to [sf-demo-playwright](../sf-demo-playwright/SKILL.md) for a pre-flight script.

---

## 5. Scoring Rubric — 130 Points

Apply to any Flow Orchestration design or build deliverable. Minimum passing: **98 / 130**. Sub-threshold categories must be fixed even if the total exceeds 98.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Pattern choice and Stage / Step structure** | 25 | 19 | Stages match business phases; Steps are narrow; parallel vs sequential is explicit; no eight-step single-Stage orchestrations; no orchestration used where a single Flow would suffice |
| **Assignee model correctness** | 20 | 15 | All assignees are formula-driven, Queue-driven, or Group-driven; no hard-coded User IDs; sandbox-refresh-safe; escalation/reassignment path defined if needed |
| **Decision and branching correctness** | 20 | 15 | Every branch has coverage; every Decision has a default path; parallel lanes reconverge safely; no orphan Steps |
| **Async Path and callout safety** | 15 | 11 | Any callout / long Apex / Platform Event wait is on Async Path; no blocking callouts inside Interactive Steps; Platform Events produce an Orchestration Event subscriber where resumption is required |
| **Approval migration correctness** | 20 | 15 | Legacy Approval Processes migrated are retired (not left running alongside); choice between Approvals-in-Flow vs Orchestration matches the process shape; no duplicate approvals on the same record |
| **Work surface UX (Work Queue / Work Guide)** | 10 | 7 | Work Queue on Home, Work Guide on the record page, visibility filters set; assignee always sees pending work without extra navigation |
| **Testing and audit** | 20 | 15 | Unit tests on step screen flows; end-to-end run exercised per branch; failure path tested; Orchestration Runs / Logs reviewed and retention policy confirmed; SOX / CFR / FedRAMP posture documented if applicable |

---

## 6. Anti-Patterns

- **Using Flow Orchestration for a single-user, single-step task.** Orchestration's overhead (metadata, Orchestration Runs, Work Queue assignment) is only worth it for multi-user or multi-stage work. One-off approval? Use Approvals in Flow. Record-triggered automation? Use [sf-flow](../sf-flow/SKILL.md).
- **Hard-coding User IDs as step assignees.** They do not survive sandbox refresh, they break when someone leaves the company, and they make the orchestration un-deployable. Always use formulas against the record (`{!recordVar.Owner.ManagerId}`), Queues, or Groups.
- **Leaving the legacy Approval Process active alongside a new Flow Orchestration on the same record.** Users get two approval requests, the record ends up in two conflicting lock states, and rollback is messy. Retire the Approval Process atomically with the Orchestration activation.
- **Putting a synchronous external callout in an Interactive Step.** The assignee's browser is now waiting on the remote API. Use Async Path for every callout; the Interactive Step resumes after the callout's response is captured as a Platform Event or invocable output.
- **Single Stage with ten Steps.** Stages are the unit of "phase of work" — intake, review, disbursement. Ten Steps in one Stage means the mental model and the metadata diverge; the Orchestration Runs view becomes unreadable. Decompose into multiple Stages.
- **Using Flow Orchestration to implement Service Cloud case routing.** That is Omni-Channel's job ([sf-service-omnichannel](../sf-service-omnichannel/SKILL.md)). Orchestrator is for business-process work, not real-time queue pushing of service interactions.
- **Ignoring failure paths.** Every Interactive Step can be rejected; every Background Step can throw; every Async Path can time out. Not configuring the failure branch leaves the orchestration stuck in a half-completed state forever, and the Orchestration Runs log fills with zombie runs.
- **Embedding an LWC in an Interactive Step screen flow without passing the orchestration context.** The LWC won't know which Orchestration Run it is serving. Pass the Orchestration Run ID or the context record ID explicitly as an LWC input.
- **Skipping the Work Guide on the record page.** Without Work Guide, the assignee has to hunt for their pending step in Work Queue, then navigate back to the record to act. Work Guide inline on the record collapses that into one place.
- **Designing for Flow Orchestration in an org that doesn't have the SKU.** Confirm licensing before design. Flow Orchestration is a separately licensed capability on some editions — if it's not enabled, the `processType=Orchestrator` deploy fails and you wasted a sprint.

---

## 7. Common Failure Modes and Remediation

### Failure 1 — "Orchestration starts but never advances past Stage 1"
- **Symptom:** Orchestration Run shows status `In Progress`, Stage 1 shows the Interactive Step assigned, but days later the run is still on Stage 1.
- **Root cause:** The assignee never saw the work. Either Work Queue / Work Guide isn't on their page, their permission set doesn't grant Orchestrator access, the assignee formula resolved to an inactive user, or the Interactive Step's screen flow is erroring silently.
- **Fix:** Open Orchestration Runs → the run → Stage 1 → Step details. Confirm the resolved assignee is an active user. Log in as the assignee and check Work Queue. If empty, verify the assignee's permissions (Flow Orchestration Runtime) and their Home page includes Work Queue. Check Setup → Flow Error Emails for the screen flow.

### Failure 2 — "Migrated from legacy Approval Process — now the record has two active approval states"
- **Symptom:** After go-live of the new Flow Orchestration, the record's `Approval Status` field says `Pending` (legacy) AND the Orchestration Run is also active. Users see duplicate approval requests.
- **Root cause:** The legacy Approval Process was not deactivated when the Orchestration was turned on. Both engines are running against the same record.
- **Fix:** Deactivate the legacy Approval Process (Setup → Approval Processes → Deactivate). Recall any in-flight legacy approvals. Migrate their state into the new Orchestration manually (not automated). Verify only one orchestration engine is running per record going forward — add a validation rule if needed to prevent accidental reactivation.

### Failure 3 — "Async Path callout completes but the orchestration doesn't resume"
- **Symptom:** The Background Step's external callout returned 200 OK. The external system did its work. But the Orchestration Run is still paused on the Background Step.
- **Root cause:** The Async Path is waiting on a Platform Event or a resumption signal that never arrived. Either the callout response was never wired into a Platform Event publish, or the Platform Event subscriber for the orchestration isn't picking up the event.
- **Fix:** Confirm the callout path publishes a Platform Event on completion (from the invocable Apex or from the external system via a Connected App / webhook). Confirm the Orchestration's Async Path is configured to subscribe to that Platform Event type. Inspect Platform Event monitor logs to confirm the event was actually published.

### Failure 4 — "Parallel Steps in one Stage — but the Stage completes before all have finished"
- **Symptom:** Three Interactive Steps are marked as parallel in one Stage. Only one is completed, and the Stage advances to the next Stage anyway.
- **Root cause:** Stage Completion criteria is set to "Any Step completes" when it should be "All Steps complete".
- **Fix:** Open the Stage → Stage Completion → change to `All Steps` (AND). Redeploy. Test with a fresh run. If the business wants "any two of three" semantics, combine a Decision element with a counter variable — native Stage Completion doesn't express quorum logic.

### Failure 5 — "Orchestration Run failures are silent — no email, no alert"
- **Symptom:** An orchestration fails in production, the record stays in limbo, nobody notices until a user complains.
- **Root cause:** No failure notification is configured. Flow Orchestration does not auto-email on failure the way invocable Flow failures do; failures surface in Orchestration Runs UI only.
- **Fix:** Add a Background Step on the failure path that emails an admin group (via email alert, Chatter post, or Slack message). Add a scheduled Apex or Flow that queries `OrchestrationRun` records where `Status = 'Error'` daily and posts a digest. Configure Setup → Process Automation Settings → Error Email Recipients as a baseline.

### Failure 6 — "Reassigning a step doesn't work — the new assignee never sees it"
- **Symptom:** An admin reassigns a pending Interactive Step from User A to User B via the Orchestration Run UI. User B's Work Queue doesn't show it.
- **Root cause:** Reassignment in Orchestration is not always instant — it requires Platform Cache refresh, and if the reassignment was done via API (not UI) with incorrect field, the step's `AssignedToId` may not have persisted.
- **Fix:** Confirm via SOQL `SELECT AssignedToId FROM OrchestrationStep WHERE OrchestrationRunId = 'xxx'`. If wrong, update via supported API (`OrchestrationStep.AssignedToId` is the correct field). Have User B refresh Work Queue (hard reload). For orgs that reassign frequently, build a small admin utility LWC that reassigns with proper platform-event emission.

---

## 8. Flow Orchestration Cheat Sheet

### Core metadata surface

| Metadata | Purpose | File suffix |
|---|---|---|
| Orchestrator Flow | The orchestration itself | `.flow-meta.xml` with `<processType>Orchestrator</processType>` |
| Step Screen Flow | The UI for an Interactive Step | `.flow-meta.xml` with `<processType>Flow</processType>` |
| Autolaunched Flow | Target of a Background Step | `.flow-meta.xml` with `<processType>AutoLaunchedFlow</processType>` |
| Invocable Apex Action | Target of a Background Step (code path) | `.cls` with `@InvocableMethod` |
| Platform Event | Resumption signal for Async Path | `.platformEvent-meta.xml` |
| Approval Process (legacy) | Legacy approval engine | `.approvalProcess-meta.xml` |

### Runtime objects (for SOQL / reporting)

| Object | Purpose |
|---|---|
| `OrchestrationRun` | One run of an orchestration against a record |
| `OrchestrationStageRun` | One Stage within a Run |
| `OrchestrationStep` | One Step within a Stage Run (pending / completed / errored) |
| `FlowOrchestrationWorkItem` | The assigned work surfaced in Work Queue |
| `ProcessInstance` (legacy) | Legacy Approval Process runs |
| `ProcessInstanceStep` (legacy) | Steps within a legacy Approval Process run |

### Assignee formulas (examples)

```
{!recordVar.Owner.ManagerId}                           // manager of record owner
{!$Record.Account.Owner.Id}                            // owner of related account
{!$User.Id}                                            // current running user (rarely correct)
{!IF(recordVar.Amount__c > 50000,
     $Setup.ApprovalConfig.VP_Approver_Id__c,
     recordVar.Owner.ManagerId)}                       // conditional
```

For Queues: set the Interactive Step's **Assigned To** to the Queue's DeveloperName.

### Work surface components

| Component | Where it goes | What it shows |
|---|---|---|
| **Work Queue** | Home page, App page | All pending Orchestration Steps for the current user |
| **Work Guide** | Record page | Active Step for this record's Orchestration Run (inline) |
| **Orchestration Run** Related List | Record page | History of runs on this record |

### Key limits / watchouts

- Orchestration metadata must be **activated** to run — a deploy is not enough.
- Stage count per Orchestration: check current release notes (was 25 as of Spring '24).
- Step count per Stage: check current release notes (was 10 parallel).
- Platform Event-based Async Path requires a specific `EventDefinition` reference in the step config.
- Orchestration Runs retention is governed by Big Objects / archival settings — confirm with compliance.

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Author step screen flow UX (complex LWC) | [sf-lwc](../sf-lwc/SKILL.md) | Component code |
| Invocable Apex action called from Background Step | [sf-apex](../sf-apex/SKILL.md) | Apex implementation |
| Record-triggered "initial trigger" Flow that launches the Orchestration | [sf-flow](../sf-flow/SKILL.md) | Flow is the entry point |
| Assign orchestration to a Queue — queue setup | [sf-permissions](../sf-permissions/SKILL.md) | Queue / group config |
| Slack notification to assignee on assignment | [sf-slack](../sf-slack/SKILL.md) | Slack-First patterns |
| Deploy the orchestration to sandbox / prod | [sf-deploy](../sf-deploy/SKILL.md) | DevOps |
| Pre-flight regression for the orchestration | [sf-demo-playwright](../sf-demo-playwright/SKILL.md) / [sf-demo-validate](../sf-demo-validate/SKILL.md) | Validation |
| Diagram the orchestration | [sf-diagram-mermaid](../sf-diagram-mermaid/SKILL.md) | Architecture diagram |

---

## 9. Output Format

When finishing, report in this order:

1. **Task classification** — design / migrate-from-approval / troubleshoot / build
2. **Industry pre-check** — skipped (platform-level primitive); note any caller industry skill
3. **Orchestration type** — Record-Triggered / Autolaunched
4. **Pattern** — sequential / parallel / conditional / long-running-with-external-event / migration-from-legacy
5. **Stages and steps** — count, names, assignee model per step
6. **Async boundaries** — where callouts and Platform Events live
7. **Legacy Approval Process disposition** — N/A / retiring / migrated-to-in-flow / migrated-to-orchestration
8. **Work surface** — Work Queue placement + Work Guide placement
9. **Scoring total** — N / 130, with any sub-threshold category flagged
10. **Next recommended step** — next phase or cross-skill handoff
