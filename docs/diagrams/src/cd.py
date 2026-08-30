"""Render the continuous-delivery release flow."""

from diagrams import Diagram
from diagrams.onprem.container import Docker
from diagrams.onprem.vcs import Github
from diagrams.onprem.registry import Harbor


def render(filename: str, outformat: list[str]) -> None:
    """Write the CD diagram."""
    with Diagram("HiveBox continuous delivery", filename=filename, outformat=outformat,
                 show=False, direction="LR"):
        tag = Github("v* tag on main", nodeid="tag")
        validation = Github("release validation", nodeid="validation")
        image = Docker("Buildx image", nodeid="image")
        registry = Harbor("GHCR", nodeid="registry")
        tag >> validation >> image >> registry
