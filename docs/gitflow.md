# Gitflow

HiveBox follows canonical Gitflow. `develop` collects work for the next release
and `main` records production releases; protected branches accept merge-commit
pull requests only.

Features and ordinary bug fixes start from `develop`. Releases are stabilized
on `release/VERSION`, integrated into `main`, and backmerged into `develop`.
Hotfixes start from `main` and are backmerged to the active release or develop.
