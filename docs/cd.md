# Continuous delivery

Continuous delivery runs when a `v*` tag is pushed. It verifies that the tag
matches the project version and points to the current `main` commit before
publishing the container image to GitHub Container Registry.

The workflow publishes a versioned image and reports its digest. This keeps
release publication tied to the Gitflow production integration.
