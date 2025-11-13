#!/data/data/com.termux/files/usr/bin/bash
# rf_pack_runtime.sh
# Assemble a runtime bundle from staging/rf_runtime into:
#   dist/rf-runtime-<tag>.tar.zst
#   dist/rf-runtime-<tag>.zip
#
# Tag rules:
#   - Default TAG: dev (local)
#   - On CI: uses GITHUB_REF_NAME, slashes turned into dashes (ci/productionize -> ci-productionize)
#   - Optional override: RF_TAG env var

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.."; pwd)"
STAGE="${REPO}/staging"
ROOT="${STAGE}/rf_runtime"
OUT="${REPO}/dist"

mkdir -p "${OUT}"

# Derive TAG and make it filesystem-safe
RAW_TAG="${RF_TAG:-${GITHUB_REF_NAME:-dev}}"
TAG="${RAW_TAG//\//-}"     # ci/productionize -> ci-productionize
BASE="rf-runtime-${TAG}"

# Basic sanity: rf_runtime must exist
if [ ! -d "${ROOT}" ]; then
  echo "[pack] ERROR: missing ${ROOT} (expected populated runtime tree)" >&2
  exit 1
fi

# --- wrappers must exist (hard requirement) ---
fail=0
for f in \
  "${ROOT}/bin/wine64.sh" \
  "${ROOT}/bin/wine32on64.sh" \
  "${ROOT}/bin/steam-win.sh"
do
  if [ ! -x "${f}" ]; then
    echo "[fail] missing wrapper: ${f}" >&2
    fail=1
  fi
done

if [ "${fail}" -ne 0 ]; then
  echo "[fail] critical wrappers missing; rf_runtime is not usable" >&2
  exit 2
fi

# --- Wine payloads: warn by default, enforce with RF_STRICT_WINE=1 ---
strict="${RF_STRICT_WINE:-0}"
wine_warn=0

if [ ! -d "${ROOT}/wine64" ]; then
  echo "[warn] missing wine64 tree at ${ROOT}/wine64" >&2
  wine_warn=1
fi

if [ ! -d "${ROOT}/wine32" ]; then
  echo "[warn] missing wine32 tree at ${ROOT}/wine32" >&2
  wine_warn=1
fi

if [ -d "${ROOT}/wine64" ] && [ ! -f "${ROOT}/wine64/wine64" ]; then
  echo "[warn] missing wine64 loader in ${ROOT}/wine64" >&2
  ls -la "${ROOT}/wine64" || true
  wine_warn=1
fi

if [ "${wine_warn}" -ne 0 ] && [ "${strict}" = "1" ]; then
  echo "[fail] RF_STRICT_WINE=1 and Wine payload incomplete; aborting pack." >&2
  exit 3
fi

# --- 1) tar.zst ---
TAR="${OUT}/${BASE}.tar.zst"
echo "[pack] ${TAR}"

# Use long-window zstd to match verify/runtime-smoke expectations
tar -C "${STAGE}" \
    -I 'zstd --long=31 -19' \
    -cf "${TAR}" \
    rf_runtime

(
  cd "${OUT}"
  sha256sum "$(basename "${TAR}")" > "$(basename "${TAR}").sha256"
)

# --- 2) zip ---
ZIP="${OUT}/${BASE}.zip"
echo "[pack] ${ZIP}"

(
  cd "${STAGE}"
  zip -q -r "${ZIP}" rf_runtime
)

(
  cd "${OUT}"
  sha256sum "$(basename "${ZIP}")" > "$(basename "${ZIP}").sha256"
)

echo "[ok] built:"
ls -lh "${TAR}" "${TAR}.sha256" "${ZIP}" "${ZIP}.sha256"

# Final note about Wine completeness (non-fatal unless RF_STRICT_WINE=1)
if [ "${wine_warn}" -ne 0 ]; then
  echo "[warn] wine payload incomplete; runtime may not run Windows titles yet." >&2
fi
