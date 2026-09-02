# Contributing to HiveBox

Thanks for contributing to HiveBox. Keep each issue and pull request focused on
one piece of work, and never include credentials, tokens, private keys, or
other sensitive data.

## Creating an issue

Use **Bug report** for reproducible unexpected behavior. Use **Feature or
implementation task** for a focused improvement. Complete the goal or
description, acceptance criteria, and validation approach so the work is
actionable; include relevant context and security or operational considerations
when they apply.

Blank issues remain available for exceptional governance, release, or research
work that does not fit either form. Do not report suspected vulnerabilities in
a public issue. Use [private vulnerability reporting](SECURITY.md) instead.

## Opening a pull request

Follow the [Gitflow workflow](docs/gitflow.md). Features
and ordinary bug fixes start from `develop` and target `develop`; do not push
directly to permanent branches.

Use a Conventional Commits title, complete the pull-request template, reference
the related issue, and report the validation you ran. Update documentation when
the change affects setup, configuration, behavior, deployment, or workflow.
Consider security and operational impact before submitting the pull request.
