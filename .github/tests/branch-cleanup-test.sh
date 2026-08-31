#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../scripts/branch-cleanup.sh"

REPOSITORY=owner/repository
HEAD_REPOSITORY=owner/repository
PR_MERGED=true
HEAD_SHA=head

current_ref_sha() { return 1; }
delete_ref_if_matches feature/already-removed head >/dev/null
printf 'PASS: already absent ref cleanup is idempotent\n'

MOCK_ANCESTORS="source:head head:develop head:head"
MOCK_ACTIVE_RELEASES=release/2.0.0
MOCK_PENDING=0
MOCK_DELIVERED_TOPIC_REFS=""
MOCK_MAIN_SHA=head
DELETED_REFS=""

branch_head() {
  case "$1" in
    main) printf '%s\n' "${MOCK_MAIN_SHA}" ;;
    develop) printf 'develop\n' ;;
    release/* | hotfix/*) printf 'source\n' ;;
    *) printf 'head\n' ;;
  esac
}
current_ref_sha() { branch_head "$1"; }
is_ancestor() { [[ " ${MOCK_ANCESTORS} " == *" $1:$2 "* ]]; }
pending_hotfix_count() { printf '%s\n' "${MOCK_PENDING}"; }
incomplete_hotfix_count() { printf '%s\n' "${MOCK_PENDING}"; }
active_release_names() { printf '%s\n' "${MOCK_ACTIVE_RELEASES}"; }
delivered_topic_refs() { printf '%s\n' "${MOCK_DELIVERED_TOPIC_REFS}"; }
delete_ref_if_matches() {
  valid_temporary_ref "$1" || return 1
  DELETED_REFS="${DELETED_REFS} $1@$2"
}

reset_mocks() {
  HEAD_REPOSITORY=owner/repository
  PR_MERGED=true
  HEAD_SHA=head
  MOCK_ANCESTORS="source:head head:develop head:head"
  MOCK_ACTIVE_RELEASES=release/2.0.0
  MOCK_PENDING=0
  MOCK_DELIVERED_TOPIC_REFS=""
  MOCK_MAIN_SHA=head
  DELETED_REFS=""
}

expect_cleanup() {
  local expected_status="$1"
  local expected_refs="$2"
  local label="$3"
  local actual=0

  if cleanup_main >/dev/null 2>&1; then
    actual=0
  else
    actual=$?
  fi

  if [[ "${actual}" != "${expected_status}" ||
        "${DELETED_REFS}" != "${expected_refs}" ]]; then
    printf 'FAIL: %s (status %s, refs %q)\n' \
      "${label}" "${actual}" "${DELETED_REFS}" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "${label}"
}

reset_mocks
BASE_REF=develop HEAD_REF=feature/example
expect_cleanup 0 "" "merged feature is retained"

reset_mocks
BASE_REF=develop HEAD_REF=feature/example PR_MERGED=false
expect_cleanup 0 "" "closed feature is retained"

reset_mocks
BASE_REF=develop HEAD_REF=feature/example HEAD_REPOSITORY=fork/repository
expect_cleanup 0 "" "fork branch is skipped"

reset_mocks
BASE_REF=main HEAD_REF=release/1.0.0
expect_cleanup 0 " release/1.0.0@head" "release with no return diff is deleted"

reset_mocks
BASE_REF=main HEAD_REF=release/1.0.0 MOCK_ANCESTORS="source:head"
expect_cleanup 0 "" "release awaiting backmerge is retained"

reset_mocks
BASE_REF=develop HEAD_REF=backmerge/release/2.0.0
MOCK_DELIVERED_TOPIC_REFS=$'feature/example\thead\nbugfix/release-fix\thead'
expect_cleanup 0 \
  " backmerge/release/2.0.0@head release/2.0.0@source feature/example@head bugfix/release-fix@head" \
  "completed release and delivered topic refs are deleted"

reset_mocks
MOCK_DELIVERED_TOPIC_REFS=$'feature/example\thead'
MOCK_MAIN_SHA=main
MOCK_ANCESTORS="source:head"
cleanup_delivered_topics >/dev/null
[[ -z "${DELETED_REFS}" ]] || {
  printf 'FAIL: topic branch not delivered to main was deleted\n' >&2
  exit 1
}
printf 'PASS: topic branch not delivered to main is retained\n'

reset_mocks
BASE_REF=develop HEAD_REF=backmerge/release/2.0.0 MOCK_PENDING=1
expect_cleanup 1 "" "pending hotfix blocks release cleanup"

reset_mocks
BASE_REF=release/2.0.0 HEAD_REF=backmerge/hotfix/1.0.1
expect_cleanup 0 \
  " backmerge/hotfix/1.0.1@head hotfix/1.0.1@source" \
  "completed active-release hotfix refs are deleted"

reset_mocks
BASE_REF=release/1.0.0 HEAD_REF=backmerge/hotfix/1.0.1
expect_cleanup 1 "" "stale release blocks hotfix cleanup"

valid_temporary_ref feature/example
! valid_temporary_ref main
! valid_temporary_ref 'feature/../main'
! valid_temporary_ref 'feature//example'

printf 'All branch cleanup tests passed.\n'
