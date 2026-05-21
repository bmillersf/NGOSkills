"""Append-only TRACE.md writer.

Per SPEC §7 and §22.2, TRACE.md is the primary debugging loop for harness runs.
One row per subagent invocation. Append-only — never rewritten.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal


Role = Literal["planner", "implementer", "evaluator"]


@dataclass(frozen=True)
class TraceRow:
    timestamp: str
    iteration: int
    role: Role
    verdict: str
    quality_score: str
    hard_fail: str
    tests: str
    artifact_delta: str
    notes: str

    def render(self) -> str:
        cells = [
            self.timestamp,
            str(self.iteration),
            self.role,
            self.verdict,
            self.quality_score,
            self.hard_fail,
            self.tests,
            self.artifact_delta,
            self.notes,
        ]
        return "| " + " | ".join(_escape_cell(c) for c in cells) + " |"


def _escape_cell(value: str) -> str:
    return value.replace("|", r"\|").replace("\n", " ")


_HEADER = (
    "| timestamp | iter | role | verdict | quality | hard-fail | tests | "
    "artifact-delta | notes |"
)
_DIVIDER = "|---|---|---|---|---|---|---|---|---|"


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M")


class TraceWriter:
    """Manages TRACE.md for one harness invocation.

    Creates the file with a header on first append; appends rows to existing
    files. Use with the path to .eval-harness/TRACE.md.
    """

    def __init__(self, path: Path):
        self.path = path

    def append(self, row: TraceRow) -> None:
        existed = self.path.exists()
        with self.path.open("a") as f:
            if not existed:
                f.write(self._initial_header())
            f.write(row.render() + "\n")

    def append_many(self, rows: list[TraceRow]) -> None:
        for row in rows:
            self.append(row)

    @staticmethod
    def _initial_header() -> str:
        return f"# Eval Harness Trace\n\n{_HEADER}\n{_DIVIDER}\n"

    def read(self) -> str:
        if not self.path.exists():
            return ""
        return self.path.read_text()
