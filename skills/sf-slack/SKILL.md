---
name: sf-slack
description: >
  Slack-First workflows from Salesforce, Slack Canvases, Slack AI,
  Slack app manifest, Bolt SDK, Slack Sales Elevate, and Slack for
  Service with 140-point scoring and industry-first routing precedence.
  TRIGGER when: user builds Slack app manifests, Slack workflows (Workflow
  Builder or Bolt), Slack Canvases, Slack AI summaries/recaps, slash
  commands, message shortcuts, Slack actions from Salesforce Flow or
  Agentforce, Slack Connect rooms, Enterprise Grid governance, Slack Sales
  Elevate deal rooms, Slack for Service swarming; or says "send to Slack
  from Flow", "Slack Canvas template", "Slack AI recap", "slash command
  /foo", "Slack app manifest", "Slack bolt app in TypeScript/Python",
  "Slack Connect for external orgs", "Enterprise Grid sharing", "Sales
  Elevate digital deal room", "Slack for Service swarm".
  DO NOT TRIGGER when: the request is primarily Data Cloud activation to
  Slack as a destination (use sf-datacloud-act); Agentforce agent handoff
  into Slack where the agent wiring dominates (use sf-ai-agentforce);
  Salesforce Flow where Slack is one step among many and the Flow design
  dominates (use sf-flow); Marketing Cloud Growth Slack notification
  (use sf-marketing-cloud-growth); nonprofit/industry Slack patterns
  where the industry overlay governs channel topology (see Phase 0:
  route to sf-nonprofit-cloud for donor/volunteer Slack, sf-industry-fsc
  for advisor/client Slack Connect, sf-industry-health for HIPAA-bounded
  channels).
license: MIT
compatibility: "Requires Slack workspace + Salesforce-Slack integration license; Slack AI requires Slack AI add-on"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "140 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-04
upstream_refs:
  - url: https://api.slack.com/docs
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.slack_sales_elevate.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://api.slack.com/automation
    anchor: ""
    sha256: ""
    importance: authoritative
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_slack.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "140-pt rubric inline (7 categories: Channel Topology + Naming 15, Governance + Compliance 25, SF→Slack 20, Slack→SF 20, Canvases + AI 20, Bolt App Quality 20, Rollout + Adoption 20), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  slack_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Channel topology + bot-app build is correct. Maps to Channel Topology + Naming (15) + Bolt App Quality (20)."
      automatic_hard_fail_rules:
        - "Any Bolt app without manifest version-controlled (production drift inevitable)"
        - "Any channel topology with ad-hoc channel creation (audit + governance breaks)"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "Governance + compliance solid. Maps to Governance + Compliance (25) — most often-failed category in regulated industries. Heaviest robustness hard-fail."
      automatic_hard_fail_rules:
        - "Any Slack Connect + Slack AI in regulated industry without Phase 0 industry-rule check"
        - "Any DLP / eDiscovery / retention policy missing on a Grid that handles PHI/PII"
        - "Any Slack OAuth Connected App requesting more scopes than action needs"
    - name: Fit
      max: 25
      hard_fail_below: 14
      description: "SF↔Slack actions wired correctly. Maps to SF→Slack (20) + Slack→SF (20) + Canvases + AI (20)."
      automatic_hard_fail_rules:
        - "Any Slack AI enabled on a channel where data classification doesn't allow (unmasked PII surfaced)"
    - name: Performance
      max: 25
      hard_fail_below: 14
      description: "Rollout + adoption tracked. Maps to Rollout + Adoption (20)."
      automatic_hard_fail_rules:
        - "Any rollout without pilot metrics captured (no signal on success)"
        - "Any rollout without quarterly audit scheduled (governance decay)"
  test_rubric:
    unit:
      required: true
      criteria: "Slack manifest validates against Slack API schema. Bolt app passes its own unit tests."
    integration:
      required: true
      criteria: "Bolt app installs against a sandbox Slack workspace. Connected App OAuth flow completes."
    smoke:
      required: true
      criteria: "End-to-end SF→Slack message + Slack→SF action completes without error. Slack AI summary on a real conversation produces sensible output."
---

# sf-slack: Slack-First Workflows, Canvases, Slack AI, Slack Actions

