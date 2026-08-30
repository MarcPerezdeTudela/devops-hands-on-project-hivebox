# Quality and testing

## Purpose

HiveBox makes correctness reproducible through focused unit tests, real HTTP
integration tests, static analysis, formatting, packaging, and dependency
checks.

## Run the tests

```shell
python -m pip install --editable ".[test]"
python -m pytest --ignore=tests/integration --cov=src --cov-report=term-missing
python -m pytest tests/integration
```

The unit suite must maintain at least 90% coverage. Integration tests run a
real Uvicorn server and a controlled local openSenseMap server on ephemeral
loopback ports; they do not require Internet access or Docker.

## Run the quality gates

```shell
python -m pip install --editable ".[quality,test]"
python -m pylint src tests
ruff format --check src tests
python -m mypy
python -m build
python -m twine check dist/*
python -m pip check
```

Pylint, Ruff, mypy, coverage, and packaging behaviour are configured in
`pyproject.toml`. Run the smallest relevant check first, then the full set
before a release.

## Troubleshooting

Do not claim a quality check passed when its required tool is unavailable.
Remove generated `build/` and `dist/` artefacts only when they are no longer
needed; neither belongs in commits.

Next: [CI and security](ci-and-security.md).

## Complete operational reference

#### Run the automated tests

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

#### Run the quality checks

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

