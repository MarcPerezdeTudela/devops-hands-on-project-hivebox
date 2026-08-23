"""Client for retrieving temperature data from openSenseMap."""

import asyncio
from datetime import UTC, datetime, timedelta
from statistics import fmean

import httpx
from pydantic import BaseModel, Field, field_validator

OPEN_SENSE_MAP_BOX_URL = "https://api.opensensemap.org/boxes/{box_id}"
REQUEST_TIMEOUT_SECONDS = 10.0
TEMPERATURE_SENSOR_TITLE = "Temperatur"
TEMPERATURE_UNIT = "°C"


class OpenSenseMapError(Exception):
    """Raised when openSenseMap cannot provide a valid response."""


class NoFreshTemperatureDataError(Exception):
    """Raised when no temperature measurement is recent enough."""


class Measurement(BaseModel):
    """Latest sensor measurement returned by openSenseMap."""

    created_at: datetime = Field(alias="createdAt")
    value: float

    @field_validator("created_at")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        """Reject timestamps that cannot be compared safely with UTC."""
        if value.tzinfo is None:
            raise ValueError("Measurement timestamp must include a timezone")
        return value


class Sensor(BaseModel):
    """Subset of an openSenseMap sensor used by HiveBox."""

    title: str
    unit: str
    last_measurement: Measurement | None = Field(
        default=None,
        alias="lastMeasurement",
    )


class SenseBox(BaseModel):
    """Subset of an openSenseMap senseBox used by HiveBox."""

    sensors: list[Sensor]


async def _fetch_temperature(
    client: httpx.AsyncClient,
    box_id: str,
    cutoff: datetime,
) -> float | None:
    """Return a senseBox's fresh ambient temperature, if available."""
    try:
        response = await client.get(OPEN_SENSE_MAP_BOX_URL.format(box_id=box_id))
        response.raise_for_status()
        sense_box = SenseBox.model_validate(response.json())
    except (httpx.HTTPError, ValueError) as exc:
        raise OpenSenseMapError(
            f"Could not retrieve valid data for senseBox {box_id}"
        ) from exc

    for sensor in sense_box.sensors:
        measurement = sensor.last_measurement
        if (
            sensor.title == TEMPERATURE_SENSOR_TITLE
            and sensor.unit == TEMPERATURE_UNIT
            and measurement is not None
            and measurement.created_at >= cutoff
        ):
            return measurement.value

    return None


async def get_average_temperature(
    box_ids: tuple[str, ...],
    current_time: datetime | None = None,
) -> float:
    """Return the average of all fresh configured senseBox temperatures."""
    reference_time = current_time or datetime.now(UTC)
    cutoff = reference_time - timedelta(hours=1)

    async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT_SECONDS) as client:
        measurements = await asyncio.gather(
            *(_fetch_temperature(client, box_id, cutoff) for box_id in box_ids)
        )

    fresh_measurements = [
        measurement for measurement in measurements if measurement is not None
    ]
    if not fresh_measurements:
        raise NoFreshTemperatureDataError(
            "No temperature measurements from the last hour are available"
        )

    return round(fmean(fresh_measurements), 2)