Owns Slack + Salesforce integration surface: Slack app manifests, Workflow Builder workflows, Bolt SDK apps (TypeScript / Python), Slack Canvases, Slack AI recaps/summaries, slash commands, message shortcuts, Slack actions from Salesforce Flow + Agentforce, Slack Connect rooms, Enterprise Grid governance, Slack Sales Elevate, and Slack for Service.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 140-pt rubric in fresh context. Robustness floor at 18 — Governance + Compliance is the most-failed category in regulated industries. Disable with `eval_harness.enabled: false`.

---

## When This Skill Owns the Task

Use `sf-slack` when the work involves:

- **Slack app manifests** (`manifest.json` / `manifest.yaml`) — slash commands, message shortcuts, unfurls, OAuth scopes
- **Bolt SDK** apps in TypeScript or Python — event subscriptions, slash commands, interactive components
- **Slack Workflow Builder** workflows (no-code / low-code)
- **Slack Canvases** — collaborative docs, templates, Canvas automations
- **Slack AI** — conversation recaps, thread summaries, channel recaps, Slack AI search
- **Slack actions from Salesforce** — Flow "Send to Slack" actions, Agentforce agent → Slack handoff, Record Action to Slack channel
- **Slack Connect** — external-organisation shared channels, governance, DLP
- **Enterprise Grid** — multi-workspace governance, IdP integration, information barriers
- **Slack Sales Elevate** — deal rooms, account channels, Salesforce record previews, deal-room playbooks
- **Slack for Service** — swarming, case channels, expert routing

---

## Phase 0: Industry Pre-Check (MANDATORY)

Before producing any artifact, run the shared industry pre-check at [`references/industry-precheck.md`](../../references/industry-precheck.md).

**Slack topology changes dramatically by industry.** A generic "customer success Slack channel" design is legally wrong for Health Cloud (HIPAA), governance-heavy for FSC (advisor ↔ client Slack Connect), and culturally wrong for a nonprofit donor stewardship channel. Route before building.

1. Detect installed industry clouds via license/feature scan + namespace scan (see pre-check reference).
2. If an industry cloud is installed AND the user's Slack workflow touches that industry's constituents, **halt and forward**:
   - FSC advisor / client / partner Slack Connect — confirm KYC-respecting room governance, record-preview scope, message-retention policy → `sf-industry-fsc`
   - **Health Cloud** patient / care-team channels — HIPAA boundary is hard: PHI must not flow into non-BAA Slack channels. Route to `sf-industry-health` for PHI handling rules before any Slack topology design.
   - Education Cloud student / advisor / faculty channels → `sf-industry-education`
   - Public Sector constituent / caseworker channels → `sf-industry-public-sector`
   - Nonprofit donor stewardship, volunteer coordination, grantee comms, case-management swarming → `sf-nonprofit-cloud` orchestrator, then specific `sf-nonprofit-*` skill
   - Manufacturing partner / distributor channels → `sf-industry-manufacturing`
   - Communications / Media / Energy B2B Slack Connect → corresponding `sf-industry-*`
3. **Return path**: industry skill confirms data-classification, retention, and who-can-be-in-the-room. This skill builds the Slack artifact on top of those rules.
4. If the user explicitly says "standard Slack-first workflow, bypass industry overlay", document the exception and proceed.

Print handoff on deferral, e.g.:

```
Detected Health Cloud + request mentions sharing patient identifiers into Slack.
HALT: PHI in non-BAA Slack is a HIPAA violation. Routing to sf-industry-health to
define PHI-safe patterns (Salesforce-side case notes with Slack swarm pointer
only; PHI never leaves Salesforce) before any Slack-app design.
```

---

## Required Context to Gather First

Ask for or infer:

- Slack plan: Business+, Enterprise Grid? (Grid unlocks org-level governance)
- Slack AI licensed? (channel recap, thread summary, search)
- Salesforce–Slack integration installed? (Sales Cloud for Slack, Service Cloud for Slack, Agentforce Slack channel)
- Slack Sales Elevate licensed? (Digital Deal Rooms)
- Slack for Service enabled? (swarming, case-channel creation)
- Industry cloud + regulatory constraints (see Phase 0)
- Internal-only or Slack Connect (external orgs)?
- Channel topology: per-account, per-deal, per-case, per-incident, per-team
- Who can invite external users? (critical in Connect)
- DLP + eDiscovery requirements
- Retention policy per channel type
- Custom app build (Bolt) or Workflow Builder only?

