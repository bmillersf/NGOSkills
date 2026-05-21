---
name: sf-skill-eval-harness
description: >
  Adversarial three-agent evaluation harness for any artifact-producing skill.
  Wraps a target skill's existing rubric with a planner / implementer / evaluator
  loop running in fresh subagent contexts, with structured handoffs in
  `.eval-harness/`, hard-fail floors, and append-only TRACE.md.
  TRIGGER when: another skill declares `eval_harness.enabled: true` in its
  SKILL.md frontmatter and produces an artifact (Apex class, LWC, demoscript,
  metadata XML, Flow, OmniScript, agent topic, etc.); user invokes
  `/run-eval-harness` directly with a target skill; sf-demo-orchestrate calls
  this skill from any of its 7 phases per the orchestrator wrap pattern.
  DO NOT TRIGGER when: target skill is pure retrieval / lookup (sf-docs, single
  SOQL queries) — no producer/evaluator gap; task is conversational with no
  artifact; gsd / superpowers / gstack commands run on their own contracts —
  this skill composes with them, never replaces. See section "Composition with
  gsd / superpowers / gstack" below.
license: MIT
metadata:
  version: "0.1.0"
  pilot: true
  scoring: "delegated to target skill's rubric (defaults: 4-dimension shape per SPEC §5.1)"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-21
upstream_refs:
  - url: "../../content/specs/skill-eval-harness-SPEC.md"
    importance: authoritative
---

# sf-skill-eval-harness — Adversarial Evaluation Harness for Any Skill

Production-grade adversarial evaluation. Three subagents in fresh contexts (planner / implementer / evaluator) loop against a target skill's rubric with hard-fail floors, structured handoffs, and append-only debugging traces.

This skill is the operational realization of `content/specs/skill-eval-harness-SPEC.md`. The Python primitives in `scripts/` provide deterministic math (schema validation, scoring, hard-fail enforcement, loop decisions, trace writing). This `SKILL.md` provides the *orchestration* — the LLM-driven control flow that spawns subagents and shepherds artifacts between them.

## When this skill fires

When *any* of these is true:

1. A target skill's SKILL.md frontmatter contains `eval_harness.enabled: true` and the target skill is producing an artifact
2. The user runs `/run-eval-harness <target-skill>` directly
3. `sf-demo-orchestrate` invokes this skill for one of its 7 phases per the orchestrator wrap pattern
4. Another skill explicitly says "wrap this with the eval harness" in its workflow

## Composition with gsd / superpowers / gstack

This skill **composes with**, never replaces, the three vendored packs:

| Pack | Owns | Harness relationship |
|---|---|---|
| **gsd** | Phase lifecycle (`.planning/`, spec→plan→execute) | Harness runs *inside* a gsd phase. `.eval-harness/` becomes a subdirectory of `.planning/<phase>/`. gsd-verifier remains authoritative for phase progression — its verdict is independent of the harness verdict. |
| **superpowers** | Engineering methodology (TDD, plan-writing, code review) | Harness *uses* superpowers — implementer subagent follows `test-driven-development`; planner role borrows `writing-plans`; evaluator uses `requesting-code-review` hygiene. Composition, not duplication. |
| **gstack** | Cognitive-mode specialists (founder taste, paranoid review, browser QA) | Different scope. gstack-review = paranoid pass on a diff after code lands. Harness evaluator = artifact-quality grade during production. Both run, sequenced. Neither preempts the other. |

**Hard non-overrides** (per SPEC §21.3): this skill MUST NOT modify `.planning/` files; MUST NOT skip or replace gsd-verifier; MUST NOT replace gstack-review or gstack-qa; MUST NOT auto-trigger superpowers skills (only delegate to them); MUST pause if user runs another command mid-loop and resume only when re-invoked.

## Three-agent architecture

```
planner ──► implementer ──► evaluator ──► (SHIP | ITERATE | SPEC-DEFECT)
                ▲                              │
                └──── EVAL-FEEDBACK ◄──────────┘
```

| Role | Subagent prompt | Key constraint |
|---|---|---|
| **Planner** | `prompts/planner.md` | Translates user request into `.eval-harness/SPEC.md` with falsifiable ACs. On re-plan, sees only `SPEC-DEFECT.md` — never the prior implementer's code. |
| **Implementer** | `prompts/implementer.md` | Executes the target skill's existing workflow. Sees the SPEC and (on iter ≥2) the prior `EVAL-FEEDBACK.md`. Does NOT see rubric weights or hard-fail floors. |
| **Evaluator** | `prompts/evaluator.md` | Fresh subagent context per iteration — never sees prior `EVAL-REPORT-*.md` files. Re-runs the target skill's rubric in read-only mode. Independently rebuilds coverage matrix and POV ratio (where applicable). |

