#!/usr/bin/env bash
set -euo pipefail
OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
echo "[ci] Latest runs (push / workflow_dispatch)"
curl -fsSL -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: rf-ci-helper' \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/runs?per_page=10" \
| jq '.workflow_runs[] | {name, event, status, conclusion, head_branch, head_sha, html_url}'
