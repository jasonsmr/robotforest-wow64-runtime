#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/token.sh"
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN first (repo actions+contents write)}"
TAG="${1:?Usage: dispatch_tag_build <vX.Y.Z>}"

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
WORKFLOW_ID="release.yml"

echo "[dispatch] Triggering workflow_dispatch for ref=$TAG"
code=$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: rf-ci-helper" \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_ID}/dispatches" \
  -d "{\"ref\":\"${TAG}\"}")

if [ "$code" != "204" ]; then
  echo "[dispatch] HTTP $code"
  echo "  Token needs Actions:RW + Contents:RW on ${OWNER}/${REPO}."
  exit 1
fi
echo "[dispatch] Sent. Use tools/check_ci.sh to watch runs."
