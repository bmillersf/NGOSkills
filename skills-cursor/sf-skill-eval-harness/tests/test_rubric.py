"""Unit tests: rubric scoring math + hard-fail enforcement + verdict logic."""
from __future__ import annotations

import pytest

from scripts import rubric
from scripts.rubric import (
    DEFAULT_DIMENSIONS,
    Dimension,
    DimensionScore,
    TestRubric,
    Verdict,
    compute_verdict,
    improvement_below_threshold,
)


def _all_pass_tests() -> TestRubric:
    return TestRubric(unit_pass=True, integration_pass=True, smoke_pass=True)


def _full_marks_scores() -> list[DimensionScore]:
    return [DimensionScore(d, d.max_points) for d in DEFAULT_DIMENSIONS]


def test_full_marks_ships() -> None:
    result = compute_verdict(_full_marks_scores(), _all_pass_tests())
    assert result.verdict == Verdict.SHIP
    assert result.quality_pct == 100.0


def test_below_pct_floor_iterates() -> None:
    scores = [
        DimensionScore(DEFAULT_DIMENSIONS[0], 16),
        DimensionScore(DEFAULT_DIMENSIONS[1], 16),
        DimensionScore(DEFAULT_DIMENSIONS[2], 16),
        DimensionScore(DEFAULT_DIMENSIONS[3], 16),
    ]
    result = compute_verdict(scores, _all_pass_tests())
    assert result.verdict == Verdict.ITERATE
    assert result.quality_pct == 64.0


def test_hard_fail_breach_blocks_ship_even_at_high_total() -> None:
    """A 92/100 with a hard-fail breach must NOT ship."""
    scores = [
        DimensionScore(DEFAULT_DIMENSIONS[0], 14),  # Correctness floor 15 → BREACH
        DimensionScore(DEFAULT_DIMENSIONS[1], 25),
        DimensionScore(DEFAULT_DIMENSIONS[2], 25),
        DimensionScore(DEFAULT_DIMENSIONS[3], 25),
    ]
    result = compute_verdict(scores, _all_pass_tests())
    assert result.verdict == Verdict.ITERATE
    assert result.quality_pct == 89.0
    assert any("Correctness" in b for b in result.hard_fail_breaches)


def test_test_rubric_failure_blocks_ship() -> None:
    """All tests must pass for SHIP, even with perfect quality."""
    scores = _full_marks_scores()
    tests = TestRubric(unit_pass=True, integration_pass=False, smoke_pass=True)
    result = compute_verdict(scores, tests)
    assert result.verdict == Verdict.ITERATE


def test_spec_defect_short_circuits() -> None:
    """spec_defect_reason produces SPEC-DEFECT regardless of scores."""
    result = compute_verdict(
        _full_marks_scores(),
        _all_pass_tests(),
        spec_defect_reason="requirements.json missing REQ-005 user clearly asked for",
    )
    assert result.verdict == Verdict.SPEC_DEFECT
    assert result.spec_defect_reason is not None


def test_score_above_max_raises() -> None:
    with pytest.raises(ValueError, match="out of range"):
        DimensionScore(DEFAULT_DIMENSIONS[0], 26)


def test_score_below_zero_raises() -> None:
    with pytest.raises(ValueError, match="out of range"):
        DimensionScore(DEFAULT_DIMENSIONS[0], -1)


def test_dimension_with_invalid_floor_raises() -> None:
    with pytest.raises(ValueError):
        Dimension("X", max_points=10, hard_fail_floor=11)


def test_improvement_below_threshold_detects_stuck() -> None:
    prev = compute_verdict(
        [
            DimensionScore(DEFAULT_DIMENSIONS[0], 18),
            DimensionScore(DEFAULT_DIMENSIONS[1], 18),
            DimensionScore(DEFAULT_DIMENSIONS[2], 18),
            DimensionScore(DEFAULT_DIMENSIONS[3], 18),
        ],
        _all_pass_tests(),
    )
    curr = compute_verdict(
        [
            DimensionScore(DEFAULT_DIMENSIONS[0], 19),
            DimensionScore(DEFAULT_DIMENSIONS[1], 19),
            DimensionScore(DEFAULT_DIMENSIONS[2], 19),
            DimensionScore(DEFAULT_DIMENSIONS[3], 19),
        ],
        _all_pass_tests(),
    )
    # Improved by 4 (72 → 76), threshold is 5 → STUCK
    assert improvement_below_threshold(prev, curr, threshold_points=5)


def test_improvement_above_threshold_continues() -> None:
    prev = compute_verdict(
        [DimensionScore(DEFAULT_DIMENSIONS[i], 15) for i in range(4)],
        _all_pass_tests(),
    )
    curr = compute_verdict(
        [DimensionScore(DEFAULT_DIMENSIONS[i], 22) for i in range(4)],
        _all_pass_tests(),
    )
    # Improved by 28 (60 → 88) → continues
    assert not improvement_below_threshold(prev, curr, threshold_points=5)


def test_default_dimensions_have_hard_fail_floors() -> None:
    """Per SPEC §5.1, all four default dimensions have hard-fail floors."""
    for d in DEFAULT_DIMENSIONS:
        assert d.hard_fail_floor is not None
        assert d.hard_fail_floor < d.max_points


def test_compute_verdict_with_custom_dimensions() -> None:
    """Skills can substitute domain-specific dimensions."""
    custom = (
        Dimension("Coverage", 30, hard_fail_floor=25),
        Dimension("Depth", 30, hard_fail_floor=20),
        Dimension("Wow", 20, hard_fail_floor=12),
        Dimension("POVRatio", 20, hard_fail_floor=12),
    )
    scores = [DimensionScore(d, d.max_points) for d in custom]
    result = compute_verdict(scores, _all_pass_tests())
    assert result.verdict == Verdict.SHIP
    assert result.quality_max == 100
