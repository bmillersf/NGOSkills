---
name: sf-demo-orchestrate
description: >
  End-to-end demo pipeline orchestrator. From a single trigger phrase and a
  batch of discovery notes, runs the full 7-step workflow by delegating to the
  existing demo-lifecycle skills in order: org connect + baseline, notes
  intake, product detection + cross-cloud skill routing, product recommendation
  approval, demoscript generation (sf-demo-author), data seeding (routes to
  sf-nonprofit-demo-data for nonprofit orgs OR sf-demo-data for cross-cloud
  / industry / commercial demos), validation + repair loop (sf-demo-validate),
  and Playwright pre-flight + presenter guide (sf-demo-playwright). May
  invoke sf-ui-fallback-playwright mid-pipeline for CLI dead-ends (Agent
  Builder publish, Prompt Builder activation, Data Cloud segment publish,
  etc.). Emits a single DEMO-PIPELINE-STATUS.md that tracks every phase,
  score, routing decision, and artifact. TRIGGER when: user says "run the full demo
  workflow", "build me a demo for <org>", "end-to-end demo from these notes",
  "take me from discovery to presenter-ready", "orchestrate the demo", "prep
  for a demo", "prep a demo", "prepare a demo", "prepare for a demo", "I
  want to prep for a demo", "demo prep", "get me ready for a demo", "ready
  the demo", or any phrase that asks for all 7 steps of the pipeline from a
  single request. DO NOT TRIGGER when: the user only wants a demoscript
  (use sf-demo-author),
  only wants data seeded (use sf-nonprofit-demo-data), only wants validation
  (use sf-demo-validate), or only wants a Playwright suite (use
  sf-demo-playwright).
license: MIT
metadata:
  version: "1.0.0"
  author: "Brian Miller"
  companion_skills:
    - sf-demo-author
    - sf-nonprofit-demo-data
    - sf-demo-data
    - sf-demo-validate
    - sf-demo-playwright
    - sf-subagent-orchestration
    - sf-ui-fallback-playwright
---

# sf-demo-orchestrate: End-to-End Demo Pipeline

One trigger phrase -> a presenter-ready demo. This skill does **not** re-implement authoring, seeding, or validation; it composes the existing demo-lifecycle skills into the 7-step pipeline illustrated in the project README and enforces the gates that keep a human in the loop.

```
┌─ 1. Connect to Org ───────────────────────────────┐
│   sf org display + baseline scan                   │
├─ 2. Provide Discovery Notes ──────────────────────┤
│   Intake raw notes, transcripts, or bullet lists   │
├─ 2.5 Product Detection & Skill Routing ───────────┤
│   industry-precheck -> map to owning sf-* skills   │
├─ 3. Approve Product Recommendations (GATE) ───────┤
│   Plan mode — user must approve each product       │
├─ 4. Demo Script Generated ────────────────────────┤
│   Delegate -> sf-demo-author                       │
├─ 5. Data Seeded ──────────────────────────────────┤
│   Route -> sf-nonprofit-demo-data (nonprofit) OR   │
│           sf-demo-data (cross-cloud / commercial)  │
├─ 6. Validated & Repaired ─────────────────────────┤
│   Delegate -> sf-demo-validate (up to 3× loop)     │
├─ 7. Ready to Present (GATE) ──────────────────────┤
│   Delegate -> sf-demo-playwright + sign-off        │
└────────────────────────────────────────────────────┘

Mid-pipeline fallback: at ANY phase, if a CLI path dead-ends
(Agent Builder publish, Prompt Builder activation, Data Cloud
segment publish, Experience Cloud site publish, Marketing Cloud
journey activation, etc.), invoke sf-ui-fallback-playwright to
drive the Setup UI headlessly, then resume the current phase.
```

## When to apply

Apply this skill when the user asks for the **whole pipeline in one go** — phrases like:

