"""FastAPI application setup."""

from typing import Literal

from fastapi import FastAPI, HTTPException, status
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel

from src import __version__
from src.config import SENSEBOX_IDS
from src.opensensemap import (
    NoFreshTemperatureDataError,
    OpenSenseMapError,
    get_average_temperature,
)
from src.temperature import TemperatureStatus, classify_temperature


class VersionResponse(BaseModel):
    """Currently deployed HiveBox version."""

    version: str


class TemperatureResponse(BaseModel):
    """Current average temperature and its comfort classification."""

    average_temperature: float
    unit: Literal["°C"] = "°C"
    status: TemperatureStatus


app = FastAPI(title="HiveBox", version=__version__)
Instrumentator().instrument(app).expose(app, include_in_schema=False)


@app.get("/version", response_model=VersionResponse)
def get_version() -> VersionResponse:
    """Return the currently deployed application version."""
    return VersionResponse(version=__version__)


@app.get("/temperature", response_model=TemperatureResponse)
async def get_temperature() -> TemperatureResponse:
    """Return the current average temperature and comfort classification."""
    try:
        average_temperature = await get_average_temperature(SENSEBOX_IDS)
    except OpenSenseMapError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to retrieve temperature data from openSenseMap",
        ) from exc
    except NoFreshTemperatureDataError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No temperature measurements from the last hour are available",
        ) from exc

    return TemperatureResponse(
        average_temperature=average_temperature,
        status=classify_temperature(average_temperature),
    )
