"""Integration tests for the Prometheus metrics endpoint."""

import sys

import httpx
import pytest
from prometheus_client.parser import text_string_to_metric_families
from prometheus_client.samples import Sample

pytestmark = pytest.mark.anyio


def _samples(exposition: str) -> list[Sample]:
    """Parse all samples from a Prometheus text exposition."""
    return [
        sample
        for metric_family in text_string_to_metric_families(exposition)
        for sample in metric_family.samples
    ]


def _sample_value(
    exposition: str,
    metric_name: str,
    labels: dict[str, str],
) -> float | None:
    """Return one metric sample selected by its name and complete label set."""
    matching_samples = [
        sample
        for sample in _samples(exposition)
        if sample.name == metric_name and sample.labels == labels
    ]
    if not matching_samples:
        return None

    assert len(matching_samples) == 1
    return matching_samples[0].value


async def test_metrics_exposes_prometheus_defaults(
    api_client: httpx.AsyncClient,
) -> None:
    """Return parseable default HTTP and Python metrics."""
    await api_client.get("/version")

    response = await api_client.get("/metrics")

    assert response.status_code == 200
    content_type = response.headers["content-type"]
    assert content_type.startswith("text/plain; version=")
    assert "charset=utf-8" in content_type

    sample_names = {sample.name for sample in _samples(response.text)}
    assert {
        "http_request_duration_seconds_count",
        "http_request_size_bytes_count",
        "http_requests_total",
        "http_response_size_bytes_count",
        "python_gc_objects_collected_total",
        "python_info",
    } <= sample_names


async def test_metrics_reflects_existing_endpoint_requests(
    api_client: httpx.AsyncClient,
) -> None:
    """Increment the matching HTTP counter after a version request."""
    labels = {
        "handler": "/version",
        "method": "GET",
        "status": "2xx",
    }
    before_response = await api_client.get("/metrics")
    before_value = _sample_value(
        before_response.text,
        "http_requests_total",
        labels,
    )

    await api_client.get("/version")
    after_response = await api_client.get("/metrics")
    after_value = _sample_value(
        after_response.text,
        "http_requests_total",
        labels,
    )

    assert after_value is not None
    assert after_value == (before_value or 0.0) + 1


async def test_metrics_is_excluded_from_openapi(
    api_client: httpx.AsyncClient,
) -> None:
    """Keep the operational metrics route outside the public API schema."""
    response = await api_client.get("/openapi.json")

    assert response.status_code == 200
    assert "/metrics" not in response.json()["paths"]


@pytest.mark.skipif(
    sys.platform != "linux",
    reason="The default process collector is supported on Linux",
)
async def test_metrics_exposes_process_metrics(
    api_client: httpx.AsyncClient,
) -> None:
    """Expose representative default process metrics on Linux."""
    response = await api_client.get("/metrics")

    sample_names = {sample.name for sample in _samples(response.text)}
    assert {
        "process_cpu_seconds_total",
        "process_resident_memory_bytes",
        "process_start_time_seconds",
    } <= sample_names
