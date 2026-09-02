# HiveBox agent guide

## Purpose and scope

HiveBox is an incremental DevOps learning project: a FastAPI service retrieves
recent ambient-temperature data from openSenseMap, exposes it for beekeepers,
and is delivered through containers, Kubernetes, CI, and Gitflow. Phase 4 is
the current target. Read [README.md](README.md) and its linked runbooks for
the operational documentation; this file is concise working guidance, not a
duplicate.

Make the smallest correct change for the requested issue. Do not refactor,
rename, reformat, or update dependencies outside that scope. Reuse existing
patterns before adding an abstraction or dependency. Preserve unrelated
working-tree changes.

## Explore only what is relevant

Start with the paths named in the task. Use this map before expanding the
search:

| Change | Start with |
| --- | --- |
| API behaviour or configuration | `src/`, matching tests in `tests/`, `pyproject.toml` |
| Unit or integration tests | matching `tests/test_*.py` or `tests/integration/`, then the code under test |
| Container image | `Dockerfile`, relevant README section, `.github/workflows/ci.yml` |
| Kubernetes or gateway | `kubernetes/`, relevant CI job, README |
| CI, security, or release governance | `.github/workflows/`, `.github/scripts/`, `.github/tests/`, `.gitflow`, README |
| Documentation | the affected implementation/configuration plus README or `SECURITY.md` |

Do not scan the whole repository by default. If the task does not identify a
path, locate the closest existing implementation and follow its convention.

## Project conventions

- Python 3.13 is required. Dependencies and quality-tool versions are pinned
  in `pyproject.toml`; do not loosen or add them without a task requirement.
- The FastAPI application is `src.main:app`. Keep endpoint response models,
  error handling, type hints, docstrings, and tests aligned with nearby code.
- `HIVEBOX_SENSEBOX_IDS` is the public configuration contract. Keep its strict
  validation semantics; never silently fall back when a supplied value is
  invalid.
- Kubernetes manifests live under `kubernetes/`. Apply least privilege and
  preserve the existing security posture.
- Never commit `.env`, credentials, tokens, or generated build/test artifacts.
  Treat potential vulnerabilities according to `SECURITY.md`; do not open a
  public issue for a suspected vulnerability.

## Git and pull requests

The authoritative workflow is [docs/gitflow.md](docs/gitflow.md) and
`.gitflow`.

- Branch features and ordinary bug fixes from `develop` using
  `feature/<issue>-<slug>` or `bugfix/<slug>`.
- Do not push directly to `main`, `develop`, or `release/*`. GitHub performs
  protected integrations with merge commits; do not squash or rebase merge.
- Keep a pull request limited to one issue. Its title must use Conventional
  Commits, for example `docs(agents): add repository agent guide (#49)`.
- Release and hotfix work have additional routing and backmerge requirements.
  Read the README before changing or creating those branches.

## Validate proportionately

Install only the extras required for the requested validation:

```shell
python -m pip install --editable ".[test]"
python -m pip install --editable ".[quality,test]"
```

Run the smallest relevant check first. Use these repository commands; do not
invent replacement scripts.

```shell
# Unit tests for application changes; the configured coverage threshold is 90%.
python -m pytest --ignore=tests/integration --cov=src --cov-report=term-missing

# HTTP integration tests.
python -m pytest tests/integration

# Python quality and packaging checks when Python code or packaging changes.
python -m pylint src tests
ruff format --check src tests
python -m mypy
python -m build
python -m twine check dist/*
python -m pip check

# Container changes.
docker build --check .
docker build --tag hivebox:local .
```

For workflow, Docker, Kubernetes, security, or governance changes, inspect
the equivalent CI job and run any safe, relevant local check. Do not claim a
check passed if its tools, credentials, Docker daemon, cluster, or external
service were unavailable.

## Keep documentation and tests in sync

- Add or update focused tests when observable application behaviour changes.
- Update `README.md` when setup, configuration, endpoints, validation,
  deployment, release workflow, or operator-facing behaviour changes.
- Update `SECURITY.md` only for security-policy changes.
- Keep infrastructure changes documented enough to be reproduced by another
  contributor.

## Completion response

Be concise. Report only:

1. What changed and the files changed.
2. Validation run and its outcome.
3. Any unresolved blocker, risk, or validation not run.

Do not provide a long explanation unless asked.