- "Run the full demo workflow for Acme"
- "Build me an end-to-end demo from these notes"
- "Take me from discovery to presenter-ready"
- "Orchestrate the demo for my acme-demo org"
- "I pasted notes — give me a finished demo"

If the user only wants one phase (author, seed, validate, Playwright), defer to the matching single-purpose skill instead. The auto-router handles that disambiguation.

## Core responsibilities

1. **Kickoff contract** — confirm the target org, locate or request discovery notes, and show the user the 7-phase plan before any delegation
2. **Phase sequencing** — invoke sub-skills in strict order; never run a later phase before its predecessor has produced a consumable artifact
3. **Hard gates** — stop and wait for explicit user approval at Phase 3 (product recommendations) and Phase 7 (final sign-off); never auto-advance past these
4. **Status tracking** — maintain `DEMO-PIPELINE-STATUS.md` at the workspace root with a live checklist, per-phase scores, links to artifacts, and the current repair-loop count
5. **Failure escalation** — if any phase cannot produce a green result after its own internal retries, halt the pipeline with a diagnosis and surface next-step options to the user
6. **Idempotent resume** — if `DEMO-PIPELINE-STATUS.md` already exists, read it and resume from the last incomplete phase instead of restarting from Phase 1

## The 7-phase workflow

### Phase 1 — Connect to the org

**Delegation**: `shell` subagent per `sf-subagent-orchestration` runs `sf org display`, the package + object + site queries, and returns a structured baseline summary (5-10 bullets). Verbose CLI output never enters parent context.

Invoke `sf org display --target-org <alias>` and run the standard baseline scan (installed packages, custom objects, Experience Cloud sites, Person Accounts enabled, Agentforce / Data Cloud / OmniStudio status). Record the baseline in `DEMO-PIPELINE-STATUS.md` under **Phase 1 — Baseline**.

Governing rule: the workspace-level `org-discovery.mdc` rule (Mandate 1) already forbids authoring without this step. This phase makes the mandate explicit and auditable.

**Halt condition**: no org connection, unreachable org, or multiple orgs with no `--target-org` hint -> stop and ask the user which org to use.

### Phase 2 — Intake discovery notes

**Delegation**: keep in **parent**. Notes parsing is a decision-laden classification step (audience, platform, use case signals) whose output every later phase reads — context must persist.

Look for notes in (priority order):

1. A path the user supplied (`notes.md`, `discovery.md`, pasted file)
2. The prior conversation turn (transcript pasted inline)
3. A request to the user if neither is available

Parse the notes once here and store a structured summary (audience, platform signals, use case signals, explicit product asks) in `DEMO-PIPELINE-STATUS.md` — **do not re-parse** in Phase 4. `sf-demo-author` will consume the same summary.

### Phase 2.5 — Product Detection & Skill Routing

**Delegation**: keep in **parent** for the routing decision itself; spawn a `shell` subagent for the detection commands (license / namespace / object scan) so their verbose JSON stays out of parent context.

This phase runs **after** the notes have been parsed (Phase 2) and **before** the user approval gate (Phase 3). Its job is to take the platform signals from the notes and produce a concrete list of **owning child skills** that will be invoked later in Phases 4–6. The routing decisions become the evidence row behind every product recommendation the user sees in Phase 3.

**Step 1 — Run the industry pre-check.** Execute the detection recipe from [`/references/industry-precheck.md`](../../references/industry-precheck.md):

1. License / feature flag scan (`sf org display --json`, `sf org list all --json`)
2. Namespace scan (`sf org list metadata-types --json`)
3. Object existence scan (`EntityDefinition` for industry objects)

Return a compact detection summary (installed industries, installed clouds, installed AI / data / integration features) to the parent. Full JSON stays in the subagent.

**Step 2 — Map each detected + requested product to its owning skill(s).** The demo may include more than one owner; that's expected on cross-cloud demos.

