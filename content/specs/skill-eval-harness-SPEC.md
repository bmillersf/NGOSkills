# SPEC: Adversarial Skill Eval Harness (Pilot in sf-demo-validate)

**Status:** Draft v5 — Phase 3 → 4 depth & user-value contract (the shallow-demo fix)
**Author:** Brian Miller (drafted with Claude)
**Date:** 2026-05-21
**Pilot target:** `sf-demo-validate` (Phase 6 of `sf-demo-orchestrate`) — lowest-risk wrap because rubric already exists
**Stage 2 target:** Extract reusable harness into `skills-cursor/sf-skill-eval-harness/`, then wrap **all 7 phases** of `sf-demo-orchestrate`
**Stage 3 target:** Opt-in extension to other artifact-producing skills via `eval_harness: enabled` SKILL.md frontmatter (`sf-apex`, `sf-lwc`, `sf-nonprofit-experience-cloud-build`, etc.)
**End-state goal:** Every artifact-producing skill in the stack runs adversarial eval. `sf-demo-orchestrate` runs end-to-end autonomously with per-phase adversarial verdicts.

---

## 1. Problem statement

Today, most `sf-*` skills follow a builder-grades-own-work pattern: the same agent that produces the artifact (demoscript, persona doc, Apex class, validation report) also scores it against the skill's rubric. This violates principle #1 (self-evaluation is a trap) — the producer has every incentive to score itself favorably, and rubrics applied in the same context as production drift toward post-hoc rationalization.

The five guiding principles for this work:

1. Self-evaluation is a trap. Use an adversarial evaluator.
2. Compaction doesn't cure coherence drift. Structured handoffs do.
3. Make subjective quality gradable with rubrics the model can apply.
4. Read the traces. They're your primary debugging loop.
5. Delete scaffolding when the model catches up. The frontier moves.

This SPEC defines a **three-agent closed-loop pattern** (Planner → Implementer → Evaluator, with feedback) that operationalizes all five.

---

## 2. Goals & non-goals

### Goals

- Produce production-grade artifacts from skills that today produce "good enough" output.
- Catch regressions and quality drops that self-evaluation misses.
- Generate durable traces that survive context compaction and serve as the primary debugging loop.
- Establish a kill-switch criterion so we delete the harness if the frontier moves past needing it.

### Non-goals

- **Not** a generic agentic framework. Three roles, one loop, one rubric pair. Resist scope creep.
- **Not** a replacement for `gsd-*` phase orchestration. This runs *inside* a single skill invocation.
- **Not** for skills that don't ship artifacts (e.g. `sf-docs` — pure retrieval has no producer/evaluator gap).
- **Not** for one-shot trivial tasks. Loop overhead must be earned by artifact complexity.

---

## 3. Architecture

### Three roles, three subagent contexts

```
┌────────────┐    spec.md     ┌──────────────┐    artifact    ┌────────────┐
│  PLANNER   │ ─────────────► │ IMPLEMENTER  │ ─────────────► │ EVALUATOR  │
│            │                │              │                │            │
│ writes     │                │ produces     │                │ grades vs  │
│ SPEC + ACs │                │ artifact +   │                │ rubric in  │
│ + rubric   │                │ tests        │                │ fresh ctx  │
└────────────┘                └──────────────┘                └─────┬──────┘
       ▲                              ▲                              │
       │                              │                              │
       │      route: spec defect      │     feedback (gaps only,     │
       └──────────────────────────────┴─────  not rubric weights)  ◄─┘
                              loop until ship/no-ship verdict
```

Each role runs in **its own subagent context** (fresh Task invocation). No role sees the others' working memory — only the structured handoff files.

### Why three, not two

Two-agent (implementer + evaluator) is the minimum viable adversarial pattern. The planner adds value when:

- Specs are non-trivial and benefit from being written-once, referenced-many
- Spec defects are real (evaluator finds an issue but the fix is upstream of the implementer)
- The artifact will be regenerated multiple times against the same spec

For pilot, we use all three. If post-pilot data shows the planner is rubber-stamping in >80% of runs, collapse to two roles.

---

## 4. Subagent contracts

