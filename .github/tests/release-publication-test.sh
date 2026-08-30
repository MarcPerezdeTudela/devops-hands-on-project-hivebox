#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
TEMPORARY_ROOT=$(mktemp -d)
trap 'rm -rf "${TEMPORARY_ROOT}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

create_fixture() {
  local name="$1"
  local directory="${TEMPORARY_ROOT}/${name}"
  local remote="${TEMPORARY_ROOT}/${name}.git"

  git init --bare --quiet "${remote}"
  git init --quiet "${directory}"
  git -C "${directory}" config user.email hivebox@example.invalid
  git -C "${directory}" config user.name HiveBox
  git -C "${directory}" checkout --quiet -b main
  git -C "${directory}" commit --allow-empty --quiet --message fixture
  git -C "${directory}" remote add origin "${remote}"
  git -C "${directory}" push --quiet --set-upstream origin main
  printf '%s\n' "${directory}"
}

run_publication() {
  local directory="$1"
  local version="$2"
  local merge_sha="$3"
  local main_sha="$4"

  (cd "${directory}" && \
    RELEASE_VERSION="${version}" MERGE_SHA="${merge_sha}" MAIN_SHA="${main_sha}" \
    bash "${REPOSITORY_ROOT}/.github/scripts/release-publication.sh")
}

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    fail "unexpected success: $*"
  fi
}

fixture=$(create_fixture new-tag)
main_sha=$(git -C "${fixture}" rev-parse HEAD)
[[ "$(run_publication "${fixture}" 1.2.3 "${main_sha}" "${main_sha}")" == v1.2.3 ]] \
  || fail 'new release tag was not reported'
[[ "$(git -C "${fixture}" cat-file -t refs/tags/v1.2.3)" == tag ]] \
  || fail 'new release tag is not annotated'
[[ "$(git -C "${fixture}" rev-parse v1.2.3^{})" == "${main_sha}" ]] \
  || fail 'new release tag does not point to the merge SHA'
[[ "$(run_publication "${fixture}" 1.2.3 "${main_sha}" "${main_sha}")" == v1.2.3 ]] \
  || fail 'matching tag retry was not a no-op'

conflicting=$(create_fixture conflicting-tag)
conflicting_sha=$(git -C "${conflicting}" rev-parse HEAD)
git -C "${conflicting}" commit --allow-empty --quiet --message next
conflicting_main=$(git -C "${conflicting}" rev-parse HEAD)
git -C "${conflicting}" tag --annotate v1.2.3 "${conflicting_sha}" --message 'Release v1.2.3'
expect_failure run_publication "${conflicting}" 1.2.3 "${conflicting_main}" "${conflicting_main}"

lightweight=$(create_fixture lightweight-tag)
lightweight_sha=$(git -C "${lightweight}" rev-parse HEAD)
git -C "${lightweight}" tag v1.2.3 "${lightweight_sha}"
expect_failure run_publication "${lightweight}" 1.2.3 "${lightweight_sha}" "${lightweight_sha}"

invalid=$(create_fixture invalid-version)
invalid_sha=$(git -C "${invalid}" rev-parse HEAD)
expect_failure run_publication "${invalid}" 1.2 "${invalid_sha}" "${invalid_sha}"

moved=$(create_fixture moved-main)
merge_sha=$(git -C "${moved}" rev-parse HEAD)
git -C "${moved}" commit --allow-empty --quiet --message later
main_sha=$(git -C "${moved}" rev-parse HEAD)
expect_failure run_publication "${moved}" 1.2.3 "${merge_sha}" "${main_sha}"
! git -C "${moved}" rev-parse --verify --quiet refs/tags/v1.2.3 >/dev/null \
  || fail 'moved main created a tag'

printf 'All release publication tests passed.\n'
