# Observability

HiveBox exposes Prometheus-compatible runtime metrics at `/metrics`. They
include HTTP instrumentation plus Python and, where supported, process metrics.

The endpoint is intentionally operational rather than part of the public API
schema. The current phase exposes default runtime metrics only; business
metrics, dashboards, and alerts are future work.
