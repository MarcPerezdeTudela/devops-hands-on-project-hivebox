"""HiveBox application configuration."""

import os
import re
from collections.abc import Mapping

SENSEBOX_IDS_ENV_VAR = "HIVEBOX_SENSEBOX_IDS"
DEFAULT_SENSEBOX_IDS = (
    "5eba5fbad46fb8001b799786",
    "5c21ff8f919bf8001adf2488",
    "5ade1acf223bd80019a1011c",
)
_SENSEBOX_ID_PATTERN = re.compile(r"[0-9a-fA-F]{24}")


class ConfigurationError(ValueError):
    """Raised when HiveBox receives invalid application configuration."""


def load_sensebox_ids(
    environment: Mapping[str, str] | None = None,
) -> tuple[str, ...]:
    """Load and validate senseBox IDs from the process environment."""
    source = os.environ if environment is None else environment
    if SENSEBOX_IDS_ENV_VAR not in source:
        return DEFAULT_SENSEBOX_IDS

    configured_value = source[SENSEBOX_IDS_ENV_VAR]
    if not configured_value.strip():
        raise ConfigurationError(f"{SENSEBOX_IDS_ENV_VAR} must not be empty")

    sensebox_ids = tuple(
        sensebox_id.strip() for sensebox_id in configured_value.split(",")
    )
    if any(not sensebox_id for sensebox_id in sensebox_ids):
        raise ConfigurationError(
            f"{SENSEBOX_IDS_ENV_VAR} contains an empty senseBox ID"
        )

    seen_ids: set[str] = set()
    for sensebox_id in sensebox_ids:
        if _SENSEBOX_ID_PATTERN.fullmatch(sensebox_id) is None:
            raise ConfigurationError(
                f"{SENSEBOX_IDS_ENV_VAR} contains an invalid senseBox ID: "
                f"'{sensebox_id}'"
            )

        normalized_id = sensebox_id.casefold()
        if normalized_id in seen_ids:
            raise ConfigurationError(
                f"{SENSEBOX_IDS_ENV_VAR} contains a duplicate senseBox ID: "
                f"'{sensebox_id}'"
            )
        seen_ids.add(normalized_id)

    return sensebox_ids


SENSEBOX_IDS = load_sensebox_ids()
