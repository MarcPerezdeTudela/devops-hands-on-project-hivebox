[![Dynamic DevOps Roadmap](https://img.shields.io/badge/Dynamic_DevOps_Roadmap-559e11?style=for-the-badge&logo=Vercel&logoColor=white)](https://devopsroadmap.io/getting-started/)
[![Community](https://img.shields.io/badge/Join_Community-%23FF6719?style=for-the-badge&logo=substack&logoColor=white)](https://newsletter.devopsroadmap.io/subscribe)
[![Fork on GitHub](https://img.shields.io/badge/Fork_On_GitHub-%2336465D?style=for-the-badge&logo=github&logoColor=white)](https://github.com/DevOpsHiveHQ/devops-hands-on-project-hivebox/fork)

# HiveBox

> [!CAUTION]
> **[Fork](https://github.com/DevOpsHiveHQ/devops-hands-on-project-hivebox/fork) this repository and open pull requests in your fork, not in this repository.**

HiveBox is an end-to-end, hands-on DevOps learning project. Its FastAPI service
retrieves recent ambient-temperature data from openSenseMap and exposes it to
beekeepers. Each guide explains both the commands to run and why the related
DevOps practice exists.

## Start here

1. Create a GitHub account if needed, fork the repository, and read
   [CONTRIBUTING.md](CONTRIBUTING.md).
2. Create a Kanban GitHub Project for your fork and choose nearby senseBox IDs
   from [openSenseMap](https://opensensemap.org/).
3. Follow the [application guide](docs/application.md) to run HiveBox locally.
4. Work through the domains below in the order that fits your learning goal.

Python 3.13 is required. Never commit `.env`, credentials, tokens, or private
keys; see [SECURITY.md](SECURITY.md) for responsible disclosure.

## Learn by domain

| Domain | What you will learn |
| --- | --- |
| [Gitflow](docs/gitflow.md) | Canonical feature, release, hotfix, and backmerge lifecycle. |
| [Application](docs/application.md) | FastAPI, openSenseMap configuration, endpoints, and Docker. |
| [Quality and testing](docs/quality-and-testing.md) | Unit and HTTP integration tests, coverage, typing, linting, and packaging. |
| [CI and security](docs/ci-and-security.md) | GitHub Actions checks, SonarQube Cloud, and OpenSSF Scorecard. |
| [Continuous delivery](docs/cd.md) | Release-tag validation and publication to GHCR. |
| [Observability](docs/observability.md) | Prometheus-compatible runtime metrics and their current scope. |
| [Kubernetes](docs/kubernetes.md) | KIND, Envoy Gateway, a secure workload, verification, and cleanup. |

## Documentation diagrams

The diagrams in the guides are generated from versioned Python sources with
[mingrammer/diagrams](https://github.com/mingrammer/diagrams). Install Graphviz
and the documentation tools, then regenerate or verify them with:

```shell
python -m pip install --editable ".[docs]"
make docs-diagrams
make docs-diagrams-check
```

`docs-diagrams-check` renders into a temporary directory and fails if the
tracked SVG or PNG outputs under `docs/diagrams/generated/` are stale.

Happy DevOpsing ♾️