Each role runs in **its own Task subagent** (fresh invocation). No role sees the others' working memory — only the structured handoff files in `.eval-harness/`.

## Workflow

### Phase 1 — Read the target skill's harness config

The target skill's SKILL.md frontmatter declares the harness config. Example from `sf-demo-validate`:

```yaml
eval_harness:
  enabled: true
  rubric_ref: "200-pt rubric in this SKILL.md (Scoring Rubric section)"
  hard_fail_dimensions: [Correctness, Robustness]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
```

Read this and bind `HarnessConfig` for the run.

### Phase 2 — Initialize `.eval-harness/`

Determine the harness directory based on invocation context:

| Context | `.eval-harness/` location |
|---|---|
| Inside `/gsd-execute-phase` | `.planning/<milestone>/<phase>/.eval-harness/` |
| Inside `sf-demo-orchestrate` | `.planning/demo-pipeline/<phase>/.eval-harness/` |
| Standalone target skill invocation | `.eval-harness/` at project root |
| Mid-pipeline side-quest, in-pipeline | inherits orchestrator location |
| Mid-pipeline side-quest, out-of-pipeline | `.eval-harness-side-quests/<timestamp>/` |

Copy `schemas/*.schema.json` into `.eval-harness/schemas/` so contract validation can run from the working directory.

### Phase 3 — Spawn planner subagent

Use the Task tool with the planner prompt:

```
Task(
  description="Eval harness planner",
  subagent_type="general-purpose",
  prompt=<contents of prompts/planner.md>
        + "\n\n## Inputs\n- User request: ...\n- Existing contracts: ..."
        + "\n- Target skill: <target>\n- Working dir: .eval-harness/"
)
```

Done criterion: `.eval-harness/SPEC.md` exists with all sections populated. Validate via:

```bash
test -f .eval-harness/SPEC.md && echo OK
```

Append a TRACE.md row:

```bash
python3 scripts/cli.py trace-append \
  --trace-path .eval-harness/TRACE.md \
  --iteration $ITER --role planner --verdict SPEC-WRITTEN \
  --artifact-delta "SPEC.md +N lines" \
  --notes "..."
```

### Phase 4 — Spawn implementer subagent

Use the Task tool with the implementer prompt + the target skill's SKILL.md as context:

```
Task(
  description="Eval harness implementer",
  subagent_type="general-purpose",
  prompt=<contents of prompts/implementer.md>
        + "\n\n## Target skill\n<target skill SKILL.md contents>"
        + "\n\n## Inputs\n- SPEC: .eval-harness/SPEC.md"
        + "\n- (iter≥2) Feedback: .eval-harness/EVAL-FEEDBACK.md"
)
```

Done criterion: artifacts produced + `IMPL-NOTES.md` exists + contract files validate:

```bash
python3 scripts/cli.py validate-contracts --harness-dir .eval-harness --strict
```

Append TRACE.md row.

### Phase 5 — Spawn evaluator subagent (fresh context)

CRITICAL: this Task invocation MUST NOT include any `EVAL-REPORT-*.md` content from prior iterations. Fresh-context evaluation is the entire point.

```
Task(
  description="Eval harness evaluator (fresh)",
  subagent_type="general-purpose",
  prompt=<contents of prompts/evaluator.md>
        + "\n\n## Target skill rubric\n<rubric from target SKILL.md>"
        + "\n\n## Inputs (DO NOT read prior EVAL-REPORTs)\n"
        + "- SPEC: .eval-harness/SPEC.md\n"
        + "- IMPL-NOTES: .eval-harness/IMPL-NOTES.md\n"
        + "- Artifacts at their real destinations"
)
```

Done criterion: `EVAL-REPORT-{iter}.md` exists + verdict is one of SHIP / ITERATE / SPEC-DEFECT.

Compute machine verdict via:

```bash
python3 scripts/cli.py score < <evaluator-scores-as-json>
```

Append TRACE.md row.

### Phase 6 — Apply loop decision

```bash
python3 scripts/cli.py loop-decide < <state-and-result-as-json>
```

Branch:

- **SHIP** — done. Surface `EVAL-REPORT-{iter}.md` and TRACE.md to user.
- **ITERATE_IMPLEMENTER** — back to Phase 4, with `EVAL-FEEDBACK.md` as additional input.
- **REPLAN** — back to Phase 3, with `SPEC-DEFECT.md` as additional input. Increments `replans_used_in_loop`.
- **ESCALATE** — surface to user with full TRACE.md. Possible reasons:
  - Iteration cap reached without SHIP
  - Improvement-below-threshold (implementer is stuck)
  - Hard-fail dimension breached (per SPEC §6.3, never gets autonomous retries)
  - SPEC-DEFECT after replan budget exhausted

