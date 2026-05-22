# Sample harness run — Helping Hands volunteer demo (deterministic walkthrough)

This document records a deterministic end-to-end run of the eval harness on the `simple-volunteer-demo` fixture. It exercises the file-based loop without invoking an LLM — proving that the harness machinery (contracts, schemas, scoring, escalation, trace) works as designed before the first LLM-driven pilot run.

> **First real-world LLM-driven pilot run completed 2026-05-21.** See [`fixtures/children-incorporated-pilot-2026-05/README.md`](fixtures/children-incorporated-pilot-2026-05/README.md) for the captured artifacts: 5-row TRACE, two EVAL-REPORTs, IMPL-NOTES, all 6 contract files. Loop converged in 2 iterations (ITERATE 77/100 → SHIP 89/100). Adversarial evaluator caught 3 gaps self-eval would have shipped. Single strongest evidence to date that the harness earns its keep.

## What this run validates

| SPEC requirement | How this run validates it |
|---|---|
| §17 cross-phase contracts validate against schemas | `cli.py validate-contracts` returns OK on all 6 fixture files |
| §22.3 cross-contract FK + no-orphans | Same CLI call also runs link integrity, returns OK |
| §6 loop termination math | `cli.py score` correctly returns ITERATE on 70/100 + smoke fail, then SHIP on 85/100 + all-pass |
| §6.3 hard-fail breach escalates | Already covered by `tests/test_loop.py::test_hard_fail_breach_escalates_immediately` |
| §22.2 TRACE.md as primary debugging loop | Trace below is human-readable, sortable by timestamp, captures exactly what happened |

## The run

### Setup

```bash
SAMPLE=/tmp/sf-demo-validate-sample-run/.eval-harness
mkdir -p "$SAMPLE"
cp eval-harness/fixtures/simple-volunteer-demo/*.json "$SAMPLE/"
```

### Step 1 — Validate contracts

```bash
$ python -m scripts.cli validate-contracts --harness-dir "$SAMPLE" --strict
OK: 6 contract(s) valid, link integrity OK
```

All 6 contracts (`requirements`, `value-moments`, `requirement-coverage`, `wow-moment-delivery`, `data-requirements`, `click-path`) pass schema validation. Cross-contract FK resolution + no-orphan check returns clean.

### Step 2 — Iteration 1 (ITERATE)

Planner writes SPEC.md → Implementer runs `sf-demo-validate` 7-phase workflow → Evaluator scores 70/100 with smoke test failing.

```bash
$ echo '{"scores":[
    {"name":"Correctness","score":21},
    {"name":"Robustness","score":14},
    {"name":"Fit","score":20},
    {"name":"Performance","score":15}
  ],"tests":{"unit_pass":true,"integration_pass":true,"smoke_pass":false}}' \
  | python -m scripts.cli score
{
  "verdict": "ITERATE",
  "quality_total": 70,
  "quality_max": 100,
  "quality_pct": 70.0,
  "hard_fail_breaches": [],
  "spec_defect_reason": null
}
$ echo $?
1
```

CLI exits non-zero on ITERATE — the orchestrating skill picks up that signal and writes EVAL-FEEDBACK.md ("step-13 retention metric not refreshing; smoke fails").

### Step 3 — Iteration 2 (SHIP)

Implementer addresses the gap. Evaluator re-scores in fresh context (no memory of iter 1).

```bash
$ echo '{"scores":[
    {"name":"Correctness","score":23},
    {"name":"Robustness","score":20},
    {"name":"Fit","score":22},
    {"name":"Performance","score":20}
  ],"tests":{"unit_pass":true,"integration_pass":true,"smoke_pass":true}}' \
  | python -m scripts.cli score
{
  "verdict": "SHIP",
  "quality_total": 85,
  "quality_max": 100,
  "quality_pct": 85.0,
  "hard_fail_breaches": [],
  "spec_defect_reason": null
}
$ echo $?
0
```

### Final TRACE.md

```
| timestamp        | iter | role        | verdict      | quality | hard-fail | tests              | artifact-delta                                                       | notes                                              |
|------------------|------|-------------|--------------|---------|-----------|--------------------|-----------------------------------------------------------------------|----------------------------------------------------|
| 2026-05-21T15:33 | 1    | planner     | SPEC-WRITTEN | —       | —         | —                  | SPEC.md (4 ACs, 4 must_demo reqs)                                     | all 4 must_demo reqs covered in ACs                |
| 2026-05-21T15:33 | 1    | implementer | DONE         | —       | —         | —                  | demoscript.md +14 steps; 5 data records seeded                        | Phase 5 fix: VolunteerShift__c PublicVisible=true  |
| 2026-05-21T15:33 | 1    | evaluator   | ITERATE      | 70/100  | —         | unit:p, int:p, smoke:f | —                                                                 | step-13 retention metric not refreshing; smoke fails |
| 2026-05-21T15:33 | 2    | implementer | DONE         | —       | —         | —                  | added retention recompute trigger; step-13 expectation tightened      | addressed smoke-test gap from EVAL-FEEDBACK        |
| 2026-05-21T15:33 | 2    | evaluator   | SHIP         | 85/100  | —         | unit:p, int:p, smoke:p | —                                                                 | all dims above floor; coverage matrix matches      |
```

## What this run does NOT validate

- **The evaluator's actual judgment.** This walkthrough simulates evaluator decisions; it does not exercise an LLM evaluator against real artifacts. That's what the pilot success-metric run will measure (SPEC §8).
- **Self-eval-vs-adversarial-eval gap.** The whole point of the harness — does fresh-context evaluation catch things in-context self-eval misses? — requires a real LLM run on a real demo. This walkthrough is pre-flight machinery validation, not the experiment itself.
- **Real org connectivity.** The fixture has no live Salesforce org behind it. The first LLM-driven pilot run will exercise that path.

## Test suite summary

```
$ python -m pytest tests/ -v
============================== 49 passed in 0.38s ==============================
```

| File | Tests | What's covered |
|---|---|---|
| `test_contracts.py` | 10 | Schema validation, FK resolution, no-orphans, hard-fail floors in schemas |
| `test_rubric.py` | 13 | Scoring math, hard-fail enforcement, verdict logic, custom dimensions |
| `test_trace.py` | 5 | TRACE.md append-only writer, escaping, header de-duplication |
| `test_loop.py` | 10 | All 7 termination paths from SPEC §6, state serialization |
| `test_evaluator_independence.py` | 5 | Coverage matrix diff, POV ratio divergence detection |
| `test_integration.py` | 6 | Full file-based loop on fixture, CLI exit codes, multi-iteration paths |

## Next: pilot success-metric run

Per SPEC §8, after 3-5 real demo prep cycles, evaluate against:

1. Did adversarial evaluator find ≥1 gap that self-eval rated as passing?
2. Did the loop converge in ≤3 iterations on average?
3. Did TRACE.md make a real debugging session faster?
4. Did the user prefer harness output over current output?

≥3 yes → extract to `skills-cursor/sf-skill-eval-harness/` and roll out per SPEC §14 Stage 3.
