"""JSON contract loaders and validators for the eval harness.

Each cross-phase artifact (requirements, value-moments, requirement-coverage,
wow-moment-delivery, data-requirements, click-path) has a JSON Schema that
gates whether the producing phase can SHIP. This module loads schemas, loads
contract files, validates them, and exposes link-integrity checks (FK
resolution, no-orphans).
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import jsonschema
except ImportError as e:
    raise ImportError(
        "jsonschema is required. Install via: pip install jsonschema"
    ) from e


SCHEMA_DIR = Path(__file__).parent.parent / "schemas"

CONTRACT_NAMES = (
    "requirements",
    "value-moments",
    "requirement-coverage",
    "wow-moment-delivery",
    "data-requirements",
    "click-path",
)


@dataclass(frozen=True)
class ValidationError:
    contract: str
    path: str
    message: str

    def __str__(self) -> str:
        return f"[{self.contract}] {self.path}: {self.message}"


@dataclass
class ValidationResult:
    contract: str
    valid: bool
    errors: list[ValidationError]

    def __bool__(self) -> bool:
        return self.valid


def load_schema(contract_name: str) -> dict[str, Any]:
    """Load a JSON Schema by contract name (e.g. 'requirements')."""
    if contract_name not in CONTRACT_NAMES:
        raise ValueError(
            f"Unknown contract: {contract_name}. Valid: {CONTRACT_NAMES}"
        )
    schema_path = SCHEMA_DIR / f"{contract_name}.schema.json"
    with schema_path.open() as f:
        return json.load(f)


def load_contract(contract_name: str, contract_path: Path) -> dict[str, Any]:
    """Load a contract JSON file."""
    with contract_path.open() as f:
        return json.load(f)


def validate_contract(
    contract_name: str, contract_data: dict[str, Any]
) -> ValidationResult:
    """Validate a loaded contract against its JSON Schema."""
    schema = load_schema(contract_name)
    validator = jsonschema.Draft7Validator(schema)
    errors = sorted(validator.iter_errors(contract_data), key=lambda e: list(e.path))
    if not errors:
        return ValidationResult(contract=contract_name, valid=True, errors=[])
    return ValidationResult(
        contract=contract_name,
        valid=False,
        errors=[
            ValidationError(
                contract=contract_name,
                path=".".join(str(p) for p in err.path) or "<root>",
                message=err.message,
            )
            for err in errors
        ],
    )


def check_link_integrity(
    requirements: dict[str, Any],
    value_moments: dict[str, Any] | None = None,
    coverage: dict[str, Any] | None = None,
    wow_delivery: dict[str, Any] | None = None,
    data_requirements: dict[str, Any] | None = None,
    click_path: dict[str, Any] | None = None,
) -> list[ValidationError]:
    """Cross-contract FK resolution + no-orphans check.

    Per SPEC §22.3:
      1. Every FK must resolve to an existing ID.
      2. Every must_demo requirement must be referenced by ≥1 value_moment
         and ≥1 coverage entry.
      3. Step IDs referenced in coverage / wow_delivery / data_requirements /
         click_path must be consistent.
    """
    errors: list[ValidationError] = []

    req_ids = {r["id"] for r in requirements["requirements"]}
    must_demo_ids = {
        r["id"] for r in requirements["requirements"] if r["must_demo"]
    }

    if value_moments is not None:
        vm_req_ids = {v["requirement_id"] for v in value_moments["value_moments"]}
        for vm_id in vm_req_ids:
            if vm_id not in req_ids:
                errors.append(
                    ValidationError(
                        "value-moments",
                        "value_moments[].requirement_id",
                        f"FK does not resolve: {vm_id} not in requirements.json",
                    )
                )
        missing = must_demo_ids - vm_req_ids
        for req_id in missing:
            errors.append(
                ValidationError(
                    "value-moments",
                    "value_moments[]",
                    f"orphan: must_demo requirement {req_id} has no value_moment",
                )
            )

    if coverage is not None:
        cov_req_ids = {c["requirement_id"] for c in coverage["coverage"]}
        uncovered_ids = set(coverage.get("uncovered_requirements", []))
        for cov_id in cov_req_ids:
            if cov_id not in req_ids:
                errors.append(
                    ValidationError(
                        "requirement-coverage",
                        "coverage[].requirement_id",
                        f"FK does not resolve: {cov_id} not in requirements.json",
                    )
                )
        for unc_id in uncovered_ids:
            if unc_id not in req_ids:
                errors.append(
                    ValidationError(
                        "requirement-coverage",
                        "uncovered_requirements[]",
                        f"FK does not resolve: {unc_id} not in requirements.json",
                    )
                )
        all_referenced = cov_req_ids | uncovered_ids
        unreferenced_must_demo = must_demo_ids - all_referenced
        for req_id in unreferenced_must_demo:
            errors.append(
                ValidationError(
                    "requirement-coverage",
                    "coverage[]",
                    f"orphan: must_demo requirement {req_id} not in coverage or uncovered list",
                )
            )
        if uncovered_ids and not coverage.get("rationale_for_uncovered"):
            errors.append(
                ValidationError(
                    "requirement-coverage",
                    "rationale_for_uncovered",
                    "uncovered_requirements is non-empty but rationale_for_uncovered is null",
                )
            )

    if click_path is not None:
        step_ids = {s["id"] for s in click_path["steps"]}

        if coverage is not None:
            for cov in coverage["coverage"]:
                for step_id in cov["covered_by_steps"]:
                    if step_id not in step_ids:
                        errors.append(
                            ValidationError(
                                "requirement-coverage",
                                "coverage[].covered_by_steps[]",
                                f"FK does not resolve: {step_id} not in click-path.json",
                            )
                        )

        if wow_delivery is not None:
            for d in wow_delivery["deliveries"]:
                step_refs = (
                    list(d["delivered_in_steps"])
                    + [d["pain_context_beat"]["step"]]
                    + [d["watch_this_cue"]["step"]]
                    + [d["moment_step"]]
                    + [d["narration_beat"]["step"]]
                )
                for step_id in step_refs:
                    if step_id not in step_ids:
                        errors.append(
                            ValidationError(
                                "wow-moment-delivery",
                                "deliveries[].steps",
                                f"FK does not resolve: {step_id} not in click-path.json",
                            )
                        )

        if data_requirements is not None:
            for rec in data_requirements["records"]:
                for step_id in rec["referenced_by_steps"]:
                    if step_id not in step_ids:
                        errors.append(
                            ValidationError(
                                "data-requirements",
                                "records[].referenced_by_steps[]",
                                f"FK does not resolve: {step_id} not in click-path.json",
                            )
                        )

    if wow_delivery is not None and value_moments is not None:
        wow_req_ids = {
            d["value_moment_requirement_id"] for d in wow_delivery["deliveries"]
        }
        vm_req_ids = {v["requirement_id"] for v in value_moments["value_moments"]}
        for wow_id in wow_req_ids:
            if wow_id not in vm_req_ids:
                errors.append(
                    ValidationError(
                        "wow-moment-delivery",
                        "deliveries[].value_moment_requirement_id",
                        f"FK does not resolve: {wow_id} not in value-moments.json",
                    )
                )
        missing = vm_req_ids - wow_req_ids
        for vm_id in missing:
            errors.append(
                ValidationError(
                    "wow-moment-delivery",
                    "deliveries[]",
                    f"orphan: value_moment {vm_id} has no delivery",
                )
            )

    return errors
