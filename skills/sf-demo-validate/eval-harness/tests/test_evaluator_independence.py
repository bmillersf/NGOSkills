"""Unit tests: independent reconstruction divergence detection.

Per SPEC §16 Phase 4, the evaluator must independently rebuild the coverage
matrix and POV ratio from prose, then compare to the implementer's claims.
This module tests the divergence-detection helpers.

Note: the LLM-driven independent reconstruction itself is in the evaluator
prompt (prompts/evaluator.md). What we test here is the deterministic math
that compares two reconstructions.
"""
from __future__ import annotations


def coverage_matrix_diff(
    implementer_claim: dict, evaluator_rebuild: dict
) -> dict[str, set[str]]:
    """Diff two coverage matrices keyed by requirement_id.

    Returns a dict of `requirement_id -> {claimed_steps_only, rebuilt_steps_only}`.
    Empty dict means the matrices agree.
    """

    def to_map(coverage: dict) -> dict[str, set[str]]:
        return {
            c["requirement_id"]: set(c["covered_by_steps"])
            for c in coverage["coverage"]
        }

    claim_map = to_map(implementer_claim)
    rebuild_map = to_map(evaluator_rebuild)
    all_keys = set(claim_map) | set(rebuild_map)

    diffs: dict[str, dict] = {}
    for key in all_keys:
        c = claim_map.get(key, set())
        r = rebuild_map.get(key, set())
        if c != r:
            diffs[key] = {
                "claimed_only": c - r,
                "rebuilt_only": r - c,
            }
    return diffs


def pov_ratio_diff(implementer_pct: float, evaluator_pct: float) -> float:
    return abs(implementer_pct - evaluator_pct)


def test_matching_coverage_no_diff(coverage) -> None:
    diff = coverage_matrix_diff(coverage, coverage)
    assert diff == {}


def test_extra_step_in_claim_detected(coverage) -> None:
    """Implementer claims a step covers a req that the evaluator says it doesn't."""
    from copy import deepcopy

    rebuild = deepcopy(coverage)
    # Implementer claims step-1, step-2, step-3 cover REQ-001
    # Evaluator rebuilds and only sees step-1 covering REQ-001 (step-2 is just scrolling)
    rebuild["coverage"][0]["covered_by_steps"] = ["step-1"]
    diffs = coverage_matrix_diff(coverage, rebuild)
    assert "REQ-001" in diffs
    assert diffs["REQ-001"]["claimed_only"] == {"step-2", "step-3"}


def test_missing_requirement_in_claim_detected(coverage) -> None:
    """Implementer drops a requirement from coverage; evaluator catches it."""
    from copy import deepcopy

    claim = deepcopy(coverage)
    claim["coverage"] = claim["coverage"][:-1]  # drop REQ-004
    diffs = coverage_matrix_diff(claim, coverage)
    assert "REQ-004" in diffs
    assert diffs["REQ-004"]["claimed_only"] == set()
    assert "step-12" in diffs["REQ-004"]["rebuilt_only"]


def test_pov_ratio_within_tolerance() -> None:
    assert pov_ratio_diff(62.0, 60.0) == 2.0
    # Threshold is 5% per SPEC §16; this is within tolerance
    assert pov_ratio_diff(62.0, 60.0) <= 5.0


def test_pov_ratio_divergence_exceeds_tolerance() -> None:
    """Implementer claims 75% end_user; evaluator rebuilds and gets 55%."""
    diff = pov_ratio_diff(75.0, 55.0)
    assert diff == 20.0
    assert diff > 5.0  # would trigger SPEC-DEFECT
