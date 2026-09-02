# Quality and testing

The project uses unit tests for application behaviour and integration tests
that exercise the API through a real local HTTP server. The unit suite enforces
a 90% coverage threshold.

Pylint, Ruff, mypy, package building, metadata validation, and dependency
checks provide the remaining quality gates. Their versions and configuration
are pinned in `pyproject.toml`.

## Run the automated tests

Install the test dependencies:

```shell
python -m pip install --editable ".[test]"
```

Run the unit test suite with coverage:

```shell
pytest --ignore=tests/integration --cov=src --cov-report=term-missing
```

The unit tests call FastAPI in memory and mock all openSenseMap requests. Run
the integration test suite separately:

```shell
pytest tests/integration
```

The integration tests communicate with HiveBox through a real Uvicorn HTTP
server. A second local HTTP server provides controlled openSenseMap responses,
so the suite is reproducible and requires neither Internet access nor Docker.
Both servers use ephemeral loopback ports and are stopped automatically even
when a test fails.

## Run the quality checks

Install the quality and test dependencies:

```shell
python -m pip install --editable ".[quality,test]"
```

Run the Python quality gates locally:

```shell
python -m pylint src tests
ruff format --check src tests
python -m mypy
python -m build
python -m twine check dist/*
python -m pip check
python -m pytest --ignore=tests/integration --cov=src --cov-report=term-missing
python -m pytest tests/integration
```

The test suite must maintain at least 90% coverage. Pylint, Ruff, mypy and the
packaging tools are configured in `pyproject.toml`.

## Validate the container

The historical Docker validation commands remain:

```shell
docker build --check .
docker build --tag hivebox:local .
```

See the [local container runbook](../README.md#run-the-container-locally) to
start the image and verify its endpoints.