| Detected / requested | Owning skill(s) | Notes |
|---|---|---|
| FSC (Financial Services Cloud) | `sf-industry-fsc` | Industry-first: wins over `sf-sales-cloud` / `sf-service-cloud` when objects are FSC-owned (Households, Financial Accounts, Life Events) |
| Health Cloud | `sf-industry-health` | Industry-first: wins over generic clouds on Patient / Care Plan / Care Request / Care Team |
| Education Cloud / EDA | `sf-industry-education` | Industry-first: Student / Program Enrollment (edu) / Course Connection / Affiliation |
| Public Sector Solutions | `sf-industry-public-sector` | Industry-first: Benefit / License / Permit / Inspection / Regulatory Code Violation |
| Field Service | `sf-field-service` | Industry-first when Work Order / Service Appointment are in scope (even without another industry cloud) |
| Manufacturing Cloud | `sf-industry-manufacturing` | Sales Agreement / Account Forecast / Rebate Program |
| Consumer Goods Cloud | `sf-industry-consumer-goods` | Retail Execution / Visit / Trade Promotion |
| Communications Cloud | `sf-industry-communications` | Enterprise Product Catalog / Order Decomposition |
| Media Cloud | `sf-industry-media` | Subscriber / Ad Sales |
| Energy & Utilities Cloud | `sf-industry-energy` | Premise / Service Point / Meter-to-cash |
| NPC / NPSP (nonprofit) | `sf-nonprofit-cloud` (orchestrator) -> children (`sf-nonprofit-npsp` or `sf-nonprofit-fundraising` / `sf-nonprofit-program-case` / `sf-nonprofit-grants`) | Nonprofit orchestrator decides NPC vs NPSP and fans out |
| Sales Cloud (no industry claim) | `sf-sales-cloud` -> `sf-sales-opportunity` / `sf-sales-forecasting` / `sf-sales-engagement` | Only route here if no industry wins; else defer per industry-precheck |
| Service Cloud (no industry claim) | `sf-service-cloud` -> `sf-service-case` / `sf-service-omnichannel` / `sf-service-knowledge` | Only route here if no industry wins |
| Marketing Cloud Growth (Core-native MC) | `sf-marketing-cloud-growth` | Check for `MarketingCloudGrowth` feature + Data Cloud enabled |
| Marketing Cloud Account Engagement (Pardot) | `sf-marketing-account-engagement` | Check for `pi__` namespace |
| Revenue Cloud Advanced / CPQ | `sf-revenue-cloud` | Quote / Order / Contract / Subscription / Billing |
| Data Cloud | `sf-datacloud` (orchestrator) -> phase children (`sf-datacloud-connect`, `-prepare`, `-harmonize`, `-segment`, `-act`, `-retrieve`) | Data Cloud always routes through its orchestrator |
| Agentforce | `sf-ai-agentforce` + optional `sf-ai-agentforce-persona`, `sf-ai-agentforce-testing`, `sf-ai-agentscript`, `sf-ai-agentforce-observability` | Persona / testing / observability co-apply when the demo shows those surfaces |
| Prompt Builder (standalone prompt templates) | `sf-ai-prompt-builder` | Co-applies with Agentforce when the demo highlights prompt authoring |
| Einstein Trust Layer / Model Builder (BYOM) | `sf-ai-model-builder-trust-layer` | Co-applies on any AI demo that touches masking / BYOM |
| OmniStudio (Core or `vlocity_cmt` / `vlocity_ins`) | `sf-industry-commoncore-omniscript`, `-flexcard`, `-integration-procedure`, `-datamapper`, `-callable-apex`, `-omnistudio-analyze` | Namespace detected by `sf-industry-commoncore-omnistudio-analyze` first, then phase skills |
| Tableau / Tableau Next / CRM Analytics | `sf-tableau` | All three surfaces routed through one skill with 140-pt scoring |
| MuleSoft (Anypoint + MuleSoft for Flow + DataWeave) | `sf-mulesoft` | Middleware demos or hybrid integration demos |
| Slack (Slack-First, Slack AI, Canvases) | `sf-slack` | Includes Slack Sales Elevate / Slack for Service overlays |
| Experience Cloud (non-nonprofit) | `sf-experience-cloud` | Defers to `sf-nonprofit-experience-cloud*` trio if a nonprofit industry also detected |
| Field Service mobile / dispatcher console | `sf-field-service` | Already covered above; reaffirmed here for clarity |
| Flow Orchestration (multi-user orchestrated work) | `sf-flow-orchestration` | Co-applies on approval / work-queue demos |
| Reports & Dashboards (native) | `sf-reports-dashboards` | Co-applies when the demo includes a native report/dashboard moment; defers to industry dashboards when detected |
| Shield / Backup / DevOps Center / Identity SSO | `sf-shield-event-monitoring`, `sf-backup-datamask`, `sf-devops-center`, `sf-identity-sso` | Co-apply on trust / governance / identity demos |

