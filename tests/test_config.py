"""Unit tests for HiveBox environment configuration."""

import os
import subprocess
import sys

import pytest

from src.config import (
    DEFAULT_SENSEBOX_IDS,
    SENSEBOX_IDS_ENV_VAR,
    ConfigurationError,
    load_sensebox_ids,
)

FIRST_SENSEBOX_ID = "5eba5fbad46fb8001b799786"
SECOND_SENSEBOX_ID = "5c21ff8f919bf8001adf2488"


def test_load_sensebox_ids_uses_defaults_when_variable_is_absent() -> None:
    """Preserve the local-development defaults when no value is supplied."""
    assert load_sensebox_ids({}) == DEFAULT_SENSEBOX_IDS


def test_load_sensebox_ids_parses_and_trims_valid_values() -> None:
    """Return configured IDs in order after removing surrounding whitespace."""
    configured_ids = f" {FIRST_SENSEBOX_ID}, {SECOND_SENSEBOX_ID.upper()} "

    assert load_sensebox_ids({SENSEBOX_IDS_ENV_VAR: configured_ids}) == (
        FIRST_SENSEBOX_ID,
        SECOND_SENSEBOX_ID.upper(),
    )


@pytest.mark.parametrize("configured_ids", ["", "   "])
def test_load_sensebox_ids_rejects_empty_configuration(
    configured_ids: str,
) -> None:
    """Reject an explicitly supplied list that contains no IDs."""
    with pytest.raises(
        ConfigurationError,
        match=r"HIVEBOX_SENSEBOX_IDS must not be empty",
    ):
        load_sensebox_ids({SENSEBOX_IDS_ENV_VAR: configured_ids})


@pytest.mark.parametrize(
    "configured_ids",
    [
        f",{FIRST_SENSEBOX_ID}",
        f"{FIRST_SENSEBOX_ID},",
        f"{FIRST_SENSEBOX_ID},,{SECOND_SENSEBOX_ID}",
    ],
)
def test_load_sensebox_ids_rejects_empty_elements(configured_ids: str) -> None:
    """Reject leading, trailing, and consecutive delimiters."""
    with pytest.raises(
        ConfigurationError,
        match=r"HIVEBOX_SENSEBOX_IDS contains an empty senseBox ID",
    ):
        load_sensebox_ids({SENSEBOX_IDS_ENV_VAR: configured_ids})


@pytest.mark.parametrize(
    "invalid_id",
    [
        "5eba5fbad46fb8001b79978",
        "5eba5fbad46fb8001b7997860",
        "5eba5fbad46fb8001b79978g",
    ],
)
def test_load_sensebox_ids_rejects_malformed_ids(invalid_id: str) -> None:
    """Require exactly 24 hexadecimal characters for every senseBox ID."""
    with pytest.raises(
        ConfigurationError,
        match=rf"HIVEBOX_SENSEBOX_IDS contains an invalid senseBox ID: '{invalid_id}'",
    ):
        load_sensebox_ids({SENSEBOX_IDS_ENV_VAR: invalid_id})


@pytest.mark.parametrize(
    "duplicate_id",
    [FIRST_SENSEBOX_ID, FIRST_SENSEBOX_ID.upper()],
)
def test_load_sensebox_ids_rejects_case_insensitive_duplicates(
    duplicate_id: str,
) -> None:
    """Prevent duplicate senseBoxes from receiving extra averaging weight."""
    configured_ids = f"{FIRST_SENSEBOX_ID},{duplicate_id}"

    with pytest.raises(
        ConfigurationError,
        match=rf"HIVEBOX_SENSEBOX_IDS contains a duplicate senseBox ID: '{duplicate_id}'",
    ):
        load_sensebox_ids({SENSEBOX_IDS_ENV_VAR: configured_ids})


def test_invalid_configuration_prevents_application_import() -> None:
    """Fail application startup when an explicit configuration is invalid."""
    environment = os.environ.copy()
    environment[SENSEBOX_IDS_ENV_VAR] = "invalid"

    result = subprocess.run(
        [sys.executable, "-c", "from src.main import app"],
        check=False,
        capture_output=True,
        env=environment,
        text=True,
    )

    assert result.returncode != 0
    assert "ConfigurationError" in result.stderr
    assert SENSEBOX_IDS_ENV_VAR in result.stderr
    assert "invalid senseBox ID: 'invalid'" in result.stderr
