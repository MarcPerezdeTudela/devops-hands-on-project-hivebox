"""Render the continuous-integration checks."""

from diagrams import Cluster, Diagram
from diagrams.onprem.vcs import Github
from diagrams.programming.language import Python
from diagrams.onprem.security import Trivy


def render(filename: str, outformat: list[str]) -> None:
    """Write the CI diagram."""
    with Diagram("HiveBox continuous integration", filename=filename, outformat=outformat,
                 show=False, direction="LR"):
        pull_request = Github("Pull request", nodeid="pull_request")
        with Cluster("parallel checks"):
            policy = Github("PR policy", nodeid="policy")
            quality = Python("quality + tests", nodeid="quality")
            security = Trivy("Kubernetes + image scan", nodeid="security")
        pull_request >> [policy, quality, security]
