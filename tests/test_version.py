"""Unit tests for the application version endpoint."""

import httpx
import pytest

pytestmark = pytest.mark.anyio


async def test_get_version(api_client: httpx.AsyncClient) -> None:
    """Return the deployed package version as JSON."""
    response = await api_client.get("/version")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {"version": "0.1.0"}
