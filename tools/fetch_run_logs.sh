#!/usr/bin/env bash
set -euo pipefail
RUNID="${1:?Usage: fetch_run_logs.sh <run_id>}"
OUT="logs-${RUNID}.zip"
if [ -z "${GITHUB_TOKEN:-}" ] && [ -f "$HOME/.config/rf/github_token" ]; then
  export GITHUB_TOKEN="$(tr -d '\r\n' < "$HOME/.config/rf/github_token")"
fi
auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
RUN_JSON="$(curl -fsSL "${auth[@]}" \
  "https://api.github.com/repos/jasonsmr/robotforest-wow64-runtime/actions/runs/${RUNID}")"
LOGS_URL="$(echo "$RUN_JSON" | jq -r '.logs_url')"
ATTEMPT="$(echo "$RUN_JSON" | jq -r '.run_attempt // 1')"
echo "[logs] run=$RUNID attempt=${ATTEMPT}"
set +e
curl -fsSL -L "${auth[@]}" "$LOGS_URL" -o "$OUT"
rc=$?
set -e
if [ $rc -ne 0 ] || [ ! -s "$OUT" ]; then
  echo "[logs] logs_url failed (rc=$rc). Trying attempts endpoint…"
  curl -fsSL -L "${auth[@]}" \
    "https://api.github.com/repos/jasonsmr/robotforest-wow64-runtime/actions/runs/${RUNID}/attempts/${ATTEMPT}/logs" \
    -o "$OUT"
fi
[ -s "$OUT" ] || { echo "[logs] empty zip"; exit 2; }
ls -lh "$OUT"