---

## Workflow Phases

### Phase 1: Channel + Governance Topology

1. Decide channel pattern: **per-account**, **per-deal**, **per-case**, **per-incident**, **per-topic**.
2. Naming convention (e.g., `#acct-<account-id>-<name>`, `#case-<caseNumber>`, `#deal-<oppId>`). Consistency enables automation.
3. Membership automation: who auto-joins on creation? who is invited on trigger?
4. Archival policy: when does the channel archive? (closed-lost deal after 30 days, resolved case after 14, etc.)
5. **Slack Connect rules**: who can invite, what domains allowed, message retention for cross-org, DLP policies.

### Phase 2: Salesforce → Slack Actions

1. **Flow "Send to Slack" action** — simple record-triggered notifications, approval requests, field-update digests.
2. **Record Action to Slack** — button on Lightning record page that posts to a channel + creates a deal room.
3. **Agentforce → Slack handoff** — agent escalation writes to a Slack channel with conversation context; human picks up.
4. **Sales Elevate Deal Room** — auto-create channel on Opportunity stage change; pin key records; add account team.
5. **Service Cloud swarm** — on high-priority case, auto-create swarm channel with SME routing.
6. Always: enforce channel topology from Phase 1; never let action-authors reinvent channel names.

### Phase 3: Slack → Salesforce Actions

1. **Slash command** (e.g., `/log-meeting`) posts to a Bolt app → creates Task / Event / Contact in Salesforce.
2. **Message shortcut** "Save to Salesforce" attaches the message as a Case Comment / Chatter post / Activity.
3. **Unfurl**: paste a Salesforce record URL, Slack unfurls with record preview (via Sales Cloud / Service Cloud for Slack app).
4. **Canvas automation**: on Deal Room creation, pre-populate a Canvas from a template with account info, MEDDIC fields, meeting notes.
5. Authorise via OAuth Connected App on the Salesforce side (see `sf-connected-apps`).

### Phase 4: Slack Canvases + Slack AI

1. **Canvas templates**: Deal Canvas, Account Canvas, Case Canvas, Incident Canvas, Project Canvas.
2. Embed live Salesforce data in Canvas via Sales Cloud for Slack record-preview blocks (read-only) or Bolt-authored dynamic Block Kit (read-write).
3. **Slack AI recap**: schedule channel recap for async teammates; thread summary for long swarm threads; search across recent channels.
4. Governance: which channels have AI enabled? AI indexes content — confirm data classification.

### Phase 5: Bolt SDK App (when Workflow Builder isn't enough)

1. Decide stack: **Bolt for TypeScript** (Node), **Bolt for Python**, or **Bolt for Java**. All three are first-class on api.slack.com/tools.
2. Hosting: Salesforce Hyperforce / Heroku / AWS / Slack-hosted functions. For tight SF integration, Heroku is the historical choice; Hyperforce emerging for 2026.
3. Manifest-first: author `manifest.json`, version-control it, rotate tokens via Slack API. The Slack CLI (`slack create` / `slack run` / `slack deploy`) is the current recommended onboarding and dev loop; pair it with the Slack GitHub Action for CI.
4. Event subscription scopes: **grant the minimum** needed. `channels:history` is an audit landmine — prefer `channels:read` + explicit conversation API calls.
5. Persistence: store conversation state, not messages. Let Slack remain the source of truth for message history.
6. Test in a sandbox Slack workspace before promoting to production Grid.

### Phase 6: Enterprise Grid + Compliance

1. **Information barriers** for regulated industries (FSC advisor ↔ research wall; Health provider ↔ payer).
2. **IdP-based provisioning** (SCIM) for user lifecycle.
3. **DLP** integrations for message content inspection.
4. **eDiscovery** exports for legal hold.
5. **Retention policies** per channel type (deal, case, swarm, Connect).
6. **Slack AI data boundaries** — confirm AI does not index regulated channels unless contractual/BAA coverage allows.

### Phase 7: Rollout + Change Management

