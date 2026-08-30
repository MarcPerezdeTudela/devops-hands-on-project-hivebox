#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/gitflow-policy.sh"

valid_temporary_ref() {
  local branch="$1"

  [[ "${branch}" != *..* ]] \
    && [[ "${branch}" != *//* ]] \
    && [[ "${branch}" != */ ]] \
    && [[ "${branch}" =~ ^(feature|bugfix|release|hotfix|backmerge/release|backmerge/hotfix)/[A-Za-z0-9][A-Za-z0-9._/-]*$ ]]
}

current_ref_sha() {
  branch_head "$1" 2>/dev/null
}

delete_ref_if_matches() {
  local branch="$1"
  local expected_sha="$2"
  local actual_sha

  valid_temporary_ref "${branch}" || policy_error \
    "Refusing to delete unexpected ref name ${branch}." || return 1

  actual_sha=$(current_ref_sha "${branch}") || {
    printf 'Ref %s is already absent; nothing to delete.\n' "${branch}"
    return 0
  }

  [[ "${actual_sha}" == "${expected_sha}" ]] || policy_error \
    "Ref ${branch} moved from ${expected_sha} to ${actual_sha}; refusing deletion." \
    || return 1

  gh api --method DELETE \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2026-03-10" \
    "repos/${REPOSITORY}/git/refs/heads/${branch}"
  printf 'Deleted completed temporary ref %s at %s.\n' \
    "${branch}" "${expected_sha}"
}

cleanup_release_backmerge() {
  local suffix="${HEAD_REF#backmerge/release/}"
  local source_branch="release/${suffix}"
  local source_sha pending

  [[ "${BASE_REF}" == "develop" ]] || policy_error \
    "Release backmerge cleanup requires develop as its target." || return 1

  source_sha=$(current_ref_sha "${source_branch}") || policy_error \
    "Source ref ${source_branch} is missing before cleanup." || return 1
  is_ancestor "${source_sha}" "${HEAD_SHA}" || policy_error \
    "Merged backmerge ${HEAD_REF} omitted current ${source_branch} tip ${source_sha}." \
    || return 1

  pending=$(pending_hotfix_count "${source_branch}") || return 1
  (( pending == 0 )) || policy_error \
    "${source_branch} still has ${pending} open hotfix backmerge(s)." || return 1
  pending=$(incomplete_hotfix_count) || return 1
  (( pending == 0 )) || policy_error \
    "${pending} production hotfix(es) still require a backmerge." || return 1

  delete_ref_if_matches "${HEAD_REF}" "${HEAD_SHA}" || return 1
  delete_ref_if_matches "${source_branch}" "${source_sha}"
}

cleanup_hotfix_backmerge() {
  local suffix="${HEAD_REF#backmerge/hotfix/}"
  local source_branch="hotfix/${suffix}"
  local source_sha active_output release
  local -a active_releases=()

  [[ "${BASE_REF}" == "develop" || "${BASE_REF}" == release/* ]] \
    || policy_error "Hotfix backmerge cleanup has an invalid target." || return 1

  source_sha=$(current_ref_sha "${source_branch}") || policy_error \
    "Source ref ${source_branch} is missing before cleanup." || return 1
  is_ancestor "${source_sha}" "${HEAD_SHA}" || policy_error \
    "Merged backmerge ${HEAD_REF} omitted approved ${source_branch} tip ${source_sha}." \
    || return 1

  if [[ "${BASE_REF}" == release/* ]]; then
    active_output=$(active_release_names) || policy_error \
      "Unable to determine the active release before cleanup." || return 1
    while IFS= read -r release; do
      [[ -n "${release}" ]] && active_releases+=("${release}")
    done <<< "${active_output}"
    (( ${#active_releases[@]} == 1 )) || policy_error \
      "Hotfix cleanup requires exactly one active release." || return 1
    [[ "${active_releases[0]}" == "${BASE_REF}" ]] || policy_error \
      "Merged hotfix target ${BASE_REF} is no longer the active release." || return 1
  fi

  delete_ref_if_matches "${HEAD_REF}" "${HEAD_SHA}" || return 1
  delete_ref_if_matches "${source_branch}" "${source_sha}"
}

cleanup_main() {
  local develop_sha

  [[ "${PR_MERGED}" == "true" ]] || {
    printf 'Pull request was closed without merging; cleanup skipped.\n'
    return 0
  }
  [[ "${HEAD_REPOSITORY}" == "${REPOSITORY}" ]] || {
    printf 'Fork-owned head ref; cleanup skipped.\n'
    return 0
  }

  case "${BASE_REF}:${HEAD_REF}" in
    develop:feature/* | develop:bugfix/* | release/*:bugfix/*)
      delete_ref_if_matches "${HEAD_REF}" "${HEAD_SHA}"
      ;;
    develop:backmerge/release/*)
      cleanup_release_backmerge
      ;;
    develop:backmerge/hotfix/* | release/*:backmerge/hotfix/*)
      cleanup_hotfix_backmerge
      ;;
    main:release/*)
      develop_sha=$(branch_head develop) || return 1
      if is_ancestor "${HEAD_SHA}" "${develop_sha}"; then
        delete_ref_if_matches "${HEAD_REF}" "${HEAD_SHA}"
      else
        printf '%s still requires its develop backmerge; retaining the ref.\n' \
          "${HEAD_REF}"
      fi
      ;;
    main:hotfix/*)
      printf '%s still requires its second integration; retaining the ref.\n' \
        "${HEAD_REF}"
      ;;
    *)
      printf 'No cleanup rule for %s -> %s.\n' "${HEAD_REF}" "${BASE_REF}"
      ;;
  esac
}

main() {
  : "${BASE_REF:?BASE_REF is required}"
  : "${HEAD_REF:?HEAD_REF is required}"
  : "${HEAD_REPOSITORY:?HEAD_REPOSITORY is required}"
  : "${HEAD_SHA:?HEAD_SHA is required}"
  : "${PR_MERGED:?PR_MERGED is required}"
  : "${REPOSITORY:?REPOSITORY is required}"

  cleanup_main
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
