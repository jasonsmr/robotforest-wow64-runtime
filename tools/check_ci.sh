#!/usr/bin/env bash
set -euo pipefail
OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
echo "[ci] Latest runs (event=push, release, workflow_dispatch)"
curl -fsSL -H 'Accept: application/vnd.github+json' \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/runs?per_page=10" \
| jq '.workflow_runs[] | {name, event, status, conclusion, head_branch, head_sha, html_url} | select(.event=="push" or .event=="workflow_dispatch" or .name|tostring|test("Build & Release"))'
