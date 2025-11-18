#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-ci/productionize}"
OUTDIR="${2:-$HOME/ci-latest-logs}"

mkdir -p "${OUTDIR}"

get_latest_id() {
  local wf="$1"
  gh run list \
    --workflow="${wf}" \
    --branch="${BRANCH}" \
    --limit 1 \
    --json databaseId \
    -q '.[0].databaseId' 2>/dev/null || true
}

for WF in "release-core.yml" "rf-release-full.yml" "runtime-smoke.yml"; do
  ID="$(get_latest_id "${WF}")"
  if [[ -n "${ID}" ]]; then
    LOG="${OUTDIR}/${WF%.yml}-latest.log"
    echo "[ci-latest] fetching ${WF} (run ${ID}) -> ${LOG}"
    gh run view "${ID}" --log > "${LOG}"
  else
    echo "[ci-latest] no runs found for ${WF} on ${BRANCH}"
  fi
done

echo "[ci-latest] logs in: ${OUTDIR}"
