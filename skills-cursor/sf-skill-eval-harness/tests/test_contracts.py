"""Unit tests: schema validation + cross-contract link integrity.

These tests are the foundation of the harness — if a contract validates and
all FKs resolve, the rest of the loop has trustworthy inputs.
"""
from __future__ import annotations

from copy import deepcopy

import pytest

from scripts import contracts


def test_all_fixture_contracts_validate(
    requirements,
    value_moments,
    coverage,
    wow_delivery,
    data_requirements,
    click_path,
) -> None:
    """The fixture is the canonical 'good' demo. All six contracts must validate."""
    assert contracts.validate_contract("requirements", requirements).valid
    assert contracts.validate_contract("value-moments", value_moments).valid
    assert contracts.validate_contract("requirement-coverage", coverage).valid
    assert contracts.validate_contract("wow-moment-delivery", wow_delivery).valid
    assert contracts.validate_contract("data-requirements", data_requirements).valid
    assert contracts.validate_contract("click-path", click_path).valid


def test_fixture_link_integrity_clean(
    requirements, value_moments, coverage, wow_delivery, data_requirements, click_path
) -> None:
    """Fixture should have zero link errors when all contracts are present."""
    errors = contracts.check_link_integrity(
        requirements=requirements,
        value_moments=value_moments,
        coverage=coverage,
        wow_delivery=wow_delivery,
        data_requirements=data_requirements,
        click_path=click_path,
    )
    assert errors == [], f"unexpected link errors:\n" + "\n".join(str(e) for e in errors)


def test_unknown_contract_name_raises() -> None:
    with pytest.raises(ValueError, match="Unknown contract"):
        contracts.load_schema("not-a-real-contract")


def test_invalid_requirement_id_pattern_fails(requirements) -> None:
    """REQ ID must match REQ-NNN pattern."""
    bad = deepcopy(requirements)
    bad["requirements"][0]["id"] = "REQUIREMENT-1"
    result = contracts.validate_contract("requirements", bad)
    assert not result.valid


def test_must_demo_orphan_caught(requirements, value_moments) -> None:
    """A must_demo requirement with no value_moment is a hard-fail."""
    bad_vm = deepcopy(value_moments)
    bad_vm["value_moments"] = bad_vm["value_moments"][:-1]  # drop REQ-004's value moment
    errors = contracts.check_link_integrity(
        requirements=requirements, value_moments=bad_vm
    )
    assert any("REQ-004" in str(e) and "orphan" in str(e) for e in errors)


def test_dangling_fk_to_requirements_caught(requirements, value_moments) -> None:
    """value_moments referencing a non-existent REQ id is caught."""
    bad_vm = deepcopy(value_moments)
    bad_vm["value_moments"][0]["requirement_id"] = "REQ-999"
    errors = contracts.check_link_integrity(
        requirements=requirements, value_moments=bad_vm
    )
    assert any("REQ-999" in str(e) and "FK does not resolve" in str(e) for e in errors)


def test_uncovered_requirement_without_rationale_caught(requirements) -> None:
    """Coverage with uncovered_requirements but null rationale is a defect."""
    bad_cov = {
        "version": "1.0",
        "requirements_file": "requirements.json",
        "coverage": [
            {
                "requirement_id": "REQ-001",
                "covered_by_steps": ["step-1"],
                "demonstration_quality": "primary",
            }
        ],
        "uncovered_requirements": ["REQ-002", "REQ-003", "REQ-004"],
        "rationale_for_uncovered": None,
    }
    errors = contracts.check_link_integrity(
        requirements=requirements, coverage=bad_cov
    )
    assert any("rationale_for_uncovered" in str(e) for e in errors)


def test_step_id_in_coverage_must_resolve(
    requirements, coverage, click_path
) -> None:
    """coverage[].covered_by_steps must point to real step IDs in click-path."""
    bad_cov = deepcopy(coverage)
    bad_cov["coverage"][0]["covered_by_steps"] = ["step-999"]
    errors = contracts.check_link_integrity(
        requirements=requirements, coverage=bad_cov, click_path=click_path
    )
    assert any("step-999" in str(e) for e in errors)


def test_wow_delivery_step_must_resolve(
    requirements, value_moments, wow_delivery, click_path
) -> None:
    """All step references inside wow-moment-delivery beats must resolve."""
    bad_wow = deepcopy(wow_delivery)
    bad_wow["deliveries"][0]["pain_context_beat"]["step"] = "step-999"
    errors = contracts.check_link_integrity(
        requirements=requirements,
        value_moments=value_moments,
        wow_delivery=bad_wow,
        click_path=click_path,
    )
    assert any("step-999" in str(e) for e in errors)


def test_value_moments_min_steps_floor() -> None:
    """min_steps below 4 is rejected by schema."""
    bad = {
        "version": "1.0",
        "duration_minutes": 30,
        "duration_budget": {
            "end_user_pov_min_pct": 60,
            "admin_setup_max_pct": 20,
            "narrative_transitions_pct": 20,
        },
        "value_moments": [
            {
                "requirement_id": "REQ-001",
                "min_steps": 3,
                "persona": "X",
                "persona_pain_quote": "0123456789",
                "persona_outcome": "0123456789",
                "wow_moment": {
                    "description": "0123456789",
                    "why_audience_leans_forward": "0123456789",
                    "presenter_cue": "x",
                    "estimated_duration_seconds": 10,
                },
                "anti_demo": [],
                "end_user_pov_steps": 2,
                "admin_pov_steps": 1,
            }
        ],
    }
    result = contracts.validate_contract("value-moments", bad)
    assert not result.valid


def test_wow_moment_duration_floor() -> None:
    """estimated_duration_seconds below 10 is rejected by schema."""
    bad = {
        "version": "1.0",
        "duration_minutes": 30,
        "duration_budget": {
            "end_user_pov_min_pct": 60,
            "admin_setup_max_pct": 20,
            "narrative_transitions_pct": 20,
        },
        "value_moments": [
            {
                "requirement_id": "REQ-001",
                "min_steps": 4,
                "persona": "X",
                "persona_pain_quote": "0123456789",
                "persona_outcome": "0123456789",
                "wow_moment": {
                    "description": "0123456789",
                    "why_audience_leans_forward": "0123456789",
                    "presenter_cue": "x",
                    "estimated_duration_seconds": 5,
                },
                "anti_demo": [],
                "end_user_pov_steps": 2,
                "admin_pov_steps": 1,
            }
        ],
    }
    result = contracts.validate_contract("value-moments", bad)
    assert not result.valid
