#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN first (repo actions+contents write)}"
TAG="${1:?Usage: dispatch_tag_build <vX.Y.Z>}"

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
WORKFLOW_ID="release.yml"   # filename under .github/workflows

echo "[dispatch] Triggering workflow_dispatch for ref=$TAG"
curl -fsSL -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_ID}/dispatches" \
  -d "{\"ref\":\"refs/tags/${TAG}\"}"

echo "[dispatch] Sent. Use tools/check_ci.sh to watch runs."
