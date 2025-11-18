#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-ci/productionize}"
OUTDIR="${2:-./ci-logs}"

mkdir -p "${OUTDIR}"

echo "[ci-latest] fetching rf-release-full.yml (latest) -> ${OUTDIR}/rf-release-full-latest.log"
gh run view \
  --branch "${BRANCH}" \
  --workflow "rf-release-full.yml" \
  --json logs \
  --jq '.logs' > "${OUTDIR}/rf-release-full-latest.log"

echo "[ci-latest] fetching runtime-smoke.yml (latest) -> ${OUTDIR}/runtime-smoke-latest.log"
gh run view \
  --branch "${BRANCH}" \
  --workflow "runtime-smoke.yml" \
  --json logs \
  --jq '.logs' > "${OUTDIR}/runtime-smoke-latest.log"

echo "[ci-latest] logs in: ${OUTDIR}"
