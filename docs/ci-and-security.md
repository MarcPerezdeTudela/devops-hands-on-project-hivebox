# Continuous integration and security

GitHub Actions validates pull-request policy, workflow syntax, Python quality,
unit and integration tests, Kubernetes manifests, and the container image.
Independent checks run in parallel with minimal permissions and timeouts.

SonarQube Cloud evaluates code quality and the OpenSSF Scorecard assesses
repository supply-chain practices. Container and manifest scans complement
these services with focused security checks.

## SonarQube and pull requests from forks

GitHub does not provide repository secrets, including `SONAR_TOKEN`, to
workflows triggered by pull requests from forks. Consequently, the
`sonarqube-quality-gate` job reports the missing configuration and cannot pass
for an external fork pull request. The remaining unprivileged pull-request
checks still run without that secret.

Do not change this workflow to `pull_request_target` or otherwise run
fork-provided code with `SONAR_TOKEN`. That would grant an untrusted pull
request access to a credential that can submit analysis for this repository.

For an external contribution, a maintainer should first review the pull request
and then apply the reviewed commits to a branch in this repository. The trusted
branch pull request receives the normal SonarQube analysis and can satisfy the
required quality gate. The original fork pull request remains the review record
and must not be merged until its equivalent trusted branch has passed the
required checks.

If the project later needs self-service fork contributions, separate the
privileged SonarQube analysis from checks required of fork pull requests. Keep
the privileged analysis restricted to trusted repository branches; do not make
its secret available to code from the fork.
