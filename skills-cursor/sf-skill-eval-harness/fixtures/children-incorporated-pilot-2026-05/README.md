# Children Incorporated — first real-world harness pilot run

**Run date:** 2026-05-21
**Org:** storm sandbox (alias `cool stuff`, instance `storm-b8c8ef44ac58ea.my.salesforce.com`)
**Target skill:** `sf-demo-validate`
**Final verdict:** SHIP at iteration 2 (89/100, 2 iterations)
**Initial verdict:** ITERATE at iteration 1 (77/100, 3 gaps caught by adversarial eval)

This directory is the captured evidence of the first end-to-end harness run against a live Salesforce org. It serves three purposes:

1. **Reference for future evaluator subagent grading** — what does a "good" SPEC look like? What do healthy IMPL-NOTES look like? What evidence-quoting standard should evaluators meet?
2. **Pilot success metric data** (per SPEC §8) — the harness caught 3 gaps self-eval would have shipped, converged in 2 iterations, kept TRACE.md compact and useful.
3. **Regression check** — if a future change to the harness skill alters loop behavior, run this fixture through the harness again and verify the same convergence shape.

## What this run proved

| SPEC §8 success criterion | Result |
|---|---|
| Did adversarial evaluator find ≥1 gap that self-eval rated as passing? | ✅ **3 gaps in iter 1.** Implementer self-rated ~196/200 internally; adversarial evaluator scored 77/100 with hard live-org evidence for each gap. |
| Did the loop converge in ≤3 iterations on average? | ✅ **2 iterations.** SHIP at iter 2 with 89/100, all hard-fails clear, 6/6 Apex tests pass. |
| Did TRACE.md make a real debugging session faster? | ✅ **5 rows replace ~3,000 words of conversation.** |
| Did the user prefer harness output over current output? | (Subjective — see commit `fbedde1` discussion thread.) |

## The three gaps adversarial eval caught

Each is a real defect the implementer's self-evaluation missed and the fresh-context evaluator surfaced with quoted org evidence:

| Gap | What self-eval claimed | What adversarial eval found |
|---|---|---|
| Bulk-safety of `CI_SponsorChildAction.sponsor` | "Bulk-safe (single SOQL/insert per type, no DML in loops)" | Live measurement: 4 SOQL + 8 DML for 2-request invocation = perfect N+1 |
| Duplicate-prevention on sponsor invocable | (silent — never tested) | Calling `sponsor()` twice with same donor+child created 2 active GiftCommitments. SPEC §5 Robustness criterion (c) verbatim: "Re-running step 5 with a duplicate donor lookup does not double-create commitments." |
| `expected_visible: 'Scheduled'` on click-path step-6 | "GiftTransaction status = Unpaid future-dated (no Scheduled value)" — claimed as a SPEC ambiguity, not a defect | NPC `GiftTransaction.Status` enum has no "Scheduled" value. The click-path's literal-string assertion was unambiguous; implementer talked around it instead of resolving it. |

## How iter-2 fixed each gap

Iter-2 implementer received only EVAL-FEEDBACK.md (gaps + why, no rubric weights, no fix prescriptions). Addressed all three with measured evidence:

| Gap | Fix | Evidence in IMPL-NOTES |
|---|---|---|
| Bulk-safety | Refactored to gather all donor+child pairs in one SOQL, batch the inserts | 5-request bulk call: deltaSOQL=3, deltaDML=4 (constant in N) |
| Duplicate prevention | Added existing-pair SOQL guard, returns `alreadySponsored: true` instead of double-inserting | Live duplicate-call: SAME_ID=true, ACTIVE_AFTER_SECOND=1 (not 2) |
| Scheduled string | Added `GiftTransaction.Display_Status__c` formula returning "Scheduled" when Unpaid + future-dated, surfaced as related-list column | 12/12 future-dated unpaid txns return Display_Status='Scheduled' |

