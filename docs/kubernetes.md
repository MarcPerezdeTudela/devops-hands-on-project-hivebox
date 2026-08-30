# Kubernetes

HiveBox runs locally in a KIND cluster. Envoy Gateway implements the Kubernetes
Gateway API, forwarding requests from the local proxy to the HiveBox Service
and its Pod.

The manifests define a namespace, configuration, service, HTTP route, and a
least-privilege deployment. The image is loaded into KIND locally and uses
`imagePullPolicy: Never` so deployment is explicit and reproducible.
