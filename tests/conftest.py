"""Shared pytest fixtures for HiveBox API tests."""

from collections.abc import AsyncIterator

import httpx
import pytest

from src.main import app


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
