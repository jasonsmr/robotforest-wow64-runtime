#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN first}"
curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github+json" \
            -H "User-Agent: rf-ci-helper" \
  https://api.github.com/user | jq '{login, id, type}'
