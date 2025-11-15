#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[pack] ERROR at line ${LINENO}" >&2' ERR

# Repo root = parent of this script directory
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
RUNTIME_DIR="${ROOT}/staging/rf_runtime"
DIST="${ROOT}/dist"

echo "[pack] rf_runtime root: ${RUNTIME_DIR}"

if [[ ! -d "${RUNTIME_DIR}" ]]; then
  echo "[pack] ERROR: runtime dir not found: ${RUNTIME_DIR}" >&2
  exit 1
fi

mkdir -p "${DIST}"

# Write MANIFEST.SHA256 inside rf_runtime
echo "[pack] Writing MANIFEST.SHA256"
(
  cd "${RUNTIME_DIR}"
  # deterministic ordering
  find . -type f -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 sha256sum > MANIFEST.SHA256
)

TAR="${DIST}/rf-runtime-dev.tar.zst"
TAR_SHA="${TAR}.sha256"
ZIP="${DIST}/rf-runtime-dev.zip"
ZIP_SHA="${ZIP}.sha256"

echo "[pack] Creating ${TAR}"
tar --use-compress-program="zstd --long=31 -T0" \
    -cf "${TAR}" \
    -C "${RUNTIME_DIR}" .

echo "[pack] Creating ${TAR_SHA}"
(
  cd "${DIST}"
  sha256sum "$(basename "${TAR}")" > "$(basename "${TAR_SHA}")"
)

echo "[pack] Creating ${ZIP}"
(
  cd "${RUNTIME_DIR}"
  zip -r "${ZIP}" . > /dev/null
)

echo "[pack] Creating ${ZIP_SHA}"
(
  cd "${DIST}"
  sha256sum "$(basename "${ZIP}")" > "$(basename "${ZIP_SHA}")"
)

echo "[pack] [ok] built:"
ls -l "${TAR}" "${TAR_SHA}" "${ZIP}" "${ZIP_SHA}"
