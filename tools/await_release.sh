#!/usr/bin/env bash
set -euo pipefail
OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
TAG="${1:?Usage: await_release <vX.Y.Z>}"
MAX_SEC="${2:-180}"

api="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG"
end=$(( $(date +%s) + MAX_SEC ))
echo "[await] Waiting for release assets on $TAG (timeout ${MAX_SEC}s)…"
while :; do
  if json=$(curl -fsSL -H 'Accept: application/vnd.github+json' "$api" 2>/dev/null); then
    url=$(printf '%s' "$json" | grep -oE 'https://[^"]+robotforest-wow64-runtime-'"$TAG"'\.zip' | head -n1 || true)
    if [[ -n "$url" ]]; then
      echo "[await] Asset ready: $url"
      exit 0
    fi
  fi
  (( $(date +%s) >= end )) && { echo "[await] Timed out waiting for $TAG"; exit 22; }
  sleep 5
done
