# Quality and testing

The project uses unit tests for application behaviour and integration tests
that exercise the API through a real local HTTP server. The unit suite enforces
a 90% coverage threshold.

Pylint, Ruff, mypy, package building, metadata validation, and dependency
checks provide the remaining quality gates. Their versions and configuration
are pinned in `pyproject.toml`.
