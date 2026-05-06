---
name: sf-sales-engagement
description: >
  Sales Engagement (formerly HVS): cadences, work queues, Sales Dialer, EAC,
  Sales Email Capture. Industry-first routing.
  TRIGGER when: user designs SDR/AE motions — multi-touch cadences, dialer
  provisioning, call dispositions, auto-call logging, EAC sync, email
  tracking, cadence targeting, HVS→Sales Engagement migration.
  DO NOT TRIGGER when: scope is multi-capability Sales (sf-sales-cloud),
  Opportunity (sf-sales-opportunity), Forecasts (sf-sales-forecasting);
  industry / nonprofit pack owns the cadence data (matching sf-industry-* /
  sf-nonprofit-* skill); Marketing sends (sf-marketing-cloud-growth,
  sf-marketing-account-engagement); Service Omni-Channel (sf-service-cloud);
  Field Service dispatch (sf-field-service); Revenue Cloud quote follow-up
  (sf-revenue-cloud); code — Apex (sf-apex), LWC (sf-lwc), Flow (sf-flow),
  Data Cloud (sf-datacloud).
license: MIT
compatibility: "Requires Sales Engagement PSL (formerly HVS); industry-first routing applies"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.sales_engagement.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.einstein_activity_capture.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/sales
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_sales.htm
---

# sf-sales-engagement: Cadences, Dialer, Activity Capture

Owns Sales Engagement (the product formerly known as High Velocity Sales) end-to-end: Cadences, Cadence Steps, Cadence Auto-Add Rules, Work Queues, Prioritized Work Queue, Sales Dialer, Sales Calls, Einstein Activity Capture (EAC), Sales Email Capture, Lightning email templates feeding cadences, email tracking, and call dispositions with auto-logging. Opportunity mechanics, forecasts, and multi-capability design route elsewhere.

---

## When this skill owns the task

Use `sf-sales-engagement` when the work involves:

- Cadence design — inbound-response, outbound-prospecting, renewal, win-back, event-follow-up
- Cadence steps — email, call, video, custom, LinkedIn, wait
- Auto-add rules — criteria-based entry from Lead or Contact; flow-driven; manual
- Target type handling — Lead vs Contact mismatch resolution
- Sales Dialer — provisioning, number assignment, routing rules, call outcomes
- Sales Calls + call disposition picklists + auto-call logging
- Prioritized Work Queue — ordering logic for the rep's "next best action"
- Einstein Activity Capture (EAC) — Gmail / Outlook / Exchange sync, sharing model, public vs private activity
- Sales Email Capture — inbox-sourced email logging, match-to-record behavior
- Lightning email templates used as cadence step content (not pure marketing sends)
- Email tracking — opens, clicks, replies, and how they feed cadence branching
- Handoff points to `sf-marketing-*` for nurture / batch sends and to `sf-service-cloud` for case-driven routing

Delegate elsewhere when:

| Scope | Route to |
|---|---|
| Opportunity splits, teams, stage, Pipeline Inspection | [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md) |
| Forecasts, quotas, adjustments | [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md) |
| Multi-capability Sales Cloud design | [sf-sales-cloud](../sf-sales-cloud/SKILL.md) |
| Journey Builder email / SMS / push | [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md) |
| Pardot Engagement Studio programs | [sf-marketing-account-engagement](../sf-marketing-account-engagement/SKILL.md) |
| Case / Omni-Channel Routing / entitlement | [sf-service-cloud](../sf-service-cloud/SKILL.md) |
| Apex / LWC / Flow implementation | [sf-apex](../sf-apex/SKILL.md) / [sf-lwc](../sf-lwc/SKILL.md) / [sf-flow](../sf-flow/SKILL.md) |

---

## Phase 0: Industry Pre-Check (MANDATORY)

**Before any cadence / dialer / EAC design, run the shared industry pre-check.** See [references/industry-precheck.md](../../references/industry-precheck.md) for the full detection + deferral protocol.

Procedure:

