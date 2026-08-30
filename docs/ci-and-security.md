# Continuous integration and security

GitHub Actions validates pull-request policy, workflow syntax, Python quality,
unit and integration tests, Kubernetes manifests, and the container image.
Independent checks run in parallel with minimal permissions and timeouts.

SonarQube Cloud evaluates code quality and the OpenSSF Scorecard assesses
repository supply-chain practices. Container and manifest scans complement
these services with focused security checks.
