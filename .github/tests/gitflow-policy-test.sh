#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../scripts/gitflow-policy.sh"

REPOSITORY=owner/repository
HEAD_SHA=approved

MOCK_INCOMPLETE=0
MOCK_BRANCH_HEAD=target-tip
MOCK_APPROVED_SHA=approved
MOCK_CURRENT_RELEASE_SHA=release-tip
MOCK_PENDING_HOTFIXES=0
MOCK_ACTIVE_RELEASES=""
MOCK_ANCESTORS="approved:backmerge-tip approved:head release-tip:head"

production_incomplete_count() { printf '%s\n' "${MOCK_INCOMPLETE}"; }
branch_head() {
  if [[ "$1" == release/* ]]; then
    printf '%s\n' "${MOCK_CURRENT_RELEASE_SHA}"
  else
    printf '%s\n' "${MOCK_BRANCH_HEAD}"
  fi
}
merged_main_head() { printf '%s\n' "${MOCK_APPROVED_SHA}"; }
pending_hotfix_count() { printf '%s\n' "${MOCK_PENDING_HOTFIXES}"; }
incomplete_hotfix_count() { printf '%s\n' "${MOCK_PENDING_HOTFIXES}"; }
active_release_names() {
  [[ -n "${MOCK_ACTIVE_RELEASES}" ]] && printf '%s\n' ${MOCK_ACTIVE_RELEASES}
  return 0
}
is_ancestor() {
  [[ " ${MOCK_ANCESTORS} " == *" $1:$2 "* ]]
}

reset_mocks() {
  HEAD_SHA=approved
  MOCK_INCOMPLETE=0
  MOCK_BRANCH_HEAD=target-tip
  MOCK_APPROVED_SHA=approved
  MOCK_CURRENT_RELEASE_SHA=release-tip
  MOCK_PENDING_HOTFIXES=0
  MOCK_ACTIVE_RELEASES=""
  MOCK_ANCESTORS="approved:backmerge-tip approved:head release-tip:head"
}

expect_status() {
  local expected="$1"
  local label="$2"
  local actual=0

  if validate_policy >/dev/null 2>&1; then
    actual=0
  else
    actual=$?
  fi

  if [[ "${actual}" != "${expected}" ]]; then
    printf 'FAIL: %s (expected %s, got %s)\n' \
      "${label}" "${expected}" "${actual}" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "${label}"
}

reset_mocks
BASE_REF=develop HEAD_REF=feature/example
expect_status 0 "feature targets develop"

reset_mocks
BASE_REF=main HEAD_REF=feature/example
expect_status 1 "feature cannot target main"

reset_mocks
BASE_REF=release/1.0.0 HEAD_REF=bugfix/release-fix
MOCK_ACTIVE_RELEASES=release/1.0.0
expect_status 0 "bugfix stabilizes release"

reset_mocks
BASE_REF=release/1.0.0 HEAD_REF=bugfix/release-fix
expect_status 1 "bugfix cannot target inactive release"

reset_mocks
BASE_REF=main HEAD_REF=release/1.0.0
expect_status 0 "release targets main before its backmerge exists"

reset_mocks
BASE_REF=main HEAD_REF=release/1.0.0 MOCK_INCOMPLETE=1
expect_status 1 "incomplete production integration blocks release"

reset_mocks
BASE_REF=develop HEAD_REF=backmerge/release/1.0.0 HEAD_SHA=head
expect_status 0 "approved release backmerge targets develop"

reset_mocks
BASE_REF=develop HEAD_REF=backmerge/release/1.0.0 HEAD_SHA=approved
expect_status 1 "release backmerge must use a distinct head"

reset_mocks
BASE_REF=develop HEAD_REF=backmerge/release/1.0.0 HEAD_SHA=head
MOCK_PENDING_HOTFIXES=1
expect_status 1 "pending hotfix blocks release backmerge"

reset_mocks
BASE_REF=main HEAD_REF=hotfix/1.0.1
expect_status 0 "hotfix targets main before its develop backmerge exists"

reset_mocks
BASE_REF=main HEAD_REF=hotfix/1.0.1 MOCK_ACTIVE_RELEASES=release/2.0.0
expect_status 0 "hotfix targets main before its release backmerge exists"

reset_mocks
BASE_REF=main HEAD_REF=hotfix/1.0.1 MOCK_INCOMPLETE=1
expect_status 1 "incomplete production integration blocks hotfix"

reset_mocks
BASE_REF=main HEAD_REF=hotfix/1.0.1
MOCK_ACTIVE_RELEASES="release/2.0.0 release/3.0.0"
expect_status 1 "multiple active releases block hotfix"

reset_mocks
BASE_REF=release/2.0.0 HEAD_REF=backmerge/hotfix/1.0.1 HEAD_SHA=head
MOCK_ACTIVE_RELEASES=release/2.0.0
expect_status 0 "approved hotfix backmerge targets active release"

reset_mocks
BASE_REF=release/2.0.0 HEAD_REF=backmerge/hotfix/1.0.1 HEAD_SHA=approved
MOCK_ACTIVE_RELEASES=release/2.0.0
expect_status 1 "hotfix backmerge must use a distinct head"

reset_mocks
BASE_REF=release/1.0.0 HEAD_REF=backmerge/hotfix/1.0.1 HEAD_SHA=head
MOCK_ACTIVE_RELEASES=release/2.0.0
expect_status 1 "hotfix cannot target stale release"

printf 'All Gitflow policy tests passed.\n'
