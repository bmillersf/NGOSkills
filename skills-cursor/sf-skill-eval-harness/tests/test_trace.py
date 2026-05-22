"""Unit tests: TRACE.md writer."""
from __future__ import annotations

from pathlib import Path

from scripts.trace import TraceRow, TraceWriter, now_iso


def test_trace_writer_creates_file_with_header(tmp_path: Path) -> None:
    trace_path = tmp_path / "TRACE.md"
    writer = TraceWriter(trace_path)
    row = TraceRow(
        timestamp="2026-05-21T14:00",
        iteration=1,
        role="planner",
        verdict="SPEC-WRITTEN",
        quality_score="—",
        hard_fail="—",
        tests="—",
        artifact_delta="spec.md +120 lines",
        notes="first plan",
    )
    writer.append(row)
    content = trace_path.read_text()
    assert "# Eval Harness Trace" in content
    assert "| timestamp |" in content
    assert "spec.md +120 lines" in content


def test_trace_writer_appends_without_duplicate_header(tmp_path: Path) -> None:
    trace_path = tmp_path / "TRACE.md"
    writer = TraceWriter(trace_path)
    for i in range(3):
        writer.append(
            TraceRow(
                timestamp=f"2026-05-21T14:{i:02d}",
                iteration=i + 1,
                role="evaluator",
                verdict="ITERATE",
                quality_score=f"{60 + i}/100",
                hard_fail="—",
                tests="unit:p, int:p, smoke:p",
                artifact_delta="—",
                notes=f"iter {i + 1}",
            )
        )
    content = trace_path.read_text()
    assert content.count("# Eval Harness Trace") == 1
    assert content.count("| timestamp |") == 1
    assert content.count("| evaluator |") == 3


def test_trace_writer_escapes_pipes(tmp_path: Path) -> None:
    """Cell content with literal '|' must be escaped to preserve table structure."""
    trace_path = tmp_path / "TRACE.md"
    writer = TraceWriter(trace_path)
    writer.append(
        TraceRow(
            timestamp="2026-05-21T14:00",
            iteration=1,
            role="evaluator",
            verdict="ITERATE",
            quality_score="60/100",
            hard_fail="—",
            tests="—",
            artifact_delta="—",
            notes="trigger fired before |update| operation",
        )
    )
    content = trace_path.read_text()
    table_rows = [
        line for line in content.splitlines() if line.startswith("| 2026-")
    ]
    assert len(table_rows) == 1
    # Count unescaped pipes only (escaped pipes are literal content): 9 cells = 10 cell separators.
    unescaped_pipes = table_rows[0].replace(r"\|", "").count("|")
    assert unescaped_pipes == 10
    # Also confirm the literal pipes inside the note survived as escaped sequences.
    assert r"\|update\|" in table_rows[0]


def test_trace_writer_escapes_newlines(tmp_path: Path) -> None:
    """Multi-line notes must collapse to single line."""
    trace_path = tmp_path / "TRACE.md"
    writer = TraceWriter(trace_path)
    writer.append(
        TraceRow(
            timestamp="2026-05-21T14:00",
            iteration=1,
            role="evaluator",
            verdict="ITERATE",
            quality_score="—",
            hard_fail="—",
            tests="—",
            artifact_delta="—",
            notes="line 1\nline 2",
        )
    )
    table_rows = [
        line for line in trace_path.read_text().splitlines() if line.startswith("| 2026-")
    ]
    assert len(table_rows) == 1


def test_now_iso_format() -> None:
    iso = now_iso()
    # YYYY-MM-DDTHH:MM
    assert len(iso) == 16
    assert iso[4] == "-" and iso[7] == "-" and iso[10] == "T" and iso[13] == ":"
