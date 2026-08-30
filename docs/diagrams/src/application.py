"""Render the HiveBox application data-flow diagram."""

from diagrams import Diagram
from diagrams.generic.blank import Blank
from diagrams.onprem.client import Users
from diagrams.onprem.monitoring import Prometheus
from diagrams.programming.framework import Fastapi


def render(filename: str, outformat: list[str]) -> None:
    """Write the application diagram to ``filename`` in each requested format."""
    with Diagram("HiveBox application data flow", filename=filename, outformat=outformat,
                 show=False, direction="LR"):
        beekeeper = Users("Beekeeper", nodeid="beekeeper")
        api = Fastapi("HiveBox API", nodeid="api")
        sensemap = Blank("openSenseMap", nodeid="opensensemap")
        metrics = Prometheus("/metrics", nodeid="metrics")
        beekeeper >> api >> sensemap
        api >> metrics