**Step 3 — Resolve conflicts by industry-first precedence.** If two owners claim the same object (e.g., `sf-sales-cloud` vs `sf-industry-fsc` on Household-centric opportunities), the industry skill wins per [`industry-precheck.md`](../../references/industry-precheck.md) unless the user explicitly says "ignore the industry overlay." Record the conflict and the resolution so the decision is auditable.

**Step 4 — Emit routing decisions into `DEMO-PIPELINE-STATUS.md`** under a new **Phase 2.5 — Product Detection & Skill Routing** block. Include:

- Detected industry (or "none — generic")
- Detected additional clouds (Sales, Service, MC variant, Revenue, Tableau, MuleSoft, Slack, Data Cloud, Agentforce, OmniStudio)
- Seed skill routing decision: `sf-nonprofit-demo-data` OR `sf-demo-data`
- Owning skill(s) per product
- Conflict resolutions with reasoning
- UI-fallback note (which surfaces are likely to need `sf-ui-fallback-playwright`, e.g., Agent Builder publish, Prompt Builder activation, Data Cloud segment publish, MCAE form builder, Experience Cloud site publish)

Example block:

```markdown
## Phase 2.5 — Product Detection & Skill Routing   [COMPLETE]
- Detected industry: Financial Services Cloud (FinServ namespace, HouseholdAccount present)
- Additional clouds: Agentforce, Data Cloud, Tableau, Slack
- Seed skill: sf-demo-data (non-nonprofit)
- Owning skills:
  - FSC household / financial account flow -> sf-industry-fsc
  - Relationship map overlay -> sf-industry-fsc
  - Agent copilot on wealth advisor -> sf-ai-agentforce, sf-ai-agentforce-persona
  - Unified profile lookup -> sf-datacloud (-> harmonize + retrieve)
  - Advisor dashboard -> sf-tableau
  - Slack alert on life event -> sf-slack
- Conflict resolved: Opportunity row conflict (sf-sales-cloud vs sf-industry-fsc)
  -> sf-industry-fsc wins (FSC overlay on Opportunity; user did not request bypass)
- UI-fallback expected at: Agent Builder publish, Data Cloud segment publish,
  Slack workflow activation.
```

**Halt condition**: if a product in the notes has **no** owning skill available (e.g., user asks for a Heroku Connect demo and there is no `sf-heroku-connect`), surface this as a gap so the user can drop the product or request a new skill. Do not fabricate routing.

**Pre-check invariant**: Phase 2.5 must complete before Phase 3 begins; the Phase 3 approval table is a pretty-printed projection of the Phase 2.5 routing map.

### Phase 3 — Product + duration gate (HARD STOP)

**Delegation**: keep in **parent**. This is a human-in-the-loop decision gate — never delegate user approval to a subagent.

Switch to plan mode. Present **two** approvals: the recommended product list **and** a target demo duration. Both must be confirmed before Phase 4 starts because they jointly determine story depth, step density, and visual count.

**3a. Product approval table:**

| Product | Status in org | Recommend? |
|---|---|---|
| Nonprofit Cloud | Installed | Include |
| Agentforce | Not enabled — 15 min to provision | Include (audience asked for AI) |
| Data Cloud | Not enabled | Skip (out of scope for this demo) |
| Experience Cloud | Active site `arlington-donor` | Include |

