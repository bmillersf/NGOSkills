"""Three-agent loop orchestrator.

The loop drives planner → implementer → evaluator with structured handoffs
and termination per SPEC §6. This module is the *control flow* — the actual
subagent invocations are wired in by the calling skill (sf-demo-validate)
using its existing playbooks.

Public surface:
  - HarnessConfig: declarative config (max_iterations, improvement_threshold, etc.)
  - HarnessState: durable state across iterations (.eval-harness/state.json)
  - LoopController: pure decision logic — given prior results, what next?

The LoopController is deliberately I/O-free so it's trivially unit-testable.
The actual orchestration (writing files, calling subagents) lives in the skill
markdown — Python here only owns: contract validation, scoring math, trace,
and loop termination decisions.
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from enum import Enum
from pathlib import Path

from .rubric import RubricResult, Verdict, improvement_below_threshold


class LoopDecision(str, Enum):
    """Next action the harness should take."""

    SHIP = "SHIP"
    ITERATE_IMPLEMENTER = "ITERATE_IMPLEMENTER"
    REPLAN = "REPLAN"
    ESCALATE = "ESCALATE"


@dataclass(frozen=True)
class HarnessConfig:
    """Loaded from skill SKILL.md eval_harness frontmatter."""

    max_iterations: int = 3
    improvement_threshold_points: int = 5
    quality_pct_floor: float = 80.0
    per_loop_replan_budget: int = 1
    global_replan_budget: int | None = None


@dataclass
class HarnessState:
    """Durable state across iterations of one harness invocation."""

    iteration: int = 0
    replans_used_in_loop: int = 0
    rubric_results: list[dict] = field(default_factory=list)

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict) -> "HarnessState":
        return cls(
            iteration=data.get("iteration", 0),
            replans_used_in_loop=data.get("replans_used_in_loop", 0),
            rubric_results=list(data.get("rubric_results", [])),
        )

    @classmethod
    def load(cls, state_path: Path) -> "HarnessState":
        if not state_path.exists():
            return cls()
        with state_path.open() as f:
            return cls.from_dict(json.load(f))

    def save(self, state_path: Path) -> None:
        state_path.parent.mkdir(parents=True, exist_ok=True)
        with state_path.open("w") as f:
            json.dump(self.to_dict(), f, indent=2)


@dataclass(frozen=True)
class LoopController:
    """Pure decision logic — what should the loop do next?"""

    config: HarnessConfig

    def decide(
        self,
        state: HarnessState,
        latest_result: RubricResult,
        prev_result: RubricResult | None = None,
    ) -> LoopDecision:
        """Decide the next action given current state and the latest evaluator result.

        Termination per SPEC §6:
          1. SHIP → done.
          2. SPEC-DEFECT with replan budget remaining → REPLAN.
          3. SPEC-DEFECT with no budget → ESCALATE.
          4. ITERATE with hard-fail breach → ESCALATE (per §6.3, hard-fails
             never get autonomous retries).
          5. ITERATE at iteration cap → ESCALATE.
          6. ITERATE with improvement-below-threshold → ESCALATE (stuck).
          7. ITERATE otherwise → ITERATE_IMPLEMENTER.
        """
        if latest_result.verdict == Verdict.SHIP:
            return LoopDecision.SHIP

        if latest_result.verdict == Verdict.SPEC_DEFECT:
            if state.replans_used_in_loop < self.config.per_loop_replan_budget:
                return LoopDecision.REPLAN
            return LoopDecision.ESCALATE

        if latest_result.hard_fail_breaches:
            return LoopDecision.ESCALATE

        if state.iteration >= self.config.max_iterations:
            return LoopDecision.ESCALATE

        if prev_result is not None and improvement_below_threshold(
            prev_result, latest_result, self.config.improvement_threshold_points
        ):
            return LoopDecision.ESCALATE

        return LoopDecision.ITERATE_IMPLEMENTER
