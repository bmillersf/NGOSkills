# sf-apex Stage B pilot — N+1 detection validation

**Run date:** 2026-05-21
**Org:** none (artifact-only, no deploy)
**Target skill:** `sf-apex` (Stage B implementation skill, the first one wrapped)
**Final verdict:** SHIP at iteration 1 (93/100, single iteration)

This is the third real-world LLM-driven harness pilot, and the first Stage B pilot. Stage A wraps the orchestrator's artifact-producing phases. Stage B extends the harness to implementation skills those phases delegate to.

## Why this pilot mattered

The Children Inc Phase 6 pilot (2026-05-21) had the implementer subagent invoke `sf-apex` to generate `CI_SponsorChildAction.sponsor()`. The implementer self-reported "bulk-safe, no DML in loops". The class was actually 4 SOQL + 8 DML for a 2-request invocation — perfect N+1. The outer harness caught it on iter-1 ITERATE.

The Stage B wrap on `sf-apex` is supposed to catch N+1 *before* the outer harness even sees the code. This pilot tested whether it does.

## What this pilot validated

**The harness produced clean code on the first try.** The implementer subagent received the same SPEC the Children Inc implementer effectively had (same Apex class, same requirements, same Person Account / Contact context), but with the wrapped sf-apex's automatic_hard_fail_rules in scope:

| Failure mode | Children Inc baseline | Stage B pilot result |
|---|---|---|
| SOQL in loops | 4 SOQL at N=2 (perfect N+1) | 1 SOQL at N=200 (constant) |
| DML in loops | 8 DML at N=2 | 4 DML at N=200 (constant) |
| Duplicate prevention | Missing — created 2 active commitments on duplicate call | Working — alreadySponsored=true on 2nd call |
| Bulk evidence | None — only N=1 test | bulk_n200LimitsEvidence + bulk_governorLimitProbe both inside Test.startTest/stopTest |
| Outer harness verdict | ITERATE (3 real bugs caught) | (no outer harness in this pilot, but artifact would pass downstream cleanly) |
| Iterations to convergence | 2 (outer) | 1 (inner) |

The wrapping rules **steered the implementer toward clean code from the start** — not by catching defects in fresh-context evaluation (the rules didn't fire), but by being declared in the planner's input space and the implementer's role contract.

That's the architecture's payoff: hard-fail rules act as guardrails *during production*, not just adversarial filters *after production*. The Children Inc N+1 happened because the implementer wasn't aware of bulk-safety as a hard requirement; the Stage B implementer was.

## Calibration validation finding

The evaluator explicitly tested whether the rules were over-strict or under-strict:

> **Stage B validation finding:** the rules did NOT fire — because the implementer wrote clean code, not because the rules are mis-calibrated. Floors of 15/12/10/15 leave clean code landing comfortably in the 22–24 range per dimension.

That's the right answer. Calibration would have been wrong if:
- Rules fired on clean code (over-strict — false positives)
- Rules failed to fire on N+1 code (under-strict — false negatives)

Neither happened. The rules are calibrated correctly for this artifact class.

## One refinement surfaced

> **Refinement worth tracking:** the bulkification regex probe should be lex-aware so it strips string literals before scanning loop bodies for DML keywords — otherwise a future evaluator could mis-call a hard-fail on a string containing the word "insert".

The evaluator hit this case on line 155 of the implementer's class — a string literal `'GiftCommitment insert failed: '` triggered an initial false positive that required reading the line to disambiguate. Adversarial evaluation caught the issue (the evaluator self-corrected) but the deterministic CLI probe could miss it. Logged as future work for `scripts/contracts.py` or a dedicated `scripts/apex_static_analysis.py` module.

## SPEC §8 success metric impact (combined data)

After three pilots (Children Inc Phase 6, Riverside Phase 4, sf-apex Stage B):

| Criterion | Children Inc | Riverside | sf-apex Stage B | Combined |
|---|---|---|---|---|
| Adversarial eval found gap self-eval missed | 3 gaps | 3 minor defects | 0 (clean code) + 1 calibration finding | ✓ in 3/3 runs |
| Loop converged in ≤3 iterations | 2 | 1 | 1 | ✓ in 3/3 runs |
| TRACE.md actionable | yes | yes | yes | ✓ in 3/3 runs |
| User preferred harness output | yes | yes (calibration miss caught) | yes (Stage B validation) | ✓ in 3/3 runs |

**Combined: 4/4 yes across three pilots, on three different rubric shapes (validation, authoring, code generation).** The harness pattern generalizes.

## Files in this fixture

| File | Role |
|---|---|
| `notes.md` | requirements (deliberately neutral — no priming about N+1 or Children Inc) |
| `CI_SponsorChildAction.cls` | the artifact (280 lines, bulk-safe, dup-aware) |
| `CI_SponsorChildAction.cls-meta.xml` | standard Apex metadata |
| `CI_SponsorChildAction_Test.cls` | test class (279 lines, 5 methods including bulk_n200LimitsEvidence and bulk_governorLimitProbe) |
| `CI_SponsorChildAction_Test.cls-meta.xml` | test class metadata |
| `.eval-harness/SPEC.md` | 26 falsifiable ACs (planner output) |
| `.eval-harness/IMPL-NOTES.md` | implementer's notes with measured Limits deltas |
| `.eval-harness/EVAL-REPORT-1.md` | full scorecard with per-AC evidence quotes |
| `.eval-harness/TRACE.md` | 3-row append-only loop history |

## What this pilot does NOT prove

- That the rules fire correctly on actual N+1 code. The rules are designed to fire — but this run produced clean code, so we have no positive-detection data point. A future "deliberately N+1" pilot would close that loop.
- That the bulkification probe (deterministic CLI) is lex-aware. The evaluator caught the false-positive case manually; the CLI might miss it.
- That Stage B composes cleanly with outer Stage A wrapping (e.g., what happens when sf-demo-validate's Phase 6 implementer invokes sf-apex's wrapped harness?). Composition test deferred to a real demo pipeline run.

## Reusing this fixture

```bash
# Verify the .cls compiles via syntax check (read-only, no deploy)
cat skills-cursor/sf-skill-eval-harness/fixtures/sf-apex-stage-b-pilot-2026-05/CI_SponsorChildAction.cls

# Re-grade the artifact through the harness CLI
cd skills-cursor/sf-skill-eval-harness && \
  echo '{...iter-1 SHIP scores from EVAL-REPORT-1.md...}' | \
  .venv/bin/python -m scripts.cli score
```

For a deliberate-N+1 calibration test, take this fixture's `notes.md`, modify `CI_SponsorChildAction.cls` to put the Child__c lookup inside a for-loop, and re-run the evaluator. Expected outcome: Correctness automatic hard-fail, ITERATE verdict.