**3b. Demo duration prompt:**

Ask: *"How long is the presenter's slot? Pick one tier (or give a custom minute count and I'll round to the nearest tier)."*

| Tier | Minutes | Story shape | Step density | Visual steps | Personas |
|---|---|---|---|---|---|
| **Lightning** | 5 | Challenge → Resolution (skip Situation setup) | 3-4 | 1 | 1 driver |
| **Short** *(default)* | 15 | 4-beat arc, condensed | 6-8 | 1-2 | 1-2 |
| **Standard** | 30 | Full 4-beat arc | 9-12 | 2-3 | 2-3 |
| **Extended** | 45 | Full arc + admin/setup view | 12-16 | 3 | 2-4 |
| **Workshop** | 60 | Full arc + handoffs + Q&A buffer | 16-22 | 3-4 | 3-4 |

If the user does not specify a duration, default to **Short (15 min)** and call that out so they can correct it. If they give a non-tier number (e.g. 20 min), pick the nearest tier and note the rounding.

Wait for the user to approve products **and** confirm the duration. Record both under **Phase 3 — Approved Products** and **Phase 3 — Demo Duration** in the status file. Do not proceed to Phase 4 until both are approved.

This gate is identical in spirit to `sf-demo-author` Phase 0.5 and Mandate 2 of `org-discovery.mdc`. The orchestrator ensures it happens even when the user drops into the pipeline from a single "run the whole thing" prompt.

### Phase 4 — Delegate to sf-demo-author

**Delegation**: `generalPurpose` subagent per `sf-subagent-orchestration`. Mission: run `sf-demo-author` Phases 1-4 against the approved notes + product list **+ approved `demo_duration_minutes`** and return `demoscript.md`, persona cards, data seed requirements, and a presenter cheat sheet (file paths only — parent does not need the full demoscript bytes in context to coordinate).

Hand the approved notes, product list, **and `demo_duration_minutes`** to `sf-demo-author` and instruct it to run its Phases 1-4 (notes intake, story architecture, persona definition, click path generation). Phase 0 and 0.5 from `sf-demo-author` have already been satisfied by Phases 1 and 3 of this orchestrator — do not re-run them. The duration must appear in the demoscript YAML frontmatter as `demo_duration_minutes:` and bound the step count, story depth, and visual count per the tier table in Phase 3.

Expected artifacts:
- `demoscript.md` (story arc, personas, click path, prerequisites, cleanup section)
- Persona cards
- Data seed requirements
- Presenter cheat sheet

Record artifact paths in `DEMO-PIPELINE-STATUS.md` -> **Phase 4 — Artifacts** and note the `sf-demo-author` scoring rubric result.

### Phase 5 — Delegate to the demo data factory (routed)

**Delegation**: `generalPurpose` subagent per `sf-subagent-orchestration` for record generation (Apex / JSON tree authoring), then a `shell` subagent for the actual `sf data` import + Anonymous Apex execution. Verbose import logs stay in the shell subagent's context; parent receives a row-count summary plus paths to the seed and teardown scripts.

**Seed skill routing.** The orchestrator picks the right data factory based on the Phase 2.5 routing decision:

| Detected | Route to | Why |
|---|---|---|
| Nonprofit Cloud (NPC) OR NPSP (`npsp` managed package) | `sf-nonprofit-demo-data` | NPC/NPSP data model knowledge: Gift Transaction / Gift Designation, Program Enrollment, Individual Application, household/soft-credit patterns |
| Anything else (Sales / Service / Revenue / FSC / Health / PSS / Field Service / Manufacturing / Consumer Goods / Media / E&U / Communications / Agentforce-only / Data Cloud-only / MC Growth / MCAE / Tableau / Slack) | `sf-demo-data` | Cross-cloud, persona-matched data factory with industry cohorts (FSC households, Health patient cohorts, PSS constituents, Field Service work orders, Manufacturing sales agreements, Sales opportunity pipelines, Service case volumes, Revenue quote-to-cash) |