1. Pilot channel topology with one team; measure adoption (active members, messages/day, Salesforce action frequency).
2. Publish a one-page "How we use Slack for [deal rooms / swarms / donor stewardship]" Canvas as the org's reference.
3. Train admins on channel lifecycle (create, archive, audit).
4. Schedule quarterly review: unused channels archived, Connect partners audited, orphaned Bolt apps decommissioned.

---

## Scoring Rubric

Total: **140 points across 7 categories.** Any category below its pass threshold fails the whole review.

```
Score: XX/140
├─ Channel Topology + Naming: XX/15     (pass >= 10) Pattern matches use case; naming deterministic; archival + membership automated
├─ Governance + Compliance: XX/25       (pass >= 18) Grid policies / DLP / eDiscovery / retention set; Connect rules explicit; industry rules respected (Phase 0)
├─ SF -> Slack Actions: XX/20           (pass >= 14) Flow + Record Action + Agentforce handoff wired; channel topology enforced; no ad-hoc channel creation
├─ Slack -> SF Actions: XX/20           (pass >= 14) Slash commands + shortcuts + unfurl configured via OAuth Connected App; least-scope tokens
├─ Canvases + AI Layer: XX/20           (pass >= 14) Canvas templates in use; Slack AI enabled only where data classification allows; summaries add value
├─ Bolt App Quality (if built): XX/20   (pass >= 14) Manifest-first, minimum scopes, manifest version-controlled, sandbox-tested, persistent state modelled
└─ Rollout + Adoption: XX/20            (pass >= 14) Pilot metrics captured; reference Canvas published; admin training done; quarterly audit scheduled
```

Passing score: **100/140 with every category at pass threshold.** Governance + Compliance is the category most often failed — particularly in regulated industries where Slack Connect + Slack AI expose new data surfaces.

---

## Anti-Patterns

- **Creating Slack channels from Flow without a naming convention.** Within a quarter you'll have `#acme-deal`, `#acme_deal`, `#acme-deal-2`, `#acme-deal-renew-v3`. Consistency is the foundation.
- **Letting agents write PHI / PII into Slack.** Slack is not inherently a BAA-covered store for most orgs. Route to Salesforce-side case notes; Slack holds the swarm pointer only.
- **Over-scoped Bolt app tokens.** `channels:history` + `im:history` + `groups:history` on a production app with a single contractor maintainer is an audit catastrophe. Minimum scope, always.
- **Per-account Slack Connect with every customer in one workspace.** Governance collapses. Use Grid workspaces; segregate Connect partners; audit quarterly.
- **Slack AI enabled on regulated channels without data-boundary confirmation.** AI summaries will quote sensitive values. Disable AI on any channel whose classification forbids third-party indexing.
- **Agentforce handoff to Slack without conversation context.** The human picks up cold. Always include: user identity, conversation transcript (redacted if needed), and a deep link to the Agentforce session record.
- **Deal rooms created on every Opportunity regardless of stage.** Channel sprawl kills adoption. Gate on stage = "Negotiation" or "Proposal" or similar signal, not "Qualification".
- **Slack-first workflows that replace Salesforce record-keeping.** Conversations go in Slack; decisions go in Salesforce. A deal has to close on the record, not in a channel.
- **Bolt app with no manifest.json version-controlled.** Deploy drift between Slack and the repo is the #1 cause of "why did the slash command stop working?" It must be source-of-truth.
- **Message shortcut that posts to Chatter instead of a first-class object.** Chatter is not the durable system of record. Tie shortcuts to Case Comments, Tasks, or custom objects.
- **Letting `sf-datacloud-act` and this skill both own the Slack activation.** Data Cloud activation to Slack is a different surface (segment → audience → Slack DM). This skill owns Salesforce-record-driven workflows. Negotiate the boundary explicitly.
- **Using Workflow Builder for a workflow that needs dynamic logic or external API calls.** Graduate to Bolt. Workflow Builder is excellent for linear no-code flows; it is not an application platform.

---

## Common Failure Modes + Remediation

