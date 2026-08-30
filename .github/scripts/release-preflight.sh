#!/usr/bin/env bash

set -euo pipefail

expected_version=${1:?"Usage: release-preflight.sh VERSION"}
branch=$(git branch --show-current)

case "${branch}" in
  release/* | hotfix/*) ;;
  *)
    printf 'Release preparation requires a release/* or hotfix/* branch; got %q.\n' \
      "${branch}" >&2
    exit 1
    ;;
esac

branch_version=${branch#*/}
if [[ "${branch_version}" != "${expected_version}" ]]; then
  printf 'Branch version %q must match the requested version %q.\n' \
    "${branch_version}" "${expected_version}" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  printf 'Release preparation requires a clean working tree.\n' >&2
  exit 1
fi