Hand the persona cards and data seed requirements to the selected skill. Both skills follow the same **platform detection -> persona-to-record mapping -> field inventory -> generation (JSON tree / Apex / `sf data`) -> freshness -> teardown** pattern, so the orchestrator's contract with the downstream skill is identical regardless of which one it picks.

Expected artifacts (either skill):
- `data/seed/*.json` (tree files) or `scripts/apex/seed-*.apex`
- `scripts/apex/teardown-*.apex` targeting `@demo.` email domains
- Persona / cohort distribution plan (donor pyramid, case-volume curve, opportunity-stage funnel, etc.)

Verify seeding by running the skill's own smoke check, then record in **Phase 5 — Seed Results**, including which data factory was invoked.

If the demo spans nonprofit AND cross-cloud surfaces (rare — e.g., a nonprofit using Sales Cloud Forecasting as a commercial-side overlay), route the nonprofit-owned records to `sf-nonprofit-demo-data` and the commercial-side records to `sf-demo-data`. Sequence nonprofit first (so Account / Contact / Person Account parents exist) before the cross-cloud skill runs its overlay.

### Phase 6 — Validate and repair (loop up to 3×)

**Delegation**: `shell` subagent per `sf-subagent-orchestration` runs each `sf-demo-validate` attempt and returns the 10-category score breakdown plus the failed-step list (not the full validation log). The pass/fail decision and any "accept partial / re-run / escalate" call stays in the **parent**.

Invoke `sf-demo-validate` against the generated `demoscript.md`. The sub-skill already owns its 10-category / 200-point rubric and its own repair loop (delegating fixes to `sf-metadata`, `sf-deploy`, `sf-permissions`, `sf-data`, `sf-flow`, etc.).

Orchestrator-level rules:

- **Pass gate**: score >= 180 / 200 AND all critical categories (Org connection, Metadata, Data, Permissions, E2E simulation) at full marks **AND step count is within the duration tier band approved in Phase 3** (e.g. a 15-min demo with 14 steps fails this gate — re-author or re-confirm duration). Record pass.
- **Partial fail**: score 120-179, non-critical category gap, or step count outside the tier band -> let `sf-demo-validate` run its repair loop or send back to `sf-demo-author` to trim/expand to fit the duration; re-run once after repair.
- **Hard fail**: score < 120 after 3 repair attempts, or a critical-category failure that cannot be auto-repaired -> halt and surface the failure diagnosis to the user.

Each attempt appends to `DEMO-PIPELINE-STATUS.md` -> **Phase 6 — Validation History** with timestamp, score, and failure summary.

### Phase 7 — Ready to present (HARD STOP)

**Delegation split** per `sf-subagent-orchestration`:
- Test suite + presenter guide authoring → `generalPurpose` subagent (returns artifact paths)
- `preflight.sh` execution → `shell` subagent (returns pass/fail counts only)
- Final user sign-off → **parent** (human-in-the-loop, never delegated)

Invoke `sf-demo-playwright` to emit:

- `demo-preflight.spec.js` — one test per demoscript step
- `PRESENTER-GUIDE.md` — quick-reference table + per-step screenshot and talking points
- `scripts/preflight.sh` — single-command pre-flight runner

Run `preflight.sh` once as the final green check. Record the result.

Then present the user with the **final sign-off panel**:

```
Demo pipeline complete.
  Org:              acme-demo
  Duration tier:    Short (15 min) — 7 steps, 2 visual moments
  Validation score: 196 / 200
  Pre-flight tests: 12 / 12 passing
  Artifacts:
    - demoscript.md
    - data/seed/*.json
    - demo-preflight.spec.js
    - PRESENTER-GUIDE.md
    - scripts/preflight.sh
  Next actions:
    1. Review PRESENTER-GUIDE.md before the session
    2. Run ./scripts/preflight.sh 30 min before go-time
    3. `git commit -am "demo: Acme discovery -> presenter-ready"` to version it
```

