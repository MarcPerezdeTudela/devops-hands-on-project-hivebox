# Continuous integration and security

GitHub Actions validates pull-request policy, workflow syntax, Python quality,
unit and integration tests, Kubernetes manifests, and the container image.
Independent checks run in parallel with minimal permissions and timeouts.

SonarQube Cloud evaluates code quality and the OpenSSF Scorecard assesses
repository supply-chain practices. Container and manifest scans complement
these services with focused security checks.

## Published image vulnerability scans

`published-image-scan.yml` runs every Saturday at 01:45 UTC and can also be
started manually. It resolves the latest GitHub Release tag, obtains the
corresponding GHCR image digest, and records both values in the workflow
summary so findings are tied to an immutable image.

The first Trivy scan reports every HIGH and CRITICAL vulnerability, including
unfixed findings, without failing the run. A second scan fails when it detects
a fixable HIGH or CRITICAL vulnerability. Review the first scan's log before
addressing the failing gate, because it preserves the full finding set.

## SonarQube and pull requests from forks

GitHub does not provide repository secrets, including `SONAR_TOKEN`, to
workflows triggered by pull requests from forks. Consequently, the
`sonarqube-quality-gate` job reports the missing configuration and cannot pass
for an external fork pull request. The remaining unprivileged pull-request
checks still run without that secret.

Do not change this workflow to `pull_request_target` or otherwise run
fork-provided code with `SONAR_TOKEN`. That would grant an untrusted pull
request access to a credential that can submit analysis for this repository.

For an external contribution, a maintainer should:

1. Review the pull request from the fork without exposing repository secrets.
2. Apply the reviewed commits to a branch in this repository and open a trusted
   branch pull request that links to the external contribution.
3. Validate and merge the trusted branch pull request after its required checks,
   including the normal SonarQube analysis, pass.
4. Close the original fork pull request without merging it, link to the trusted
   pull request, and credit the external author for the contribution.

The external pull request remains the review and attribution record, while the
trusted branch pull request is the integration vehicle.

If the project later needs self-service fork contributions, separate the
privileged SonarQube analysis from checks required of fork pull requests. Keep
the privileged analysis restricted to trusted repository branches; do not make
its secret available to code from the fork.
