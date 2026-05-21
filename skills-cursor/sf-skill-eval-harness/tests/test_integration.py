"""Integration tests: end-to-end harness loop on the simple-volunteer-demo fixture.

These are deterministic integration tests — they exercise the full file-based
loop without invoking an LLM. The fixture stands in for the implementer's
output; the test simulates evaluator decisions to drive each branch of the
loop controller.

Real-world LLM-driven runs are not unit-tested; they are exercised by the
pilot success-metric run (separate task #2 in the task list).
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

from scripts import contracts
from scripts.harness import HarnessConfig, HarnessState, LoopController, LoopDecision
from scripts.rubric import (
    DEFAULT_DIMENSIONS,
    DimensionScore,
    TestRubric,
    Verdict,
    compute_verdict,
)
from scripts.trace import TraceRow, TraceWriter, now_iso


HARNESS_ROOT = Path(__file__).parent.parent


def _copy_fixture_to(dest: Path, fixture_dir: Path) -> None:
    """Copy the six contract files from the fixture into dest."""
    dest.mkdir(parents=True, exist_ok=True)
    for name in contracts.CONTRACT_NAMES:
        src = fixture_dir / f"{name}.json"
        if src.exists():
            (dest / f"{name}.json").write_text(src.read_text())


def test_fixture_contracts_pass_cli_validation(tmp_path, fixture_dir) -> None:
    """The fixture's six contract files validate end-to-end via the CLI."""
    harness_dir = tmp_path / ".eval-harness"
    _copy_fixture_to(harness_dir, fixture_dir)

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "scripts.cli",
            "validate-contracts",
            "--harness-dir",
            str(harness_dir),
            "--strict",
        ],
        cwd=HARNESS_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (
        f"CLI validation failed.\nstdout: {result.stdout}\nstderr: {result.stderr}"
    )
    assert "OK" in result.stdout


def test_full_loop_ships_on_iteration_2(tmp_path) -> None:
    """Simulated 2-iteration loop where iter1 ITERATEs and iter2 SHIPs."""
    harness_dir = tmp_path / ".eval-harness"
    harness_dir.mkdir()
    state_path = harness_dir / "state.json"
    trace_path = harness_dir / "TRACE.md"
    writer = TraceWriter(trace_path)
    config = HarnessConfig(max_iterations=3)
    controller = LoopController(config)

    state = HarnessState.load(state_path)
    state.iteration = 1
    iter1 = compute_verdict(
        [DimensionScore(d, 18) for d in DEFAULT_DIMENSIONS],  # 72% — below 80
        TestRubric(True, True, True),
    )
    writer.append(
        TraceRow(
            now_iso(), 1, "evaluator", iter1.verdict.value,
            f"{iter1.quality_total}/{iter1.quality_max}", "—",
            "unit:p, int:p, smoke:p", "—", "below quality floor",
        )
    )
    decision = controller.decide(state, iter1)
    assert decision == LoopDecision.ITERATE_IMPLEMENTER

    state.iteration = 2
    state.rubric_results.append({"verdict": iter1.verdict.value})
    iter2 = compute_verdict(
        [DimensionScore(d, 22) for d in DEFAULT_DIMENSIONS],  # 88% — above floor
        TestRubric(True, True, True),
    )
    writer.append(
        TraceRow(
            now_iso(), 2, "evaluator", iter2.verdict.value,
            f"{iter2.quality_total}/{iter2.quality_max}", "—",
            "unit:p, int:p, smoke:p", "—", "ship",
        )
    )
    decision = controller.decide(state, iter2, prev_result=iter1)
    assert decision == LoopDecision.SHIP

    state.save(state_path)

    trace_content = trace_path.read_text()
    assert "# Eval Harness Trace" in trace_content
    assert "iter | role" in trace_content or "| iter |" in trace_content
    assert trace_content.count("| evaluator |") == 2

    saved_state = HarnessState.load(state_path)
    assert saved_state.iteration == 2


