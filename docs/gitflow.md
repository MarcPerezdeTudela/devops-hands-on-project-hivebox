# Gitflow

HiveBox follows canonical Gitflow. `develop` collects work for the next release
and `main` records production releases; protected branches accept merge-commit
pull requests only.

Features and ordinary bug fixes start from `develop`. Releases are stabilized
on `release/VERSION`, integrated into `main`, and backmerged into `develop`.
Hotfixes start from `main` and are backmerged to the active release or develop.

## Protected production merges

The `main-protection` ruleset requires all configured status checks to be
current before a pull request can merge. When `main` advances, GitHub requires
the pull request branch to update and the required checks to pass again on the
updated head; checks from an earlier base state cannot satisfy the rule.

## Temporary branch cleanup

GitHub's repository-wide automatic pull-request branch deletion is disabled.
HiveBox instead runs a repository-owned cleanup workflow after merged pull
requests. It never approves or merges pull requests, creates commits or tags,
rewrites refs, or recreates deleted branches.

- A `feature/*` or `bugfix/*` branch remains after its pull request to
  `develop` (or an active `release/*`) merges. The cleanup workflow deletes it
  only after the exact head SHA of its latest merged pull request is an
  ancestor of `main`; delivery through a release is therefore identified by
  ancestry, not by a branch name or a tag.
- A `release/*` branch remains at its merged head until the required
  `backmerge/release/*` pull request has merged into `develop`, including any
  required hotfix backmerges. A `hotfix/*` branch remains until its required
  backmerge reaches its active release or `develop`.
- A moved, unknown, fork-owned, or still-required branch is retained. The
  workflow logs the reason and fails closed when it cannot prove the required
  relationship. Retrying a completed cleanup is safe: an already-absent ref is
  reported as a no-op.

For manual cleanup, first verify the source SHA is reachable from `main` and
that all required backmerge pull requests are merged. Then delete only the
named temporary branch in GitHub or with `git push origin --delete BRANCH`.
Do not delete `main`, `develop`, an active release, or a ref whose SHA changed
after its approved pull request; resolve the lifecycle state first.
