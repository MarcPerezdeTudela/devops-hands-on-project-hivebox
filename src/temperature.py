"""Temperature classification rules."""

from enum import StrEnum


class TemperatureStatus(StrEnum):
    """Supported temperature comfort classifications."""

    TOO_COLD = "Too Cold"
    GOOD = "Good"
    TOO_HOT = "Too Hot"


def classify_temperature(temperature: float) -> TemperatureStatus:
    """Classify a temperature using HiveBox comfort thresholds."""
    if temperature < 10:
        return TemperatureStatus.TOO_COLD
    if temperature <= 37:
        return TemperatureStatus.GOOD
    return TemperatureStatus.TOO_HOT
