# Phase 5 (data seeding) — deterministic walkthrough

**Run date:** 2026-05-21
**Org:** none — deterministic walkthrough only (no org cycles burned)
**Target skills:** `sf-nonprofit-demo-data` AND `sf-demo-data` (both wrapped together; routed alternatives)

## What this walkthrough proves

Phase 5 wirings are mechanically sound *before* any LLM-driven Phase 5 pilot fires. The harness CLI primitives (validate-contracts, score) correctly enforce the new Phase 5 rubric on real contract data.

| Test | Result |
|---|---|
| Schema validation on Riverside Food Network's `data-requirements.json` (Phase 4 fixture, used as Phase 5 input) | OK: 6 contracts valid, link integrity OK |
| Verdict computation on hypothetical iter-1 ITERATE scenario (Coverage 16, floor 18) | ITERATE — `Coverage scored 16 (floor 18)` triggers hard-fail despite 81% aggregate |
| Verdict computation on hypothetical iter-2 SHIP scenario (all dims clear floors) | SHIP — 93/100, all hard-fail floors satisfied |

## Why this walkthrough matters

Without a hard-fail floor, an 81% Coverage score would ship the demo. The simulation captures the exact failure mode: 2 of 8 partner agency records missing from the org would mean **2 click-path steps that fail to find their data on demo day** — a demo-killing defect masked by a high aggregate score. Hard-fail floors catch this exactly.

The 18-point Coverage floor on a 25-point dimension means "miss more than 28% of records and you cannot ship." That's the right line for Phase 5 because partial coverage looks fine in aggregate but breaks the live demo.

## What this walkthrough does NOT prove

- Whether an LLM-driven evaluator subagent will faithfully run the three deterministic probes (Coverage probe, Layout-completeness probe, Relationship probe) against a live org. That's the live-org pilot, deferred to a real demo prep cycle.
- Whether `sf-nonprofit-demo-data` and `sf-demo-data` actually generate the records described in `data-requirements.json` correctly. That's the implementer subagent's job, also deferred.
- Whether the Phase 5 evaluator catches realism failures (e.g., generic "Test User 1" names slipping past). Realism grading requires an LLM evaluator with domain knowledge.

## When the live pilot should happen

When a real `/sf-demo-orchestrate` run fires Phase 5 naturally for a customer-facing demo, the live pilot will execute as part of the normal pipeline. Capturing it as a one-off here would be contrived test data.

The deferred-pilot decision is logged: do not run a Phase 5 contrived pilot just to generate fixture data. Wait for genuine pipeline invocation.

## SPEC §8 success metric impact

This walkthrough adds 0 data points to the §8 success metrics — it's mechanical verification, not adversarial evaluation. The §8 metric data still stands at 4/4 yes from two prior LLM-driven pilots:

1. Children Inc Phase 6 (sf-demo-validate, ITERATE → SHIP, 2 iterations)
2. Riverside Food Network Phase 4 (sf-demo-author, SHIP-with-calibration-miss, 1 iteration)

A live Phase 5 pilot will add the 3rd data point when a real demo prep cycle exercises it.

## Reproducing this walkthrough

```bash
cd skills-cursor/sf-skill-eval-harness && \
  .venv/bin/python -m scripts.cli validate-contracts \
    --harness-dir fixtures/riverside-food-network-phase4-pilot-2026-05/.eval-harness \
    --strict

# Iter-1 ITERATE simulation (Coverage breach):
echo '{...iter1 JSON above...}' | .venv/bin/python -m scripts.cli score

# Iter-2 SHIP simulation:
echo '{...iter2 JSON above...}' | .venv/bin/python -m scripts.cli score
```

Full JSON inputs and outputs preserved in `walkthrough.log` alongside this README.
