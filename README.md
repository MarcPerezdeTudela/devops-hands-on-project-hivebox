# HiveBox

<p align="center">
  <img alt="HiveBox project header" width="90%" src="https://devopsroadmap.io/img/projects/hivebox-devops-end-to-end-project.png" />
</p>

HiveBox is a hands-on DevOps project built around a FastAPI service for
beekeepers. It retrieves recent ambient-temperature data from openSenseMap and
is incrementally delivered through testing, containers, Kubernetes, and CI/CD.

## Start locally

HiveBox requires Python 3.13. Install the project and run the development
server:

```shell
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --editable .
fastapi dev
curl http://127.0.0.1:8000/version
# {"version":"0.2.2"}
```

Build the equivalent local image with `docker build --tag hivebox:v0.2.2 .`.

## Project guides

- [Gitflow](docs/gitflow.md)
- [Application](docs/application.md)
- [Quality and testing](docs/quality-and-testing.md)
- [Continuous integration and security](docs/ci-and-security.md)
- [Continuous delivery](docs/cd.md)
- [Observability](docs/observability.md)
- [Kubernetes](docs/kubernetes.md)

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance and
[SECURITY.md](SECURITY.md) for responsible vulnerability reporting.
