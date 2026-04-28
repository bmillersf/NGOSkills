---
name: sf-demo-orchestrate
description: >
  End-to-end demo pipeline orchestrator. From a single trigger phrase and a
  batch of discovery notes, runs the full 7-step workflow by delegating to the
  existing demo-lifecycle skills in order: org connect + baseline, notes
  intake, product recommendation approval, demoscript generation
  (sf-demo-author), data seeding (sf-nonprofit-demo-data), validation + repair
  loop (sf-demo-validate), and Playwright pre-flight + presenter guide
  (sf-demo-playwright). Emits a single DEMO-PIPELINE-STATUS.md that tracks
  every phase, score, and artifact. TRIGGER when: user says "run the full demo
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
    - sf-demo-validate
    - sf-demo-playwright
    - sf-subagent-orchestration
---

# sf-demo-orchestrate: End-to-End Demo Pipeline

One trigger phrase -> a presenter-ready demo. This skill does **not** re-implement authoring, seeding, or validation; it composes the existing demo-lifecycle skills into the 7-step pipeline illustrated in the project README and enforces the gates that keep a human in the loop.

```
┌─ 1. Connect to Org ───────────────────────────────┐
│   sf org display + baseline scan                   │
├─ 2. Provide Discovery Notes ──────────────────────┤
│   Intake raw notes, transcripts, or bullet lists   │
├─ 3. Approve Product Recommendations (GATE) ───────┤
│   Plan mode — user must approve each product       │
├─ 4. Demo Script Generated ────────────────────────┤
│   Delegate -> sf-demo-author                       │
├─ 5. Data Seeded ──────────────────────────────────┤
│   Delegate -> sf-nonprofit-demo-data               │
├─ 6. Validated & Repaired ─────────────────────────┤
│   Delegate -> sf-demo-validate (up to 3× loop)     │
├─ 7. Ready to Present (GATE) ──────────────────────┤
│   Delegate -> sf-demo-playwright + sign-off        │
└────────────────────────────────────────────────────┘
```

## When to apply

Apply this skill when the user asks for the **whole pipeline in one go** — phrases like:

- "Run the full demo workflow for BTH"
- "Build me an end-to-end demo from these notes"
- "Take me from discovery to presenter-ready"
- "Orchestrate the demo for my bth-demo org"
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

### Phase 5 — Delegate to sf-nonprofit-demo-data

**Delegation**: `generalPurpose` subagent per `sf-subagent-orchestration` for record generation (Apex / JSON tree authoring), then a `shell` subagent for the actual `sf data` import + Anonymous Apex execution. Verbose import logs stay in the shell subagent's context; parent receives a row-count summary plus paths to the seed and teardown scripts.

Hand the persona cards and data seed requirements to `sf-nonprofit-demo-data`. Let it run platform detection (NPC vs NPSP), persona-to-record mapping, generation (JSON tree / Apex / `sf data`), freshness rules, and teardown script generation.

Expected artifacts:
- `data/seed/*.json` (tree files) or `scripts/apex/seed-*.apex`
- `scripts/apex/teardown-*.apex` targeting `@demo.` email domains

Verify seeding by running the skill's own smoke check, then record in **Phase 5 — Seed Results**.

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
  Org:              bth-demo
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
    3. `git commit -am "demo: BTH discovery -> presenter-ready"` to version it
```

Wait for explicit "looks good / ship it" before closing the pipeline. Do not auto-commit; version control is always the user's call.

## DEMO-PIPELINE-STATUS.md format

Written to the workspace root and updated after every phase transition. Template:

```markdown
# Demo Pipeline Status

- **Target org:** bth-demo
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
- Teardown: scripts/apex/teardown-bth-demo.apex

## Phase 6 — Validation            [IN_PROGRESS, attempt 2 of 3]
- Attempt 1: 158 / 200 (missing ProgramEngagement FLS, stale shift dates)
- Repairs delegated to sf-permissions, sf-nonprofit-demo-data
- Attempt 2: running...

## Phase 7 — Ready                 [PENDING]
```

## Interaction with existing rules

- `org-discovery.mdc` (always-applied) — Mandates 1, 2, 3 are satisfied in-line by Phases 1, 3, and the delegated sub-skills. The orchestrator never bypasses them; it makes them visible in the status file.
- `nonprofit-auto-router.md` — when a user prompt matches *both* a single-phase skill and an end-to-end trigger, the router prefers this orchestrator. Single-phase triggers still route to single-phase skills.

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
