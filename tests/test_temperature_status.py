"""Unit tests for temperature status classification."""

import pytest

from src.temperature import TemperatureStatus, classify_temperature


@pytest.mark.parametrize(
    ("temperature", "expected_status"),
    [
        (-5.0, TemperatureStatus.TOO_COLD),
        (9.99, TemperatureStatus.TOO_COLD),
        (10.0, TemperatureStatus.GOOD),
        (10.01, TemperatureStatus.GOOD),
        (25.5, TemperatureStatus.GOOD),
        (36.99, TemperatureStatus.GOOD),
        (37.0, TemperatureStatus.GOOD),
        (37.01, TemperatureStatus.TOO_HOT),
        (50.0, TemperatureStatus.TOO_HOT),
    ],
)
def test_classify_temperature(
    temperature: float,
    expected_status: TemperatureStatus,
) -> None:
    """Classify normal, boundary, and decimal temperatures."""
    assert classify_temperature(temperature) is expected_status
