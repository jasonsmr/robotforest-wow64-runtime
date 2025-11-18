#!/usr/bin/env bash
set -euo pipefail
TAG="${1:?Usage: await_release <vX.Y.Z> [seconds] }"
WAIT_SECS="${2:-300}"
REPO="jasonsmr/robotforest-wow64-runtime"

AUTH=()
UA=(-H "User-Agent: rf-await/1.1" -H "Accept: application/vnd.github+json")
[ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
api(){ curl -fsSL "${AUTH[@]}" "${UA[@]}" "$@"; }

echo "[await] Waiting for release asset robotforest-wow64-runtime-${TAG}.zip (timeout ${WAIT_SECS}s)…"
end=$(( $(date +%s) + WAIT_SECS ))
while [ "$(date +%s)" -lt "$end" ]; do
  json="$(api "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" || true)"
  if [ -n "$json" ] && echo "$json" | jq -e '.assets and (.assets | length>0)' >/dev/null 2>&1; then
    url="$(echo "$json" | jq -r ".assets[] | select(.name==\"robotforest-wow64-runtime-${TAG}.zip\") | .browser_download_url" | head -n1)"
    if [ -n "$url" ] && [ "$url" != "null" ]; then
      echo "[await] Asset ready: $url"
      exit 0
    fi
  fi
  echo "[await] still waiting… ~$(( end - $(date +%s) ))s left"
  sleep 63
done

echo "[await] Timed out waiting for ${TAG}"
exit 2
