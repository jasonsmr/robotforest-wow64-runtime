#!/usr/bin/env bash
set -euo pipefail
TAG="${1:?Usage: cut_release <vX.Y.Z>}"

# Ensure workflow exists on remote
git fetch origin --prune

# Create and push the tag (idempotent)
git tag -a "$TAG" -m "robotforest-wow64-runtime $TAG" 2>/dev/null || true
git push origin "$TAG"

# Wait for the GitHub Action to build & publish the ZIP
"$(dirname "$0")/await_release.sh" "$TAG" "${WAIT_SECS:-1800}"
