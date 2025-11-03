#!/usr/bin/env bash
set -euo pipefail
OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"
curl -fsSL -H 'Accept: application/vnd.github+json' \
            -H 'User-Agent: rf-ci-helper' \
  "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows" \
| jq '.workflows[] | {id, name, path, state}'
