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
{"version":"0.1.0"}
```

#### Get the current average temperature

By default, the application retrieves the ambient temperature from these three
senseBoxes and averages measurements from the last hour:

- `5eba5fbad46fb8001b799786`
- `5c21ff8f919bf8001adf2488`
- `5ade1acf223bd80019a1011c`

Request the current average temperature:

```shell
curl http://127.0.0.1:8000/temperature
```

The parameterless `GET /temperature` endpoint returns the average rounded to
two decimal places and its temperature status:

```json
{"average_temperature":15.1,"unit":"°C","status":"Good"}
```

The status uses continuous boundaries, so every temperature has exactly one
classification:

| Average temperature | Status |
| --- | --- |
| Below 10 °C | `Too Cold` |
| From 10 °C through 37 °C | `Good` |
| Above 37 °C | `Too Hot` |

Only ambient temperature measurements no older than one hour are included. The
endpoint returns `502 Bad Gateway` when openSenseMap cannot provide valid data,
and `503 Service Unavailable` when no recent measurement is available.

##### Configure the senseBoxes

Set `HIVEBOX_SENSEBOX_IDS` to a comma-separated list to replace the local
defaults. For example, start the development server with two senseBoxes:

```shell
HIVEBOX_SENSEBOX_IDS="5eba5fbad46fb8001b799786,5c21ff8f919bf8001adf2488" fastapi dev
```

For repeated local use, copy the tracked example to an ignored `.env` file and
edit the IDs:

```shell
cp .env.example .env
```

Uvicorn can load that file before importing HiveBox:

```shell
uvicorn src.main:app --reload --env-file .env
```

`fastapi dev` uses variables already exported by the shell; use the Uvicorn
command above when configuration should come directly from a `.env` file. Do
not commit `.env`. The tracked `.env.example` contains only public sample
configuration.

Each senseBox ID must contain exactly 24 hexadecimal characters. Surrounding
spaces are removed, while empty entries and duplicate IDs are rejected. An
absent variable selects the three defaults above; a variable that is present
but empty or malformed stops the application at startup with a configuration
error. This distinction prevents a deployment mistake from silently querying
the development senseBoxes.

#### Inspect the default Prometheus metrics

Request the application's default Prometheus metrics:

```shell
curl http://127.0.0.1:8000/metrics
```

The parameterless `GET /metrics` endpoint returns the Prometheus text
exposition format. Representative metric families include:

- `http_requests_total`, request and response sizes, and request durations;
- `python_info` and `python_gc_*` runtime metrics;
- `process_*` CPU, memory, and start-time metrics on supported Linux runtimes.

The Docker image runs on Linux and exposes all three groups. Runtime-dependent
process metrics may not be available when the application runs directly on a
different operating system.

`/metrics` is an operational endpoint, so it is intentionally omitted from
FastAPI's generated documentation and OpenAPI schema. Phase 4 exposes only the
default metrics; HiveBox-specific business metrics are introduced separately
in Phase 5.

#### Run with Docker

The multi-stage build installs the application in an isolated virtual
environment and copies only that environment into the runtime stage. The final
container uses the pinned slim Python image and runs as the unprivileged user
`10001:10001`.

Validate the Dockerfile and build the image from the repository root:

```shell
docker build --check .
docker build --tag hivebox:v0.1.0 .
```

Run the API and publish its port locally:

```shell
docker run --rm --publish 8000:8000 hivebox:v0.1.0
```

Pass a custom senseBox configuration to the container at runtime:

```shell
docker run --rm \
  --env HIVEBOX_SENSEBOX_IDS="5eba5fbad46fb8001b799786,5c21ff8f919bf8001adf2488" \
  --publish 8000:8000 \
  hivebox:v0.1.0
```

The equivalent environment entry in a future Kubernetes workload manifest is:

```yaml
env:
  - name: HIVEBOX_SENSEBOX_IDS
    value: "5eba5fbad46fb8001b799786,5c21ff8f919bf8001adf2488"
