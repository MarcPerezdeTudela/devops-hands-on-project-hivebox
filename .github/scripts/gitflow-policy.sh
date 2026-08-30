#!/usr/bin/env bash

set -uo pipefail

policy_error() {
  printf '::error::%s\n' "$*" >&2
  return 1
}

repo_owner() {
  printf '%s\n' "${REPOSITORY%%/*}"
}

api_open_pulls() {
  gh api --paginate --method GET \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2026-03-10" \
    "repos/${REPOSITORY}/pulls" \
    --field state=open \
    --field per_page=100 \
    --slurp
}

api_closed_pulls() {
  gh api --paginate --method GET \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2026-03-10" \
    "repos/${REPOSITORY}/pulls" \
    --field state=closed \
    --field per_page=100 \
    --slurp
}

flatten_pages() {
  jq -c 'if (.[0] | type) == "array" then add else . end'
}

branch_head() {
  local branch="$1"
  gh api \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2026-03-10" \
    "repos/${REPOSITORY}/git/ref/heads/${branch}" \
    --jq '.object.sha'
}

is_ancestor() {
  local ancestor="$1"
  local descendant="$2"
  local status

  status=$(gh api \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2026-03-10" \
    "repos/${REPOSITORY}/compare/${ancestor}...${descendant}" \
    --jq '.status') || return 1

  [[ "${status}" == "ahead" || "${status}" == "identical" ]]
}

open_pr_head() {
  local base="$1"
  local head_branch="$2"
  local owner
  owner=$(repo_owner)

  api_open_pulls \
    | flatten_pages \
    | jq -r \
      --arg base "${base}" \
      --arg head "${head_branch}" \
      --arg repo "${REPOSITORY}" \
      '.[]
       | select(.base.ref == $base)
       | select(.head.ref == $head)
       | select(.head.repo.full_name == $repo)
       | .head.sha' \
    | head -n 1
}

merged_main_head() {
  local source_branch="$1"

  api_closed_pulls \
    | flatten_pages \
    | jq -r \
      --arg head "${source_branch}" \
      --arg repo "${REPOSITORY}" \
      '[.[]
        | select(.base.ref == "main")
        | select(.head.ref == $head)
        | select(.head.repo.full_name == $repo)
        | select(.merged_at != null)]
       | sort_by(.merged_at)
       | last
       | .head.sha // empty'
}

merged_backmerge_exists() {
  local source_branch="$1"
  local approved_sha="$2"
  local kind="${source_branch%%/*}"
  local suffix="${source_branch#*/}"
  local backmerge_branch="backmerge/${kind}/${suffix}"
  local candidate_sha candidate_shas

  candidate_shas=$(api_closed_pulls \
    | flatten_pages \
    | jq -r \
      --arg head "${backmerge_branch}" \
      --arg repo "${REPOSITORY}" \
      '[.[]
        | select(.head.ref == $head)
        | select(.head.repo.full_name == $repo)
        | select(.merged_at != null)
        | select(.base.ref == "develop" or (.base.ref | startswith("release/")))]
       | .[].head.sha') || return 1

  while IFS= read -r candidate_sha; do
    [[ -n "${candidate_sha}" ]] || continue
    if is_ancestor "${approved_sha}" "${candidate_sha}"; then
      return 0
    fi
  done <<< "${candidate_shas}"

  # Grandfather the v0.1.0 release, which used the same source branch and SHA
  # for its develop backmerge before canonical backmerge branches existed.
  if [[ "${kind}" == "release" ]]; then
    local completed
    completed=$(api_closed_pulls \
      | flatten_pages \
      | jq -r \
        --arg head "${source_branch}" \
        --arg sha "${approved_sha}" \
        --arg repo "${REPOSITORY}" \
        '[.[]
          | select(.base.ref == "develop")
          | select(.head.ref == $head)
          | select(.head.sha == $sha)
          | select(.head.repo.full_name == $repo)
          | select(.merged_at != null)]
         | length') || return 1
    (( completed > 0 ))
    return
  fi

  return 1
}

