"""FastAPI application setup."""

from fastapi import FastAPI
from pydantic import BaseModel

from src import __version__


class VersionResponse(BaseModel):
    """Currently deployed HiveBox version."""

    version: str


app = FastAPI(title="HiveBox", version=__version__)


@app.get("/version", response_model=VersionResponse)
def get_version() -> VersionResponse:
    """Return the currently deployed application version."""
    return VersionResponse(version=__version__)