Wait for explicit "looks good / ship it" before closing the pipeline. Do not auto-commit; version control is always the user's call.

## DEMO-PIPELINE-STATUS.md format

Written to the workspace root and updated after every phase transition. Template:

```markdown
# Demo Pipeline Status

- **Target org:** acme-demo
- **Started:** 2026-04-17 12:51 PST
- **Current phase:** 6 — Validated & Repaired (attempt 2)
- **Overall:** IN_PROGRESS

## Phase 1 — Baseline              [COMPLETE]
- Packages: NPC, Experience Cloud (Arlington_Donor_Portal1)
- Person Accounts: enabled
- Agentforce: not provisioned

## Phase 2 — Notes Intake          [COMPLETE]
- Audience: VP Programs, IT Director, 2 Volunteer Coordinators
- Platform signals: NPC, volunteer portal, Agentforce (nice-to-have)
- Use case: volunteer self-service, shift sign-up, intake automation

## Phase 3 — Approved Products     [COMPLETE]
- [x] Nonprofit Cloud
- [x] Experience Cloud
- [x] Agentforce (provisioned during run)
- [ ] Data Cloud (rejected)

## Phase 3 — Demo Duration         [COMPLETE]
- Tier: Short (15 min)  -- step band 6-8, visual band 1-2, personas 1-2
- Source: explicit user input ("we have a 15 minute slot")

## Phase 4 — Demoscript            [COMPLETE]
- Artifact: demoscript.md
- demo_duration_minutes: 15  (7 steps, 2 visual -- within tier)
- sf-demo-author score: 142 / 150

## Phase 5 — Seed                  [COMPLETE]
- 12 volunteers, 5 programs, 24 shifts, 8 gifts
- Teardown: scripts/apex/teardown-acme-demo.apex

## Phase 6 — Validation            [IN_PROGRESS, attempt 2 of 3]
- Attempt 1: 158 / 200 (missing ProgramEngagement FLS, stale shift dates)
- Repairs delegated to sf-permissions, sf-nonprofit-demo-data
- Attempt 2: running...

## Phase 7 — Ready                 [PENDING]
```

## Mid-pipeline UI fallback (sf-ui-fallback-playwright)

Several Salesforce surfaces have **no reliable CLI path** as of Spring '26, so the pipeline occasionally hits dead-ends where `sf project deploy`, `sf agent`, `sf data360`, or metadata API commands cannot finish a workflow a demo requires. When that happens, the orchestrator delegates to **`sf-ui-fallback-playwright`** to drive the Setup UI headlessly via Playwright, then resumes the current phase. This is not a replacement for any phase — it is an inline repair tool that keeps the pipeline moving.

Known dead-ends where the orchestrator should pre-emptively include `sf-ui-fallback-playwright` in the phase plan (flagged in the Phase 2.5 UI-fallback note):

| Surface | Why CLI can't finish | What the fallback does |
|---|---|---|
| Agent Builder — publish / activate | Agent activation requires Setup UI toggle on most releases | Playwright: log in, open Agent Builder, click "Activate" / "Publish" |
| Prompt Builder — activate a template | Standalone Prompt Template activation is Setup-only for non-Flow templates | Playwright: open Prompt Builder, click "Activate" on the new version |
| Data Cloud — publish a segment | `sf data360` can build but not always publish; UI click required | Playwright: open Segment, click "Publish" and wait for status |
| Experience Cloud — publish a site | `sf community publish` works for many templates but not all LWR variants | Playwright: Experience Builder -> Publish |
| MCAE (Pardot) — form / landing-page builder | `pi__` builder UIs have no metadata path for drag-and-drop layout | Playwright: open builder, place components, save |
| Marketing Cloud Growth — journey activation | Some journey transitions require the canvas UI | Playwright: open Journey Builder, activate |
| Agent test execution | `sf agent test run` works but invoking the UI "Run Test Set" button is sometimes required to populate the Agent Analytics dashboard the demo shows | Playwright: click Run on the test set |
| OmniStudio — activate OmniScript | Core OmniScript activation is metadata; vlocity activation in some orgs still needs UI | Playwright: OmniStudio app -> activate |
| Flow Orchestration — activate an orchestration | UI-only activation on first deployment in some editions | Playwright: Setup -> Flow Orchestration -> Activate |

