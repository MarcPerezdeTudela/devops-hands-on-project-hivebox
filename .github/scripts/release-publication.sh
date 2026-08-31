#!/usr/bin/env bash

set -euo pipefail

publication_error() {
  printf '::error::%s\n' "$*" >&2
  return 1
}

release_tag_for_version() {
  local version="$1"

  [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || publication_error \
    "Release version ${version} must be a semantic version without a prefix." || return 1
  printf 'v%s\n' "${version}"
}

create_release_tag() {
  local version="$1"
  local merge_sha="$2"
  local main_sha="$3"
  local release_tag tag_sha tag_type

  release_tag=$(release_tag_for_version "${version}") || return 1
  [[ "${merge_sha}" == "${main_sha}" ]] || publication_error \
    "Merged SHA ${merge_sha} is no longer the current main SHA ${main_sha}." || return 1

  if git rev-parse --verify --quiet "refs/tags/${release_tag}" >/dev/null; then
    tag_type=$(git cat-file -t "refs/tags/${release_tag}")
    [[ "${tag_type}" == tag ]] || publication_error \
      "Existing tag ${release_tag} is not annotated; refusing to replace it." || return 1
    tag_sha=$(git rev-list -n 1 "refs/tags/${release_tag}")
    [[ "${tag_sha}" == "${merge_sha}" ]] || publication_error \
      "Existing tag ${release_tag} points to ${tag_sha}, not ${merge_sha}." || return 1
    printf 'Release tag %s already points to %s; retry is a no-op.\n' \
      "${release_tag}" "${merge_sha}" >&2
  else
    git tag --annotate "${release_tag}" "${merge_sha}" \
      --message "Release ${release_tag}"
    git push origin "refs/tags/${release_tag}"
    printf 'Created annotated release tag %s at %s.\n' \
      "${release_tag}" "${merge_sha}" >&2
  fi

  printf '%s\n' "${release_tag}"
}

main() {
  : "${RELEASE_VERSION:?RELEASE_VERSION is required}"
  : "${MERGE_SHA:?MERGE_SHA is required}"
  : "${MAIN_SHA:?MAIN_SHA is required}"

  create_release_tag "${RELEASE_VERSION}" "${MERGE_SHA}" "${MAIN_SHA}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
