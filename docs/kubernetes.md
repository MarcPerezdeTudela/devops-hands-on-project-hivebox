# Kubernetes

HiveBox runs locally in a KIND cluster. Envoy Gateway implements the Kubernetes
Gateway API and forwards local HTTP traffic to the HiveBox Service and Pod.

The complete request path is:

```text
127.0.0.1:8080
  -> KIND node port 30080
  -> Envoy NodePort Service
  -> Envoy Proxy pod
  -> HiveBox ClusterIP Service
  -> HiveBox pod port 8000
```

## Prerequisites

Install Docker with a running daemon, KIND 0.33.0, `kubectl` 1.37.0, `curl`,
and `shasum`. Port 8080 must be free:

```shell
docker info
kind version
kubectl version --client
curl --version
shasum --version
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

The final command must produce no output. The cluster configuration pins the
KIND node image to Kubernetes 1.36.4 and maps only `127.0.0.1:8080` to its
NodePort 30080.

## Create the KIND cluster

Use a dedicated temporary kubeconfig so the procedure does not alter the
default Kubernetes context:

```shell
HIVEBOX_KUBECONFIG="$(mktemp "${TMPDIR:-/tmp}/hivebox-kubeconfig.XXXXXX")"
export HIVEBOX_KUBECONFIG

kind create cluster \
  --name hivebox \
  --config kubernetes/kind/cluster.yaml \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --wait 120s

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  wait --for=condition=Ready node/hivebox-control-plane --timeout=120s
```

The node must report `condition met` before continuing.

## Install Envoy Gateway

Download the pinned Envoy Gateway 1.9.0 installer and verify it before
applying it:

```shell
HIVEBOX_ENVOY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hivebox-envoy.XXXXXX")"
export HIVEBOX_ENVOY_DIR

curl \
  --fail --location --silent --show-error \
  --output "$HIVEBOX_ENVOY_DIR/install.yaml" \
  https://github.com/envoyproxy/gateway/releases/download/v1.9.0/install.yaml

printf '%s  %s\n' \
  a83dea73466ee6528f0d23f86d36573fbf1f305c822d986a63e262e32594481a \
  "$HIVEBOX_ENVOY_DIR/install.yaml" \
  | shasum -a 256 --check

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --filename "$HIVEBOX_ENVOY_DIR/install.yaml"

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  wait --for=condition=Available deployment/envoy-gateway --timeout=5m
```

The checksum command must print `OK`. Do not continue if it differs.

## Configure and validate the gateway

Apply the gateway resources in their dependency order: `EnvoyProxy`,
`GatewayClass`, then `Gateway`.

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --dry-run=server --filename kubernetes/gateway/

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --filename kubernetes/gateway/

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  wait --for=condition=Accepted gatewayclass/hivebox --timeout=5m

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  wait --for=condition=Programmed gateway/hivebox --timeout=5m
```

`Accepted=True` means the controller manages the GatewayClass;
`Programmed=True` means the Envoy listener is configured. Confirm that the
generated service exposes the expected NodePort:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace envoy-gateway-system \
  get services --output wide
```

The HTTP service must expose NodePort `30080`.

## Build and load HiveBox

The Deployment uses `imagePullPolicy: Never`, so load the exact local image
into the KIND node:

```shell
HIVEBOX_VERSION="$(python3 -c \
  'import pathlib, tomllib; print(tomllib.loads(pathlib.Path("pyproject.toml").read_text())["project"]["version"])')"
HIVEBOX_IMAGE="hivebox:v$HIVEBOX_VERSION"
export HIVEBOX_IMAGE HIVEBOX_VERSION

grep --fixed-strings "image: $HIVEBOX_IMAGE" kubernetes/app/deployment.yaml
docker build --tag "$HIVEBOX_IMAGE" .
kind load docker-image "$HIVEBOX_IMAGE" --name hivebox
```

The `grep` command confirms that the manifest and package version agree.

## Deploy the application

Create the namespace first, then validate and apply the application resources:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --filename kubernetes/app/namespace.yaml

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --dry-run=server --filename kubernetes/app/

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  apply --server-side --filename kubernetes/app/

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace hivebox \
  rollout status deployment/hivebox --timeout=5m

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace hivebox \
  wait --for=condition=Ready pod --selector app.kubernetes.io/name=hivebox --timeout=5m
```

Inspect the deployed objects and validate that the route was accepted:

```shell
kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace hivebox \
  get deployments,pods,services,endpointslices,httproutes --output wide

kubectl \
  --kubeconfig "$HIVEBOX_KUBECONFIG" \
  --context kind-hivebox \
  --namespace hivebox \
  get httproute/hivebox \
  --output jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status}{"\\n"}{end}'
```

Expect one available Deployment, one Ready Pod, a Service on port 8000, and
`Accepted=True` plus `ResolvedRefs=True` for the HTTPRoute.

## Smoke-test the public route

Retry `/version` while the application starts, then inspect metrics:

```shell
HIVEBOX_VERSION_BODY="$(curl \
  --fail --silent --show-error --connect-timeout 2 --max-time 5 \
  --retry 20 --retry-all-errors --retry-delay 1 \
  http://127.0.0.1:8080/version)"
test "$HIVEBOX_VERSION_BODY" = "{\"version\":\"$HIVEBOX_VERSION\"}"

curl --fail --silent --show-error http://127.0.0.1:8080/metrics \
  | grep --fixed-strings 'python_info'
```

The version assertion and representative Prometheus metric prove that traffic
crosses the host mapping, Gateway, route, Service, and Pod.

## Diagnose failures

Inspect desired state, observed state, events, and logs in that order:

```shell
kubectl --kubeconfig "$HIVEBOX_KUBECONFIG" --context kind-hivebox \
  --namespace hivebox describe deployment/hivebox
kubectl --kubeconfig "$HIVEBOX_KUBECONFIG" --context kind-hivebox \
  --namespace hivebox get pods,services,endpointslices,httproutes --output wide
kubectl --kubeconfig "$HIVEBOX_KUBECONFIG" --context kind-hivebox \
  --namespace hivebox logs deployment/hivebox
kubectl --kubeconfig "$HIVEBOX_KUBECONFIG" --context kind-hivebox \
  --namespace hivebox get events --sort-by=.lastTimestamp
kubectl --kubeconfig "$HIVEBOX_KUBECONFIG" --context kind-hivebox \
  --namespace envoy-gateway-system logs deployment/envoy-gateway
```

`ErrImageNeverPull` means the image was not loaded into KIND. A Service without
an EndpointSlice address indicates a label or Pod problem. `Accepted=False` or
`ResolvedRefs=False` identifies a Gateway attachment or backend reference
problem.

## Tear down

Delete only the named cluster and the temporary files created by this runbook:

```shell
kind delete cluster --name hivebox --kubeconfig "$HIVEBOX_KUBECONFIG"
rm -- "$HIVEBOX_ENVOY_DIR/install.yaml"
rmdir -- "$HIVEBOX_ENVOY_DIR"
rm -- "$HIVEBOX_KUBECONFIG"
unset HIVEBOX_ENVOY_DIR HIVEBOX_IMAGE HIVEBOX_KUBECONFIG HIVEBOX_VERSION
```

Do not delete another cluster, the default kubeconfig, or shared Gateway
resources outside this named local environment.