**Invocation pattern**: any phase (4, 5, 6, or 7) that hits a dead-end calls `sf-ui-fallback-playwright` with the minimum contract: URL / Setup path, target control selector or accessible name, success predicate (HTTP status, element visible, status text). The fallback runs, returns a pass/fail, and the original phase resumes. All fallback invocations are recorded in `DEMO-PIPELINE-STATUS.md` under **UI-Fallback History** so the presenter and the auditor can see exactly which controls were driven by Playwright.

Never let a dead-end halt the pipeline without at least one fallback attempt; only escalate to the user after `sf-ui-fallback-playwright` reports a hard failure (e.g., element not found, auth expired, control disabled due to missing license).

## Interaction with existing rules

- `org-discovery.mdc` (always-applied) — Mandates 1, 2, 3 are satisfied in-line by Phases 1, 3, and the delegated sub-skills. The orchestrator never bypasses them; it makes them visible in the status file.
- `nonprofit-auto-router.md` — when a user prompt matches *both* a single-phase skill and an end-to-end trigger, the router prefers this orchestrator. Single-phase triggers still route to single-phase skills.
- `industry-precheck.md` — Phase 2.5 hard-invokes this reference; every Phase 2.5 routing decision is auditable against the precheck's license/namespace/object scan.

## Anti-patterns

Do **not**:

- Re-implement authoring, seeding, or validation logic inside this skill — always delegate
- Skip the product-approval gate because "the notes look obvious"
- Auto-commit, auto-push, or mutate the git state; the pipeline ends at presenter-ready, not at "shipped"
- Proceed past a hard fail in Phase 6 by lowering the pass gate; escalate to the user instead
- Run phases in parallel — the artifacts from each phase are inputs to the next

## Failure playbook

| Failure | Orchestrator response |
|---|---|
| Phase 1: no org alias supplied | Ask user which org; do not guess |
| Phase 2: notes missing and no paste | Pause and request notes; do not fabricate |
| Phase 3: user rejects every recommended product | Ask whether to proceed with org-as-is or abort |
| Phase 3: user gives no duration | Default to Short (15 min) and tell the user; let them override before unlocking Phase 4 |
| Phase 3: user demands a duration that doesn't fit the product list (e.g. 5 min for 4 products) | Surface the conflict, recommend either trimming products or moving to a longer tier, and ask the user to pick |
| Phase 4: `sf-demo-author` produces < 100 / 150 | Surface the weak categories and ask whether to accept or re-run with tightened notes |
| Phase 4: step count is outside the duration tier band | Send back to `sf-demo-author` with the explicit target step range; do not advance to Phase 5 |
| Phase 5: seed script errors | Let `sf-nonprofit-demo-data` self-diagnose once; if still failing, halt |
| Phase 6: hard fail after 3 attempts | Halt, attach the validation report, ask user whether to accept partial pass or remediate manually |
| Phase 7: preflight.sh fails any test | Re-loop through Phase 6 once; if still failing, halt at pre-Phase 7 |

## Output contract

When the pipeline reaches Phase 7 sign-off, the workspace contains:

- `demoscript.md`
- `DEMO-PIPELINE-STATUS.md`
- `data/seed/` artifacts + teardown Apex
- `demo-preflight.spec.js`
- `PRESENTER-GUIDE.md`
- `scripts/preflight.sh`

Any successor agent opening the repo can read `DEMO-PIPELINE-STATUS.md` and know exactly what was approved, what was built, and what the last validation score was.
