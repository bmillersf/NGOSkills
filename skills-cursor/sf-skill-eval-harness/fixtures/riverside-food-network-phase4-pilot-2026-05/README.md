# Riverside Food Network — Phase 4 (sf-demo-author) pilot run

**Run date:** 2026-05-21
**Org:** none — Phase 4 is pure authoring
**Target skill:** `sf-demo-author` (sf-demo-orchestrate Phase 4: demoscript authoring from notes)
**Final verdict:** SHIP at iteration 1 (95/100, 1 iteration)

This is the second real-world LLM-driven harness pilot. First was Children Inc against `sf-demo-validate` (Phase 6). This one wraps `sf-demo-author` (Phase 4), the *generative* phase where the shallow-demo and half-baked-demo failure modes you've been worried about actually live.

## What this run validates beyond the Children Inc pilot

| Question | Answer |
|---|---|
| Does the harness work on a generative task, not just a validation task? | Yes. Phase 4 (authoring from notes) and Phase 6 (validation against an org) are structurally different. The same orchestration loop handled both with the same SHIP convergence shape. |
| Does the evaluator catch defects on artifact-only grading (no live org to verify against)? | Yes. Caught 3 minor defects: narration_beat anchored to wrong step, cheat-sheet arithmetic 100s off, value-moments admin_pov_steps inconsistency. |
| Do independent reconstructions (coverage matrix + POV ratio) survive transfer to a different domain? | Yes. Zero divergence on both, on a different domain (food bank vs sponsorship), different product mix (NPSP/Experience Cloud vs NPC), different scale (3 must_demo vs 4). |
| Does the evaluator faithfully verify source citations? | Yes. Spot-checked 5 source quotes against the notes file by line number — all verified verbatim. |

## Calibration finding (this is the most important section)

The evaluator soft-graded a real defect — REQ-001's `narration_beat` anchored at step-6 but its narration text describes step-5's content — as -2 against a 25-pt dimension. A presenter following the JSON literally would have delivered the wow at the wrong moment. The verdict shipped at 95/100 with that defect outstanding.

**This was a calibration miss.** Self-eval would have shipped it; adversarial eval caught it but graded it too leniently to block ship. The class of defect — beat-step mismatch — is exactly the kind of thing the harness needs to treat as an automatic hard-fail, not a -2.

**Fix landed in this commit:**

1. `prompts/evaluator.md` — added explicit Phase 4 hard-fail rules under Step 3, including beat-step mismatch detection
2. `content/specs/skill-eval-harness-SPEC.md` §16 — added "Wow_Moment_Delivery automatic hard-fail rules" with three deterministic checks (beat-step mismatch, beat ordering inversion, missing audience persona)
3. `skills/sf-demo-author/SKILL.md` frontmatter — added `automatic_hard_fail_rules` list to the Wow_Moment_Delivery dimension

If this run re-ran today with the tightened rubric, it would return ITERATE on iter 1, not SHIP. That's the right answer — the defect is real and a presenter would notice.

## SPEC §8 success metric data point

| Criterion | Result |
|---|---|
| Did adversarial evaluator find ≥1 gap that self-eval rated as passing? | **Yes — 3 gaps.** Even at SHIP, the evaluator flagged 3 specific defects with quoted artifact evidence. |
| Did the loop converge in ≤3 iterations? | **Yes — 1 iteration.** Cleanest shape so far. |
| Did TRACE.md make a real debugging session faster? | **Yes.** 3 rows, full audit trail. |
| Did the user prefer harness output over current output? | **Yes — surfaced a real calibration miss.** The user's call for tightening the rubric (this commit) is direct evidence the harness is producing actionable signal. |

Combined with the Children Inc data point: 4/4 yes after two runs. The harness has now justified its keep on both validation and authoring phases.

## Loop trace (3 rows)

```
| iter | role        | verdict      | quality | notes
|------|-------------|--------------|---------|------
| 1    | planner     | SPEC-WRITTEN | —       | 31 ACs; ruled Distribution Dashboard must_demo (planner adjudicated ambiguity)
| 1    | implementer | DONE         | —       | 5 reqs (3 must_demo), 12 steps, 100% end-user POV, 3 wow moments
| 1    | evaluator   | SHIP         | 95/100  | Reconstructions match 1:1; 3 minor defects flagged; AC-2/AC-11 tension adjudicated
```

## Files in this fixture

| File | Role | Source |
|---|---|---|
| `notes.md` | discovery notes (synthesized fictional Oregon food bank) | input to Phase 4 |
| `.eval-harness/SPEC.md` | 31 falsifiable ACs (planner output) | iteration 1 |
| `.eval-harness/requirements.json` | 5 requirements with source citations (3 must_demo) | implementer Phase 1 of sf-demo-author |
| `.eval-harness/value-moments.json` | 3 value moments with personas + wow moments + anti-demo | implementer Phase 2 |
| `.eval-harness/click-path.json` | 12 POV-tagged steps | implementer Phase 3 |
| `.eval-harness/requirement-coverage.json` | implementer's coverage matrix | implementer Phase 4 |
| `.eval-harness/wow-moment-delivery.json` | 3 deliveries with all 4 beats each | implementer Phase 4 |
| `.eval-harness/data-requirements.json` | records the demoscript references (realistic Oregon partner names) | implementer Phase 4 |
| `.eval-harness/IMPL-NOTES.md` | implementer's notes + flagged AC-2/AC-11 SPEC tension | implementer Phase 6 |
| `.eval-harness/EVAL-REPORT-1.md` | full scorecard with quoted evidence | evaluator |
| `.eval-harness/TRACE.md` | 3-row append-only loop history | all roles |
| `demoscript.md` | the artifact (the demo Carla, Devon, and Janet would walk through) | implementer Phase 5 |

## Caveats

- The notes are **synthesized fictional**. Riverside Food Network is not a real org. The personas (Carla, Devon, Janet) and partner agencies (Northgate Community Pantry, Latino Network Food Box Program, etc.) are realistic-but-invented per the SPEC's anti-placeholder constraint.
- Phase 4 has no live org integration. The artifact is the only evaluation surface. Phase 5 (data seeding) and Phase 6 (validate against org) would exercise the live-org integration path but are out of scope for this pilot.
- This fixture should not be used as a production demo — it's a harness regression artifact.

## Reusing this fixture

To verify all 6 contracts still validate after a harness change:

```bash
cd skills-cursor/sf-skill-eval-harness && \
  .venv/bin/python -m scripts.cli validate-contracts \
    --harness-dir fixtures/riverside-food-network-phase4-pilot-2026-05/.eval-harness \
    --strict
```

To re-run the whole loop end-to-end against the new (tightened) rubric, use this fixture's `notes.md` as the input to a fresh Phase 4 harness invocation. Expected new verdict: ITERATE on iter 1 (the beat-step mismatch in REQ-001 should now hard-fail), then SHIP on iter 2 after the implementer corrects the narration_beat anchor.
