#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
workflow=$(<"${REPOSITORY_ROOT}/.github/workflows/published-image-scan.yml")

[[ "${workflow}" == *'schedule:'* ]] \
  || { printf 'FAIL: missing scheduled trigger\n' >&2; exit 1; }
[[ "${workflow}" == *'workflow_dispatch:'* ]] \
  || { printf 'FAIL: missing manual trigger\n' >&2; exit 1; }
[[ "${workflow}" == *'packages: read'* ]] \
  || { printf 'FAIL: missing GHCR read permission\n' >&2; exit 1; }
[[ "${workflow}" == *'gh release view'* ]] \
  || { printf 'FAIL: workflow does not resolve the latest release\n' >&2; exit 1; }
[[ "${workflow}" == *'docker buildx imagetools inspect'* ]] \
  || { printf 'FAIL: workflow does not resolve the image digest\n' >&2; exit 1; }
[[ "${workflow}" == *'Image: \`${reference}\`'* ]] \
  || { printf 'FAIL: workflow does not report the image tag\n' >&2; exit 1; }
[[ "${workflow}" == *'Digest: \`${digest}\`'* ]] \
  || { printf 'FAIL: workflow does not report the image digest\n' >&2; exit 1; }
[[ "${workflow}" == *'name: Report published image vulnerabilities'* ]] \
  || { printf 'FAIL: missing non-blocking vulnerability report\n' >&2; exit 1; }
[[ "${workflow}" == *'name: Fail on fixable published image vulnerabilities'* ]] \
  || { printf 'FAIL: missing fixable vulnerability gate\n' >&2; exit 1; }
[[ "${workflow}" == *'ignore-unfixed: false'* ]] \
  || { printf 'FAIL: report does not include unfixed vulnerabilities\n' >&2; exit 1; }
[[ "${workflow}" == *'ignore-unfixed: true'* ]] \
  || { printf 'FAIL: gate does not target fixable vulnerabilities\n' >&2; exit 1; }

printf 'All published image scan workflow tests passed.\n'
