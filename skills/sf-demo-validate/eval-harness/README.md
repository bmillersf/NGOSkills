# sf-demo-validate Eval Harness (Pilot)

Adversarial evaluation wrapper around `sf-demo-validate`'s existing 200-point rubric. This is **Stage 1 of the harness rollout** per `content/specs/skill-eval-harness-SPEC.md`.

## What it does

Wraps `sf-demo-validate` with the three-agent loop from the SPEC:

```
planner ──► implementer ──► evaluator ──► (SHIP | ITERATE | SPEC-DEFECT)
                ▲                              │
                └──── EVAL-FEEDBACK ◄──────────┘
```

The implementer is `sf-demo-validate`'s existing 7-phase workflow. The harness adds:

- **Fresh-context evaluator** that re-scores independently (no sunk-cost drift)
- **Hard-fail floors** that block SHIP regardless of total score
- **Independent reconstructions** that catch when the implementer claims coverage it didn't deliver
- **TRACE.md** — append-only debugging loop
- **JSON contracts** for handoffs (so artifacts can't drift between phases)

## Invocation (via skill orchestration)

The harness is invoked from `sf-demo-validate`'s SKILL.md when the skill's `eval_harness.enabled` flag is set. The Python scripts in `scripts/` provide the deterministic primitives the orchestration calls into.

## Direct CLI usage

```bash
# Validate all six contract files in .eval-harness/
python3 -m scripts.cli validate-contracts --harness-dir .eval-harness

# Score against the 4-dimension rubric (JSON on stdin)
echo '{
  "scores": [
    {"name": "Correctness", "score": 22},
    {"name": "Robustness", "score": 18},
    {"name": "Fit", "score": 20},
    {"name": "Performance", "score": 15}
  ],
  "tests": {"unit_pass": true, "integration_pass": true, "smoke_pass": true}
}' | python3 -m scripts.cli score

# Append a row to TRACE.md
python3 -m scripts.cli trace-append \
  --trace-path .eval-harness/TRACE.md \
  --iteration 1 \
  --role evaluator \
  --verdict SHIP \
  --quality "75/100" \
  --tests "unit:p, int:p, smoke:p" \
  --notes "all hard-fail floors met"

# Decide next loop action (JSON on stdin)
echo '{
  "config": {"max_iterations": 3},
  "state": {"iteration": 1, "replans_used_in_loop": 0},
  "latest": {
    "verdict": "ITERATE",
    "dimensions": [{"name":"Correctness","max_points":25,"hard_fail_floor":15}],
    "scores": [{"name":"Correctness","score":18}],
    "tests": {"unit_pass": true, "integration_pass": false, "smoke_pass": true}
  }
}' | python3 -m scripts.cli loop-decide
```

## Files in this directory

| Path | Purpose |
|---|---|
| `schemas/*.schema.json` | JSON Schema for the six cross-phase contracts |
| `scripts/contracts.py` | Contract loaders, schema validation, FK + no-orphan checks |
| `scripts/rubric.py` | Quality dimensions, hard-fail floors, verdict computation |
| `scripts/trace.py` | Append-only TRACE.md writer |
| `scripts/harness.py` | Loop control logic (pure, I/O-free) |
| `scripts/cli.py` | CLI entry point used by the skill orchestration and tests |
| `prompts/planner.md` | Subagent prompt for the planner role |
| `prompts/implementer.md` | Subagent prompt for the implementer role |
| `prompts/evaluator.md` | Subagent prompt for the evaluator role |
| `fixtures/simple-volunteer-demo/` | Fixture demo for unit + integration testing |
| `tests/` | Unit and integration tests |

## Pilot success criteria (SPEC §8)

After 3-5 real demo prep cycles, evaluate:

1. Did adversarial evaluator find ≥1 gap that self-eval rated as passing?
2. Did the loop converge in ≤3 iterations on average?
3. Did TRACE.md make a real debugging session faster?
4. Did the user prefer harness output over current output?

≥3 yes → extract to `skills-cursor/sf-skill-eval-harness/` and roll out.
<3 yes → revert and document why in skill-learning anti-patterns.

## Dependencies

- Python 3.10+
- `jsonschema` (`pip install jsonschema`)
- `pytest` for the test suite