1. **Detect.** Run license / namespace / object scans per the reference.
2. **Cross-reference.** If the user's "cadence" or "outreach" is really an industry-packaged outreach motion, halt and forward:

   | Detected | "Cadence" is really | Route to |
   |---|---|---|
   | FSC (`FinServ__`) | Advisor touch plan tied to Interaction Summaries, Life Event Moments, ARC | `sf-industry-fsc` |
   | Health Cloud (`HealthCloudGA__`) | Patient outreach / care-gap campaign / member engagement | `sf-industry-health` |
   | Education Cloud / EDA (`hed__`) | Recruiter / admissions / advancement outreach on EDA | `sf-industry-education` |
   | Public Sector (`OutfundsPS__`) | Constituent outreach tied to Benefit / Application / License renewal | `sf-industry-public-sector` |
   | Field Service | Technician dispatch, service-appointment reminders | `sf-field-service` |
   | Nonprofit Cloud | Donor stewardship, grantee comms journey, program participant outreach | `sf-nonprofit-cloud` + children |
   | NPSP (`npsp`) | NPSP Engagement Plan on donor Contact | `sf-nonprofit-npsp` |
   | Manufacturing Cloud | Sales Agreement renewal cycle outreach | `sf-industry-manufacturing` |
   | Consumer Goods Cloud | Visit plan on retail Accounts | `sf-industry-consumer-goods` |
   | Communications Cloud (`vlocity_cmt__`) | Subscription churn / upsell outreach tied to subscriber cart | `sf-industry-communications` |
   | Media Cloud (`vlocity_media__`) | Subscriber retention outreach | `sf-industry-media` |
   | Energy & Utilities (`vlocity_ins__` + E&U) | Meter-to-cash / outage communication | `sf-industry-energy` |
   | Revenue Cloud Advanced / CPQ | Quote-follow-up tied to Billing Schedule, subscription renewal | `sf-revenue-cloud` |

3. **Defer.** Emit the standard handoff line and stop generic work.
4. **Proceed only when clean** or the user has explicitly opted out or the cadence is pure generic outbound on standard Lead / Contact.

**NEVER silently override an industry data model.** Running a generic Sales Engagement cadence on top of an FSC advisor touch plan or an NPSP Engagement Plan duplicates the activity and breaks the industry's reporting.

---

## Required context to gather first

