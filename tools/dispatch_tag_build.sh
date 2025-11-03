#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN first (repo actions+contents write)}"
TAG="${1:?Usage: dispatch_tag_build <vX.Y.Z>}"

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
WORKFLOW_ID="release.yml"   # confirm with tools/list_workflows.sh if needed

echo "[dispatch] Triggering workflow_dispatch for ref=$TAG"
resp=$(curl -sS -o /dev/stderr -w "%{http_code}" -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: rf-ci-helper" \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_ID}/dispatches" \
  -d "{\"ref\":\"${TAG}\"}")
if [[ "$resp" != "204" ]]; then
  echo "[dispatch] Non-204 HTTP code: $resp"
  echo "  Tips:"
  echo "   - Ensure the token has: Actions: write, Contents: write"
  echo "   - Fine-grained PAT must grant access to this repo"
  echo "   - Confirm WORKFLOW_ID matches the workflow filename in .github/workflows/"
  exit 1
fi
echo "[dispatch] Sent. Use tools/check_ci.sh to watch runs."
