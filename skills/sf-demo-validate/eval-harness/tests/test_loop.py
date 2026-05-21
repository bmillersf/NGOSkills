"""Unit tests: loop termination decision logic."""
from __future__ import annotations

from scripts.harness import HarnessConfig, HarnessState, LoopController, LoopDecision
from scripts.rubric import (
    DEFAULT_DIMENSIONS,
    DimensionScore,
    RubricResult,
    TestRubric,
    Verdict,
    compute_verdict,
)


def _full_pass() -> TestRubric:
    return TestRubric(True, True, True)


def _ship_result() -> RubricResult:
    return compute_verdict(
        [DimensionScore(d, d.max_points) for d in DEFAULT_DIMENSIONS],
        _full_pass(),
    )


def _iterate_result() -> RubricResult:
    return compute_verdict(
        [DimensionScore(d, 16) for d in DEFAULT_DIMENSIONS],  # 64% < 80
        _full_pass(),
    )


def _hard_fail_result() -> RubricResult:
    return compute_verdict(
        [
            DimensionScore(DEFAULT_DIMENSIONS[0], 12),  # below 15 floor
            DimensionScore(DEFAULT_DIMENSIONS[1], 25),
            DimensionScore(DEFAULT_DIMENSIONS[2], 25),
            DimensionScore(DEFAULT_DIMENSIONS[3], 25),
        ],
        _full_pass(),
    )


def _spec_defect_result() -> RubricResult:
    return compute_verdict(
        [DimensionScore(d, 20) for d in DEFAULT_DIMENSIONS],
        _full_pass(),
        spec_defect_reason="REQ-005 missing",
    )


def test_ship_verdict_terminates() -> None:
    config = HarnessConfig()
    state = HarnessState(iteration=1)
    decision = LoopController(config).decide(state, _ship_result())
    assert decision == LoopDecision.SHIP


def test_hard_fail_breach_escalates_immediately() -> None:
    """Per SPEC §6.3, hard-fail breaches never get autonomous retries."""
    config = HarnessConfig()
    state = HarnessState(iteration=1)
    decision = LoopController(config).decide(state, _hard_fail_result())
    assert decision == LoopDecision.ESCALATE


def test_iteration_cap_escalates() -> None:
    config = HarnessConfig(max_iterations=3)
    state = HarnessState(iteration=3)
    decision = LoopController(config).decide(state, _iterate_result())
    assert decision == LoopDecision.ESCALATE


def test_iterate_under_cap_continues() -> None:
    config = HarnessConfig(max_iterations=3)
    state = HarnessState(iteration=1)
    decision = LoopController(config).decide(state, _iterate_result())
    assert decision == LoopDecision.ITERATE_IMPLEMENTER


def test_spec_defect_with_budget_replans() -> None:
    config = HarnessConfig(per_loop_replan_budget=1)
    state = HarnessState(iteration=1, replans_used_in_loop=0)
    decision = LoopController(config).decide(state, _spec_defect_result())
    assert decision == LoopDecision.REPLAN


def test_spec_defect_without_budget_escalates() -> None:
    config = HarnessConfig(per_loop_replan_budget=1)
    state = HarnessState(iteration=1, replans_used_in_loop=1)
    decision = LoopController(config).decide(state, _spec_defect_result())
    assert decision == LoopDecision.ESCALATE


def test_improvement_below_threshold_escalates() -> None:
    """Stuck implementer triggers ESCALATE rather than infinite iteration."""
    config = HarnessConfig(max_iterations=5, improvement_threshold_points=5)
    state = HarnessState(iteration=2)
    prev = compute_verdict(
        [DimensionScore(d, 16) for d in DEFAULT_DIMENSIONS],  # total 64
        _full_pass(),
    )
    curr = compute_verdict(
        [DimensionScore(d, 17) for d in DEFAULT_DIMENSIONS],  # total 68 (+4 < 5)
        _full_pass(),
    )
    decision = LoopController(config).decide(state, curr, prev)
    assert decision == LoopDecision.ESCALATE


def test_state_serialization_roundtrip(tmp_path) -> None:
    state_path = tmp_path / "state.json"
    state = HarnessState(iteration=2, replans_used_in_loop=1)
    state.rubric_results.append({"iteration": 1, "verdict": "ITERATE"})
    state.save(state_path)
    loaded = HarnessState.load(state_path)
    assert loaded.iteration == 2
    assert loaded.replans_used_in_loop == 1
    assert loaded.rubric_results == [{"iteration": 1, "verdict": "ITERATE"}]


def test_load_missing_state_returns_default(tmp_path) -> None:
    missing = tmp_path / "does-not-exist.json"
    state = HarnessState.load(missing)
    assert state.iteration == 0
    assert state.replans_used_in_loop == 0
