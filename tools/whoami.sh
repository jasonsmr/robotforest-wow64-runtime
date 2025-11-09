#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/token.sh"

# Basic validation: accept classic ghp_ or fine-grained github_pat_
tok="${GITHUB_TOKEN:-}"
len=$(printf %s "$tok" | wc -c | tr -d ' ')
# wc -l returns 0 if no trailing newline; treat 0 or 1 as OK
lines=$(printf %s "$tok" | wc -l | tr -d ' ')
if [ "$len" -lt 35 ]; then
  echo "[whoami] Token looks too short (length=$len). Re-export it WITHOUT quotes:"
  echo "         export GITHUB_TOKEN=ghp_xxx   # or github_pat_xxx"
  exit 1
fi

OWNER="jasonsmr"
REPO="robotforest-wow64-runtime"

# Query a repo endpoint so fine-grained tokens work
resp="$(curl -fsSL \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: rf-ci-helper" \
  "https://api.github.com/repos/${OWNER}/${REPO}")"

printf '%s\n' "$resp" | jq '{full_name, private, permissions, default_branch}'
