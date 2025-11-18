#!/usr/bin/env bash
# tools/ci_collect_logs.sh
# Collect GitHub Actions logs for a branch and pack them into a single tar.gz.
#
# Usage:
#   tools/ci_collect_logs.sh [branch] [limit]
#   branch defaults to "ci/productionize"
#   limit  defaults to 20

set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")"/.. && pwd)"
cd "${ROOT}"

BRANCH="${1:-ci/productionize}"
LIMIT="${2:-20}"

OUTDIR="${ROOT}/ci-logs"
DIST="${ROOT}/dist"

echo "[ci-logs] root:     ${ROOT}"
echo "[ci-logs] branch:   ${BRANCH}"
echo "[ci-logs] limit:    ${LIMIT}"
echo "[ci-logs] outdir:   ${OUTDIR}"
echo "[ci-logs] dist dir: ${DIST}"

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}" "${DIST}"

# 1) Save a human-readable summary of recent runs
echo "[ci-logs] capturing summary list..."
gh run list --branch "${BRANCH}" --limit "${LIMIT}" > "${OUTDIR}/runs-${BRANCH//\//_}.txt"

# 2) Get run IDs in JSON form (databaseId == numeric ID gh uses)
echo "[ci-logs] collecting run IDs..."
mapfile -t RUN_IDS < <(
  gh run list \
    --branch "${BRANCH}" \
    --limit "${LIMIT}" \
    --json databaseId \
    -q '.[].databaseId'
)

if [[ ${#RUN_IDS[@]} -eq 0 ]]; then
  echo "[ci-logs] No runs found for branch ${BRANCH}"
  exit 0
fi

echo "[ci-logs] found ${#RUN_IDS[@]} runs"

# 3) For each run, capture full log
for RUN_ID in "${RUN_IDS[@]}"; do
  LOG_FILE="${OUTDIR}/run-${RUN_ID}.log"
  echo "[ci-logs] fetching log for run ${RUN_ID} -> ${LOG_FILE}"
  if gh run view "${RUN_ID}" --log > "${LOG_FILE}"; then
    echo "[ci-logs] ok: ${RUN_ID}" >> "${OUTDIR}/index.txt"
  else
    echo "[ci-logs] WARN: failed to fetch ${RUN_ID}" | tee -a "${OUTDIR}/index.txt"
  fi
done

# 4) Pack everything into a tar.gz in dist/
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="ci-logs-${BRANCH//\//_}-${STAMP}.tar.gz"
ARCHIVE_PATH="${DIST}/${ARCHIVE}"

echo "[ci-logs] creating archive: ${ARCHIVE_PATH}"
(
  cd "${ROOT}"
  tar -czf "${ARCHIVE_PATH}" "$(basename "${OUTDIR}")"
)

echo "[ci-logs] done."
echo "[ci-logs] archive: ${ARCHIVE_PATH}"