Each subagent receives a single prompt with: **goal**, **inputs (paths)**, **constraints**, **return format**, **done criteria**. (This is the standard subagent contract from the user's CLAUDE.md.)

### 4.1 Planner

**Goal:** Translate the user's request into a SPEC.md the implementer can build against and the evaluator can grade against.

**Inputs:**
- User request (verbatim)
- Skill's domain rubric (from skill SKILL.md)
- Existing codebase context (read-only)
- Prior SPEC.md if this is a re-plan after a spec-defect routing

**Outputs (writes to `.eval-harness/SPEC.md`):**
- Goal statement (one sentence)
- Acceptance criteria (numbered, falsifiable)
- Out-of-scope list (what the implementer must NOT do)
- Test plan: unit tests, integration tests, smoke/e2e — each as a list of named cases
- Rubric weights for this run (see §5)

**Constraints:**
- ACs must be falsifiable. "Code is well-organized" is not an AC; "No function exceeds 40 lines" is.
- Test plan must specify *what* tests to write, not *how* to implement them.
- Planner does NOT see the prior implementer's code on a re-plan — only the evaluator's spec-defect report.

**Done criteria:** SPEC.md exists, all sections populated, ACs are falsifiable.

### 4.2 Implementer

**Goal:** Produce the artifact + tests that satisfy SPEC.md.

**Inputs:**
- `.eval-harness/SPEC.md`
- `.eval-harness/EVAL-FEEDBACK.md` (only on iteration ≥2, contains failing dimensions and *why*, NOT rubric weights)
- Codebase (read + write)

**Outputs:**
- The artifact itself (code, demoscript, metadata, etc., at its real destination)
- Tests at the real destination
- `.eval-harness/IMPL-NOTES.md`: one paragraph on what was built, what was deferred, any spec ambiguities encountered

**Constraints:**
- Implementer does NOT see the rubric weights or scoring formula. Only the AC list and the prior evaluator's feedback (if any).
- Must write tests before or alongside the artifact (TDD per superpowers `test-driven-development` skill).
- If the implementer believes the spec is wrong, it writes that to IMPL-NOTES.md instead of working around it. The evaluator decides whether to route back to the planner.

**Done criteria:** Artifact + tests exist, tests pass locally, IMPL-NOTES.md written.

### 4.3 Evaluator

**Goal:** Grade the artifact against the rubric in fresh context. No memory of prior iterations.

**Inputs:**
- `.eval-harness/SPEC.md`
- The artifact + tests (read from real destinations)
- `.eval-harness/IMPL-NOTES.md`
- The rubric definition (from skill SKILL.md)

**Outputs (writes to `.eval-harness/EVAL-REPORT-{iter}.md`):**
- Score per quality dimension (with evidence quoted from artifact)
- Test rubric pass/fail (binary per category)
- Hard-fail check (any dimension below threshold → ship-blocked regardless of total)
- Verdict: `SHIP` | `ITERATE` | `SPEC-DEFECT`
- If `ITERATE`: write `.eval-harness/EVAL-FEEDBACK.md` with failing dimensions + why (no weights, no fix prescriptions — just the gap)
- If `SPEC-DEFECT`: write `.eval-harness/SPEC-DEFECT.md` with what's wrong upstream

**Constraints:**
- Fresh subagent per iteration. Evaluator MUST NOT see prior EVAL-REPORTs (prevents sunk-cost leniency drift).
- Must quote evidence from the artifact for every score. "7/10" without a quote is invalid.
- Must run tests, not just inspect them. Test rubric scores from actual execution.

**Done criteria:** EVAL-REPORT-{iter}.md written with all dimensions scored + evidence + verdict.

### 4.4 Optional fourth role: Adversarial test generator

For high-stakes skills (security, compliance, demo-validate), spawn a fourth subagent that writes *additional* tests trying to break the implementation. Runs in parallel with Evaluator. Failing adversarial tests count toward the test rubric and can flip a `SHIP` to `ITERATE`.

Not in pilot. Add if pilot data shows the implementer's self-written tests are too easy on themselves.

---

## 5. Rubric structure

Two rubrics, scored independently. Both must pass for `SHIP`.

### 5.1 Quality rubric (0-100, weighted)

Four dimensions, 0-25 each. Skills MAY substitute domain-specific dimensions but must keep the four-dimension shape and the hard-fail concept.

| Dimension | What it grades | Default hard-fail floor |
|---|---|---|
| **Correctness** | Does it satisfy the SPEC's acceptance criteria? Does it do what it claims? | 15 |
| **Robustness** | Edge cases, error paths, failure modes. Does it survive bad input? | 12 |
| **Fit** | Matches existing patterns in the codebase / skill conventions / org norms. | 10 |
| **Performance** | Governor limits, query efficiency, bulk-safety, no N+1. | 12 |

**Hard-fail rule:** Any dimension below its floor → verdict is `ITERATE` regardless of total score. A 92/100 with Correctness at 14 does not ship.

**On rubric gaming:** Implementer never sees the dimension weights or floor values. Only sees the AC list (which is correctness-equivalent) and the evaluator's prose feedback. Prevents fitting-to-rubric across iterations.

### 5.2 Test rubric (binary, all required)

| Category | Required for SHIP |
|---|---|
| Unit tests exist + pass | Yes — every artifact |
| Integration tests exist + pass | Yes — every artifact |
| Smoke / e2e covers the golden path | Yes — every artifact |

All three required for every artifact, no exceptions. Production-grade means production-grade. Skills that produce artifacts where one of these categories doesn't translate cleanly (e.g. a static demoscript markdown file) MUST define what each category means in their context — for a demoscript, integration test = "every CLI command in the script executes against a real org without error"; smoke test = "the full click-path runs end-to-end in Playwright."

No partial credit. Tests pass or they don't. Coverage percentage is irrelevant — what matters is whether the named test cases from SPEC.md's test plan are implemented and green.

### 5.3 Per-skill customization

Skills declare in their SKILL.md:

```yaml
eval_harness:
  quality_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 15
      description: "..."
    # ... 3 more
  test_rubric:
    - unit_tests: required
    - integration_tests: required
    - smoke_e2e: required
  hard_fail_dimensions: [Correctness, Robustness]  # which dims have hard-fail floors
  max_iterations: 3
  improvement_threshold: 5  # if iter N+1 doesn't beat iter N by 5pts, stop
```

---

## 6. Loop control

### Termination conditions (any one ends the loop)

1. **SHIP:** Quality rubric ≥80, all hard-fail floors met, all test rubric required = pass.
2. **NO-SHIP (iteration cap):** `max_iterations` reached without SHIP. Escalate per §6.3.
3. **NO-SHIP (no improvement):** Iteration N+1 scores within `improvement_threshold` of iteration N. Stop — implementer is stuck. Escalate per §6.3.
4. **NO-SHIP (spec defect):** Evaluator returns `SPEC-DEFECT` verdict. Route to planner for re-plan if budget remains, else escalate per §6.3.
5. **User abort:** User halts the loop manually.

### 6.1 Iteration cap

Default `max_iterations = 3` per loop. Empirically: iteration 1 establishes the baseline, iteration 2 fixes the obvious gaps, iteration 3 polishes. Beyond 3, returns diminish and you're usually fitting-to-rubric.

### 6.2 Re-plan budget — autonomous-run-aware

The harness is designed to run inside long-running autonomous orchestrators (notably `sf-demo-orchestrate`). Per-loop re-plan limits are too tight for autonomous runs across N phases. Two-tier budget:

- **Per-loop:** Maximum 1 re-plan per harness invocation. If a second SPEC-DEFECT fires within the same loop, escalate.
- **Per-orchestrator-run (global):** Maximum 3 re-plans across all phases of a single orchestrator run. Tracked in the orchestrator's status file (e.g., `DEMO-PIPELINE-STATUS.md`).

When invoked standalone (not from an orchestrator), the harness uses only the per-loop limit; global budget is N/A.

### 6.3 Escalation rules — what surfaces to the user vs what stays autonomous

The point of long-running autonomy is to keep going on quality drift but stop hard on real defects. Three-tier escalation:

| Trigger | Stays autonomous (orchestrator continues) | Escalates to user immediately |
|---|---|---|
| Quality score below 80, no hard-fail breach | Yes — re-plan or iterate | No |
| Iteration cap reached, no hard-fail breach, global re-plan budget remains | Yes — consume one global re-plan, restart loop | No |
| Iteration cap reached, no hard-fail breach, global budget depleted | No | Yes — surface latest EVAL-REPORT + TRACE |
| **Hard-fail floor breached on any dimension** | **No** | **Yes — immediately, regardless of budget** |
| SPEC-DEFECT after re-plan already used in this loop | No | Yes — issue is upstream of the harness |
| Test rubric: any required category failing after iteration cap | No | Yes — broken tests don't get autonomous waivers |

**Hard-fail dimensions never get silent retries.** Security, data integrity, demo-script-vs-org-state alignment, and similar critical dimensions wake the user up the first time they breach. The orchestrator does not absorb them.

---

## 7. Handoff file schema

All handoff files live in `.eval-harness/` at the project root (or the skill's working directory). Files are durable across context compaction — this is principle #2.

```
.eval-harness/
├── SPEC.md                    # Planner output (overwritten on re-plan)
├── IMPL-NOTES.md              # Implementer notes for current iteration
├── EVAL-REPORT-1.md           # Evaluator report, iteration 1
├── EVAL-REPORT-2.md           # ...
├── EVAL-REPORT-3.md           # ...
├── EVAL-FEEDBACK.md           # Latest feedback for implementer (gaps only)
├── SPEC-DEFECT.md             # Present only if evaluator routes back to planner
└── TRACE.md                   # Append-only loop trace (principle #4)
```

### TRACE.md format (one row per subagent invocation)

```
| timestamp | iter | role | verdict | quality | hard-fail | tests | artifact-delta | notes |
|---|---|---|---|---|---|---|---|---|
| 2026-05-21T14:02 | 1 | planner | SPEC-WRITTEN | — | — | — | spec.md +120 lines | first plan |
| 2026-05-21T14:08 | 1 | implementer | DONE | — | — | — | demoscript.md +340 lines, 4 tests | TDD followed |
| 2026-05-21T14:11 | 1 | evaluator | ITERATE | 67 | Robustness 8 (floor 12) | unit:pass, e2e:fail | — | edge cases missing on Account merge step |
| 2026-05-21T14:15 | 2 | implementer | DONE | — | — | — | demoscript.md +45 lines, 2 tests | added merge edge cases |
| 2026-05-21T14:18 | 2 | evaluator | SHIP | 88 | all met | all pass | — | done |
```

This trace is **the** debugging loop. When a user asks "why did this skill take 3 iterations?", you read TRACE.md, not the conversation transcript.

---

## 8. Pilot scope: `sf-demo-validate`

### Why this skill

1. Already has a 200-pt rubric — we change *who grades it*, not the rubric itself
2. Already has self-repair logic — natural fit for the loop
3. Already writes status files (`DEMO-PIPELINE-STATUS.md`) — handoff pattern is familiar
4. High visibility — failures show up in real demo prep cycles

### What changes

**Before:** Single agent runs `sf-demo-validate`, scores itself 180/200, self-repairs gaps, declares ready.

**After:**
- Planner subagent reads the demo's milestone artifacts and writes `.eval-harness/SPEC.md` with the demo's acceptance criteria and a test plan
- Implementer subagent runs the existing validation + repair logic (the bulk of `sf-demo-validate`'s SKILL.md is reused as-is)
- Evaluator subagent runs the 200-pt rubric in fresh context, with hard-fail floors on critical dimensions (data integrity, security, demo-script-vs-org-state alignment)
- Loop until SHIP or 3 iterations
- Final TRACE.md replaces the current ad-hoc status output

### What stays unchanged

The 200-point rubric itself. The self-repair playbooks. The CLI commands. The escalation chain to `/gsd-debug` and `/gstack-investigate`. We are not rewriting the skill — we are wrapping it in the harness.

### Pilot success metric

After 3-5 real demo prep cycles, compare:

| Question | If yes → keep harness | If no → kill harness (principle #5) |
|---|---|---|
| Did adversarial evaluator find ≥1 gap that self-eval rated as passing? | yes (≥1 cycle) | 0 across all cycles |
| Did the loop converge in ≤3 iterations on average? | ≤3 | >3 means we're fitting |
| Did TRACE.md make a real debugging session faster? | yes (cite the case) | no |
| Did the user (Brian) prefer harness output over current output? | yes | no |

Three out of four "yes" → extract to `skills-cursor/sf-skill-eval-harness/` and roll out to `sf-ai-agentforce-persona` and `sf-ai-agentforce-testing` next. Below three → revert and document why in skill-learning anti-patterns.

---

## 9. Mapping to existing primitives

The pattern is mostly composition of agents that already exist in `~/.claude/agents/`:

| Harness role | Existing primitive | Notes |
|---|---|---|
| Planner | `gsd-planner` | Already writes structured plans; needs minor adapter for the rubric-weights output |
| Implementer | `gsd-executor` + superpowers `test-driven-development` | Existing combo; add the IMPL-NOTES.md output |
| Evaluator (quality) | `gsd-code-reviewer` | Already runs in fresh context with adversarial stance; extend to write EVAL-REPORT format |
| Evaluator (eval coverage) | `gsd-eval-auditor` | Already does this for AI-SPEC.md phases — borrow its dimension scoring pattern |
| Goal verification | `gsd-verifier` | Goal-backward check, runs after SHIP verdict for sanity |
| Trace reading | New: simple TRACE.md format | Lightweight; no new agent |

**Implication:** The pilot is mostly orchestration glue + the SPEC/IMPL-NOTES/EVAL-REPORT/TRACE file conventions. The hard parts (fresh-context evaluation, adversarial stance, rubric-driven scoring) are already implemented in the gsd agents.

---

## 10. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Loop runs forever | Hard cap `max_iterations`; improvement-threshold early-stop; user-abort always available |
| Evaluator and implementer both run the same model and converge to the same blind spots | For pilot, accept the risk and measure. If blind-spot convergence is observed, mitigate later by (a) using a different model for the evaluator subagent, or (b) adding the adversarial test generator (§4.4) |
| Rubric weights leak to implementer through prose feedback | Evaluator's EVAL-FEEDBACK.md is constrained to "what's wrong" not "why points were deducted." Spot-check by reading 2-3 feedback files manually after pilot |
| Trace files clutter the repo | `.eval-harness/` is gitignored by default. User opts in to commit when they want history |
| Harness becomes scaffolding the frontier passes (principle #5) | The pilot success metric explicitly tests this. Quarterly `/skills-frontier-review` (separate proposal) revisits |
| User context overhead from reading SPEC + EVAL-REPORTs in main thread | Subagents return one-line summaries to parent. Parent reads files only on user request or when the loop terminates |

---

## 11. Out of this SPEC (deferred decisions)

- **Trace visualization.** TRACE.md is markdown for v1. A renderer / dashboard is out of scope.
- **Multi-skill harness composition.** What happens when skill A invokes skill B inside an eval loop? Defer until a real case forces the question.
- **Cross-session loop resumption.** If the user closes the laptop mid-iteration, can we resume? V1 says no — re-run from iteration 1. Revisit if it becomes painful.
- **Rubric versioning.** When a skill's rubric changes, do old TRACE.md files need migration? Defer.
- **The fourth role (adversarial test generator).** Not in pilot. Add only if pilot evaluator is demonstrably too lenient on tests.
- **Production trace export.** Sending traces to Langfuse / Braintrust / Phoenix for long-term analysis. Out of scope for pilot.

---

## 12. Acceptance criteria for this SPEC

This SPEC is ready for implementation when:

- [ ] User has read §3 (architecture) and §4 (subagent contracts) and confirms the three-role split matches their intent
- [ ] User has reviewed §5 (rubric structure) and confirmed Correctness/Robustness/Fit/Performance dimensions match what they meant by "uniqueness/style/performance/usage" — or substituted their preferred four
- [ ] User has confirmed `sf-demo-validate` is the right pilot (vs `sf-ai-agentforce-persona` or `sf-ai-agentforce-testing`)
- [ ] User has confirmed pilot success metrics in §8
- [ ] User has confirmed risks and mitigations in §10 are acceptable

After acceptance, implementation work is ~1-2 days:
1. Write the orchestrator skill `sf-skill-eval-harness` (skills-cursor/) — half day
2. Wire `sf-demo-validate` to invoke it — half day
3. Run 3-5 real demo prep cycles, capture data — depends on cadence
4. Decide keep / extract / kill based on §8 metrics

---

## 13. Resolved decisions (2026-05-21)

1. **Dimensions:** Confirmed — `Fit` replaces "Uniqueness" (pattern adherence / non-duplication).
2. **Test rubric scope:** Tightened — unit + integration + smoke/e2e required for **every** artifact. Skills must define what each test category means for their artifact type (see §5.2).
3. **Re-plan budget:** Two-tier — 1 per loop, 3 global per orchestrator run, tracked in orchestrator status file (see §6.2). Hard-fail dimensions always escalate to user, regardless of budget (§6.3).
4. **Pilot vs harness-first:** Pilot-first confirmed — build inside `sf-demo-validate`, extract to `skills-cursor/sf-skill-eval-harness/` after pilot succeeds, then wrap remaining `sf-demo-orchestrate` phases.

## 14. Implementation roadmap (post-acceptance)

End-state: every artifact-producing skill in the stack can run adversarial eval. `sf-demo-orchestrate` runs autonomously with per-phase verdicts. Roadmap to get there:

| Stage | Work | Decision gate |
|---|---|---|
| **1. Pilot** | Build three-agent loop inside `sf-demo-validate` (Phase 6 of orchestrator). Reuse existing 200-pt rubric. Add `.eval-harness/` artifacts and TRACE.md. | After 3-5 real demo prep cycles, evaluate against §8 success metrics. Keep / extract / kill. |
| **2. Extract** | Pilot passes → extract reusable orchestration glue + handoff schema into `skills-cursor/sf-skill-eval-harness/`. Refactor `sf-demo-validate` to consume it. | Drift check via `sync-skills.sh --check`. Manual review of extracted abstractions for over-generalization (principle #5 check — anything not battle-tested in pilot stays out). |
| **3. Wrap all orchestrator phases** | Apply harness to **all 7 phases** of `sf-demo-orchestrate` (org connect, notes intake, product recs, demoscript, data seeding, validate, Playwright). Each phase gets a per-phase rubric per §16. Phases run in parallel where independent. | Each phase has its own §8-style success metric. A phase wrap that doesn't catch ≥1 real defect in 3 cycles gets killed for that phase. |
| **4. Orchestrator integration** | Update `sf-demo-orchestrate` to: (a) track global re-plan budget across phases, (b) aggregate phase TRACE.md into `DEMO-PIPELINE-STATUS.md`, (c) honor §6.3 escalation rules, (d) propagate hard-fail breaches up the orchestrator chain. | Final acceptance: a full `/sf-demo-orchestrate` run from notes to presenter-ready completes autonomously on a clean test org with all 7 per-phase verdicts captured. |
| **5. Opt-in extension to other skills** | Add `eval_harness: enabled` SKILL.md frontmatter convention. Skills opt in by declaring their per-skill rubric (§5.3). Roll out to high-value artifact-producing skills first: `sf-apex`, `sf-lwc`, `sf-nonprofit-experience-cloud-build`, `sf-ai-agentforce-persona`. | One skill at a time. Same §8 success metric per skill. **Do not retrofit all 60+ skills automatically** — opt-in only, as each skill's rubric matures. |

**Stop conditions at any stage:**
- Frontier model update makes the harness redundant (principle #5) — measure self-eval vs adversarial-eval gap; if gap closes, kill the harness
- Pilot data shows blind-spot convergence between implementer and evaluator (same model, same blind spots) — mitigate via different model for evaluator, or kill if mitigation fails
- Stage 3 catches no defects across 3 demo cycles for a given phase — kill the harness wrap for that phase, leave others in place

## 15. Open questions for the user

None at this time — proceed to implementation when ready.

---

## 16. Per-phase rubrics for `sf-demo-orchestrate` (Stage 3)

Each phase needs its own four-dimension quality rubric. The default `Correctness / Robustness / Fit / Performance` shape from §5.1 is generic; phases substitute domain-specific dimensions but keep the four-dimension + hard-fail shape.

### Phase 1: Org connect + baseline

**Artifact:** Connected org metadata + baseline org snapshot.

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Correctness** | Right org targeted, auth valid, alias matches user intent | 15 |
| **Completeness** | Baseline captures all relevant orgs (sandbox + prod) and current feature flags | 12 |
| **Drift detection** | Identifies stale auth, expired sessions, deprecated CLI versions | 10 |
| **Safety** | Confirms no destructive ops queued; flags prod connections explicitly | 12 (hard-fail floor matters most here) |

**Tests:** unit (alias resolution), integration (sf org list passes), smoke (sample query against the connected org returns expected schema).

### Phase 2: Notes intake

**Artifact:** Structured discovery digest from raw notes.

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Correctness** | Captures all distinct asks from the notes (nothing dropped) | 15 |
| **Faithfulness** | No hallucinated requirements not in source notes | 12 (hard-fail) |
| **Coherence** | Conflicts in source notes surfaced, not silently resolved | 10 |
| **Persona fidelity** | Personas referenced match what the notes actually say about audience | 10 |

**Tests:** unit (parse notes file), integration (digest references notes by line/quote), smoke (digest re-read produces same routing decision).

### Phase 3: Product detection + recommendation

**Artifact:** Recommended product set + cross-cloud routing decision + duration + `value-moments.json` (see §19) — the *depth and user-value spec* that bounds Phase 4.

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Routing accuracy** | Industry-first routing precedence applied; no generic skill chosen when industry-pack-owned | 12 (hard-fail) |
| **Demo depth specification** | Per `must_demo` requirement: min step count specified, persona pain quote captured, persona outcome stated, ≥1 wow moment identified | 15 (hard-fail — the shallow-demo killer) |
| **User-value framing** | Recommendations encode user *outcomes*, not product *features*; end-user POV ratio target ≥60%; admin/setup time capped at ≤20% of duration | 13 (hard-fail) |
| **Duration fit** | Aggregate min-step-counts across requirements ≤ duration budget; no overstuffing, no underutilization | 10 |

**Tests:** unit (routing rule eval + `value-moments.json` schema valid), integration (recommendation references skill SKILL.md TRIGGER clauses + every product maps to ≥1 requirement from Phase 2), smoke (depth budget across requirements is feasible inside duration budget).

**Critical evaluator check:** Evaluator reads each `value-moments.json` entry and asks: *"Would an end-user (not an admin) lean forward during this moment?"* If the wow moment is "the record was created" or "the field was populated," that's an admin moment, not a user moment. Hard-fail.

### Phase 4: Demoscript authoring

**Artifact:** `demoscript.md` with story arc + click path + personas + machine-readable `requirement-coverage.json` (§17) + `wow-moment-delivery.json` (§19).

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Requirement coverage & depth** | Every Phase 2 requirement is demonstrated AND each one meets the min step count from Phase 3's `value-moments.json`. No drops, no shallow coverage. | 18 (hard-fail) |
| **Wow-moment delivery** | Every wow moment from Phase 3 is delivered with: (a) preceding pain context beat, (b) explicit "watch this" cue for the presenter, (c) the moment itself, (d) a "this is what just happened" narration beat | 12 (hard-fail) |
| **End-user POV ratio** | Click-path steps tagged `pov: end_user` ≥ Phase 3 target (default 60%); steps tagged `pov: admin` ≤ Phase 3 cap (default 20%) | 12 (hard-fail) |
| **Click-path fidelity & data contract** | UI steps are real; `data-requirements.json` validates against schema | 13 (hard-fail) |

**Tests:** unit (markdown structure valid + all JSON contracts validate), integration (every CLI command in script executes against connected org + every requirement maps to ≥1 step at required depth + POV ratio computed and checked), smoke (full click-path runs end-to-end in Playwright headless + wow-moment beats render visibly distinct in the presenter guide).

**Critical evaluator checks:** Two independent reconstructions, both required:

1. **Coverage matrix** — Evaluator reads Phase 2 digest + Phase 4 script side-by-side, builds requirement → step matrix from scratch. Mismatch with `requirement-coverage.json` = `SPEC-DEFECT`.
2. **Depth & POV reconstruction** — Evaluator reads Phase 3 `value-moments.json` + Phase 4 click-path, independently counts steps per requirement and tags each step's POV (end_user / admin / mixed). Computes POV ratio from scratch. If implementer's claimed ratio diverges from evaluator's reconstruction by >5%, that's a `SPEC-DEFECT`.

The point of two independent reconstructions: implementer can't game one without breaking the other.

### Phase 5: Data seeding

**Artifact:** Seeded records in the connected org matching demoscript needs.

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Coverage** | Every record the demoscript references exists in the org | 18 (hard-fail) |
| **Layout completeness** | No demo screen looks half-empty — all writeable fields populated unless empty-by-design | 12 |
| **Relationship integrity** | Lookups, parent-child, junction objects all resolve | 12 (hard-fail) |
| **Realism** | Names, amounts, dates feel real, not "Test User 1" / "$100" | 8 |

**Tests:** unit (data tree JSON validates), integration (sf data import succeeds with no errors), smoke (every demoscript step that reads data finds the data).

### Phase 6: `sf-demo-validate` (existing 200-pt rubric)

**Artifact:** Validated, repaired demo-ready org.

This is the **pilot phase**. Existing 200-pt rubric is reused; harness only changes *who grades it* (fresh evaluator subagent) and *how the trace is captured* (TRACE.md). No new rubric design needed.

### Phase 7: Playwright pre-flight + presenter guide

**Artifact:** Playwright test suite + HTML visual report + annotated presenter guide.

| Dimension | Grades | Hard-fail |
|---|---|---|
| **Test coverage** | Every demoscript step has a corresponding Playwright assertion | 15 (hard-fail) |
| **Visual fidelity** | Screenshots at each step match what the script claims will be shown | 12 |
| **Presenter clarity** | Talking points reference what's visible on the screenshot, not abstract | 10 |
| **Resilience** | Tests handle Salesforce UI lag, async loads, and auth re-prompts | 13 |

**Tests:** unit (Playwright spec parses), integration (full suite runs green against connected org), smoke (presenter guide PDF renders with all screenshots embedded).

---

**Note on rubric maintenance.** Each phase's rubric lives alongside the phase's skill (or in `sf-demo-orchestrate`'s SKILL.md if the phase is orchestrator-internal). When the rubric changes, increment a version number — TRACE.md records the rubric version used, so old traces remain interpretable.

---

## 17. Cross-phase handoff contracts (the rough-handoff fix)

The "rough handoff" failure mode happens when Phase N's output is prose, Phase N+1 interprets it loosely, and the mismatch only surfaces at end-to-end test time (or worse, during the live demo). Fix: every phase emits a structured machine-readable artifact alongside its human-readable artifact. Phase N+1's evaluator validates against that contract before the implementer runs.

### 17.1 Requirement-coverage contract (Phase 2 → Phase 4)

Phase 2 (notes intake) writes `.eval-harness/requirements.json`:

```json
{
  "version": "1.0",
  "source_notes": "path/to/notes.md",
  "requirements": [
    {
      "id": "REQ-001",
      "summary": "Show donor giving history with year-over-year comparison",
      "source_quote": "donors want to see how their giving has evolved",
      "source_line": 23,
      "must_demo": true,
      "category": "feature"
    },
    {
      "id": "REQ-002",
      "summary": "Volunteer signup via Experience Cloud portal",
      "source_quote": "make it easy to sign up new volunteers",
      "source_line": 41,
      "must_demo": true,
      "category": "feature"
    }
  ]
}
```

Phase 4 (demoscript) writes `.eval-harness/requirement-coverage.json`:

```json
{
  "version": "1.0",
  "requirements_file": ".eval-harness/requirements.json",
  "coverage": [
    {
      "requirement_id": "REQ-001",
      "covered_by_steps": ["step-3", "step-4"],
      "demonstration_quality": "primary"
    },
    {
      "requirement_id": "REQ-002",
      "covered_by_steps": ["step-7"],
      "demonstration_quality": "primary"
    }
  ],
  "uncovered_requirements": [],
  "rationale_for_uncovered": null
}
```

**Hard rules:**
- Every `requirements[].id` with `must_demo: true` must appear in `coverage[]` with at least one step OR in `uncovered_requirements[]` with a non-null `rationale_for_uncovered` that the evaluator approves.
- `demonstration_quality` is `primary` (this step is the main demo of this requirement) or `incidental` (the requirement is touched but not the focus). Each requirement needs at least one `primary`.
- Phase 4's evaluator independently builds this matrix from the demoscript and compares. Mismatch = `SPEC-DEFECT`.

### 17.2 Data dependency contract (Phase 4 → Phase 5)

Phase 4 (demoscript) writes `.eval-harness/data-requirements.json`:

```json
{
  "version": "1.0",
  "records": [
    {
      "id": "donor-001",
      "object": "Account",
      "record_type": "Household",
      "required_fields": {
        "Name": "The Hartwell Family",
        "npe01__SYSTEMIsIndividual__c": true,
        "npo02__TotalOppAmount__c": 4500
      },
      "referenced_by_steps": ["step-3", "step-4"],
      "relationships": [
        {"to": "donor-001-contact", "via": "PrimaryContact__c"}
      ]
    }
  ]
}
```

**Hard rules:**
- Every record the demoscript references must appear in `records[]` with object, fields, and which steps need it.
- Phase 5 reads this file directly to drive seeding. No interpretation of prose.
- Phase 5's evaluator verifies every `records[].id` exists in the org with the required fields populated and all relationships resolved.

### 17.3 Click-path contract (Phase 4 → Phase 7)

Phase 4 writes `.eval-harness/click-path.json`:

```json
{
  "version": "1.0",
  "steps": [
    {
      "id": "step-3",
      "description": "Navigate to The Hartwell Family household record",
      "url_pattern": "/lightning/r/Account/{donor-001.id}/view",
      "actions": [
        {"type": "click", "selector": "a[title='The Hartwell Family']"},
        {"type": "wait_for", "selector": "h1.recordHeader"},
        {"type": "screenshot", "name": "donor-detail.png"}
      ],
      "expected_visible": ["Total Gifts: $4,500", "Last Gift: 2025-12-15"]
    }
  ]
}
```

**Hard rules:**
- Every step in the demoscript must have a corresponding entry here.
- Phase 7 generates Playwright tests directly from this file. No prose interpretation.
- Phase 7's evaluator verifies every assertion in `expected_visible` actually fires green against the seeded org.

### 17.4 Why machine-readable, not just structured prose

Two reasons:

1. **Evaluator can mechanically compare.** "Did Phase 5 seed everything Phase 4 needs?" becomes a JSON diff, not a prose review. Catches half-baked handoffs deterministically.
2. **Implementer can't paper over gaps.** Prose lets an LLM write "the demo includes donor history" without specifying which records, which fields, which screens. JSON forces concreteness — and missing JSON keys are caught by schema validation, not by hoping the evaluator notices.

### 17.5 Schema enforcement

Each contract has a JSON Schema in `.eval-harness/schemas/`. Phase implementer's `unit_tests` rubric includes "contract file validates against schema" as a required category. A demoscript that produces invalid JSON fails Phase 4's test rubric automatically — no SHIP verdict possible.

---

## 18. The half-baked + shallow-demo prevention checklist

Two failure modes, defense-in-depth on both:

**Half-baked = features silently dropped.** Caught by:

| Defense layer | Where it lives | What it catches |
|---|---|---|
| Phase 2 hard-fail on faithfulness | §16 Phase 2 rubric | Notes digest hallucinated requirements not in source |
| `requirements.json` with line citations | §17.1 | Phase 2 must point to source-line evidence for each requirement |
| Phase 4 hard-fail on requirement coverage (18 pts) | §16 Phase 4 rubric | Demoscript drops a `must_demo: true` requirement |
| Independent coverage matrix by evaluator | §16 Phase 4 critical evaluator check | Implementer can't lie about coverage — evaluator builds matrix from scratch |
| Phase 5 reads `data-requirements.json` directly | §17.2 | No prose interpretation — half-empty screens caught at seed time |
| Phase 6 (`sf-demo-validate`) cross-checks coverage | Existing 200-pt rubric + harness | Final check: every requirement has a working demo path in the seeded org |
| Phase 7 Playwright asserts on `expected_visible` | §17.3 | If the demo step claims to show something, the test verifies it actually shows |

**Shallow = demo runs end to end but is forgettable / admin-heavy / no wow.** Caught by:

| Defense layer | Where it lives | What it catches |
|---|---|---|
| Phase 3 hard-fail on demo depth specification (15 pts) | §16 Phase 3 rubric | Per-requirement min steps + persona pain + wow moment must be specified |
| Phase 3 hard-fail on user-value framing (13 pts) | §16 Phase 3 rubric | End-user POV target + admin cap must be set; recommendations encoded as outcomes |
| `value-moments.json` contract | §19.1 | Phase 3 spec is machine-readable; Phase 4 can be graded against it |
| Phase 4 hard-fail on requirement coverage AND depth (18 pts) | §16 Phase 4 rubric | Coverage isn't enough — each requirement must hit `min_steps` from Phase 3 |
| Phase 4 hard-fail on wow-moment delivery (12 pts) | §16 Phase 4 rubric | All four beats (pain → watch this → moment → narration) must be present and ordered |
| Phase 4 hard-fail on POV ratio (12 pts) | §16 Phase 4 rubric | Click-path tagged per step; ratio measured against Phase 3 target |
| Independent POV reconstruction by evaluator | §16 Phase 4 critical evaluator check | Implementer can't fake the POV ratio — evaluator re-tags every step from scratch |
| `wow-moment-delivery.json` contract | §19.2 | Wow moments are machine-checkable, not claimed in prose |

If a demo ships half-baked or shallow through all 15 of these defenses, that's a real bug worth investigating, not a normal outcome.

---

## 19. Phase 3 → 4 depth & user-value contract (the shallow-demo fix)

The "5 clicks of stuff I don't care about as an end-user" problem is upstream of Phase 4. It's a Phase 3 specification gap: if Phase 3 hands Phase 4 "demo Agentforce auto-triage for 30 min," Phase 4 will faithfully produce 5 clicks. The fix is making Phase 3 specify *depth*, *pain*, *outcome*, and *wow moments* — and making that specification the contract Phase 4 is graded against.

### 19.1 `value-moments.json` (Phase 3 emits)

```json
{
  "version": "1.0",
  "duration_minutes": 30,
  "duration_budget": {
    "end_user_pov_min_pct": 60,
    "admin_setup_max_pct": 20,
    "narrative_transitions_pct": 20
  },
  "value_moments": [
    {
      "requirement_id": "REQ-001",
      "min_steps": 6,
      "persona": "Sarah, Director of Development",
      "persona_pain_quote": "I spend 4 hours every Monday building donor reports manually before I can even think about strategy",
      "persona_outcome": "Sarah opens her dashboard at 8am Monday and the report is already there, with anomalies flagged — she has her morning back",
      "wow_moment": {
        "description": "AI-flagged anomaly: 'Hartwell family gave 3x normal — likely major gift opportunity'",
        "why_audience_leans_forward": "It's the system noticing what Sarah didn't have time to notice. Audience realizes this is the system doing strategy work, not data work.",
        "presenter_cue": "Pause here. Let it land.",
        "estimated_duration_seconds": 15
      },
      "anti_demo": [
        "Do not show how the AI was configured",
        "Do not show the underlying data model",
        "Do not click into Setup"
      ],
      "end_user_pov_steps": 5,
      "admin_pov_steps": 1
    }
  ]
}
```

**Hard rules:**
- Every Phase 2 requirement with `must_demo: true` must have a `value_moments[]` entry.
- `min_steps` is a minimum, not a target. Phase 4 may produce more steps but cannot produce fewer.
- `wow_moment` is required. "There is no wow moment" is not a valid value. If a requirement genuinely has no wow moment, it shouldn't be a `must_demo` requirement.
- `persona_pain_quote` should be drawn from the Phase 2 notes digest where possible. If invented, mark `synthesized: true` and the evaluator will scrutinize harder.
- `anti_demo[]` is the explicit "don't show this" list — typically Setup, configuration, the underlying data model, anything end-users don't see in real life.
- `end_user_pov_steps + admin_pov_steps ≤ min_steps` and end_user share must satisfy `duration_budget.end_user_pov_min_pct`.

### 19.2 `wow-moment-delivery.json` (Phase 4 emits)

```json
{
  "version": "1.0",
  "value_moments_file": ".eval-harness/value-moments.json",
  "deliveries": [
    {
      "value_moment_requirement_id": "REQ-001",
      "delivered_in_steps": ["step-3", "step-4", "step-5"],
      "pain_context_beat": {
        "step": "step-3",
        "narration": "Sarah arrives Monday morning. Last week, this is when she'd be 2 hours into her report."
      },
      "watch_this_cue": {
        "step": "step-4",
        "narration": "Watch the top of the dashboard — Sarah hasn't done anything yet."
      },
      "moment_step": "step-4",
      "narration_beat": {
        "step": "step-5",
        "narration": "The system noticed what Sarah didn't have time to notice. That's the difference."
      }
    }
  ]
}
```

**Hard rules:**
- Every `value_moments[]` entry from Phase 3 must have a corresponding `deliveries[]` entry.
- All four beats (pain_context, watch_this, moment, narration) must be present and tied to specific steps in the click-path.
- Beats must appear in click-path step order (pain before moment, moment before narration).

### 19.3 Per-step POV tagging (in `click-path.json`, extends §17.3)

```json
{
  "id": "step-4",
  "description": "Sarah views her morning dashboard",
  "pov": "end_user",
  "url_pattern": "/lightning/n/Donor_Dashboard",
  "actions": [...],
  "expected_visible": [...]
}
```

`pov` enum: `end_user` | `admin` | `mixed` | `narrative`. The narrative bucket is for transition steps that don't show UI (e.g., a slide intro). POV ratio is computed across `end_user` vs `admin` only — narrative steps don't count against either side.

### 19.4 Why this fixes the shallow-demo problem

| Old failure mode | What now blocks it |
|---|---|
| Phase 3 says "demo auto-triage" → Phase 4 produces 5 clicks | Phase 3 must specify min steps + persona pain + wow moment per requirement; "demo auto-triage" is not a valid Phase 3 output |
| Phase 4 produces a feature checklist instead of a story | Phase 4 must deliver pain_context → watch_this → moment → narration beats per requirement; checklist demos can't satisfy this contract |
| Demo is mostly Setup/admin time | Phase 3 caps admin time at 20%; Phase 4's evaluator measures POV ratio independently |
| No wow moment, demo is flat | Phase 3 hard-fail if no wow moment specified; Phase 4 hard-fail if specified moment isn't delivered |
| Implementer claims user-focused but actually shows admin screens | Two independent reconstructions in §16 Phase 4 — implementer can't fake the POV ratio |

### 19.5 Defaults (configurable in `sf-demo-orchestrate` SKILL.md)

| Setting | Default | Rationale |
|---|---|---|
| `end_user_pov_min_pct` | 60% | Most of the demo is what end-users see. |
| `admin_setup_max_pct` | 20% | Some admin context is fine; dominant-admin demos lose audiences. |
| `narrative_transitions_pct` | 20% | Story beats need room. |
| `min_steps_per_requirement` (default if Phase 3 doesn't specify) | 4 | Below 4 steps, you can't tell a pain → wow → outcome story. |
| `wow_moment_min_duration_seconds` | 10 | Anything shorter than 10s of "watch this" doesn't land. |

These are starting points. Pilot data will tell us where they should actually sit.
