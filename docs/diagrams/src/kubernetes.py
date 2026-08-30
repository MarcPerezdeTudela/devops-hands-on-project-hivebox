"""Render the local Kubernetes Gateway request path."""

from diagrams import Diagram
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.network import Service
from diagrams.generic.network import Router
from diagrams.onprem.container import Docker


def render(filename: str, outformat: list[str]) -> None:
    """Write the Kubernetes request-path diagram."""
    with Diagram("HiveBox local Kubernetes Gateway", filename=filename,
                 outformat=outformat, show=False, direction="LR"):
        docker = Docker("localhost:8080", nodeid="localhost")
        gateway = Router("Envoy Gateway", nodeid="gateway")
        service = Service("HiveBox Service", nodeid="service")
        deployment = Deployment("HiveBox Deployment", nodeid="deployment")
        pod = Pod("HiveBox Pod", nodeid="pod")
        docker >> gateway >> service >> deployment >> pod