### Phase 7 — Persist state and surface

Save `HarnessState` to `.eval-harness/state.json`. Append final TRACE.md row. If `SHIP`, mark the run complete; if `ESCALATE`, write a clear summary of what happened and what input the user needs to provide to resume.

## Shared schemas

Six JSON Schema files in `schemas/` define cross-phase contracts (from SPEC §17 and §19). When the target skill is `sf-demo-orchestrate`, all six apply. For other skills, only the relevant subset applies (e.g., `sf-apex` doesn't need `value-moments.json`).

| Schema | Used by |
|---|---|
| `requirements.schema.json` | sf-demo-orchestrate Phase 2 |
| `value-moments.schema.json` | sf-demo-orchestrate Phase 3 |
| `requirement-coverage.schema.json` | sf-demo-orchestrate Phase 4 |
| `wow-moment-delivery.schema.json` | sf-demo-orchestrate Phase 4 |
| `data-requirements.schema.json` | sf-demo-orchestrate Phase 5 |
| `click-path.schema.json` | sf-demo-orchestrate Phases 4 + 7 |

Other artifact-producing skills MAY define their own contracts in their own `schemas/` directories. The harness loads schemas from the target skill's directory first, falling back to the harness's shared schemas if the target doesn't override.

## Default rubric shape (SPEC §5.1)

When a target skill doesn't supply its own dimensions, the harness uses 4 dimensions × 25 points:

| Dimension | Hard-fail floor |
|---|---|
| Correctness | 15 |
| Robustness | 12 |
| Fit | 10 |
| Performance | 12 |

Plus the binary test rubric (unit + integration + smoke/e2e — all required for SHIP, no partial credit).

Skills MAY substitute domain-specific dimensions but MUST keep the 4-dimension + hard-fail shape.

## Loop control

- `max_iterations` (default 3) — hard iteration cap
- `improvement_threshold_points` (default 5) — if iteration N+1 doesn't improve quality total by this much, the loop escalates ("implementer is stuck")
- `per_loop_replan_budget` (default 1) — max planner re-invocations per loop
- `quality_pct_floor` (default 80) — minimum quality percentage for SHIP

When invoked inside `sf-demo-orchestrate`, the orchestrator additionally tracks a global re-plan budget (default 3 across all phases of one orchestrator run).

## Anti-patterns

- **Evaluator reading prior EVAL-REPORTs.** Sunk-cost leniency drift is exactly what fresh-context prevents — never re-introduce.
- **Implementer seeing rubric weights or hard-fail floors.** Implementer fits to ACs; evaluator owns the rubric. Don't leak weights into prompts.
- **Marking PARTIAL coverage as COVERED.** The hard-fail floors exist to block partial-credit gaming.
- **Suggesting fixes in EVAL-FEEDBACK.** Evaluator describes gaps; implementer chooses fixes. Prescriptions in feedback are how the same fix mistake propagates across iterations.
- **Crediting documentation as evidence of validation.** The artifact must work, not look like it would.
- **Modifying `.planning/` files.** gsd-owned. Read-only across that boundary.
- **Auto-pushing learnings.** This skill never `git push`. User initiates pushes manually.

## Tests + sample run

- `tests/` — 49 pytest tests covering schema validation, rubric scoring, trace, loop control, evaluator independence, integration. Run via:
  ```bash
  cd skills-cursor/sf-skill-eval-harness && \
    python3 -m venv .venv && .venv/bin/pip install jsonschema pytest && \
    .venv/bin/python -m pytest tests/
  ```
- `SAMPLE-RUN.md` — deterministic 2-iteration walkthrough proving the harness machinery works end-to-end before any LLM-driven run
- `fixtures/simple-volunteer-demo/` — Helping Hands NGO 30-min volunteer demo with all 6 contract files populated

## Pilot status (per SPEC §8)

This skill is in **Stage 1 pilot** (per SPEC §14 roadmap). Currently wired into `sf-demo-validate`. After 3-5 real demo prep cycles, evaluate against:

1. Did adversarial evaluator find ≥1 gap that self-eval rated as passing?
2. Did the loop converge in ≤3 iterations on average?
3. Did TRACE.md make a real debugging session faster?
4. Did the user prefer harness output over current output?

≥3 yes → roll out to remaining `sf-demo-orchestrate` phases (SPEC §14 Stage 3) and tier-1 opt-in skills (SPEC §20.4).
<3 yes → revert and document why in skill-learning anti-patterns.

## Disabling

A target skill disables the harness by setting `eval_harness.enabled: false` in its frontmatter (or omitting the `eval_harness` block entirely). The skill runs as it did before, no harness wrap. The harness skill itself remains installed — no rot, since its tests keep it honest — but no subagents are spawned.
