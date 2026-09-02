# Continuous delivery

Continuous delivery publishes a `v*` tag after verifying that it matches the
project version and points to the current `main` commit. Manual pushes of a
`v*` tag continue to start the image-publication workflow.

When a `release/*` or `hotfix/*` pull request is merged into `main`, the
repository-owned release-publication workflow runs after the required `main`
checks have allowed the merge. It verifies the exact merge SHA is still the
`main` tip, creates the annotated `vVERSION` tag, reuses the image-publication
workflow, and then publishes a GitHub Release with generated notes.

The workflows use only the scoped `GITHUB_TOKEN`; no personal access token is
needed. They never approve or merge pull requests, create commits, force-push,
rewrite or delete refs, or recreate branches. A matching existing tag or
GitHub Release makes its corresponding retry a no-op. For image publication,
the workflow first inspects the versioned GHCR tag: an existing tag is reused
with its recorded digest, while only an absent tag is built and pushed. A tag
at a different SHA, an invalid version, or a merge SHA that is no longer
`main` stops the workflow without changing refs.

For manual recovery, verify the intended `main` SHA and project version first.
If the annotated tag is absent, create it at that exact SHA and push it; this
starts image publication. If the image is already published but the GitHub
Release is missing, create the release for the existing tag with generated
notes. Do not move, replace, or delete a release tag.