- **Sales Engagement PSL** — assigned per user. Without the feature PSL, cadence UI is hidden.
- **Sales Dialer PSL + number provisioning** — separate license; region-specific number pool; minutes budget.
- **EAC user license** — separate PSL; connected mailbox required (Gmail / O365 / Exchange).
- **Sales Email Capture** — distinct from EAC for some flows; confirm which is in use.
- **Persona map** — SDR, BDR, AE, CSM. Different personas own different cadences and work queues.
- **Target type** — Lead, Contact, or Person Account. Cadences can target Lead OR Contact in a single cadence, not both.
- **Conversion flow** — when Lead converts to Contact, does the cadence move with the target? (Default: it doesn't; requires explicit flow handling.)
- **Compliance** — do-not-call, email opt-out, country-specific (TCPA, GDPR), and consent tracking.
- **Email template library** — Lightning email templates, folder structure, variable merge fields.
- **Call disposition picklist** — standardize for reporting.
- **Industry overlay** — confirmed clean from Phase 0.

---

## Workflow phases

### Phase 1 — Scope + persona map

1. Confirm Phase 0 pre-check is clean (or exception documented).
2. List the cadences the business actually needs. Start with 2–4 (inbound MQL, outbound prospecting, renewal, win-back); avoid launching 12 day-one.
3. Assign each cadence to a persona + target type (Lead vs Contact). Mixing target types inside a cadence isn't supported.
4. Confirm Sales Engagement + Dialer + EAC PSL coverage per persona before any build.

### Phase 2 — Cadence design

1. For each cadence, define the step sequence: email, call, wait, video, LinkedIn, custom task. Keep total touches in the 6–10 range for outbound prospecting; inbound-response is usually shorter and faster.
2. Map branching logic on tracked email events (open / click / reply) and call dispositions.
3. Define exit criteria: meeting booked, disqualified, unsubscribed, replied.
4. Define auto-add entry: criteria-based (e.g., lead source = web, status = MQL), flow-driven (record-triggered Flow enrolls on conversion), or manual-only.
5. Draft email templates as Lightning email templates with merge fields. Do not use marketing-send templates — separate governance, separate tracking.

### Phase 3 — Work queue + prioritization

1. Decide how the rep sees their queue: Today's Tasks, Prioritized Work Queue, or a custom list view.
2. Prioritized Work Queue ranks steps across cadences; set the weighting factors (step age, priority, custom score).
3. Train the rep on `Snooze`, `Skip`, and `Complete` semantics — misusing Skip corrupts cadence analytics.

### Phase 4 — Sales Dialer + call disposition

1. Provision dialer numbers in the target regions. Confirm caller-ID display and country compliance (TCPA stamp, DNC scrubbing).
2. Assign dialer numbers per user or per team.
3. Build the call disposition picklist — standard set: Connected, Voicemail Left, No Answer, Wrong Number, Not Interested, Meeting Booked, Bad Data. Keep ~8 values; more fragments reporting.
4. Enable auto-log so every completed call writes a Task with disposition, duration, recording URL (if allowed), and cadence-step linkage.

### Phase 5 — Einstein Activity Capture + Sales Email Capture

1. Decide EAC sharing model: `Everyone`, `Sharing with Groups`, or `Don't Share`. `Everyone` is the default but is often not compliant in regulated industries — if Phase 0 detected FSC, Health, Public Sector, or Education Cloud, strongly reconsider.
2. Provision EAC user PSL + connect each user's mailbox. Expect a 24–48 hour sync ramp.
3. Decide whether calendar + contact sync is one-way or bidirectional.
4. If Sales Email Capture is in use (distinct from EAC), confirm the match-to-record rules so logged emails attach to the right Contact / Lead / Opportunity.
5. Configure email tracking (open / click / reply) and confirm it drives cadence branching where used.

### Phase 6 — Verification + report

1. Smoke: enroll a test Lead in a cadence, confirm the first step appears in the rep's work queue.
2. Smoke: complete a call step, confirm disposition logged, task created, auto-log fired.
3. Smoke: send a tracked email, confirm open / click / reply event is captured.
4. Smoke: convert the test Lead to Contact, confirm cadence behavior matches the design decision (move, exit, or pause).
5. Confirm EAC is syncing activity without duplicating with Sales Email Capture.
6. Confirm industry-specific touch plans are NOT being silently duplicated by the cadence.

---

## Scoring rubric (120 pts)

| Category | Points | Pass threshold |
|---|---|---|
| Phase 0 industry pre-check executed + documented | 20 | Industry detection run; deferral emitted if positive |
| Persona + target type alignment | 10 | Each cadence scoped to Lead OR Contact; PSL coverage confirmed |
| Cadence step design (count, sequencing, exit criteria) | 15 | 6–10 steps outbound; explicit exits; no dead branches |
| Auto-add entry rules | 10 | Criteria-based / flow-driven / manual decided per cadence |
| Branching on tracked events | 10 | Email open/click/reply and call disposition drive next step |
| Sales Dialer + call disposition correctness | 10 | Numbers provisioned; dispositions ≤ 8; auto-log on |
| EAC sharing model + mailbox sync | 10 | Sharing model appropriate for industry; mailbox connected per user |
| Sales Email Capture reconciliation with EAC | 5 | No duplicate activity logging |
| Conversion-time cadence handling (Lead → Contact) | 5 | Explicit decision documented |
| Compliance (DNC / TCPA / GDPR / opt-out) | 10 | Each applicable framework addressed |
| Anti-patterns explicitly avoided | 15 | No cadence explosion, no mixed target type, no industry override |

Pass = 96 / 120. Below 96, revise.

---

## Anti-patterns

1. **Skipping Phase 0.** Standing up a generic cadence in an FSC / Nonprofit / Health / Education / PSS org without checking for packaged touch plans.
2. **Silently overriding an industry data model.** NEVER silently override an industry data model. NPSP Engagement Plans, FSC ARC touch plans, Health Cloud care-gap campaigns, and Education Cloud advancement outreach are industry-owned; duplicating them with Sales Engagement cadences breaks reporting and annoys the persona.
3. **Mixed target type.** Building a single cadence that targets both Leads and Contacts. Not supported; causes silent enrollment failures.
4. **Cadence explosion.** Launching 10+ cadences on day one. Reps ignore what they don't understand; start with 2–4 and add incrementally.
5. **Conversion-time drop-off.** Converting a Lead to a Contact without a plan for what happens to the in-flight cadence. Default behavior is the cadence exits; usually not what the business wants.
6. **Disposition sprawl.** More than ~8 call dispositions. Reporting becomes noise, reps stop selecting deliberately.
7. **EAC sharing = Everyone in a regulated industry.** FSC / Health / PSS / Education Cloud often require activity privacy. The default `Everyone` share can leak PII.
8. **Dialer without compliance stamping.** Turning on auto-dial without TCPA time-of-day enforcement or DNC scrub in the US produces a legal incident.
9. **Using marketing email templates as cadence content.** Marketing sends use a different unsubscribe and tracking infrastructure; reusing them corrupts both motions.
10. **Ignoring Sales Email Capture vs EAC overlap.** Both log activity; enabling both without reconciliation produces duplicate tasks.

---

## Common failure modes + remediation

### Symptom: "Rep says cadence step didn't appear in their queue."
- **Root cause:** Missing Sales Engagement PSL, cadence auto-add entry criteria didn't match, or target type is Lead but rep is looking at Contact queue.
- **Fix:** Verify PSL assignment, replay the auto-add criteria against the record, and confirm target type.

### Symptom: "EAC isn't syncing activity from Gmail / Outlook."
- **Root cause:** Mailbox not connected, user hasn't completed OAuth consent, sync still in initial 24–48 hr ramp, or the sender/recipient matching rules excluded the thread.
- **Fix:** Confirm mailbox connection state in Setup → EAC; wait out the initial ramp; inspect matching rules; confirm domain allow-list.

### Symptom: "Calls aren't auto-logging to the cadence step."
- **Root cause:** Auto-log disabled, dialer number mismatch, or the call was placed from outside the Dialer (manual dial on a mobile).
- **Fix:** Re-enable auto-log; ensure dialer placement; train reps to always place through Dialer for auto-logging.

### Symptom: "Cadence stops advancing after step 3."
- **Root cause:** Step exit criteria triggered (e.g., reply detected), or the target failed a validation rule that blocked the next task creation, or a flow fired that removed the target from the cadence.
- **Fix:** Inspect cadence history on the target; check flow triggers acting on the Task/Lead/Contact; validate step 4 conditions.

### Symptom: "Duplicate tasks: one from cadence, one from EAC / Sales Email Capture."
- **Root cause:** Both surfaces are logging the same email send.
- **Fix:** Decide the single source of truth (usually cadence for outbound, EAC for ambient email) and disable logging from the other for that scenario.

---

## CLI / metadata cheat sheet

```bash
# Sales Engagement cadence inventory
sf data query --target-org <alias> --query "SELECT Id, Name, State, TargetEntity FROM ActionCadence"

# Cadence step inventory for a cadence
sf data query --target-org <alias> --query "SELECT Id, Name, StepType, StepNumber FROM ActionCadenceStep WHERE ActionCadenceId = '<id>'"

# Cadence targets (who is enrolled)
sf data query --target-org <alias> --query "SELECT Id, TargetId, State, CompletionReason FROM ActionCadenceTracker LIMIT 100"

# Sales Dialer number inventory
sf data query --target-org <alias> --query "SELECT Id, PhoneNumber, OwnerId, Country FROM VoiceCallList LIMIT 50"

# Sales Call dispositions in use
sf data query --target-org <alias> --query "SELECT CallDisposition, COUNT(Id) FROM Task WHERE CallType != NULL GROUP BY CallDisposition"

# EAC user enrollment
sf data query --target-org <alias> --query "SELECT UserId, Status FROM UserEmailCalendarSync"

# EAC sharing model
sf data query --target-org <alias> --query "SELECT DeveloperName, MasterLabel FROM PermissionSet WHERE Name LIKE 'EinsteinActivity%'"
```

Metadata surfaces owned here:

- `ActionCadence` + `ActionCadenceStep` + `ActionCadenceRule` (auto-add)
- `ActionCadenceTracker` (target enrollment)
- `Task` (with `CallType`, `CallDisposition`, `CallDurationInSeconds`, `CallObject`)
- `EmailTemplate` (Lightning, cadence-owned)
- `VoiceCall` + `VoiceCallList` (Dialer)
- `UserEmailCalendarSync` (EAC user state)

Feature / license gates:

- Sales Engagement PSL — per user
- Sales Dialer PSL + purchased minutes + provisioned numbers
- Einstein Activity Capture PSL + connected mailbox
- Sales Email Capture — separate enablement path; reconcile with EAC

---

## Output format

```text
Engagement task: <cadence design / dialer / EAC / work queue / email template / compliance>
Phase 0 industry pre-check: <clean / deferred to sf-industry-X (reason)>
License gates: <Sales Engagement PSL / Dialer PSL / EAC PSL confirmed>
Cadence inventory: <count + target type per cadence>
Auto-add rules: <criteria-based / flow-driven / manual>
Dialer: <numbers provisioned / disposition picklist / auto-log state>
EAC: <sharing model / mailbox sync state / PII considerations>
Sales Email Capture vs EAC: <reconciled / single source of truth>
Compliance: <DNC / TCPA / GDPR / opt-out>
Conversion handling: <Lead → Contact cadence behavior>
Hand-offs: <sf-sales-cloud orchestrator / sf-marketing-* / sf-service-cloud>
Verification: <smoke test results / EAC ramp complete / auto-log firing>
Next step: <specific config, or escalate to orchestrator>
```

---

## References

- [Industry pre-check reference](../../references/industry-precheck.md) — MANDATORY Phase 0
- [sf-sales-cloud orchestrator](../sf-sales-cloud/SKILL.md)
- [sf-sales-opportunity](../sf-sales-opportunity/SKILL.md)
- [sf-sales-forecasting](../sf-sales-forecasting/SKILL.md)
- [sf-marketing-cloud-growth](../sf-marketing-cloud-growth/SKILL.md)
- [sf-marketing-account-engagement](../sf-marketing-account-engagement/SKILL.md)
