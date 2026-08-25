"""Unit tests for the average temperature endpoint."""

from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from pytest_httpx import HTTPXMock

from src.config import SENSEBOX_IDS
from src.opensensemap import OPEN_SENSE_MAP_BOX_URL

pytestmark = pytest.mark.anyio


def _measurement(value: float, measured_at: datetime) -> dict[str, str]:
    """Build an openSenseMap measurement payload."""
    return {
        "createdAt": measured_at.isoformat(),
        "value": str(value),
    }


def _sensebox_payload(
    temperature: float | None,
    measured_at: datetime | None,
    *,
    include_soil_temperature: bool = False,
) -> dict[str, list[dict[str, Any]]]:
    """Build the relevant subset of an openSenseMap senseBox response."""
    sensors: list[dict[str, Any]] = []
    ambient_sensor: dict[str, Any] = {
        "title": "Temperatur",
        "unit": "°C",
    }
    if temperature is not None and measured_at is not None:
        ambient_sensor["lastMeasurement"] = _measurement(
            temperature,
            measured_at,
        )
    sensors.append(ambient_sensor)

    if include_soil_temperature:
        sensors.append(
            {
                "title": "Bodentemperatur",
                "unit": "°C",
                "lastMeasurement": _measurement(99.0, datetime.now(UTC)),
            }
        )

    return {"sensors": sensors}


def _mock_senseboxes(
    httpx_mock: HTTPXMock,
    payloads: tuple[dict[str, Any], ...],
) -> None:
    """Register one mocked openSenseMap response per configured senseBox."""
    for box_id, payload in zip(SENSEBOX_IDS, payloads, strict=True):
        httpx_mock.add_response(
            url=OPEN_SENSE_MAP_BOX_URL.format(box_id=box_id),
            json=payload,
        )


async def test_get_average_temperature(
    api_client: httpx.AsyncClient,
    httpx_mock: HTTPXMock,
) -> None:
    """Average fresh ambient readings and exclude soil temperature."""
    fresh_time = datetime.now(UTC) - timedelta(minutes=5)
    _mock_senseboxes(
        httpx_mock,
        (
            _sensebox_payload(10.0, fresh_time),
            _sensebox_payload(
                20.0,
                fresh_time,
                include_soil_temperature=True,
            ),
            _sensebox_payload(30.0, fresh_time),
        ),
    )

    response = await api_client.get("/temperature")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {
        "average_temperature": 20.0,
        "unit": "°C",
        "status": "Good",
    }


async def test_temperature_rejects_stale_measurements(
    api_client: httpx.AsyncClient,
    httpx_mock: HTTPXMock,
) -> None:
    """Return 503 when every ambient measurement is older than one hour."""
    stale_time = datetime.now(UTC) - timedelta(hours=2)
    _mock_senseboxes(
        httpx_mock,
        tuple(
            _sensebox_payload(temperature, stale_time)
            for temperature in (10.0, 20.0, 30.0)
        ),
    )

    response = await api_client.get("/temperature")

    assert response.status_code == 503
    assert response.json() == {
        "detail": "No temperature measurements from the last hour are available"
    }


async def test_temperature_handles_missing_measurements(
    api_client: httpx.AsyncClient,
    httpx_mock: HTTPXMock,
) -> None:
    """Return 503 when senseBoxes have no ambient measurement data."""
    _mock_senseboxes(
        httpx_mock,
        (
            {"sensors": []},
            _sensebox_payload(None, None),
            {
                "sensors": [
                    {
                        "title": "Temperatur",
                        "unit": "°C",
                        "lastMeasurement": None,
                    }
                ]
            },
        ),
    )

    response = await api_client.get("/temperature")

    assert response.status_code == 503
    assert response.json() == {
        "detail": "No temperature measurements from the last hour are available"
    }


async def test_temperature_handles_upstream_failure(
    api_client: httpx.AsyncClient,
    httpx_mock: HTTPXMock,
) -> None:
    """Return 502 when openSenseMap responds with an HTTP error."""
    httpx_mock.add_response(status_code=500, is_reusable=True)

    response = await api_client.get("/temperature")

    assert response.status_code == 502
    assert response.json() == {
        "detail": "Failed to retrieve temperature data from openSenseMap"
    }