| Symptom | Root Cause | Fix |
|---|---|---|
| Flow "Send to Slack" action fails silently | OAuth scope missing or token expired | Re-authorise the Connected App user; confirm `chat:write` + `chat:write.public` scopes |
| Deal Room channel created but team not added | Sales Elevate user mapping not configured for opportunity team members | Configure user mapping in Slack integration admin; re-run team sync |
| Slash command returns timeout | Bolt app slow ACK; Slack expects ACK within 3s | ACK immediately, defer work to async handler; use `respond()` callback for later message |
| Canvas template missing fields on Deal Room creation | Canvas automation scope token expired or template ID stale | Re-issue template ID; rotate bot token |
| Agentforce Slack handoff doesn't surface conversation | Agent action posts only summary, not transcript or link | Update action to include session URL + last N turns + user identity |
| Slack Connect channel rejects external invite | External domain not on allow-list; or Connect policy forbids external admin | Update Grid-level Connect policy; confirm partner workspace admin approves |
| Slack AI recap includes sensitive record info | AI indexed a regulated channel | Disable AI on that channel; audit what AI has previously summarised |

---

## Cheat Sheet — Slack Artifact Map

| Concern | Artifact | Authoring surface |
|---|---|---|
| App definition | `manifest.json` | api.slack.com app config |
| Slash command | `/cmd` route | manifest + Bolt listener |
| Message shortcut | "Save to Salesforce" | manifest + Bolt listener |
| Unfurl | URL unfurl listener | manifest + Bolt listener or Sales Cloud for Slack |
| Workflow (low-code) | Workflow JSON | Workflow Builder |
| Canvas template | Canvas | Slack UI; automatable via API |
| Slack AI | Channel/Thread recap | Slack UI (licensed) |
| Salesforce-side action | Flow "Send to Slack" | Salesforce Flow Builder |
| Deal Room | Channel + Canvas + record pins | Slack Sales Elevate |
| Case swarm | Channel + Canvas + SME routing | Slack for Service |
| Bolt app | TypeScript/Python/Java project | Slack CLI (`slack create`/`slack run`) or IDE + manifest |
| Slack CLI | `slack login`, `slack create`, `slack run`, `slack deploy` | Terminal; official onboarding path per api.slack.com/docs |
| Slack GitHub Action | CI workflow step | `.github/workflows/*.yml` (see Slack GitHub Action tool) |
| Slack AI agent | Agent app built on Slack platform | `/ai/agent-quickstart` (Slack-native agents, distinct from Agentforce handoff) |
| Hosting | Heroku / Hyperforce / AWS / Slack-hosted functions | ops choice |
| Governance | Information barriers + retention + DLP | Enterprise Grid admin |

---

## Cross-Skill Integration

| To Skill | When to Use |
|---|---|
| `sf-connected-apps` | OAuth Connected App that Slack Bolt app consumes to hit Salesforce APIs |
| `sf-integration` | Named Credential / External Service wrapper for Slack API from Apex |
| `sf-flow` | Flow design dominates, Slack is one step — route Flow design there and return for Slack details |
| `sf-ai-agentforce` | Agent build is primary; agent-to-Slack handoff is a sub-feature |
| `sf-datacloud-act` | Data Cloud activation → Slack DM for segments (different surface) |
| `sf-marketing-cloud-growth` | Marketing journey Slack notification (MCG activation) |
| `sf-industry-*` / `sf-nonprofit-*` | Always before Slack topology design when industry overlay present |
| `sf-apex` | Custom callable that fires Slack webhook / chat.postMessage |
| `sf-deploy` | CI/CD for Salesforce metadata that wires the Slack-integrated Flow |

---

## Additional Resources

- [Slack API documentation](https://api.slack.com/docs)
- [Slack Automation (Workflow Builder + functions)](https://api.slack.com/automation)
- [AI in Slack / Create an agent quickstart](https://api.slack.com/ai/agent-quickstart)
- [Slack CLI](https://api.slack.com/tools/slack-cli)
- [Slack GitHub Action](https://api.slack.com/tools/slack-github-action)
- [Bolt frameworks (JavaScript, Python, Java)](https://api.slack.com/tools)
- [Slack Sales Elevate (Salesforce Help)](https://help.salesforce.com/s/articleView?id=sf.slack_sales_elevate.htm)
- [Industry pre-check reference](../../references/industry-precheck.md)
