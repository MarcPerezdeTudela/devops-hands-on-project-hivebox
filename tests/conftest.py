"""Shared pytest fixtures for HiveBox API tests."""

import os
from collections.abc import AsyncIterator

import httpx
import pytest

# Unit tests always exercise the documented local defaults. This must happen
# before importing the application because configuration is resolved at import.
os.environ.pop("HIVEBOX_SENSEBOX_IDS", None)

from src.main import app  # pylint: disable=wrong-import-position


@pytest.fixture
def anyio_backend() -> str:
    """Run async tests with the asyncio backend used by the application."""
    return "asyncio"


@pytest.fixture
async def api_client() -> AsyncIterator[httpx.AsyncClient]:
    """Provide an asynchronous client connected directly to FastAPI."""
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(
        transport=transport,
        base_url="http://test",
    ) as client:
        yield client