```

This example only shows the application configuration contract. Kubernetes
manifests are introduced separately during Phase 4.

You can verify that the configured process is not running as root:

```shell
docker run --rm --entrypoint id hivebox:v0.1.0
```

The API documentation is then available at `http://127.0.0.1:8000/docs`, and
the OpenAPI schema at `http://127.0.0.1:8000/openapi.json`. Press `Ctrl+C` to
stop the API. The `--rm` option removes the stopped container automatically.

The application version comes from the installed package metadata generated
from `project.version` in `pyproject.toml`.

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

#### Continuous integration

The GitHub Actions workflow runs for pull requests and subsequent pushes to
`develop` and `main`. Its independent checks enforce:

- Gitflow branch direction and Conventional Commits pull request titles
- GitHub Actions syntax
- Python linting, formatting, strict static typing and package integrity
- unit tests, the coverage threshold and deterministic integration tests over
  HTTP
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

#### Supply-chain security analysis

OpenSSF Scorecard evaluates the repository's software supply-chain security
practices. It checks repository configuration and development practices such as
workflow permissions, pinned dependencies, branch protection, security policy,
code review and vulnerability handling. It complements the application checks
in continuous integration; it does not replace tests, linters or vulnerability
scanners.

The Scorecard workflow runs after pushes to `main` and every Saturday at
01:30 UTC. Feature branches target `develop`, so their pull requests do not run
this repository-level analysis. The first canonical result for a change appears
after a release branch is merged into `main`.

