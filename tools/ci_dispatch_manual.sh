#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail
TAG="${1:-}"
: "${GITHUB_TOKEN:?set GITHUB_TOKEN or export from tools/token.sh}"

WF_ID="$(curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/jasonsmr/robotforest-wow64-runtime/actions/workflows" \
  | jq -r '.workflows[] | select(.path==".github/workflows/manual-release.yml") | .id')"

PAYLOAD='{"ref":"main"'
if [[ -n "$TAG" ]]; then
  PAYLOAD="$PAYLOAD,\"inputs\":{\"tag\":\"'"$TAG"'\"}"
fi
PAYLOAD="$PAYLOAD}"

curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/jasonsmr/robotforest-wow64-runtime/actions/workflows/${WF_ID}/dispatches" \
  -d "$PAYLOAD"