## Loop trace (5 rows, full history)

See `.eval-harness/TRACE.md`. The trace alone tells the whole story:

```
| iter | role        | verdict      | quality | notes
|------|-------------|--------------|---------|------
| 1    | planner     | SPEC-WRITTEN | —       | 27 ACs, 2 ambiguities flagged for human checkpoint
| 1    | implementer | DONE         | —       | 40 metadata cmp deployed; 7 records seeded
| 1    | evaluator   | ITERATE      | 77/100  | bulk-unsafe, no dup-prevent, Scheduled string drift
| 2    | implementer | DONE         | —       | bulk refactor; dup guard; Display_Status__c formula
| 2    | evaluator   | SHIP         | 89/100  | 6/6 tests pass, 0 reconstruction divergence
```

## Files in this fixture

| File | Role | Phase |
|---|---|---|
| `.eval-harness/notes.md` | discovery notes (raw user input) | Phase 2 input |
| `.eval-harness/requirements.json` | 17 requirements, 4 must_demo, with source citations | Phase 2 output |
| `.eval-harness/value-moments.json` | 4 value moments with personas + wow moments + anti-demo | Phase 3 output |
| `.eval-harness/click-path.json` | 15 steps, POV-tagged | Phase 4 output |
| `.eval-harness/requirement-coverage.json` | implementer's coverage matrix | Phase 4 output |
| `.eval-harness/wow-moment-delivery.json` | per-requirement narrative beats | Phase 4 output |
| `.eval-harness/data-requirements.json` | 7 records to seed | Phase 4 output |
| `.eval-harness/SPEC.md` | 27 falsifiable ACs (planner's contract) | Iter 1 planner output |
| `.eval-harness/IMPL-NOTES.md` | iter-2 implementer's notes (overwrote iter-1's) | Iter 2 implementer output |
| `.eval-harness/EVAL-REPORT-1.md` | iter-1 evaluator's full scorecard with quoted evidence | Iter 1 evaluator output |
| `.eval-harness/EVAL-FEEDBACK.md` | iter-1 evaluator's gap descriptions for next iteration | Iter 1 evaluator output |
| `.eval-harness/EVAL-REPORT-2.md` | iter-2 evaluator's SHIP verdict report | Iter 2 evaluator output |
| `.eval-harness/TRACE.md` | append-only loop history | All roles |
| `demoscript.md` | the artifact being validated | Phase 4 output |

## Caveats and limitations

This fixture captures one real-world run. It is not a regression test in the harness's pytest suite — running it again would require:

- A connected `cool stuff`-equivalent storm org with NPC + Pardot/Marketing Cloud installed
- Re-spawning the three subagents with the same prompts in fresh context
- Cleanup between iterations to undo prior deployments (the demoscript's Teardown section helps)

Treat it as **evidence**, not as **automation**. The pytest suite (49 tests in `tests/`) covers the deterministic primitives. This fixture covers the LLM-driven orchestration that those primitives enable.

## What this fixture does NOT contain

- The implementer subagent's full conversational trace (~tens of thousands of tokens of tool calls). Only the ~14 KB IMPL-NOTES summary persists.
- The evaluator subagent's full conversational trace. Only the ~15 KB EVAL-REPORT-N.md summaries persist.
- The actual deployed metadata XML (lives in the `cool stuff` org, not in this repo).
- Any access tokens, Org IDs in URL form, or PII. Scrubbed before commit.

## Reusing this fixture

If you want to test a harness change against this fixture without spinning up a real org:

```bash
# Validate that all six contracts still pass schema + link integrity
cd skills-cursor/sf-skill-eval-harness && \
  .venv/bin/python -m scripts.cli validate-contracts \
    --harness-dir fixtures/children-incorporated-pilot-2026-05/.eval-harness \
    --strict
```

For the live-org regression path, follow `SAMPLE-RUN.md` and substitute this fixture's `notes.md` as Phase 2 input.