Each run publishes its SARIF results to GitHub Code Scanning and to the public
OpenSSF Scorecard service. The same SARIF file is available as a workflow
artifact for five days. Consult the workflow run in the repository's Actions
tab, its findings under **Security > Code scanning**, or the public
[OpenSSF Scorecard viewer](https://scorecard.dev/viewer/?uri=github.com/MarcPerezdeTudela/devops-hands-on-project-hivebox).

### Phase 4: Local Kubernetes gateway

HiveBox uses [KIND](https://kind.sigs.k8s.io/) to run a local Kubernetes cluster
on Docker. KIND means **Kubernetes IN Docker**: it creates a Docker container
that behaves as a Kubernetes node. It does not put Kubernetes inside the
HiveBox application container. A later step will deploy HiveBox as a separate
pod managed by this cluster.

Incoming HTTP traffic uses the Kubernetes
[Gateway API](https://gateway-api.sigs.k8s.io/). Gateway API is a collection of
Kubernetes resource definitions; it needs a controller that turns those
declarations into running infrastructure. HiveBox uses
[Envoy Gateway](https://gateway.envoyproxy.io/) as that controller and Envoy
Proxy as the process that receives each request.

The resources introduced here have different responsibilities:

- `EnvoyProxy` tells Envoy Gateway how to expose the generated proxy Service;
- `GatewayClass` associates HiveBox Gateways with the Envoy Gateway controller;
- `Gateway` requests an HTTP listener on port 80;
- a future `HTTPRoute` from issue #25 will describe which requests go to the
  HiveBox Service.

`HTTPRoute` is configuration consumed by the controller, not a process through
which network packets travel. Once issue #25 is implemented, the runtime path
will be:

```text
127.0.0.1:8080
  -> KIND node container port 30080
  -> Envoy NodePort Service
  -> Envoy Proxy pod
  -> HiveBox Service
  -> HiveBox pod
```

This phase pins Kubernetes 1.36.4 because it is both available for KIND 0.33.0
and supported by Envoy Gateway 1.9.0. The KIND node image is pinned by digest,
so the cluster does not silently change when a tag is republished. The Envoy
Gateway release manifest is downloaded at runtime and verified with SHA-256
before Kubernetes receives it.

#### Prerequisites

Install and start:

- Docker with a running Docker engine;
- KIND 0.33.0;
- `kubectl` 1.37.0;
- `curl` and `shasum`.

The `kubectl` client may be one minor version newer than the Kubernetes API
server. Check the tools from the repository root:

```shell
docker version
docker info
kind version
kubectl version --client
curl --version
shasum --version
```

Port 8080 must be free. This command should produce no output:

```shell
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

List existing KIND clusters:

```shell
kind get clusters
```

If `hivebox` already exists, inspect or delete it deliberately before creating
a fresh environment. KIND must never replace an existing cluster implicitly.

#### Create the KIND cluster

Create a temporary kubeconfig and keep these variables in the same terminal for
the entire lifecycle:

```shell
HIVEBOX_KUBECONFIG="$(mktemp "${TMPDIR:-/tmp}/hivebox-kubeconfig.XXXXXX")"
export HIVEBOX_KUBECONFIG
```

A kubeconfig contains cluster addresses and credentials used by `kubectl`.
Using a dedicated temporary file prevents KIND from modifying the default
kubeconfig or changing its current context.

Create the single-node cluster:

```shell
kind create cluster \
  --name hivebox \
  --config kubernetes/kind/cluster.yaml \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --wait 120s
```

The KIND configuration maps only `127.0.0.1:8080` on the host to TCP port
`30080` in the node container. Binding to loopback means the gateway is not
exposed to other machines on the local network.

Wait for the node to report that it can accept workloads:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  wait \
  --for=condition=Ready \
  node/hivebox-control-plane \
  --timeout=120s
```

Every Kubernetes command below includes the dedicated kubeconfig and context.
This repetition is intentional: it makes the target cluster unambiguous.

#### Install Envoy Gateway

Download the Envoy Gateway 1.9.0 installer into another temporary location:

```shell
HIVEBOX_ENVOY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hivebox-envoy.XXXXXX")"
export HIVEBOX_ENVOY_DIR

curl \
  --fail \
  --location \
  --silent \
  --show-error \
  --output "$HIVEBOX_ENVOY_DIR/install.yaml" \
  https://github.com/envoyproxy/gateway/releases/download/v1.9.0/install.yaml
```

Verify the exact release asset. A successful command prints `OK`:

```shell
printf '%s  %s\n' \
  a83dea73466ee6528f0d23f86d36573fbf1f305c822d986a63e262e32594481a \
  "$HIVEBOX_ENVOY_DIR/install.yaml" \
  | shasum -a 256 --check
```

Do not continue if the checksum differs. A mismatch means the downloaded bytes
are not the artifact reviewed for this repository.

Apply the verified manifest with server-side apply. Envoy Gateway's installer
contains large CRDs, for which server-side apply avoids the annotation size
limit of client-side apply:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply \
  --server-side \
  --filename "$HIVEBOX_ENVOY_DIR/install.yaml"
```

Wait for the Envoy Gateway control-plane Deployment:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  wait \
  --for=condition=Available \
  deployment/envoy-gateway \
  --timeout=5m
```

#### Configure the HiveBox gateway

Ask the real API server to validate the three local manifests without saving
them:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply \
  --server-side \
  --dry-run=server \
  --filename kubernetes/gateway/
```

Then apply the same directory. File names keep the dependency order visible:
the `EnvoyProxy` configuration comes before the class that references it, and
the class comes before the Gateway.

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply \
  --server-side \
  --filename kubernetes/gateway/
```

Wait for Envoy Gateway to accept the class and program the listener:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  wait \
  --for=condition=Accepted \
  gatewayclass/hivebox \
  --timeout=5m

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  wait \
  --for=condition=Programmed \
  gateway/hivebox \
  --timeout=5m
```

`Accepted` means the controller recognizes and will manage the GatewayClass.
`Programmed` means it has created and configured the Envoy data plane requested
by the Gateway.

#### Verify the gateway

Select the generated Envoy resources through stable ownership labels instead
of relying on their generated names:

```shell
HIVEBOX_ENVOY_SELECTOR='gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=hivebox'
export HIVEBOX_ENVOY_SELECTOR

HIVEBOX_ENVOY_DEPLOYMENT="$(kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get deployments \
  --selector "$HIVEBOX_ENVOY_SELECTOR" \
  --output jsonpath='{.items[0].metadata.name}')"
export HIVEBOX_ENVOY_DEPLOYMENT

HIVEBOX_ENVOY_SERVICE="$(kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get services \
  --selector "$HIVEBOX_ENVOY_SELECTOR" \
  --output jsonpath='{.items[0].metadata.name}')"
export HIVEBOX_ENVOY_SERVICE
```

Both variables must contain a generated name:

```shell
test -n "$HIVEBOX_ENVOY_DEPLOYMENT"
test -n "$HIVEBOX_ENVOY_SERVICE"
printf 'Deployment: %s\nService: %s\n' \
  "$HIVEBOX_ENVOY_DEPLOYMENT" \
  "$HIVEBOX_ENVOY_SERVICE"
```

Wait for the proxy Deployment and inspect the resources:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  rollout status \
  "deployment/$HIVEBOX_ENVOY_DEPLOYMENT" \
  --timeout=5m

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  get nodes,gatewayclasses

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get gateways,pods,services
```

Confirm that the generated HTTP Service port is the expected NodePort:

```shell
HIVEBOX_NODE_PORT="$(kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get "service/$HIVEBOX_ENVOY_SERVICE" \
  --output jsonpath='{.spec.ports[?(@.port==80)].nodePort}')"

test "$HIVEBOX_NODE_PORT" = 30080

docker port hivebox-control-plane 30080/tcp \
  | grep --fixed-strings '127.0.0.1:8080'
```

No application route belongs to issue #24, so this command must report no
resources:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  get httproutes \
  --all-namespaces
```

Request a unique path from the listener and capture its status:

```shell
HIVEBOX_CHECK_PATH='/issue-24-gateway-check'
export HIVEBOX_CHECK_PATH

HIVEBOX_HTTP_STATUS="$(curl \
  --silent \
  --show-error \
  --max-time 10 \
  --output /dev/null \
  --write-out '%{http_code}' \
  "http://127.0.0.1:8080$HIVEBOX_CHECK_PATH")"

test "$HIVEBOX_HTTP_STATUS" = 404
```

Confirm that Envoy logged that exact path as a missing route:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  logs \
  "deployment/$HIVEBOX_ENVOY_DEPLOYMENT" \
  --container envoy \
  --tail=20 \
  | grep --fixed-strings '"response_code":404' \
  | grep --fixed-strings '"response_code_details":"route_not_found"' \
  | grep --fixed-strings '"x-envoy-origin-path":"/issue-24-gateway-check"'
```

The 404 plus the matching Envoy access-log entry is the expected success result
for issue #24. It proves the request crossed Docker's port mapping, the
Kubernetes NodePort Service, and the Envoy Proxy listener. Envoy has no
`HTTPRoute` yet, so it correctly has nowhere to forward the request. Issue #25
will add the route and HiveBox workload.

#### Troubleshoot the environment

If a wait or request fails, inspect desired state, observed state, events, and
logs in that order:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  describe gatewayclass/hivebox

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  describe gateway/hivebox

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get events \
  --sort-by=.lastTimestamp

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  logs \
  deployment/envoy-gateway
```

Also check `docker info`, `kind get clusters`, the port-8080 listener, the
generated Service's NodePort, and the Envoy proxy pod status. A checksum failure
is not a Kubernetes problem: stop before installation and verify the upstream
release asset.

#### Delete and rebuild the environment

Delete only the named KIND cluster, still using its dedicated kubeconfig:

```shell
kind delete cluster \
  --name hivebox \
  --kubeconfig "$HIVEBOX_KUBECONFIG"
```

Remove only the temporary files created during this lifecycle:

```shell
rm -- "$HIVEBOX_ENVOY_DIR/install.yaml"
rmdir -- "$HIVEBOX_ENVOY_DIR"
rm -- "$HIVEBOX_KUBECONFIG"

unset HIVEBOX_CHECK_PATH
unset HIVEBOX_ENVOY_DEPLOYMENT
unset HIVEBOX_ENVOY_DIR
unset HIVEBOX_ENVOY_SELECTOR
unset HIVEBOX_ENVOY_SERVICE
unset HIVEBOX_HTTP_STATUS
unset HIVEBOX_KUBECONFIG
unset HIVEBOX_NODE_PORT
```

Run the complete create, install, configure, verify, and delete procedure again
with newly generated temporary paths. A second successful clean lifecycle
demonstrates that the environment is reproducible rather than dependent on
leftover cluster state.