incomplete_hotfix_count() {
  local count=0
  local source_branch approved_sha rows

  rows=$(api_closed_pulls \
    | flatten_pages \
    | jq -r \
      --arg repo "${REPOSITORY}" \
      '.[]
       | select(.base.ref == "main")
       | select(.head.repo.full_name == $repo)
       | select(.merged_at != null)
       | select(.head.ref | startswith("hotfix/"))
       | [.head.ref, .head.sha]
       | @tsv') || return 1

  while IFS=$'\t' read -r source_branch approved_sha; do
    [[ -n "${source_branch}" ]] || continue
    if ! merged_backmerge_exists "${source_branch}" "${approved_sha}"; then
      count=$((count + 1))
    fi
  done <<< "${rows}"

  printf '%s\n' "${count}"
}

production_incomplete_count() {
  local count=0
  local source_branch approved_sha rows

  rows=$(api_closed_pulls \
    | flatten_pages \
    | jq -r \
      --arg repo "${REPOSITORY}" \
      '.[]
       | select(.base.ref == "main")
       | select(.head.repo.full_name == $repo)
       | select(.merged_at != null)
       | select(.head.ref | startswith("release/") or startswith("hotfix/"))
       | [.head.ref, .head.sha]
       | @tsv') || return 1

  while IFS=$'\t' read -r source_branch approved_sha; do
    [[ -n "${source_branch}" ]] || continue
    if ! merged_backmerge_exists "${source_branch}" "${approved_sha}"; then
      count=$((count + 1))
    fi
  done <<< "${rows}"

  printf '%s\n' "${count}"
}

active_release_names() {
  api_open_pulls \
    | flatten_pages \
    | jq -r \
      --arg repo "${REPOSITORY}" \
      '[.[]
        | select(.head.repo.full_name == $repo)
        | if (.base.ref == "main" and (.head.ref | startswith("release/")))
          then .head.ref
          elif (.base.ref == "develop" and
                (.head.ref | startswith("backmerge/release/")))
          then (.head.ref | sub("^backmerge/"; ""))
          else empty
          end]
       | unique[]'
}

pending_hotfix_count() {
  local release_branch="$1"

  api_open_pulls \
    | flatten_pages \
    | jq -r \
      --arg base "${release_branch}" \
      --arg repo "${REPOSITORY}" \
      '[.[]
        | select(.base.ref == $base)
        | select(.head.repo.full_name == $repo)
        | select(.head.ref | startswith("backmerge/hotfix/"))]
       | length'
}

require_companion() {
  local approved_sha="$1"
  local companion_branch="$2"
  local companion_target="$3"
  local companion_sha

  companion_sha=$(open_pr_head "${companion_target}" "${companion_branch}")
  [[ -n "${companion_sha}" ]] || policy_error \
    "Open ${companion_branch} -> ${companion_target} before merging into main." \
    || return 1

  is_ancestor "${approved_sha}" "${companion_sha}" || policy_error \
    "${companion_branch} does not contain approved head ${approved_sha}." \
    || return 1
}

require_no_incomplete_production() {
  local incomplete
  incomplete=$(production_incomplete_count) || return 1
  (( incomplete == 0 )) || policy_error \
    "${incomplete} earlier release/hotfix integration has not completed its backmerge."
}

