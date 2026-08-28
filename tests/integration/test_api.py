"""Integration tests for HiveBox's public HTTP contracts."""

from http import HTTPStatus

import httpx
from prometheus_client.parser import text_string_to_metric_families


def test_version_contract_over_http(live_api_client: httpx.Client) -> None:
    """Return the deployed version through a real HTTP server."""
    response = live_api_client.get("/version")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {"version": "0.1.0"}


def test_metrics_contract_over_http(live_api_client: httpx.Client) -> None:
    """Expose parseable default metrics through a real HTTP server."""
    live_api_client.get("/version").raise_for_status()

    response = live_api_client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain; version=")
    sample_names = {
        sample.name
        for family in text_string_to_metric_families(response.text)
        for sample in family.samples
    }
    assert {
        "http_requests_total",
        "python_gc_objects_collected_total",
        "python_info",
    } <= sample_names


def test_temperature_contract_with_controlled_upstream(
    live_api_client: httpx.Client,
) -> None:
    """Calculate temperature from controlled data fetched over HTTP."""
    expected_payload: dict[str, object] = {
        "average_temperature": 21.0,
        "unit": "°C",
        "status": "Good",
    }

    response = live_api_client.get("/temperature")

    assert response.status_code == HTTPStatus.OK
    assert response.headers["content-type"] == "application/json"
    assert response.json() == expected_payload
