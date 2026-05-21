"""Shared pytest fixtures for the eval harness test suite."""
from __future__ import annotations

import sys
from pathlib import Path

# Add the eval-harness directory to sys.path so `from scripts import ...`
# works when pytest is run from the repo root or anywhere else.
_HARNESS_ROOT = Path(__file__).parent.parent
if str(_HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(_HARNESS_ROOT))

import json

import pytest

FIXTURE_DIR = _HARNESS_ROOT / "fixtures" / "simple-volunteer-demo"


@pytest.fixture
def fixture_dir() -> Path:
    return FIXTURE_DIR


@pytest.fixture
def requirements() -> dict:
    return json.loads((FIXTURE_DIR / "requirements.json").read_text())


@pytest.fixture
def value_moments() -> dict:
    return json.loads((FIXTURE_DIR / "value-moments.json").read_text())


@pytest.fixture
def coverage() -> dict:
    return json.loads((FIXTURE_DIR / "requirement-coverage.json").read_text())


@pytest.fixture
def wow_delivery() -> dict:
    return json.loads((FIXTURE_DIR / "wow-moment-delivery.json").read_text())


@pytest.fixture
def data_requirements() -> dict:
    return json.loads((FIXTURE_DIR / "data-requirements.json").read_text())


@pytest.fixture
def click_path() -> dict:
    return json.loads((FIXTURE_DIR / "click-path.json").read_text())