validate_policy() {
  local suffix source_branch approved_sha current_release_sha pending active_output
  local -a active_releases=()

  case "${BASE_REF}:${HEAD_REF}" in
    develop:feature/* | develop:bugfix/*)
      return 0
      ;;

    release/*:bugfix/*)
      active_output=$(active_release_names) || policy_error \
        "Unable to determine the active release lifecycle." || return 1
      while IFS= read -r release; do
        [[ -n "${release}" ]] && active_releases+=("${release}")
      done <<< "${active_output}"
      (( ${#active_releases[@]} == 1 )) || policy_error \
        "A bugfix may target a release only when exactly one release is active." \
        || return 1
      [[ "${active_releases[0]}" == "${BASE_REF}" ]] || policy_error \
        "Bugfix target ${BASE_REF} is not the active release." \
        || return 1
      ;;

    main:release/*)
      require_no_incomplete_production || return 1
      suffix="${HEAD_REF#release/}"
      if is_ancestor "${HEAD_SHA}" "$(branch_head develop)"; then
        return 0
      fi
      require_companion \
        "${HEAD_SHA}" "backmerge/release/${suffix}" develop
      ;;

    main:hotfix/*)
      require_no_incomplete_production || return 1
      active_output=$(active_release_names) || policy_error \
        "Unable to determine the active release lifecycle." || return 1
      while IFS= read -r release; do
        [[ -n "${release}" ]] && active_releases+=("${release}")
      done <<< "${active_output}"
      if (( ${#active_releases[@]} > 1 )); then
        policy_error "Multiple active releases make hotfix routing ambiguous."
        return 1
      fi
      suffix="${HEAD_REF#hotfix/}"
      if (( ${#active_releases[@]} == 1 )); then
        require_companion \
          "${HEAD_SHA}" "backmerge/hotfix/${suffix}" "${active_releases[0]}"
      else
        require_companion \
          "${HEAD_SHA}" "backmerge/hotfix/${suffix}" develop
      fi
      ;;

    develop:backmerge/release/*)
      suffix="${HEAD_REF#backmerge/release/}"
      source_branch="release/${suffix}"
      approved_sha=$(merged_main_head "${source_branch}")
      [[ -n "${approved_sha}" ]] || policy_error \
        "${source_branch} must merge into main before its develop backmerge." \
        || return 1
      is_ancestor "${approved_sha}" "${HEAD_SHA}" || policy_error \
        "${HEAD_REF} does not contain main-approved head ${approved_sha}." \
        || return 1
      current_release_sha=$(branch_head "${source_branch}") || policy_error \
        "Active source ${source_branch} is missing." \
        || return 1
      is_ancestor "${current_release_sha}" "${HEAD_SHA}" || policy_error \
        "${HEAD_REF} does not contain current ${source_branch} tip ${current_release_sha}." \
        || return 1
      pending=$(pending_hotfix_count "${source_branch}") || return 1
      (( pending == 0 )) || policy_error \
        "${source_branch} still has ${pending} pending hotfix backmerge(s)." \
        || return 1
      pending=$(incomplete_hotfix_count) || return 1
      (( pending == 0 )) || policy_error \
        "${pending} production hotfix(es) have not completed their backmerge." \
        || return 1
      ;;

    develop:backmerge/hotfix/* | release/*:backmerge/hotfix/*)
      suffix="${HEAD_REF#backmerge/hotfix/}"
      source_branch="hotfix/${suffix}"
      approved_sha=$(merged_main_head "${source_branch}")
      [[ -n "${approved_sha}" ]] || policy_error \
        "${source_branch} must merge into main before its backmerge." \
        || return 1
      is_ancestor "${approved_sha}" "${HEAD_SHA}" || policy_error \
        "${HEAD_REF} does not contain main-approved head ${approved_sha}." \
        || return 1

      if [[ "${BASE_REF}" == release/* ]]; then
        active_output=$(active_release_names) || policy_error \
          "Unable to determine the active release lifecycle." || return 1
        while IFS= read -r release; do
          [[ -n "${release}" ]] && active_releases+=("${release}")
        done <<< "${active_output}"
        (( ${#active_releases[@]} == 1 )) || policy_error \
          "A hotfix may target a release only when exactly one release is active." \
          || return 1
        [[ "${active_releases[0]}" == "${BASE_REF}" ]] || policy_error \
          "Hotfix target ${BASE_REF} is not the active release." \
          || return 1
      fi
      ;;

    *)
      policy_error "Gitflow does not allow ${HEAD_REF} to target ${BASE_REF}."
      ;;
  esac
}

main() {
  : "${BASE_REF:?BASE_REF is required}"
  : "${HEAD_REF:?HEAD_REF is required}"
  : "${HEAD_SHA:?HEAD_SHA is required}"
  : "${REPOSITORY:?REPOSITORY is required}"

  if validate_policy; then
    printf 'Gitflow allows %s to target %s.\n' "${HEAD_REF}" "${BASE_REF}"
  else
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
