#!/usr/bin/env bash
set -euo pipefail
TAG="${1:?Usage: watch_tag <vX.Y.Z>}"
REPO="jasonsmr/robotforest-wow64-runtime"
AUTH=()
UA=(-H "User-Agent: rf-watch/1.2" -H "Accept: application/vnd.github+json")
[ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
api(){ curl -fsSL "${AUTH[@]}" "${UA[@]}" "$@"; }

# Resolve tag->commit sha
TAG_SHA="$(api "https://api.github.com/repos/${REPO}/git/ref/tags/${TAG#refs/tags/}" | jq -r '.object.sha // empty')"
echo "[watch] tag: ${TAG} sha: ${TAG_SHA:-<none>}"

get_run_id() {
  # look at both push and workflow_dispatch runs
  api "https://api.github.com/repos/${REPO}/actions/runs?per_page=50" \
  | jq -r --arg sha "$TAG_SHA" '
      .workflow_runs[]
      | select((.event=="push" or .event=="workflow_dispatch"))
      | select(.head_sha==$sha) | .id
    ' | head -n1
}

print_status() {
  local run_id="$1"
  api "https://api.github.com/repos/${REPO}/actions/runs/${run_id}/jobs?per_page=100" \
  | jq -r '.jobs[] | "\(.name): \(.status) / " + ((.conclusion // "…")) + "\n  steps:\n" +
           ( [ .steps[] | "   - " + .name + ": " + (.status // "…") + " / " + (.conclusion // "…") ] | join("\n") )'
}

run_id=""
if [ -n "${TAG_SHA:-}" ]; then
  for _ in {1..120}; do
    run_id="$(get_run_id || true)"
    [ -n "${run_id:-}" ] && [ "${run_id}" != "null" ] && break
    sleep 5
  done
fi

if [ -z "${run_id:-}" ] || [ "${run_id}" = "null" ]; then
  echo "[watch] no run found yet; watching release assets…"
  while :; do
    api "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" \
    | jq -r '.assets[]? | "\(.name)  \(.state // "uploaded")"'
    echo "-----"
    sleep 15
  done
fi

echo "[watch] run id: ${run_id}"
while :; do
  print_status "$run_id" || true
  echo "-----"
  sleep 15
done
