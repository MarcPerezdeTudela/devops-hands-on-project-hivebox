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
# {"version":"0.3.0"}
```

## Run the container locally

The multi-stage build installs the application in an isolated virtual
environment and copies only that environment into the runtime stage. The final
container uses the pinned slim Python image and runs as the unprivileged user
`10001:10001`.

Validate the Dockerfile and build the image from the repository root:

```shell
docker build --check .
docker build --tag hivebox:v0.3.0 .
```

Run the API and publish its port locally:

```shell
docker run --rm --name hivebox -p 8000:8000 hivebox:v0.3.0
```

The API documentation is available at `http://127.0.0.1:8000/docs`, and its
OpenAPI schema at `http://127.0.0.1:8000/openapi.json`. In another terminal,
verify the application endpoints:

```shell
curl http://127.0.0.1:8000/version
# {"version":"0.3.0"}
curl http://127.0.0.1:8000/metrics
```

The `/metrics` endpoint returns Prometheus text exposition. Press `Ctrl+C` to
stop the API; `--rm` removes the stopped container automatically.

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

## License

The HiveBox implementation in this repository is available under the
[MIT License](LICENSE). The project requirements are based on the
[HiveBox hands-on project](https://devopsroadmap.io/projects/hivebox/) from
DevOps Hive.
