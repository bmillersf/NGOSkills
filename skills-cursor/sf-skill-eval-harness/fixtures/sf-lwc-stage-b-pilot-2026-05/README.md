# sf-lwc Stage B pilot — a11y / Dark Mode / SLDS deprecation rules validation

**Run date:** 2026-05-21
**Org:** none (artifact-only, no deploy)
**Target skill:** `sf-lwc` (Stage B implementation skill, second pilot)
**Final verdict:** SHIP at iteration 1 (94/100, single iteration)

This is the fourth real-world LLM-driven harness pilot, and the second Stage B pilot (after sf-apex). Stage B extends the harness from orchestrator phases to implementation skills.

## What this pilot validates

The wrapped sf-lwc has automatic hard-fail rules that are different from sf-apex's. Apex hard-fails are about runtime correctness (governor limits, N+1, security boundaries). LWC hard-fails are about user-facing quality that slips past basic visual testing:

- A11y regressions only surface for users with assistive tech
- Dark Mode breakers only surface after orgs enable Dark Mode
- SLDS 1 deprecations work today but break in a future release

This pilot tested whether the four LWC-specific deterministic probes fire correctly on a clean component.

## What this pilot proved

The implementer subagent received the SPEC and produced clean code on the first try. All four probes ran and confirmed clean status:

| Probe | What it checks | Outcome |
|---|---|---|
| A11y probe | `<button>`, `<a>`, `<input>`, `<img>` without labels/alt; clickable divs without role+tabindex+keyboard | 0 violations — all interactive elements are `lightning-*` base components |
| SLDS hardcoded-color probe | `#hex`, `rgb()`, named colors in CSS | 0 violations — all colors via `--slds-g-color-*` tokens |
| SLDS deprecation probe | `--lwc-*` deprecated tokens, SLDS 1 utility class names | 0 violations — pure SLDS 2 |
| Reactivity model probe | `@track` on primitives, `document.querySelector`, `!important` in CSS | 0 violations — getter-based derived state, no DOM bypass |

**The rules did NOT fire — because the implementer wrote clean code, not because the rules are mis-calibrated.** Floors of 15/12/10/12 leave clean code landing comfortably in the 23-24 range per dimension.

## Calibration finding (the same pattern as sf-apex Stage B)

Same finding as the sf-apex Stage B pilot: rules are correctly calibrated for the negative direction (no false-positive firings on clean code). To fully validate precision, a deliberate-failure pilot is needed — a bundle that hardcodes `#FFFFFF`, uses raw `<button>`, references `--lwc-color-text-default`, etc. — to confirm each rule actually fires when violations exist.

**Recommended next: Stage B adversarial-failure pilot.** Take this fixture, deliberately introduce one failure per probe, run the evaluator. Expected outcome: each violation triggers its declared automatic hard-fail. That closes the calibration loop in both directions.

## What the evaluator did flag (the most interesting part)

Even on a clean SHIP at 94/100, the fresh-context evaluator surfaced two minor findings the implementer talked around:

1. **SPEC nomenclature drift:** Implementer collapsed three test cases (TC-U6 + TC-U7 + TC-S1) into one combined Jest test. Behavior is fully exercised, but the SPEC required three discretely-named cases. -1 Correctness deduction. Self-eval would have waved this off as "behavior covered, who cares about names" — fresh-context evaluator caught the partial-compliance.
2. **`display: contents` on `<dl>` rows:** Historical screen-reader edge case — some legacy assistive tech doesn't traverse children of `display: contents` containers. -2 Robustness deduction. The implementer didn't disclose this in IMPL-NOTES; the fresh-context evaluator surfaced it from CSS knowledge.

Neither tripped a hard-fail floor. Both are real findings worth noting.

## SPEC §8 success metric data point

| Criterion | Result |
|---|---|
| Did adversarial evaluator find ≥1 gap that self-eval rated as passing? | **Yes — 2 findings.** Implementer claimed clean; evaluator caught SPEC nomenclature drift + display:contents a11y edge. |
| Did the loop converge in ≤3 iterations? | **Yes — 1 iteration.** |
| Did TRACE.md make a real debugging session faster? | **Yes.** 3 rows, full audit trail. |
| Did the user prefer harness output? | TBD — the calibration recommendation (run a deliberate-failure pilot) is itself a useful next-step signal. |

Combined data after 4 pilots: still 4/4 yes across all runs.

## Loop trace

```
| iter | role        | verdict      | quality | notes
|------|-------------|--------------|---------|------
| 1    | planner     | SPEC-WRITTEN | —       | 33 ACs, no priming toward known LWC failure modes
| 1    | implementer | DONE         | —       | 5 files, 10 Jest cases, self-ran probes clean
| 1    | evaluator   | SHIP         | 94/100  | All 4 probes clean; 33/33 ACs pass; 2 minor findings flagged
```

## Files in this fixture

| File | Role |
|---|---|
| `notes.md` | requirements (volunteer shift card with Dark Mode + a11y constraints) |
| `lwc/volunteerShiftCard/volunteerShiftCard.html` | template (107 lines, all `lightning-*` base components) |
| `lwc/volunteerShiftCard/volunteerShiftCard.js` | controller (196 lines, getter-based state, shape-tolerant contactId extraction) |
| `lwc/volunteerShiftCard/volunteerShiftCard.css` | styles (80 lines, 19 `--slds-g-*` token refs, 0 hardcoded colors) |
| `lwc/volunteerShiftCard/volunteerShiftCard.js-meta.xml` | LWC metadata (apiVersion 62.0, isExposed=true, 4 targets) |
| `lwc/volunteerShiftCard/__tests__/volunteerShiftCard.test.js` | Jest tests (245 lines, 10 cases) |
| `.eval-harness/SPEC.md` | 33 falsifiable ACs |
| `.eval-harness/IMPL-NOTES.md` | implementer's architecture notes |
| `.eval-harness/EVAL-REPORT-1.md` | full scorecard with quoted evidence |
| `.eval-harness/TRACE.md` | 3-row append-only loop history |

## What this pilot does NOT prove

- Positive-detection on actual a11y / Dark Mode / SLDS 1 violations. The rules are designed to fire — but this run produced clean code, so we have no positive-detection data point. A deliberate-failure pilot would close that loop.
- That `display: contents` is genuinely a robustness issue in the user's target screen-reader matrix. The evaluator flagged it as a known historical edge; modern screen readers handle it correctly. The -2 deduction may itself be worth calibration review.
- Composition with outer Stage A wrapping (e.g., when sf-demo-validate's Phase 5 fix logic invokes sf-lwc to generate a portal component). Composition test deferred to a real demo pipeline run.

## Reusing this fixture

For a deliberate-failure calibration test, take this fixture's `notes.md`, modify the LWC bundle to introduce specific failures, and re-run the evaluator. Expected outcomes:

| Failure introduced | Expected hard-fail |
|---|---|
| Hardcode `color: #ffffff` in CSS | Fit automatic hard-fail |
| Replace `<lightning-button>` with `<button>` (no aria-label) | Robustness automatic hard-fail |
| Add `--lwc-color-text-default` to CSS | Fit automatic hard-fail |
| Use `@track` on a primitive `name` field | Correctness automatic hard-fail |
| Add `!important` to any CSS rule | Performance automatic hard-fail |

Each violation should trigger the corresponding automatic_hard_fail_rule and force ITERATE.
