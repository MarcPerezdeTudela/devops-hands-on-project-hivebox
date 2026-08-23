[![Dynamic DevOps Roadmap](https://img.shields.io/badge/Dynamic_DevOps_Roadmap-559e11?style=for-the-badge&logo=Vercel&logoColor=white)](https://devopsroadmap.io/getting-started/)
[![Community](https://img.shields.io/badge/Join_Community-%23FF6719?style=for-the-badge&logo=substack&logoColor=white)](https://newsletter.devopsroadmap.io/subscribe)
[![Telegram Group](https://img.shields.io/badge/Telegram_Group-%232ca5e0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/DevOpsHive/985)
[![Fork on GitHub](https://img.shields.io/badge/Fork_On_GitHub-%2336465D?style=for-the-badge&logo=github&logoColor=white)](https://github.com/DevOpsHiveHQ/devops-hands-on-project-hivebox/fork)

# HiveBox - DevOps End-to-End Hands-On Project

<p align="center">
  <a href="https://devopsroadmap.io/projects/hivebox" style="display: block; padding: .5em 0; text-align: center;">
    <img alt="HiveBox - DevOps End-to-End Hands-On Project" border="0" width="90%" src="https://devopsroadmap.io/img/projects/hivebox-devops-end-to-end-project.png" />
  </a>
</p>

> [!CAUTION]
> **[Fork](https://github.com/DevOpsHiveHQ/devops-hands-on-project-hivebox/fork)** this repo, and create PRs in your fork, **NOT** in this repo!

> [!TIP]
> If you are looking for the full roadmap, including this project, go back to the [getting started](https://devopsroadmap.io/getting-started) page.

This repository is the starting point for [HiveBox](https://devopsroadmap.io/projects/hivebox/), the end-to-end hands-on project.

You can fork this repository and start implementing the [HiveBox](https://devopsroadmap.io/projects/hivebox/) project. HiveBox project follows the same Dynamic MVP-style mindset used in the [roadmap](https://devopsroadmap.io/).

The project aims to cover the whole Software Development Life Cycle (SDLC). That means each phase will cover all aspects of DevOps, such as planning, coding, containers, testing, continuous integration, continuous delivery, infrastructure, etc.

Happy DevOpsing ♾️

## Before you start

Here is a pre-start checklist:

- ⭐ <a target="_blank" href="https://github.com/DevOpsHiveHQ/dynamic-devops-roadmap">Star the **roadmap** repo</a> on GitHub for better visibility.
- ✉️ <a target="_blank" href="https://newsletter.devopsroadmap.io/subscribe">Join the community</a> for the project community activities, which include mentorship, job posting, online meetings, workshops, career tips and tricks, and more.
- 🌐 <a target="_blank" href="https://t.me/DevOpsHive/985">Join the Telegram group</a> for interactive communication.

## Preparation

- [Create GitHub account](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github) (if you don't have one), then [fork this repository](https://github.com/DevOpsHiveHQ/devops-hands-on-project-hivebox/fork) and start from there.
- [Create GitHub project board](https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/creating-a-project) for this repository (use `Kanban` template).
- Feature and bugfix branches target `develop`. Only `release/*` and
  `hotfix/*` branches target `main`, following Gitflow. Don't push directly to
  either protected branch.
- Document as you go. Always assume that someone else will read your project at any phase.
- You can get senseBox IDs by checking the [openSenseMap](https://opensensemap.org/) website. Use 3 senseBox IDs close to each other (you can use the following [5eba5fbad46fb8001b799786](https://opensensemap.org/explore/5eba5fbad46fb8001b799786), [5c21ff8f919bf8001adf2488](https://opensensemap.org/explore/5c21ff8f919bf8001adf2488), and [5ade1acf223bd80019a1011c](https://opensensemap.org/explore/5ade1acf223bd80019a1011c)). Just copy the IDs, you will need them in the next steps.

<br/>
<p align="center">
  <a href="https://devopsroadmap.io/projects/hivebox/" imageanchor="1">
    <img src="https://img.shields.io/badge/Get_Started_Now-559e11?style=for-the-badge&logo=Vercel&logoColor=white" />
  </a><br/>
</p>

---

## Implementation

### Phase 3: FastAPI application setup

The API is implemented with FastAPI. Its application object lives in
`src/main.py`, and `pyproject.toml` declares both the Python dependencies
and the FastAPI entrypoint.

Python 3.13 is required.

Create and activate a virtual environment:

```shell
python3 -m venv .venv
source .venv/bin/activate
```

Install the project and its dependencies:

```shell
python -m pip install --editable .
```

Start the development server:

```shell
fastapi dev
```

The server listens on `http://127.0.0.1:8000`. FastAPI's generated API
documentation is available at `http://127.0.0.1:8000/docs`, and its OpenAPI
schema is available at `http://127.0.0.1:8000/openapi.json`.

#### Get the deployed version

Request the currently deployed application version:

```shell
curl http://127.0.0.1:8000/version
```

The parameterless `GET /version` endpoint returns:

```json
{"version":"0.0.1"}
```

#### Get the current average temperature

The application retrieves the ambient temperature from the three configured
senseBoxes and averages measurements from the last hour:

- `5eba5fbad46fb8001b799786`
- `5c21ff8f919bf8001adf2488`
- `5ade1acf223bd80019a1011c`

Request the current average temperature:

```shell
curl http://127.0.0.1:8000/temperature
```

The parameterless `GET /temperature` endpoint returns the average rounded to
two decimal places:

```json
{"average_temperature":15.1,"unit":"°C"}
```

Only ambient temperature measurements no older than one hour are included. The
endpoint returns `502 Bad Gateway` when openSenseMap cannot provide valid data,
and `503 Service Unavailable` when no recent measurement is available.

#### Run with Docker

The multi-stage build installs the application in an isolated virtual
environment and copies only that environment into the runtime stage. The final
container uses the pinned slim Python image and runs as the unprivileged user
`10001:10001`.

Validate the Dockerfile and build the image from the repository root:

```shell
docker build --check .
docker build --tag hivebox:v0.0.1 .
```

Run the API and publish its port locally:

```shell
docker run --rm --publish 8000:8000 hivebox:v0.0.1
```

You can verify that the configured process is not running as root:

```shell
docker run --rm --entrypoint id hivebox:v0.0.1
```

The API documentation is then available at `http://127.0.0.1:8000/docs`, and
the OpenAPI schema at `http://127.0.0.1:8000/openapi.json`. Press `Ctrl+C` to
stop the API. The `--rm` option removes the stopped container automatically.

The application version comes from the installed package metadata generated
from `project.version` in `pyproject.toml`.

#### Run the unit tests

Install the test dependencies:

```shell
python -m pip install --editable ".[test]"
```

Run the test suite:

```shell
pytest
```

The tests mock all openSenseMap requests and do not require network access.

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
python -m pytest --cov=src --cov-report=term-missing
```

The test suite must maintain at least 90% coverage. Pylint, Ruff, mypy and the
packaging tools are configured in `pyproject.toml`.

#### Continuous integration

The GitHub Actions workflow runs for pull requests and subsequent pushes to
`develop` and `main`. Its independent checks enforce:

- Gitflow branch direction and Conventional Commits pull request titles
- GitHub Actions syntax
- Python linting, formatting, strict static typing and package integrity
- unit tests and the coverage threshold
- Dockerfile linting, image building, non-root metadata and a live `/version`
  smoke test with graceful shutdown

Configure the repository rulesets for `develop` and `main` to require the
following status checks before merging:

```text
pull-request-policy
workflow-lint
python-quality
unit-tests
container
```

The workflow has read-only repository permissions. External GitHub Actions and
containerized linters are pinned to immutable commits or image digests.
