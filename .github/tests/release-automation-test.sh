#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
TEMPORARY_ROOT=$(mktemp -d)
trap 'rm -rf "${TEMPORARY_ROOT}"' EXIT
CURRENT_VERSION=$(python3 -c \
  'import pathlib, tomllib; print(tomllib.loads(pathlib.Path("pyproject.toml").read_text())["project"]["version"])')
IFS=. read -r VERSION_MAJOR VERSION_MINOR VERSION_PATCH <<< "${CURRENT_VERSION}"
PATCH_VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.$((VERSION_PATCH + 1))"
MINOR_VERSION="${VERSION_MAJOR}.$((VERSION_MINOR + 1)).0"
MAJOR_VERSION="$((VERSION_MAJOR + 1)).0.0"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

create_fixture() {
  local name="$1"
  local branch="$2"
  local directory="${TEMPORARY_ROOT}/${name}"

  mkdir -p "${directory}/.github/scripts" "${directory}/kubernetes/app" \
    "${directory}/tests/integration"
  cp "${REPOSITORY_ROOT}/Makefile" "${directory}/"
  cp "${REPOSITORY_ROOT}/pyproject.toml" "${directory}/"
  cp "${REPOSITORY_ROOT}/README.md" "${directory}/"
  cp "${REPOSITORY_ROOT}/kubernetes/app/deployment.yaml" \
    "${directory}/kubernetes/app/"
  cp "${REPOSITORY_ROOT}/tests/test_version.py" "${directory}/tests/"
  cp "${REPOSITORY_ROOT}/tests/integration/test_api.py" \
    "${directory}/tests/integration/"
  cp "${REPOSITORY_ROOT}/.github/scripts/release-preflight.sh" \
    "${directory}/.github/scripts/"
  cp "${REPOSITORY_ROOT}/.github/scripts/release-version.sh" \
    "${directory}/.github/scripts/"

  git -C "${directory}" init --quiet
  git -C "${directory}" config user.email hivebox@example.invalid
  git -C "${directory}" config user.name HiveBox
  git -C "${directory}" add .
  git -C "${directory}" commit --quiet --message fixture
  git -C "${directory}" branch --move main
  git -C "${directory}" tag "v${CURRENT_VERSION}"
  git -C "${directory}" switch --quiet --create "${branch}"
  printf '%s\n' "${directory}"
}

expect_preflight_failure() {
  local directory="$1"
  local version="$2"
  if (cd "${directory}" && bash .github/scripts/release-preflight.sh "${version}") \
    >/dev/null 2>&1; then
    fail "preflight unexpectedly accepted ${version} in ${directory}"
  fi
}

release_directory=$(create_fixture release "release/${PATCH_VERSION}")
(cd "${release_directory}" && bash .github/scripts/release-preflight.sh "${PATCH_VERSION}")
touch "${release_directory}/untracked"
expect_preflight_failure "${release_directory}" "${PATCH_VERSION}"
rm "${release_directory}/untracked"
expect_preflight_failure "${release_directory}" "${MINOR_VERSION}"

hotfix_directory=$(create_fixture hotfix "hotfix/${PATCH_VERSION}")
(cd "${hotfix_directory}" && bash .github/scripts/release-preflight.sh "${PATCH_VERSION}")

invalid_directory=$(create_fixture invalid feature/release-check)
expect_preflight_failure "${invalid_directory}" "${PATCH_VERSION}"

expect_version() {
  local directory="$1"
  local expected="$2"
  local actual

  actual=$(cd "${directory}" && bash .github/scripts/release-version.sh)
  [[ "${actual}" == "${expected}" ]] \
    || fail "expected version ${expected}, got ${actual}"
}

expect_no_version() {
  local directory="$1"

  if (cd "${directory}" && bash .github/scripts/release-version.sh) \
    >/dev/null 2>&1; then
    fail "version calculation unexpectedly succeeded in ${directory}"
  fi
}

patch_directory=$(create_fixture version-patch develop)
git -C "${patch_directory}" commit --allow-empty --quiet --message 'fix(api): repair endpoint'
expect_version "${patch_directory}" "${PATCH_VERSION}"

minor_directory=$(create_fixture version-minor develop)
git -C "${minor_directory}" commit --allow-empty --quiet --message 'fix(api): repair endpoint'
git -C "${minor_directory}" commit --allow-empty --quiet --message 'feat(api): add endpoint'
expect_version "${minor_directory}" "${MINOR_VERSION}"

major_directory=$(create_fixture version-major develop)
git -C "${major_directory}" commit --allow-empty --quiet --message 'feat(api)!: change contract'
expect_version "${major_directory}" "${MAJOR_VERSION}"

breaking_footer_directory=$(create_fixture version-footer develop)
git -C "${breaking_footer_directory}" commit --allow-empty --quiet \
  --message 'fix(api): change contract' --message 'BREAKING CHANGE: old clients stop working'
expect_version "${breaking_footer_directory}" "${MAJOR_VERSION}"

no_release_directory=$(create_fixture version-none develop)
git -C "${no_release_directory}" commit --allow-empty --quiet --message 'docs(readme): clarify usage'
expect_no_version "${no_release_directory}"

hotfix_backmerge_directory=$(create_fixture version-hotfix-backmerge develop)
git -C "${hotfix_backmerge_directory}" switch --quiet main
git -C "${hotfix_backmerge_directory}" commit --allow-empty --quiet \
  --message 'fix(cd): production correction'
git -C "${hotfix_backmerge_directory}" tag --force "v${CURRENT_VERSION}"
git -C "${hotfix_backmerge_directory}" switch --quiet develop
git -C "${hotfix_backmerge_directory}" commit --allow-empty --quiet \
  --message "chore(release): backmerge hotfix v${CURRENT_VERSION} (#61)"
git -C "${hotfix_backmerge_directory}" commit --allow-empty --quiet \
  --message 'fix(api): repair after hotfix'
expect_version "${hotfix_backmerge_directory}" "${PATCH_VERSION}"

for part in patch minor major; do
  case "${part}" in
    patch) version=${PATCH_VERSION} ;;
    minor) version=${MINOR_VERSION} ;;
    major) version=${MAJOR_VERSION} ;;
  esac

  directory=$(create_fixture "bump-${part}" "release/${version}")
  initial_head=$(git -C "${directory}" rev-parse HEAD)
  initial_tags=$(git -C "${directory}" tag --points-at "${initial_head}")
  (cd "${directory}" && make "release-bump-${part}")

  [[ "$(git -C "${directory}" rev-parse HEAD)" == "${initial_head}" ]] \
    || fail "${part} bump created a commit"
  for file in \
    pyproject.toml \
    kubernetes/app/deployment.yaml \
    tests/test_version.py \
    tests/integration/test_api.py \
    README.md; do
    grep --fixed-strings "${version}" "${directory}/${file}" >/dev/null \
      || fail "${part} bump did not update ${file}"
  done
  [[ "$(git -C "${directory}" tag --points-at "${initial_head}")" == "${initial_tags}" ]] \
    || fail "${part} bump created a tag"
done

printf 'All controlled release automation tests passed.\n'
