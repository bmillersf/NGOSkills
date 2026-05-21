"""CLI entry point for the eval harness.

Subcommands:
  validate-contracts   Validate all six JSON contracts in .eval-harness/
  score                Compute verdict from rubric inputs (JSON on stdin)
  trace-append         Append a row to TRACE.md
  loop-decide          Print the next loop decision given state + latest result

This CLI is invoked by the skill's harness orchestration in SKILL.md, by tests,
and by the user directly when debugging. It is *not* a substitute for the
subagent prompts — the LLM-driven roles (planner, implementer, evaluator) live
in the skill markdown.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import contracts as contracts_mod
from . import rubric as rubric_mod
from . import trace as trace_mod
from .harness import HarnessConfig, HarnessState, LoopController


def _cmd_validate_contracts(args: argparse.Namespace) -> int:
    harness_dir = Path(args.harness_dir)
    if not harness_dir.exists():
        print(f"error: {harness_dir} does not exist", file=sys.stderr)
        return 2

    loaded: dict[str, dict] = {}
    schema_errors: list[contracts_mod.ValidationError] = []

    for name in contracts_mod.CONTRACT_NAMES:
        contract_path = harness_dir / f"{name}.json"
        if not contract_path.exists():
            if args.strict:
                print(f"error: {contract_path} missing (--strict)", file=sys.stderr)
                return 1
            continue
        data = contracts_mod.load_contract(name, contract_path)
        result = contracts_mod.validate_contract(name, data)
        if not result.valid:
            schema_errors.extend(result.errors)
        else:
            loaded[name] = data

    link_errors: list[contracts_mod.ValidationError] = []
    if "requirements" in loaded:
        link_errors = contracts_mod.check_link_integrity(
            requirements=loaded["requirements"],
            value_moments=loaded.get("value-moments"),
            coverage=loaded.get("requirement-coverage"),
            wow_delivery=loaded.get("wow-moment-delivery"),
            data_requirements=loaded.get("data-requirements"),
            click_path=loaded.get("click-path"),
        )

    all_errors = schema_errors + link_errors
    if all_errors:
        for err in all_errors:
            print(str(err), file=sys.stderr)
        return 1

    print(f"OK: {len(loaded)} contract(s) valid, link integrity OK")
    return 0


def _cmd_score(args: argparse.Namespace) -> int:
    payload = json.load(sys.stdin)

    dim_specs = payload.get("dimensions") or [
        {
            "name": d.name,
            "max_points": d.max_points,
            "hard_fail_floor": d.hard_fail_floor,
        }
        for d in rubric_mod.DEFAULT_DIMENSIONS
    ]
    dim_by_name = {
        d["name"]: rubric_mod.Dimension(
            name=d["name"],
            max_points=d["max_points"],
            hard_fail_floor=d.get("hard_fail_floor"),
        )
        for d in dim_specs
    }
    scores = [
        rubric_mod.DimensionScore(
            dimension=dim_by_name[s["name"]],
            score=s["score"],
            evidence=s.get("evidence", ""),
        )
        for s in payload["scores"]
    ]
    test_rubric = rubric_mod.TestRubric(
        unit_pass=payload["tests"]["unit_pass"],
        integration_pass=payload["tests"]["integration_pass"],
        smoke_pass=payload["tests"]["smoke_pass"],
    )
    result = rubric_mod.compute_verdict(
        quality_scores=scores,
        test_rubric=test_rubric,
        quality_pct_floor=payload.get("quality_pct_floor", 80.0),
        spec_defect_reason=payload.get("spec_defect_reason"),
    )
    out = {
        "verdict": result.verdict.value,
        "quality_total": result.quality_total,
        "quality_max": result.quality_max,
        "quality_pct": round(result.quality_pct, 2),
        "hard_fail_breaches": result.hard_fail_breaches,
        "spec_defect_reason": result.spec_defect_reason,
    }
    print(json.dumps(out, indent=2))
    return 0 if result.verdict == rubric_mod.Verdict.SHIP else 1


def _cmd_trace_append(args: argparse.Namespace) -> int:
    row = trace_mod.TraceRow(
        timestamp=args.timestamp or trace_mod.now_iso(),
        iteration=args.iteration,
        role=args.role,
        verdict=args.verdict,
        quality_score=args.quality or "—",
        hard_fail=args.hard_fail or "—",
        tests=args.tests or "—",
        artifact_delta=args.artifact_delta or "—",
        notes=args.notes or "",
    )
    writer = trace_mod.TraceWriter(Path(args.trace_path))
    writer.append(row)
    return 0


def _cmd_loop_decide(args: argparse.Namespace) -> int:
    payload = json.load(sys.stdin)
    config = HarnessConfig(**payload.get("config", {}))
    state = HarnessState.from_dict(payload.get("state", {}))

    def _result(d: dict) -> rubric_mod.RubricResult:
        dims = {
            sp["name"]: rubric_mod.Dimension(
                sp["name"], sp["max_points"], sp.get("hard_fail_floor")
            )
            for sp in d.get("dimensions", [])
        }
        return rubric_mod.RubricResult(
            quality_scores=[
                rubric_mod.DimensionScore(
                    dimension=dims[s["name"]],
                    score=s["score"],
                )
                for s in d.get("scores", [])
            ],
            test_rubric=rubric_mod.TestRubric(**d["tests"]),
            verdict=rubric_mod.Verdict(d["verdict"]),
            spec_defect_reason=d.get("spec_defect_reason"),
            hard_fail_breaches=d.get("hard_fail_breaches", []),
        )

    latest = _result(payload["latest"])
    prev = _result(payload["prev"]) if payload.get("prev") else None

    decision = LoopController(config).decide(state, latest, prev)
    print(json.dumps({"decision": decision.value}))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="eval-harness")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_validate = sub.add_parser("validate-contracts")
    p_validate.add_argument(
        "--harness-dir",
        default=".eval-harness",
        help="Directory containing the contract JSON files (default: .eval-harness)",
    )
    p_validate.add_argument(
        "--strict",
        action="store_true",
        help="Fail if any of the six expected contract files are missing",
    )
    p_validate.set_defaults(func=_cmd_validate_contracts)

    p_score = sub.add_parser("score")
    p_score.set_defaults(func=_cmd_score)

    p_trace = sub.add_parser("trace-append")
    p_trace.add_argument("--trace-path", required=True)
    p_trace.add_argument("--iteration", type=int, required=True)
    p_trace.add_argument("--role", required=True, choices=["planner", "implementer", "evaluator"])
    p_trace.add_argument("--verdict", required=True)
    p_trace.add_argument("--timestamp")
    p_trace.add_argument("--quality")
    p_trace.add_argument("--hard-fail")
    p_trace.add_argument("--tests")
    p_trace.add_argument("--artifact-delta")
    p_trace.add_argument("--notes")
    p_trace.set_defaults(func=_cmd_trace_append)

    p_loop = sub.add_parser("loop-decide")
    p_loop.set_defaults(func=_cmd_loop_decide)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
