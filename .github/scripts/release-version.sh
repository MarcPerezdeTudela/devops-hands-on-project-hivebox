#!/usr/bin/env bash

set -euo pipefail

latest_tag=$(git tag --list 'v[0-9]*' --sort=-v:refname | head -n 1)
if [[ -z "${latest_tag}" ]]; then
  printf 'No semantic-version release tag exists.\n' >&2
  exit 1
fi
current_version=${latest_tag#v}

if ! [[ "${current_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Latest release tag %q is not a semantic version.\n' "${latest_tag}" >&2
  exit 1
fi

reference=${latest_tag}
if ! git merge-base --is-ancestor "${latest_tag}" HEAD; then
  main_tag=$(git rev-parse main 2>/dev/null || true)
  tag_commit=$(git rev-list -n 1 "${latest_tag}")
  release_tag_pattern=${latest_tag//./\\.}
  backmerge_subject_pattern="^chore\\(release\\): backmerge( hotfix)? ${release_tag_pattern}( \\(#[0-9]+\\))?$"
  reference=$(git log --format=%H --extended-regexp --grep="${backmerge_subject_pattern}" HEAD \
    | head -n 1)

  if [[ "${main_tag}" != "${tag_commit}" || -z "${reference}" ]]; then
    printf 'Latest release tag %q is not an ancestor of HEAD and has no usable backmerge.\n' \
      "${latest_tag}" >&2
    exit 1
  fi

  printf 'Using the documented %s backmerge as the temporary release baseline.\n' \
    "${latest_tag}" >&2
fi

if [[ "$(git rev-list --count "${reference}..HEAD")" == 0 ]]; then
  printf 'No commits exist after %q; no release version can be calculated.\n' \
    "${latest_tag}" >&2
  exit 1
fi

increment=none
breaking_subject_pattern='^[a-z]+(\([a-z0-9._/-]+\))?!:'
breaking_footer_pattern=$'(^|\n)BREAKING[[:space:]-]CHANGE:'
feature_pattern='^feat(\([a-z0-9._/-]+\))?:'
patch_pattern='^(fix|perf)(\([a-z0-9._/-]+\))?:'
while IFS= read -r -d '' message; do
  message=${message#$'\n'}
  subject=${message%%$'\n'*}

  if [[ "${subject}" =~ ${breaking_subject_pattern} ]] || \
      [[ "${message}" =~ ${breaking_footer_pattern} ]]; then
    increment=major
    break
  fi

  if [[ "${subject}" =~ ${feature_pattern} ]] && \
      [[ "${increment}" != major ]]; then
    increment=minor
  elif [[ "${subject}" =~ ${patch_pattern} ]] && \
      [[ "${increment}" == none ]]; then
    increment=patch
  fi
done < <(git log --format='%B%x00' "${reference}..HEAD")

case "${increment}" in
  major)
    IFS=. read -r major minor patch <<< "${current_version}"
    printf '%s.0.0\n' "$((major + 1))"
    ;;
  minor)
    IFS=. read -r major minor patch <<< "${current_version}"
    printf '%s.%s.0\n' "${major}" "$((minor + 1))"
    ;;
  patch)
    IFS=. read -r major minor patch <<< "${current_version}"
    printf '%s.%s.%s\n' "${major}" "${minor}" "$((patch + 1))"
    ;;
  none)
    printf 'No feat:, fix:, perf:, or breaking Conventional Commit exists after %q.\n' \
      "${latest_tag}" >&2
    exit 1
    ;;
esac
