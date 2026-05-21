"""Rubric scoring and hard-fail enforcement for the eval harness.

Wraps sf-demo-validate's existing 200-point rubric with:
  1. SHIP / ITERATE / SPEC-DEFECT verdict logic
  2. Hard-fail floor enforcement (any dim below floor → ITERATE regardless of total)
  3. Test rubric (binary: unit + integration + smoke/e2e all required)
  4. Improvement-threshold early-stop across iterations

Per SPEC §5.1 and §6, hard-fail dimensions never receive autonomous retries —
they escalate per §6.3 if the orchestrator is involved.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Iterable


class Verdict(str, Enum):
    SHIP = "SHIP"
    ITERATE = "ITERATE"
    SPEC_DEFECT = "SPEC-DEFECT"


@dataclass(frozen=True)
class Dimension:
    """One axis of the quality rubric."""

    name: str
    max_points: int
    hard_fail_floor: int | None = None

    def __post_init__(self) -> None:
        if self.max_points <= 0:
            raise ValueError(f"max_points must be positive: {self.max_points}")
        if self.hard_fail_floor is not None:
            if self.hard_fail_floor < 0 or self.hard_fail_floor > self.max_points:
                raise ValueError(
                    f"hard_fail_floor {self.hard_fail_floor} must be in [0, {self.max_points}]"
                )


@dataclass(frozen=True)
class DimensionScore:
    dimension: Dimension
    score: int
    evidence: str = ""

    def __post_init__(self) -> None:
        if self.score < 0 or self.score > self.dimension.max_points:
            raise ValueError(
                f"score {self.score} out of range for {self.dimension.name} "
                f"(max {self.dimension.max_points})"
            )

    @property
    def hard_fail(self) -> bool:
        floor = self.dimension.hard_fail_floor
        return floor is not None and self.score < floor


@dataclass(frozen=True)
class TestRubric:
    """Binary test rubric — all required for SHIP."""

    # Tell pytest this dataclass is not a test class.
    __test__ = False

    unit_pass: bool
    integration_pass: bool
    smoke_pass: bool

    @property
    def all_pass(self) -> bool:
        return self.unit_pass and self.integration_pass and self.smoke_pass


@dataclass
class RubricResult:
    quality_scores: list[DimensionScore]
    test_rubric: TestRubric
    verdict: Verdict
    spec_defect_reason: str | None = None
    hard_fail_breaches: list[str] = field(default_factory=list)

    @property
    def quality_total(self) -> int:
        return sum(s.score for s in self.quality_scores)

    @property
    def quality_max(self) -> int:
        return sum(s.dimension.max_points for s in self.quality_scores)

    @property
    def quality_pct(self) -> float:
        if self.quality_max == 0:
            return 0.0
        return 100.0 * self.quality_total / self.quality_max


# Default 4-dimension shape from SPEC §5.1.
# sf-demo-validate uses its own 200-pt rubric (see SKILL.md §"Scoring Rubric");
# the harness wraps that rubric by collapsing the 10 base categories into the
# 4 SPEC dimensions for verdict purposes, while preserving full per-category
# detail in the EVAL-REPORT.
DEFAULT_DIMENSIONS = (
    Dimension("Correctness", max_points=25, hard_fail_floor=15),
    Dimension("Robustness", max_points=25, hard_fail_floor=12),
    Dimension("Fit", max_points=25, hard_fail_floor=10),
    Dimension("Performance", max_points=25, hard_fail_floor=12),
)


def compute_verdict(
    quality_scores: Iterable[DimensionScore],
    test_rubric: TestRubric,
    quality_pct_floor: float = 80.0,
    spec_defect_reason: str | None = None,
) -> RubricResult:
    """Compute SHIP / ITERATE / SPEC-DEFECT verdict.

    Order of checks (any failure short-circuits to non-SHIP):
      1. spec_defect_reason set → SPEC-DEFECT
      2. Any hard_fail dimension breached → ITERATE
      3. Test rubric: any required category failing → ITERATE
      4. Quality total < quality_pct_floor → ITERATE
      5. Else → SHIP
    """
    scores = list(quality_scores)

    if spec_defect_reason:
        return RubricResult(
            quality_scores=scores,
            test_rubric=test_rubric,
            verdict=Verdict.SPEC_DEFECT,
            spec_defect_reason=spec_defect_reason,
        )

    hard_fail_breaches = [
        f"{s.dimension.name} scored {s.score} (floor {s.dimension.hard_fail_floor})"
        for s in scores
        if s.hard_fail
    ]

    if hard_fail_breaches:
        return RubricResult(
            quality_scores=scores,
            test_rubric=test_rubric,
            verdict=Verdict.ITERATE,
            hard_fail_breaches=hard_fail_breaches,
        )

    if not test_rubric.all_pass:
        return RubricResult(
            quality_scores=scores,
            test_rubric=test_rubric,
            verdict=Verdict.ITERATE,
        )

    quality_total = sum(s.score for s in scores)
    quality_max = sum(s.dimension.max_points for s in scores)
    pct = 100.0 * quality_total / quality_max if quality_max else 0.0
    if pct < quality_pct_floor:
        return RubricResult(
            quality_scores=scores,
            test_rubric=test_rubric,
            verdict=Verdict.ITERATE,
        )

    return RubricResult(
        quality_scores=scores,
        test_rubric=test_rubric,
        verdict=Verdict.SHIP,
    )


def improvement_below_threshold(
    prev_result: RubricResult,
    curr_result: RubricResult,
    threshold_points: int = 5,
) -> bool:
    """True if curr_result quality total improved by less than threshold_points
    over prev_result. Used by the loop to detect "implementer is stuck"."""
    return (curr_result.quality_total - prev_result.quality_total) < threshold_points
