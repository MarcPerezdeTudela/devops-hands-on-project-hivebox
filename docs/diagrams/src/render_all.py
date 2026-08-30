"""Generate every tracked HiveBox documentation diagram."""

from __future__ import annotations

import argparse
import base64
import hashlib
import importlib
from pathlib import Path
import re


DIAGRAMS = (
    "application",
    "gitflow",
    "ci",
    "cd",
    "observability",
    "kubernetes",
)

IMAGE_REFERENCE = re.compile(rb'xlink:href="([^"]+)"')


def embed_svg_images(output: Path) -> None:
    """Replace renderer-local SVG icon paths with portable data URIs."""
    for svg in output.glob("*.svg"):
        source = svg.read_bytes()

        def replace(match: re.Match[bytes]) -> bytes:
            image = Path(match.group(1).decode("utf-8"))
            encoded = base64.b64encode(image.read_bytes())
            return b'xlink:href="data:image/png;base64,' + encoded + b'"'

        svg.write_bytes(IMAGE_REFERENCE.sub(replace, source))


def source_digest() -> str:
    """Return a stable digest for every source that defines generated assets."""
    digest = hashlib.sha256()
    source_directory = Path(__file__).parent
    for name in (*DIAGRAMS, Path(__file__).stem):
        digest.update((source_directory / f"{name}.py").read_bytes())
    return digest.hexdigest()


def main() -> None:
    """Render SVG and PNG assets into the requested directory."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()
    arguments.output.mkdir(parents=True, exist_ok=True)

    for name in DIAGRAMS:
        module = importlib.import_module(name)
        module.render(str(arguments.output / name), ["svg", "png"])

    embed_svg_images(arguments.output)
    (arguments.output / ".source-sha256").write_text(f"{source_digest()}\n")


if __name__ == "__main__":
    main()
