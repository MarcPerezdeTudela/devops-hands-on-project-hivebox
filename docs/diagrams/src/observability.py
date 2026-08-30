"""Render the current Prometheus observability boundary."""

from diagrams import Diagram
from diagrams.onprem.monitoring import Prometheus
from diagrams.programming.framework import Fastapi


def render(filename: str, outformat: list[str]) -> None:
    """Write the observability diagram."""
    with Diagram("HiveBox observability", filename=filename, outformat=outformat,
                 show=False, direction="LR"):
        api = Fastapi("HiveBox API", nodeid="api")
        endpoint = Prometheus("/metrics endpoint", nodeid="endpoint")
        consumer = Prometheus("Prometheus-compatible consumer", nodeid="consumer")
        api >> endpoint >> consumer