def test_hard_fail_escalates_immediately_in_full_loop(tmp_path) -> None:
    """A hard-fail breach on iteration 1 escalates without consuming retries."""
    harness_dir = tmp_path / ".eval-harness"
    harness_dir.mkdir()
    config = HarnessConfig(max_iterations=3)
    controller = LoopController(config)

    state = HarnessState(iteration=1)
    iter1 = compute_verdict(
        [
            DimensionScore(DEFAULT_DIMENSIONS[0], 14),  # below 15 floor
            DimensionScore(DEFAULT_DIMENSIONS[1], 25),
            DimensionScore(DEFAULT_DIMENSIONS[2], 25),
            DimensionScore(DEFAULT_DIMENSIONS[3], 25),
        ],
        TestRubric(True, True, True),
    )
    decision = controller.decide(state, iter1)
    assert decision == LoopDecision.ESCALATE
    assert iter1.hard_fail_breaches != []


def test_spec_defect_replan_then_ship(tmp_path) -> None:
    """SPEC-DEFECT on iter1, replan, SHIP on iter2."""
    config = HarnessConfig(max_iterations=3, per_loop_replan_budget=1)
    controller = LoopController(config)

    state = HarnessState(iteration=1, replans_used_in_loop=0)
    iter1 = compute_verdict(
        [DimensionScore(d, 22) for d in DEFAULT_DIMENSIONS],
        TestRubric(True, True, True),
        spec_defect_reason="REQ-005 absent from requirements.json",
    )
    decision1 = controller.decide(state, iter1)
    assert decision1 == LoopDecision.REPLAN

    # After replan: budget consumed, fresh planner, fresh implementer
    state.replans_used_in_loop = 1
    state.iteration = 2
    iter2 = compute_verdict(
        [DimensionScore(d, d.max_points) for d in DEFAULT_DIMENSIONS],
        TestRubric(True, True, True),
    )
    decision2 = controller.decide(state, iter2)
    assert decision2 == LoopDecision.SHIP


def test_spec_defect_with_replan_budget_exhausted_escalates(tmp_path) -> None:
    """Second SPEC-DEFECT in same loop escalates instead of replanning again."""
    config = HarnessConfig(per_loop_replan_budget=1)
    controller = LoopController(config)

    state = HarnessState(iteration=2, replans_used_in_loop=1)
    iter2 = compute_verdict(
        [DimensionScore(d, 22) for d in DEFAULT_DIMENSIONS],
        TestRubric(True, True, True),
        spec_defect_reason="second defect",
    )
    decision = controller.decide(state, iter2)
    assert decision == LoopDecision.ESCALATE


def test_score_cli_returns_non_zero_on_iterate(tmp_path) -> None:
    """The score CLI exits 1 when verdict is ITERATE — useful for shell pipelines."""
    payload = {
        "scores": [
            {"name": "Correctness", "score": 14},
            {"name": "Robustness", "score": 25},
            {"name": "Fit", "score": 25},
            {"name": "Performance", "score": 25},
        ],
        "tests": {"unit_pass": True, "integration_pass": True, "smoke_pass": True},
    }
    result = subprocess.run(
        [sys.executable, "-m", "scripts.cli", "score"],
        cwd=HARNESS_ROOT,
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    out = json.loads(result.stdout)
    assert out["verdict"] == "ITERATE"
    assert "Correctness" in out["hard_fail_breaches"][0]
    assert result.returncode == 1


def test_score_cli_returns_zero_on_ship() -> None:
    payload = {
        "scores": [
            {"name": "Correctness", "score": 22},
            {"name": "Robustness", "score": 22},
            {"name": "Fit", "score": 22},
            {"name": "Performance", "score": 22},
        ],
        "tests": {"unit_pass": True, "integration_pass": True, "smoke_pass": True},
    }
    result = subprocess.run(
        [sys.executable, "-m", "scripts.cli", "score"],
        cwd=HARNESS_ROOT,
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    out = json.loads(result.stdout)
    assert out["verdict"] == "SHIP"
    assert result.returncode == 0
