"""Render the canonical Gitflow lifecycle."""

from diagrams import Diagram
from diagrams.generic.blank import Blank
from diagrams.onprem.vcs import Github


def render(filename: str, outformat: list[str]) -> None:
    """Write the Gitflow diagram."""
    with Diagram("HiveBox canonical Gitflow", filename=filename, outformat=outformat,
                 show=False, direction="LR"):
        develop = Github("develop", nodeid="develop")
        feature = Blank("feature / bugfix", nodeid="feature")
        release = Blank("release", nodeid="release")
        main = Github("main", nodeid="main")
        backmerge = Blank("backmerge", nodeid="backmerge")
        develop >> feature >> develop
        develop >> release >> main
        release >> backmerge >> develop
