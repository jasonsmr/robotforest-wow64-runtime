#!/usr/bin/env bash
set -euo pipefail
OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
TAG="${1:?Usage: await_release <vX.Y.Z>}"
MAX_SEC="${2:-900}"  # bump default to 15min

api="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG"
end=$(( $(date +%s) + MAX_SEC ))
echo "[await] Waiting for release asset robotforest-wow64-runtime-${TAG}.zip (timeout ${MAX_SEC}s)…"
i=0
while :; do
  i=$((i+1))
  if json=$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api" 2>/dev/null); then
    url=$(printf '%s' "$json" | grep -oE 'https://[^"]+robotforest-wow64-runtime-'"$TAG"'\.zip' | head -n1 || true)
    if [[ -n "$url" ]]; then
      echo "[await] Asset ready: $url"
      exit 0
    fi
  fi
  now=$(date +%s)
  left=$(( end - now ))
  (( left <= 0 )) && { echo "[await] Timed out waiting for $TAG"; exit 22; }
  (( i % 12 == 0 )) && echo "[await] still waiting… ~${left}s left"
  sleep 5
done
