#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
workflow=$(<"${REPOSITORY_ROOT}/.github/workflows/cd.yml")

[[ "${workflow}" == *'name: Check for an existing release image'* ]] \
  || { printf 'FAIL: missing existing image check\n' >&2; exit 1; }
[[ "${workflow}" == *'docker buildx imagetools inspect'* ]] \
  || { printf 'FAIL: existing image check does not inspect the registry\n' >&2; exit 1; }
[[ "${workflow}" == *"if: steps.existing-image.outputs.exists != 'true'"* ]] \
  || { printf 'FAIL: image build is not conditional on a missing tag\n' >&2; exit 1; }
[[ "${workflow}" == *'steps.published-image.outputs.digest'* ]] \
  || { printf 'FAIL: workflow does not report the selected digest\n' >&2; exit 1; }

printf 'All release image publication tests passed.\n'
